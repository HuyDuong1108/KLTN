import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'writing_test_page.dart';

class WritingReviewPage extends StatefulWidget {
  final String resultId;

  const WritingReviewPage({
    super.key,
    required this.resultId,
  });

  @override
  State<WritingReviewPage> createState() =>
      _WritingReviewPageState();
}
class _WritingReviewPageState
    extends State<WritingReviewPage> {

  bool _loading = true;
  Map<String, dynamic>? resultData;
  Map<String, dynamic>? aiResult;

  @override
  void initState() {
    super.initState();
    _loadReview();
  }

  Future<void> _loadReview() async {
    final doc = await FirebaseFirestore.instance
        .collection('writing_results')
        .doc(widget.resultId)
        .get();

    final data = doc.data();

   setState(() {
  resultData = data;

  final rawAI = data?['aiResult'];

  if (rawAI == null ||
    rawAI is! Map ||
    rawAI['overallBand'] == null ||
    rawAI['strengths'] == null ||
    rawAI['improvements'] == null ||
    rawAI['bandUpgradeTips'] == null) {
    aiResult = _safeAIResult();
  } else {
    aiResult = Map<String, dynamic>.from(rawAI);
  }

  _loading = false;
});

  }


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
      body: _loading
    ? const Center(child: CircularProgressIndicator())
    : ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _overviewComment(),
          const SizedBox(height: 24),

          _taskReview(
            title: "Task 1 Review",
            taskKey: "task1",
          ),

          const SizedBox(height: 24),

          _taskReview(
            title: "Task 2 Review",
            taskKey: "task2",
          ),

          const SizedBox(height: 24),

          _vocabUpgrade(),
          const SizedBox(height: 24),

          _grammarUpgrade(),
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
      child: Text( aiResult?['overallComment'] ??
        "Your writing is clear and easy to follow. To reach Band 7+, "
        "you should develop ideas more deeply and use a wider range of academic vocabulary.",
        style: const TextStyle(color: Colors.white, height: 1.5, fontSize: 15),
      ),
    );
  }

  // ================= TASK REVIEW =================
  Widget _taskReview({
  required String title,
  required String taskKey,
}) {
  final strengths = (aiResult?['strengths'] as List?) ?? [];
final improvements = (aiResult?['improvements'] as List?) ?? [];


  final answer =
      resultData?['tasks']?[taskKey]?['answer'] ?? "";

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
          text: strengths != null && strengths.isNotEmpty
              ? strengths.first
              : "No strengths available.",
        ),

        _highlightBlock(
          label: "⚠ Needs Improvement",
          color: warnYellow,
          text: improvements != null && improvements.isNotEmpty
              ? improvements.first
              : "No improvements available.",
        ),

        const SizedBox(height: 12),
        const Text(
          "Suggested Rewrite:",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        Text(
          answer,
          style: const TextStyle(height: 1.5),
        ),
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
  final vocab = aiResult?['vocabularyFeedback'];

  final weakWords =
      (vocab?['weakWords'] as List?) ?? [];
  final betterWords =
      (vocab?['betterAlternatives'] as List?) ?? [];
  final collocations =
      (vocab?['collocationSuggestions'] as List?) ?? [];

  return _card(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Vocabulary & Structures to Upgrade Your Band",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: primaryBlue,
          ),
        ),
        const SizedBox(height: 12),

        if (weakWords.isNotEmpty) ...[
          const Text(
            "Words to Improve:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(weakWords.map((e) => "• $e").join("\n")),
          const SizedBox(height: 12),
        ],

        if (betterWords.isNotEmpty) ...[
          const Text(
            "Better Alternatives:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(betterWords.map((e) => "• $e").join("\n")),
          const SizedBox(height: 12),
        ],

        if (collocations.isNotEmpty) ...[
          const Text(
            "Collocation Suggestions:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(collocations.map((e) => "• $e").join("\n")),
        ],

        if (weakWords.isEmpty &&
            betterWords.isEmpty &&
            collocations.isEmpty)
          const Text(
            "No vocabulary analysis available.",
          ),
      ],
    ),
  );
}
Widget _grammarUpgrade() {
  final grammar = aiResult?['grammarFeedback'];

  final errors =
      (grammar?['commonErrors'] as List?) ?? [];
  final structureIssues =
      (grammar?['sentenceStructureIssues'] as List?) ?? [];
  final suggestions =
      (grammar?['improvementSuggestions'] as List?) ?? [];

  return _card(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Grammar Range & Accuracy",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: primaryBlue,
          ),
        ),
        const SizedBox(height: 12),

        if (errors.isNotEmpty) ...[
          const Text(
            "Common Errors:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(errors.map((e) => "• $e").join("\n")),
          const SizedBox(height: 12),
        ],

        if (structureIssues.isNotEmpty) ...[
          const Text(
            "Sentence Structure Issues:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(structureIssues.map((e) => "• $e").join("\n")),
          const SizedBox(height: 12),
        ],

        if (suggestions.isNotEmpty) ...[
          const Text(
            "How to Improve Grammar:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(suggestions.map((e) => "• $e").join("\n")),
        ],

        if (errors.isEmpty &&
            structureIssues.isEmpty &&
            suggestions.isEmpty)
          const Text("No grammar analysis available."),
      ],
    ),
  );
}



  // ================= BAND TIPS =================
  Widget _bandUpgradeTips() {
  final tips = aiResult?['bandUpgradeTips'] as List?;

  return _card(
    Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "How to Reach the Next Band",
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 18,
            color: primaryBlue,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          tips != null
              ? tips.map((e) => "• $e").join("\n")
              : "No improvement tips available.",
          style: const TextStyle(height: 1.6),
        ),
      ],
    ),
  );
}

Map<String, dynamic> _safeAIResult() {
  final task1WordCount =
      resultData?['tasks']?['task1']?['wordCount'] ?? 0;
  final task2WordCount =
      resultData?['tasks']?['task2']?['wordCount'] ?? 0;

  double estimatedBand = 5.5;

  if (task2WordCount >= 250 && task1WordCount >= 150) {
    estimatedBand = 6.5;
  }

  if (task2WordCount >= 280 && task1WordCount >= 170) {
    estimatedBand = 7.0;
  }

  return {
    "overallBand": estimatedBand,
    "overallComment":
        "Your writing meets basic task requirements. To achieve a higher band, focus on deeper idea development and grammatical accuracy.",
    "strengths": [
      "Your response addresses the main task.",
      "Ideas are generally understandable."
    ],
    "improvements": [
      "Develop explanations with clearer examples.",
      "Improve grammar accuracy in complex sentences.",
      "Expand academic vocabulary range."
    ],
    "bandUpgradeTips": [
      "Use more varied sentence structures.",
      "Avoid repeating basic vocabulary.",
      "Add more detailed comparisons in Task 1.",
      "Support arguments with examples in Task 2."
    ]
  };
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
  final testId = resultData?['testId'];

  if (testId != null) {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => WritingTestPage(
          testId: testId,
        ),
      ),
    );
  }
},

            icon: const Icon(Icons.refresh, color: Colors.white),
            label: const Text(
              "Back to Test",
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
