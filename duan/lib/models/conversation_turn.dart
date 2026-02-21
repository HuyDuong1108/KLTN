import 'package:cloud_firestore/cloud_firestore.dart';

class ConversationTurn {
  final int turnIndex;
  final String aiQuestion;
  final String userTranscript;
  final String aiResponse;
  final double fluencyScore; // 1.0 – 9.0
  final double lexicalScore; // 1.0 – 9.0
  final double grammarScore; // 1.0 – 9.0
  final double pronunciationScore; // 1.0 – 9.0
  final double overallBand;
  final String feedbackVN;
  final String improvementTip;
  final List<String> strengths;
  final List<String> weaknesses;
  final DateTime timestamp;

  ConversationTurn({
    required this.turnIndex,
    required this.aiQuestion,
    required this.userTranscript,
    required this.aiResponse,
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

  factory ConversationTurn.fromJson(Map<String, dynamic> j) {
    DateTime ts;
    final rawTs = j['timestamp'];
    if (rawTs is Timestamp) {
      ts = rawTs.toDate();
    } else if (rawTs is int) {
      ts = DateTime.fromMillisecondsSinceEpoch(rawTs);
    } else {
      ts = DateTime.now();
    }

    return ConversationTurn(
      turnIndex: (j['turnIndex'] as num?)?.toInt() ?? 0,
      aiQuestion: j['aiQuestion'] as String? ?? '',
      userTranscript: j['userTranscript'] as String? ?? '',
      aiResponse: j['aiResponse'] as String? ?? '',
      fluencyScore: (j['fluencyScore'] as num?)?.toDouble() ?? 0.0,
      lexicalScore: (j['lexicalScore'] as num?)?.toDouble() ?? 0.0,
      grammarScore: (j['grammarScore'] as num?)?.toDouble() ?? 0.0,
      pronunciationScore: (j['pronunciationScore'] as num?)?.toDouble() ?? 0.0,
      overallBand: (j['overallBand'] as num?)?.toDouble() ?? 0.0,
      feedbackVN: j['feedbackVN'] as String? ?? '',
      improvementTip: j['improvementTip'] as String? ?? '',
      strengths: List<String>.from(j['strengths'] as List? ?? []),
      weaknesses: List<String>.from(j['weaknesses'] as List? ?? []),
      timestamp: ts,
    );
  }

  Map<String, dynamic> toJson() => {
    'turnIndex': turnIndex,
    'aiQuestion': aiQuestion,
    'userTranscript': userTranscript,
    'aiResponse': aiResponse,
    'fluencyScore': fluencyScore,
    'lexicalScore': lexicalScore,
    'grammarScore': grammarScore,
    'pronunciationScore': pronunciationScore,
    'overallBand': overallBand,
    'feedbackVN': feedbackVN,
    'improvementTip': improvementTip,
    'strengths': strengths,
    'weaknesses': weaknesses,
    'timestamp': timestamp.millisecondsSinceEpoch,
  };
}
