import 'package:flutter/material.dart';
import 'dart:math';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lesson_detail_page_zh.dart';
import 'quiz_page_zh.dart';

/// ================= PAGE =================
class QuizResultPageZh extends StatelessWidget {
  final int score;
  final int total;
  final Duration timeSpent;
  final DocumentReference lessonRef;
  final Map<int, Map<String, dynamic>> answers;
  final List tests;

  const QuizResultPageZh({
    super.key,
    required this.lessonRef,
    required this.score,
    required this.total,
    required this.timeSpent,
    required this.answers,
    required this.tests,
  });

  String get lessonId => lessonRef.id;
  String get courseId => lessonRef.parent.parent!.id;
  String get languageCode => lessonRef.parent.parent!.parent.parent!.id;

  double get percent => score / total * 100;
  bool get passed => percent == 100;

  /// ===== Chiến danh =====
  String get title {
    if (percent == 100) return "🏆 Bậc Thầy Tuyệt Đối";
    if (percent >= 90) return "🔥 Chiến Binh Kiến Thức";
    if (percent >= 80) return "⚡ Học Giả Tăng Tốc";
    if (percent >= 70) return "📘 Người Chinh Phục";
    return "🌱 Tân Binh Tiềm Năng";
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF6F7FB),
      appBar: AppBar(
        title: const Text("Kết quả bài học"),
        centerTitle: true,
        backgroundColor: Colors.orange.shade400,
        elevation: 0,
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              _scoreCard(),
              const SizedBox(height: 20),
              _rankCard(),
              const SizedBox(height: 20),
              _top10Card(context),
              const SizedBox(height: 30),
              passed ? _passedActions(context) : _failedActions(context),
            ],
          ),
        ),
      ),
    );
  }

  // ================= SCORE CARD =================

  Widget _scoreCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: _cardDecoration(),
      child: Column(
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            "$score / $total",
            style: const TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.orange,
            ),
          ),
          Text(
            "${percent.toStringAsFixed(0)}%",
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            "⏱ Thời gian: ${timeSpent.inMinutes} phút",
            style: const TextStyle(color: Colors.black54),
          ),
        ],
      ),
    );
  }

  // ================= RANK =================

  Widget _rankCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('lessons')
          .doc(lessonId)
          .collection('results')
          .orderBy('score', descending: true)
          .orderBy('timeSpent')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final docs = snapshot.data!.docs;
        final myUid = FirebaseAuth.instance.currentUser!.uid;

        int rank = 0;
        int count = 0;

        for (final d in docs) {
          final data = d.data() as Map<String, dynamic>;
          if (!data.containsKey('uid')) continue;

          count++;
          if (data['uid'] == myUid && rank == 0) {
            rank = count;
          }
        }

        if (rank == 0) rank = count;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Xếp hạng bài làm này",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              Text(
                "#$rank / $count",
                style: const TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= TOP 10 =================
  Widget _statItem(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            value,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(fontSize: 13, color: Colors.black54),
          ),
        ],
      ),
    );
  }

  Widget _divider() {
    return Container(width: 1, height: 28, color: Colors.grey.shade300);
  }

  void _showUserProfile(BuildContext context, Map<String, dynamic> resultData) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return FutureBuilder<DocumentSnapshot>(
          future: FirebaseFirestore.instance
              .collection('users')
              .doc(resultData['uid'])
              .get(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.all(40),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (!snapshot.hasData || !snapshot.data!.exists) {
              return const SizedBox();
            }

            final user = snapshot.data!.data() as Map<String, dynamic>;
            final name = (user['name'] ?? '').toString();

            return Container(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              decoration: const BoxDecoration(
                color: Color(0xffF6F7FB),
                borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade300,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // CARD 1
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: _cardDecoration(),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.orange.shade100,

                          child: Text(
                            name.isNotEmpty ? name[0].toUpperCase() : '?',
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user['name'],
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              Text(
                                "${resultData['percent']}% • ${(resultData['timeSpent'] / 60).round()} phút",
                                style: const TextStyle(color: Colors.black54),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // CARD 2
                  Container(
                    padding: const EdgeInsets.symmetric(
                      vertical: 14,
                      horizontal: 16,
                    ),
                    decoration: _cardDecoration(),
                    child: Row(
                      children: [
                        _statItem("Giới tính", user['gender']),
                        _divider(),
                        _statItem("Ngày sinh", user['birthday']),
                        _divider(),
                        _statItem(
                          "Thời gian",
                          "${(resultData['timeSpent'] / 60).round()} phút",
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ===== CTA =====
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      onPressed: () {
                        Navigator.popUntil(context, (route) => route.isFirst);

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "🤝 Đã gửi lời mời kết bạn tới ${user['name']}",
                            ),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                      icon: const Icon(Icons.person_add, color: Colors.white),
                      label: const Text(
                        "Kết bạn",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
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
      },
    );
  }

  Widget _top10Card(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('lessons')
          .doc(lessonId)
          .collection('results')
          .orderBy('score', descending: true)
          .orderBy('timeSpent')
          .limit(10)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const CircularProgressIndicator();
        }

        final docs = snapshot.data!.docs;

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: _cardDecoration(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "🏆 Top ${docs.length} lượt làm tốt nhất",
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              ...docs.asMap().entries.map((entry) {
                final index = entry.key;
                final resultData = entry.value.data() as Map<String, dynamic>;
                if (!resultData.containsKey('uid')) return const SizedBox();

                final uid = resultData['uid'];

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance
                      .collection('users')
                      .doc(uid)
                      .get(),
                  builder: (context, userSnap) {
                    if (!userSnap.hasData) {
                      return const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: LinearProgressIndicator(),
                      );
                    }

                    final user =
                        userSnap.data!.data() as Map<String, dynamic>? ?? {};
                    final name = (user['name'] ?? 'Ẩn danh').toString();

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Text(
                            "#${index + 1}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.orange,
                            ),
                          ),
                          const SizedBox(width: 12),
                          GestureDetector(
                            onTap: () => _showUserProfile(context, resultData),
                            child: CircleAvatar(
                              radius: 16,
                              child: Text(
                                name.isNotEmpty ? name[0].toUpperCase() : '?',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(child: Text(name)),
                          Text(
                            "${resultData['score']} / ${resultData['total']}",
                          ),
                          const SizedBox(width: 8),
                          Text("${(resultData['timeSpent'] / 60).round()}p"),
                        ],
                      ),
                    );
                  },
                );
              }).toList(),
            ],
          ),
        );
      },
    );
  }

  // ================= ACTIONS =================

  Widget _failedActions(BuildContext context) {
    return Column(
      children: [
        _mainButton(
          icon: Icons.menu_book_outlined,
          text: "Học lại",
          onTap: () => Navigator.pop(context),
        ),
        const SizedBox(height: 12),
        _outlineButton(
          icon: Icons.refresh,
          text: "Làm lại từ đầu",
          onTap: () async {
            final lessonSnap = await lessonRef.get();

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => QuizPageZh(tests: tests, lessonDoc: lessonSnap),
              ),
            );
          },
        ),
      ],
    );
  }

  Future<void> _saveLessonProgress() async {
    if (score != total) return;

    final uid = FirebaseAuth.instance.currentUser!.uid;

    await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("learning")
        .doc(languageCode)
        .collection(courseId)
        .doc(lessonId)
        .set({
          "score": score,
          "total": total,
          "timeSpent": timeSpent.inSeconds,
          "completedAt": FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
  }

  Widget _passedActions(BuildContext context) {
    return Column(
      children: [
        _mainButton(
          icon: Icons.visibility_outlined,
          text: "Xem lại bài làm",
          onTap: () async {
            final lessonSnap = await lessonRef.get();

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => QuizPageZh(
                  tests: tests,
                  lessonDoc: lessonSnap,
                  isReview: true,
                  answers: answers,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        _outlineButton(
          icon: Icons.arrow_forward,
          text: "Bài tiếp theo",
          onTap: () async {
            await _saveLessonProgress();
            final nextId = await _getNextLessonId();
            if (nextId == null) return;

            final doc = await FirebaseFirestore.instance
                .collection('languages')
                .doc(languageCode)
                .collection('courses')
                .doc(courseId)
                .collection('lessons')
                .doc(nextId)
                .get();

            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (_) => LessonDetailPageZh(lessonDoc: doc),
              ),
            );
          },
        ),
      ],
    );
  }

  // ================= HELPERS =================

  Widget _mainButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _outlineButton({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: Colors.orange),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
        onPressed: onTap,
        icon: Icon(icon, color: Colors.orange),
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.orange,
          ),
        ),
      ),
    );
  }

  Future<String?> _getNextLessonId() async {
    final snap = await FirebaseFirestore.instance
        .collection('languages')
        .doc(languageCode)
        .collection('courses')
        .doc(courseId)
        .collection('lessons')
        .orderBy('order')
        .get();

    for (int i = 0; i < snap.docs.length - 1; i++) {
      if (snap.docs[i].id == lessonId) {
        return snap.docs[i + 1].id;
      }
    }
    return null;
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.06),
          blurRadius: 12,
          offset: const Offset(0, 6),
        ),
      ],
    );
  }
}
