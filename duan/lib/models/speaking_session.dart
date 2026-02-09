import 'package:cloud_firestore/cloud_firestore.dart';
import 'word_error.dart';
import 'pronunciation_feedback.dart';

class SpeakingSession {
  final String sessionId;
  final String userId;
  final DateTime timestamp;
  final String targetSentence;
  final String transcript;
  final int overallScore; // 0-100
  final double bandScore; // 1.0-9.0
  final Duration duration;
  final Map<String, double> confidenceScores;
  final List<WordError> wordErrors;
  final PronunciationFeedback feedback;
  final String? category;

  const SpeakingSession({
    required this.sessionId,
    required this.userId,
    required this.timestamp,
    required this.targetSentence,
    required this.transcript,
    required this.overallScore,
    required this.bandScore,
    required this.duration,
    required this.confidenceScores,
    required this.wordErrors,
    required this.feedback,
    this.category,
  });

  factory SpeakingSession.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data()!;

    DateTime timestamp;
    final ts = data['timestamp'];
    if (ts is Timestamp) {
      timestamp = ts.toDate();
    } else if (ts is int) {
      timestamp = DateTime.fromMillisecondsSinceEpoch(ts);
    } else {
      timestamp = DateTime.now();
    }

    final confScoresRaw = data['confidenceScores'] as Map<String, dynamic>?;
    final confidenceScores =
        confScoresRaw?.map(
          (key, value) => MapEntry(key, (value as num).toDouble()),
        ) ??
        {};

    final wordErrorsRaw = data['wordErrors'] as List<dynamic>? ?? [];
    final wordErrors = wordErrorsRaw
        .map((e) => WordError.fromJson(e as Map<String, dynamic>))
        .toList();

    final feedbackData = data['feedback'] as Map<String, dynamic>? ?? {};
    final feedback = PronunciationFeedback.fromJson(feedbackData);

    return SpeakingSession(
      sessionId: doc.id,
      userId: data['userId'] as String,
      timestamp: timestamp,
      targetSentence: data['targetSentence'] as String,
      transcript: data['transcript'] as String,
      overallScore: data['overallScore'] as int,
      bandScore: (data['bandScore'] as num).toDouble(),
      duration: Duration(seconds: data['durationSeconds'] as int),
      confidenceScores: confidenceScores,
      wordErrors: wordErrors,
      feedback: feedback,
      category: data['category'] as String?,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'timestamp': FieldValue.serverTimestamp(),
      'timestampMs': timestamp.millisecondsSinceEpoch,
      'targetSentence': targetSentence,
      'transcript': transcript,
      'overallScore': overallScore,
      'bandScore': bandScore,
      'durationSeconds': duration.inSeconds,
      'confidenceScores': confidenceScores,
      'wordErrors': wordErrors.map((e) => e.toJson()).toList(),
      'feedback': feedback.toJson(),
      'category': category,
    };
  }

  Map<String, dynamic> toCommunitySafe() {
    return {
      'targetSentence': targetSentence,
      'transcript': transcript,
      'overallScore': overallScore,
      'bandScore': bandScore,
      'wordErrors': wordErrors.map((e) => e.toJson()).toList(),
      'feedback': feedback.toJson(),
      'category': category,
      'createdAt': FieldValue.serverTimestamp(),
      'likesCount': 0,
    };
  }
}
