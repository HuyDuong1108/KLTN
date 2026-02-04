import 'package:flutter/material.dart';
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

          // ===== DONE TEST =====
          _readingTestCard(
            context: context,
            title: "IELTS Reading Test 1",
            completed: true,
            correct: 30,
            band: 7.0,
          ),

          // ===== NOT DONE =====
          _readingTestCard(
            context: context,
            title: "IELTS Reading Test 2",
            completed: false,
          ),

          _readingTestCard(
            context: context,
            title: "IELTS Reading Test 3",
            completed: false,
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
              Text("Completed: 1 / 10"),
              Text("Average Band: 7.0"),
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
    required bool completed,
    int? correct,
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
            children: const [
              Icon(Icons.article_outlined, size: 18),
              SizedBox(width: 6),
              Text("3 Passages"),
              SizedBox(width: 16),
              Icon(Icons.help_outline, size: 18),
              SizedBox(width: 6),
              Text("40 Questions"),
              SizedBox(width: 16),
              Icon(Icons.timer_outlined, size: 18),
              SizedBox(width: 6),
              Text("60 min"),
            ],
          ),

          const SizedBox(height: 14),

          // ===== STATE =====
          if (completed) ...[
            Row(
              children: [
                _infoChip("Correct: $correct / 40"),
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
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ReadingReviewPage()),
                );
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
                  MaterialPageRoute(builder: (_) => const ReadingTestPage()),
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
