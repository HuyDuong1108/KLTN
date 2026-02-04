import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';

class ReadingReviewPage extends StatelessWidget {
  const ReadingReviewPage({super.key});

  // ================= COLORS =================
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color correctGreen = Color(0xFFC8E6C9);
  static const Color wrongRed = Color(0xFFFFCDD2);
  static const Color keywordYellow = Color(0xFFFFF59D);
  static const Color bgColor = Color(0xFFF6FAFF);
  static const Color textGrey = Color(0xFF455A64);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,

      // ================= APP BAR =================
      appBar: AppBar(
        title: const Text(
          "Reading Review",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: primaryBlue,
        elevation: 0,
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _summaryCard(),
          const SizedBox(height: 20),
          _passageCard(context),
          const SizedBox(height: 28),
          _questionReviewSection(),
        ],
      ),
    );
  }

  // ================= SUMMARY =================
  Widget _summaryCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF42A5F5), Color(0xFF90CAF9)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Reading Test 1", style: TextStyle(color: Colors.white70)),
          SizedBox(height: 6),
          Text(
            "Band 6.5",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Correct: 28 / 40",
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ================= PASSAGE =================
  Widget _passageCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 15,
            height: 1.6,
            color: textGrey,
          ),
          children: [
            const TextSpan(
              text:
                  "The history of urban transportation reflects the rapid development of cities and the evolving needs of their populations. ",
            ),

            // ===== CORRECT ANSWER SUPPORT =====
            TextSpan(
              text:
                  "Early forms of transport relied heavily on animal power, particularly horses. ",
              style: const TextStyle(
                backgroundColor: correctGreen,
                fontWeight: FontWeight.w600,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  _showExplain(
                    context,
                    "This sentence explains why animal transport was common in early cities.",
                  );
                },
            ),

            const TextSpan(
              text:
                  "These methods were effective for small communities but became increasingly inefficient as cities expanded. ",
            ),

            // ===== KEYWORD =====
            TextSpan(
              text: "inefficient as cities expanded",
              style: const TextStyle(
                backgroundColor: keywordYellow,
                fontStyle: FontStyle.italic,
              ),
            ),

            const TextSpan(
              text:
                  ". The introduction of mechanised transport systems in the 19th century marked a turning point. ",
            ),

            // ===== WRONG INTERPRETATION =====
            TextSpan(
              text:
                  "Steam-powered trams and railways enabled people to travel greater distances in less time, ",
              style: const TextStyle(
                backgroundColor: wrongRed,
              ),
              recognizer: TapGestureRecognizer()
                ..onTap = () {
                  _showExplain(
                    context,
                    "You selected this as the main idea, but this sentence is only an example, not the main focus.",
                  );
                },
            ),

            const TextSpan(
              text:
                  "reshaping urban landscapes and influencing where people lived and worked.\n\n",
            ),

            const TextSpan(
              text:
                  "In the modern era, public transportation systems face new challenges, including environmental concerns and population growth.",
            ),
          ],
        ),
      ),
    );
  }

  // ================= QUESTION REVIEW =================
  Widget _questionReviewSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Question Review",
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: primaryBlue,
          ),
        ),
        const SizedBox(height: 14),

        _questionReviewCard(
          number: 1,
          question: "What is the main focus of the passage?",
          userAnswer: "A. Decline of rural transport",
          correctAnswer: "B. Evolution of urban transportation",
          explanation:
              "The passage describes how transportation systems changed as cities developed, not rural areas.",
          skill: "Main idea identification",
          correct: false,
        ),

        _questionReviewCard(
          number: 2,
          question: "Horses were sufficient for transportation in large cities.",
          userAnswer: "FALSE",
          correctAnswer: "FALSE",
          explanation:
              "The passage clearly states animal transport became inefficient as cities expanded.",
          skill: "TRUE / FALSE / NOT GIVEN",
          correct: true,
        ),
      ],
    );
  }

  Widget _questionReviewCard({
    required int number,
    required String question,
    required String userAnswer,
    required String correctAnswer,
    required String explanation,
    required String skill,
    required bool correct,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: correct ? Colors.green : Colors.red,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Question $number",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(question),
          const SizedBox(height: 10),

          Row(
            children: [
              Icon(
                correct ? Icons.check_circle : Icons.cancel,
                color: correct ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Text("Your answer: $userAnswer"),
            ],
          ),

          if (!correct) ...[
            const SizedBox(height: 6),
            Text(
              "Correct answer: $correctAnswer",
              style: const TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],

          const SizedBox(height: 10),
          Text(
            "Explanation:",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          Text(explanation),

          const SizedBox(height: 8),
          Chip(
            label: Text(skill),
            backgroundColor: const Color(0xFFE3F2FD),
          ),
        ],
      ),
    );
  }

  // ================= EXPLANATION POPUP =================
  void _showExplain(BuildContext context, String text) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Explanation"),
        content: Text(text),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }
}
