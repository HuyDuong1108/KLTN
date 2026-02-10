import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class ReadingReviewPage extends StatelessWidget {
  final String resultId;

  const ReadingReviewPage({super.key, required this.resultId});

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

      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('reading_results')
            .doc(resultId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _summaryCard(data),
              const SizedBox(height: 20),
              _passageCard(context, data),
              const SizedBox(height: 28),
              _questionReviewSection(context, data),
            ],
          );
        },
      ),
    );
  }

  // ================= SUMMARY =================
  Widget _summaryCard(Map<String, dynamic> data) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF42A5F5), Color(0xFF90CAF9)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Reading Test 1", style: TextStyle(color: Colors.white70)),
          SizedBox(height: 6),
          Text(
            "Band ${data['band']}",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Correct: ${data['correct']} / ${data['correct'] + data['incorrect']}",
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ================= PASSAGE =================
  Widget _passageCard(BuildContext context, Map<String, dynamic> data) {
    final String passage = data['passages'][0]['content'];
    final List questions = data['questions'];

    List<TextSpan> spans = [];
    int index = 0;

    for (final q in questions) {
      if (q['start'] == null || q['end'] == null) continue;

      if (index < q['start']) {
        spans.add(TextSpan(text: passage.substring(index, q['start'])));
      }

      spans.add(
        TextSpan(
          text: passage.substring(q['start'], q['end']),
          style: TextStyle(
            backgroundColor: q['correct'] ? correctGreen : wrongRed,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () async {
              showDialog(
                context: context,
                barrierDismissible: false,
                builder: (_) =>
                    const Center(child: CircularProgressIndicator()),
              );

              final explanation = await _getOrCreateExplanation(
                resultId: resultId,
                question: q,
              );

              Navigator.pop(context); // đóng loading

              _showExplain(context, explanation);
            },
        ),
      );

      index = q['end'];
    }

    if (index < passage.length) {
      spans.add(TextSpan(text: passage.substring(index)));
    }

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 15, height: 1.6, color: textGrey),
          children: spans,
        ),
      ),
    );
  }

  // ================= QUESTION REVIEW =================
  Widget _questionReviewSection(
    BuildContext context,
    Map<String, dynamic> data,
  ) {
    final List questions = data['questions'];

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
        ...questions.map((q) {
          return _questionReviewCard(
            number: q['id'],
            question: q['question'],
            userAnswer: q['userAnswer'],
            correctAnswer: q['correctAnswer'],
            explanation: q['correct']
                ? "Correct answer based on passage."
                : "Tap highlighted text to see explanation.",
            skill: q['type'],
            correct: q['correct'],
          );
        }).toList(),
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
          Chip(label: Text(skill), backgroundColor: const Color(0xFFE3F2FD)),
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Future<String> _askGeminiExplain(String sentence, String question) async {
    final model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: dotenv.env['GEMINI_API_KEY']!,
    );

    final prompt =
        """
Explain why the following sentence supports or contradicts the answer.

Question: $question
Sentence: $sentence

Explain in simple IELTS Reading terms.
""";

    final response = await model.generateContent([Content.text(prompt)]);
    return response.text ?? "No explanation available.";
  }

  Future<String> _getOrCreateExplanation({
    required String resultId,
    required Map<String, dynamic> question,
  }) async {
    if (question['explanation'] != null &&
        question['explanation'].toString().isNotEmpty) {
      return question['explanation'];
    }

    final model = GenerativeModel(
      model: 'gemini-pro',
      apiKey: dotenv.env['GEMINI_API_KEY']!,
    );

    final prompt =
        '''
Explain why the correct answer is correct for this IELTS Reading question.

Question:
${question['question']}

Correct Answer:
${question['correctAnswer']}

User Answer:
${question['userAnswer']}

Explain clearly and simply.
''';

    final response = await model.generateContent([Content.text(prompt)]);

    final explanation = response.text ?? "Explanation not available.";

    final docRef = FirebaseFirestore.instance
        .collection('reading_results')
        .doc(resultId);

    final snapshot = await docRef.get();
    final data = snapshot.data()!;
    final List questions = List.from(data['questions']);

    final index = questions.indexWhere((q) => q['id'] == question['id']);

    if (index != -1) {
      questions[index]['explanation'] = explanation;

      await docRef.update({"questions": questions});
    }

    return explanation;
  }
}
