import 'package:cloud_firestore/cloud_firestore.dart';
import 'models/companion_message.dart';

/// Firestore structure:
///
///   users/{uid}/companion_profile/profile
///     - characterId: string
///     - memorySummary: string
///     - lastSummarizedAt: timestamp
///
///   users/{uid}/companion_messages/{autoId}
///     - role: "user" | "model"
///     - content: string
///     - createdAt: int (ms since epoch, dùng server-side sort được)
///     - suggestions: `List<String>`
class CompanionMemoryStore {
  CompanionMemoryStore._();
  static final CompanionMemoryStore instance = CompanionMemoryStore._();

  // ---------------- REFS ----------------
  DocumentReference<Map<String, dynamic>> _profileDoc(String uid) {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("companion_profile")
        .doc("profile");
  }

  CollectionReference<Map<String, dynamic>> _messagesCol(String uid) {
    return FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("companion_messages");
  }

  // ---------------- PROFILE ----------------
  Future<CompanionProfile> loadProfile(String uid) async {
    try {
      final doc = await _profileDoc(uid).get();
      if (!doc.exists) return const CompanionProfile();
      final data = doc.data() ?? const {};
      return CompanionProfile(
        characterId: data["characterId"] as String?,
        memorySummary: (data["memorySummary"] ?? "").toString(),
        lastSummarizedAt: data["lastSummarizedAt"] is Timestamp
            ? (data["lastSummarizedAt"] as Timestamp).toDate()
            : null,
      );
    } catch (_) {
      return const CompanionProfile();
    }
  }

  Future<void> saveCharacter(String uid, String characterId) async {
    await _profileDoc(uid).set(
      {"characterId": characterId},
      SetOptions(merge: true),
    );
  }

  Future<void> saveMemorySummary(String uid, String summary) async {
    await _profileDoc(uid).set(
      {
        "memorySummary": summary,
        "lastSummarizedAt": FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  // ---------------- MESSAGES ----------------
  /// Load N tin gần nhất, sắp xếp theo thời gian tăng dần (cũ → mới)
  /// để render trực tiếp vào list.
  Future<List<CompanionMessage>> loadRecent(String uid, {int limit = 20}) async {
    final snap = await _messagesCol(uid)
        .orderBy("createdAt", descending: true)
        .limit(limit)
        .get();
    final list = snap.docs
        .map((d) => CompanionMessage.fromFirestore(d.data()))
        .toList()
        .reversed
        .toList();
    return list;
  }

  /// Lưu 1 message. Trả về docId (không cần dùng thường xuyên).
  Future<String> appendMessage(String uid, CompanionMessage msg) async {
    final ref = await _messagesCol(uid).add(msg.toFirestore());
    return ref.id;
  }

  /// Đếm nhanh tổng số message hiện có (aggregate, 1 read).
  Future<int> countMessages(String uid) async {
    try {
      final agg = await _messagesCol(uid).count().get();
      return agg.count ?? 0;
    } catch (_) {
      // Fallback (hiếm khi cần)
      final snap = await _messagesCol(uid).get();
      return snap.docs.length;
    }
  }

  /// Lấy message cũ hơn 20 tin gần nhất (dùng để feed summarizer).
  /// Trả về list theo thứ tự thời gian tăng dần.
  Future<List<CompanionMessage>> loadOlderThanRecent(
    String uid, {
    int keepRecent = 20,
  }) async {
    // Phân trang: lấy tất cả tin rồi cắt — hoặc query skip.
    // Firestore không có OFFSET, nên dùng cursor dựa trên doc thứ keepRecent mới nhất.
    final latestN = await _messagesCol(uid)
        .orderBy("createdAt", descending: true)
        .limit(keepRecent)
        .get();
    if (latestN.docs.length < keepRecent) return const [];

    final cursor = latestN.docs.last; // doc cũ nhất trong N gần nhất
    final older = await _messagesCol(uid)
        .orderBy("createdAt", descending: true)
        .startAfterDocument(cursor)
        .get();

    final list = older.docs
        .map((d) => CompanionMessage.fromFirestore(d.data()))
        .toList()
        .reversed
        .toList();
    return list;
  }

  /// Xoá các message cũ hơn 20 tin gần nhất (dùng sau khi summarize xong).
  Future<void> deleteOlderThanRecent(
    String uid, {
    int keepRecent = 20,
  }) async {
    final latestN = await _messagesCol(uid)
        .orderBy("createdAt", descending: true)
        .limit(keepRecent)
        .get();
    if (latestN.docs.length < keepRecent) return;

    final cursor = latestN.docs.last;
    final older = await _messagesCol(uid)
        .orderBy("createdAt", descending: true)
        .startAfterDocument(cursor)
        .get();

    // Batch xoá (tối đa 500 op/batch)
    const batchSize = 400;
    final docs = older.docs;
    for (int i = 0; i < docs.length; i += batchSize) {
      final batch = FirebaseFirestore.instance.batch();
      for (int j = i; j < i + batchSize && j < docs.length; j++) {
        batch.delete(docs[j].reference);
      }
      await batch.commit();
    }
  }

  /// Xoá toàn bộ messages + reset profile (dùng cho nút "Bắt đầu cuộc trò chuyện mới").
  Future<void> clearAll(String uid) async {
    // Xoá tất cả messages
    final all = await _messagesCol(uid).get();
    const batchSize = 400;
    for (int i = 0; i < all.docs.length; i += batchSize) {
      final batch = FirebaseFirestore.instance.batch();
      for (int j = i; j < i + batchSize && j < all.docs.length; j++) {
        batch.delete(all.docs[j].reference);
      }
      await batch.commit();
    }
    // Reset summary (giữ characterId để user không phải chọn lại)
    await _profileDoc(uid).set(
      {
        "memorySummary": "",
        "lastSummarizedAt": null,
      },
      SetOptions(merge: true),
    );
  }
}

class CompanionProfile {
  final String? characterId;
  final String memorySummary;
  final DateTime? lastSummarizedAt;

  const CompanionProfile({
    this.characterId,
    this.memorySummary = "",
    this.lastSummarizedAt,
  });
}
