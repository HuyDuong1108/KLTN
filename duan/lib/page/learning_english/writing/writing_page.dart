import 'package:flutter/material.dart';
import 'writing_test_page.dart';
import 'writing_review_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class WritingPage extends StatefulWidget {
  const WritingPage({super.key});

  @override
  State<WritingPage> createState() => _WritingPageState();
}

class _WritingPageState extends State<WritingPage> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _loading = true;
  List<DocumentSnapshot> _tests = [];

  // ===== COLORS =====
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color softBlue = Color(0xFF90CAF9);
  static const Color bgColor = Color(0xFFF6FAFF);
  static const Color textGrey = Color(0xFF607D8B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,

      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text(
          "Writing",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _overviewCard(),
                const SizedBox(height: 28),

                const Text(
                  "Full Writing Tests",
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),

                ..._tests.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;

                  return _writingTestCard(
                    context: context,
                    testId: doc.id,
                    title: data['title'],
                    completed: false, // 👈 tạm thời
                  );
                }).toList(),
              ],
            ),
    );
  }

  @override
  void initState() {
    super.initState();
    _loadWritingTests();
  }

  Future<void> _loadWritingTests() async {
    final snapshot = await _firestore
        .collection('writing_tests')
        .orderBy('createdAt')
        .get();

    setState(() {
      _tests = snapshot.docs;
      _loading = false;
    });
  }

  // ================= OVERVIEW =================
  Widget _overviewCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFFBBDEFB), Color(0xFFE3F2FD)],
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.edit, size: 40, color: primaryBlue),
          const SizedBox(width: 16),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: const [
              Text(
                "Writing Progress",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SizedBox(height: 6),
              Text("Completed: 1 / 10"),
              Text("Average Band: 6.5"),
            ],
          ),
        ],
      ),
    );
  }

  // ================= TEST CARD =================
  Widget _writingTestCard({
    required BuildContext context,
    required String testId,
    required String title,
    required bool completed,
    double? band,
    int? task1Words,
    int? task2Words,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: const [
          BoxShadow(
            color: Color(0x334FC3F7),
            blurRadius: 10,
            offset: Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 10),

          Row(
            children: const [
              Icon(Icons.assignment_outlined, size: 18),
              SizedBox(width: 6),
              Text("Task 1 & Task 2"),
              SizedBox(width: 16),
              Icon(Icons.timer_outlined, size: 18),
              SizedBox(width: 6),
              Text("60 min"),
            ],
          ),

          const SizedBox(height: 14),

          if (completed) ...[
            Row(
              children: [
                _infoChip("Band $band"),
                const SizedBox(width: 4),
                _infoChip("T1: $task1Words words"),
                const SizedBox(width: 4),
                _infoChip("T2: $task2Words words"),
              ],
            ),

            const SizedBox(height: 14),
            _primaryButton(
              text: "Review Writing",
              icon: Icons.analytics_outlined,
              color: primaryBlue,
              onPressed: () {
                // Navigator.push(
                //   context,
                //   MaterialPageRoute(builder: (_) => const WritingReviewPage()),
                // );
              },
            ),
          ] else ...[
            const Text("Not attempted", style: TextStyle(color: textGrey)),
            const SizedBox(height: 14),
            _primaryButton(
              text: "Start Test",
              icon: Icons.play_arrow_rounded,
              color: softBlue,
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => WritingTestPage(testId: testId),
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }

  // ================= COMPONENTS =================
  Widget _infoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        text,
        style: const TextStyle(fontWeight: FontWeight.w600, color: primaryBlue),
      ),
    );
  }

  Widget _primaryButton({
    required String text,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon, color: Colors.white),
        label: Text(
          text,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
    );
  }
}
