import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'reading_test_page.dart';
import 'reading_review_page.dart';

class ReadingPage extends StatelessWidget {
  const ReadingPage({super.key});

  // ===== COLORS =====
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color softBlue = Color(0xFF90CAF9);
  static const Color bgColor = Color(0xFFF6FAFF);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color textGrey = Color(0xFF607D8B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Reading",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      // ================= BODY =================
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reading_tests')
            .orderBy('id')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No reading tests found"));
          }

          final tests = snapshot.data!.docs;

          // ===== LOAD READING RESULTS (Y CHANG LISTENING) =====
          return FutureBuilder<QuerySnapshot>(
            future: FirebaseFirestore.instance
                .collection('reading_results')
                .orderBy('submittedAt', descending: true)
                .get(),
            builder: (context, resultSnapshot) {
              if (!resultSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final results = resultSnapshot.data!.docs;

              // Map lưu latest result theo testId
              final Map<String, Map<String, dynamic>> latestResultByTest = {};

              for (final doc in results) {
                final data = doc.data() as Map<String, dynamic>;
                final testId = data['testId'];

                if (!latestResultByTest.containsKey(testId)) {
                  latestResultByTest[testId] = {...data, 'id': doc.id};
                }
              }

              return ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _overviewCard(
                    completed: latestResultByTest.length,
                    total: tests.length,
                    averageBand: latestResultByTest.isEmpty
                        ? 0
                        : latestResultByTest.values
                                  .map((e) => (e['band'] ?? 0).toDouble())
                                  .reduce((a, b) => a + b) /
                              latestResultByTest.length,
                  ),
                  const SizedBox(height: 28),

                  const Text(
                    "Full Reading Tests",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 16),

                  ...tests.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final result = latestResultByTest[doc.id];

                    return _readingTestCard(
                      context: context,
                      testId: doc.id,
                      title: data['title'],
                      totalQuestions: data['totalQuestions'],
                      duration: data['duration'],
                      completed: result != null,
                      correct: result?['correct'],
                      band: result?['band'],
                      resultId: result?['id'],
                    );
                  }).toList(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ================= OVERVIEW =================
  Widget _overviewCard({
    required int completed,
    required int total,
    required double averageBand,
  }) {
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
          const Icon(Icons.menu_book, size: 40, color: primaryBlue),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Reading Progress",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 6),
              Text("Completed: $completed / $total"),
              Text("Average Band: ${averageBand.toStringAsFixed(1)}"),
            ],
          ),
        ],
      ),
    );
  }

  // ================= TEST CARD =================
  Widget _readingTestCard({
    required BuildContext context,
    required String title,
    required int totalQuestions,
    required int duration,
    required bool completed,
    int? correct,
    double? band,
    required String testId,
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
          // ===== TITLE =====
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          // ===== META =====
          Row(
            children: [
              const Icon(Icons.article_outlined, size: 18),
              const SizedBox(width: 6),
              const Text("3 Passages"),
              const SizedBox(width: 16),
              const Icon(Icons.help_outline, size: 18),
              const SizedBox(width: 6),
              Text("$totalQuestions Questions"),
              const SizedBox(width: 16),
              const Icon(Icons.timer_outlined, size: 18),
              const SizedBox(width: 6),
              Text("$duration min"),
            ],
          ),

          const SizedBox(height: 14),

          // ===== STATE =====
          if (completed) ...[
            Row(
              children: [
                _infoChip("Correct: $correct / $totalQuestions"),
                const SizedBox(width: 8),
                _infoChip("Band: ${band?.toStringAsFixed(1)}"),
              ],
            ),
            const SizedBox(height: 14),

            Row(
              children: [
                // ===== REVIEW =====
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                ReadingReviewPage(resultId: resultId!),
                          ),
                        );
                      },
                      icon: const Icon(Icons.analytics_outlined, size: 22),
                      label: const Text(
                        "Review",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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

                // ===== TEST AGAIN =====
                Expanded(
                  child: SizedBox(
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ReadingTestPage(testId: testId),
                          ),
                        );
                      },
                      icon: const Icon(Icons.refresh, size: 22),
                      label: const Text(
                        "Test Again",
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
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
                    builder: (_) => ReadingTestPage(testId: testId),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
        icon: Icon(icon, size: 22, color: Colors.white),
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
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
