import 'package:flutter/material.dart';
import 'writing_result_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';

class WritingTestPage extends StatefulWidget {
  final String testId;

  const WritingTestPage({super.key, required this.testId});

  @override
  State<WritingTestPage> createState() => _WritingTestPageState();
}

class _WritingTestPageState extends State<WritingTestPage> {
  bool _loading = true;
  List<Map<String, dynamic>> _tasks = [];
  Timer? _timer;
  int _remainingSeconds = 0;
  bool _timerStarted = false;

  int _durationMinutes = 60; // fallback

  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color bgColor = Color(0xFFF6FAFF);

  @override
  void initState() {
    super.initState();
    _loadTestAndStartTimer();
  }

  Future<void> _loadTest() async {
    final doc = await FirebaseFirestore.instance
        .collection('writing_tests')
        .doc(widget.testId)
        .get();

    final data = doc.data() as Map<String, dynamic>;

    setState(() {
      _tasks = List<Map<String, dynamic>>.from(data['tasks']);
      _loading = false;
    });
  }

  Future<void> _loadTestAndStartTimer() async {
    final doc = await FirebaseFirestore.instance
        .collection('writing_tests')
        .doc(widget.testId)
        .get();

    final data = doc.data() as Map<String, dynamic>;

    setState(() {
      _tasks = List<Map<String, dynamic>>.from(data['tasks']);
      _loading = false;
    });

    final int duration = (data['duration'] is int && data['duration'] > 0)
        ? data['duration']
        : _durationMinutes;

    _startTimer(duration);
  }

  void _startTimer(int minutes) {
    if (_timerStarted) return;

    _remainingSeconds = minutes * 60;
    _timerStarted = true;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_remainingSeconds <= 0) {
        timer.cancel();
        _autoSubmit();
      } else {
        setState(() {
          _remainingSeconds--;
        });
      }
    });
  }

  String _formatTime(int seconds) {
    if (seconds <= 0) return "00:00";
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  void _autoSubmit() {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const WritingResultPage()),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: primaryBlue,
        elevation: 0,
        title: const Text(
          "IELTS Writing Test",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                _formatTime(_remainingSeconds),
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: Colors.red,
                ),
              ),
            ),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                ..._tasks.map((task) {
                  return _taskCard(
                    title: task['type'] == 'task1' ? 'Task 1' : 'Task 2',
                    question: task['question'],
                    minWords: task['minWords'],
                    imageAsset: task['imageAsset'],
                  );
                }).toList(),

                const SizedBox(height: 32),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const WritingResultPage(),
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: const Text(
                      "Submit Writing",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  Widget _taskCard({
    required String title,
    required String question,
    required int minWords,
    String? imageAsset,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
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
          const SizedBox(height: 8),
          Text(question),
          const SizedBox(height: 8),
          if (title == "Task 1" && imageAsset != null) ...[
            Image.asset(imageAsset, fit: BoxFit.contain),
            const SizedBox(height: 8),
          ],

          Text(
            "Write at least $minWords words",
            style: const TextStyle(
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            maxLines: 8,
            decoration: InputDecoration(
              hintText: "Write your answer here...",
              filled: true,
              fillColor: const Color(0xFFF5FAFF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 6),
          const Text("Word count: 0", style: TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }
}
