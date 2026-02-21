import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/speaking_session.dart';
import '../models/word_error.dart';

class SpeakingStats {
  final int totalSessions;
  final double averageBandScore;
  final Map<String, int> commonErrors;
  final DateTime? lastSessionAt;

  const SpeakingStats({
    required this.totalSessions,
    required this.averageBandScore,
    required this.commonErrors,
    this.lastSessionAt,
  });

  factory SpeakingStats.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();
    if (data == null) {
      return const SpeakingStats(
        totalSessions: 0,
        averageBandScore: 0.0,
        commonErrors: {},
      );
    }

    DateTime? lastSessionAt;
    final lastTs = data['lastSessionAt'];
    if (lastTs is Timestamp) {
      lastSessionAt = lastTs.toDate();
    } else if (lastTs is int) {
      lastSessionAt = DateTime.fromMillisecondsSinceEpoch(lastTs);
    }

    final commonErrorsRaw = data['commonErrors'] as Map<String, dynamic>?;
    final commonErrors =
        commonErrorsRaw?.map((key, value) => MapEntry(key, value as int)) ?? {};

    return SpeakingStats(
      totalSessions: data['totalSessions'] as int? ?? 0,
      averageBandScore: (data['averageBandScore'] as num?)?.toDouble() ?? 0.0,
      commonErrors: commonErrors,
      lastSessionAt: lastSessionAt,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'totalSessions': totalSessions,
      'averageBandScore': averageBandScore,
      'commonErrors': commonErrors,
      'lastSessionAt': lastSessionAt != null
          ? Timestamp.fromDate(lastSessionAt!)
          : null,
    };
  }
}

class SpeakingSessionStore {
  SpeakingSessionStore._();
  static final SpeakingSessionStore instance = SpeakingSessionStore._();

  CollectionReference<Map<String, dynamic>> _sessionsCollection(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('speaking_sessions');
  }

  DocumentReference<Map<String, dynamic>> _statsDocument(String uid) {
    return FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('speaking_stats')
        .doc('summary');
  }

  CollectionReference<Map<String, dynamic>> _communityCollection() {
    return FirebaseFirestore.instance.collection('speaking_community');
  }

  Future<String> saveSession(SpeakingSession session) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final docRef = await _sessionsCollection(
      user.uid,
    ).add(session.toFirestore());

    // Update stats
    await _updateStats(
      uid: user.uid,
      bandScore: session.bandScore,
      wordErrors: session.wordErrors,
    );

    return docRef.id;
  }

  Future<void> _updateStats({
    required String uid,
    required double bandScore,
    required List<WordError> wordErrors,
  }) async {
    final statsRef = _statsDocument(uid);
    final doc = await statsRef.get();

    if (!doc.exists) {
      // First session
      final errorCounts = <String, int>{};
      for (final error in wordErrors) {
        errorCounts[error.errorType.name] =
            (errorCounts[error.errorType.name] ?? 0) + 1;
      }

      await statsRef.set({
        'totalSessions': 1,
        'averageBandScore': bandScore,
        'commonErrors': errorCounts,
        'lastSessionAt': FieldValue.serverTimestamp(),
      });
    } else {
      // Update existing stats
      final stats = SpeakingStats.fromFirestore(doc);
      final newTotal = stats.totalSessions + 1;
      final newAverage =
          ((stats.averageBandScore * stats.totalSessions) + bandScore) /
          newTotal;

      final updatedErrors = Map<String, int>.from(stats.commonErrors);
      for (final error in wordErrors) {
        updatedErrors[error.errorType.name] =
            (updatedErrors[error.errorType.name] ?? 0) + 1;
      }

      await statsRef.update({
        'totalSessions': newTotal,
        'averageBandScore': newAverage,
        'commonErrors': updatedErrors,
        'lastSessionAt': FieldValue.serverTimestamp(),
      });
    }
  }

  Future<SpeakingSession?> getSession(String sessionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final doc = await _sessionsCollection(user.uid).doc(sessionId).get();
    if (!doc.exists) return null;

    return SpeakingSession.fromFirestore(doc);
  }

  Stream<List<SpeakingSession>> watchSessions({int limit = 50}) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value([]);
    }

    return _sessionsCollection(user.uid)
        .orderBy('timestampMs', descending: true)
        .limit(limit)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs
              .map((doc) => SpeakingSession.fromFirestore(doc))
              .toList();
        });
  }

  Future<List<SpeakingSession>> getSessions({
    int limit = 50,
    DateTime? startAfter,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    Query<Map<String, dynamic>> query = _sessionsCollection(
      user.uid,
    ).orderBy('timestampMs', descending: true);

    if (startAfter != null) {
      query = query.startAfter([startAfter.millisecondsSinceEpoch]);
    }

    final snapshot = await query.limit(limit).get();
    return snapshot.docs
        .map((doc) => SpeakingSession.fromFirestore(doc))
        .toList();
  }

  Future<SpeakingStats> getStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const SpeakingStats(
        totalSessions: 0,
        averageBandScore: 0.0,
        commonErrors: {},
      );
    }

    final doc = await _statsDocument(user.uid).get();
    return SpeakingStats.fromFirestore(doc);
  }

  Stream<SpeakingStats> watchStats() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return Stream.value(
        const SpeakingStats(
          totalSessions: 0,
          averageBandScore: 0.0,
          commonErrors: {},
        ),
      );
    }

    return _statsDocument(
      user.uid,
    ).snapshots().map((doc) => SpeakingStats.fromFirestore(doc));
  }

  Future<String> shareToCommunity(SpeakingSession session) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final docRef = await _communityCollection().add(session.toCommunitySafe());

    return docRef.id;
  }

  Stream<List<Map<String, dynamic>>> watchCommunity({
    int limit = 20,
    double? minBandScore,
    double? maxBandScore,
  }) {
    Query<Map<String, dynamic>> query = _communityCollection().orderBy(
      'likesCount',
      descending: true,
    );

    if (minBandScore != null) {
      query = query.where('bandScore', isGreaterThanOrEqualTo: minBandScore);
    }

    if (maxBandScore != null) {
      query = query.where('bandScore', isLessThanOrEqualTo: maxBandScore);
    }

    return query.limit(limit).snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        final data = doc.data();
        data['id'] = doc.id;
        return data;
      }).toList();
    });
  }

  Future<void> likeCommunitySession(String sessionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _communityCollection().doc(sessionId).update({
      'likesCount': FieldValue.increment(1),
    });
  }

  Future<void> deleteSession(String sessionId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    await _sessionsCollection(user.uid).doc(sessionId).delete();
  }
}
