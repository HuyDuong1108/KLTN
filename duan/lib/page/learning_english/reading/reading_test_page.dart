import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'reading_result_page.dart';
import 'package:flutter/foundation.dart';

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
  static const Color bgColor = Color(0xFFF6FAFF);
  static const Color textGrey = Color(0xFF455A64);

  // ================= STATE =================

  final Map<int, List<TextMark>> passageMarks = {};
  int? currentPassageIndex;
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
_readingPassage(passage['content'], index),                  const SizedBox(height: 24),
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

  @override
void dispose() {
  _focusNode.dispose();
  for (var controller in sentenceControllers.values) {
    controller.dispose();
  }
  super.dispose();
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
        Future.delayed(const Duration(milliseconds: 100), () {
          if (currentSelection != null &&
              currentSelection!.start != currentSelection!.end &&
              !isMenuOpen) {
            setState(() {
              isMenuOpen = true;
              currentPassageIndex = passageIndex; // Lưu passage hiện tại
            });
            _showHighlightMenu();
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
// ================= BUILD HIGHLIGHTED TEXT =================
TextSpan _buildHighlightedText(String text, int passageIndex) {
  // Kiểm tra an toàn
  if (passageMarks[passageIndex] == null || passageMarks[passageIndex]!.isEmpty) {
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
      spans.add(TextSpan(
        text: text.substring(currentIndex, mark.start),
      ));
    }

    // Text được highlight
    spans.add(TextSpan(
      text: text.substring(mark.start, mark.end),
      style: TextStyle(backgroundColor: mark.color),
    ));

    currentIndex = mark.end;
  }

  // Text còn lại sau highlight cuối
  if (currentIndex < text.length) {
    spans.add(TextSpan(
      text: text.substring(currentIndex),
    ));
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

  // ================= HIGHLIGHT MENU =================
void _showHighlightMenu() {
  showModalBottomSheet(
    context: context,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => Container(
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            "Choose Highlight Color",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _colorButton(highlightYellow),
              _colorButton(highlightBlue),
              _colorButton(highlightGreen),
            ],
          ),
        ],
      ),
    ),
  ).whenComplete(() => isMenuOpen = false);
}
  Widget _colorButton(Color color) {
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
        
        Navigator.pop(context);
        
        // Sau khi đóng bottom sheet, mới setState
        Future.delayed(const Duration(milliseconds: 100), () {
          if (mounted) {
            setState(() {
              currentSelection = null;
            });
          }
        });
      } else {
        Navigator.pop(context);
      }
    },
    child: Container(
      margin: const EdgeInsets.all(8),
      child: CircleAvatar(
        backgroundColor: color,
        radius: 30,
      ),
    ),
  );
}
  // ================= SUBMIT =================
  Widget _bottomSubmitBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const ReadingResultPage()),
          );
        },
        child: const Text(
          "Submit Reading Test",
          style: TextStyle(color: Colors.white),
        ),
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
