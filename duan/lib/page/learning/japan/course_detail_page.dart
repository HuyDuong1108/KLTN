import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'lesson_detail_page.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'quiz_page.dart';

class CourseDetailPage extends StatefulWidget {
  final String courseTitle;
  final List<DocumentSnapshot> lessonDocs;

  const CourseDetailPage({
    super.key,
    required this.courseTitle,
    required this.lessonDocs,
  });

  @override
  State<CourseDetailPage> createState() => _CourseDetailPageState();
}

class _CourseDetailPageState extends State<CourseDetailPage> {
  Map<String, Map<String, dynamic>> completedLessons = {};
  bool isLoading = true;
  @override
  void initState() {
    super.initState();
    _loadCompletedLessons();
  }

  Future<void> _loadCompletedLessons() async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    final lessonRef = widget.lessonDocs.first.reference;
    final courseRef = lessonRef.parent.parent; // level_x
    final languageRef = courseRef?.parent.parent; // ja

    if (courseRef == null || languageRef == null) {
      setState(() => isLoading = false);
      return;
    }

    final snap = await FirebaseFirestore.instance
        .collection("users")
        .doc(uid)
        .collection("learning")
        .doc(languageRef.id)
        .collection(courseRef.id)
        .get();

    completedLessons = {for (final doc in snap.docs) doc.id: doc.data()};

    setState(() {
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    double progress = widget.lessonDocs.isEmpty
        ? 0
        : widget.lessonDocs.where((doc) {
                final data = completedLessons[doc.id];
                return data != null && data["score"] == data["total"];
              }).length /
              widget.lessonDocs.length;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // --- Header ---
          SliverAppBar(
            pinned: true,
            backgroundColor: const Color(0xFFFF9800),
            elevation: 0,
            leading: const BackButton(color: Colors.black),
            title: Text(
              widget.courseTitle,
              style: const TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 12,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // TITLE + %
                    Row(
                      children: [
                        const Icon(
                          Icons.flag_rounded,
                          color: Color(0xFFFF9800),
                          size: 20,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          "Tiến độ học",
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Spacer(),
                        Text(
                          "${(progress * 100).toStringAsFixed(0)}%",
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFFFF9800),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    // PROGRESS BAR
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: progress,
                        minHeight: 6, // 👈 mảnh, nhìn sang
                        backgroundColor: Colors.grey.shade200,
                        valueColor: const AlwaysStoppedAnimation(
                          Color(0xFFFF9800),
                        ),
                      ),
                    ),

                    const SizedBox(height: 12),

                    Text(
                      "${(progress * widget.lessonDocs.length).round()} / ${widget.lessonDocs.length} bài hoàn thành",
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // --- Danh sách bài học ---
          SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final lessonId = widget.lessonDocs[index].id;
              final lessonProgress = completedLessons[lessonId];

              final bool isDone =
                  lessonProgress != null &&
                  lessonProgress["score"] == lessonProgress["total"];

              final bool canLearn =
                  index == 0 ||
                  (() {
                    final prevId = widget.lessonDocs[index - 1].id;
                    final prev = completedLessons[prevId];
                    return prev != null && prev["score"] == prev["total"];
                  })();

              final lessonData =
                  widget.lessonDocs[index].data() as Map<String, dynamic>;
              final lessonTitle = lessonData["title"];
              return Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Column(
                  children: [
                    // ✅ BỌC ROW = CONTAINER (CHỖ QUAN TRỌNG)
                    Container(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),

                      decoration: BoxDecoration(
                        color: isDone
                            ? Colors.green.withOpacity(0.08)
                            : canLearn
                            ? Colors.orange.withOpacity(0.08)
                            : Colors.transparent,
                        // ⚪ khoá
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,

                        children: [
                          // DOT + LINE
                          Column(
                            children: [
                              Container(
                                width: 14,
                                height: 14,
                                decoration: BoxDecoration(
                                  color: isDone
                                      ? Colors.green
                                      : canLearn
                                      ? Colors.orange
                                      : Colors.grey,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              if (index != widget.lessonDocs.length - 1)
                                Container(
                                  width: 1.5,
                                  height: 72,
                                  margin: const EdgeInsets.only(top: 6),
                                  decoration: BoxDecoration(
                                    color: isDone
                                        ? Colors.green.shade200
                                        : canLearn
                                        ? Colors.orange.shade200
                                        : Colors.grey.shade300,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                            ],
                          ),

                          const SizedBox(width: 16),

                          // CONTENT
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  lessonTitle,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    Icon(
                                      isDone
                                          ? Icons.check_circle_rounded
                                          : canLearn
                                          ? Icons.play_circle_fill_rounded
                                          : Icons.lock_rounded,
                                      size: 16,
                                      color: isDone
                                          ? Colors.green
                                          : canLearn
                                          ? Colors.orange
                                          : Colors.grey,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      isDone
                                          ? "Hoàn thành"
                                          : canLearn
                                          ? "Bài tiếp theo"
                                          : "Khoá",
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: isDone
                                            ? Colors.green
                                            : canLearn
                                            ? Colors.orange
                                            : Colors.grey,
                                      ),
                                    ),
                                  ],
                                ),

                                const SizedBox(height: 8),
                                if (isDone)
                                  lessonButton(
                                    text: "Ôn lại",
                                    icon: Icons.refresh_rounded,
                                    bgColor: const Color.fromARGB(
                                      255,
                                      173,
                                      239,
                                      178,
                                    ),
                                    fgColor: const Color(0xFF2E7D32),
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => LessonDetailPage(
                                            lessonDoc: widget.lessonDocs[index],
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                else if (canLearn)
                                  lessonButton(
                                    text: "Bắt đầu",
                                    icon: Icons.play_arrow_rounded,
                                    bgColor: const Color(0xFFFF9800),
                                    fgColor: Colors.white,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (_) => LessonDetailPage(
                                            lessonDoc: widget.lessonDocs[index],
                                          ),
                                        ),
                                      );
                                    },
                                  )
                                else
                                  const Text(
                                    "Hoàn thành bài trước để mở",
                                    style: TextStyle(color: Colors.grey),
                                  ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }, childCount: widget.lessonDocs.length),
          ),
        ],
      ),
    );
  }

  Widget lessonButton({
    required String text,
    required IconData icon,
    required Color bgColor,
    required Color fgColor,
    required VoidCallback onTap,
  }) {
    return SizedBox(
      height: 40, // ✅ CHUẨN
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(
          text,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        style: ElevatedButton.styleFrom(
          elevation: 0,
          backgroundColor: bgColor,
          foregroundColor: fgColor,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }

  Widget secondaryButton({required String text, required VoidCallback onTap}) {
    return SizedBox(
      height: 44,
      child: OutlinedButton(
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFFF9800),
          side: const BorderSide(color: Color(0xFFFF9800), width: 1.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 20),
        ),
        onPressed: onTap,
        child: Text(
          text,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}
