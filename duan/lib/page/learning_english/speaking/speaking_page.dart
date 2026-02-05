import 'package:flutter/material.dart';
import 'ielts_speaking_test_page.dart';

class SpeakingPage extends StatelessWidget {
  const SpeakingPage({super.key});

  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color bgColor = Color(0xFFF6FAFF);
  static const Color textGrey = Color(0xFF607D8B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,

      // ===== APP BAR =====
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: primaryBlue,
        elevation: 0,
        title: const Text(
          "Speaking",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _overallSpeakingCard(),
          const SizedBox(height: 28),

          const Text(
            "Practice Modes",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const IeltsSpeakingTestPage()),
              );
            },
            child: _modeCard(
              icon: Icons.headset_mic,
              title: "IELTS Speaking Test",
              subtitle: "Simulate real IELTS speaking exam",
              color: primaryBlue,
            ),
          ),

          _modeCard(
            icon: Icons.chat_bubble_outline,
            title: "AI Speaking Partner",
            subtitle: "Practice speaking like a real conversation",
            color: Colors.teal,
          ),

          _modeCard(
            icon: Icons.record_voice_over,
            title: "Pronunciation Practice",
            subtitle: "Improve pronunciation & intonation",
            color: Colors.orange,
          ),

          const SizedBox(height: 28),

          const Text(
            "Recent Practices",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _historyItem("Mock Test – Part 2", "Band 6.0 • 2 days ago"),
          _historyItem("AI Conversation", "Fluency improved • Yesterday"),
        ],
      ),
    );
  }

  // ===== OVERALL CARD =====
  Widget _overallSpeakingCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: const LinearGradient(
          colors: [Color(0xFF42A5F5), Color(0xFF90CAF9)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Your Speaking Level",
            style: TextStyle(color: Colors.white70),
          ),
          SizedBox(height: 6),
          Text(
            "Band 6.0",
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 6),
          Text(
            "Good fluency, pronunciation needs improvement",
            style: TextStyle(color: Colors.white),
          ),
          SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _miniStat("Fluency", "6.0"),
              _miniStat("Pronunciation", "5.5"),
              _miniStat("Vocabulary", "6.0"),
              _miniStat("Grammar", "6.5"),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _miniStat(String label, String value) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  // ===== MODE CARD =====
  Widget _modeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(color: textGrey)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16),
        ],
      ),
    );
  }

  // ===== HISTORY ITEM =====
  Widget _historyItem(String title, String subtitle) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          const Icon(Icons.play_circle_outline, color: primaryBlue),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: const TextStyle(color: textGrey)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
