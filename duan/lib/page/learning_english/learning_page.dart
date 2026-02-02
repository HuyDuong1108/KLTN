import 'package:flutter/material.dart';

class LearningPage extends StatelessWidget {
  const LearningPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5FAFF),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ===== HEADER =====
              const Text(
                "Learning",
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                "Improve your IELTS skills step by step",
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF607D8B),
                ),
              ),

              const SizedBox(height: 20),

              // ===== OVERALL BAND CARD =====
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF42A5F5), Color(0xFF81D4FA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0x3342A5F5),
                      blurRadius: 10,
                      offset: Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    const Icon(Icons.trending_up, color: Colors.white, size: 40),
                    const SizedBox(width: 14),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text(
                          "Overall IELTS Band",
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          "5.5 / 9.0",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 26,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ===== SKILLS GRID =====
              GridView.count(
                crossAxisCount: 2,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                mainAxisSpacing: 14,
                crossAxisSpacing: 14,
                childAspectRatio: 1.1,
                children: const [
                  _SkillCard(
                    icon: Icons.headphones,
                    title: "Listening",
                    band: "6.0",
                    lessons: "24 lessons",
                    color: Color(0xFF4FC3F7),
                  ),
                  _SkillCard(
                    icon: Icons.record_voice_over,
                    title: "Speaking",
                    band: "5.0",
                    lessons: "18 practices",
                    color: Color(0xFF81C784),
                  ),
                  _SkillCard(
                    icon: Icons.menu_book,
                    title: "Reading",
                    band: "6.0",
                    lessons: "30 passages",
                    color: Color(0xFFFFB74D),
                  ),
                  _SkillCard(
                    icon: Icons.edit,
                    title: "Writing",
                    band: "5.0",
                    lessons: "12 tasks",
                    color: Color(0xFFBA68C8),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ===== CTA =====
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: const [
                    Icon(Icons.lightbulb, color: Color(0xFFFFC107)),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        "Tip: Practice Speaking daily to improve fluency faster.",
                        style: TextStyle(fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ===== SKILL CARD =====

class _SkillCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String band;
  final String lessons;
  final Color color;

  const _SkillCard({
    required this.icon,
    required this.title,
    required this.band,
    required this.lessons,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () {
        // TODO: Navigate to skill detail page
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.25),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              "Band $band",
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Spacer(),
            Text(
              lessons,
              style: const TextStyle(
                fontSize: 12,
                color: Color(0xFF607D8B),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
