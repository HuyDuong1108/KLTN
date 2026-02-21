import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

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
          final List passages = data['passages'];
          final List allQuestions = data['questions'];

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _summaryCard(data),
              const SizedBox(height: 20),

              ...passages.asMap().entries.map((entry) {
                final int pIndex = entry.key;
                final passage = entry.value;

                final passageQuestions = allQuestions
                    .where((q) => q['passageIndex'] == pIndex)
                    .toList();

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _passageTitle(pIndex + 1),
                    const SizedBox(height: 12),
                    _passageCard(context, passage, passageQuestions),
                    const SizedBox(height: 20),
                    _questionReviewSection(passageQuestions),
                    const SizedBox(height: 32),
                  ],
                );
              }).toList(),
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
          Text("Reading Test", style: TextStyle(color: Colors.white70)),
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

  String _displaySkillName(String type) {
    switch (type) {
      case 'MCQ':
        return 'Multiple Choice';
      case 'TFNG':
        return 'True / False / Not Given';
      case 'SENTENCE':
        return 'Sentence Completion';
      default:
        return type;
    }
  }

  // ================= PASSAGE =================
  Widget _passageCard(
    BuildContext context,
    Map<String, dynamic> passage,
    List questions,
  ) {
    final String content = passage['content'] ?? '';

    final sortedQuestions =
        questions.where((q) => q['start'] != null && q['end'] != null).toList()
          ..sort((a, b) => a['start'].compareTo(b['start']));

    List<TextSpan> spans = [];
    int index = 0;

    for (final q in sortedQuestions) {
      final int start = q['start'];
      final int end = q['end'];

      if (index < start) {
        spans.add(TextSpan(text: content.substring(index, start)));
      }

      spans.add(
        TextSpan(
          text: content.substring(start, end),
          style: TextStyle(
            backgroundColor: q['correct'] ? correctGreen : wrongRed,
          ),
        ),
      );

      index = end;
    }

    if (index < content.length) {
      spans.add(TextSpan(text: content.substring(index)));
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

  Widget _passageTitle(int index) {
    return Text(
      "Reading Passage $index",
      style: const TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: primaryBlue,
      ),
    );
  }

  // ================= QUESTION REVIEW =================
  Widget _questionReviewSection(List questions) {
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
            explanation: q['explanation']?.toString().trim().isNotEmpty == true
                ? q['explanation']
                : "No explanation available.",

            skill: _displaySkillName(q['type']),

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
}
