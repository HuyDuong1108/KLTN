import 'package:flutter/material.dart';
import 'homeaction/chatgemni.dart';
import 'profile/statistics/statistics_detail_page.dart';
import 'package:intl/intl.dart';

// dữ liệu từ API
import '../data/stats_api.dart';
import '../models/stats_summary.dart';

// mới thêm :
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/continue_learning_card.dart';
import 'learning/japan/lesson_detail_page.dart';
import 'homeaction/speaking_example.dart';

// Trang Home chính
class HomePageContent extends StatefulWidget {
  const HomePageContent({super.key});

  @override
  State<HomePageContent> createState() => _HomePageContentState();
}

class _HomePageContentState extends State<HomePageContent> {
  late Future<StatsSummary> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = StatsApi.instance.fetchSummary();
  }

  String _fmtInt(int n) {
    final s = n.toString();
    return s.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  String _getGreetingName() {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return "there";

    if (user.displayName != null && user.displayName!.isNotEmpty) {
      return user.displayName!;
    }

    if (user.email != null && user.email!.isNotEmpty) {
      return user.email!.split('@').first;
    }

    return "there";
  }

  Future<void> _openContinueLesson(
    BuildContext context,
    String lessonPath,
  ) async {
    try {
      final snap = await FirebaseFirestore.instance.doc(lessonPath).get();
      if (!snap.exists) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Không tìm thấy bài học để tiếp tục.")),
        );
        return;
      }

      if (!context.mounted) return;
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => LessonDetailPage(lessonDoc: snap)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Lỗi mở bài học: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF3F9FF),

      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // --- Header ---
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const CircleAvatar(
                        radius: 22,
                        backgroundImage: AssetImage("lib/image/logo.png"),
                      ),
                      const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Hi, ${_getGreetingName()}!",
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            "DolphSpeak",
                            style: TextStyle(
                              color: Color(0xFF1976D2),
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  Row(
                    children: const [
                      Icon(Icons.notifications_none, size: 28),
                      SizedBox(width: 12),
                      Icon(Icons.settings, size: 28),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // --- Continue Learning card : mới thêm ---
              ContinueLearningCard(
                onContinue: (lessonPath) =>
                    _openContinueLesson(context, lessonPath),
              ),

              //  Stats card từ backend
              FutureBuilder<StatsSummary>(
                future: _statsFuture,
                builder: (context, snapshot) {
                  final stats = snapshot.data;

                  final streak = stats?.streakCurrent;
                  final xp = stats?.xpTotal;
                  final weekly = stats?.successRate7d;

                  final streakText = streak == null
                      ? "🔥 —-day streak"
                      : "🔥 ${streak}-day streak";
                  final weeklyText = weekly == null
                      ? "Weekly complete —%"
                      : "Weekly complete ${(weekly * 100).round()}%";
                  final xpText = xp == null ? "⭐ — XP" : "⭐ ${_fmtInt(xp)} XP";

                  return InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const StatisticsDetailPage(),
                        ),
                      );
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 5,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  streakText,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(weeklyText),
                                const SizedBox(height: 6),
                                Text(
                                  xpText,
                                  style: const TextStyle(
                                    color: Color(0xFF1976D2),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(
                            Icons.bar_chart,
                            size: 40,
                            color: Color(0xFF4FC3F7),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),

              const SizedBox(height: 20),

              const Text(
                "Quick Practice",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _quickPracticeButton(
                    Icons.book,
                    const Color.fromARGB(255, 94, 177, 245),
                    () {},
                  ),
                  _quickPracticeButton(
                    Icons.question_answer,
                    const Color.fromARGB(255, 208, 93, 228), // tím AI
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const ChatGeminiPage(),
                        ),
                      );
                    },
                  ),
                  _quickPracticeButton(
                    Icons.mic,
                    const Color.fromARGB(
                      255,
                      241,
                      62,
                      71,
                    ), // xanh ngọc speaking
                    () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SpeakingPage()),
                      );
                    },
                  ),
                ],
              ),

              const SizedBox(height: 20),

              const Text(
                "Today's Goals",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              StreamBuilder<DocumentSnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .doc(FirebaseAuth.instance.currentUser!.uid)
                    .collection('dailyGoals')
                    .doc(DateFormat('yyyy-MM-dd').format(DateTime.now()))
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || !snapshot.data!.exists) {
                    return Row(
                      children: const [
                        _goalChip("Daily Lesson", false, progress: "0/2"),
                        _goalChip("Flashcards", false, progress: "0/2"),
                        _goalChip("Speaking", false, progress: "0/5"),
                      ],
                    );
                  }

                  final data = snapshot.data!.data() as Map<String, dynamic>;

                  final lessonDone = data['lessonCompleted'] ?? false;
                  final flashDone = data['flashcardCompleted'] ?? false;
                  final speakingDone = data['speakingCompleted'] ?? false;

                  final lessonProgress =
                      "${data['listeningReadingCount'] ?? 0}/2";
                  final flashProgress = "${data['flashcardSetCount'] ?? 0}/2";
                  final speakingProgress = "${data['speakingCount'] ?? 0}/5";

                  return Row(
                    children: [
                      _goalChip(
                        "Test Lesson",
                        lessonDone,
                        progress: lessonProgress,
                      ),
                      _goalChip(
                        "Flashcards",
                        flashDone,
                        progress: flashProgress,
                      ),
                      _goalChip(
                        "Speaking",
                        speakingDone,
                        progress: speakingProgress,
                      ),
                    ],
                  );
                },
              ),

              const SizedBox(height: 20),

              const Text(
                "Recommended Paths",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Row(
                children: const [
                  Expanded(
                    child: _pathCard(
                      "Business English",
                      "20/60",
                      "lib/image/logo.png",
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _pathCard(
                      "Travel Essentials",
                      "7/10",
                      "lib/image/logo.png",
                    ),
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: _pathCard(
                      "Academic Writing",
                      "10/20",
                      "lib/image/logo.png",
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// --- Widget nhỏ tái sử dụng ---

Widget _quickPracticeButton(IconData icon, Color color, VoidCallback onTap) {
  return GestureDetector(
    onTap: onTap,
    child: Container(
      height: 60,
      width: 60,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(icon, color: color, size: 30),
    ),
  );
}

class _goalChip extends StatelessWidget {
  final String title;
  final bool completed;
  final String progress;

  const _goalChip(
    this.title,
    this.completed, {
    required this.progress,
    super.key,
  });

  double _calculatePercent() {
    final parts = progress.split('/');
    if (parts.length != 2) return 0;
    final current = int.tryParse(parts[0]) ?? 0;
    final total = int.tryParse(parts[1]) ?? 1;
    return total == 0 ? 0 : current / total;
  }

  @override
  Widget build(BuildContext context) {
    final percent = _calculatePercent();

    final Color primaryBlue = const Color(0xFF42A5F5);
    final Color accentBlue = const Color(0xFF81D4FA);

    return Expanded(
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          gradient: completed
              ? const LinearGradient(
                  colors: [Color(0xFF42A5F5), Color(0xFF81D4FA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: completed ? null : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: completed
                  ? primaryBlue.withOpacity(0.25)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // --- ICON ---
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: completed
                    ? Colors.white.withOpacity(0.25)
                    : primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                completed ? Icons.check_circle : Icons.track_changes,
                color: completed ? Colors.white : primaryBlue,
                size: 20,
              ),
            ),

            const SizedBox(height: 12),

            // --- TITLE ---
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: completed ? Colors.white : Colors.black87,
              ),
            ),

            const SizedBox(height: 6),

            // --- PROGRESS TEXT ---
            Text(
              "$progress complete",
              style: TextStyle(
                fontSize: 12,
                color: completed ? Colors.white70 : Colors.grey[600],
              ),
            ),

            const SizedBox(height: 10),

            // --- PROGRESS BAR ---
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: LinearProgressIndicator(
                value: percent,
                minHeight: 6,
                backgroundColor: completed
                    ? Colors.white.withOpacity(0.3)
                    : Colors.grey[200],
                valueColor: AlwaysStoppedAnimation<Color>(
                  completed ? Colors.white : primaryBlue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _pathCard extends StatelessWidget {
  final String title;
  final String progress;
  final String image;

  const _pathCard(this.title, this.progress, this.image, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          SizedBox(height: 60, child: Image.asset(image, fit: BoxFit.contain)),
          const SizedBox(height: 8),
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 4),
          Text(
            "$progress complete",
            style: const TextStyle(color: Color(0xFF607D8B), fontSize: 12),
          ),
        ],
      ),
    );
  }
}
