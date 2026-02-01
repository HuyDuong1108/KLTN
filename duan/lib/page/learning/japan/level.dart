import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'course_detail_page.dart';

class LevelSelectionPage extends StatefulWidget {
  final int? unlockedLevel;
  const LevelSelectionPage({super.key, this.unlockedLevel});

  @override
  State<LevelSelectionPage> createState() => _LevelSelectionPageState();
}

class _LevelSelectionPageState extends State<LevelSelectionPage> {
  int unlockedLevel = 1;
  int xp = 0;
  List<DocumentSnapshot> courses = [];
  bool isLoadingCourses = true;

  @override
  void initState() {
    super.initState();
    _loadUnlockedLevel();
    _loadCourses();
  }

  Future<void> _loadCourses() async {
    try {
      final snap = await FirebaseFirestore.instance
          .collection("languages")
          .doc("ja")
          .collection("courses")
          .get();

      setState(() {
        courses = snap.docs;
        isLoadingCourses = false;
      });
    } catch (e) {
      debugPrint("Load courses error: $e");
    }
  }

  /// 🔹 Lấy dữ liệu unlockedLevel + XP từ Firestore
  Future<void> _loadUnlockedLevel() async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid == null) return;

      final doc = await FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .get();

      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          unlockedLevel = (data["japanese_level"] ?? 1) as int;
          xp = (data["xp"] ?? 0) as int;
        });
      }
    } catch (e) {
      debugPrint("Lỗi load japanese_level: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    double progress = unlockedLevel / courses.length;
    if (progress > 1) progress = 1;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Japanese Courses",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.orange.shade400,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // --- Header với level, progress ---
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                const Text(
                  "語語てとる",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const Text(
                  "Select a course to begin",
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Level $unlockedLevel",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    Text(
                      "$xp XP",
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    color: Colors.orange,
                    backgroundColor: Colors.grey[300],
                    minHeight: 8,
                  ),
                ),
              ],
            ),
          ),

          // --- Grid Courses ---
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: courses.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisExtent: 200,
                crossAxisSpacing: 14,
                mainAxisSpacing: 14,
              ),
              itemBuilder: (context, index) {
                final doc = courses[index];
                final data = doc.data() as Map<String, dynamic>;

                final title = data["title"];
                final subtitle = data["subtitle"];
                final levelId = doc.id; // level_1, level_2...
                final match = RegExp(r'level_(\d+)').firstMatch(levelId);
                final levelNumber = match != null
                    ? int.parse(match.group(1)!)
                    : 1;

                final isUnlocked = levelNumber <= unlockedLevel;

                return Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.shade300,
                        blurRadius: 6,
                        offset: const Offset(2, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.school,
                        size: 50,
                        color: isUnlocked
                            ? Colors.orange
                            : Colors.grey.shade400,
                      ),
                      const SizedBox(height: 10),
                      Text(
                        title,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: isUnlocked
                              ? Colors.black87
                              : Colors.grey.shade500,
                        ),
                      ),

                      const SizedBox(height: 6),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          subtitle,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12,
                            color: isUnlocked
                                ? Colors.orange
                                : Colors.grey.shade400,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (isUnlocked)
                        ElevatedButton(
                          onPressed: () async {
                            final lessonSnap = await FirebaseFirestore.instance
                                .collection("languages")
                                .doc("ja")
                                .collection("courses")
                                .doc(doc.id)
                                .collection("lessons")
                                .orderBy("order")
                                .get();

                            final lessons = lessonSnap.docs;

                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => CourseDetailPage(
                                  courseTitle: title,
                                  lessonDocs:
                                      lessons, // 👈 truyền Firestore docs
                                ),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(30),
                            ),
                          ),
                          child: const Text("Start"),
                        )
                      else
                        const Icon(Icons.lock, color: Colors.grey, size: 28),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
