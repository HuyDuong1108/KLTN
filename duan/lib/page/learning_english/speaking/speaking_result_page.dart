import 'package:flutter/material.dart';
import 'speaking_review_page.dart';
import '../../../models/speaking_session.dart';

class SpeakingResultPage extends StatelessWidget {
  final SpeakingSession? session;

  const SpeakingResultPage({super.key, this.session});

  // ================= COLORS =================
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color bgColor = Color(0xFFF6FAFF);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFFA726);
  static const Color errorRed = Color(0xFFE53935);
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
          "Speaking Result",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      // ================= BODY =================
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _overallBandCard(),
          const SizedBox(height: 24),

          _criteriaScores(),
          const SizedBox(height: 24),

          _bandDescriptor(),
          const SizedBox(height: 24),

          _strengthWeakness(),
          const SizedBox(height: 24),

          _fluencyPronunciationInsight(),
          const SizedBox(height: 32),

          _actionButtons(context),
        ],
      ),
    );
  }

  // ================= OVERALL BAND =================
  Widget _overallBandCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF42A5F5), Color(0xFF90CAF9)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "Overall Speaking Band",
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 6),
          Text(
            "6.0",
            style: TextStyle(
              fontSize: 44,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "You communicate effectively but lack consistency in fluency and pronunciation.",
            style: TextStyle(color: Colors.white),
          ),
        ],
      ),
    );
  }

  // ================= CRITERIA SCORES =================
  Widget _criteriaScores() {
    return _card(
      title: "Speaking Criteria",
      child: Column(
        children: const [
          _criteriaRow("Fluency & Coherence", 6.0),
          _criteriaRow("Lexical Resource", 6.0),
          _criteriaRow("Grammar Range & Accuracy", 6.5),
          _criteriaRow("Pronunciation", 5.5),
        ],
      ),
    );
  }

  // ================= BAND DESCRIPTOR =================
  Widget _bandDescriptor() {
    return _card(
      title: "Band 6 Descriptor",
      child: const Text(
        "You can communicate meaning clearly in familiar situations. "
        "However, hesitation, repetition, and pronunciation issues "
        "sometimes reduce clarity, especially in longer answers.",
        style: TextStyle(height: 1.6),
      ),
    );
  }

  // ================= STRENGTH & WEAKNESS =================
  Widget _strengthWeakness() {
    return _card(
      title: "Strengths & Areas to Improve",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "✔ Strengths",
            style: TextStyle(fontWeight: FontWeight.bold, color: successGreen),
          ),
          SizedBox(height: 6),
          Text(
            "• Ideas are relevant and easy to understand.\n"
            "• Uses a reasonable range of vocabulary.\n"
            "• Grammar is generally accurate in simple sentences.",
            style: TextStyle(height: 1.5),
          ),
          SizedBox(height: 14),
          Text(
            "⚠ Areas to Improve",
            style: TextStyle(fontWeight: FontWeight.bold, color: warningOrange),
          ),
          SizedBox(height: 6),
          Text(
            "• Frequent pauses when answering Part 2.\n"
            "• Limited use of stress and intonation.\n"
            "• Some mispronounced word endings.",
            style: TextStyle(height: 1.5),
          ),
        ],
      ),
    );
  }

  // ================= FLUENCY & PRONUNCIATION =================
  Widget _fluencyPronunciationInsight() {
    return _card(
      title: "Speech Analysis",
      child: Column(
        children: [
          _analysisRow("Average Pause Length", "1.8s", warningOrange),
          _analysisRow("Speech Rate", "112 words/min", successGreen),
          _analysisRow("Pronunciation Accuracy", "78%", errorRed),
          _analysisRow("Intonation Variation", "Low", warningOrange),
        ],
      ),
    );
  }

  Widget _analysisRow(String label, String value, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(child: Text(label)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
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
              if (session != null) {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SpeakingReviewPage(session: session!),
                  ),
                );
              }
            },
            icon: const Icon(Icons.analytics),
            label: const Text("Review Speaking"),
            style: ElevatedButton.styleFrom(
              foregroundColor: Colors.white,
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
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}
