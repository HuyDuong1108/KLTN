import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import 'chinese_level.dart'; // LevelSelectionPageZh

class ChineseTestPage extends StatefulWidget {
  const ChineseTestPage({super.key});

  @override
  State<ChineseTestPage> createState() => _ChineseTestPageState();
}

class _ChineseTestPageState extends State<ChineseTestPage> {
  int score = 0;
  bool submitted = false;

  final questions = [
    {
      "question": "拼音 “xǐ huān” nghĩa là:",
      "options": ["Ghét", "Thích", "Ăn", "Uống"],
      "answer": 1
    },
    {
      "question": "你 好 đọc là:",
      "options": ["nǐ hǎo", "ní hǎo", "nǐ hào", "nì hǎo"],
      "answer": 0
    },
    {
      "question": "汉字 “三” là số mấy?",
      "options": ["1", "2", "3", "4"],
      "answer": 2
    },
    {
      "question": "我叫安。 nghĩa là:",
      "options": [
        "Tôi khỏe",
        "Tên tôi là An",
        "Tôi là giáo viên",
        "Xin chào"
      ],
      "answer": 1
    },
    {
      "question": "妈妈 là:",
      "options": ["Bố", "Mẹ", "Anh trai", "Chị gái"],
      "answer": 1
    },
    {
      "question": "吃 nghĩa là:",
      "options": ["Uống", "Đi", "Ăn", "Ngủ"],
      "answer": 2
    },
    {
      "question": "Câu nào đúng?",
      "options": [
        "我 是 学生。",
        "我是 学生。",
        "我 学生 是。",
        "学生 我 是。"
      ],
      "answer": 1
    },
    {
      "question": "Điền từ đúng: 我 ___ 老师。",
      "options": ["是", "不", "有", "在"],
      "answer": 0
    },
    {
      "question":
          "Đoạn: 你好。我叫安。我是中国人。\n\n安是哪国人？",
      "options": ["中国", "日本", "韩国", "越南"],
      "answer": 0
    },
    {
      "question":
          "Đoạn: 你好。我叫安。我是学生。\n\n安是什么？",
      "options": ["老师", "学生", "医生", "工人"],
      "answer": 1
    },
  ];

  Map<int, int> selectedAnswers = {};

  /// 🎨 Gradient màu giống Chinese trong LearningPage
  final List<Color> chineseGradient = const [
    Color.fromARGB(255, 172, 243, 198),
    Color.fromARGB(255, 161, 215, 241),
  ];

  /// Nộp bài
  void submit() {
    int tempScore = 0;
    for (int i = 0; i < questions.length; i++) {
      if (selectedAnswers[i] == questions[i]["answer"]) {
        tempScore++;
      }
    }
    setState(() {
      score = tempScore;
      submitted = true;
    });
  }

  /// Xác định level
  int getLevelIndex(int score) {
    if (score <= 3) return 1; // Beginner
    if (score <= 6) return 2; // HSK 1
    if (score <= 8) return 3; // HSK 2
    return 4; // HSK 3
  }

  String getLevelText(int score) {
    if (score <= 3) return "Beginner – Cần học lại từ đầu";
    if (score <= 6) return "Elementary – HSK 1";
    if (score <= 8) return "Pre-Intermediate – HSK 2";
    return "Intermediate – HSK 3";
  }

  /// Lưu level tiếng Trung
  Future<void> saveUnlockedLevel(int unlockedLevel) async {
    try {
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        await FirebaseFirestore.instance.collection("users").doc(uid).set({
          "chinese_level": unlockedLevel,
        }, SetOptions(merge: true));
      }
    } catch (e) {
      debugPrint("Lỗi lưu chinese_level: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    int answeredCount = selectedAnswers.length;
    double progress = answeredCount / questions.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7FDFB),
      appBar: AppBar(
        title: const Text("📝 Test Đầu Vào Tiếng Trung"),
        centerTitle: true,
        backgroundColor: chineseGradient[0],
        foregroundColor: Colors.black,
        elevation: 0,
      ),
      body: SafeArea(
        child: Column(
          children: [
            // ===== Progress =====
            Container(
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: chineseGradient),
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
                      valueColor:
                          const AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "Đã trả lời $answeredCount / ${questions.length} câu",
                    style: const TextStyle(color: Colors.black),
                  ),
                ],
              ),
            ),

            // ===== Questions =====
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  ...List.generate(questions.length, (index) {
                    final q = questions[index];
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
                            Text(
                              "Câu ${index + 1}: ${q["question"]}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ...List.generate(options.length, (optIndex) {
                              final isSelected =
                                  selectedAnswers[index] == optIndex;
                              final isCorrect =
                                  submitted && optIndex == q["answer"];
                              final isWrong = submitted &&
                                  isSelected &&
                                  optIndex != q["answer"];

                              return Container(
                                margin:
                                    const EdgeInsets.symmetric(vertical: 4),
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
                                  activeColor: chineseGradient[0],
                                  title: Text(options[optIndex]),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    );
                  }),

                  if (!submitted)
                    ElevatedButton(
                      onPressed: submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: chineseGradient[0],
                        foregroundColor: Colors.black,
                        padding:
                            const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text("Nộp bài"),
                    ),

                  if (submitted) ...[
                    const SizedBox(height: 20),
                    Card(
                      elevation: 6,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          gradient:
                              LinearGradient(colors: chineseGradient),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Text(
                              "🎯 Điểm của bạn: $score / 10",
                              style: const TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              "📊 Trình độ: ${getLevelText(score)}",
                              textAlign: TextAlign.center,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    ElevatedButton.icon(
                      onPressed: () async {
                        final unlockedLevel = getLevelIndex(score);
                        await saveUnlockedLevel(unlockedLevel);

                        if (context.mounted) {
                          Navigator.pushReplacement(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  LevelSelectionPageZh(
                                unlockedLevel: unlockedLevel,
                              ),
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.school),
                      label: const Text("Bắt đầu học"),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: chineseGradient[0],
                        foregroundColor: Colors.black,
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
