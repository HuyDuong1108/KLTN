import 'package:flutter/material.dart';

class WritingResultPage extends StatelessWidget {
  const WritingResultPage({super.key});

  // ================= COLORS =================
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color mintBlue = Color(0xFFE0F7FA);
  static const Color bgColor = Color(0xFFF6FAFF);

  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFFA726);
  static const Color textGrey = Color(0xFF455A64);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,

      // ================= APP BAR =================
      appBar: AppBar(
        title: const Text(
          "Writing Result",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: primaryBlue,
        elevation: 0,
      ),

      // ================= BODY =================
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _overallBandCard(),
          const SizedBox(height: 16),

          _bandComment(),
          const SizedBox(height: 20),
          

          _taskScoreCard(),
          const SizedBox(height: 20),

          _criteriaBreakdown(),
          const SizedBox(height: 20),

          _feedbackSection(),
          const SizedBox(height: 20),

          _improvementSection(),
          const SizedBox(height: 24),

          _essayReviewSection(),
          const SizedBox(height: 32),

          _backButton(context),
        ],
      ),
    );
  }

  // ================= OVERALL BAND =================
  Widget _overallBandCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF42A5F5), Color(0xFF90CAF9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Overall Writing Band",
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 6),
          Text(
            "6.5",
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "Competent User",
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ================= BAND COMMENT =================
  Widget _bandComment() {
    return _card(
      color: lightBlue,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.chat_bubble_outline, color: primaryBlue),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Your writing shows clear organisation and relevant ideas. "
              "To reach Band 7+, focus on developing ideas more deeply and "
              "using a wider range of academic vocabulary.",
              style: TextStyle(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  // ================= TASK SCORE =================
  Widget _taskScoreCard() {
    return Row(
      children: [
        _taskMiniCard("Task 1", "6.0", lightBlue),
        const SizedBox(width: 16),
        _taskMiniCard("Task 2", "6.5", mintBlue),
      ],
    );
  }

  Widget _taskMiniCard(String title, String band, Color bg) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              band,
              style: const TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ================= CRITERIA =================
  Widget _criteriaBreakdown() {
    return _sectionCard(
      title: "Band Criteria Breakdown",
      child: Column(
        children: const [
          _criteriaRow("Task Achievement", 6.0),
          _criteriaRow("Coherence & Cohesion", 6.5),
          _criteriaRow("Lexical Resource", 6.0),
          _criteriaRow("Grammar Range & Accuracy", 6.5),
        ],
      ),
    );
  }

  // ================= FEEDBACK =================
  Widget _feedbackSection() {
    return _sectionCard(
      title: "Detailed Feedback",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "✔ Strengths",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: successGreen,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "• Ideas are relevant and clearly expressed.\n"
            "• Paragraphing is logical and easy to follow.\n"
            "• Grammar is mostly accurate.",
            style: TextStyle(height: 1.5),
          ),
          SizedBox(height: 14),
          Text(
            "⚠ Areas to Improve",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: warningOrange,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "• Some ideas lack deeper explanation.\n"
            "• Limited range of academic vocabulary.\n"
            "• Minor grammatical slips remain.",
            style: TextStyle(height: 1.5),
          ),
        ],
      ),
    );
  }

  // ================= IMPROVEMENT =================
  Widget _improvementSection() {
    return _sectionCard(
      title: "How to Improve Your Writing Band",
      child: const Text(
        "• Analyse Task 1 data carefully before writing.\n"
        "• Use more varied linking devices.\n"
        "• Practise complex sentence structures.\n"
        "• Learn topic-based academic vocabulary.",
        style: TextStyle(height: 1.6),
      ),
    );
  }

  // ================= ESSAY REVIEW =================
  Widget _essayReviewSection() {
    return _sectionCard(
      title: "Your Writing",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Task 1 Essay",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "The chart illustrates the proportion of households with various "
            "types of internet access over a given period...",
            style: TextStyle(height: 1.5),
          ),
          SizedBox(height: 16),
          Text(
            "Task 2 Essay",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "Some people argue that schools should focus more on teaching "
            "financial skills. I strongly agree with this view...",
            style: TextStyle(height: 1.5),
          ),
        ],
      ),
    );
  }

  // ================= BUTTON =================
  Widget _backButton(BuildContext context) {
    return SizedBox(
      height: 52,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        child: const Text(
          "Back to Writing",
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  // ================= SHARED =================
  Widget _card({required Color color, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(20),
      ),
      child: child,
    );
  }

  Widget _sectionCard({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
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
          child,
        ],
      ),
    );
  }
}

// ================= CRITERIA ROW =================
class _criteriaRow extends StatelessWidget {
  final String title;
  final double band;

  const _criteriaRow(this.title, this.band);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(title)),
          Text(
            band.toString(),
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: Color(0xFF1976D2),
            ),
          ),
        ],
      ),
    );
  }
}
