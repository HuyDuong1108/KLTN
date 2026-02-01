import 'package:duan/page/learning/korean/level_korean.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// import 'level_korean.dart'; // LevelSelectionPage

class KoreanTestPage extends StatefulWidget {
  const KoreanTestPage({super.key});

  @override
  State<KoreanTestPage> createState() => _KoreanTestPageState();
}

class _KoreanTestPageState extends State<KoreanTestPage> {
  int score = 0;
  bool submitted = false;

  final questions = [
    {
      "question": "ㅎ phát âm là:",
      "options": ["h", "k", "t", "p"],
      "answer": 0
    },
    {
      "question": "ㄱ phát âm gần đúng là:",
      "options": ["g/k", "n", "m", "s"],
      "answer": 0
    },
    {
      "question": "안녕하세요 nghĩa là:",
      "options": ["Xin chào", "Cảm ơn", "Xin lỗi", "Tạm biệt"],
      "answer": 0
    },
    {
      "question": "감사합니다 nghĩa là:",
      "options": ["Xin lỗi", "Cảm ơn", "Không sao", "Xin chào"],
      "answer": 1
    },
    {
      "question": "학생 nghĩa là:",
      "options": ["Giáo viên", "Học sinh", "Bác sĩ", "Bạn bè"],
      "answer": 1
    },
    {
      "question": "선생님 là:",
      "options": ["Học sinh", "Giáo viên", "Nhân viên", "Bác sĩ"],
      "answer": 1
    },
    {
      "question": "Câu nào đúng ngữ pháp?",
      "options": [
        "저는 학생입니다.",
        "저는 입니다 학생.",
        "학생 저는 입니다.",
        "입니다 저는 학생."
      ],
      "answer": 0
    },
    {
      "question": "Điền từ thích hợp: 저는 밥___ 먹어요.",
      "options": ["을", "이", "가", "에"],
      "answer": 0
    },
    {
      "question":
          "Đoạn: 안녕하세요. 저는 민수입니다. 한국 사람입니다.\n\n민수 씨는 어디 사람입니까?",
      "options": ["한국", "중국", "베트남", "미국"],
      "answer": 0
    },
    {
      "question":
          "Đoạn: 안녕하세요. 저는 민수입니다. 한국 사람입니다.\n\n이름은 무엇입니까?",
      "options": ["민수", "학생", "선생님", "한국"],
      "answer": 0
    },
  ];

  Map<int, int> selectedAnswers = {};

  final List<Color> koreanGradient = const [
    Color.fromARGB(255, 185, 163, 238),
    Color(0xFFfbc2eb),
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
    if (score <= 6) return 2; // Topik 1
    if (score <= 8) return 3; // Topik 2
    return 4; // Intermediate
  }

  String getLevelText(int score) {
    if (score <= 3) return "Beginner – Chưa có nền tảng";
    if (score <= 6) return "Elementary – TOPIK 1";
    if (score <= 8) return "Pre-Intermediate – TOPIK 2";
    return "Intermediate – Giao tiếp tốt";
  }

  /// Lưu level vào Firestore
  Future<void> saveUnlockedLevel(int unlockedLevel) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    await FirebaseFirestore.instance.collection("users").doc(uid).set({
      "korean_level": unlockedLevel,
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    int answeredCount = selectedAnswers.length;
    double progress = answeredCount / questions.length;

    return Scaffold(
      backgroundColor: const Color(0xFFF7F6FD),
      appBar: AppBar(
        title: const Text("📝 Test Đầu Vào Tiếng Hàn"),
        centerTitle: true,
        backgroundColor: koreanGradient[0],
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          /// Progress
          Container(
            margin: const EdgeInsets.all(16),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: koreanGradient),
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
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),

          /// Questions
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
                                fontWeight: FontWeight.w600, fontSize: 16),
                          ),
                          const SizedBox(height: 12),
                          ...List.generate(options.length, (i) {
                            final isSelected =
                                selectedAnswers[index] == i;
                            final isCorrect =
                                submitted && i == q["answer"];
                            final isWrong =
                                submitted && isSelected && i != q["answer"];

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
                                value: i,
                                groupValue: selectedAnswers[index],
                                onChanged: submitted
                                    ? null
                                    : (val) {
                                        setState(() {
                                          selectedAnswers[index] = val!;
                                        });
                                      },
                                activeColor: koreanGradient[0],
                                title: Text(options[i]),
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
                      backgroundColor: koreanGradient[0],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text("Nộp bài"),
                  ),

                if (submitted) ...[
                  const SizedBox(height: 20),
                  Card(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient:
                            LinearGradient(colors: koreanGradient),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          Text(
                            "🎯 Điểm: $score / 10",
                            style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Colors.white),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            getLevelText(score),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                                fontSize: 16, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton.icon(
                    onPressed: () async {
                      final level = getLevelIndex(score);
                      await saveUnlockedLevel(level);

                      if (context.mounted) {
                        Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) =>
                                KoreanLevelSelectionPage(unlockedLevel: level),
                          ),
                        );
                      }
                    },
                    icon: const Icon(Icons.school),
                    label: const Text("Bắt đầu học"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: koreanGradient[0],
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          vertical: 14, horizontal: 20),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}
