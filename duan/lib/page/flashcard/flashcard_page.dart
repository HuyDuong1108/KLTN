import 'dart:async';
import 'package:flutter/material.dart';
import '../../models/flashcard_set.dart';
import '../../models/vocabulary.dart';
import '../../models/stats_progress.dart';
import 'flashcard_set_detail.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../data/set_review_history_store.dart';
import '../../data/stats_api.dart';

class FlashcardPage extends StatefulWidget {
  const FlashcardPage({super.key});

  @override
  State<FlashcardPage> createState() => _FlashcardPageState();
}

class _LastReviewIndex {
  final Map<String, DateTime> bySetKey;    // p::<setId> | c::<setId>
  final Map<String, DateTime> byTitleNorm; // normalized title

  const _LastReviewIndex({
    required this.bySetKey,
    required this.byTitleNorm,
  });

  static const empty = _LastReviewIndex(bySetKey: {}, byTitleNorm: {});
}

class _FlashcardPageState extends State<FlashcardPage>
    with TickerProviderStateMixin {
  late TabController _tabController;
  bool isOffline = false;
  late final StreamSubscription _connectivitySub;

  Future<_LastReviewIndex>? _lastReviewIndexFuture;

  String _normTitle(String s) {
    return s.trim().replaceAll(RegExp(r'\s+'), ' ').toLowerCase();
  }

  String _setKey({required String setId, required bool isPersonal}) {
    return '${isPersonal ? 'p' : 'c'}::$setId';
  }

  String? _extractSetId(dynamic match) {
    if (match == null) return null;

    if (match is Map) {
      final v = match['setId'] ?? match['set_id'] ?? match['setDocId'] ?? match['set_doc_id'];
      if (v is String && v.trim().isNotEmpty) return v.trim();
      return null;
    }

    try {
      final v = (match as dynamic).setId;
      if (v is String && v.trim().isNotEmpty) return v.trim();
    } catch (_) {}

    try {
      final v = (match as dynamic).set_id;
      if (v is String && v.trim().isNotEmpty) return v.trim();
    } catch (_) {}

    return null;
  }

  bool? _extractIsPersonal(dynamic match) {
    if (match == null) return null;

    if (match is Map) {
      final v = match['isPersonal'] ?? match['is_personal'] ?? match['personal'];
      if (v is bool) return v;
      if (v is int) return v != 0;
      if (v is String) {
        final s = v.trim().toLowerCase();
        if (s == 'true' || s == '1') return true;
        if (s == 'false' || s == '0') return false;
      }
      return null;
    }

    try {
      final v = (match as dynamic).isPersonal;
      if (v is bool) return v;
    } catch (_) {}

    try {
      final v = (match as dynamic).is_personal;
      if (v is bool) return v;
    } catch (_) {}

    return null;
  }

  String? _extractSetTitle(dynamic match) {
    if (match == null) return null;

    if (match is Map) {
      final v = match['setTitle'] ?? match['set_title'] ?? match['set'];
      if (v is String && v.trim().isNotEmpty) return v.trim();
      return null;
    }

    try {
      final v = (match as dynamic).setTitle;
      if (v is String && v.trim().isNotEmpty) return v.trim();
    } catch (_) {}

    return null;
  }

  DateTime? _parseLocalTs(String ts) {
    if (ts.trim().isEmpty) return null;
    try {
      return DateTime.parse(ts).toLocal();
    } catch (_) {
      return null;
    }
  }

  Future<_LastReviewIndex> _loadLastReviewIndexFromStats() async {
    try {
      final StatsProgress p = await StatsApi.instance.fetchProgress();

      final bySetKey = <String, DateTime>{};
      final byTitleNorm = <String, DateTime>{};

      for (final e in p.recent) {
        final dt = _parseLocalTs(e.ts);
        if (dt == null) continue;

        final title = _extractSetTitle(e.match);
        if (title != null) {
          final k = _normTitle(title);
          final prev = byTitleNorm[k];
          if (prev == null || dt.isAfter(prev)) byTitleNorm[k] = dt;
        }

        final setId = _extractSetId(e.match);
        final isPersonal = _extractIsPersonal(e.match);
        if (setId != null && isPersonal != null) {
          final k = _setKey(setId: setId, isPersonal: isPersonal);
          final prev = bySetKey[k];
          if (prev == null || dt.isAfter(prev)) bySetKey[k] = dt;
        }
      }

      return _LastReviewIndex(bySetKey: bySetKey, byTitleNorm: byTitleNorm);
    } catch (_) {
      return _LastReviewIndex.empty;
    }
  }

  Widget _buildLastReviewLabel({
  required _LastReviewIndex idx,
  required String setId,
  required bool isPersonal,
  required String setTitle,
}) {
    DateTime? statsDt;

    final key = _setKey(setId: setId, isPersonal: isPersonal);
    statsDt = idx.bySetKey[key];
    statsDt ??= idx.byTitleNorm[_normTitle(setTitle)];

    final future = _lastAnyModeFutureBySetKey.putIfAbsent(
      key,
      () => SetReviewHistoryStore.instance.getLastSessionTime(
        setId: setId,
        isPersonal: isPersonal,
      ),
    );

    final style = TextStyle(
      fontSize: 12,
      color: Colors.grey.shade500,
      fontWeight: FontWeight.w600,
    );

    return FutureBuilder<DateTime?>(
      future: future,
      builder: (context, snap) {
        final sessionDt = snap.data;

        DateTime? dt = statsDt;
        if (sessionDt != null && (dt == null || sessionDt.isAfter(dt))) {
          dt = sessionDt;
        }

        if (dt == null) {
          return Text('Chưa ôn tập', style: style);
        }

        final text = _formatLastReviewLabel(dt);

        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.history_rounded, size: 14, color: Colors.grey.shade500),
            const SizedBox(width: 4),
            Text(text, style: style),
          ],
        );
      },
    );
  }


  void _refreshLastReviewIndex() {
    _lastReviewIndexFuture = _loadLastReviewIndexFromStats();
    _lastAnyModeFutureBySetKey.clear();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    _refreshLastReviewIndex();

    _connectivitySub = Connectivity().onConnectivityChanged.listen((result) {
      setState(() {
        isOffline = result == ConnectivityResult.none;
      });

      if (result != ConnectivityResult.none) {
        setState(_refreshLastReviewIndex);
      }
    });
  }


  @override
  void dispose() {
    _tabController.dispose();
    _connectivitySub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      floatingActionButton: isOffline
          ? null
          : FloatingActionButton(
              backgroundColor: Colors.orange,
              onPressed: () => showAddFlashcardSheet(context),
              child: const Icon(Icons.add, color: Colors.white),
            ),

      body: Column(
        children: [
          // OFFLINE BANNER
          if (isOffline)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              color: Colors.orange.shade100,
              child: const Text(
                "Bạn đang offline dữ liệu sẽ đồng bộ khi có mạng",
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
            ),

          // TAB BAR
          Container(
            color: Colors.white,
            child: TabBar(
              controller: _tabController,
              labelColor: const Color(0xFFFF8F00),
              unselectedLabelColor: const Color(0xFFB0BEC5),
              indicatorColor: const Color(0xFFFF8F00),
              labelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
              unselectedLabelStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
              tabs: const [
                Tab(text: "Cộng đồng"),
                Tab(text: "Cá nhân"),
              ],
            ),
          ),

          // TAB CONTENT
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                // Cộng đồng (Firestore)
                _buildCommunityFlashcards(),

                // Cá nhân (Firestore)
                _buildPersonalFlashcards(),
              ],
            ),
          ),
        ],
      ),
    );
  }
  // final Map<String, Future<String>> _lastReviewLabelCache = {};
  // final Map<String, Future<Map<String, DateTime>>> _lastReviewMapCache = {};



  String _cacheKey({required String setId, required bool isPersonal}) {
    return '${isPersonal ? 'p' : 'c'}::$setId';
  }

  String _two(int n) => n.toString().padLeft(2, '0');

  String _formatLastReviewLabel(DateTime dt) {
    if (dt.millisecondsSinceEpoch <= 0) return 'Chưa ôn tập';

    final now = DateTime.now();
    final local = dt.toLocal();

    final sameDay = now.year == local.year &&
        now.month == local.month &&
        now.day == local.day;

    if (sameDay) {
      return '${_two(local.hour)}:${_two(local.minute)}';
    }

    final nowDate = DateTime(now.year, now.month, now.day);
    final thenDate = DateTime(local.year, local.month, local.day);
    final days = nowDate.difference(thenDate).inDays;

    if (days <= 0) {
      return '${_two(local.hour)}:${_two(local.minute)}';
    }

    if (days < 7) return '$days ngày trước';
    if (days < 30) return '1 tuần trước';

    if (days < 365) {
      final months = (days / 30).floor();
      final m = months < 1 ? 1 : months;
      return '$m tháng trước';
    }

    final years = (days / 365).floor();
    final y = years < 1 ? 1 : years;
    return '$y năm trước';
  }
  final Map<String, Future<DateTime?>> _lastAnyModeFutureBySetKey = {};
  Future<Map<String, DateTime>> _loadLastReviewMapFromStats() async {
    try {
      // Cần dùng đúng hàm đang được StatisticsDetailPage gọi để lấy StatsProgress.
      // Ví dụ phổ biến: StatsApi.instance.fetchProgress()
      final StatsProgress p = await StatsApi.instance.fetchProgress();

      final map = <String, DateTime>{};

      for (final e in p.recent) {
        final title = _extractSetTitle(e.match);
        if (title == null) continue;

        final dt = _parseLocalTs(e.ts);
        if (dt == null) continue;

        final prev = map[title];
        if (prev == null || dt.isAfter(prev)) {
          map[title] = dt;
        }
      }

      return map;
    } catch (_) {
      return <String, DateTime>{};
    }
  }

  // Future<Map<String, DateTime>> _ensureLastReviewMap({
  //   required bool isPersonal,
  // }) {
  //   final key = isPersonal ? 'p' : 'c';
  //   return _lastReviewMapCache.putIfAbsent(key, () => _loadLastReviewMapFromStats());
  // }

  



  // ================== TAB CỘNG ĐỒNG ==================
  Widget _buildCommunityFlashcards() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('flashcard_sets')
          .where('isCommunity', isEqualTo: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Chưa có bộ cộng đồng nào"));
        }

        final communitySets = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return FlashcardSet(
            id: doc.id,
            title: data['title'] ?? '',
            description: data['description'] ?? '',
            vocabList: (data['vocabList'] as List<dynamic>? ?? [])
                .map(
                  (v) => Vocabulary(
                    word: v['word'] ?? '',
                    romaji: v['romaji'] ?? '',
                    meaning: v['meaning'] ?? '',
                  ),
                )
                .toList(),
            participants: data['participants'] ?? 1,
          );
        }).toList();

        return FutureBuilder<_LastReviewIndex>(
          future: _lastReviewIndexFuture,
          builder: (context, snap) {
            final idx = snap.data ?? _LastReviewIndex.empty;
            return _buildFlashcardList(communitySets, isPersonal: false, idx: idx);
          },
        );

      },
    );
  }

  // ================== TAB CÁ NHÂN ==================
  Widget _buildPersonalFlashcards() {
    final userId = FirebaseAuth.instance.currentUser?.uid;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('flashcards')
          .doc(userId)
          .collection('userFlashcards')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(child: Text("Chưa có bộ flashcard nào"));
        }

        final userSets = snapshot.data!.docs.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return FlashcardSet(
            id: doc.id,
            title: data['title'] ?? 'Không có tiêu đề',
            description: data['description'] ?? '',
            vocabList: (data['vocabList'] as List<dynamic>? ?? [])
                .map(
                  (v) => Vocabulary(
                    word: v['word'] ?? '',
                    romaji: v['romaji'] ?? '',
                    meaning: v['meaning'] ?? '',
                  ),
                )
                .toList(),
            participants: data['participants'] ?? 1,
          );
        }).toList();

        return FutureBuilder<_LastReviewIndex>(
          future: _lastReviewIndexFuture,
          builder: (context, snap) {
            final idx = snap.data ?? _LastReviewIndex.empty;
            return _buildFlashcardList(userSets, isPersonal: true, idx: idx);
          },
        );

      },
    );
  }

  void _showFlashcardActions(BuildContext context, FlashcardSet set) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade100,
      clipBehavior: Clip.antiAlias,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),

              // SỬA
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.orangeAccent),
                title: const Text("Chỉnh sửa"),
                onTap: () {
                  Navigator.pop(context);
                  _showEditFlashcardSheet(context, set);
                },
              ),

              // XÓA
              ListTile(
                leading: const Icon(Icons.delete, color: Colors.orangeAccent),
                title: const Text("Xóa"),
                onTap: () {
                  Navigator.pop(context);
                  _confirmDelete(context, set);
                },
              ),

              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  void _showEditFlashcardSheet(BuildContext context, FlashcardSet set) {
    final titleController = TextEditingController(text: set.title);
    final descController = TextEditingController(text: set.description);

    final userId = FirebaseAuth.instance.currentUser!.uid;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade100,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(context).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                "Chỉnh sửa Flashcard",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: titleController,
                decoration: InputDecoration(
                  labelText: "Tiêu đề",
                  labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.orange.shade200,
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              TextField(
                controller: descController,
                decoration: InputDecoration(
                  labelText: "Mô tả",
                  labelStyle: TextStyle(fontWeight: FontWeight.w600),
                  filled: true,
                  fillColor: Colors.white,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: BorderSide(
                      color: Colors.orange.shade200,
                      width: 2,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 20),

              SizedBox(
                height: 50,
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: () async {
                    await FirebaseFirestore.instance
                        .collection('flashcards')
                        .doc(userId)
                        .collection('userFlashcards')
                        .doc(set.id)
                        .update({
                          "title": titleController.text.trim(),
                          "description": descController.text.trim(),
                        });

                    Navigator.pop(context);
                  },
                  child: const Text(
                    "LƯU",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================== HIỂN THỊ LIST ==================
  Widget _buildFlashcardList(
  List<FlashcardSet> sets, {
  required bool isPersonal,
  required _LastReviewIndex idx,
}) {
  if (sets.isEmpty) {
    return const Center(child: Text("Không có dữ liệu"));
  }

  return ListView.builder(
    padding: const EdgeInsets.all(16),
    itemCount: sets.length,
    itemBuilder: (context, index) {
      final set = sets[index];

      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.orange.shade200.withOpacity(0.4),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => FlashcardSetDetailPage(
                  set: set,
                  isPersonal: isPersonal,
                ),
              ),
            ).then((_) {
              if (!mounted) return;
              setState(_refreshLastReviewIndex);
            });
          },
          onLongPress: isPersonal ? () => _showFlashcardActions(context, set) : null,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.menu_book_rounded,
                        color: Colors.orange,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            set.title,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            set.description,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Icon(Icons.list_alt, size: 18, color: Colors.orange.shade700),
                              const SizedBox(width: 6),
                              Text("${set.vocabList.length} từ"),
                              const SizedBox(width: 16),
                              Icon(Icons.group, size: 18, color: Colors.blue.shade600),
                              const SizedBox(width: 6),
                              Text("${set.participants} người"),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios,
                      size: 18,
                      color: Colors.orange,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: _buildLastReviewLabel(
                    idx: idx,
                    setId: set.id,
                    isPersonal: isPersonal,
                    setTitle: set.title,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    },
  );
}


  void _confirmDelete(BuildContext context, FlashcardSet set) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        bool isDeleting = false;

        return StatefulBuilder(
          builder: (ctx, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 22),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Icon header
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red.shade400,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Title
                    const Text(
                      "Xóa flashcard",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Content
                    Text(
                      'Bạn có chắc muốn xóa "${set.title}" không?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Buttons (match app style)
                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: OutlinedButton(
                              onPressed: isDeleting
                                  ? null
                                  : () => Navigator.pop(dialogCtx),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orange.shade700,
                                side: BorderSide(
                                  color: Colors.orange.shade300,
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                "Hủy",
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton(
                              onPressed: isDeleting
                                  ? null
                                  : () async {
                                      setState(() => isDeleting = true);
                                      try {
                                        await FirebaseFirestore.instance
                                            .collection('flashcards')
                                            .doc(userId)
                                            .collection('userFlashcards')
                                            .doc(set.id)
                                            .delete();

                                        if (ctx.mounted)
                                          Navigator.pop(dialogCtx);
                                      } catch (e) {
                                        if (ctx.mounted) {
                                          Navigator.pop(dialogCtx);
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(content: Text("Lỗi: $e")),
                                          );
                                        }
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade400,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: isDeleting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      "Xóa",
                                      style: TextStyle(
                                        fontWeight: FontWeight.w900,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  // ================== TẠO FLASHCARD ==================
  void showAddFlashcardSheet(BuildContext context) {
    String title = '';
    String description = '';
    bool loading = false;

    final userId = FirebaseAuth.instance.currentUser?.uid ?? "anonymous";

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade100,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 12),

                  const Text(
                    "Tạo Flashcard mới",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Tiêu đề
                  TextField(
                    decoration: InputDecoration(
                      labelText: "Tiêu đề",
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.orange.shade200,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) => title = value,
                  ),

                  const SizedBox(height: 12),

                  // Mô tả
                  TextField(
                    decoration: InputDecoration(
                      labelText: "Mô tả",
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.orange.shade200,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (value) => description = value,
                  ),

                  const SizedBox(height: 20),

                  // LƯU
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: loading
                          ? null
                          : () async {
                              if (title.trim().isEmpty) return;

                              setState(() => loading = true);

                              try {
                                final ref = FirebaseFirestore.instance
                                    .collection('flashcards')
                                    .doc(userId)
                                    .collection('userFlashcards')
                                    .doc();

                                await ref.set({
                                  "title": title.trim(),
                                  "description": description.trim(),
                                  "vocabList": [],
                                  "participants": 1,
                                  "createdAt": FieldValue.serverTimestamp(),
                                });

                                Navigator.pop(context);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      "Tạo flashcard thành công!",
                                      style: TextStyle(color: Colors.orange),
                                    ),
                                    backgroundColor: Colors.orange.shade100,
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.all(16),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text("Lỗi: $e")),
                                );
                              } finally {
                                setState(() => loading = false);
                              }
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "LƯU",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),

                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
