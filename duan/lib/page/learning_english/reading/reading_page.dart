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
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _overviewCard(),
          const SizedBox(height: 28),

          const Text(
            "Full Reading Tests",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),

          /// 🔥 LOAD DATA FROM FIRESTORE
          StreamBuilder<QuerySnapshot>(
            stream: FirebaseFirestore.instance
                .collection('reading_tests')
                .orderBy('id')
                .snapshots(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: CircularProgressIndicator(),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text("No reading tests found"),
                );
              }

              final tests = snapshot.data!.docs;

              return Column(
                children: tests.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  final String title = data['title'];
                  final int totalQuestions = data['totalQuestions'];
                  final int duration = data['duration'];

                  /// 👉 sau này bạn có thể lưu result riêng
                  final bool completed = false;
                  final int? correct = null;
                  final double? band = null;

                  return _readingTestCard(
                    context: context,
                    title: title,
                    totalQuestions: totalQuestions,
                    duration: duration,
                    completed: completed,
                    correct: correct,
                    band: band,
                    testId: doc.id,
                  );
                }).toList(),
              );
            },
          ),
        ],
      ),
    );
  }

  // ================= OVERVIEW =================
  Widget _overviewCard() {
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
            children: const [
              Text(
                "Reading Progress",
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 6),
              Text("Completed: --"),
              Text("Average Band: --"),
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
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
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
                _infoChip("Band: $band"),
              ],
            ),
            const SizedBox(height: 14),
            _primaryButton(
              text: "Review Test",
              icon: Icons.analytics_outlined,
              color: primaryBlue,
              onPressed: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (_) => ReadingReviewPage(testId: testId),
                //   ),
                // );
              },
            ),
          ] else ...[
            const Text(
              "Not attempted",
              style: TextStyle(color: textGrey),
            ),
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
        style: const TextStyle(
          fontWeight: FontWeight.w600,
          color: primaryBlue,
        ),
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
