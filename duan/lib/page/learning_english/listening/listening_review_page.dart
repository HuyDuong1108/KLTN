import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ListeningReviewPage extends StatefulWidget {
  final String resultId;

  const ListeningReviewPage({super.key, required this.resultId});

  @override
  State<ListeningReviewPage> createState() => _ListeningReviewPageState();
}

class _ListeningReviewPageState extends State<ListeningReviewPage>
    with SingleTickerProviderStateMixin {
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color errorRed = Color(0xFFE53935);
  static const Color bgColor = Color(0xFFF6FAFF);

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,

      // ================= APP BAR =================
      appBar: AppBar(
        title: const Text(
          "Listening Review",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: primaryBlue,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: primaryBlue,
          labelColor: primaryBlue,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "Section 1"),
            Tab(text: "Section 2"),
            Tab(text: "Section 3"),
            Tab(text: "Section 4"),
          ],
        ),
      ),

      // ================= BODY =================
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('listening_results')
            .doc(widget.resultId)
            .get(),
        builder: (context, resultSnapshot) {
          if (!resultSnapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final resultData =
              resultSnapshot.data!.data() as Map<String, dynamic>;

          final String testId = resultData['testId'];
          final Map<String, dynamic> userAnswers = Map<String, dynamic>.from(
            resultData['answers'],
          );

          // 🔥 fetch test
          return FutureBuilder<DocumentSnapshot>(
            future: FirebaseFirestore.instance
                .collection('listening_tests')
                .doc(testId)
                .get(),
            builder: (context, testSnapshot) {
              if (!testSnapshot.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final testData =
                  testSnapshot.data!.data() as Map<String, dynamic>;

              return TabBarView(
                controller: _tabController,
                children: [
                  _sectionReview(1, testData, userAnswers),
                  _sectionReview(2, testData, userAnswers),
                  _sectionReview(3, testData, userAnswers),
                  _sectionReview(4, testData, userAnswers),
                ],
              );
            },
          );
        },
      ),
    );
  }

  // ================= SECTION REVIEW =================
  Widget _sectionReview(
    int section,
    Map<String, dynamic> testData,
    Map<String, dynamic> userAnswers,
  ) {
    final sectionData = (testData['sections'] as List).firstWhere(
      (s) => s['section'] == section,
    );

    final questions = sectionData['questions'] as List;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionIntro(section),
        const SizedBox(height: 16),

        ...questions.map((q) {
          final number = q['number'];
          final question = q['question'];
          String correctAnswer;

          if (q['answerType'] == 'mcq') {
            final int correctIndex = q['correctAnswer'];
            final List options = q['options'];

            correctAnswer = (correctIndex >= 0 && correctIndex < options.length)
                ? options[correctIndex].toString()
                : '';
          } else {
            correctAnswer = q['correctAnswer'].toString().trim().toLowerCase();
          }

          final yourAnswer = (userAnswers[number.toString()] ?? '')
              .toString()
              .trim()
              .toLowerCase();

          final correct = yourAnswer == correctAnswer;

          return _reviewCard(
            number: number,
            question: question,
            yourAnswer: yourAnswer.isEmpty ? '—' : yourAnswer,
            correctAnswer: correctAnswer,
            correct: correct,
          );
        }),
      ],
    );
  }

  // ================= SECTION HEADER =================
  Widget _sectionIntro(int section) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.headphones, color: primaryBlue),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Section $section Review",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                "Check your answers, learn from mistakes",
                style: TextStyle(color: Colors.grey),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= REVIEW CARD =================
  Widget _reviewCard({
    required int number,
    required String question,
    required String yourAnswer,
    required String correctAnswer,
    required bool correct,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: correct ? successGreen : errorRed,
          width: 1.2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ===== QUESTION HEADER =====
          Row(
            children: [
              Icon(
                correct ? Icons.check_circle : Icons.cancel,
                color: correct ? successGreen : errorRed,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  "$number. $question",
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          // ===== YOUR ANSWER =====
          Text(
            "Your answer: $yourAnswer",
            style: TextStyle(
              color: correct ? successGreen : errorRed,
              fontWeight: FontWeight.w600,
            ),
          ),

          // ===== CORRECT ANSWER =====
          if (!correct) ...[
            const SizedBox(height: 6),
            Text(
              "Correct answer: $correctAnswer",
              style: const TextStyle(
                color: successGreen,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
