import 'package:flutter/material.dart';
import '../../models/vocabulary.dart';
import 'study_result_pages.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/set_review_history_store.dart';

class FlashcardTypingPage extends StatefulWidget {
  final List<Vocabulary> vocabList;
  final String? setTitle;
  final String? setId;
  final bool isPersonal;
  const FlashcardTypingPage({
    super.key,
    required this.vocabList,
    this.setTitle,
    this.setId,
    this.isPersonal = false,
  });

  @override
  State<FlashcardTypingPage> createState() => _FlashcardTypingPageState();
}

class _FlashcardTypingPageState extends State<FlashcardTypingPage> {
  int currentIndex = 0;
  int score = 0;

  bool showResult = false;
  bool isCorrect = false;
  String feedback = "";
  final List<String> _needPractice = [];

  final TextEditingController _controller = TextEditingController();

  Future<void> _saveTypingSessionHistory() async {
    final setId = (widget.setId ?? '').trim();
    if (setId.isEmpty) return;

    final total = widget.vocabList.length;
    final correct = score;
    final wrong = (total - correct).clamp(0, total);

    try {
      await SetReviewHistoryStore.instance.addEntry(
        setId: setId,
        isPersonal: widget.isPersonal,
        entry: SetReviewHistoryEntry(
          id: '',
          createdAt: DateTime.now(),
          mode: 'typing',
          total: total,
          correct: correct,
          wrong: wrong,
        ),
      );
    } catch (_) {}
  }

  Future<void> checkAnswer() async {
    if (showResult) return;

    final userAnswer = _controller.text.trim().toLowerCase();
    final correct = widget.vocabList[currentIndex].word.toLowerCase();

    setState(() {
      showResult = true;
      isCorrect = userAnswer == correct;

      if (isCorrect) {
        score++;
        feedback = "Đúng rồi!";
      } else {
        final v = widget.vocabList[currentIndex];
        final line = '${v.word} (${v.romaji}) — ${v.meaning}';
        if (!_needPractice.contains(line)) {
          _needPractice.add(line);
        }
        feedback = "Sai rồi!\nĐáp án đúng: ${v.word}";
      }
    });

    Future.delayed(const Duration(milliseconds: 1600), () async {
      if (currentIndex < widget.vocabList.length - 1) {
        setState(() {
          currentIndex++;
          showResult = false;
          feedback = "";
          _controller.clear();
        });
      } else {
        await _saveTypingSessionHistory();
        if (!mounted) return;
        // final uid = FirebaseAuth.instance.currentUser?.uid;
        // if (uid != null && widget.setId != null && widget.setId!.trim().isNotEmpty) {
        //   final total = widget.vocabList.length;
        //   final correctCount = score;
        //   final wrongCount = total - score;

        //   try {
        //     await SetReviewHistoryStore.instance.addEntry(
        //       setId: widget.setId!,
        //       isPersonal: widget.isPersonal,
        //       entry: SetReviewHistoryEntry(
        //         id: '',
        //         createdAt: DateTime.now(),
        //         mode: 'typing',
        //         total: total,
        //         correct: correctCount,
        //         wrong: wrongCount,
        //       ),
        //     );
        //   } catch (_) {}
        // }

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => TypingResultPage(
              setTitle: widget.setTitle ?? "Typing Flashcard",
              correct: score,
              total: widget.vocabList.length,
              needPracticeLines: _needPractice,
              retryBuilder: (ctx) => FlashcardTypingPage(
                vocabList: widget.vocabList,
                setTitle: widget.setTitle,
                setId: widget.setId,
                isPersonal: widget.isPersonal,
              ),
            ),
          ),
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final vocab = widget.vocabList[currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F9FF),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text("Typing Flashcard"),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            /// PROGRESS BAR
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: (currentIndex + 1) / widget.vocabList.length,
                minHeight: 8,
                color: Colors.blue,
                backgroundColor: Colors.blue.shade100,
              ),
            ),
            const SizedBox(height: 20),

            /// FLASHCARD
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              padding: const EdgeInsets.all(24),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade200.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    vocab.meaning,
                    style: const TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    vocab.romaji,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey.shade600,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            /// INPUT + BUTTON
            Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                /// INPUT
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  decoration: BoxDecoration(
                    color: showResult ? Colors.grey.shade200 : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.blue.shade100.withOpacity(0.6),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: TextField(
                    controller: _controller,
                    enabled: !showResult,
                    textInputAction: TextInputAction.done,
                    style: const TextStyle(fontSize: 18),
                    decoration: InputDecoration(
                      hintText: "Nhập từ tiếng Anh...",
                      contentPadding: const EdgeInsets.symmetric(
                        vertical: 14,
                        horizontal: 16,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(16),
                        borderSide: BorderSide.none,
                      ),
                    ),
                    onSubmitted: (_) => checkAnswer(),
                  ),
                ),

                const SizedBox(height: 12),

                /// BUTTON
                SizedBox(
                  height: 50,
                  child: Opacity(
                    opacity: showResult ? 0.5 : 1,
                    child: ElevatedButton(
                      onPressed: showResult ? null : checkAnswer,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        "Xác nhận",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            /// ICON + FEEDBACK — Ở DƯỚI CÙNG
            Expanded(
              child: Column(
                children: [
                  /// ICON
                  Expanded(
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 300),
                      transitionBuilder: (child, animation) =>
                          ScaleTransition(scale: animation, child: child),
                      child: showResult
                          ? FittedBox(
                              key: ValueKey(isCorrect),
                              fit: BoxFit.contain,
                              child: Image.asset(
                                isCorrect
                                    ? "lib/image/dung.png"
                                    : "lib/image/sai.png",
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                  ),

                  /// FEEDBACK TEXT
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 300),
                    child: feedback.isNotEmpty
                        ? Text(
                            feedback,
                            key: ValueKey(feedback),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                              color: isCorrect ? Colors.green : Colors.red,
                            ),
                          )
                        : const SizedBox.shrink(),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
