import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_pcm_sound/flutter_pcm_sound.dart';

import '../../../data/gemini_realtime_service.dart';

class GeminiLiveVoicePage extends StatefulWidget {
  const GeminiLiveVoicePage({super.key});

  @override
  State<GeminiLiveVoicePage> createState() => _GeminiLiveVoicePageState();
}

class _GeminiLiveVoicePageState extends State<GeminiLiveVoicePage> {
  // Colors (match speaking UI theme)
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color bgColor = Color(0xFFF6FAFF);
  static const Color textGrey = Color(0xFF607D8B);

  final GeminiRealtimeService _service = GeminiRealtimeService();
  StreamSubscription<GeminiEvent>? _sub;
  bool _pcmReady = false;
  bool _pcmPlaying = false;
  bool _pcmResetting = false;

  GeminiMode _mode = GeminiMode.aiSpeaksFirst;
  final TextEditingController _topicController = TextEditingController(
    text: 'Travel',
  );
  // final List<String> _logs = [];
  bool _busy = false;
  bool _started = false;
  bool _userIsSpeaking = false;

  @override
  void initState() {
    super.initState();
    _initPcmOutput();
    _sub = _service.events.listen((event) async {
      if (!mounted) return;

      if (event.type == 'audio_chunk') {
        final data = event.data;
        if (data is Uint8List) {
          _playPcmChunk(data);
        }
        return;
      }

      if (event.type == 'interrupted') {
        await _resetPcmBuffer();
      }
      if (!mounted) return;

      setState(() {
        if (event.type == 'turn_complete') {
          _pcmPlaying = false;
          // _logs.add('Turn complete');
        } else if (event.type == 'interrupted') {
          _pcmPlaying = false;
          // _logs.add('AI interrupted');
        } else if (event.type == 'text') {
          // _logs.add('Text: ${event.data}');
        } else if (event.type == 'message' && event.data is Map) {
          // _logs.add('Message received');
        } else if (event.type == 'connection_closed') {
          // final data = event.data is Map ? event.data as Map : null;
          // _logs.add(
          //   'Connection closed (code: ${data?['code'] ?? 'n/a'}, reason: ${data?['reason'] ?? 'n/a'})',
          // );
          _started = false;
          _busy = false;
        } else if (event.type == 'session_timeout' || event.type == 'stopped') {
          _started = false;
          _busy = false;
        } else if (event.type == 'error') {
          // _logs.add('Error: ${event.data}');
          _busy = false;
        } else if (event.type == 'debug') {
          // _logs.add('Debug: ${event.data}');
        } else {
          // _logs.add(event.type);
        }
        // if (_logs.length > 30) {
        //   _logs.removeAt(0);
        // }
      });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _service.dispose();
    _disposePcmOutput();
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _initPcmOutput() async {
    try {
      await FlutterPcmSound.setLogLevel(LogLevel.none);
      await FlutterPcmSound.setup(sampleRate: 48000, channelCount: 1);
      await FlutterPcmSound.setFeedThreshold(2048);
      _pcmReady = true;
    } catch (_) {
      _pcmReady = false;
    }
  }

  Future<void> _resetPcmBuffer() async {
    if (!_pcmReady || _pcmResetting) return;
    _pcmResetting = true;
    _pcmPlaying = false;
    try {
      await FlutterPcmSound.release();
      await FlutterPcmSound.setup(sampleRate: 48000, channelCount: 1);
      await FlutterPcmSound.setFeedThreshold(2048);
    } catch (_) {
      _pcmReady = false;
    } finally {
      _pcmResetting = false;
    }
  }

  Future<void> _disposePcmOutput() async {
    try {
      await FlutterPcmSound.release();
    } catch (_) {}
  }

  void _playPcmChunk(Uint8List bytes) {
    if (!_pcmReady || _pcmResetting || bytes.isEmpty) return;
    final pcm = PcmArrayInt16(
      bytes: bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes),
    );
    FlutterPcmSound.feed(pcm);
    if (!_pcmPlaying) {
      FlutterPcmSound.start();
      _pcmPlaying = true;
    }
  }

  Future<void> _start() async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await _service.initialize(
        mode: _mode,
        selectedTopic: _topicController.text.trim().isEmpty
            ? null
            : _topicController.text.trim(),
      );
      await _service.start(sessionSeconds: 180);
      setState(() {
        _started = true;
        _busy = false;
      });
    } catch (e, st) {
      setState(() => _busy = false);
      // Log full error + stacktrace to Debug Console for diagnosis
      // ignore: avoid_print
      print('GeminiLiveVoicePage: Failed to start: $e');
      // ignore: avoid_print
      print(st);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to start: $e — see Debug Console for stack trace',
            ),
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  Future<void> _stop() async {
    await _service.stop();
    if (!mounted) return;
    setState(() => _started = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text('Live Voice Companion'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Real-time Gemini voice practice',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Speak naturally and get instant AI responses.',
                  style: TextStyle(color: textGrey),
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: _topicController,
                  decoration: InputDecoration(
                    labelText: 'Topic',
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Conversation mode',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
                RadioListTile<GeminiMode>(
                  value: GeminiMode.aiSpeaksFirst,
                  groupValue: _mode,
                  title: const Text('AI speaks first'),
                  subtitle: const Text(
                    'Start with an opening sentence about the topic',
                  ),
                  onChanged: (value) => setState(() => _mode = value!),
                ),
                RadioListTile<GeminiMode>(
                  value: GeminiMode.userSpeaksFirst,
                  groupValue: _mode,
                  title: const Text('User speaks first'),
                  subtitle: const Text('Wait until the user starts speaking'),
                  onChanged: (value) => setState(() => _mode = value!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: _busy || _started ? null : _start,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _busy
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Start session'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: _started ? _stop : null,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: primaryBlue,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    side: const BorderSide(color: primaryBlue),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Text('Stop session'),
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          if (_started) ...[
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  const Text(
                    'Push-to-talk',
                    style: TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  GestureDetector(
                    onLongPressStart: (_) {
                      _service.sendActivityStart();
                      setState(() => _userIsSpeaking = true);
                    },
                    onLongPressEnd: (_) {
                      _service.sendActivityEnd();
                      setState(() => _userIsSpeaking = false);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 120),
                      width: 88,
                      height: 88,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: _userIsSpeaking ? Colors.red : primaryBlue,
                        boxShadow: _userIsSpeaking
                            ? [
                                BoxShadow(
                                  color: Colors.red.withOpacity(0.4),
                                  blurRadius: 20,
                                  spreadRadius: 4,
                                ),
                              ]
                            : [
                                BoxShadow(
                                  color: primaryBlue.withOpacity(0.25),
                                  blurRadius: 16,
                                  spreadRadius: 2,
                                ),
                              ],
                      ),
                      child: Icon(
                        _userIsSpeaking ? Icons.mic : Icons.mic_none,
                        color: Colors.white,
                        size: 38,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    _userIsSpeaking ? 'Release to send' : 'Hold to speak',
                    style: const TextStyle(color: textGrey),
                  ),
                ],
              ),
            ),
          ],
          // const SizedBox(height: 20),
          // const Text(
          //   'Session log',
          //   style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          // ),
          // const SizedBox(height: 8),
          // Container(
          //   padding: const EdgeInsets.all(12),
          //   decoration: BoxDecoration(
          //     color: Colors.grey.shade100,
          //     borderRadius: BorderRadius.circular(12),
          //     border: Border.all(color: Colors.grey.shade300),
          //   ),
          //   child: Column(
          //     crossAxisAlignment: CrossAxisAlignment.start,
          //     children: _logs.isEmpty
          //         ? const [Text('No events yet')]
          //         : _logs
          //               .map(
          //                 (e) => Padding(
          //                   padding: const EdgeInsets.only(bottom: 6),
          //                   child: Text('• $e'),
          //                 ),
          //               )
          //               .toList(),
          //   ),
          // ),
        ],
      ),
    );
  }
}
