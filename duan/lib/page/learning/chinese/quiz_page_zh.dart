import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'quiz_result_page_zh.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class QuizPageZh extends StatefulWidget {
  final List tests;
final DocumentSnapshot lessonDoc;  final bool isReview;
  final Map<int, Map<String, dynamic>>? answers;

  const QuizPageZh({
    super.key,
    required this.tests,
     required this.lessonDoc,
    this.isReview = false,
    this.answers,
  });

  @override
  State<QuizPageZh> createState() => _QuizPageZhState();
}

class _QuizPageZhState extends State<QuizPageZh>
    with SingleTickerProviderStateMixin {
  int currentIndex = 0;
  int score = 0;
  Map<int, Map<String, dynamic>> userAnswers = {};
DocumentReference get lessonRef => widget.lessonDoc.reference;
  String get lessonId => widget.lessonDoc.id;
  String get courseId => lessonRef.parent.parent!.id;
  String get languageCode => lessonRef.parent.parent!.parent.parent!.id;

  late AnimationController _controller;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _slideAnim = Tween<Offset>(
      begin: const Offset(1, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  void _nextQuestion({required bool correct, dynamic answer}) {
    userAnswers[currentIndex] = {'correct': correct, 'answer': answer};

    if (correct) score++;

    if (!widget.isReview && currentIndex < widget.tests.length - 1) {
      _controller.reset();
      setState(() => currentIndex++);
      _controller.forward();
    } else {
      if (!widget.isReview) {
        _showResult();
      }
    }
  }

  Future<void> _saveResult() async {
    final user = FirebaseAuth.instance.currentUser!;
    final percent = (score / widget.tests.length * 100).round();
    final timeSpent = 6 * 60;

    await FirebaseFirestore.instance
        .collection('lessons')
        .doc(lessonId)
        .collection('results')
        .add({
      'uid': user.uid,
      'name': user.displayName ?? 'Người dùng',
      'score': score,
      'total': widget.tests.length,
      'percent': percent,
      'timeSpent': timeSpent,
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  void _showResult() async {
    if (!widget.isReview) {
      await _saveResult();
    }

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => QuizResultPageZh(
          lessonRef: lessonRef,
          score: score,
          total: widget.tests.length,
          timeSpent: const Duration(minutes: 6),
          answers: userAnswers,
          tests: widget.tests,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final question = widget.tests[currentIndex];

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Câu ${currentIndex + 1}/${widget.tests.length}"),
        backgroundColor: Colors.orange.shade400,
        elevation: 0,
      ),
      body: SlideTransition(
        position: _slideAnim,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(child: _buildQuestion(question)),
              if (widget.isReview) _reviewNavigation(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _reviewNavigation() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        children: [
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.grey.shade200,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed:
                  currentIndex > 0 ? () => setState(() => currentIndex--) : null,
              icon: const Icon(Icons.arrow_back, color: Colors.black),
              label: const Text(
                "Câu trước",
                style: TextStyle(color: Colors.black),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              onPressed: currentIndex < widget.tests.length - 1
                  ? () => setState(() => currentIndex++)
                  : null,
              icon: const Icon(Icons.arrow_forward, color: Colors.white),
              label: const Text(
                "Câu tiếp",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion(Map q) {
    switch (q["type"]) {
      case "choice":
        return _choiceQuestion(q);
      case "fill":
        return _fillChoiceQuestion(q);
      case "match":
        return _matchQuestion(q);
      default:
        return const Center(child: Text("Không hỗ trợ dạng này"));
    }
  }

  // ================= CHOICE =================

  Widget _choiceQuestion(Map q) {
    final correctAnswer = q["answer"];
    final reviewData = widget.answers?[currentIndex];
    final userAnswer = reviewData?['answer'];

    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _questionText(q["question"]),
          const SizedBox(height: 20),
          ...q["options"].map<Widget>((option) {
            Color bgColor = Colors.white;

            if (widget.isReview) {
              if (option == correctAnswer) {
                bgColor = Colors.green.shade100;
              } else if (option == userAnswer) {
                bgColor = Colors.red.shade100;
              }
            }

            return _optionTile(
              text: option,
              backgroundColor: bgColor,
              onTap: widget.isReview
                  ? null
                  : () => _nextQuestion(
                        correct: option == correctAnswer,
                        answer: option,
                      ),
            );
          }).toList(),
        ],
      ),
    );
  }

  // ================= FILL =================

  Widget _fillChoiceQuestion(Map q) {
    String? selected;
    final reviewData = widget.answers?[currentIndex];
    final userAnswer = reviewData?['answer'];

    return StatefulBuilder(
      builder: (context, setLocal) {
        final displayText = q["question"].replaceAll(
          "___",
          widget.isReview
              ? "_*${userAnswer ?? q['answer']}*_"
              : selected != null
                  ? "_*$selected*_"
                  : "_*_____ *_",
        );

        return _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _questionText(displayText),
              const SizedBox(height: 20),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: q["options"].map<Widget>((opt) {
                  final selectedNow = selected == opt;
                  return ChoiceChip(
                    label: Text(opt, style: const TextStyle(fontSize: 16)),
                    selected: selectedNow,
                    selectedColor: Colors.orange.shade200,
                    backgroundColor: Colors.grey.shade200,
                    onSelected: widget.isReview
                        ? null
                        : (_) => setLocal(() => selected = opt),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  onPressed: selected == null
                      ? null
                      : () => _nextQuestion(
                            correct: selected == q["answer"],
                            answer: selected,
                          ),
                  child: const Text(
                    "Xác nhận",
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
      },
    );
  }

  // ================= MATCH (GIỮ NGUYÊN) =================

  Widget _matchQuestion(Map q) {
    final Map pairs = q["pairs"];
    final left = pairs.keys.toList();
    final right = List<String>.from(pairs.values)..shuffle();

    String? selectedLeft;
    Set<String> matchedLeft = {};
    Set<String> matchedRight = {};

    if (widget.isReview) {
      final entries = pairs.entries.toList();

      return _card(
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _questionText("**Đáp án đúng**"),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Column(
                    children: List.generate(entries.length, (i) {
                      final color = _pairColor(i);
                      return _matchItem(
                        text: entries[i].key,
                        disabled: true,
                        selected: true,
                        colorOverride: color,
                        onTap: () {},
                      );
                    }),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    children: List.generate(entries.length, (i) {
                      final color = _pairColor(i);
                      return _matchItem(
                        text: entries[i].value,
                        disabled: true,
                        selected: true,
                        colorOverride: color,
                        onTap: () {},
                      );
                    }),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
    }

    return StatefulBuilder(
      builder: (context, setLocal) {
        return _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _questionText("**Nối từ đúng**"),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: left.map((l) {
                        final isMatched = matchedLeft.contains(l);
                        return _matchItem(
                          text: l,
                          selected: selectedLeft == l,
                          disabled: isMatched,
                          onTap: () {
                            if (isMatched) return;
                            setLocal(() => selectedLeft = l);
                          },
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      children: right.map((r) {
                        final isMatched = matchedRight.contains(r);
                        return _matchItem(
                          text: r,
                          disabled: isMatched,
                          onTap: () {
                            if (selectedLeft == null || isMatched) return;

                            final correct = pairs[selectedLeft] == r;

                            setLocal(() {
                              if (correct) {
                                matchedLeft.add(selectedLeft!);
                                matchedRight.add(r);
                              }
                              selectedLeft = null;
                            });

                            if (matchedLeft.length == pairs.length) {
                              _nextQuestion(
                                correct: true,
                                answer: Map.from(pairs),
                              );
                            }
                          },
                        );
                      }).toList(),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  // ================= UI HELPERS =================

  Widget _card(Widget child) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: child,
    );
  }

  MarkdownStyleSheet _questionStyle(BuildContext context) {
    return MarkdownStyleSheet(
      p: const TextStyle(
        fontSize: 19,
        fontWeight: FontWeight.w600,
        height: 1.45,
        color: Colors.black87,
      ),
      strong: const TextStyle(fontWeight: FontWeight.bold),
      em: TextStyle(
        fontStyle: FontStyle.italic,
        decoration: TextDecoration.underline,
        decorationThickness: 2,
        color: Colors.orange.shade700,
      ),
    );
  }

  Widget _questionText(String text) {
    return Markdown(
      data: text,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      styleSheet: _questionStyle(context),
    );
  }

  Widget _optionTile({
    required String text,
    required VoidCallback? onTap,
    Color backgroundColor = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: backgroundColor,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.orange.shade200),
          ),
          child: Row(
            children: [
              Icon(
                Icons.radio_button_unchecked,
                color: onTap == null ? Colors.grey : Colors.black,
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(text, style: const TextStyle(fontSize: 16))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _matchItem({
    required String text,
    bool selected = false,
    bool disabled = false,
    Color? colorOverride,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: disabled ? null : onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: colorOverride ??
                (disabled
                    ? Colors.green.shade100
                    : selected
                        ? Colors.orange.shade100
                        : Colors.white),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: colorOverride ??
                  (disabled ? Colors.green : Colors.orange.shade200),
            ),
          ),
          child: Center(
            child: Text(
              text,
              style: TextStyle(
                color: disabled ? Colors.green[800] : Colors.black,
                fontWeight: disabled ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Color _pairColor(int index) {
    final colors = [
      Colors.orange.shade200,
      Colors.blue.shade200,
      Colors.green.shade200,
      Colors.purple.shade200,
      Colors.pink.shade200,
      Colors.teal.shade200,
    ];
    return colors[index % colors.length];
  }
}
