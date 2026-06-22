import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:record/record.dart';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/io.dart';
import 'package:web_socket_channel/status.dart' as status;
import 'package:flutter/foundation.dart';

import 'package:firebase_auth/firebase_auth.dart';

import 'speaking_session_store.dart';
import '../models/speaking_session.dart';
import '../models/pronunciation_feedback.dart';
import '../models/word_error.dart';

enum GeminiMode { userSpeaksFirst, aiSpeaksFirst }

class GeminiEvent {
  final String type;
  final dynamic data;
  GeminiEvent(this.type, [this.data]);
}

class GeminiRealtimeService {
  GeminiRealtimeService({SpeakingSessionStore? sessionStore})
    : _sessionStore = sessionStore ?? SpeakingSessionStore.instance;

  final SpeakingSessionStore _sessionStore;
  final AudioRecorder _recorder = AudioRecorder();
  WebSocketChannel? _channel;
  IOWebSocketChannel? _ioChannel;
  final _events = StreamController<GeminiEvent>.broadcast();
  Stream<GeminiEvent> get events => _events.stream;

  Timer? _sessionTimer;

  String? _sessionId;
  String? _chosenTopic;
  DateTime? _startedAt;
  bool _setupComplete = false;
  String? _pendingOpeningText;
  StreamSubscription<Uint8List>? _audioSub;
  int _audioChunkCount = 0;
  Completer<void>? _setupCompleter;

  bool get isConnected => _channel != null;

  Future<void> initialize({
    required GeminiMode mode,
    String? selectedTopic,
  }) async {
    _chosenTopic = selectedTopic;
    _sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    // Keep the key out of source; this app currently reads it from .env.
    // If you later add a backend token service, swap this lookup there.
    final apiKey = dotenv.env['API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API_KEY not set in .env');
    }

    final uri = Uri.parse(
      'wss://generativelanguage.googleapis.com/ws/google.ai.generativelanguage.v1beta.GenerativeService.BidiGenerateContent?key=$apiKey',
    );

    // Diagnostic log for debugging connection issues
    // ignore: avoid_print
    print('GeminiRealtimeService: connecting to $uri');
    _events.add(GeminiEvent('debug', 'Connecting to Gemini Live...'));

    if (kIsWeb) {
      _channel = WebSocketChannel.connect(uri);
    } else {
      _ioChannel = IOWebSocketChannel.connect(
        uri,
        pingInterval: const Duration(seconds: 10),
      );
      _channel = _ioChannel;
    }

    // ignore: avoid_print
    print('GeminiRealtimeService: socket opened');
    _events.add(GeminiEvent('debug', 'WebSocket opened'));

    _setupCompleter = Completer<void>();

    _channel!.stream.listen(
      _onMessage,
      onDone: _onDone,
      onError: (e) {
        _events.add(GeminiEvent('error', e));
        _events.add(GeminiEvent('debug', 'WebSocket error: $e'));
      },
    );

    // Send initial setup block requesting AUDIO modality and a live model
    final setup = {
      'setup': {
        'model': 'models/gemini-3.1-flash-live-preview',
        'generationConfig': {
          'responseModalities': ['AUDIO'],
        },
        'realtimeInputConfig': {
          'automaticActivityDetection': {'disabled': true},
        },
        'systemInstruction': {
          'parts': [
            {
              'text': mode == GeminiMode.userSpeaksFirst
                  ? 'Act as a friendly, relatable human companion. Wait in silence. Do NOT speak until the user says something first. Keep your responses short (1-3 sentences) and conversational.'
                  : 'Act as a friendly, relatable human companion. Keep your responses short (1-3 sentences) and conversational.',
            },
          ],
        },
      },
    };

    try {
      await _channel!.ready;
    } catch (_) {}

    _channel!.sink.add(jsonEncode(setup));
    _events.add(GeminiEvent('debug', 'Setup sent'));

    if (mode == GeminiMode.aiSpeaksFirst && selectedTopic != null) {
      _pendingOpeningText =
          'The user has chosen the topic: $selectedTopic. Please start the conversation with an engaging opening sentence about this topic.';
    }

    await _setupCompleter!.future.timeout(
      const Duration(seconds: 60),
      onTimeout: () => throw TimeoutException(
        'Gemini setup timed out — check API key and model name',
      ),
    );
  }

  Future<void> start({int sessionSeconds = 180}) async {
    if (_channel == null) throw Exception('Not initialized');

    _startedAt = DateTime.now();

    _sessionTimer?.cancel();
    _sessionTimer = Timer(Duration(seconds: sessionSeconds), () async {
      await stop();
      await _persistSession();
      _events.add(GeminiEvent('session_timeout'));
    });

    // start recording to temporary file; we'll chunk and send
    if (kIsWeb) {
      // Web does not support dart:io filesystem APIs like Directory.systemTemp.
      // The current recording/streaming implementation requires file access
      // to chunk recorded data. For now, surface a clear error so callers
      // know realtime streaming is not supported on web in this implementation.
      throw UnsupportedError(
        'Realtime voice streaming is not supported on Web. Use Android or iOS.',
      );
    }

    if (!await _recorder.hasPermission()) {
      throw Exception('Microphone permission denied');
    }

    _audioChunkCount = 0;
    final stream = await _recorder.startStream(
      const RecordConfig(
        encoder: AudioEncoder.pcm16bits,
        sampleRate: 16000,
        numChannels: 1,
        echoCancel: true,
        noiseSuppress: true,
        autoGain: false,
      ),
    );

    _audioSub?.cancel();
    _audioSub = stream.listen(
      (bytes) {
        if (bytes.isEmpty) return;
        _audioChunkCount += 1;
        final base64Chunk = base64Encode(bytes);
        final msg = {
          'realtimeInput': {
            'audio': {'data': base64Chunk, 'mimeType': 'audio/pcm;rate=16000'},
          },
        };
        _channel?.sink.add(jsonEncode(msg));
        if (_audioChunkCount % 50 == 0) {
          _events.add(
            GeminiEvent('debug', 'Audio chunks sent: $_audioChunkCount'),
          );
        }
      },
      onError: (e, st) {
        _events.add(GeminiEvent('error', {'error': e, 'stack': st}));
        _events.add(GeminiEvent('debug', 'Audio stream error: $e'));
      },
    );
    _events.add(GeminiEvent('started'));
  }

  Future<void> stop() async {
    _sessionTimer?.cancel();
    await _audioSub?.cancel();
    _audioSub = null;

    try {
      if (await _recorder.isRecording()) {
        await _recorder.stop();
      }
    } catch (_) {}

    try {
      _channel?.sink.close(status.normalClosure);
    } catch (_) {}
    _channel = null;
    _events.add(GeminiEvent('stopped'));
  }

  Future<void> dispose() async {
    _sessionTimer?.cancel();
    await _audioSub?.cancel();
    _audioSub = null;
    await stop();
    await _events.close();
  }

  void _onMessage(dynamic raw) {
    try {
      String? jsonStr;
      if (raw is String) {
        jsonStr = raw;
      } else if (raw is Uint8List) {
        jsonStr = utf8.decode(raw);
      } else if (raw is List<int>) {
        jsonStr = utf8.decode(raw);
      } else {
        _events.add(
          GeminiEvent('debug', 'Unknown frame type: ${raw.runtimeType}'),
        );
        return;
      }

      final Map<String, dynamic> msg = jsonDecode(jsonStr);

      if (msg.containsKey('error')) {
        _events.add(GeminiEvent('error', msg['error']));
      }

      if (msg.containsKey('setupComplete')) {
        _setupComplete = true;
        if (_setupCompleter != null && !_setupCompleter!.isCompleted) {
          _setupCompleter!.complete();
        }
        _events.add(GeminiEvent('debug', 'Setup complete received'));
        _trySendOpening();
      }

      bool hadAudio = false;
      final serverContent = msg['serverContent'];
      if (serverContent is Map) {
        final modelTurn = serverContent['modelTurn'];
        if (modelTurn is Map) {
          final parts = modelTurn['parts'];
          if (parts is List) {
            for (final part in parts) {
              if (part is Map) {
                if (part['text'] is String) {
                  _events.add(GeminiEvent('text', part['text']));
                }
                if (part['inlineData'] is Map) {
                  final inline = (part['inlineData'] as Map)['data'] as String?;
                  if (inline != null && inline.isNotEmpty) {
                    hadAudio = true;
                    final bytes = base64Decode(inline);
                    // Server audio is PCM16 little-endian at 24kHz
                    final resampled = _upsample2x(bytes);
                    _events.add(GeminiEvent('audio_chunk', resampled));
                  }
                }
              }
            }
          }
        }
        if (serverContent['turnComplete'] == true) {
          _events.add(GeminiEvent('turn_complete'));
        }
        if (serverContent['interrupted'] == true) {
          _events.add(GeminiEvent('interrupted'));
        }
      }

      if (!hadAudio) {
        _events.add(GeminiEvent('debug', 'Msg keys: ${msg.keys}'));
        _events.add(GeminiEvent('message', msg));
      }
    } catch (e, st) {
      _events.add(GeminiEvent('error', {'error': e, 'stack': st}));
    }
  }

  void _onDone() {
    final ws = _ioChannel?.innerWebSocket;
    _events.add(
      GeminiEvent('connection_closed', {
        'code': ws?.closeCode,
        'reason': ws?.closeReason,
      }),
    );
    _events.add(
      GeminiEvent(
        'debug',
        'WebSocket closed (code: ${ws?.closeCode}, reason: ${ws?.closeReason})',
      ),
    );
  }

  void _trySendOpening() {
    if (!_setupComplete) return;
    final text = _pendingOpeningText;
    if (text == null || text.isEmpty) return;
    final clientMsg = {
      'clientContent': {
        'turns': [
          {
            'role': 'user',
            'parts': [
              {'text': text},
            ],
          },
        ],
        'turnComplete': true,
      },
    };
    _channel?.sink.add(jsonEncode(clientMsg));
    _events.add(GeminiEvent('debug', 'Opening prompt sent'));
    _pendingOpeningText = null;
  }

  Uint8List _upsample2x(Uint8List input) {
    final inSamples = input.lengthInBytes ~/ 2;
    if (inSamples == 0) return Uint8List(0);
    final inView = input.buffer.asByteData(
      input.offsetInBytes,
      input.lengthInBytes,
    );
    final out = ByteData(inSamples * 4);
    for (int i = 0; i < inSamples; i++) {
      final a = inView.getInt16(i * 2, Endian.little);
      final b = (i + 1 < inSamples)
          ? inView.getInt16((i + 1) * 2, Endian.little)
          : a;
      out.setInt16(i * 4, a, Endian.little);
      out.setInt16(i * 4 + 2, (a + b) >> 1, Endian.little);
    }
    return out.buffer.asUint8List();
  }

  void sendActivityStart() {
    if (_channel == null) return;
    _channel!.sink.add(
      jsonEncode({
        'realtimeInput': {'activityStart': {}},
      }),
    );
    _events.add(GeminiEvent('debug', 'activityStart sent'));
  }

  void sendActivityEnd() {
    if (_channel == null) return;
    _channel!.sink.add(
      jsonEncode({
        'realtimeInput': {'activityEnd': {}},
      }),
    );
    _events.add(GeminiEvent('debug', 'activityEnd sent'));
  }

  Future<void> _persistSession() async {
    final endedAt = DateTime.now();
    final durationSeconds = _startedAt == null
        ? 0
        : endedAt.difference(_startedAt!).inSeconds;

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return;

      final speakingSession = SpeakingSession(
        sessionId: _sessionId ?? '',
        userId: user.uid,
        timestamp: endedAt,
        targetSentence: _chosenTopic ?? '',
        transcript: '',
        overallScore: 0,
        bandScore: 0.0,
        duration: Duration(seconds: durationSeconds),
        confidenceScores: {},
        wordErrors: <WordError>[],
        feedback: PronunciationFeedback(
          summaryVN: '',
          summaryEN: '',
          tipsVN: [],
          tipsEN: [],
          nextStepsVN: '',
          nextStepsEN: '',
          improvementFocus: [],
        ),
        category: null,
      );

      await _sessionStore.saveSession(speakingSession);
    } catch (e) {
      // non-fatal
      _events.add(GeminiEvent('error', e));
    }
  }
}
