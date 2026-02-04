import 'package:flutter/material.dart';

class ListeningReviewPage extends StatefulWidget {
  const ListeningReviewPage({super.key});

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
      body: TabBarView(
        controller: _tabController,
        children: [
          _sectionReview(section: 1),
          _sectionReview(section: 2),
          _sectionReview(section: 3),
          _sectionReview(section: 4),
        ],
      ),
    );
  }

  // ================= SECTION REVIEW =================
  Widget _sectionReview({required int section}) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _sectionIntro(section),
        const SizedBox(height: 16),

        // Demo questions
        _reviewCard(
          number: section * 10 - 9,
          question: "Customer name",
          yourAnswer: "Jon Smith",
          correctAnswer: "John Smith",
          correct: false,
        ),
        _reviewCard(
          number: section * 10 - 8,
          question: "Telephone number",
          yourAnswer: "089234110",
          correctAnswer: "089234110",
          correct: true,
        ),
        _reviewCard(
          number: section * 10 - 7,
          question: "Type of accommodation",
          yourAnswer: "Apartment",
          correctAnswer: "Apartment",
          correct: true,
        ),
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
                "Check your answers and learn from mistakes",
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
