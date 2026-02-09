import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/word_error.dart';
import '../models/pronunciation_feedback.dart';

class GeminiAnalysisResult {
  final int overallScore;
  final double bandScore;
  final List<WordError> wordErrors;
  final PronunciationFeedback feedback;

  const GeminiAnalysisResult({
    required this.overallScore,
    required this.bandScore,
    required this.wordErrors,
    required this.feedback,
  });

  factory GeminiAnalysisResult.fromJson(Map<String, dynamic> json) {
    final wordErrorsRaw = json['wordErrors'] as List<dynamic>? ?? [];
    final wordErrors = wordErrorsRaw
        .map((e) => WordError.fromJson(e as Map<String, dynamic>))
        .toList();

    final feedback = PronunciationFeedback.fromJson(json);

    return GeminiAnalysisResult(
      overallScore: json['overallScore'] as int,
      bandScore: (json['bandScore'] as num).toDouble(),
      wordErrors: wordErrors,
      feedback: feedback,
    );
  }
}

class SpeakingGeminiService {
  SpeakingGeminiService._();
  static final SpeakingGeminiService instance = SpeakingGeminiService._();

  static const Duration _timeout = Duration(seconds: 10);

  Future<GeminiAnalysisResult> analyzeTranscript({
    required String targetSentence,
    required String userTranscript,
    required Map<String, double> confidenceScores,
  }) async {
    final apiKey = dotenv.env['API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API_KEY not found in .env file');
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent?key=$apiKey',
    );

    final prompt = _buildPrompt(
      targetSentence: targetSentence,
      userTranscript: userTranscript,
      confidenceScores: confidenceScores,
    );

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt},
                  ],
                },
              ],
            }),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        throw Exception(
          'Gemini API failed: ${response.statusCode} ${response.body}',
        );
      }

      final data = jsonDecode(response.body);
      String rawText = data['candidates'][0]['content']['parts'][0]['text'];

      // Remove markdown code blocks if present
      rawText = rawText.replaceAll('```json', '').replaceAll('```', '').trim();

      final decoded = jsonDecode(rawText) as Map<String, dynamic>;
      return GeminiAnalysisResult.fromJson(decoded);
    } catch (e) {
      throw Exception('Failed to analyze transcript: $e');
    }
  }

  Future<String> generateTargetSentence({
    required String category,
    String difficulty = 'intermediate',
  }) async {
    final apiKey = dotenv.env['API_KEY'];
    if (apiKey == null || apiKey.isEmpty) {
      throw Exception('API_KEY not found in .env file');
    }

    final url = Uri.parse(
      'https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent?key=$apiKey',
    );

    final prompt =
        '''
You are an IELTS speaking coach. Generate a practice sentence for pronunciation training.

Category: $category
Difficulty: $difficulty

Requirements:
- Natural English sentence
- 8-15 words
- Include common pronunciation challenges
- Appropriate for IELTS speaking practice

Return ONLY a JSON object:
{
  "sentence": "the practice sentence",
  "ipa": "IPA transcription",
  "translation": "Bản dịch tiếng Việt"
}
''';

    try {
      final response = await http
          .post(
            url,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'contents': [
                {
                  'parts': [
                    {'text': prompt},
                  ],
                },
              ],
            }),
          )
          .timeout(_timeout);

      if (response.statusCode != 200) {
        throw Exception(
          'Gemini API failed: ${response.statusCode} ${response.body}',
        );
      }

      final data = jsonDecode(response.body);
      String rawText = data['candidates'][0]['content']['parts'][0]['text'];

      rawText = rawText.replaceAll('```json', '').replaceAll('```', '').trim();

      final decoded = jsonDecode(rawText) as Map<String, dynamic>;
      return decoded['sentence'] as String;
    } catch (e) {
      throw Exception('Failed to generate sentence: $e');
    }
  }

  String _buildPrompt({
    required String targetSentence,
    required String userTranscript,
    required Map<String, double> confidenceScores,
  }) {
    final confScoresStr = confidenceScores.entries
        .map((e) => '${e.key}: ${e.value.toStringAsFixed(2)}')
        .join(', ');

    return '''
You are an IELTS pronunciation coach with expertise in phonetics and accent analysis. Analyze this speaking performance with detailed error detection.

Target sentence: "$targetSentence"
User transcript: "$userTranscript"
STT confidence scores: {$confScoresStr}

Analyze pronunciation quality and return a JSON object with this exact structure:
{
  "overallScore": 0-100 integer,
  "bandScore": 1.0-9.0 float (IELTS band),
  "wordErrors": [
    {
      "word": "specific word with error",
      "position": word position in sentence (0-indexed),
      "errorType": "stress" | "vowel" | "consonant" | "omission" | "insertion" | "substitution",
      "severity": 1-10 integer (10 = most severe),
      "expectedIPA": "correct IPA pronunciation",
      "actualIPA": "likely user's pronunciation",
      "tip": "specific actionable tip in English"
    }
  ],
  "feedbackVN": "Overall feedback summary in Vietnamese (2-3 sentences)",
  "feedbackEN": "Overall feedback summary in English (2-3 sentences)",
  "tipsVN": ["Tip 1 in Vietnamese", "Tip 2 in Vietnamese", "Tip 3 in Vietnamese"],
  "tipsEN": ["Tip 1 in English", "Tip 2 in English", "Tip 3 in English"],
  "nextStepsVN": "Recommended next practice focus in Vietnamese",
  "nextStepsEN": "Recommended next practice focus in English",
  "improvementFocus": ["errorType1", "errorType2"] // top 2-3 error types to focus on
}

Scoring guidelines:
- Use hybrid approach: STT confidence < 0.7 indicates potential error
- Compare semantic similarity and phonetic accuracy
- Missing words = omission errors
- Extra words = insertion errors
- Different words = substitution errors
- Band score conversion: 90-100 = 8.0-9.0, 75-89 = 6.5-7.5, 60-74 = 5.5-6.0, 40-59 = 4.5-5.0, below 40 = below 4.5

Provide constructive, encouraging feedback in both Vietnamese and English. Focus on the top 3-5 most impactful errors.

Return ONLY the JSON object, no additional text.
''';
  }
}
