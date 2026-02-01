import 'package:cloud_firestore/cloud_firestore.dart';

class AddVocabsResult {
  AddVocabsResult({
    required this.added,
    required this.skipped,
    required this.skippedWords,
  });

  final int added;
  final int skipped; // số từ bị bỏ qua vì đã tồn tại
  final List<String> skippedWords; // danh sách từ bị bỏ qua (unique)
}

class CreateSetWithVocabsResult {
  CreateSetWithVocabsResult({
    required this.setId,
    required this.result,
  });

  final String setId;
  final AddVocabsResult result;
}

class LearningToFlashcardsService {
  LearningToFlashcardsService(this._db);
  final FirebaseFirestore _db;

  CollectionReference<Map<String, dynamic>> _userSets(String uid) {
    return _db.collection('flashcards').doc(uid).collection('userFlashcards');
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> watchUserSets(String uid) {
    // createdAt có thể null ở set cũ, nên không orderBy để tránh lỗi index
    return _userSets(uid).snapshots();
  }

  Future<String> createUserSet({
    required String uid,
    required String title,
    required String description,
    Map<String, dynamic>? source,
  }) async {
    final doc = _userSets(uid).doc();
    await doc.set({
      'title': title,
      'description': description,
      'participants': 1,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
      'vocabList': <Map<String, dynamic>>[],
      if (source != null) 'source': source,
    }, SetOptions(merge: true));
    return doc.id;
  }

  // NEW: trả kết quả added / skipped để UI báo đúng
  Future<AddVocabsResult> addVocabsToSetWithResult({
    required String uid,
    required String setId,
    required List<Map<String, dynamic>> vocabs,
  }) async {
    final ref = _userSets(uid).doc(setId);

    return _db.runTransaction<AddVocabsResult>((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) {
        throw StateError('Bộ thẻ không tồn tại nữa.');
      }
      final data = (snap.data() ?? <String, dynamic>{});

      final raw = data['vocabList'];
      final List<Map<String, dynamic>> current = [];

      if (raw is List) {
        for (final e in raw) {
          if (e is Map) current.add(Map<String, dynamic>.from(e));
        }
      } else if (raw is Map) {
        for (final e in raw.values) {
          if (e is Map) current.add(Map<String, dynamic>.from(e));
        }
      }

      final existing = <String>{};
      for (final e in current) {
        final w = (e['word'] ?? '').toString().trim();
        if (w.isNotEmpty) existing.add(w);
      }

      final addedWords = <String>[];
      final skippedWords = <String>[];
      final skippedSet = <String>{};

      for (final v in vocabs) {
        final w = (v['word'] ?? '').toString().trim();
        if (w.isEmpty) continue;

        if (existing.contains(w)) {
          // chỉ list unique để UI show gọn
          if (!skippedSet.contains(w)) {
            skippedSet.add(w);
            skippedWords.add(w);
          }
          continue;
        }

        current.add(v);
        existing.add(w);
        addedWords.add(w);
      }

      final hasNew = addedWords.isNotEmpty;

      if (hasNew) {
        tx.set(ref, {
          'vocabList': current,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
      }

      return AddVocabsResult(
        added: addedWords.length,
        skipped: skippedWords.length,
        skippedWords: skippedWords,
      );
    });
  }

  // OLD: giữ nguyên signature để không vỡ chỗ đang gọi
  Future<void> addVocabsToSet({
    required String uid,
    required String setId,
    required List<Map<String, dynamic>> vocabs,
  }) async {
    await addVocabsToSetWithResult(uid: uid, setId: setId, vocabs: vocabs);
  }

  // NEW: tạo set + trả luôn kết quả add
  Future<CreateSetWithVocabsResult> createSetWithVocabsWithResult({
    required String uid,
    required String title,
    required String description,
    required List<Map<String, dynamic>> vocabs,
    Map<String, dynamic>? source,
  }) async {
    final setId = await createUserSet(
      uid: uid,
      title: title,
      description: description,
      source: source,
    );

    final res = await addVocabsToSetWithResult(
      uid: uid,
      setId: setId,
      vocabs: vocabs,
    );

    return CreateSetWithVocabsResult(setId: setId, result: res);
  }

  // OLD: giữ nguyên signature để không vỡ chỗ đang gọi
  Future<String> createSetWithVocabs({
    required String uid,
    required String title,
    required String description,
    required List<Map<String, dynamic>> vocabs,
    Map<String, dynamic>? source,
  }) async {
    final out = await createSetWithVocabsWithResult(
      uid: uid,
      title: title,
      description: description,
      vocabs: vocabs,
      source: source,
    );
    return out.setId;
  }
}
