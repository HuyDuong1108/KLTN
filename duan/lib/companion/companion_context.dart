import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/stats_api.dart';

/// Snapshot của user context tại thời điểm gửi lên AI.
class CompanionContextSnapshot {
  final String? name;
  final String? level;
  final double? latestBand;
  final String? latestSkill;
  final String? weakSkill;
  final int? streakDays;
  final int? flashcardSetsCount;
  final String? currentPage;
  final String? recentActivity;

  const CompanionContextSnapshot({
    this.name,
    this.level,
    this.latestBand,
    this.latestSkill,
    this.weakSkill,
    this.streakDays,
    this.flashcardSetsCount,
    this.currentPage,
    this.recentActivity,
  });

  const CompanionContextSnapshot.empty() : this();

  Map<String, dynamic> toJson() => {
        if (name != null) "name": name,
        if (level != null) "level": level,
        if (latestBand != null) "latest_band": latestBand,
        if (latestSkill != null) "latest_skill": latestSkill,
        if (weakSkill != null) "weak_skill": weakSkill,
        if (streakDays != null) "streak_days": streakDays,
        if (flashcardSetsCount != null)
          "flashcard_sets_count": flashcardSetsCount,
        if (currentPage != null) "current_page": currentPage,
        if (recentActivity != null) "recent_activity": recentActivity,
      };

  CompanionContextSnapshot copyWith({
    String? name,
    String? level,
    double? latestBand,
    String? latestSkill,
    String? weakSkill,
    int? streakDays,
    int? flashcardSetsCount,
    String? currentPage,
    String? recentActivity,
  }) {
    return CompanionContextSnapshot(
      name: name ?? this.name,
      level: level ?? this.level,
      latestBand: latestBand ?? this.latestBand,
      latestSkill: latestSkill ?? this.latestSkill,
      weakSkill: weakSkill ?? this.weakSkill,
      streakDays: streakDays ?? this.streakDays,
      flashcardSetsCount: flashcardSetsCount ?? this.flashcardSetsCount,
      currentPage: currentPage ?? this.currentPage,
      recentActivity: recentActivity ?? this.recentActivity,
    );
  }
}

/// Service gom context cho companion.
/// - Fetch song song từ Firestore + backend stats.
/// - Cache với TTL để tránh hammer Firestore mỗi tin nhắn.
/// - Page bên ngoài gọi `setCurrentPage()` + `setRecentActivity()` để enrich.
class CompanionContextService {
  CompanionContextService._();
  static final CompanionContextService instance = CompanionContextService._();

  String? _currentPage;
  String? _recentActivity;
  DateTime? _recentActivityAt;

  // Cache
  CompanionContextSnapshot? _cached;
  DateTime? _cachedAt;
  String? _cachedUid;
  static const _cacheTtl = Duration(minutes: 2);

  /// Các page gọi hàm này khi build xong để AI biết user đang ở đâu.
  /// Ví dụ: "Dashboard", "Flashcard Community", "Listening Test".
  void setCurrentPage(String? page) {
    _currentPage = page;
  }

  String? get currentPage => _currentPage;

  /// Page gọi sau khi user hoàn thành 1 action đáng kể.
  /// Ví dụ: "Vừa hoàn thành Listening Test 1 (band 6.5)"
  /// Chỉ giữ trong 10 phút — sau đó coi như stale.
  void setRecentActivity(String activity) {
    _recentActivity = activity;
    _recentActivityAt = DateTime.now();
    // invalidate cache để snapshot sau phản ánh activity mới
    _cached = null;
  }

  String? _activeRecentActivity() {
    if (_recentActivity == null || _recentActivityAt == null) return null;
    final diff = DateTime.now().difference(_recentActivityAt!);
    if (diff.inMinutes >= 10) return null;
    return _recentActivity;
  }

  /// Gom snapshot. Dùng cache nếu còn valid.
  Future<CompanionContextSnapshot> collect({bool forceRefresh = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return CompanionContextSnapshot(currentPage: _currentPage);
    }

    final uid = user.uid;
    final now = DateTime.now();

    // Trả cache nếu còn hạn (nhưng vẫn override currentPage + recentActivity)
    if (!forceRefresh &&
        _cached != null &&
        _cachedUid == uid &&
        _cachedAt != null &&
        now.difference(_cachedAt!) < _cacheTtl) {
      return _cached!.copyWith(
        currentPage: _currentPage,
        recentActivity: _activeRecentActivity(),
      );
    }

    // Fetch song song các nguồn dữ liệu
    final results = await Future.wait<dynamic>([
      _fetchUserDoc(uid).catchError((_) => null),
      _fetchLatestTest(uid).catchError((_) => null),
      _fetchFlashcardCount(uid).catchError((_) => 0),
      _fetchStreak().catchError((_) => null),
    ]);

    final userDoc = results[0] as _UserInfo?;
    final latest = results[1] as _LatestTestInfo?;
    final flashcardCount = results[2] as int?;
    final streak = results[3] as int?;

    String? recent = _activeRecentActivity();
    if (recent == null && latest != null && latest.submittedAt != null) {
      // Suy ra activity gần nhất từ latestTest nếu chưa có explicit
      final diff = DateTime.now().difference(latest.submittedAt!);
      if (diff.inHours < 24) {
        recent =
            "Vừa hoàn thành ${latest.testType ?? 'test'} (band ${latest.band ?? '?'})";
      }
    }

    final snap = CompanionContextSnapshot(
      name: userDoc?.name,
      level: userDoc?.level,
      latestBand: latest?.band,
      latestSkill: latest?.testType,
      streakDays: streak,
      flashcardSetsCount: flashcardCount,
      currentPage: _currentPage,
      recentActivity: recent,
    );

    _cached = snap;
    _cachedAt = now;
    _cachedUid = uid;

    return snap;
  }

  /// Clear cache khi user logout.
  void clearCache() {
    _cached = null;
    _cachedAt = null;
    _cachedUid = null;
    _currentPage = null;
    _recentActivity = null;
    _recentActivityAt = null;
  }

  // ---------------- FETCHERS ----------------

  Future<_UserInfo?> _fetchUserDoc(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .get();
    if (!doc.exists) return null;
    final d = doc.data()!;
    String? name;
    final n = d["name"];
    if (n is String && n.trim().isNotEmpty) name = n.trim();
    String? level;
    final l = d["level"] ?? d["englishLevel"];
    if (l is String && l.trim().isNotEmpty) level = l.trim();
    return _UserInfo(name: name, level: level);
  }

  Future<_LatestTestInfo?> _fetchLatestTest(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("latestTest")
        .doc("result")
        .get();
    if (!doc.exists) return null;
    final d = doc.data()!;
    double? band;
    final b = d["band"];
    if (b is num) band = b.toDouble();
    DateTime? ts;
    final sa = d["submittedAt"];
    if (sa is Timestamp) ts = sa.toDate();
    return _LatestTestInfo(
      testType: (d["testType"] ?? "").toString().isEmpty
          ? null
          : d["testType"].toString(),
      band: band,
      submittedAt: ts,
    );
  }

  Future<int?> _fetchFlashcardCount(String uid) async {
    try {
      // AggregateQuery count — nhanh, không cần load toàn bộ docs
      final agg = await FirebaseFirestore.instance
          .collection("flashcards")
          .doc(uid)
          .collection("userFlashcards")
          .count()
          .get();
      return agg.count;
    } catch (_) {
      // Fallback: count bằng cách query — chậm hơn nhưng chắc chắn
      final snap = await FirebaseFirestore.instance
          .collection("flashcards")
          .doc(uid)
          .collection("userFlashcards")
          .get();
      return snap.docs.length;
    }
  }

  Future<int?> _fetchStreak() async {
    try {
      final summary = await StatsApi.instance.fetchSummary();
      return summary.streakCurrent;
    } catch (_) {
      return null;
    }
  }
}

class _UserInfo {
  final String? name;
  final String? level;
  _UserInfo({this.name, this.level});
}

class _LatestTestInfo {
  final String? testType;
  final double? band;
  final DateTime? submittedAt;
  _LatestTestInfo({this.testType, this.band, this.submittedAt});
}
