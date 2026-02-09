import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:record/record.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class SpeechRecognitionResult {
  final String transcript;
  final double confidence;
  final Map<String, double> wordConfidences;
  final Duration audioDuration;

  const SpeechRecognitionResult({
    required this.transcript,
    required this.confidence,
    required this.wordConfidences,
    required this.audioDuration,
  });

  factory SpeechRecognitionResult.fromJson(Map<String, dynamic> json) {
    final results = json['results'] as List<dynamic>? ?? [];
    if (results.isEmpty) {
      return const SpeechRecognitionResult(
        transcript: '',
        confidence: 0.0,
        wordConfidences: {},
        audioDuration: Duration.zero,
      );
    }

    final firstResult = results[0] as Map<String, dynamic>;
    final alternatives = firstResult['alternatives'] as List<dynamic>? ?? [];

    if (alternatives.isEmpty) {
      return const SpeechRecognitionResult(
        transcript: '',
        confidence: 0.0,
        wordConfidences: {},
        audioDuration: Duration.zero,
      );
    }

    final alternative = alternatives[0] as Map<String, dynamic>;
    final transcript = alternative['transcript'] as String? ?? '';
    final confidence = (alternative['confidence'] as num?)?.toDouble() ?? 0.0;

    // Extract word-level confidences
    final wordConfidences = <String, double>{};
    final words = alternative['words'] as List<dynamic>? ?? [];

    for (final wordData in words) {
      final word = (wordData['word'] as String?)?.toLowerCase() ?? '';
      final wordConfidence =
          (wordData['confidence'] as num?)?.toDouble() ?? 0.0;
      if (word.isNotEmpty) {
        wordConfidences[word] = wordConfidence;
      }
    }

    // Calculate audio duration from last word end time
    Duration audioDuration = Duration.zero;
    if (words.isNotEmpty) {
      final lastWord = words.last as Map<String, dynamic>;
      final endTimeStr = lastWord['endTime'] as String?;
      if (endTimeStr != null) {
        // endTime format: "10.500s"
        final seconds = double.tryParse(endTimeStr.replaceAll('s', '')) ?? 0.0;
        audioDuration = Duration(milliseconds: (seconds * 1000).round());
      }
    }

    return SpeechRecognitionResult(
      transcript: transcript,
      confidence: confidence,
      wordConfidences: wordConfidences,
      audioDuration: audioDuration,
    );
  }
}

class GoogleCloudSpeechService {
  GoogleCloudSpeechService._();
  static final GoogleCloudSpeechService instance = GoogleCloudSpeechService._();

  final AudioRecorder _recorder = AudioRecorder();
  static const Duration _maxRecordingDuration = Duration(seconds: 10);
  String? _currentRecordingPath;

  Future<bool> requestMicrophonePermission() async {
    final status = await Permission.microphone.request();
    return status.isGranted;
  }

  Future<String> startRecording() async {
    final hasPermission = await requestMicrophonePermission();
    if (!hasPermission) {
      throw Exception('Microphone permission denied');
    }

    final tempDir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final path = '${tempDir.path}/recording_$timestamp.wav';

    final config = RecordConfig(
      encoder: AudioEncoder.wav,
      sampleRate: 16000,
      numChannels: 1,
      bitRate: 256000,
    );

    await _recorder.start(config, path: path);
    _currentRecordingPath = path;

    // Auto-stop after max duration
    Future.delayed(_maxRecordingDuration, () async {
      if (await _recorder.isRecording()) {
        await stopRecording();
      }
    });

    return path;
  }

  Future<String?> stopRecording() async {
    try {
      final path = await _recorder.stop();
      return path ?? _currentRecordingPath;
    } catch (e) {
      return _currentRecordingPath;
    }
  }

  Future<bool> isRecording() async {
    return await _recorder.isRecording();
  }

  Future<SpeechRecognitionResult> recognizeSpeech({
    required String audioFilePath,
    String languageCode = 'en-US',
  }) async {
    final apiKey = dotenv.env['GOOGLE_CLOUD_API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('GOOGLE_CLOUD_API_KEY not found in .env file');
    }

    final audioFile = File(audioFilePath);
    if (!await audioFile.exists()) {
      throw Exception('Audio file not found: $audioFilePath');
    }

    // Read and encode audio file as base64
    final audioBytes = await audioFile.readAsBytes();
    final audioBase64 = base64Encode(audioBytes);

    // Build API request
    final url = Uri.parse(
      'https://speech.googleapis.com/v1/speech:recognize?key=$apiKey',
    );

    final requestBody = {
      'config': {
        'encoding': 'LINEAR16',
        'sampleRateHertz': 16000,
        'languageCode': languageCode,
        'enableWordTimeOffsets': true,
        'enableWordConfidence': true,
        'enableAutomaticPunctuation': true,
        'model': 'default',
      },
      'audio': {'content': audioBase64},
    };

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(requestBody),
          )
          .timeout(const Duration(seconds: 30));

      if (response.statusCode != 200) {
        throw Exception(
          'Speech API error: ${response.statusCode} - ${response.body}',
        );
      }

      final responseData = jsonDecode(response.body) as Map<String, dynamic>;
      final result = SpeechRecognitionResult.fromJson(responseData);

      // Clean up audio file after successful recognition
      await _deleteAudioFile(audioFilePath);

      return result;
    } catch (e) {
      // Try to clean up even on error
      await _deleteAudioFile(audioFilePath);
      rethrow;
    }
  }

  Future<void> _deleteAudioFile(String path) async {
    try {
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }
    } catch (e) {
      // Ignore deletion errors
    }
  }

  Future<void> cancelRecording() async {
    try {
      await _recorder.stop();
      if (_currentRecordingPath != null) {
        await _deleteAudioFile(_currentRecordingPath!);
        _currentRecordingPath = null;
      }
    } catch (e) {
      // Ignore cancellation errors
    }
  }

  void dispose() {
    _recorder.dispose();
  }
}
