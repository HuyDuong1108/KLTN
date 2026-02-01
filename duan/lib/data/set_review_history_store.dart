import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class SetReviewHistoryEntry {
  final String id;
  final DateTime createdAt;
  final String mode; // flashcard | quiz | typing | due

  final int total;

  // flashcard buckets
  final int again;
  final int hard;
  final int good;
  final int easy;

  // quiz/typing buckets
  final int correct;
  final int wrong;

  const SetReviewHistoryEntry({
    required this.id,
    required this.createdAt,
    required this.mode,
    required this.total,
    this.again = 0,
    this.hard = 0,
    this.good = 0,
    this.easy = 0,
    this.correct = 0,
    this.wrong = 0,
  });

  String get modeLabel {
    final m = mode.toLowerCase().trim();
    if (m.contains('quiz')) return 'Quiz';
    if (m.contains('typing')) return 'Typing';
    if (m.contains('due')) return 'Due';
    return 'Flashcard';
  }

  Map<String, dynamic> toMapForWrite() => {
    'createdAt': FieldValue.serverTimestamp(),
    'createdAtMs': DateTime.now().millisecondsSinceEpoch,
    'mode': mode,
    'total': total,
    'again': again,
    'hard': hard,
    'good': good,
    'easy': easy,
    'correct': correct,
    'wrong': wrong,
  };

  static int _asInt(dynamic v) {
    if (v is int) return v;
    if (v is double) return v.round();
    return int.tryParse(v?.toString() ?? '') ?? 0;
  }

  factory SetReviewHistoryEntry.fromDoc(
    QueryDocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data();

    final ts = data['createdAt'];
    DateTime createdAt;

    if (ts is Timestamp) {
      createdAt = ts.toDate();
    } else if (ts is int) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(ts);
    } else if (ts is double) {
      createdAt = DateTime.fromMillisecondsSinceEpoch(ts.round());
    } else if (ts is String) {
      createdAt = DateTime.tryParse(ts) ?? DateTime.fromMillisecondsSinceEpoch(0);
    } else {
      createdAt = DateTime.fromMillisecondsSinceEpoch(0);
    }

    return SetReviewHistoryEntry(
      id: doc.id,
      createdAt: createdAt,
      mode: (data['mode'] ?? 'flashcard').toString(),
      total: _asInt(data['total']),
      again: _asInt(data['again']),
      hard: _asInt(data['hard']),
      good: _asInt(data['good']),
      easy: _asInt(data['easy']),
      correct: _asInt(data['correct']),
      wrong: _asInt(data['wrong']),
    );
  }
}

class SetReviewHistoryStore {
  SetReviewHistoryStore._();
  static final SetReviewHistoryStore instance = SetReviewHistoryStore._();

  CollectionReference<Map<String, dynamic>> _collection({
    required String uid,
    required String setId,
    required bool isPersonal,
  }) {
    if (isPersonal) {
      return FirebaseFirestore.instance
          .collection('flashcards')
          .doc(uid)
          .collection('userFlashcards')
          .doc(setId)
          .collection('reviewSessions');
    }

    return FirebaseFirestore.instance
        .collection('flashcard_sets')
        .doc(setId)
        .collection('userProgress')
        .doc(uid)
        .collection('reviewSessions');
  }

  Future<List<SetReviewHistoryEntry>> listForSet({
    required String setId,
    required bool isPersonal,
    int limit = 50,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return <SetReviewHistoryEntry>[];

    final col = _collection(uid: user.uid, setId: setId, isPersonal: isPersonal);

    final qs = await col
        .orderBy('createdAt', descending: true)
        .limit(limit)
        .get();

    return qs.docs.map((d) => SetReviewHistoryEntry.fromDoc(d)).toList();
  }

  Future<void> addEntry({
    required String setId,
    required bool isPersonal,
    required SetReviewHistoryEntry entry,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final col = _collection(uid: user.uid, setId: setId, isPersonal: isPersonal);
    await col.add(entry.toMapForWrite());
  }

  Future<void> deleteEntry({
    required String setId,
    required bool isPersonal,
    required String entryId,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final col = _collection(uid: user.uid, setId: setId, isPersonal: isPersonal);
    await col.doc(entryId).delete();
  }

  Future<void> clearSet({
    required String setId,
    required bool isPersonal,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final col = _collection(uid: user.uid, setId: setId, isPersonal: isPersonal);

    const pageSize = 200;
    while (true) {
      final qs = await col.orderBy('createdAt', descending: true).limit(pageSize).get();
      if (qs.docs.isEmpty) break;

      final batch = FirebaseFirestore.instance.batch();
      for (final d in qs.docs) {
        batch.delete(d.reference);
      }
      await batch.commit();

      if (qs.docs.length < pageSize) break;
    }
  }
   Future<DateTime?> getLastSessionTime({
    required String setId,
    required bool isPersonal,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    final sid = setId.trim();
    if (sid.isEmpty) return null;

    final col = _collection(uid: user.uid, setId: sid, isPersonal: isPersonal);

    try {
      final qs = await col
          .orderBy('createdAtMs', descending: true)
          .limit(1)
          .get();

      if (qs.docs.isEmpty) return null;

      final data = qs.docs.first.data();

      final ms = data['createdAtMs'];
      if (ms is int && ms > 0) {
        return DateTime.fromMillisecondsSinceEpoch(ms).toLocal();
      }
      if (ms is double && ms > 0) {
        return DateTime.fromMillisecondsSinceEpoch(ms.round()).toLocal();
      }

      // fallback
      final ts = data['createdAt'];
      if (ts is Timestamp) return ts.toDate().toLocal();

      return null;
    } catch (_) {
      return null;
    }
  }
}
