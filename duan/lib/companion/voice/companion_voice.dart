import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Service gom TTS (đọc to câu trả lời) + STT (voice input).
/// Web + Android đều được hỗ trợ qua `flutter_tts` + `speech_to_text`.
///
/// Lưu ý Web:
/// - Cần HTTPS hoặc localhost để STT hoạt động (Chrome policy).
/// - TTS dùng Web Speech Synthesis API.
///
/// Lưu ý Android:
/// - Cần permission `RECORD_AUDIO` trong AndroidManifest.xml cho STT.
class CompanionVoice extends ChangeNotifier {
  CompanionVoice._();
  static final CompanionVoice instance = CompanionVoice._();

  final FlutterTts _tts = FlutterTts();
  final stt.SpeechToText _stt = stt.SpeechToText();

  bool _ttsReady = false;
  bool _sttAvailable = false;
  bool _isSpeaking = false;
  bool _isListening = false;
  String _lastRecognized = "";
  String? _sttLocale; // "vi_VN" | "en_US" v.v.
  List<Map<String, String>> _availableVoices = [];
  Map<String, String>? _selectedVoice;

  // getters
  bool get isSpeaking => _isSpeaking;
  bool get isListening => _isListening;
  bool get sttAvailable => _sttAvailable;
  String get lastRecognized => _lastRecognized;
  List<Map<String, String>> get availableVoices =>
      List.unmodifiable(_availableVoices);
  Map<String, String>? get selectedVoice => _selectedVoice;

  // ---------------- INIT ----------------
  Future<void> ensureInit() async {
    if (!_ttsReady) {
      try {
        await _tts.setLanguage("vi-VN");

        // Enumerate voices + auto pick best vi-VN voice available
        await _pickBestVietnameseVoice();

        // Tuning cho tự nhiên hơn:
        // - rate 0.5 là baseline "normal" cho vi-VN; chậm hơn nghe robotic
        // - pitch 1.0 giữ chất giọng gốc (tăng lên sẽ the thé)
        // - volume 1.0 max
        await _tts.setSpeechRate(0.5);
        await _tts.setPitch(1.0);
        try {
          await _tts.setVolume(1.0);
        } catch (_) {}

        await _tts.awaitSpeakCompletion(true);
        _tts.setStartHandler(() {
          _isSpeaking = true;
          notifyListeners();
        });
        _tts.setCompletionHandler(() {
          _isSpeaking = false;
          notifyListeners();
        });
        _tts.setCancelHandler(() {
          _isSpeaking = false;
          notifyListeners();
        });
        _tts.setErrorHandler((msg) {
          _isSpeaking = false;
          notifyListeners();
        });
        _ttsReady = true;
      } catch (e) {
        debugPrint("[CompanionVoice] TTS init error: $e");
      }
    }

    if (!_sttAvailable) {
      try {
        _sttAvailable = await _stt.initialize(
          onStatus: (s) {
            _isListening = s == "listening";
            notifyListeners();
          },
          onError: (e) {
            debugPrint("[CompanionVoice] STT error: ${e.errorMsg}");
            _isListening = false;
            notifyListeners();
          },
        );
        if (_sttAvailable) {
          // Auto-detect locale ưu tiên Vietnamese nếu có
          final locales = await _stt.locales();
          final vi = locales.firstWhere(
            (l) => l.localeId.toLowerCase().startsWith("vi"),
            orElse: () => locales.isNotEmpty
                ? locales.first
                : stt.LocaleName("en_US", "English (US)"),
          );
          _sttLocale = vi.localeId;
        }
      } catch (e) {
        debugPrint("[CompanionVoice] STT init error: $e");
      }
    }
  }

  // ---------------- VOICE SELECTION ----------------

  /// Enumerate hết voices của engine (Windows SAPI / Chrome speechSynthesis /
  /// Android TTS), lọc ra vi-VN, rồi auto pick giọng tốt nhất có thể.
  ///
  /// Rank (cao → thấp):
  ///   1. Google tiếng Việt / Vietnamese (Google) — neural, rất tự nhiên
  ///   2. Bất kỳ voice nào có "natural" / "neural" trong tên
  ///   3. Microsoft Hoai Nhan / HoaiMy Online / An Online — neural Azure (mới)
  ///   4. Microsoft An / Hoai My Desktop — local (hơi robotic)
  ///   5. Bất kỳ voice vi-VN khác
  Future<void> _pickBestVietnameseVoice() async {
    try {
      final raw = await _tts.getVoices;
      if (raw is! List) return;

      final all = <Map<String, String>>[];
      for (final v in raw) {
        if (v is Map) {
          final name = (v['name'] ?? '').toString();
          final locale = (v['locale'] ?? v['language'] ?? '').toString();
          if (name.isEmpty) continue;
          all.add({'name': name, 'locale': locale});
        }
      }

      // Lọc vi-VN
      final vi = all.where((v) {
        final locale = v['locale']!.toLowerCase();
        final name = v['name']!.toLowerCase();
        return locale.startsWith('vi') ||
            name.contains('vietnam') ||
            name.contains('tiếng việt') ||
            name.contains('tieng viet');
      }).toList();

      _availableVoices = vi;

      debugPrint(
        "[CompanionVoice] ${all.length} voices total, ${vi.length} vi-VN:",
      );
      for (final v in vi) {
        debugPrint("  - ${v['name']}  [${v['locale']}]");
      }

      if (vi.isEmpty) {
        debugPrint(
          "[CompanionVoice] ⚠ Không tìm thấy voice vi-VN nào — "
          "engine sẽ fallback về giọng mặc định (có thể sai ngữ điệu).",
        );
        return;
      }

      // Ranking bằng score
      int score(Map<String, String> v) {
        final n = v['name']!.toLowerCase();
        if (n.contains('google')) return 100;
        if (n.contains('neural') || n.contains('natural')) return 90;
        if (n.contains('online') && n.contains('microsoft')) return 80;
        if (n.contains('hoai nhan') ||
            n.contains('hoaimy') ||
            n.contains('hoai my') && n.contains('online')) {
          return 75;
        }
        if (n.contains('microsoft')) return 50;
        return 30;
      }

      vi.sort((a, b) => score(b).compareTo(score(a)));
      final best = vi.first;

      try {
        await _tts.setVoice({
          'name': best['name']!,
          'locale': best['locale']!,
        });
        _selectedVoice = best;
        debugPrint("[CompanionVoice] ✔ Picked voice: ${best['name']}");
      } catch (e) {
        debugPrint("[CompanionVoice] setVoice failed: $e");
      }
    } catch (e) {
      debugPrint("[CompanionVoice] getVoices error: $e");
    }
  }

  /// Cho phép UI set giọng thủ công khi user muốn đổi.
  Future<void> selectVoice(Map<String, String> voice) async {
    try {
      await _tts.setVoice({
        'name': voice['name'] ?? '',
        'locale': voice['locale'] ?? 'vi-VN',
      });
      _selectedVoice = voice;
      notifyListeners();
    } catch (e) {
      debugPrint("[CompanionVoice] selectVoice error: $e");
    }
  }

  // ---------------- TTS ----------------
  Future<void> speak(String text) async {
    if (text.trim().isEmpty) return;
    await ensureInit();
    if (_isSpeaking) {
      await stopSpeaking();
    }
    // Strip markdown nhẹ cho TTS đọc sạch hơn
    final clean = _stripMarkdown(text);
    try {
      await _tts.speak(clean);
    } catch (e) {
      debugPrint("[CompanionVoice] speak error: $e");
    }
  }

  Future<void> stopSpeaking() async {
    try {
      await _tts.stop();
    } catch (_) {}
    _isSpeaking = false;
    notifyListeners();
  }

  String _stripMarkdown(String s) {
    // Bỏ ** bold **, ``, #headers, *italic*, [links](url)
    return s
        .replaceAll(RegExp(r'\*\*(.*?)\*\*'), r'$1')
        .replaceAll(RegExp(r'\*(.*?)\*'), r'$1')
        .replaceAll(RegExp(r'`(.*?)`'), r'$1')
        .replaceAll(RegExp(r'^#+\s*', multiLine: true), '')
        .replaceAll(RegExp(r'\[([^\]]+)\]\([^)]+\)'), r'$1');
  }

  // ---------------- STT ----------------
  /// Bắt đầu ghi. Callback `onResult` nhận text tạm thời (partial) lẫn final.
  /// Gọi `stopListening()` để dừng. Trả `false` nếu không init được.
  Future<bool> startListening({
    required void Function(String text, bool isFinal) onResult,
  }) async {
    await ensureInit();
    if (!_sttAvailable) return false;
    if (_isListening) await stopListening();

    _lastRecognized = "";
    try {
      await _stt.listen(
        localeId: _sttLocale,
        listenOptions: stt.SpeechListenOptions(
          listenMode: stt.ListenMode.dictation,
          partialResults: true,
          cancelOnError: true,
        ),
        onResult: (result) {
          _lastRecognized = result.recognizedWords;
          notifyListeners();
          onResult(result.recognizedWords, result.finalResult);
        },
      );
      _isListening = true;
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint("[CompanionVoice] listen error: $e");
      return false;
    }
  }

  Future<void> stopListening() async {
    try {
      await _stt.stop();
    } catch (_) {}
    _isListening = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _tts.stop();
    _stt.cancel();
    super.dispose();
  }
}
