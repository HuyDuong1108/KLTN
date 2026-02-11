import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WritingResultPage extends StatefulWidget {
  final String resultId;

  const WritingResultPage({super.key, required this.resultId});

  @override
  State<WritingResultPage> createState() => _WritingResultPageState();
}

class _WritingResultPageState extends State<WritingResultPage> {
  bool _loading = true;
  Map<String, dynamic>? resultData;
  Map<String, dynamic>? aiResult;

  // ================= COLORS =================
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color mintBlue = Color(0xFFE0F7FA);
  static const Color bgColor = Color(0xFFF6FAFF);

  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFFA726);
  static const Color textGrey = Color(0xFF455A64);

  String _getBandLabel(double band) {
    if (band >= 8) return "Very Good User";
    if (band >= 7) return "Good User";
    if (band >= 6) return "Competent User";
    if (band >= 5) return "Modest User";
    return "Limited User";
  }

  @override
  Widget build(BuildContext context) {
    final double overallBand = (aiResult?['overallBand'] ?? 0).toDouble();

    final String bandLabel = _getBandLabel(overallBand);
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
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
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

  @override
  void initState() {
    super.initState();
    _loadResult();
  }

  Future<void> _loadResult() async {
    final doc = await FirebaseFirestore.instance
        .collection('writing_results')
        .doc(widget.resultId)
        .get();

    final data = doc.data();

    setState(() {
      resultData = data ?? {};
      aiResult = data?['aiResult'] ?? _safeDefault();
      _loading = false;
    });
  }

  Map<String, dynamic> _safeDefault() {
    return {
      "overallBand": 5.5,
      "task1Band": 5.5,
      "task2Band": 5.5,
      "criteria": {},
      "strengths": [],
      "improvements": [],
      "bandUpgradeTips": [],
    };
  }

  // ================= OVERALL BAND =================
  Widget _overallBandCard() {
    final double overallBand = (aiResult?['overallBand'] ?? 0).toDouble();

    final String bandLabel = _getBandLabel(overallBand);

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
        children: [
          const Text(
            "Overall Writing Band",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            overallBand.toStringAsFixed(1),
            style: const TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          Text(bandLabel, style: const TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  // ================= BAND COMMENT =================
  Widget _bandComment() {
    final double overallBand = (aiResult?['overallBand'] ?? 0).toDouble();

    return _card(
      color: lightBlue,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.chat_bubble_outline, color: primaryBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              aiResult?['overallComment'] ??
                  _ruleBasedOverallComment(overallBand),
              style: const TextStyle(height: 1.5),
            ),
          ),
        ],
      ),
    );
  }

  String _ruleBasedOverallComment(double band) {
    if (band >= 7) {
      return "Your writing is well-developed and coherent. "
          "To reach Band 8, refine lexical precision and sentence variety.";
    } else if (band >= 6) {
      return "Your writing is clear and organised. "
          "Develop ideas more deeply and expand academic vocabulary.";
    } else {
      return "Focus on task response and grammar accuracy. "
          "Improve paragraph structure and idea development.";
    }
  }

  // ================= TASK SCORE =================
  Widget _taskScoreCard() {
    final double task1 = (aiResult?['task1Band'] ?? 0).toDouble();

    final double task2 = (aiResult?['task2Band'] ?? 0).toDouble();

    return Row(
      children: [
        _taskMiniCard("Task 1", task1.toStringAsFixed(1), lightBlue),
        const SizedBox(width: 16),
        _taskMiniCard("Task 2", task2.toStringAsFixed(1), mintBlue),
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
    final criteria = aiResult?['criteria'] ?? {};

    return _sectionCard(
      title: "Band Criteria Breakdown",
      child: Column(
        children: [
          _criteriaRow(
            "Task Achievement",
            (criteria['taskAchievement'] ?? 0).toDouble(),
          ),
          _criteriaRow(
            "Coherence & Cohesion",
            (criteria['coherence'] ?? 0).toDouble(),
          ),
          _criteriaRow(
            "Lexical Resource",
            (criteria['lexical'] ?? 0).toDouble(),
          ),
          _criteriaRow(
            "Grammar Range & Accuracy",
            (criteria['grammar'] ?? 0).toDouble(),
          ),
        ],
      ),
    );
  }

  // ================= FEEDBACK =================
  Widget _feedbackSection() {
    final strengths = aiResult?['strengths'] as List?;
    final improvements = aiResult?['improvements'] as List?;

    return _sectionCard(
      title: "Detailed Feedback",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "✔ Strengths",
            style: TextStyle(fontWeight: FontWeight.bold, color: successGreen),
          ),
          const SizedBox(height: 6),
          Text(
            strengths != null
                ? strengths.map((e) => "• $e").join("\n")
                : "• Clear structure\n• Relevant ideas",
            style: const TextStyle(height: 1.5),
          ),
          const SizedBox(height: 14),
          const Text(
            "⚠ Areas to Improve",
            style: TextStyle(fontWeight: FontWeight.bold, color: warningOrange),
          ),
          const SizedBox(height: 6),
          Text(
            improvements != null
                ? improvements.map((e) => "• $e").join("\n")
                : "• Expand explanations\n• Improve vocabulary range",
            style: const TextStyle(height: 1.5),
          ),
        ],
      ),
    );
  }

  // ================= IMPROVEMENT =================
  Widget _improvementSection() {
    final tips = aiResult?['bandUpgradeTips'] as List?;

    return _sectionCard(
      title: "How to Improve Your Writing Band",
      child: Text(
        tips != null
            ? tips.map((e) => "• $e").join("\n")
            : "• Develop ideas more clearly\n"
                  "• Improve grammar accuracy\n"
                  "• Expand academic vocabulary",
        style: const TextStyle(height: 1.6),
      ),
    );
  }

  // ================= ESSAY REVIEW =================
  Widget _essayReviewSection() {
    final task1 = (resultData?['tasks']?['task1']?['answer'] ?? "").toString();

    final task2 = (resultData?['tasks']?['task2']?['answer'] ?? "").toString();

    return _sectionCard(
      title: "Your Writing",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Task 1 Essay",
            style: TextStyle(fontWeight: FontWeight.bold, color: primaryBlue),
          ),
          const SizedBox(height: 6),
          Text(task1, style: const TextStyle(height: 1.5)),
          const SizedBox(height: 16),
          const Text(
            "Task 2 Essay",
            style: TextStyle(fontWeight: FontWeight.bold, color: primaryBlue),
          ),
          const SizedBox(height: 6),
          Text(task2, style: const TextStyle(height: 1.5)),
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
            band.toStringAsFixed(1),
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
