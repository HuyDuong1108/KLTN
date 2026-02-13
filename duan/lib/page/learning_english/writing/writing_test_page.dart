import 'package:flutter/material.dart';
import 'writing_result_page.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';


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
  final Map<String, TextEditingController> _answerControllers = {};
  final Map<String, int> _wordCounts = {};
  bool _isSubmitting = false;

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
Future<void> _updateDailyGoal() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

  final docRef = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('dailyGoals')
      .doc(today);

  final snap = await docRef.get();

  // Nếu chưa có document thì tạo mới
  if (!snap.exists) {
    await docRef.set({
      "listeningReadingCount": 1,
      "flashcardSetCount": 0,
      "speakingCount": 0,
      "date": today,
    });
  } else {
    await docRef.update({
      "listeningReadingCount": FieldValue.increment(1),
    });
  }
}

  Future<void> _loadTestAndStartTimer() async {
    final doc = await FirebaseFirestore.instance
        .collection('writing_tests')
        .doc(widget.testId)
        .get();

    final data = doc.data() as Map<String, dynamic>;

    setState(() {
      _tasks = List<Map<String, dynamic>>.from(data['tasks']);
      for (final task in _tasks) {
        final String key = task['type'];
        _answerControllers[key] = TextEditingController();
        _wordCounts[key] = 0;
      }

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
        _submitWriting();
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

  Future<Map<String, dynamic>> _callGeminiAI({
    required String task1,
    required String task2,
  }) async {
    try {
      final apiKey = dotenv.env['API_KEY'];

      final url =
          "https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=$apiKey";

      final prompt =
          """
You are an IELTS Writing examiner.

Evaluate the following essays strictly according to official IELTS band descriptors.
For suggestedRewrite.highlightPhrases.type use only:
- vocabulary
- collocation
- grammar
- band_booster


Task 1:
$task1

Task 2:
$task2

Return ONLY valid JSON with this structure:

{
  "overallBand": number,
  "task1Band": number,
  "task2Band": number,
  "criteria": {
    "taskAchievement": number,
    "coherence": number,
    "lexical": number,
    "grammar": number
  },
  "overallComment": "string",
  "strengths": ["string"],
  "improvements": ["string"],
  "bandUpgradeTips": ["string"],
  "taskFeedback": {
    "task1": {
      "errors": ["string"]
    },
    "task2": {
      "errors": ["string"]
    }
  },

  "vocabularyFeedback": {
    "weakWords": ["string"],
    "betterAlternatives": ["string"],
    "collocationSuggestions": ["string"]
  },

  "grammarFeedback": {
    "commonErrors": ["string"],
    "sentenceStructureIssues": ["string"],
    "improvementSuggestions": ["string"]
  }
  "suggestedRewrite": {
  "task1": {
    "text": "string",
    "highlightPhrases": [
      {
        "phrase": "string",
        "type": "vocabulary" 
      }
    ]
  },
  "task2": {
    "text": "string",
    "highlightPhrases": [
      {
        "phrase": "string",
        "type": "grammar"
      }
    ]
  }
}

}


Do NOT include markdown.
Do NOT include explanation outside JSON.
Only return raw JSON.
""";

      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "contents": [
            {
              "parts": [
                {"text": prompt},
              ],
            },
          ],
        }),
      );

      if (response.statusCode != 200) {
        return _defaultAIResult();
      }

      final decoded = jsonDecode(response.body);

      if (decoded["candidates"] == null || decoded["candidates"].isEmpty) {
        return _defaultAIResult();
      }

      final raw = decoded["candidates"][0]["content"]["parts"][0]["text"];

      final cleaned = raw
          .replaceAll("```json", "")
          .replaceAll("```", "")
          .trim();

      final parsed = jsonDecode(cleaned);

      // validate structure
      if (parsed["overallBand"] == null) {
        return _defaultAIResult();
      }

      return parsed;
    } catch (e) {
      return _defaultAIResult();
    }
  }

  Future<void> _submitWriting() async {
    if (!mounted) return;

    setState(() {
      _isSubmitting = true;
    });

    final resultRef = FirebaseFirestore.instance
        .collection('writing_results')
        .doc();

    final task1 = _answerControllers['task1']!.text;
    final task2 = _answerControllers['task2']!.text;

    await resultRef.set({
      "testId": widget.testId,
      "submittedAt": FieldValue.serverTimestamp(),
      "durationUsed": (_durationMinutes * 60) - _remainingSeconds,
      "tasks": {
        "task1": {"answer": task1, "wordCount": _wordCounts['task1']},
        "task2": {"answer": task2, "wordCount": _wordCounts['task2']},
      },
      "aiResult": null,
    });
    await _updateDailyGoal();


    final aiData = await _callGeminiAI(task1: task1, task2: task2);

    await resultRef.update({"aiResult": aiData});

    setState(() {
      _isSubmitting = false;
    });

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => WritingResultPage(resultId: resultRef.id),
      ),
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
      body: Stack(
        children: [
          _loading
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
                        onPressed: _isSubmitting ? null : _submitWriting,
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

          if (_isSubmitting)
            Container(
              color: Colors.black.withOpacity(0.5),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Colors.white),
                    SizedBox(height: 20),
                    Text(
                      "Analyzing your writing...\nThis may take a few seconds.",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white, fontSize: 16),
                    ),
                  ],
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
            controller:
                _answerControllers[title == "Task 1" ? 'task1' : 'task2'],
            maxLines: 8,
            onChanged: (text) {
              final key = title == "Task 1" ? 'task1' : 'task2';
              setState(() {
                _wordCounts[key] = text.trim().isEmpty
                    ? 0
                    : text.trim().split(RegExp(r'\s+')).length;
              });
            },
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
          Text(
            "Word count: ${_wordCounts[title == "Task 1" ? 'task1' : 'task2'] ?? 0}",
            style: const TextStyle(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  Map<String, dynamic> _defaultAIResult() {
    return {
      "overallBand": 5.5,
      "task1Band": 5.5,
      "task2Band": 5.5,
      "criteria": {
        "taskAchievement": 5.5,
        "coherence": 5.5,
        "lexical": 5.5,
        "grammar": 5.5,
      },
      "overallComment":
          "Automatic evaluation is temporarily unavailable. Please review your writing manually.",
      "strengths": ["Your response is saved successfully."],
      "improvements": ["AI evaluation is currently unavailable."],
      "bandUpgradeTips": [
        "Practice developing ideas more clearly.",
        "Improve grammar accuracy.",
        "Expand academic vocabulary.",
      ],
      "taskFeedback": {
        "task1": {
          "errors": [
            "Limited use of complex sentence structures.",
            "Some comparisons are not fully explained.",
          ],
        },
        "task2": {
          "errors": [
            "Arguments lack deeper development.",
            "Grammar inaccuracies reduce clarity.",
          ],
        },
      },
    };
  }
}
