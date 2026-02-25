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

  // Generous timeouts — complex prompts can take 15-20 s on Gemini
  static const Duration _analyzeTimeout = Duration(seconds: 30);
  static const Duration _generateTimeout = Duration(seconds: 20);

  // ─── Retry helper: handles 429 RESOURCE_EXHAUSTED with exponential backoff ───
  Future<http.Response> _postWithRetry(
    Uri url,
    Map<String, String> headers,
    String body, {
    required Duration timeout,
    int maxRetries = 3,
  }) async {
    int attempt = 0;
    while (true) {
      final response = await http
          .post(url, headers: headers, body: body)
          .timeout(timeout);
      if (response.statusCode == 429 && attempt < maxRetries) {
        // Back-off: 2^attempt seconds (2s, 4s, 8s)
        await Future.delayed(Duration(seconds: 2 << attempt));
        attempt++;
        continue;
      }
      return response;
    }
  }

  Future<GeminiAnalysisResult> analyzeTranscript({
    required String targetSentence,
    required String userTranscript,
    required Map<String, double> confidenceScores,
    String category = 'Individual Sounds',
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
      category: category,
    );

    try {
      final response = await _postWithRetry(
        url,
        {'Content-Type': 'application/json'},
        jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
        }),
        timeout: _analyzeTimeout,
      );

      if (response.statusCode == 429) {
        throw Exception(
          'Gemini quota exceeded (429). Please wait a moment and try again.',
        );
      }
      if (response.statusCode != 200) {
        throw Exception('Gemini API failed: ${response.statusCode}');
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

    // Each category gets a tailored generation prompt so the practice
    // sentences truly exercise different phonetic/prosodic skills.
    final String categoryRequirements;
    switch (category) {
      case 'Individual Sounds':
        categoryRequirements = '''
Focus: difficult English phonemes that Vietnamese speakers struggle with.
MUST include at least 3 of these sounds in the sentence:
- /θ/ or /ð/  → words like "think", "the", "those", "breathe"
- /v/          → words like "value", "arrive", "love"
- /æ/          → words like "cat", "plan", "travel"
- /r/ (initial)→ words like "really", "wrong", "around"
- /ɪ/ vs /iː/  → contrasts like "ship/sheep", "fill/feel"
Return varied consonant-vowel challenges, NOT a tongue-twister.
Example style: "The weather forecast threatened heavy thunder throughout the valley."
''';
        break;
      case 'Word Stress':
        categoryRequirements = '''
Focus: polysyllabic words where wrong stress placement changes meaning or sounds unnatural.
MUST include at least 2 of these stress challenge types:
- Noun-verb stress pairs:  "REcord" (noun) vs "reCORD" (verb), "PROtest" vs "proTEST"
- Long academic/IELTS words with non-obvious stress: "deTERmine", "parTICular", "adVANtage"
- Compound stress contrasts: "HOT dog" (food) vs "hot DOG" (warm dog)
The sentence must feel natural in IELTS academic/general topic context.
Example style: "The government decided to present a proposal to record economic progress."
''';
        break;
      case 'Sentence Intonation':
      default:
        categoryRequirements = '''
Focus: sentence-level prosody — rising/falling intonation, thought groups, pausing.
Use ONE of these structures that naturally requires varied intonation:
- Tag question:    "You enjoy learning English, don't you?"
- List structure:  "To improve fluency, you need vocabulary, grammar, and regular practice."
- Conditional:     "If you practise every day, your confidence will grow significantly."
- Contrast/emphasis: "It wasn't the difficulty that surprised me — it was the length."
The sentence should be 12-18 words so there is enough to demonstrate a full intonation arc.
Example style: "The more you listen to native speakers, the faster your intonation improves."
''';
    }

    final prompt =
        '''
You are an IELTS speaking coach. Generate ONE practice sentence for pronunciation training.

Category: $category
Difficulty: $difficulty

$categoryRequirements
General requirements:
- Natural English sentence (NOT a list or fragment)
- Appropriate for IELTS speaking practice
- Do NOT invent non-English words

Return ONLY a JSON object:
{
  "sentence": "the practice sentence",
  "ipa": "full IPA transcription of the sentence",
  "translation": "Bản dịch tiếng Việt"
}
''';

    try {
      final response = await _postWithRetry(
        url,
        {'Content-Type': 'application/json'},
        jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt},
              ],
            },
          ],
        }),
        timeout: _generateTimeout,
      );

      if (response.statusCode == 429) {
        throw Exception(
          'Gemini quota exceeded (429). Please wait a moment and try again.',
        );
      }
      if (response.statusCode != 200) {
        throw Exception('Gemini API failed: ${response.statusCode}');
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
    String category = 'Individual Sounds',
  }) {
    final confScoresStr = confidenceScores.entries
        .map((e) => '${e.key}: ${e.value.toStringAsFixed(2)}')
        .join(', ');

    // ── Category-specific coaching focus ─────────────────────────────────────
    final String coachRole;
    final String analysisInstructions;
    final String errorTypePriority;

    switch (category) {
      case 'Individual Sounds':
        coachRole =
            'You are an IELTS phonetics expert specialising in segmental '
            'pronunciation — individual consonants and vowels.';
        analysisInstructions = '''
PRIMARY FOCUS — Segmental errors (in this order of priority):
1. Consonant errors: /θ/ vs /t/ or /s/, /ð/ vs /d/ or /z/, /v/ vs /b/ or /f/,
   /r/ vs /l/, /w/ vs /v/.
2. Vowel errors: /æ/ vs /e/, /ɪ/ vs /iː/, /ʌ/ vs /a/, final unstressed vowels.
3. Omission/substitution of entire sounds in consonant clusters.
For each word error, compare the EXPECTED IPA vs the LIKELY actual production.
Do NOT report stress or intonation errors — those belong to other categories.
Feedback tips must be phoneme-level: e.g. "Place tongue between teeth for /θ/".
''';
        errorTypePriority =
            '"consonant", "vowel", "substitution", "omission", "insertion"';
        break;

      case 'Word Stress':
        coachRole =
            'You are an IELTS pronunciation coach specialising in suprasegmental '
            'features — word stress, syllable prominence, and lexical rhythm.';
        analysisInstructions = '''
PRIMARY FOCUS — Word stress errors:
1. Identify every polysyllabic word (3+ syllables) in the target sentence.
2. For each, judge whether the user placed primary stress on the CORRECT syllable.
   Use the STT confidence per word as a proxy: low confidence on a stressed syllable
   often indicates mis-stress.
3. Flag noun-verb stress pair mistakes (e.g. "reCORD" used when "REcord" was intended).
4. Report stress errors using errorType: "stress".
   In the "tip" field, show the correct pattern with CAPS on the stressed syllable:
   e.g. "de-TER-mine", "pre-SEN-ta-tion".
Do NOT heavily penalise segmental consonant/vowel quality — focus on RHYTHM and STRESS.
overallScore should primarily reflect stress accuracy.
''';
        errorTypePriority =
            '"stress", "omission", "substitution", "consonant", "vowel"';
        break;

      case 'Sentence Intonation':
      default:
        coachRole =
            'You are an IELTS speaking examiner specialising in connected speech, '
            'sentence intonation, thought groups, and prosodic fluency.';
        analysisInstructions = '''
PRIMARY FOCUS — Sentence-level prosody:
1. Thought groups: Does the speaker pause at natural grammatical boundaries?
   (after clauses, before conjunctions, at comma positions in the target sentence).
2. Intonation arc: Does overall pitch fall at declarative sentence endings?
   Does it rise appropriately for questions or list items?
3. Sentence stress (nuclear stress): Is the most important word in each thought group
   given the highest pitch peak?
4. Fluency markers: Hesitations, restarts, and unnatural pausing reduce the score.
Word-level errors should be reported as "stress" or "substitution" only when they
disrupt the prosodic flow of the whole sentence.
Feedback tips must address intonation patterns, not individual sounds:
e.g. "Let your pitch fall on the last content word of each clause."
overallScore and bandScore should weight prosody (60%) and accuracy (40%).
''';
        errorTypePriority =
            '"stress", "omission", "insertion", "substitution", "consonant"';
        break;
    }
    // ─────────────────────────────────────────────────────────────────────────

    // Pre-compute localised focus label to avoid complex ternary inside string
    final String focusVN;
    if (category == 'Individual Sounds') {
      focusVN = 'âm đơn';
    } else if (category == 'Word Stress') {
      focusVN = 'trọng âm';
    } else {
      focusVN = 'ngữ điệu';
    }

    return '''
$coachRole Analyze this speaking performance.

Practice category: $category
Target sentence: "$targetSentence"
User transcript:  "$userTranscript"
STT word-confidence scores: {$confScoresStr}

$analysisInstructions
Return a JSON object with this EXACT structure (no extra keys, no markdown):
{
  "overallScore": 0-100 integer,
  "bandScore": 1.0-9.0 float (IELTS band),
  "wordErrors": [
    {
      "word": "the mispronounced word",
      "position": 0,
      "errorType": $errorTypePriority,
      "severity": 1-10,
      "expectedIPA": "/correct IPA/",
      "actualIPA": "/likely user IPA/",
      "tip": "specific actionable correction tip in English"
    }
  ],
  "feedbackVN": "2-3 cau nhan xet tong the bang tieng Viet, tap trung vao $focusVN",
  "feedbackEN": "2-3 sentence overall feedback in English focused on $category",
  "tipsVN": ["Meo 1", "Meo 2", "Meo 3"],
  "tipsEN": ["Tip 1", "Tip 2", "Tip 3"],
  "nextStepsVN": "Goi y buoc luyen tap tiep theo bang tieng Viet",
  "nextStepsEN": "Recommended next practice focus in English",
  "improvementFocus": ["errorType1", "errorType2"]
}

Band score: 90-100=8.0-9.0, 75-89=6.5-7.5, 60-74=5.5-6.0, 40-59=4.5-5.0, <40=<4.5
Provide constructive, encouraging feedback. List only real errors (max 5 most impactful).
Return ONLY the JSON object, no additional text.
''';
  }
}
