import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/ielts_speaking_session.dart';
import 'ai_partner_gemini_service.dart'; // reuse TurnScoreResult

class IeltsGeminiService {
  IeltsGeminiService._();
  static final instance = IeltsGeminiService._();

  static const String _model = 'gemini-2.0-flash';
  static const Duration _timeout = Duration(seconds: 25);

  String get _apiKey => dotenv.env['API_KEY'] ?? '';
  String get _endpoint =>
      'https://generativelanguage.googleapis.com/v1/models/$_model:generateContent?key=$_apiKey';

  // ─────────────────────────────────────────────────────────────
  // 1. Generate 5 Part 1 personal questions
  // ─────────────────────────────────────────────────────────────
  Future<List<String>> generatePart1Questions() async {
    const prompt = '''
You are an IELTS speaking examiner. Generate exactly 5 Part 1 questions about everyday personal topics 
(home, family, work/studies, hobbies, daily routines, food, transport, weather, technology).
Each question must be short and conversational (1 sentence).
Return ONLY a JSON array of 5 strings, no explanation.
Example: ["Do you work or study?", "What do you do in your free time?", "Do you enjoy cooking?", "How do you usually travel to school?", "What kind of music do you like?"]
''';
    try {
      final raw = await _callGemini(prompt);
      final cleaned = _cleanJson(raw);
      final list = jsonDecode(cleaned) as List;
      return list.map((e) => e.toString()).take(5).toList();
    } catch (_) {
      return [
        'Can you tell me about your hometown?',
        'What do you do in your free time?',
        'Do you prefer indoor or outdoor activities?',
        'What kind of music do you enjoy listening to?',
        'How do you usually spend your weekends?',
      ];
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 2. Generate a Part 2 cue card
  // ─────────────────────────────────────────────────────────────
  Future<IeltsCueCard> generateCueCard() async {
    const prompt = '''
You are an IELTS speaking examiner. Generate one Part 2 task card.
Return ONLY valid JSON with this exact schema (no extra fields):
{
  "topic": "Describe a person who has had a great influence on you.",
  "bulletPoints": [
    "Who this person is",
    "How you know them",
    "What they have done that influenced you",
    "Explain why they have been an influence on you"
  ]
}
Rules:
- The topic must start with "Describe ..."
- There must be exactly 4 bullet points that help structure the 2-minute talk
- The topic should be interesting and varied (people, places, events, objects, experiences)
''';
    try {
      final raw = await _callGemini(prompt);
      final cleaned = _cleanJson(raw);
      return IeltsCueCard.fromJson(jsonDecode(cleaned) as Map<String, dynamic>);
    } catch (_) {
      return const IeltsCueCard(
        topic: 'Describe a memorable journey you have taken.',
        bulletPoints: [
          'Where you went',
          'Who you went with',
          'What you did there',
          'Explain why it was memorable',
        ],
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 3. Generate 4 Part 3 abstract discussion questions
  // ─────────────────────────────────────────────────────────────
  Future<List<String>> generatePart3Questions(String cueCardTopic) async {
    final prompt =
        '''
You are an IELTS speaking examiner. The candidate just spoke about: "$cueCardTopic"

Generate exactly 4 Part 3 discussion questions that:
- Explore broader societal, cultural, or philosophical angles related to the topic
- Are abstract and open-ended (not personal)
- Progress from more concrete to more abstract
- Are appropriate for Band 6-8 level discussion

Return ONLY a JSON array of 4 strings, no explanation.
''';
    try {
      final raw = await _callGemini(prompt);
      final cleaned = _cleanJson(raw);
      final list = jsonDecode(cleaned) as List;
      return list.map((e) => e.toString()).take(4).toList();
    } catch (_) {
      return [
        'In what ways can people influence each other in modern society?',
        'How has technology changed the way people share experiences?',
        'Do you think the media portrays certain topics accurately?',
        'What role should education play in shaping young people\'s values?',
      ];
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 4. Score an IELTS turn (all 4 criteria)
  // ─────────────────────────────────────────────────────────────
  Future<TurnScoreResult> scoreIeltsTurn({
    required String transcript,
    required String question,
    required int part,
    required List<IeltsTurn> history,
  }) async {
    final historyCtx = _buildHistoryContext(history);
    final partDesc = _partDescription(part);

    final prompt =
        '''
You are an expert IELTS speaking examiner. Analyze the candidate's spoken response in $partDesc of the IELTS Speaking test.

Examiner asked: "$question"
Candidate said: "$transcript"

Previous exchanges in this part:
$historyCtx

Score using IELTS Speaking Band Descriptors (1.0–9.0, half-band increments only: 5.0, 5.5, 6.0, etc.):

1. **Fluency & Coherence**: flow, hesitation frequency, self-correction, logical organisation, use of discourse markers
2. **Lexical Resource**: vocabulary range, collocations, idiomatic expressions, precision, paraphrase ability
3. **Grammatical Range & Accuracy**: variety of structures (simple/complex), error frequency and impact
4. **Pronunciation**: clarity, intelligibility, word stress, sentence stress, intonation patterns

Be realistic — Band 5.0–6.5 is typical for intermediate learners.
Note: pronunciation is estimated from transcript patterns (STT output).

Return ONLY valid JSON:
{
  "fluency": 5.5,
  "lexical": 6.0,
  "grammar": 5.5,
  "pronunciation": 5.0,
  "overallBand": 5.5,
  "feedbackVN": "Nhận xét ngắn bằng tiếng Việt (2-3 câu) về điểm mạnh và yếu.",
  "improvementTip": "One specific, actionable tip in English (1 sentence).",
  "strengths": ["strength 1", "strength 2"],
  "weaknesses": ["weakness 1"]
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
        improvementTip: 'Try to expand your answer with more specific details.',
        strengths: [],
        weaknesses: [],
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 5. Generate examiner intro for each part
  // ─────────────────────────────────────────────────────────────
  Future<String> generatePartIntro({
    required int part,
    IeltsCueCard? cueCard,
  }) async {
    String prompt;
    if (part == 1) {
      prompt = '''
You are an IELTS speaking examiner starting the test.
Write a brief, natural Part 1 introduction (1-2 sentences).
- Introduce yourself as the examiner (use "I" not a name)
- Tell the candidate Part 1 is about personal questions
- Sound professional but warm
Return ONLY the spoken text, nothing else.
''';
    } else if (part == 2 && cueCard != null) {
      prompt =
          '''
You are an IELTS speaking examiner transitioning to Part 2.
The task card topic is: "${cueCard.topic}"
Write a 2-3 sentence introduction that:
- Tells the candidate they have 1 minute to prepare
- Says they should speak for 1 to 2 minutes
- Sounds natural and professional
Return ONLY the spoken text, nothing else.
''';
    } else {
      prompt = '''
You are an IELTS speaking examiner transitioning to Part 3.
Write a 1-2 sentence introduction that:
- Smoothly transitions from Part 2
- Says you'll now discuss more abstract questions related to the topic
Return ONLY the spoken text, nothing else.
''';
    }
    try {
      return (await _callGemini(prompt)).trim();
    } catch (_) {
      if (part == 1) {
        return "I'd like to ask you some questions about yourself to get started.";
      }
      if (part == 2) {
        return "Now I'm going to give you a topic. You have one minute to prepare and then speak for one to two minutes.";
      }
      return "We've been talking about that topic. I'd now like to ask you some more general questions related to this.";
    }
  }

  // ─────────────────────────────────────────────────────────────
  // 6. Generate closing message after test
  // ─────────────────────────────────────────────────────────────
  Future<String> generateTestClosingMessage({
    required double overallBand,
    required double part1Band,
    required double part2Band,
    required double part3Band,
  }) async {
    final prompt =
        '''
You are an IELTS speaking examiner wrapping up a full IELTS speaking test.
Estimated bands — Overall: ${overallBand.toStringAsFixed(1)}, Part 1: ${part1Band.toStringAsFixed(1)}, Part 2: ${part2Band.toStringAsFixed(1)}, Part 3: ${part3Band.toStringAsFixed(1)}.

Write a closing statement (2-3 sentences) that:
- Thanks the candidate for participating
- Mentions one genuine strength shown during the test
- Suggests one key improvement area based on the band level
- Sounds like a real human examiner, NOT a formal report

Return ONLY the spoken text, nothing else.
''';
    try {
      return (await _callGemini(prompt)).trim();
    } catch (_) {
      return "Thank you — that's the end of the speaking test. You showed good communicative ability throughout. Keep working on expanding your vocabulary for higher band scores.";
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────
  String _partDescription(int part) {
    switch (part) {
      case 1:
        return 'Part 1 (Introduction & Interview)';
      case 2:
        return 'Part 2 (Individual Long Turn)';
      case 3:
        return 'Part 3 (Two-way Discussion)';
      default:
        return 'Speaking Test';
    }
  }

  String _buildHistoryContext(List<IeltsTurn> history) {
    if (history.isEmpty) return '(No previous exchanges in this part)';
    final buf = StringBuffer();
    for (final t in history) {
      buf.writeln('Examiner: ${t.question}');
      buf.writeln('Candidate: ${t.transcript}');
    }
    return buf.toString();
  }

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
      throw Exception('Gemini error ${response.statusCode}: ${response.body}');
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    final candidates = json['candidates'] as List<dynamic>?;
    if (candidates == null || candidates.isEmpty) {
      throw Exception('No candidates from Gemini');
    }
    final content = candidates[0]['content'] as Map<String, dynamic>;
    final parts = content['parts'] as List<dynamic>;
    return (parts[0]['text'] as String).trim();
  }

  String _cleanJson(String raw) {
    var s = raw.trim();
    if (s.startsWith('```')) {
      s = s.replaceFirst(RegExp(r'^```[a-z]*\n?'), '');
      s = s.replaceFirst(RegExp(r'```$'), '');
    }
    return s.trim();
  }
}
