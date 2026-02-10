import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReadingResultPage extends StatelessWidget {
  final String resultId;

  const ReadingResultPage({super.key, required this.resultId});

  // ================= COLORS =================
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color bgColor = Color(0xFFF6FAFF);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color errorRed = Color(0xFFE53935);
  static const Color textGrey = Color(0xFF455A64);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,

      // ================= APP BAR =================
      appBar: AppBar(
        title: const Text(
          "Reading Result",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: primaryBlue,
        elevation: 0,
      ),

      // ================= BODY =================
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

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _overallResultCard(data),
              const SizedBox(height: 20),
              _bandDescriptorCard(data['band']),
              const SizedBox(height: 20),
              _questionTypeAnalysis(data['typeScore']),
              const SizedBox(height: 20),
              _improvementTips(data),
              const SizedBox(height: 24),
              _reviewButtons(context),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  // ================= OVERALL RESULT =================
  Widget _overallResultCard(Map<String, dynamic> data) {
    final int correct = data['correct'];
    final int incorrect = data['incorrect'];
    final double band = data['band'];
    final int seconds = data['durationUsed'];

    final String time =
        "${seconds ~/ 60}m ${(seconds % 60).toString().padLeft(2, '0')}s";

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF42A5F5), Color(0xFF90CAF9)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("Overall Reading Band", style: TextStyle(color: Colors.white70)),
          SizedBox(height: 6),
          Text(
            band.toString(),
            style: TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,

            children: [
              _ResultStat(
                label: "Correct",
                value: "$correct / ${correct + incorrect}",
              ),
              _ResultStat(
                label: "Accuracy",
                value: "${(correct / (correct + incorrect) * 100).round()}%",
              ),
              _ResultStat(label: "Time", value: time),
            ],
          ),
        ],
      ),
    );
  }

  // ================= BAND DESCRIPTOR =================
  Widget _bandDescriptorCard(double band) {
    final descriptor = _getBandDescriptor(band);

    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Band $band Descriptor",
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 10),

          ...descriptor.map(
            (line) => Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Text("• $line"),
            ),
          ),
        ],
      ),
    );
  }

  List<String> _getBandDescriptor(double band) {
    if (band >= 7.5) {
      return [
        "Demonstrates a very strong understanding of complex texts.",
        "Accurately identifies main ideas, details, and writer’s opinions.",
        "Handles paraphrasing and inference questions with high accuracy.",
        "Rarely makes mistakes in NOT GIVEN questions.",
      ];
    }

    if (band >= 7.0) {
      return [
        "Understands both main ideas and supporting details clearly.",
        "Can locate information efficiently across the passage.",
        "Occasional mistakes occur in inference or matching questions.",
        "Overall reading strategy is effective.",
      ];
    }

    if (band >= 6.5) {
      return [
        "Understands main ideas and most specific details.",
        "Can locate information but may struggle with paraphrased content.",
        "Errors mainly occur in NOT GIVEN and inference questions.",
        "Needs to improve speed and keyword recognition.",
      ];
    }

    if (band >= 6.0) {
      return [
        "Understands general meaning but misses some specific details.",
        "Has difficulty with paraphrasing and matching information.",
        "Inference questions are often answered incorrectly.",
        "Needs to improve scanning and skimming skills.",
      ];
    }

    return [
      "Has limited understanding of the overall passage.",
      "Struggles to locate specific information accurately.",
      "Frequently confused by paraphrasing and NOT GIVEN questions.",
      "Needs significant improvement in basic reading strategies.",
    ];
  }

  // ================= QUESTION TYPE ANALYSIS =================
  Widget _questionTypeAnalysis(Map<String, dynamic> typeScore) {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Performance by Question Type",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 12),
          ...typeScore.entries.map((e) {
            final correct = e.value['correct'];
            final total = e.value['total'];

            final double rate = correct / total;

            final Color color;
            if (rate >= 0.7) {
              color = successGreen; // xanh
            } else if (rate >= 0.4) {
              color = Colors.orange; // cam
            } else {
              color = errorRed; // đỏ
            }

            return _typeRow(_prettyTypeName(e.key), "$correct / $total", color);
          }).toList(),
        ],
      ),
    );
  }

  String _prettyTypeName(String raw) {
    switch (raw) {
      case "MCQ":
        return "Multiple Choice";
      case "TFNG":
        return "TRUE / FALSE / NOT GIVEN";
      case "SENTENCE":
        return "Sentence Completion";
      default:
        return raw;
    }
  }

  Widget _typeRow(String type, String score, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Expanded(child: Text(type)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              score,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  // ================= REVIEW BUTTONS =================
  Widget _reviewButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
  child: SizedBox(
    height: 40,
    child: OutlinedButton.icon(
      onPressed: () {
        Navigator.pop(context);
      },
      icon: const Icon(Icons.menu_book, size: 18),
      label: const Text(
        "Back to Reading",
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryBlue,
        side: const BorderSide(color: primaryBlue),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  ),
),

        const SizedBox(width: 12),
        Expanded(
  child: SizedBox(
    height: 40,
    child: ElevatedButton.icon(
      onPressed: () {
        // Navigator.push(
        //         context,
        //         MaterialPageRoute(
        //           builder: (_) => ReadingReviewPage(
        //             resultId: resultId,
        //           ),
        //         ),
        //       );
      },
      icon: const Icon(Icons.analytics, size: 18, color: Colors.white),
      label: const Text(
        "Review Answers",
        style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: primaryBlue,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    ),
  ),
),

      ],
    );
  }

  // ================= IMPROVEMENT TIPS =================
  Widget _improvementTips(Map<String, dynamic> data) {
    final tips = _generateTips(
      band: data['band'],
      typeScore: data['typeScore'],
    );

    return _card(
  Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Row(
        children: const [
          Icon(Icons.lightbulb, color: Colors.orange),
          SizedBox(width: 8),
          Text(
            "Teacher's Feedback",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
      const SizedBox(height: 12),

      ...tips.map(
        (t) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            "• $t",
            style: const TextStyle(
              fontSize: 14,
              height: 1.5,
            ),
          ),
        ),
      ),
    ],
  ),
);

  }

  List<String> _generateTips({
    required double band,
    required Map<String, dynamic> typeScore,
  }) {
    List<String> tips = [];

    // ===== THEO BAND =====
    if (band < 6.0) {
      tips.add(
        "Focus on understanding the general meaning of each paragraph before answering questions.",
      );
      tips.add(
        "Improve basic skimming and scanning skills to locate keywords faster.",
      );
    } else if (band < 6.5) {
      tips.add(
        "Pay more attention to paraphrasing, especially when keywords are not repeated exactly.",
      );
    } else if (band < 7.0) {
      tips.add(
        "Work on inference questions where answers are implied rather than stated directly.",
      );
    } else {
      tips.add(
        "Your comprehension is strong. Focus on improving speed to double-check answers.",
      );
    }

    // ===== THEO QUESTION TYPE =====
    if (typeScore.containsKey("TFNG")) {
      final tfng = typeScore["TFNG"];
      if (tfng['correct'] / tfng['total'] < 0.6) {
        tips.add(
          "For TRUE / FALSE / NOT GIVEN questions, avoid using personal knowledge—only rely on the passage.",
        );
      }
    }

    if (typeScore.containsKey("SENTENCE")) {
      final sent = typeScore["SENTENCE"];
      if (sent['correct'] / sent['total'] < 0.6) {
        tips.add(
          "Sentence completion mistakes suggest difficulty with paraphrasing. Practice identifying synonym patterns.",
        );
      }
    }

    if (typeScore.containsKey("MCQ")) {
      final mcq = typeScore["MCQ"];
      if (mcq['correct'] / mcq['total'] < 0.6) {
        tips.add(
          "For multiple-choice questions, read the question stem carefully before checking the options.",
        );
      }
    }

    // ===== FALLBACK =====
    if (tips.isEmpty) {
      tips.add(
        "Maintain your current reading strategy and continue practicing with full-length tests.",
      );
    }

    return tips;
  }

  // ================= SHARED CARD =================
  Widget _card(Widget child) {
    return Container(
      padding: const EdgeInsets.all(16),
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
      child: child,
    );
  }
}

// ================= SMALL STAT =================
class _ResultStat extends StatelessWidget {
  final String label;
  final String value;

  const _ResultStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.white70)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
