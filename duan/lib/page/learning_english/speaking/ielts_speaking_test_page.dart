import 'package:flutter/material.dart';
import 'speaking_result_page.dart';

class IeltsSpeakingTestPage extends StatelessWidget {
  const IeltsSpeakingTestPage({super.key});

  // ===== COLORS =====
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color bgColor = Color(0xFFF6FAFF);
  static const Color textGrey = Color(0xFF607D8B);
  static const Color recordRed = Color(0xFFE53935);

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
          "IELTS Speaking Test",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                "Part 1 / 3",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
            ),
          ),
        ],
      ),

      // ================= BODY =================
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _partHeader(),
          const SizedBox(height: 20),

          _questionCard(),
          const SizedBox(height: 24),

          _recordingPanel(),
          const SizedBox(height: 32),

          _actionButtons(context),
        ],
      ),
    );
  }

  // ================= PART HEADER =================
  Widget _partHeader() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF42A5F5), Color(0xFF90CAF9)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "PART 1 - Introduction & Interview",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "Answer the following questions. Speak naturally.",
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 10),
          Text("Time: 4 – 5 minutes", style: TextStyle(color: Colors.white)),
        ],
      ),
    );
  }

  // ================= QUESTION =================
  Widget _questionCard() {
    return Container(
      padding: const EdgeInsets.all(20),
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
        children: const [
          Text(
            "Question 1",
            style: TextStyle(fontWeight: FontWeight.bold, color: primaryBlue),
          ),
          SizedBox(height: 10),
          Text(
            "Can you tell me about your hometown?",
            style: TextStyle(fontSize: 18, height: 1.5),
          ),
          SizedBox(height: 14),
          Text(
            "Suggested answer length: 20–30 seconds",
            style: TextStyle(color: textGrey, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  // ================= RECORDING PANEL =================
  Widget _recordingPanel() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const Text(
            "Recording",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          const SizedBox(height: 12),

          const Text(
            "00:18",
            style: TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),

          const SizedBox(height: 20),

          CircleAvatar(
            radius: 36,
            backgroundColor: recordRed,
            child: const Icon(Icons.mic, size: 36, color: Colors.white),
          ),

          const SizedBox(height: 12),
          const Text(
            "Tap to start / stop recording",
            style: TextStyle(color: textGrey),
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
          child: OutlinedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SpeakingResultPage()),
              );
            },
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 14),
              foregroundColor: primaryBlue,
              side: const BorderSide(color: primaryBlue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              "End Test",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: ElevatedButton(
            onPressed: () {
              //TODO: Next Question
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              "Next Question",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
