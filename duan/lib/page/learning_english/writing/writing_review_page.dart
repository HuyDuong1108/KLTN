import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'writing_test_page.dart';

class WritingReviewPage extends StatefulWidget {
  final String resultId;

  const WritingReviewPage({super.key, required this.resultId});

  @override
  State<WritingReviewPage> createState() => _WritingReviewPageState();
}

class _WritingReviewPageState extends State<WritingReviewPage> {
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
                _highlightLegend(),
                const SizedBox(height: 24),

                _taskReview(title: "Task 1 Review", taskKey: "task1"),

                const SizedBox(height: 24),

                _taskReview(title: "Task 2 Review", taskKey: "task2"),

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

  Widget _highlightLegend() {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Highlight Meaning",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 14),

          _legendItem("Vocabulary Upgrade", Colors.green),
          _legendItem("Collocation", Colors.orange),
          _legendItem("Grammar Improvement", Colors.purple),
          _legendItem("Band Booster Phrase", Colors.blue),
        ],
      ),
    );
  }

  Widget _legendItem(String text, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 18,
            height: 18,
            decoration: BoxDecoration(
              color: color.withOpacity(0.4),
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(width: 10),
          Text(text, style: const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _highlightedText({
    required String fullText,
    required List highlights,
  }) {
    List<TextSpan> spans = [];
    String remainingText = fullText;

    for (var item in highlights) {
      final String phrase = item['phrase']?.toString() ?? "";

      final String type = item['type']?.toString() ?? "";

      if (phrase.isEmpty) continue;

      final int index = remainingText.indexOf(phrase);

      if (index < 0) continue;

      final String before = remainingText.substring(0, index);

      spans.add(TextSpan(text: before));

      spans.add(
        TextSpan(
          text: phrase,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            backgroundColor: _getHighlightColor(type),
          ),
        ),
      );

      // 👇 FIX CHUẨN Ở ĐÂY
      final int endIndex = index + phrase.length;

      if (endIndex <= remainingText.length) {
        remainingText = remainingText.substring(endIndex);
      } else {
        remainingText = "";
      }
    }

    spans.add(TextSpan(text: remainingText));

    return RichText(
      text: TextSpan(
        style: const TextStyle(
          color: Colors.black87,
          height: 1.6,
          fontSize: 15,
        ),
        children: spans,
      ),
    );
  }

  Color _getHighlightColor(String type) {
    switch (type) {
      case "vocabulary":
        return Colors.green.withOpacity(0.3);

      case "collocation":
        return Colors.orange.withOpacity(0.3);

      case "grammar":
        return Colors.purple.withOpacity(0.3);

      case "band_booster":
        return Colors.blue.withOpacity(0.3);

      default:
        return Colors.yellow.withOpacity(0.3);
    }
  }

  // ================= OVERVIEW =================
  Widget _overviewComment() {
    final band = aiResult?['overallBand'] ?? 0;

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: const LinearGradient(
          colors: [Color(0xFF42A5F5), Color(0xFF90CAF9)],
        ),

        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Overall Band: ${band.toStringAsFixed(1)}",
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            aiResult?['overallComment'] ?? "",
            style: const TextStyle(
              color: Colors.white,
              height: 1.5,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ================= TASK REVIEW =================
  Widget _taskReview({required String title, required String taskKey}) {
    final strengths = (aiResult?['strengths'] as List?) ?? [];
    final improvements = (aiResult?['improvements'] as List?) ?? [];
    final taskErrors =
        (aiResult?['taskFeedback']?[taskKey]?['errors'] as List?) ?? [];

    final answer = resultData?['tasks']?[taskKey]?['answer'] ?? "";
    final rewrite = aiResult?['suggestedRewrite']?[taskKey]?['text'] ?? answer;

    final highlights =
        (aiResult?['suggestedRewrite']?[taskKey]?['highlightPhrases']
            as List?) ??
        [];

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
            label: "Good",
            color: goodGreen,
            text: strengths != null && strengths.isNotEmpty
                ? strengths.first
                : "No strengths available.",
          ),

          _highlightBlock(
            label: "Needs Improvement",
            color: warnYellow,
            text: improvements != null && improvements.isNotEmpty
                ? improvements.first
                : "No improvements available.",
          ),

          _highlightBlock(
            label: "Error",
            color: errorRed,
            text: taskErrors.isNotEmpty
                ? taskErrors.first
                : "No errors available.",
          ),

          const SizedBox(height: 12),
          const Text(
            "Suggested Rewrite:",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),

          _highlightedText(fullText: rewrite, highlights: highlights),
        ],
      ),
    );
  }

  Widget _highlightBlock({
    required String label,
    required Color color,
    required String text,
  }) {
    IconData icon;

    if (label == "Good") {
      icon = Icons.check;
    } else if (label == "Error") {
      icon = Icons.cancel_outlined;
    } else {
      icon = Icons.warning_amber_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: Colors.black87, height: 1.5),
                children: [
                  TextSpan(
                    text: "$label\n",
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  TextSpan(text: text),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= VOCAB =================
  Widget _vocabUpgrade() {
    final vocab = aiResult?['vocabularyFeedback'];

    final weakWords = (vocab?['weakWords'] as List?) ?? [];
    final betterWords = (vocab?['betterAlternatives'] as List?) ?? [];
    final collocations = (vocab?['collocationSuggestions'] as List?) ?? [];

    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Lexical Resource Analysis",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 16),

          if (weakWords.isNotEmpty)
            _bulletSection("Weak Vocabulary", weakWords, Colors.red),

          if (betterWords.isNotEmpty)
            _bulletSection("Better Alternatives", betterWords, Colors.green),

          if (collocations.isNotEmpty)
            _bulletSection(
              "Collocation Suggestions",
              collocations,
              Colors.orange,
            ),
        ],
      ),
    );
  }

  Widget _bulletSection(String title, List items, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 16,
            ),
          ),
          const SizedBox(height: 8),
          ...items.map(
            (e) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.circle, size: 8, color: color),
                  const SizedBox(width: 8),
                  Expanded(child: Text(e.toString())),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _grammarUpgrade() {
    final grammar = aiResult?['grammarFeedback'];

    final errors = (grammar?['commonErrors'] as List?) ?? [];
    final structureIssues =
        (grammar?['sentenceStructureIssues'] as List?) ?? [];
    final suggestions = (grammar?['improvementSuggestions'] as List?) ?? [];

    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Grammar Range & Accuracy",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 20,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 16),

          if (errors.isNotEmpty)
            _bulletSection("Common Errors", errors, Colors.red),

          if (structureIssues.isNotEmpty)
            _bulletSection(
              "Sentence Structure Issues",
              structureIssues,
              Colors.orange,
            ),

          if (suggestions.isNotEmpty)
            _bulletSection(
              "Improvement Suggestions",
              suggestions,
              Colors.green,
            ),
        ],
      ),
    );
  }

  // ================= BAND TIPS =================
  Widget _bandUpgradeTips() {
    final tips = aiResult?['bandUpgradeTips'] as List?;

    final List<String> tipList = tips != null && tips.isNotEmpty
        ? List<String>.from(tips)
        : [
            "**Vocabulary:** Actively learn synonyms and topic-specific vocabulary.",
            "**Grammar:** Improve sentence structure and reduce grammar errors.",
            "**Task 1:** Provide clearer data comparisons.",
            "**Task 2:** Develop arguments with specific examples.",
            "**Coherence and Cohesion:** Use better linking devices.",
          ];

    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "How to Reach the Next Band",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 16),

          ...tipList.map((e) => _improvementItem(e)).toList(),
        ],
      ),
    );
  }

  Widget _improvementItem(String text) {
    String title = "";
    String content = text;

    if (text.contains(":")) {
      title = text.split(":").first.replaceAll("**", "").trim();
      content = text.split(":").sublist(1).join(":").trim();
    }

    Color color = Colors.blue;
    IconData icon = Icons.arrow_right;

    switch (title.toLowerCase()) {
      case "vocabulary":
        color = Colors.green;
        icon = Icons.auto_awesome;
        break;
      case "grammar":
        color = Colors.purple;
        icon = Icons.rule;
        break;
      case "task 1":
        color = Colors.orange;
        icon = Icons.bar_chart;
        break;
      case "task 2":
        color = Colors.redAccent;
        icon = Icons.edit;
        break;
      case "coherence":
      case "coherence and cohesion":
        color = Colors.teal;
        icon = Icons.link;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(
                  color: Colors.black87,
                  height: 1.5,
                  fontSize: 14,
                ),
                children: [
                  if (title.isNotEmpty)
                    TextSpan(
                      text: "$title\n",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  TextSpan(text: content),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _safeAIResult() {
    final task1WordCount = resultData?['tasks']?['task1']?['wordCount'] ?? 0;
    final task2WordCount = resultData?['tasks']?['task2']?['wordCount'] ?? 0;

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
        "Ideas are generally understandable.",
      ],
      "improvements": [
        "Develop explanations with clearer examples.",
        "Improve grammar accuracy in complex sentences.",
        "Expand academic vocabulary range.",
      ],
      "taskFeedback": {
        "task1": {
          "errors": [
            "Limited use of complex sentence structures.",
            "Some data comparisons lack clarity.",
          ],
        },
        "task2": {
          "errors": [
            "Arguments are not fully developed.",
            "Grammar inaccuracies affect coherence.",
          ],
        },
      },

      "bandUpgradeTips": [
        "Use more varied sentence structures.",
        "Avoid repeating basic vocabulary.",
        "Add more detailed comparisons in Task 1.",
        "Support arguments with examples in Task 2.",
      ],
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
                    builder: (_) => WritingTestPage(testId: testId),
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
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: child,
    );
  }
}
