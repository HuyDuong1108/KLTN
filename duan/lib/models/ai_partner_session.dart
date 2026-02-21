import 'package:cloud_firestore/cloud_firestore.dart';
import 'conversation_turn.dart';

class AiPartnerSession {
  final String sessionId;
  final String userId;
  final String topic;
  final bool isFreeMode;
  final List<ConversationTurn> turns;
  final double avgFluency;
  final double avgLexical;
  final double avgGrammar;
  final double avgPronunciation;
  final double overallBand;
  final String closingMessage; // AI's natural closing sentence
  final DateTime startedAt;
  final DateTime endedAt;

  AiPartnerSession({
    required this.sessionId,
    required this.userId,
    required this.topic,
    required this.isFreeMode,
    required this.turns,
    required this.avgFluency,
    required this.avgLexical,
    required this.avgGrammar,
    required this.avgPronunciation,
    required this.overallBand,
    required this.closingMessage,
    required this.startedAt,
    required this.endedAt,
  });

  Duration get duration => endedAt.difference(startedAt);

  factory AiPartnerSession.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;

    DateTime _parseTs(dynamic raw) {
      if (raw is Timestamp) return raw.toDate();
      if (raw is int) return DateTime.fromMillisecondsSinceEpoch(raw);
      return DateTime.now();
    }

    final turnsList = (d['turns'] as List<dynamic>? ?? [])
        .map((t) => ConversationTurn.fromJson(t as Map<String, dynamic>))
        .toList();

    return AiPartnerSession(
      sessionId: doc.id,
      userId: d['userId'] as String? ?? '',
      topic: d['topic'] as String? ?? '',
      isFreeMode: d['isFreeMode'] as bool? ?? false,
      turns: turnsList,
      avgFluency: (d['avgFluency'] as num?)?.toDouble() ?? 0.0,
      avgLexical: (d['avgLexical'] as num?)?.toDouble() ?? 0.0,
      avgGrammar: (d['avgGrammar'] as num?)?.toDouble() ?? 0.0,
      avgPronunciation: (d['avgPronunciation'] as num?)?.toDouble() ?? 0.0,
      overallBand: (d['overallBand'] as num?)?.toDouble() ?? 0.0,
      closingMessage: d['closingMessage'] as String? ?? '',
      startedAt: _parseTs(d['startedAtMs'] ?? d['startedAt']),
      endedAt: _parseTs(d['endedAtMs'] ?? d['endedAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'userId': userId,
    'topic': topic,
    'isFreeMode': isFreeMode,
    'turns': turns.map((t) => t.toJson()).toList(),
    'avgFluency': avgFluency,
    'avgLexical': avgLexical,
    'avgGrammar': avgGrammar,
    'avgPronunciation': avgPronunciation,
    'overallBand': overallBand,
    'closingMessage': closingMessage,
    'startedAt': FieldValue.serverTimestamp(),
    'startedAtMs': startedAt.millisecondsSinceEpoch,
    'endedAt': FieldValue.serverTimestamp(),
    'endedAtMs': endedAt.millisecondsSinceEpoch,
  };
}
