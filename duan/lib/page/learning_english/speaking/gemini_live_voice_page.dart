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

class _GeminiLiveVoicePageState extends State<GeminiLiveVoicePage>
    with SingleTickerProviderStateMixin {
  // Colors (match the other Speaking modes' theme)
  static const Color accent = Color(0xFF673AB7); // deep purple — this mode's
  // signature color on the Speaking hub (see speaking_page.dart mode card)
  static const Color accentLight = Color(0xFF9575CD);
  static const Color bgColor = Color(0xFFF6FAFF);
  static const Color textGrey = Color(0xFF607D8B);

  // Gemini Live streams 24kHz mono PCM16 audio; play back at that native
  // rate so no resampling is needed.
  static const int _pcmSampleRate = 24000;
  // Buffer this many bytes (~150ms) before starting playback, so the native
  // audio track doesn't start on a near-empty queue and underrun/click.
  static const int _jitterBufferBytes = (_pcmSampleRate * 2 * 150) ~/ 1000;
  // Extra pad added on top of the computed playback duration before we
  // re-open the mic, to cover speaker/room decay after the last sample.
  static const Duration _micResumePad = Duration(milliseconds: 250);
  static const int _maxSeconds = 180;

  final GeminiRealtimeService _service = GeminiRealtimeService();
  StreamSubscription<GeminiEvent>? _sub;
  bool _pcmReady = false;
  bool _pcmPlaying = false;
  bool _pcmResetting = false;
  int _pendingBytesBeforeStart = 0;

  // Bytes fed to the player for the turn currently playing/queued, and when
  // the first byte of it was fed — used to compute exactly how long local
  // playback will take, so the mic is only re-opened once the AI's audio
  // has actually finished coming out of the speaker (see _scheduleMicResume).
  int _bytesQueuedThisTurn = 0;
  DateTime? _turnAudioStartedAt;
  Timer? _resumeMicTimer;

  // Ignore any audio_chunk tagged with a turn id below this floor — set
  // past the current turn on manual interrupt so trailing chunks from the
  // abandoned turn don't get played after the user cut it off.
  int _acceptedFromTurn = 0;

  GeminiMode _mode = GeminiMode.aiSpeaksFirst;
  final TextEditingController _topicController = TextEditingController(
    text: 'Travel',
  );
  bool _busy = false;
  bool _started = false;

  int _timerSeconds = _maxSeconds;
  Timer? _countdownTimer;

  late final AnimationController _pulseCtrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);
  late final Animation<double> _pulse = Tween<double>(
    begin: 1.0,
    end: 1.12,
  ).animate(CurvedAnimation(parent: _pulseCtrl, curve: Curves.easeInOut));

  @override
  void initState() {
    super.initState();
    _initPcmOutput();
    _sub = _service.events.listen((event) async {
      if (!mounted) return;

      if (event.type == 'audio_chunk') {
        final chunk = event.data;
        if (chunk is GeminiAudioChunk && chunk.turn >= _acceptedFromTurn) {
          _turnAudioStartedAt ??= DateTime.now();
          _bytesQueuedThisTurn += chunk.bytes.lengthInBytes;
          final wasPlaying = _pcmPlaying;
          _playPcmChunk(chunk.bytes);
          if (_pcmPlaying != wasPlaying) setState(() {});
        }
        return;
      }

      if (event.type == 'interrupted') {
        _resumeMicTimer?.cancel();
        _bytesQueuedThisTurn = 0;
        _turnAudioStartedAt = null;
        await _resetPcmBuffer();
      }
      if (!mounted) return;

      setState(() {
        if (event.type == 'turn_complete') {
          _flushPendingAudioIfAny();
          _pcmPlaying = false;
          _pendingBytesBeforeStart = 0;
          _scheduleMicResume();
        } else if (event.type == 'interrupted') {
          _pcmPlaying = false;
          _pendingBytesBeforeStart = 0;
        } else if (event.type == 'connection_closed') {
          _countdownTimer?.cancel();
          _started = false;
          _busy = false;
        } else if (event.type == 'session_timeout' || event.type == 'stopped') {
          _countdownTimer?.cancel();
          _started = false;
          _busy = false;
        } else if (event.type == 'error') {
          _busy = false;
        }
      });
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _resumeMicTimer?.cancel();
    _pulseCtrl.dispose();
    _sub?.cancel();
    _service.dispose();
    _disposePcmOutput();
    _topicController.dispose();
    super.dispose();
  }

  Future<void> _initPcmOutput() async {
    try {
      await FlutterPcmSound.setLogLevel(LogLevel.none);
      await FlutterPcmSound.setup(
        sampleRate: _pcmSampleRate,
        channelCount: 1,
      );
      await FlutterPcmSound.setFeedThreshold(2400);
      _pcmReady = true;
    } catch (_) {
      _pcmReady = false;
    }
  }

  Future<void> _resetPcmBuffer() async {
    if (!_pcmReady || _pcmResetting) return;
    _pcmResetting = true;
    _pcmPlaying = false;
    _pendingBytesBeforeStart = 0;
    try {
      await FlutterPcmSound.release();
      await FlutterPcmSound.setup(
        sampleRate: _pcmSampleRate,
        channelCount: 1,
      );
      await FlutterPcmSound.setFeedThreshold(2400);
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
      // Hold off starting playback until enough audio is queued, so the
      // native audio track doesn't start on a near-empty buffer and click.
      _pendingBytesBeforeStart += bytes.lengthInBytes;
      if (_pendingBytesBeforeStart < _jitterBufferBytes) return;
      FlutterPcmSound.start();
      _pcmPlaying = true;
    }
  }

  /// Very short AI replies can end (turn_complete) before enough bytes
  /// were queued to cross the jitter-buffer threshold in _playPcmChunk, so
  /// playback would never actually start. Force-start it here if that
  /// happened, otherwise the (short) reply would silently never be heard.
  void _flushPendingAudioIfAny() {
    if (!_pcmPlaying && _pendingBytesBeforeStart > 0) {
      FlutterPcmSound.start();
      _pcmPlaying = true;
    }
  }

  /// Re-opens the mic exactly when local playback of this turn's audio is
  /// expected to actually finish coming out of the speaker: bytes queued
  /// divided by bytes-per-second gives the playback duration, offset from
  /// when the first byte was fed, plus a safety pad.
  void _scheduleMicResume() {
    _resumeMicTimer?.cancel();
    final startedAt = _turnAudioStartedAt;
    final bytes = _bytesQueuedThisTurn;
    _bytesQueuedThisTurn = 0;
    _turnAudioStartedAt = null;
    if (startedAt == null || bytes == 0) {
      _service.resumeMic();
      return;
    }
    final playbackMs = (bytes / (_pcmSampleRate * 2)) * 1000;
    final deadline = startedAt
        .add(Duration(milliseconds: playbackMs.round()))
        .add(_micResumePad);
    final delay = deadline.difference(DateTime.now());
    if (delay.isNegative) {
      _service.resumeMic();
    } else {
      _resumeMicTimer = Timer(delay, () {
        if (mounted) _service.resumeMic();
      });
    }
  }

  Future<void> _onInterruptPressed() async {
    _resumeMicTimer?.cancel();
    _bytesQueuedThisTurn = 0;
    _turnAudioStartedAt = null;
    // Reject any further chunks belonging to the turn being cut off — the
    // service keeps tagging them with the same (not-yet-closed) turn id
    // until the server formally ends it, so this floor is what actually
    // stops them from being played.
    final abandonedTurn = _service.currentTurn;
    _service.interrupt();
    await _resetPcmBuffer();
    if (!mounted) return;
    setState(() {
      _pcmPlaying = false;
      _acceptedFromTurn = abandonedTurn + 1;
    });
  }

  void _startCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _timerSeconds--);
      if (_timerSeconds <= 0) t.cancel();
    });
  }

  Future<void> _start() async {
    if (_busy) return;
    setState(() => _busy = true);
    _resumeMicTimer?.cancel();
    _bytesQueuedThisTurn = 0;
    _turnAudioStartedAt = null;
    _pendingBytesBeforeStart = 0;
    _pcmPlaying = false;
    _acceptedFromTurn = 0;
    try {
      await _service.initialize(
        mode: _mode,
        selectedTopic: _topicController.text.trim().isEmpty
            ? null
            : _topicController.text.trim(),
      );
      await _service.start(sessionSeconds: _maxSeconds);
      setState(() {
        _started = true;
        _busy = false;
        _timerSeconds = _maxSeconds;
      });
      _startCountdown();
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
            backgroundColor: Colors.red.shade700,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
          ),
        );
      }
    }
  }

  Future<void> _stop() async {
    _countdownTimer?.cancel();
    await _service.stop();
    if (!mounted) return;
    setState(() => _started = false);
  }

  String _formatTime(int seconds) {
    final s = seconds < 0 ? 0 : seconds;
    final m = (s ~/ 60).toString().padLeft(2, '0');
    final r = (s % 60).toString().padLeft(2, '0');
    return '$m:$r';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: accent,
        elevation: 0,
        title: _started
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Live Voice Companion',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  Text(
                    _formatTime(_timerSeconds),
                    style: TextStyle(
                      fontSize: 12,
                      color: _timerSeconds < 30 ? Colors.red : textGrey,
                    ),
                  ),
                ],
              )
            : const Text(
                'Live Voice Companion',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
        actions: [
          if (_started)
            IconButton(
              icon: const Icon(Icons.call_end, color: Colors.red),
              tooltip: 'End session',
              onPressed: _stop,
            ),
        ],
      ),
      body: _started ? _buildSession() : _buildSetup(),
    );
  }

  // ── Setup screen ────────────────────────────────────────────────
  Widget _buildSetup() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [accentLight, accent],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(0.3),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.graphic_eq,
                  color: Colors.white,
                  size: 28,
                ),
              ),
              const SizedBox(width: 16),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Real-time Voice Chat',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'A free-flowing spoken conversation with Gemini',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Topic',
                style: TextStyle(fontWeight: FontWeight.w600, color: accent),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _topicController,
                decoration: InputDecoration(
                  hintText: 'e.g. Travel, Technology, Food...',
                  filled: true,
                  fillColor: Colors.grey.shade50,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.fromLTRB(18, 10, 18, 0),
                child: Text(
                  'Conversation mode',
                  style: TextStyle(fontWeight: FontWeight.w600, color: accent),
                ),
              ),
              RadioListTile<GeminiMode>(
                value: GeminiMode.aiSpeaksFirst,
                groupValue: _mode,
                activeColor: accent,
                title: const Text('AI speaks first'),
                subtitle: const Text(
                  'Start with an opening sentence about the topic',
                ),
                onChanged: (value) => setState(() => _mode = value!),
              ),
              RadioListTile<GeminiMode>(
                value: GeminiMode.userSpeaksFirst,
                groupValue: _mode,
                activeColor: accent,
                title: const Text('User speaks first'),
                subtitle: const Text('Wait until the user starts speaking'),
                onChanged: (value) => setState(() => _mode = value!),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _busy ? null : _start,
            icon: _busy
                ? const SizedBox(
                    height: 18,
                    width: 18,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: Colors.white,
                    ),
                  )
                : const Icon(Icons.mic),
            label: Text(_busy ? 'Connecting...' : 'Start session'),
            style: ElevatedButton.styleFrom(
              backgroundColor: accent,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  // ── Live session screen ─────────────────────────────────────────
  Widget _buildSession() {
    return Column(
      children: [
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: LinearProgressIndicator(
            value: (_timerSeconds / _maxSeconds).clamp(0.0, 1.0),
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(
              _timerSeconds < 30 ? Colors.red : accent,
            ),
            borderRadius: BorderRadius.circular(4),
            minHeight: 5,
          ),
        ),
        Expanded(
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AnimatedBuilder(
                  animation: _pulse,
                  builder: (_, child) => Transform.scale(
                    scale: _pulse.value,
                    child: child,
                  ),
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: _pcmPlaying ? accent : Colors.white,
                      border: _pcmPlaying
                          ? null
                          : Border.all(color: accent, width: 3),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withOpacity(0.3),
                          blurRadius: 24,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Icon(
                      _pcmPlaying ? Icons.volume_up : Icons.mic,
                      color: _pcmPlaying ? Colors.white : accent,
                      size: 56,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  _pcmPlaying
                      ? 'AI is speaking...'
                      : 'Listening — speak naturally',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: _pcmPlaying ? accent : textGrey,
                  ),
                ),
              ],
            ),
          ),
        ),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: _pcmPlaying
          ? Row(
              children: [
                const Icon(Icons.graphic_eq, color: accent),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'AI is speaking',
                    style: TextStyle(color: accent, fontWeight: FontWeight.w600),
                  ),
                ),
                TextButton.icon(
                  onPressed: _onInterruptPressed,
                  icon: const Icon(Icons.pan_tool_alt, color: Colors.red),
                  label: const Text(
                    'Interrupt',
                    style: TextStyle(color: Colors.red),
                  ),
                ),
              ],
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.hearing, color: textGrey, size: 18),
                SizedBox(width: 8),
                Text(
                  'Just talk — jump in anytime',
                  style: TextStyle(color: textGrey, fontSize: 13),
                ),
              ],
            ),
    );
  }
}
