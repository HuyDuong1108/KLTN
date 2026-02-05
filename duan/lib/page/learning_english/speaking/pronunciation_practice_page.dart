import 'package:flutter/material.dart';

class PronunciationPracticePage extends StatelessWidget {
  const PronunciationPracticePage({super.key});

  // ================= COLORS =================
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color bgColor = Color(0xFFF6FAFF);
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
          "Pronunciation Practice",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      // ================= BODY =================
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _overviewCard(),
          const SizedBox(height: 28),

          const Text(
            "Practice Categories",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _categoryCard(
            icon: Icons.record_voice_over,
            title: "Individual Sounds",
            subtitle: "Practice difficult English sounds",
          ),

          _categoryCard(
            icon: Icons.trending_up,
            title: "Word Stress",
            subtitle: "Correct syllable stress",
          ),

          _categoryCard(
            icon: Icons.multitrack_audio,
            title: "Sentence Intonation",
            subtitle: "Sound natural & confident",
          ),

          const SizedBox(height: 28),

          const Text(
            "Practice Session",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          _practiceCard(),

          const SizedBox(height: 24),
          _feedbackCard(),
        ],
      ),

      // ================= CONTROL BAR =================
      bottomNavigationBar: _bottomControlBar(),
    );
  }

  // ================= OVERVIEW =================
  Widget _overviewCard() {
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
          const Text(
            "Your Pronunciation Level",
            style: TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          const Text(
            "Band 5.5",
            style: TextStyle(
              fontSize: 40,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: const [
              _miniStat("Accuracy", "60%"),
              _miniStat("Stress", "55%"),
              _miniStat("Intonation", "58%"),
              _miniStat("Speed", "65%"),
            ],
          ),
        ],
      ),
    );
  }

  // ================= CATEGORY CARD =================
  Widget _categoryCard({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.12),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 26,
            backgroundColor: lightBlue,
            child: Icon(icon, color: primaryBlue, size: 26),
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

  // ================= PRACTICE CARD =================
  Widget _practiceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Practice Sentence",
            style: TextStyle(
                fontWeight: FontWeight.bold, color: primaryBlue),
          ),
          const SizedBox(height: 10),
          const Text(
            "I think education plays a crucial role in shaping a person’s future.",
            style: TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 6),
          const Text(
            "/aɪ θɪŋk ˌedʒuˈkeɪʃən pleɪz ə ˈkruːʃl rəʊl/",
            style: TextStyle(color: textGrey),
          ),
          const SizedBox(height: 16),

          Row(
            children: [
              _iconButton(Icons.volume_up, "Listen"),
              const SizedBox(width: 12),
              _iconButton(Icons.mic, "Record"),
              const SizedBox(width: 12),
              _iconButton(Icons.replay, "Replay"),
            ],
          ),

          const SizedBox(height: 16),
          Row(
            children: const [
              Icon(Icons.check_circle, color: successGreen),
              SizedBox(width: 8),
              Text(
                "Pronunciation Score: 62%",
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= FEEDBACK =================
  Widget _feedbackCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: lightBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "AI Feedback",
            style: TextStyle(
                fontWeight: FontWeight.bold, color: primaryBlue),
          ),
          SizedBox(height: 10),
          Text(
            "⚠ You mispronounced the sound /θ/ in \"think\".\n"
            "Try placing your tongue gently between your teeth.\n\n"
            "✔ Good intonation in the second clause.\n\n"
            "💡 Band Tip: Replace \"plays a role\" with "
            "\"has a significant impact\" for higher band.",
            style: TextStyle(height: 1.6),
          ),
        ],
      ),
    );
  }

  // ================= CONTROL BAR =================
  Widget _bottomControlBar() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.skip_previous),
            color: primaryBlue,
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.navigate_next),
            label: const Text("Next Sentence"),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _iconButton(IconData icon, String label) {
    return Expanded(
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(icon),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryBlue,
          side: const BorderSide(color: primaryBlue),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        ),
      ),
    );
  }
}

// ================= MINI STAT =================
class _miniStat extends StatelessWidget {
  final String label;
  final String value;

  const _miniStat(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label,
            style: const TextStyle(color: Colors.white70, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
              color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ],
    );
  }
}
