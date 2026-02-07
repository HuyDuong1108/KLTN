import 'package:flutter/material.dart';

class WritingReviewPage extends StatelessWidget {
  const WritingReviewPage({super.key});

  // ===== COLORS =====
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color bgColor = Color(0xFFF6FAFF);
  static const Color goodGreen = Color(0xFFE8F5E9);
  static const Color warnYellow = Color(0xFFFFF8E1);
  static const Color errorRed = Color(0xFFFFEBEE);
  static const Color textGrey = Color(0xFF455A64);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: primaryBlue,
        elevation: 0,
        title: const Text(
          "Writing Review",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      // ================= BODY =================
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _overviewComment(),
          const SizedBox(height: 24),

          _taskReview(
            title: "Task 1 Review",
            content:
                "The chart shows an increase in internet usage over the years. "
                "However, some data is not fully described, and comparisons could be clearer.",
          ),

          const SizedBox(height: 24),

          _taskReview(
            title: "Task 2 Review",
            content:
                "Some people believe schools should teach financial skills. "
                "I agree with this idea because money management is essential in modern life.",
          ),

          const SizedBox(height: 24),

          _vocabUpgrade(),
          const SizedBox(height: 24),

          _bandUpgradeTips(),
          const SizedBox(height: 32),

          _actionButtons(context),
        ],
      ),
    );
  }

  // ================= OVERVIEW =================
  Widget _overviewComment() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF42A5F5), Color(0xFF90CAF9)],
        ),
      ),
      child: const Text(
        "Your writing is clear and easy to follow. To reach Band 7+, "
        "you should develop ideas more deeply and use a wider range of academic vocabulary.",
        style: TextStyle(color: Colors.white, height: 1.5, fontSize: 15),
      ),
    );
  }

  // ================= TASK REVIEW =================
  Widget _taskReview({required String title, required String content}) {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 12),

          _highlightBlock(
            label: "✔ Good",
            color: goodGreen,
            text: "The introduction clearly paraphrases the question.",
          ),

          _highlightBlock(
            label: "⚠ Needs Improvement",
            color: warnYellow,
            text: "Some comparisons are mentioned but not fully explained.",
          ),

          _highlightBlock(
            label: "✖ Error",
            color: errorRed,
            text: "There is limited use of complex sentence structures.",
          ),

          const SizedBox(height: 12),
          const Text(
            "Suggested Rewrite:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(content, style: const TextStyle(height: 1.5)),
        ],
      ),
    );
  }

  Widget _highlightBlock({
    required String label,
    required Color color,
    required String text,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(text, style: const TextStyle(height: 1.4))),
        ],
      ),
    );
  }

  // ================= VOCAB =================
  Widget _vocabUpgrade() {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Vocabulary & Structures to Upgrade Your Band",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: primaryBlue,
            ),
          ),
          SizedBox(height: 12),
          Text("• Instead of \"important\" → \"essential / crucial\""),
          Text(
            "• Instead of \"many people\" → \"a significant proportion of people\"",
          ),
          Text("• Use structures like: \"Not only ..., but also ...\""),
        ],
      ),
    );
  }

  // ================= BAND TIPS =================
  Widget _bandUpgradeTips() {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "How to Reach the Next Band",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: primaryBlue,
            ),
          ),
          SizedBox(height: 10),
          Text(
            "• Develop each main idea with explanation + example.\n"
            "• Use more academic collocations.\n"
            "• Reduce grammar mistakes in complex sentences.\n"
            "• Avoid repeating the same words.",
            style: TextStyle(height: 1.6),
          ),
        ],
      ),
    );
  }

  // ================= ACTION =================
  Widget _actionButtons(BuildContext context) {
    return Column(
      children: [
        // ===== PRIMARY: RETAKE TEST =====
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Navigate to WritingTestPage
            },
            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text(
              "Rewrite & Retake Test",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              elevation: 4,
              shadowColor: primaryBlue.withOpacity(0.35),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
        ),

        const SizedBox(height: 14),

        // ===== SECONDARY: BACK TO WRITING =====
        SizedBox(
          width: double.infinity,
          height: 48,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back, color: primaryBlue),
            label: const Text(
              "Back to Writing",
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: primaryBlue,
              ),
            ),
            style: OutlinedButton.styleFrom(
              backgroundColor: const Color(0xFFE3F2FD),
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ================= SHARED CARD =================
  Widget _card(Widget child) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }
}
