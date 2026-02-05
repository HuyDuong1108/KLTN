import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'listening_test_page.dart';
import 'listening_review_page.dart';

class ListeningPage extends StatelessWidget {
  const ListeningPage({super.key});

  // ===== COLORS =====
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color lightBlue = Color(0xFF4FC3F7);
  static const Color bgColor = Color(0xFFF6FAFF);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          "Listening",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('listening_tests')
            .orderBy('title')
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No listening tests found"));
          }

          final tests = snapshot.data!.docs;

          // ===== OVERVIEW LOGIC (CHUẨN UX CŨ) =====
          final int totalTests = tests.length;
          final int completedTests = 0; // 🔥 chưa có result
          final double averageBand = 0.0; // 🔥 chưa có band

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _overviewCard(
                completed: completedTests,
                total: totalTests,
                averageBand: averageBand,
              ),
              const SizedBox(height: 28),
              const Text(
                "Full Listening Tests",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),

              ...tests.map((doc) {
                final data = doc.data() as Map<String, dynamic>;

                return _listeningTestCard(
                  context: context,
                  testId: doc.id,
                  title: data['title'],
                  totalQuestions: data['totalQuestions'],
                  completed: false, // 🔥 sau này nối result
                );
              }).toList(),
            ],
          );
        },
      ),
    );
  }

  // ================= OVERVIEW CARD =================
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
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.headphones, size: 40, color: primaryBlue),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Listening Progress",
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
  Widget _listeningTestCard({
    required BuildContext context,
    required String testId,
    required String title,
    required int totalQuestions,
    required bool completed,
    int? score,
    double? band,
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
            children: [
              const Icon(Icons.layers, size: 18),
              const SizedBox(width: 6),
              const Text("4 Sections"),
              const SizedBox(width: 16),
              const Icon(Icons.help_outline, size: 18),
              const SizedBox(width: 6),
              Text("$totalQuestions Questions"),
            ],
          ),
          const SizedBox(height: 14),
          if (completed) ...[
            Row(
              children: [
                _infoChip("Score: $score/$totalQuestions"),
                const SizedBox(width: 8),
                _infoChip("Band: $band"),
              ],
            ),
            const SizedBox(height: 14),
            _primaryButton(
              text: "Review Test",
              icon: Icons.analytics_outlined,
              background: primaryBlue,
              textColor: Colors.white,
              onPressed: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (_) => ListeningReviewPage(testId: testId),
                //   ),
                // );
              },
            ),
          ] else ...[
            const Text(
              "Not attempted",
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 14),
            _primaryButton(
              text: "Start Test",
              icon: Icons.play_arrow_rounded,
              background: lightBlue,
              textColor: Colors.white,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => ListeningTestPage(testId: testId),
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
    required Color background,
    required Color textColor,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, size: 22, color: textColor),
        label: Text(
          text,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: background,
          elevation: 3,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
