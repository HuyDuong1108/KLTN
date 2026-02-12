import 'package:flutter/material.dart';
import 'writing_test_page.dart';
import 'writing_review_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WritingPage extends StatefulWidget {
  const WritingPage({super.key});

  @override
  State<WritingPage> createState() => _WritingPageState();
}

class _WritingPageState extends State<WritingPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  List<DocumentSnapshot> _results = [];
  Map<String, Map<String, dynamic>> _latestResultByTest = {};

  bool _loading = true;
  List<DocumentSnapshot> _tests = [];

  // ===== COLORS =====
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color softBlue = Color(0xFF90CAF9);
  static const Color bgColor = Color(0xFFF6FAFF);
  static const Color textGrey = Color(0xFF607D8B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,

      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Writing",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _overviewCard(),
                const SizedBox(height: 28),

                const Text(
                  "Full Writing Tests",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                ..._tests.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final result = _latestResultByTest[doc.id];
                  final ai = result?['aiResult'];
                  final tasks = result?['tasks'];

                  return _writingTestCard(
                    context: context,
                    testId: doc.id,
                    title: data['title'],
                    completed: result != null,
                    band: ai?['overallBand'],
                    task1Words: tasks?['task1']?['wordCount'],
                    task2Words: tasks?['task2']?['wordCount'],
                    resultId: result?['id'],
                  );
                }).toList(),
              ],
            ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadWritingTests();
  }
Future<void> _loadWritingTests() async {
  try {
    final testSnapshot = await _firestore
        .collection('writing_tests')
        .orderBy('createdAt')
        .get();

    final resultSnapshot = await _firestore
        .collection('writing_results')
        .orderBy('submittedAt', descending: true)
        .get();

    final Map<String, Map<String, dynamic>> latestResultByTest = {};

    for (final doc in resultSnapshot.docs) {
      final data = doc.data() as Map<String, dynamic>;
      final testId = data['testId'];

      if (data['aiResult'] != null &&
          !latestResultByTest.containsKey(testId)) {
        latestResultByTest[testId] = {
          ...data,
          'id': doc.id,
        };
      }
    }

    if (!mounted) return;

    setState(() {
      _tests = List<DocumentSnapshot>.from(testSnapshot.docs);
      _latestResultByTest = latestResultByTest;
      _loading = false;
    });
  } catch (e) {
    print("🔥 WritingPage Load Error: $e");

    if (!mounted) return;

    setState(() {
      _tests = [];
      _latestResultByTest = {};
      _loading = false;
    });
  }
}
  
  // ================= OVERVIEW =================
  Widget _overviewCard() {
  final completed = _latestResultByTest.length;
  final total = _tests.length;

  double totalBand = 0.0;
  int counted = 0;

  for (final e in _latestResultByTest.values) {
    final ai = e['aiResult'];
    if (ai != null && ai['overallBand'] != null) {
      totalBand += (ai['overallBand'] as num).toDouble();
      counted++;
    }
  }

  final averageBand =
      counted == 0 ? 0.0 : totalBand / counted;

  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(20),
      gradient: const LinearGradient(
        colors: [Color(0xFFBBDEFB), Color(0xFFE3F2FD)],
      ),
    ),
    child: Row(
      children: [
        const Icon(Icons.edit, size: 40, color: primaryBlue),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Writing Progress",
              style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text("Completed: $counted / $total"),
            Text("Average Band: ${averageBand.toStringAsFixed(1)}"),
          ],
        ),
      ],
    ),
  );
}
  // ================= TEST CARD =================
  Widget _writingTestCard({
    required BuildContext context,
    required String testId,
    required String title,
    required bool completed,
    double? band,
    int? task1Words,
    int? task2Words,
    String? resultId,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x334FC3F7),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          Row(
            children: const [
              Icon(Icons.assignment_outlined, size: 18),
              SizedBox(width: 6),
              Text("Task 1 & Task 2"),
              SizedBox(width: 16),
              Icon(Icons.timer_outlined, size: 18),
              SizedBox(width: 6),
              Text("60 min"),
            ],
          ),

          const SizedBox(height: 14),

          if (completed) ...[
            Row(
              children: [
                _infoChip(
                  "Band ${band != null ? band.toStringAsFixed(1) : "N/A"}",
                ),
                const SizedBox(width: 4),
                _infoChip("T1: $task1Words words"),
                const SizedBox(width: 4),
                _infoChip("T2: $task2Words words"),
              ],
            ),

            const SizedBox(height: 14),

            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                WritingReviewPage(resultId: resultId!),
                          ),
                        );
                      },
                      icon: const Icon(Icons.analytics_outlined),
                      label: const Text(
                        "Review",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryBlue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 12),

                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => WritingTestPage(testId: testId),
                          ),
                        );
                      },
                      icon: const Icon(Icons.refresh),
                      label: const Text(
                        "Test Again",
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: softBlue,
                        side: BorderSide(color: softBlue, width: 1.6),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ] else ...[
            const Text("Not attempted", style: TextStyle(color: textGrey)),
            const SizedBox(height: 14),
            _primaryButton(
              text: "Start Test",
              icon: Icons.play_arrow_rounded,
              color: softBlue,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WritingTestPage(testId: testId),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // ================= COMPONENTS =================
  Widget _infoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, color: primaryBlue),
      ),
    );
  }

  Widget _primaryButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
