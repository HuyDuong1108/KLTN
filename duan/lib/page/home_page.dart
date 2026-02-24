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
import 'homeaction/speaking_example.dart';
import 'learning_english/reading/reading_review_page.dart';
import 'learning_english/writing/writing_review_page.dart';
import 'learning_english/listening/listening_review_page.dart';
import 'flashcard/flashcard_study_page.dart';
import '../models/vocabulary.dart';

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
                onContinue: (reviewPath) async {
                  final snap = await FirebaseFirestore.instance
                      .doc(reviewPath)
                      .get();

                  if (!context.mounted) return;

                  final data = snap.data() as Map<String, dynamic>;
                  final testType = data['testType'];

                  if (reviewPath.contains("reading_results")) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ReadingReviewPage(
                          resultId: reviewPath.split('/').last,
                        ),
                      ),
                    );
                  } else if (reviewPath.contains("writing_results")) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => WritingReviewPage(
                          resultId: reviewPath.split('/').last,
                        ),
                      ),
                    );
                  } else if (reviewPath.contains("listening_results")) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ListeningReviewPage(
                          resultId: reviewPath.split('/').last,
                        ),
                      ),
                    );
                  }
                },
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
              FutureBuilder(
                future: _getRecentFlashcards(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) {
                    return const SizedBox();
                  }

                  final sets = snapshot.data as List<Map<String, dynamic>>;

                  return Row(
                    children: sets.map((set) {
                      return Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 10),
                          child: _pathCardDynamic(set),
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _pathCardDynamic(Map<String, dynamic> set) {
    final progress = "${set['easy']}/${set['total']}";

    return GestureDetector(
      onTap: () async {
        final user = FirebaseAuth.instance.currentUser;
        if (user == null) return;

        final setId = set['setId'];
        final isPersonal = set['isPersonal'];

        DocumentSnapshot setDoc;

        if (isPersonal) {
          setDoc = await FirebaseFirestore.instance
              .collection('flashcards')
              .doc(user.uid)
              .collection('userFlashcards')
              .doc(setId)
              .get();
        } else {
          setDoc = await FirebaseFirestore.instance
              .collection('flashcard_sets')
              .doc(setId)
              .get();
        }

        final rawList =
            (setDoc.data() as Map<String, dynamic>)['vocabList'] ?? [];

        final vocabList = rawList.map<Vocabulary>((e) {
          final data = Map<String, dynamic>.from(e);
          return Vocabulary(
            word: data['word'],
            romaji: data['romaji'],
            meaning: data['meaning'],
          );
        }).toList();

        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => FlashcardStudyPage(
              vocabList: vocabList,
              setId: setId,
              isPersonal: isPersonal,
              setTitle: set['title'],
            ),
          ),
        );
      },
      child: Container(
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
            SizedBox(height: 60, child: Image.asset("lib/image/logo.png")),
            const SizedBox(height: 8),
            Text(
              set['title'],
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              "$progress easy",
              style: const TextStyle(color: Color(0xFF607D8B), fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Map<String, dynamic>>> _getRecentFlashcards() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    List<Map<String, dynamic>> result = [];

    // 1️⃣ Lấy bộ cá nhân
    final personalSets = await FirebaseFirestore.instance
        .collection('flashcards')
        .doc(user.uid)
        .collection('userFlashcards')
        .get();

    for (var setDoc in personalSets.docs) {
      final setId = setDoc.id;

      final sessionSnap = await setDoc.reference
          .collection('reviewSessions')
          .orderBy('createdAtMs', descending: true)
          .limit(1)
          .get();

      if (sessionSnap.docs.isEmpty) continue;

      final data = sessionSnap.docs.first.data();

      result.add({
        "setId": setId,
        "title": setDoc.data()['title'] ?? "Flashcard",
        "easy": data['easy'] ?? 0,
        "total": data['total'] ?? 0,
        "isPersonal": true,
        "createdAtMs": data['createdAtMs'] ?? 0,
      });
    }

    // 2️⃣ Lấy bộ cộng đồng
    final communitySets = await FirebaseFirestore.instance
        .collection('flashcard_sets')
        .get();

    for (var setDoc in communitySets.docs) {
      final setId = setDoc.id;

      final sessionSnap = await FirebaseFirestore.instance
          .collection('flashcard_sets')
          .doc(setId)
          .collection('userProgress')
          .doc(user.uid)
          .collection('reviewSessions')
          .orderBy('createdAtMs', descending: true)
          .limit(1)
          .get();

      if (sessionSnap.docs.isEmpty) continue;

      final data = sessionSnap.docs.first.data();

      result.add({
        "setId": setId,
        "title": setDoc.data()['title'] ?? "Flashcard",
        "easy": data['easy'] ?? 0,
        "total": data['total'] ?? 0,
        "isPersonal": false,
        "createdAtMs": data['createdAtMs'] ?? 0,
      });
    }

    // 3️⃣ Sắp xếp theo thời gian gần nhất
    result.sort(
      (a, b) => (b['createdAtMs'] as int).compareTo(a['createdAtMs'] as int),
    );

    return result.take(3).toList();
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
