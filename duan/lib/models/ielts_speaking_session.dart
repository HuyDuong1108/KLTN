import 'package:cloud_firestore/cloud_firestore.dart';

// ─────────────────────────────────────────────────────────────
// Cue Card (Part 2 task card)
// ─────────────────────────────────────────────────────────────
class IeltsCueCard {
  final String topic;
  final List<String> bulletPoints; // exactly 4 guiding bullets

  const IeltsCueCard({required this.topic, required this.bulletPoints});

  factory IeltsCueCard.fromJson(Map<String, dynamic> j) => IeltsCueCard(
    topic: j['topic'] as String? ?? '',
    bulletPoints: List<String>.from(j['bulletPoints'] as List? ?? []),
  );

  Map<String, dynamic> toJson() => {
    'topic': topic,
    'bulletPoints': bulletPoints,
  };
}

// ─────────────────────────────────────────────────────────────
// Per-turn data (Part 1, 2, or 3)
// ─────────────────────────────────────────────────────────────
class IeltsTurn {
  final int turnIndex;
  final int part; // 1 | 2 | 3
  final String question;
  final String transcript;
  final double fluencyScore;
  final double lexicalScore;
  final double grammarScore;
  final double pronunciationScore;
  final double overallBand;
  final String feedbackVN;
  final String improvementTip;
  final List<String> strengths;
  final List<String> weaknesses;
  final DateTime timestamp;

  const IeltsTurn({
    required this.turnIndex,
    required this.part,
    required this.question,
    required this.transcript,
    required this.fluencyScore,
    required this.lexicalScore,
    required this.grammarScore,
    required this.pronunciationScore,
    required this.overallBand,
    required this.feedbackVN,
    required this.improvementTip,
    required this.strengths,
    required this.weaknesses,
    required this.timestamp,
  });

  bool get isSkipped => transcript == '(skipped)';

  factory IeltsTurn.fromJson(Map<String, dynamic> j) => IeltsTurn(
    turnIndex: (j['turnIndex'] as num?)?.toInt() ?? 0,
    part: (j['part'] as num?)?.toInt() ?? 1,
    question: j['question'] as String? ?? '',
    transcript: j['transcript'] as String? ?? '',
    fluencyScore: (j['fluencyScore'] as num?)?.toDouble() ?? 0.0,
    lexicalScore: (j['lexicalScore'] as num?)?.toDouble() ?? 0.0,
    grammarScore: (j['grammarScore'] as num?)?.toDouble() ?? 0.0,
    pronunciationScore: (j['pronunciationScore'] as num?)?.toDouble() ?? 0.0,
    overallBand: (j['overallBand'] as num?)?.toDouble() ?? 0.0,
    feedbackVN: j['feedbackVN'] as String? ?? '',
    improvementTip: j['improvementTip'] as String? ?? '',
    strengths: List<String>.from(j['strengths'] as List? ?? []),
    weaknesses: List<String>.from(j['weaknesses'] as List? ?? []),
    timestamp: j['timestampMs'] is int
        ? DateTime.fromMillisecondsSinceEpoch(j['timestampMs'] as int)
        : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'turnIndex': turnIndex,
    'part': part,
    'question': question,
    'transcript': transcript,
    'fluencyScore': fluencyScore,
    'lexicalScore': lexicalScore,
    'grammarScore': grammarScore,
    'pronunciationScore': pronunciationScore,
    'overallBand': overallBand,
    'feedbackVN': feedbackVN,
    'improvementTip': improvementTip,
    'strengths': strengths,
    'weaknesses': weaknesses,
    'timestampMs': timestamp.millisecondsSinceEpoch,
  };
}

// ─────────────────────────────────────────────────────────────
// Full IELTS Speaking Session
// ─────────────────────────────────────────────────────────────
class IeltsSpeakingSession {
  final String sessionId;
  final String userId;
  final IeltsCueCard cueCard;
  final int prepTimeUsed; // seconds actually spent in prep
  final List<IeltsTurn> part1Turns; // 5 turns
  final IeltsTurn? part2Turn; // 1 monologue
  final List<IeltsTurn> part3Turns; // 4 turns
  final double part1Band;
  final double part2Band;
  final double part3Band;
  final double avgFluency;
  final double avgLexical;
  final double avgGrammar;
  final double avgPronunciation;
  final double overallBand;
  final DateTime startedAt;
  final DateTime endedAt;

  const IeltsSpeakingSession({
    required this.sessionId,
    required this.userId,
    required this.cueCard,
    required this.prepTimeUsed,
    required this.part1Turns,
    this.part2Turn,
    required this.part3Turns,
    required this.part1Band,
    required this.part2Band,
    required this.part3Band,
    required this.avgFluency,
    required this.avgLexical,
    required this.avgGrammar,
    required this.avgPronunciation,
    required this.overallBand,
    required this.startedAt,
    required this.endedAt,
  });

  Duration get duration => endedAt.difference(startedAt);

  List<IeltsTurn> get allTurns => [
    ...part1Turns,
    if (part2Turn != null) part2Turn!,
    ...part3Turns,
  ];

  factory IeltsSpeakingSession.fromFirestore(DocumentSnapshot doc) {
    final j = doc.data() as Map<String, dynamic>;
    return IeltsSpeakingSession(
      sessionId: doc.id,
      userId: j['userId'] as String? ?? '',
      cueCard: IeltsCueCard.fromJson(
        (j['cueCard'] as Map<String, dynamic>?) ??
            {'topic': '', 'bulletPoints': []},
      ),
      prepTimeUsed: (j['prepTimeUsed'] as num?)?.toInt() ?? 0,
      part1Turns: (j['part1Turns'] as List? ?? [])
          .map((t) => IeltsTurn.fromJson(t as Map<String, dynamic>))
          .toList(),
      part2Turn: j['part2Turn'] != null
          ? IeltsTurn.fromJson(j['part2Turn'] as Map<String, dynamic>)
          : null,
      part3Turns: (j['part3Turns'] as List? ?? [])
          .map((t) => IeltsTurn.fromJson(t as Map<String, dynamic>))
          .toList(),
      part1Band: (j['part1Band'] as num?)?.toDouble() ?? 0.0,
      part2Band: (j['part2Band'] as num?)?.toDouble() ?? 0.0,
      part3Band: (j['part3Band'] as num?)?.toDouble() ?? 0.0,
      avgFluency: (j['avgFluency'] as num?)?.toDouble() ?? 0.0,
      avgLexical: (j['avgLexical'] as num?)?.toDouble() ?? 0.0,
      avgGrammar: (j['avgGrammar'] as num?)?.toDouble() ?? 0.0,
      avgPronunciation: (j['avgPronunciation'] as num?)?.toDouble() ?? 0.0,
      overallBand: (j['overallBand'] as num?)?.toDouble() ?? 0.0,
      startedAt: j['startedAtMs'] is int
          ? DateTime.fromMillisecondsSinceEpoch(j['startedAtMs'] as int)
          : (j['startedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      endedAt: j['endedAtMs'] is int
          ? DateTime.fromMillisecondsSinceEpoch(j['endedAtMs'] as int)
          : (j['endedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'cueCard': cueCard.toJson(),
    'prepTimeUsed': prepTimeUsed,
    'part1Turns': part1Turns.map((t) => t.toJson()).toList(),
    'part2Turn': part2Turn?.toJson(),
    'part3Turns': part3Turns.map((t) => t.toJson()).toList(),
    'part1Band': part1Band,
    'part2Band': part2Band,
    'part3Band': part3Band,
    'avgFluency': avgFluency,
    'avgLexical': avgLexical,
    'avgGrammar': avgGrammar,
    'avgPronunciation': avgPronunciation,
    'overallBand': overallBand,
    'startedAt': Timestamp.fromDate(startedAt),
    'startedAtMs': startedAt.millisecondsSinceEpoch,
    'endedAt': Timestamp.fromDate(endedAt),
    'endedAtMs': endedAt.millisecondsSinceEpoch,
  };
}
