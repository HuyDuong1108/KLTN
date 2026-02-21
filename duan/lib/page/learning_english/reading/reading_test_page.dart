import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'reading_result_page.dart';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class ReadingTestPage extends StatefulWidget {
  final String testId;
  const ReadingTestPage({super.key, required this.testId});

  @override
  State<ReadingTestPage> createState() => _ReadingTestPageState();
}

class _ReadingTestPageState extends State<ReadingTestPage> {
  // ================= COLORS =================
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color highlightYellow = Color(0xFFFFF59D);
  static const Color highlightBlue = Color(0xFFB3E5FC);
  static const Color highlightGreen = Color(0xFFC8E6C9);
  static const Color highlightPurple = Color(0xFFE1BEE7); // THÊM MÀU TÍM
  static const Color highlightOrange = Color(0xFFFFE0B2);
  static const Color bgColor = Color(0xFFF6FAFF);
  static const Color textGrey = Color(0xFF455A64);

  // ================= STATE =================

  Timer? _timer;
  int _remainingSeconds = 0;
  bool _timerStarted = false;

  int _durationMinutes = 60; // fallback nếu Firestore thiếu

  final Map<int, List<TextMark>> passageMarks = {};
  int? currentPassageIndex;
  Offset? selectionPosition;
  TextSelection? currentSelection;
  final FocusNode _focusNode = FocusNode();
  bool isMenuOpen = false;

  final Map<int, String?> answers = {};
  final Map<int, TextEditingController> sentenceControllers = {};

  // ================= BUILD =================
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
          "IELTS Reading Test",
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
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('reading_tests')
            .doc(widget.testId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final List passages = data['passages'];

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: passages.length,
            itemBuilder: (context, index) {
              final passage = passages[index];
              final List questions = passage['questions'];

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _passageHeader(index + 1),
                  _readingPassage(passage['content'], index),
                  const SizedBox(height: 24),
                  _questionSection(questions),
                  const SizedBox(height: 40),
                ],
              );
            },
          );
        },
      ),

      // ================= SUBMIT =================
      bottomNavigationBar: _bottomSubmitBar(),
    );
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
      await docRef.update({"listeningReadingCount": FieldValue.increment(1)});
    }
  }

  @override
  void initState() {
    super.initState();
    _loadTestAndStartTimer();
  }

  Future<void> _loadTestAndStartTimer() async {
    final doc = await FirebaseFirestore.instance
        .collection('reading_tests')
        .doc(widget.testId)
        .get();

    if (!doc.exists) return;

    final data = doc.data()!;

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
    final int m = seconds ~/ 60;
    final int s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Future<void> _autoSubmit() async {
    final doc = await FirebaseFirestore.instance
        .collection('reading_tests')
        .doc(widget.testId)
        .get();

    if (!doc.exists) return;

    final data = doc.data()!;
    final passages = data['passages'];

    final userAnswers = _collectUserAnswers();
    final result = await _calculateResult(userAnswers, passages);

    final docRef = FirebaseFirestore.instance
        .collection('reading_results')
        .doc();

    await docRef.set({
      "testId": widget.testId,
      "submittedAt": FieldValue.serverTimestamp(),
      "durationUsed": (_durationMinutes * 60) - _remainingSeconds,
      "totalQuestions": result['correct'] + result['incorrect'],
      "correct": result['correct'],
      "incorrect": result['incorrect'],
      "accuracy": result['accuracy'],
      "band": result['band'],
      "typeScore": result['typeScore'],
      "answers": userAnswers,
      "questions": result['questionResults'],
      "passages": passages,
    });
    await _updateDailyGoal();
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('latestTest')
          .doc('result')
          .set({
            "testType": "Reading",
            "testId": widget.testId,
            "band": result['band'],
            "score": result['correct'], // dùng correct làm score
            "durationMinutes": _durationMinutes,
            "submittedAt": FieldValue.serverTimestamp(),
            "reviewPath": docRef.path,
          });
    }

    if (!mounted) return;

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => ReadingResultPage(resultId: docRef.id)),
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    _focusNode.dispose();
    for (var controller in sentenceControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Map<String, String> _collectUserAnswers() {
    final Map<String, String> result = {};

    // MCQ + TFNG
    answers.forEach((key, value) {
      if (value != null) {
        result[key.toString()] = value!;
      }
    });

    // SENTENCE
    sentenceControllers.forEach((key, controller) {
      result[key.toString()] = controller.text.trim();
    });

    return result;
  }

  Map<String, dynamic> _calculateResult(
    Map<String, String> userAnswers,
    List passages,
  ) {
    int correct = 0;
    Map<String, Map<String, int>> typeScore = {};

    List<Map<String, dynamic>> questionResults = [];

    for (int pIndex = 0; pIndex < passages.length; pIndex++) {
      final passage = passages[pIndex];

      for (final q in passage['questions']) {
        final String id = q['id'].toString();
        final String correctAnswer = (q['answer'] ?? '')
            .toString()
            .toLowerCase()
            .trim();

        final String userAnswer = (userAnswers[id] ?? '').toLowerCase().trim();

        final bool isCorrect =
            userAnswer.isNotEmpty && userAnswer == correctAnswer;

        if (isCorrect) correct++;

        final String type = q['type'];
        typeScore.putIfAbsent(type, () => {"correct": 0, "total": 0});

        typeScore[type]!["total"] = typeScore[type]!["total"]! + 1;

        if (isCorrect) {
          typeScore[type]!["correct"] = typeScore[type]!["correct"]! + 1;
        }

        final String explanation = q['explanation'] ?? '';
        final Map<String, dynamic>? evidence = q['evidence'];

        questionResults.add({
          "id": q['id'],
          "type": q['type'],
          "question": q['question'],
          "userAnswer": userAnswer,
          "correctAnswer": correctAnswer,
          "correct": isCorrect,
          "passageIndex": pIndex,
          "start": q['start'], // nếu có
          "end": q['end'], // nếu có
          "explanation": explanation,
          "start": evidence?['start'],
          "end": evidence?['end'],
        });
      }
    }

    final int total = questionResults.length;
    final int incorrect = total - correct;
    final double accuracy = correct / total;

    double band;
    if (correct >= 30)
      band = 7.0;
    else if (correct >= 26)
      band = 6.5;
    else if (correct >= 23)
      band = 6.0;
    else
      band = 5.5;

    return {
      "correct": correct,
      "incorrect": incorrect,
      "accuracy": accuracy,
      "band": band,
      "typeScore": typeScore,
      "questionResults": questionResults,
    };
  }

  // ================= HEADER =================
  Widget _passageHeader(int passageNumber) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Reading Passage $passageNumber",
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            "Answer the questions below",
            style: TextStyle(color: textGrey),
          ),
        ],
      ),
    );
  }

  // ================= PASSAGE =================
  Widget _readingPassage(String passageText, int passageIndex) {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Listener(
        onPointerUp: (event) {
          // Lưu vị trí pointer
          selectionPosition = event.position;

          Future.delayed(const Duration(milliseconds: 100), () {
            if (currentSelection != null &&
                currentSelection!.start != currentSelection!.end &&
                !isMenuOpen) {
              setState(() {
                isMenuOpen = true;
                currentPassageIndex = passageIndex;
              });
              _showFloatingHighlightMenu();
            }
          });
        },
        child: SelectableText.rich(
          _buildHighlightedText(passageText, passageIndex),
          style: const TextStyle(fontSize: 15, height: 1.6, color: textGrey),
          onSelectionChanged: (selection, cause) {
            setState(() {
              currentSelection = selection;
              currentPassageIndex = passageIndex;
            });
          },
        ),
      ),
    );
  }

  // ================= FLOATING HIGHLIGHT MENU =================
  void _showFloatingHighlightMenu() {
    if (selectionPosition == null) return;

    final overlay = Overlay.of(context);
    OverlayEntry? overlayEntry;

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        left: selectionPosition!.dx - 180,
        top: selectionPosition!.dy - 80, // Hiển thị phía trên vị trí bôi đen
        child: Material(
          elevation: 8,
          borderRadius: BorderRadius.circular(16),
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: primaryBlue.withOpacity(0.2), width: 1),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // // Tiêu đề
                // Container(
                //   padding: const EdgeInsets.symmetric(horizontal: 8),
                //   child: Row(
                //     children: [
                //       Icon(Icons.palette, size: 18, color: primaryBlue),
                //       const SizedBox(width: 6),
                //       const Text(
                //         "Highlight",
                //         style: TextStyle(
                //           fontSize: 13,
                //           fontWeight: FontWeight.w600,
                //           color: textGrey,
                //         ),
                //       ),
                //     ],
                //   ),
                // ),

                // const SizedBox(width: 8),

                // // Divider dọc
                // Container(
                //   height: 30,
                //   width: 1,
                //   color: Colors.grey.shade300,
                // ),

                // const SizedBox(width: 8),

                // Các nút màu
                _floatingColorButton(highlightYellow, overlayEntry),
                const SizedBox(width: 6),
                _floatingColorButton(highlightBlue, overlayEntry),
                const SizedBox(width: 6),
                _floatingColorButton(highlightGreen, overlayEntry),
                const SizedBox(width: 6),
                _floatingColorButton(highlightPurple, overlayEntry),
                const SizedBox(width: 6),
                _floatingColorButton(highlightOrange, overlayEntry),

                const SizedBox(width: 8),

                // Divider dọc
                Container(height: 30, width: 1, color: Colors.grey.shade300),

                const SizedBox(width: 4),

                // Nút đóng
                IconButton(
                  icon: const Icon(Icons.close, size: 18),
                  onPressed: () {
                    overlayEntry?.remove();
                    setState(() {
                      isMenuOpen = false;
                      currentSelection = null;
                    });
                  },
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  color: Colors.grey.shade600,
                ),
              ],
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
  }

  // ================= FLOATING COLOR BUTTON =================
  Widget _floatingColorButton(Color color, OverlayEntry? overlayEntry) {
    return GestureDetector(
      onTap: () {
        if (currentSelection != null && currentPassageIndex != null) {
          // Khởi tạo list nếu chưa có
          if (!passageMarks.containsKey(currentPassageIndex)) {
            passageMarks[currentPassageIndex!] = [];
          }

          // Thêm mark vào passage tương ứng
          passageMarks[currentPassageIndex!]!.add(
            TextMark(
              start: currentSelection!.start,
              end: currentSelection!.end,
              color: color,
            ),
          );

          // Đóng overlay
          overlayEntry?.remove();

          // Update UI
          setState(() {
            isMenuOpen = false;
            currentSelection = null;
          });
        }
      },
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300, width: 2),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          Icons.check,
          size: 16,
          color: Colors.black.withOpacity(0.6),
        ),
      ),
    );
  }

  // ================= BUILD HIGHLIGHTED TEXT =================
  TextSpan _buildHighlightedText(String text, int passageIndex) {
    // Kiểm tra an toàn
    if (passageMarks[passageIndex] == null ||
        passageMarks[passageIndex]!.isEmpty) {
      return TextSpan(text: text);
    }

    final marks = passageMarks[passageIndex]!;

    // Sắp xếp marks theo vị trí start
    final sortedMarks = List<TextMark>.from(marks)
      ..sort((a, b) => a.start.compareTo(b.start));

    List<TextSpan> spans = [];
    int currentIndex = 0;

    for (var mark in sortedMarks) {
      // Kiểm tra index hợp lệ
      if (mark.start < 0 || mark.end > text.length || mark.start >= mark.end) {
        continue; // Bỏ qua mark không hợp lệ
      }

      // Text trước highlight
      if (currentIndex < mark.start) {
        spans.add(TextSpan(text: text.substring(currentIndex, mark.start)));
      }

      // Text được highlight
      spans.add(
        TextSpan(
          text: text.substring(mark.start, mark.end),
          style: TextStyle(backgroundColor: mark.color),
        ),
      );

      currentIndex = mark.end;
    }

    // Text còn lại sau highlight cuối
    if (currentIndex < text.length) {
      spans.add(TextSpan(text: text.substring(currentIndex)));
    }

    return TextSpan(children: spans);
  }

  // ================= QUESTIONS =================
  Widget _questionSection(List questions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Questions",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        ...questions.map((q) {
          final int id = q['id'];
          final String type = q['type'];

          if (type == "MCQ") {
            return _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$id. ${q['question']}",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  ...q['options'].map<Widget>((opt) {
                    return RadioListTile(
                      title: Text(opt),
                      value: opt,
                      groupValue: answers[id],
                      onChanged: (v) => setState(() => answers[id] = v),
                    );
                  }).toList(),
                ],
              ),
            );
          }

          if (type == "TFNG") {
            return _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$id. ${q['question']}",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  ...["TRUE", "FALSE", "NOT GIVEN"].map((v) {
                    return RadioListTile(
                      title: Text(v),
                      value: v,
                      groupValue: answers[id],
                      onChanged: (val) => setState(() => answers[id] = val),
                    );
                  }).toList(),
                ],
              ),
            );
          }

          if (type == "SENTENCE") {
            sentenceControllers.putIfAbsent(id, () => TextEditingController());

            return _card(
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "$id. ${q['question']}",
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: sentenceControllers[id],
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

          return const SizedBox.shrink();
        }).toList(),
      ],
    );
  }

  Widget _card(Widget child) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: child,
    );
  }

  // ================= SUBMIT =================
  Widget _bottomSubmitBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
        onPressed: () {
          _showSubmitDialog();
        },

        child: const Text(
          "Submit Reading Test",
          style: TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  void _showSubmitDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Submit Reading Test"),
        content: const Text(
          "Are you sure you want to submit your answers?\n"
          "You cannot change them after submission.",
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _autoSubmit(); // 🔥 DUY NHẤT chỗ điều hướng
            },
            style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
            child: const Text("Submit", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ================= MODEL =================
class TextMark {
  final int start;
  final int end;
  Color color;
  String? note;

  TextMark({
    required this.start,
    required this.end,
    required this.color,
    this.note,
  });
}
