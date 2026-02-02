import 'package:flutter/material.dart';
import '../../models/vocabulary.dart';
import 'dart:math';
import 'study_result_pages.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/set_review_history_store.dart';


class FlashcardQuizPage extends StatefulWidget {
  final List<Vocabulary> vocabList;
  final String? setTitle;
  final String? setId;
  final bool isPersonal;
  const FlashcardQuizPage({
    super.key,
    required this.vocabList,
    this.setTitle,
    this.setId,
    this.isPersonal = false,
  });

  @override
  State<FlashcardQuizPage> createState() => _FlashcardQuizPageState();
}

class _FlashcardQuizPageState extends State<FlashcardQuizPage> {
  int currentIndex = 0;
  int score = 0;
  String feedback = "";
  String? selectedAnswer;
  bool showResult = false;
  final List<String> _reviewLines = [];

  late List<String> options;
  

  @override
  void initState() {
    super.initState();
    options = getOptions(widget.vocabList[currentIndex]);
  }

  List<String> getOptions(Vocabulary correct) {
    final allMeanings = widget.vocabList
        .map((e) => (e.meaning).trim())
        .where((m) => m.isNotEmpty)
        .toSet()
        .toList();

    // Nếu bộ quá ít dữ liệu, trả về tối thiểu 1 lựa chọn
    if (allMeanings.isEmpty) return [correct.meaning];

    // Tạo danh sách đáp án sai (unique)
    final distractors = allMeanings
        .where((m) => m != correct.meaning)
        .toList()
      ..shuffle();

    // Số lựa chọn tối đa: 4, nhưng không vượt quá số meaning unique hiện có
    final targetCount = allMeanings.length >= 4 ? 4 : allMeanings.length;

    final result = <String>[correct.meaning];

    // thêm đáp án sai cho đủ targetCount
    result.addAll(distractors.take((targetCount - 1).clamp(0, distractors.length)));

    result.shuffle();
    return result;
  }

  String generateComment(bool isCorrect) {
    final random = Random();
    final correctComments = [
      "Tốt lắm! Bạn đang tiến bộ rất nhanh!",
      "Xuất sắc! Tiếp tục duy trì nhé!",
      "Trả lời đúng rồi, tuyệt vời!",
      "Giỏi quá! Bạn nhớ từ vựng rất tốt!"
    ];

    final wrongComments = [
      "Không sao, tiếp tục cố gắng nhé!",
      "Sai rồi… nhưng bạn sẽ nhớ lâu hơn!",
      "Đừng bỏ cuộc! Cố thêm chút nữa!",
      "Sai một chút nhưng không vấn đề gì!"
    ];

    return isCorrect
        ? correctComments[random.nextInt(correctComments.length)]
        : wrongComments[random.nextInt(wrongComments.length)];
  }
  final List<String> needReviewLines = [];

  Future<void> checkAnswer(String answer) async {

    final correct = widget.vocabList[currentIndex];
    final isCorrect = answer == correct.meaning;
    if (!isCorrect) {
      final line = '${correct.word} (${correct.romaji}) — Đáp án: ${correct.meaning}';
      if (!_reviewLines.contains(line)) _reviewLines.add(line);
    }


    setState(() {
      selectedAnswer = answer;
      showResult = true;
      feedback = isCorrect ? "Đúng" : "Sai";
      if (isCorrect) score++;
    });

    Future.delayed(const Duration(milliseconds: 1800), () async{
      if (currentIndex < widget.vocabList.length - 1) {
        setState(() {
          currentIndex++;
          selectedAnswer = null;
          showResult = false;
          feedback = "";
          options = getOptions(widget.vocabList[currentIndex]);
        });
      } else {
          await _saveQuizSessionHistory();
          if (!mounted) return;
          final uid = FirebaseAuth.instance.currentUser?.uid;
          if (uid != null && widget.setId != null && widget.setId!.trim().isNotEmpty) {
            final total = widget.vocabList.length;
            final correctCount = score;
            final wrongCount = total - score;

            try {
              await SetReviewHistoryStore.instance.addEntry(
                setId: widget.setId!,
                isPersonal: widget.isPersonal,
                entry: SetReviewHistoryEntry(
                  id: '',
                  createdAt: DateTime.now(),
                  mode: 'quiz',
                  total: total,
                  correct: correctCount,
                  wrong: wrongCount,
                ),
              );
            } catch (_) {}
          }
 
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (_) => QuizResultPage(
                setTitle: widget.setTitle ?? "Flashcard Quiz",
                score: score,
                total: widget.vocabList.length,
                needReviewLines: _reviewLines,
                retryBuilder: (ctx) => FlashcardQuizPage(
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
  

  Color getOptionColor(String option, String correct) {
    if (selectedAnswer == null) return Colors.white;

    if (option == selectedAnswer) {
      if (!showResult) return Colors.blue.shade100;

      return option == correct
          ? Colors.green.shade300
          : Colors.red.shade300;
    }

    if (showResult && option == correct) return Colors.green.shade300;

    return Colors.white;
  }

  // mới
  Future<void> _saveQuizSessionHistory() async {
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
          mode: 'quiz',
          total: total,
          correct: correct,
          wrong: wrong,
        ),
      );
    } catch (_) {}
  }


  @override
  Widget build(BuildContext context) {
    final vocab = widget.vocabList[currentIndex];

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.blue,
        title: const Text("Flashcard Quiz"),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Progress bar
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

            // Card từ vựng
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.blue.shade200.withOpacity(0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(
                    vocab.word,
                    style: const TextStyle(
                        fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    vocab.romaji,
                    style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Options
            Expanded(
              child: ListView.builder(
                itemCount: options.length,
                itemBuilder: (context, index) {
                  final opt = options[index];
                  final color = getOptionColor(opt, vocab.meaning);

                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade100.withOpacity(0.5),
                          blurRadius: 6,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: ListTile(
                      title: Text(
                        opt,
                        style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w500),
                      ),
                      onTap: selectedAnswer == null
                          ? () => checkAnswer(opt)
                          : null,
                    ),
                  );
                },
              ),
            ),

            // Feedback mới: hiện hình + bình luận tự động
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 300),
              child: showResult
                  ? Column(
                      key: ValueKey(feedback),
                      children: [
                        Image.asset(
                          feedback == "Đúng"
                              ? "lib/image/dung.png"
                              : "lib/image/sai.png",
                          width: 250,
                        ),
                        const SizedBox(height: 10),
                        Text(
                          generateComment(feedback == "Đúng"),
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 17,
                            fontWeight: FontWeight.w500,
                            color: feedback == "Đúng"
                                ? Colors.green
                                : Colors.red,
                          ),
                        ),
                      ],
                    )
                  : const SizedBox.shrink(),
            ),
          ],
        ),
      ),
    );
  }
}
