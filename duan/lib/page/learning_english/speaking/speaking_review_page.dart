import 'package:flutter/material.dart';

class SpeakingReviewPage extends StatelessWidget {
  const SpeakingReviewPage({super.key});

  // ================= COLORS =================
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color bgColor = Color(0xFFF6FAFF);
  static const Color errorRed = Color(0xFFE53935);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFFA726);
  static const Color textGrey = Color(0xFF607D8B);

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
          "Speaking Review",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _summaryCard(),
          const SizedBox(height: 24),

          _transcriptSection(),
          const SizedBox(height: 24),

          _pronunciationSection(),
          const SizedBox(height: 24),

          _vocabularyUpgradeSection(),
          const SizedBox(height: 24),

          _examinerComment(),
          const SizedBox(height: 32),

          _actionButtons(context),
        ],
      ),
    );
  }

  // ================= SUMMARY =================
  Widget _summaryCard() {
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF42A5F5), Color(0xFF90CAF9)],
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "IELTS Speaking – Part 2 Review",
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 6),
          Text(
            "Estimated Band: 6.0",
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "You spoke clearly but lost fluency due to hesitation and limited vocabulary.",
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ================= TRANSCRIPT =================
  Widget _transcriptSection() {
    return _card(
      title: "Transcript & Corrections",
      child: Column(
        children: [
          _sentenceReview(
            original: "I think my hometown is very big and have many people.",
            issue: "Grammar & verb agreement",
            suggestion:
                "I think my hometown is quite large and has a high population.",
          ),
          _sentenceReview(
            original: "I am live there for twenty years.",
            issue: "Tense error",
            suggestion: "I have lived there for twenty years.",
          ),
        ],
      ),
    );
  }

  Widget _sentenceReview({
    required String original,
    required String issue,
    required String suggestion,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: errorRed.withOpacity(0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Your sentence:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(original, style: const TextStyle(color: errorRed)),
          const SizedBox(height: 8),
          Text(
            "Issue: $issue",
            style: const TextStyle(
              color: warningOrange,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Suggested correction:",
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(suggestion, style: const TextStyle(color: successGreen)),
        ],
      ),
    );
  }

  // ================= PRONUNCIATION =================
  Widget _pronunciationSection() {
    return _card(
      title: "Pronunciation Issues",
      child: Column(
        children: const [
          _pronunciationItem(
            word: "population",
            ipa: "/ˌpɒp.jʊˈleɪ.ʃən/",
            tip: "Stress the third syllable: -la-",
          ),
          _pronunciationItem(
            word: "environment",
            ipa: "/ɪnˈvaɪ.rən.mənt/",
            tip: "Do not pronounce extra syllables",
          ),
        ],
      ),
    );
  }

  // ================= VOCAB UPGRADE =================
  Widget _vocabularyUpgradeSection() {
    return _card(
      title: "Vocabulary to Boost Band",
      child: Column(
        children: const [
          _vocabRow(basic: "very big", advanced: "quite large / spacious"),
          _vocabRow(basic: "many people", advanced: "a high population"),
        ],
      ),
    );
  }

  // ================= EXAMINER COMMENT =================
  Widget _examinerComment() {
    return _card(
      title: "Examiner-style Feedback",
      child: const Text(
        "The candidate can communicate ideas clearly but relies heavily on simple "
        "sentence structures. To reach Band 7, more complex grammar and precise "
        "vocabulary should be used consistently, with improved control of pronunciation.",
        style: TextStyle(height: 1.6),
      ),
    );
  }

  // ================= ACTION BUTTONS =================
  Widget _actionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.replay),
            label: const Text("Practice Again"),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryBlue,
              side: const BorderSide(color: primaryBlue),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: const Icon(Icons.arrow_back),
            label: const Text("Back to Speaking"),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              padding: const EdgeInsets.symmetric(vertical: 14),
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
  Widget _card({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
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

// ================= HELPERS =================
class _pronunciationItem extends StatelessWidget {
  final String word;
  final String ipa;
  final String tip;

  const _pronunciationItem({
    required this.word,
    required this.ipa,
    required this.tip,
  });

  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color warningOrange = Color(0xFFFFA726);
  static const Color textGrey = Color(0xFF607D8B);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            word,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          Text(ipa, style: const TextStyle(color: textGrey)),
          Text(
            "Tip: $tip",
            style: const TextStyle(color: warningOrange, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _vocabRow extends StatelessWidget {
  final String basic;
  final String advanced;
    static const Color primaryBlue = Color(0xFF1976D2);


  const _vocabRow({required this.basic, required this.advanced});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(basic)),
          const Icon(Icons.arrow_forward, size: 16),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              advanced,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
