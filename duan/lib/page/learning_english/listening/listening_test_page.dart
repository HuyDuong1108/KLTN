import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'listening_result_page.dart';

class ListeningTestPage extends StatefulWidget {
  final String testId;

  const ListeningTestPage({
    super.key,
    required this.testId,
  });

  @override
  State<ListeningTestPage> createState() => _ListeningTestPageState();
}

class _ListeningTestPageState extends State<ListeningTestPage> {
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color bgColor = Color(0xFFF6FAFF);

  final Map<int, TextEditingController> _inputControllers = {};
  final Map<int, String> _mcqAnswers = {};

  Timer? _timer;
  int _remainingSeconds = 0;
  bool _timerStarted = false;

  Map<String, dynamic>? _testData;

  // ================= INIT =================
  @override
  void initState() {
    super.initState();
    _loadTestAndStartTimer();
  }

  // ================= LOAD DATA + START TIMER =================
  Future<void> _loadTestAndStartTimer() async {
    final doc = await FirebaseFirestore.instance
        .collection('listening_tests')
        .doc(widget.testId)
        .get();

    if (!doc.exists) return;

    _testData = doc.data()!;
    final int duration =
        (_testData!['duration'] is int && _testData!['duration'] > 0)
            ? _testData!['duration']
            : 30;

    _startTimer(duration);
    setState(() {});
  }

  // ================= TIMER =================
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
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ================= DISPOSE =================
  @override
  void dispose() {
    _timer?.cancel();
    for (final c in _inputControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ================= AUTO SUBMIT =================
  void _autoSubmit() {
    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => const ListeningResultPage(),
      ),
    );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    if (_testData == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final sections = _testData!['sections'] as List<dynamic>;

    return Scaffold(
      backgroundColor: bgColor,

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: primaryBlue,
        elevation: 0,
        title: const Text(
          "IELTS Listening Test",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                _formatTime(_remainingSeconds),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
            ),
          ),
        ],
      ),

      // ================= BODY =================
      body: Column(
        children: [
          _audioPlayer(),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                for (final section in sections) ...[
                  _sectionHeader(
                    title: "Section ${section['section']}",
                    description: section['instruction'],
                  ),
                  ..._buildQuestions(section['questions']),
                  const SizedBox(height: 36),
                ],
              ],
            ),
          ),
        ],
      ),

      bottomNavigationBar: _bottomBar(context),
    );
  }

  // ================= AUDIO PLAYER =================
  Widget _audioPlayer() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            "You will hear the recording ONCE only",
            style: TextStyle(
              fontSize: 13,
              fontStyle: FontStyle.italic,
              color: Colors.grey,
            ),
          ),
          SizedBox(height: 10),
          Row(
            children: [
              Icon(Icons.play_circle_fill, size: 40, color: primaryBlue),
              SizedBox(width: 12),
              Expanded(
                child: LinearProgressIndicator(
                  value: 0.0,
                  minHeight: 6,
                  backgroundColor: Color(0xFFE3F2FD),
                  valueColor: AlwaysStoppedAnimation(primaryBlue),
                ),
              ),
              SizedBox(width: 12),
              Text("AUDIO"),
            ],
          ),
        ],
      ),
    );
  }

  // ================= SECTION HEADER =================
  Widget _sectionHeader({
    required String title,
    required String description,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Text(description),
        ],
      ),
    );
  }

  // ================= QUESTIONS BUILDER =================
  List<Widget> _buildQuestions(List<dynamic> questions) {
    return questions.map<Widget>((q) {
      final int number = q['number'];
      final String question = q['question'];
      final String type = q['answerType'];

      if (type == 'input') {
        _inputControllers.putIfAbsent(
          number,
          () => TextEditingController(),
        );
        return _questionInput(number, question, _inputControllers[number]!);
      } else {
        return _questionMCQ(
          number,
          question,
          List<String>.from(q['options']),
        );
      }
    }).toList();
  }

  // ================= INPUT QUESTION =================
  Widget _questionInput(
    int number,
    String question,
    TextEditingController controller,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$number. $question",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: controller,
            decoration: InputDecoration(
              hintText: "Write NO MORE THAN TWO WORDS",
              filled: true,
              fillColor: const Color(0xFFF5FAFF),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= MCQ =================
  Widget _questionMCQ(
    int number,
    String question,
    List<String> options,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$number. $question",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 10),
          ...options.map(
            (e) => RadioListTile<String>(
              value: e,
              groupValue: _mcqAnswers[number],
              onChanged: (val) {
                setState(() {
                  _mcqAnswers[number] = val!;
                });
              },
              title: Text(e),
              dense: true,
            ),
          ),
        ],
      ),
    );
  }

  // ================= BOTTOM BAR =================
  Widget _bottomBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
          const Text(
            "40 Questions",
            style: TextStyle(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          ElevatedButton.icon(
            onPressed: () => _showSubmitDialog(context),
            icon: const Icon(Icons.check_circle_outline, color: Colors.white),
            label: const Text(
              "Submit Test",
              style:
                  TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(14),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showSubmitDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Submit Test"),
        content: const Text(
          "Are you sure you want to submit your answers?\nYou cannot change them after submission.",
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _autoSubmit();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
            ),
            child:
                const Text("Submit", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}
