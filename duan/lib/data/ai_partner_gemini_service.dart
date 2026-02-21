import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/conversation_turn.dart';
import '../models/ai_partner_profile.dart';

class TurnScoreResult {
  final double fluency;
  final double lexical;
  final double grammar;
  final double pronunciation;
  final double overallBand;
  final String feedbackVN;
  final String improvementTip;
  final List<String> strengths;
  final List<String> weaknesses;

  TurnScoreResult({
    required this.fluency,
    required this.lexical,
    required this.grammar,
    required this.pronunciation,
    required this.overallBand,
    required this.feedbackVN,
    required this.improvementTip,
    required this.strengths,
    required this.weaknesses,
  });

  factory TurnScoreResult.fromJson(Map<String, dynamic> j) => TurnScoreResult(
    fluency: (j['fluency'] as num?)?.toDouble() ?? 5.0,
    lexical: (j['lexical'] as num?)?.toDouble() ?? 5.0,
    grammar: (j['grammar'] as num?)?.toDouble() ?? 5.0,
    pronunciation: (j['pronunciation'] as num?)?.toDouble() ?? 5.0,
    overallBand: (j['overallBand'] as num?)?.toDouble() ?? 5.0,
    feedbackVN: j['feedbackVN'] as String? ?? '',
    improvementTip: j['improvementTip'] as String? ?? '',
    strengths: List<String>.from(j['strengths'] as List? ?? []),
    weaknesses: List<String>.from(j['weaknesses'] as List? ?? []),
  );
}

class AiPartnerGeminiService {
  AiPartnerGeminiService._();
  static final instance = AiPartnerGeminiService._();

  static const String _model = 'gemini-2.0-flash';
  static const Duration _timeout = Duration(seconds: 20);

  String get _apiKey => dotenv.env['API_KEY'] ?? '';
  String get _endpoint =>
      'https://generativelanguage.googleapis.com/v1/models/$_model:generateContent?key=$_apiKey';

  // ─────────────────────────────────────────────────────────────
  // 1. Generate list of free-choice topics using Gemini
  // ─────────────────────────────────────────────────────────────
  Future<List<String>> generateFreeTopics() async {
    const prompt = '''
You are an IELTS speaking examiner. Generate 6 interesting and varied IELTS Part 1/Part 2 conversation topics for an English learner.
Return ONLY a JSON array of strings, no explanation.
Example: ["Childhood memories", "Future technology", "Local cuisine", "Social media habits", "Dream travel destination", "Work-life balance"]
''';
    try {
      final raw = await _callGemini(prompt);
      final cleaned = _cleanJson(raw);
      final List<dynamic> list = jsonDecode(cleaned) as List;
      return list.map((e) => e.toString()).toList();
    } catch (_) {
      return [
        'Childhood memories',
        'Future technology',
        'Local cuisine',
        'Social media habits',
        'Dream travel',
        'Work-life balance',
      ];
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 2. Generate opening question (Prompt 1 variant)
  // ─────────────────────────────────────────────────────────────
  Future<String> generateOpeningQuestion({
    required String topic,
    required bool isFreeMode,
    required AiPartnerProfile profile,
  }) async {
    final profileCtx = _buildProfileContext(profile);
    final modeCtx = isFreeMode
        ? 'This is a free conversation session, keep it natural and casual.'
        : 'This is a structured IELTS speaking practice session.';

    final prompt =
        '''
You are a friendly but professional IELTS speaking examiner.
Topic: "$topic"
$modeCtx
$profileCtx

Generate a natural opening question to start the conversation.
- Keep it 1-2 sentences only.
- Sound warm and encouraging.
- Do NOT include greetings like "Hello" or "Hi".
- Do NOT explain scoring or instructions.
Return ONLY the question text, nothing else.
''';
    try {
      return (await _callGemini(prompt)).trim();
    } catch (_) {
      return 'Could you tell me a little about $topic?';
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 3. Generate conversation response (Prompt 1 — main)
  // ─────────────────────────────────────────────────────────────
  Future<String> generateConversationResponse({
    required String topic,
    required bool isFreeMode,
    required List<ConversationTurn> history,
    required String userTranscript,
    required AiPartnerProfile profile,
  }) async {
    final profileCtx = _buildProfileContext(profile);
    final historyCtx = _buildHistoryContext(history);
    final modeCtx = isFreeMode
        ? 'This is a free, casual English conversation.'
        : 'This is an IELTS speaking practice session. Topic: "$topic".';

    final prompt =
        '''
You are a friendly, professional IELTS speaking examiner having a TURN-BASED spoken conversation.
$modeCtx
$profileCtx

Conversation so far:
$historyCtx

The learner just said: "$userTranscript"

Your role:
- Respond naturally and briefly (2-3 sentences MAX).
- Ask ONE follow-up question related to what they said.
- Adjust complexity to their level (shown in profile).
- Do NOT correct grammar explicitly during conversation.
- Do NOT use markdown, bullet points, or lists.
- Sound like a real human speaking, not a teacher.
- Keep response concise — this is spoken dialogue.

Return ONLY your spoken response text, nothing else.
''';
    try {
      return (await _callGemini(prompt)).trim();
    } catch (_) {
      return 'That\'s interesting! Could you tell me more about that?';
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 4. Generate natural closing message
  // ─────────────────────────────────────────────────────────────
  Future<String> generateClosingMessage({
    required List<ConversationTurn> turns,
    required String topic,
  }) async {
    final avgBand = turns.isEmpty
        ? 5.0
        : turns.map((t) => t.overallBand).reduce((a, b) => a + b) /
              turns.length;

    final prompt =
        '''
You are an IELTS speaking examiner wrapping up a practice conversation about "$topic".
The learner achieved approximately Band ${avgBand.toStringAsFixed(1)} in this session.

Write a brief, warm, natural closing statement (2-3 sentences) that:
- Acknowledges something specific they did well.
- Mentions one key area to keep working on (based on band score).
- Ends encouragingly.
- Sounds like a real human speaking, NOT a formal report.

Return ONLY the closing text, nothing else.
''';
    try {
      return (await _callGemini(prompt)).trim();
    } catch (_) {
      return 'Great conversation! Keep practicing regularly and you\'ll see improvement soon.';
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 5. Score a turn (Prompt 2 — scoring)
  // ─────────────────────────────────────────────────────────────
  Future<TurnScoreResult> scoreTurn({
    required String userTranscript,
    required String aiQuestion,
    required int turnIndex,
    required List<ConversationTurn> history,
  }) async {
    final historyCtx = _buildHistoryContext(history);

    final prompt =
        '''
You are an expert IELTS speaking examiner. Analyze the learner's spoken response below.

AI examiner asked: "$aiQuestion"
Learner said: "$userTranscript"

Previous conversation context:
$historyCtx

Score the response using IELTS Speaking Band Descriptors (1.0–9.0, half-band increments like 5.0, 5.5, 6.0):

1. **Fluency & Coherence**: flow, hesitation, self-correction, logical organisation
2. **Lexical Resource**: vocabulary range, collocations, idiomatic language, precision  
3. **Grammatical Range & Accuracy**: variety of structures, error frequency
4. **Pronunciation**: clarity, intelligibility, word stress, intonation (note: this is from STT transcript, estimate based on word choice patterns)

Return ONLY valid JSON matching this exact schema:
{
  "fluency": 5.5,
  "lexical": 6.0,
  "grammar": 5.5,
  "pronunciation": 5.0,
  "overallBand": 5.5,
  "feedbackVN": "Phản hồi bằng tiếng Việt ngắn gọn 2-3 câu về điểm mạnh và yếu.",
  "improvementTip": "One specific, actionable tip in English (1 sentence).",
  "strengths": ["strength 1", "strength 2"],
  "weaknesses": ["weakness 1", "weakness 2"]
}
''';
    try {
      final raw = await _callGemini(prompt);
      final cleaned = _cleanJson(raw);
      return TurnScoreResult.fromJson(
        jsonDecode(cleaned) as Map<String, dynamic>,
      );
    } catch (_) {
      return TurnScoreResult(
        fluency: 5.0,
        lexical: 5.0,
        grammar: 5.0,
        pronunciation: 5.0,
        overallBand: 5.0,
        feedbackVN: 'Đã ghi nhận câu trả lời của bạn.',
        improvementTip: 'Try to expand your answers with more details.',
        strengths: [],
        weaknesses: [],
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Helper: build profile context string
  // ─────────────────────────────────────────────────────────────
  String _buildProfileContext(AiPartnerProfile profile) {
    if (profile.sessionCount == 0) {
      return 'Learner profile: New learner, no previous sessions.';
    }
    final buf = StringBuffer('Learner profile:\n');
    if (profile.profileSummary.isNotEmpty) {
      buf.writeln('- Summary: ${profile.profileSummary}');
    }
    if (profile.strengths.isNotEmpty) {
      buf.writeln('- Known strengths: ${profile.strengths.join(', ')}');
    }
    if (profile.weaknesses.isNotEmpty) {
      buf.writeln(
        '- Known weaknesses to address: ${profile.weaknesses.join(', ')}',
      );
    }
    buf.writeln(
      '- Approximate band levels: Fluency ${profile.fluencyLevel.toStringAsFixed(1)}, '
      'Lexical ${profile.lexicalLevel.toStringAsFixed(1)}, '
      'Grammar ${profile.grammarLevel.toStringAsFixed(1)}, '
      'Pronunciation ${profile.pronunciationLevel.toStringAsFixed(1)}',
    );
    return buf.toString();
  }

  // ─────────────────────────────────────────────────────────────
  // Helper: build conversation history string
  // ─────────────────────────────────────────────────────────────
  String _buildHistoryContext(List<ConversationTurn> history) {
    if (history.isEmpty) return '(Start of conversation)';
    final buf = StringBuffer();
    for (final t in history) {
      buf.writeln('AI: ${t.aiQuestion}');
      buf.writeln('Learner: ${t.userTranscript}');
      if (t.aiResponse.isNotEmpty) {
        buf.writeln('AI response: ${t.aiResponse}');
      }
    }
    return buf.toString();
  }

  // ─────────────────────────────────────────────────────────────
  // Core HTTP call
  // ─────────────────────────────────────────────────────────────
  Future<String> _callGemini(String prompt) async {
    final body = jsonEncode({
      'contents': [
        {
          'parts': [
            {'text': prompt},
          ],
        },
      ],
      'generationConfig': {
        'temperature': 0.7,
        'topP': 0.9,
        'maxOutputTokens': 1024,
      },
    });

    final response = await http
        .post(
          Uri.parse(_endpoint),
          headers: {'Content-Type': 'application/json'},
          body: body,
        )
        .timeout(_timeout);

    if (response.statusCode != 200) {
      throw Exception(
        'Gemini API error ${response.statusCode}: ${response.body}',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = json['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('No candidates returned from Gemini');
    }
    final content = candidates[0]['content'] as Map<String, dynamic>;
    final parts = content['parts'] as List<dynamic>;
    return (parts[0]['text'] as String).trim();
  }

  // ─────────────────────────────────────────────────────────────
  // Helper: strip markdown code fences from JSON
  // ─────────────────────────────────────────────────────────────
  String _cleanJson(String raw) {
    var s = raw.trim();
    if (s.startsWith('```')) {
      s = s.replaceFirst(RegExp(r'^```[a-z]*\n?'), '');
      s = s.replaceFirst(RegExp(r'```$'), '');
    }
    return s.trim();
  }
}
