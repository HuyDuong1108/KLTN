import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'level.dart'; // file LevelSelectionPage

class JapaneseTestPage extends StatefulWidget {
  const JapaneseTestPage({super.key});

  @override
  State<JapaneseTestPage> createState() => _JapaneseTestPageState();
}

class _JapaneseTestPageState extends State<JapaneseTestPage> {
  int score = 0;
  bool submitted = false;

  final questions = [
    {"question": "ひ phát âm là:", "options": ["hi", "ha", "fu", "he"], "answer": 0},
    {"question": "つ phát âm là:", "options": ["ta", "chi", "tsu", "sa"], "answer": 2},
    {"question": "Katakana 「ア」 đọc là:", "options": ["i", "u", "e", "a"], "answer": 3},
    {"question": "「ありがとう」 nghĩa là gì?", "options": ["Xin lỗi", "Cảm ơn", "Xin chào", "Tạm biệt"], "answer": 1},
    {"question": "「みず」 nghĩa là:", "options": ["Lửa", "Nước", "Núi", "Trời"], "answer": 1},
    {"question": "「せんせい」 là:", "options": ["Giáo viên", "Học sinh", "Bạn bè", "Bác sĩ"], "answer": 0},
    {"question": "Chọn câu đúng:", "options": ["わたしはがくせいです。", "がくせいですわたし。", "わたしがくせい。", "がくせいわたしです。"], "answer": 0},
    {"question": "Điền từ thích hợp: これは___ほんです。", "options": ["が", "は", "を", "に"], "answer": 1},
    {"question": "Đoạn: こんにちは。わたしのなまえは たろう です。にほんじんです。\n\nたろうさんは どこの ひとですか?", "options": ["にほん", "ちゅうごく", "ベトナム", "アメリカ"], "answer": 0},
    {"question": "Đoạn: こんにちは。わたしのなまえは たろう です。にほんじんです。\n\nたろうさんの なまえは?", "options": ["にほん", "たろう", "がくせい", "せんせい"], "answer": 1},
  ];

  Map<int, int> selectedAnswers = {};

  final List<Color> japaneseGradient = const [
    Color.fromARGB(255, 249, 160, 163),
    Color(0xFFfad0c4),
  ];

  /// Nộp bài kiểm tra
  void submit() {
    int tempScore = 0;
    for (int i = 0; i < questions.length; i++) {
      if (selectedAnswers[i] == questions[i]!["answer"]) {
        tempScore++;
      }
    }
    setState(() {
      score = tempScore;
      submitted = true;
    });
  }

  /// Xác định level theo điểm số
  int getLevelIndex(int score) {
    if (score <= 3) return 1; // Beginner
    if (score <= 6) return 2; // N5
    if (score <= 8) return 3; // N4
    return 4; // N3
  }

  /// Trả về text mô tả level
  String getLevelText(int score) {
    if (score <= 3) return "Beginner – Cần học lại từ đầu (dưới N5)";
    if (score <= 6) return "Elementary – Biết cơ bản (JLPT N5)";
    if (score <= 8) return "Pre-Intermediate – Nắm căn bản (JLPT N4)";
    return "Intermediate – Nền tảng vững (JLPT N3)";
  }

  /// Lưu trình độ vào Firestore
  Future<void> saveUnlockedLevel(int unlockedLevel) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection("users").doc(uid).set({
          "japanese_level": unlockedLevel,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("Lỗi khi lưu unlockedLevel: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    int answeredCount = selectedAnswers.length;
    double progress = answeredCount / questions.length;

    return Scaffold(
      backgroundColor: const Color(0xFFFDF6F6),
      appBar: AppBar(
        title: const Text("📝 Test Đầu Vào Tiếng Nhật"),
        centerTitle: true,
        backgroundColor: japaneseGradient[0],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Thanh progress
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: japaneseGradient),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: LinearProgressIndicator(
                      value: progress,
                      minHeight: 14,
                      backgroundColor: Colors.white.withOpacity(0.3),
                      valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text("Đã trả lời $answeredCount / ${questions.length} câu",
                      style: const TextStyle(color: Colors.white)),
                ],
              ),
            ),

            // Nội dung câu hỏi
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ...List.generate(questions.length, (index) {
                    var q = questions[index]!;
                    final options = q["options"] as List<String>;
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      margin: const EdgeInsets.only(bottom: 18),
                      elevation: 3,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text("Câu ${index + 1}: ${q["question"] as String}",
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600, fontSize: 16)),
                            const SizedBox(height: 12),
                            ...List.generate(options.length, (optIndex) {
                              final isSelected = selectedAnswers[index] == optIndex;
                              final isCorrect = submitted && optIndex == q["answer"];
                              final isWrong =
                                  submitted && isSelected && optIndex != q["answer"];
                              return Container(
                                margin: const EdgeInsets.symmetric(vertical: 4),
                                decoration: BoxDecoration(
                                  color: isCorrect
                                      ? Colors.green.withOpacity(0.15)
                                      : isWrong
                                          ? Colors.red.withOpacity(0.15)
                                          : Colors.grey.withOpacity(0.05),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: RadioListTile<int>(
                                  value: optIndex,
                                  groupValue: selectedAnswers[index],
                                  onChanged: submitted
                                      ? null
                                      : (val) {
                                          setState(() {
                                            selectedAnswers[index] = val!;
                                          });
                                        },
                                  activeColor: japaneseGradient[0],
                                  title: Text(
                                    options[optIndex],
                                    style: TextStyle(
                                      color: isCorrect
                                          ? Colors.green[800]
                                          : isWrong
                                              ? Colors.red[800]
                                              : Colors.black87,
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  }),

                  // Nút nộp bài
                  if (!submitted)
                    ElevatedButton(
                      onPressed: submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: japaneseGradient[0],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text("Nộp bài"),
                    ),

                  // Kết quả sau khi nộp
                  if (submitted) ...[
                    Card(
                      elevation: 6,
                      margin: const EdgeInsets.only(top: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: japaneseGradient,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Text("🎯 Điểm của bạn: $score / 10",
                                style: const TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white)),
                            const SizedBox(height: 8),
                            Text("📊 Trình độ: ${getLevelText(score)}",
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    fontSize: 16, color: Colors.white)),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () async {
                        int unlockedLevel = getLevelIndex(score);
                        await saveUnlockedLevel(unlockedLevel);

                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  LevelSelectionPage(unlockedLevel: unlockedLevel),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.school),
                      label: const Text("Bắt đầu học"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: japaneseGradient[0],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    OutlinedButton.icon(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.exit_to_app),
                      label: const Text("Thoát"),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: japaneseGradient[0],
                        side: BorderSide(color: japaneseGradient[0]),
                        padding: const EdgeInsets.symmetric(
                            vertical: 14, horizontal: 20),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
