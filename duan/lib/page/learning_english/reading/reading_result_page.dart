import 'package:flutter/material.dart';

class ReadingResultPage extends StatelessWidget {
  const ReadingResultPage({super.key});

  // ================= COLORS =================
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color bgColor = Color(0xFFF6FAFF);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color errorRed = Color(0xFFE53935);
  static const Color textGrey = Color(0xFF455A64);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,

      // ================= APP BAR =================
      appBar: AppBar(
        title: const Text(
          "Reading Result",
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
          _overallResultCard(),
          const SizedBox(height: 20),
          _bandDescriptorCard(),
          const SizedBox(height: 20),
          _questionTypeAnalysis(),
          const SizedBox(height: 20),
          _questionResultList(),
          const SizedBox(height: 24),
          _reviewButtons(context),
          const SizedBox(height: 20),
          _improvementTips(),
        ],
      ),
    );
  }

  // ================= OVERALL RESULT =================
  Widget _overallResultCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
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
            "Overall Reading Band",
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 6),
          Text(
            "6.5",
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _ResultStat(label: "Correct", value: "28 / 40"),
              _ResultStat(label: "Accuracy", value: "70%"),
              _ResultStat(label: "Time", value: "52m 30s"),
            ],
          ),
        ],
      ),
    );
  }

  // ================= BAND DESCRIPTOR =================
  Widget _bandDescriptorCard() {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Band 6.5 Descriptor",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: primaryBlue,
            ),
          ),
          SizedBox(height: 10),
          Text("• Understands main ideas and specific details."),
          Text("• Can locate information but may struggle with inference."),
          Text("• Errors mainly occur in NOT GIVEN and paraphrasing questions."),
        ],
      ),
    );
  }

  // ================= QUESTION TYPE ANALYSIS =================
  Widget _questionTypeAnalysis() {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Performance by Question Type",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 12),
          _typeRow("Multiple Choice", "6 / 8", successGreen),
          _typeRow("TRUE / FALSE / NOT GIVEN", "4 / 8", errorRed),
          _typeRow("Sentence Completion", "3 / 5", Colors.orange),
          _typeRow("Matching Information", "5 / 7", successGreen),
        ],
      ),
    );
  }

  Widget _typeRow(String type, String score, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(type)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              score,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= QUESTION RESULT LIST =================
  Widget _questionResultList() {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Question Review",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 12),

          _questionItem(1, true, "B", "B"),
          _questionItem(2, false, "TRUE", "FALSE"),
          _questionItem(3, true, "NOT GIVEN", "NOT GIVEN"),
          _questionItem(4, false, "A", "D"),
          _questionItem(5, true, "congestion", "congestion"),
        ],
      ),
    );
  }

  Widget _questionItem(
    int number,
    bool correct,
    String userAnswer,
    String correctAnswer,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: correct ? successGreen : errorRed,
          width: 1.2,
        ),
      ),
      child: Row(
        children: [
          Icon(
            correct ? Icons.check_circle : Icons.cancel,
            color: correct ? successGreen : errorRed,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Question $number",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 4),
                Text(
                  "Your answer: $userAnswer",
                  style: const TextStyle(color: textGrey),
                ),
                if (!correct)
                  Text(
                    "Correct answer: $correctAnswer",
                    style: const TextStyle(
                      color: errorRed,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= REVIEW BUTTONS =================
  Widget _reviewButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              // TODO: Navigate to review with passage
            },
            icon: const Icon(Icons.menu_book),
            label: const Text("Review with Passage"),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              foregroundColor: primaryBlue,
              side: const BorderSide(color: primaryBlue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Navigate to review by question
            },
            icon: const Icon(Icons.analytics),
            label: const Text("Review Answers"),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ================= IMPROVEMENT TIPS =================
  Widget _improvementTips() {
    return _card(
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Icon(Icons.lightbulb, color: Colors.orange),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              "Tip: Be careful with NOT GIVEN questions. Avoid using your own knowledge "
              "and focus strictly on information stated in the passage.",
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ================= SHARED CARD =================
  Widget _card(Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: child,
    );
  }
}

// ================= SMALL STAT =================
class _ResultStat extends StatelessWidget {
  final String label;
  final String value;

  const _ResultStat({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
