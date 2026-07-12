import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

// ─── Result models ───────────────────────────────────────────────────────────

class AzurePhonemeResult {
  final String phoneme;
  final double accuracyScore;

  const AzurePhonemeResult({
    required this.phoneme,
    required this.accuracyScore,
  });
}

class AzureWordResult {
  final String word;
  final double accuracyScore;
  // "None" | "Mispronunciation" | "Omission" | "Insertion"
  final String errorType;
  final List<AzurePhonemeResult> phonemes;

  const AzureWordResult({
    required this.word,
    required this.accuracyScore,
    required this.errorType,
    required this.phonemes,
  });

  bool get hasError => errorType != 'None' || accuracyScore < 70;
}

class AzurePronunciationResult {
  final String transcript;
  final double pronunciationScore; // overall (PronScore) 0–100
  final double accuracyScore;
  final double fluencyScore;
  final double completenessScore; // 0 when no referenceText
  final double prosodyScore; // 0 when API doesn't return it
  final List<AzureWordResult> words;
  final Duration audioDuration;

  const AzurePronunciationResult({
    required this.transcript,
    required this.pronunciationScore,
    required this.accuracyScore,
    required this.fluencyScore,
    required this.completenessScore,
    required this.prosodyScore,
    required this.words,
    required this.audioDuration,
  });

  factory AzurePronunciationResult.empty() => const AzurePronunciationResult(
    transcript: '',
    pronunciationScore: 0,
    accuracyScore: 0,
    fluencyScore: 0,
    completenessScore: 0,
    prosodyScore: 0,
    words: [],
    audioDuration: Duration.zero,
  );

  factory AzurePronunciationResult.fromJson(Map<String, dynamic> json) {
    final status = json['RecognitionStatus'] as String? ?? '';
    if (status != 'Success') return AzurePronunciationResult.empty();

    final nBest = json['NBest'] as List<dynamic>?;
    if (nBest == null || nBest.isEmpty) return AzurePronunciationResult.empty();

    final best = nBest[0] as Map<String, dynamic>;
    // Azure REST API puts scores directly on the NBest object,
    // not inside a "PronunciationAssessment" sub-object.
    final pron = best['PronunciationAssessment'] as Map<String, dynamic>? ?? best;

    final transcript =
        best['Display'] as String? ??
        best['ITN'] as String? ??
        best['Lexical'] as String? ??
        '';

    final rawWords = best['Words'] as List<dynamic>? ?? [];
    final words = rawWords.map((w) {
      final wMap = w as Map<String, dynamic>;
      final wPron =
          wMap['PronunciationAssessment'] as Map<String, dynamic>? ?? wMap;
      final rawPhonemes = wMap['Phonemes'] as List<dynamic>? ?? [];
      final phonemes = rawPhonemes.map((p) {
        final pMap = p as Map<String, dynamic>;
        final pPron =
            pMap['PronunciationAssessment'] as Map<String, dynamic>? ?? pMap;
        return AzurePhonemeResult(
          phoneme: pMap['Phoneme'] as String? ?? '',
          accuracyScore: (pPron['AccuracyScore'] as num?)?.toDouble() ?? 0.0,
        );
      }).toList();

      return AzureWordResult(
        word: (wMap['Word'] as String? ?? '').toLowerCase(),
        accuracyScore: (wPron['AccuracyScore'] as num?)?.toDouble() ?? 0.0,
        errorType: wPron['ErrorType'] as String? ?? 'None',
        phonemes: phonemes,
      );
    }).toList();

    // Audio duration from last word offset + duration (Azure uses 100ns ticks)
    Duration audioDuration = Duration.zero;
    if (rawWords.isNotEmpty) {
      final last = rawWords.last as Map<String, dynamic>;
      final offset = (last['Offset'] as num?)?.toInt() ?? 0;
      final dur = (last['Duration'] as num?)?.toInt() ?? 0;
      audioDuration = Duration(microseconds: ((offset + dur) / 10).round());
    }

    return AzurePronunciationResult(
      transcript: transcript,
      pronunciationScore: (pron['PronScore'] as num?)?.toDouble()
          ?? (pron['AccuracyScore'] as num?)?.toDouble()
          ?? 0.0,
      accuracyScore: (pron['AccuracyScore'] as num?)?.toDouble() ?? 0.0,
      fluencyScore: (pron['FluencyScore'] as num?)?.toDouble() ?? 0.0,
      completenessScore:
          (pron['CompletenessScore'] as num?)?.toDouble() ?? 0.0,
      prosodyScore: (pron['ProsodyScore'] as num?)?.toDouble() ?? 0.0,
      words: words,
      audioDuration: audioDuration,
    );
  }

  /// Maps an Azure score (0–100) to IELTS band (1.0–9.0, 0.5 increments).
  static double scoreToIeltsBand(double azureScore) {
    if (azureScore >= 90) return 9.0;
    if (azureScore >= 82) return 8.5;
    if (azureScore >= 75) return 8.0;
    if (azureScore >= 67) return 7.5;
    if (azureScore >= 60) return 7.0;
    if (azureScore >= 53) return 6.5;
    if (azureScore >= 47) return 6.0;
    if (azureScore >= 41) return 5.5;
    if (azureScore >= 35) return 5.0;
    if (azureScore >= 30) return 4.5;
    return 4.0;
  }
}

// ─── Service ─────────────────────────────────────────────────────────────────

class AzurePronunciationService {
  AzurePronunciationService._();
  static final AzurePronunciationService instance =
      AzurePronunciationService._();

  AudioRecorder _recorder = AudioRecorder();
  static const Duration _maxRecordingDuration = Duration(seconds: 10);
  String? _currentRecordingPath;
  String? _lastRecordingPath;

  String? get lastRecordingPath => _lastRecordingPath;

  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<String> startRecording() async {
    final hasPermission = await requestMicrophonePermission();
    if (!hasPermission) throw Exception('Microphone permission denied');

    // Clean up previous recording
    if (_lastRecordingPath != null) {
      await _deleteAudioFile(_lastRecordingPath!);
      _lastRecordingPath = null;
    }

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${tempDir.path}/recording_$timestamp.wav';

    await _recorder.start(
      const RecordConfig(
        encoder: AudioEncoder.wav,
        sampleRate: 16000,
        numChannels: 1,
        bitRate: 256000,
      ),
      path: path,
    );
    _currentRecordingPath = path;

    Future.delayed(_maxRecordingDuration, () async {
      if (await _recorder.isRecording()) await stopRecording();
    });

    return path;
  }

  Future<String?> stopRecording() async {
    try {
      final path = await _recorder.stop();
      return path ?? _currentRecordingPath;
    } catch (_) {
      return _currentRecordingPath;
    }
  }

  Future<bool> isRecording() => _recorder.isRecording();

  /// Send audio to Azure Cognitive Services Pronunciation Assessment.
  ///
  /// [referenceText] — the sentence the learner should have said.
  ///   When provided: Azure returns per-word accuracy + completeness scores.
  ///   When null/empty: Azure transcribes freely and returns fluency + pronunciation scores.
  Future<AzurePronunciationResult> assessPronunciation({
    required String audioPath,
    String? referenceText,
    String language = 'en-US',
  }) async {
    final apiKey = dotenv.env['AZURE_SPEECH_KEY'];
    final region = dotenv.env['AZURE_SPEECH_REGION'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('AZURE_SPEECH_KEY not found in .env');
    }
    if (region == null || region.isEmpty) {
      throw Exception('AZURE_SPEECH_REGION not found in .env');
    }

    final audioFile = File(audioPath);
    if (!await audioFile.exists()) {
      throw Exception('Audio file not found: $audioPath');
    }
    final audioBytes = await audioFile.readAsBytes();
    final sampleRate = _readWavSampleRate(audioBytes);
    debugPrint('[Azure] Audio file size: ${audioBytes.length} bytes (${(audioBytes.length / 1024).toStringAsFixed(1)} KB)');
    debugPrint('[Azure] WAV sample rate from header: $sampleRate Hz');

    final hasRef = referenceText != null && referenceText.isNotEmpty;
    final assessmentConfig = jsonEncode({
      'ReferenceText': referenceText ?? '',
      'GradingSystem': 'HundredMark',
      'Granularity': 'Phoneme',
      'Dimension': 'Comprehensive',
      'EnableProsodyAssessment': true,
      if (hasRef) 'EnableMiscue': true,
    });
    final assessmentHeader = base64Encode(utf8.encode(assessmentConfig));

    final url = Uri.parse(
      'https://$region.stt.speech.microsoft.com/speech/recognition/conversation'
      '/cognitiveservices/v1?language=$language&format=detailed&profanity=Masked',
    );

    try {
      final response = await http
          .post(
            url,
            headers: {
              'Ocp-Apim-Subscription-Key': apiKey,
              'Content-Type': 'audio/wav; codecs=audio/pcm; samplerate=$sampleRate',
              'Pronunciation-Assessment': assessmentHeader,
            },
            body: audioBytes,
          )
          .timeout(const Duration(seconds: 30));

      debugPrint('[Azure] Response status: ${response.statusCode}');
      debugPrint('[Azure] Response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception(
          'Azure Speech API error: ${response.statusCode} — ${response.body}',
        );
      }

      final data = jsonDecode(response.body) as Map<String, dynamic>;
      final recognitionStatus = data['RecognitionStatus'] as String? ?? 'Unknown';
      debugPrint('[Azure] RecognitionStatus: $recognitionStatus');

      // Keep audio file for playback debugging
      _lastRecordingPath = audioPath;

      final result = AzurePronunciationResult.fromJson(data);
      debugPrint('[Azure] Scores — Pron: ${result.pronunciationScore}, '
          'Accuracy: ${result.accuracyScore}, Fluency: ${result.fluencyScore}, '
          'Completeness: ${result.completenessScore}');
      debugPrint('[Azure] Transcript: "${result.transcript}"');
      return result;
    } catch (e) {
      // Still keep audio file for debugging on error
      _lastRecordingPath = audioPath;
      rethrow;
    }
  }

  Future<void> cancelRecording() async {
    try {
      await _recorder.stop();
      if (_currentRecordingPath != null) {
        await _deleteAudioFile(_currentRecordingPath!);
        _currentRecordingPath = null;
      }
    } catch (_) {}
  }

  void dispose() {
    _recorder.dispose();
    _recorder = AudioRecorder();
  }

  /// Read the actual sample rate from the WAV file header.
  /// Falls back to 16000 if the header can't be parsed.
  int _readWavSampleRate(List<int> bytes) {
    if (bytes.length < 28) return 16000;
    // Verify RIFF header
    if (bytes[0] != 0x52 || bytes[1] != 0x49 ||
        bytes[2] != 0x46 || bytes[3] != 0x46) return 16000;
    // Sample rate is at byte offset 24, little-endian uint32
    final rate = bytes[24] | (bytes[25] << 8) | (bytes[26] << 16) | (bytes[27] << 24);
    return rate > 0 ? rate : 16000;
  }

  /// Record device mic while TTS speaks [sentence] through the speaker, then
  /// send the captured audio to Azure. This tests the full pipeline: mic →
  /// WAV file → Azure API.  If TTS scores high but your voice scores 0, the
  /// issue is pronunciation.  If TTS also scores 0, the recording format or
  /// API config is wrong.
  Future<AzurePronunciationResult> testWithTtsAudio({
    required String sentence,
    String language = 'en-US',
  }) async {
    final tts = FlutterTts();
    await tts.setLanguage(language);
    await tts.setSpeechRate(0.5);
    await tts.setVolume(1.0);

    // 1. Start recording via the same pipeline as normal recording
    debugPrint('[TTS Test] Starting mic recording + TTS playback for: "$sentence"');
    final recordingPath = await startRecording();

    // 2. Small delay so the recorder is ready before TTS starts
    await Future.delayed(const Duration(milliseconds: 300));

    // 3. Speak through speaker while mic records
    final ttsCompleter = Completer<void>();
    tts.setCompletionHandler(() {
      if (!ttsCompleter.isCompleted) ttsCompleter.complete();
    });
    await tts.speak(sentence);

    // 4. Wait for TTS to finish speaking
    await ttsCompleter.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () => debugPrint('[TTS Test] TTS playback timed out'),
    );

    // 5. Small tail so the last syllable is fully captured
    await Future.delayed(const Duration(milliseconds: 500));

    // 6. Stop recording
    final path = await stopRecording();
    final audioPath = path ?? recordingPath;
    debugPrint('[TTS Test] Recording saved to: $audioPath');

    // 7. Send to Azure
    final result = await assessPronunciation(
      audioPath: audioPath,
      referenceText: sentence,
      language: language,
    );

    debugPrint('[TTS Test] Score: ${result.pronunciationScore}/100');
    await tts.stop();
    return result;
  }

  Future<void> _deleteAudioFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) await file.delete();
    } catch (_) {}
  }
}
