import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';


class ListeningResultPage extends StatelessWidget {
  final String resultId;

const ListeningResultPage({
  super.key,
  required this.resultId,
});


  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color errorRed = Color(0xFFE53935);
  static const Color bgColor = Color(0xFFF6FAFF);
  static const Color warningOrange = Color(0xFFFFB74D);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        title: const Text(
          "Listening Result",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: primaryBlue,
        elevation: 0,
      ),
      body: FutureBuilder<DocumentSnapshot>(
  future: FirebaseFirestore.instance
      .collection('listening_results')
      .doc(resultId)
      .get(),
  builder: (context, snapshot) {
    if (!snapshot.hasData) {
      return const Center(child: CircularProgressIndicator());
    }

    final data = snapshot.data!.data() as Map<String, dynamic>;

    final double band = (data['band'] ?? 0).toDouble();
    final int correct = data['correct'] ?? 0;
    final int incorrect = data['incorrect'] ?? 0;
    final int duration = data['durationUsed'] ?? 0;

    final Map<String, dynamic> sectionScore =
        Map<String, dynamic>.from(data['sectionScore'] ?? {});

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _bandCard(band),
        const SizedBox(height: 24),
        _summaryCard(correct, incorrect, duration),
        const SizedBox(height: 28),
        _sectionResult(sectionScore),
        const SizedBox(height: 24),
        _feedbackCard(sectionScore),
        const SizedBox(height: 32),
        _actionButtons(context),
      ],
    );
  },
),

    );
  }

  // ================= BAND CARD =================
  Widget _bandCard(double band) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF42A5F5), Color(0xFF90CAF9)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x3342A5F5),
            blurRadius: 12,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Text(
            "Your Band Score",
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
          SizedBox(height: 8),
          Text(
            band.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 56,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "Good performance 👏",
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // ================= SUMMARY =================
  Widget _summaryCard(int correct, int incorrect, int duration) {
  return Row(
    children: [
      _summaryItem("Correct", "$correct", successGreen),
      const SizedBox(width: 12),
      _summaryItem("Incorrect", "$incorrect", errorRed),
      const SizedBox(width: 12),
      _summaryItem("Time", _formatTime(duration), primaryBlue),
    ],
  );
}

String _formatTime(int seconds) {
  final m = seconds ~/ 60;
  final s = seconds % 60;
  return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
}


  Widget _summaryItem(String title, String value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              title,
              style: const TextStyle(fontSize: 13, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  // ================= SECTION RESULT =================
  Widget _sectionResult(Map<String, dynamic> sectionScore) {
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text("Section Breakdown",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
      const SizedBox(height: 12),
      for (int i = 1; i <= 4; i++)
        _sectionTile(
          "Section $i",
          "${sectionScore[i.toString()] ?? 0} / 10",
        ),
    ],
  );
}


  Widget _sectionTile(String title, String score) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Text(
            title,
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Text(
            score,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
        ],
      ),
    );
  }

  // ================= FEEDBACK =================
  Widget _feedbackCard(Map<String, dynamic> sectionScore) {
  final List<String> weakSections = [];

  sectionScore.forEach((key, value) {
    if ((value ?? 0) < 6) {
      weakSections.add("Section $key");
    }
  });

  String message;
  if (weakSections.isNotEmpty) {
    message =
        "You should focus more on ${weakSections.join(', ')}. These sections are below 60%.";
  } else {
    message =
        "Great job! Your listening performance is consistent across all sections.";
  }

  return Container(
    padding: const EdgeInsets.all(18),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(20),
    ),
    child: Row(
      children: [
        const Icon(Icons.lightbulb, color: warningOrange, size: 30),
        const SizedBox(width: 12),
        Expanded(child: Text(message)),
      ],
    ),
  );
}


  // ================= ACTION BUTTONS =================
  Widget _actionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () {
              // TODO: Navigate to review answers page
            },
            icon: const Icon(Icons.search, color: Colors.white),
            label: const Text(
              "Review Answers",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 3,
            ),
          ),
        ),
        const SizedBox(height: 14),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () {
              Navigator.pop(context); // quay lại test
            },
            icon: const Icon(Icons.refresh),
            label: const Text(
              "Retake Test",
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            style: OutlinedButton.styleFrom(
              foregroundColor: primaryBlue,
              side: const BorderSide(color: primaryBlue),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

}
