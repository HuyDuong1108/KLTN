import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'reading_result_page.dart';

class ReadingTestPage extends StatefulWidget {
  const ReadingTestPage({super.key});

  @override
  State<ReadingTestPage> createState() => _ReadingTestPageState();
}

class _ReadingTestPageState extends State<ReadingTestPage> {
  // ================= COLORS =================
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color highlightYellow = Color(0xFFFFF59D);
  static const Color highlightBlue = Color(0xFFB3E5FC);
  static const Color highlightGreen = Color(0xFFC8E6C9);
  static const Color notePurple = Color(0xFFBA68C8);
  static const Color bgColor = Color(0xFFF6FAFF);
  static const Color textGrey = Color(0xFF455A64);

  // ================= PASSAGE =================
  final String passageText =
      "The history of urban transportation reflects the rapid development of cities "
      "and the evolving needs of their populations. "
      "Early forms of transport relied heavily on animal power, particularly horses. "
      "These methods were effective for small communities but became increasingly inefficient "
      "as cities expanded. "
      "The introduction of mechanised transport systems in the 19th century marked a turning point. "
      "Steam-powered trams and railways enabled people to travel greater distances in less time, "
      "reshaping urban landscapes and influencing where people lived and worked.\n\n"
      "In the modern era, public transportation systems face new challenges, including environmental "
      "concerns and population growth. Cities around the world are now investing in sustainable "
      "solutions such as electric buses, underground rail networks, and cycling infrastructure "
      "to reduce congestion and pollution while maintaining accessibility.";

  // ================= STATE =================
  final List<TextMark> marks = [];
  TextSelection? currentSelection;
  bool isMenuOpen = false;

  // ================= ANSWERS =================
  String? mcq1;
  String? mcq4;
  String? tf2;
  String? tf3;
  final TextEditingController sentence5Controller = TextEditingController();

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
          "IELTS Reading Test 1",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Center(
              child: Text(
                "59:00",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.redAccent,
                ),
              ),
            ),
          ),
        ],
      ),

      // ================= BODY =================
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _passageHeader(),
          _readingPassage(),
          const SizedBox(height: 32),
          _questionSection(),
          const SizedBox(height: 80),
        ],
      ),

      // ================= SUBMIT =================
      bottomNavigationBar: _bottomSubmitBar(),
    );
  }

  // ================= HEADER =================
  Widget _passageHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Reading Passage 1",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          SizedBox(height: 6),
          Text("Questions 1–5", style: TextStyle(color: textGrey)),
        ],
      ),
    );
  }

  // ================= PASSAGE =================
  Widget _readingPassage() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: SelectableText.rich(
        TextSpan(
          style: const TextStyle(fontSize: 15, height: 1.6, color: textGrey),
          children: _buildTextSpans(),
        ),
        onSelectionChanged: (selection, cause) {
          if (selection.start == selection.end) return;

          currentSelection = selection;

          if ((cause == SelectionChangedCause.longPress ||
                  cause == SelectionChangedCause.drag) &&
              !isMenuOpen) {
            isMenuOpen = true;
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) _showHighlightMenu();
            });
          }
        },
      ),
    );
  }

  List<TextSpan> _buildTextSpans() {
    final spans = <TextSpan>[];
    int index = 0;
    final sorted = [...marks]..sort((a, b) => a.start.compareTo(b.start));

    for (final mark in sorted) {
      if (mark.start > index) {
        spans.add(TextSpan(text: passageText.substring(index, mark.start)));
      }

      spans.add(
        TextSpan(
          text: passageText.substring(mark.start, mark.end),
          style: TextStyle(
            backgroundColor: mark.color,
            color: textGrey,
            fontStyle: mark.note != null ? FontStyle.italic : FontStyle.normal,
          ),
          recognizer: TapGestureRecognizer()
            ..onTap = () {
              if (mark.note != null) _editNote(mark);
            },
        ),
      );
      index = mark.end;
    }

    if (index < passageText.length) {
      spans.add(TextSpan(text: passageText.substring(index)));
    }

    return spans;
  }

  // ================= QUESTIONS =================
  Widget _questionSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Questions",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),

        // ===== Q1 MCQ =====
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "1. What is the main focus of the passage?",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              RadioListTile(
                title: const Text("A. Rural transportation"),
                value: "A",
                groupValue: mcq1,
                onChanged: (v) => setState(() => mcq1 = v),
              ),
              RadioListTile(
                title: const Text("B. Evolution of urban transport"),
                value: "B",
                groupValue: mcq1,
                onChanged: (v) => setState(() => mcq1 = v),
              ),
              RadioListTile(
                title: const Text("C. Environmental issues"),
                value: "C",
                groupValue: mcq1,
                onChanged: (v) => setState(() => mcq1 = v),
              ),
            ],
          ),
        ),

        // ===== Q2 TFNG =====
        _tfngCard(
          2,
          "Horses were effective only in small communities.",
          tf2,
          (v) => setState(() => tf2 = v),
        ),

        // ===== Q3 TFNG =====
        _tfngCard(
          3,
          "Steam-powered transport reduced travel time.",
          tf3,
          (v) => setState(() => tf3 = v),
        ),

        // ===== Q4 MCQ =====
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "4. Which solution is NOT mentioned?",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              RadioListTile(
                title: const Text("A. Electric buses"),
                value: "A",
                groupValue: mcq4,
                onChanged: (v) => setState(() => mcq4 = v),
              ),
              RadioListTile(
                title: const Text("B. Underground rail"),
                value: "B",
                groupValue: mcq4,
                onChanged: (v) => setState(() => mcq4 = v),
              ),
              RadioListTile(
                title: const Text("C. Autonomous cars"),
                value: "C",
                groupValue: mcq4,
                onChanged: (v) => setState(() => mcq4 = v),
              ),
            ],
          ),
        ),

        // ===== Q5 SENTENCE =====
        _card(
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "5. Cities invest in transport to reduce ________ and pollution.",
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: sentence5Controller,
                decoration: const InputDecoration(
                  hintText: "NO MORE THAN TWO WORDS",
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _tfngCard(
    int number,
    String question,
    String? value,
    Function(String) onChanged,
  ) {
    return _card(
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$number. $question",
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          RadioListTile(
            title: const Text("TRUE"),
            value: "TRUE",
            groupValue: value,
            onChanged: (v) => onChanged(v!),
          ),
          RadioListTile(
            title: const Text("FALSE"),
            value: "FALSE",
            groupValue: value,
            onChanged: (v) => onChanged(v!),
          ),
          RadioListTile(
            title: const Text("NOT GIVEN"),
            value: "NOT GIVEN",
            groupValue: value,
            onChanged: (v) => onChanged(v!),
          ),
        ],
      ),
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
      builder: (_) => Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _colorButton(highlightYellow),
          _colorButton(highlightBlue),
          _colorButton(highlightGreen),
          IconButton(
            icon: const Icon(Icons.note_add, color: notePurple),
            onPressed: () {
              Navigator.pop(context);
              _addNote();
            },
          ),
        ],
      ),
    ).whenComplete(() => isMenuOpen = false);
  }

  Widget _colorButton(Color color) {
    return GestureDetector(
      onTap: () {
        setState(() {
          _mergeAndAddMark(
            TextMark(
              start: currentSelection!.start,
              end: currentSelection!.end,
              color: color,
            ),
          );

          currentSelection = null;
        });

        Navigator.pop(context);

        FocusScope.of(context).unfocus();
      },
      child: CircleAvatar(backgroundColor: color),
    );
  }

  void _addNote() {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Add Note"),
        content: TextField(controller: controller, maxLines: 3),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                _mergeAndAddMark(
                  TextMark(
                    start: currentSelection!.start,
                    end: currentSelection!.end,
                    color: highlightYellow,
                    note: controller.text,
                  ),
                );
                currentSelection = null;
              });
              FocusScope.of(context).unfocus();
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _editNote(TextMark mark) {
    final controller = TextEditingController(text: mark.note);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Edit Note"),
        content: TextField(controller: controller, maxLines: 3),
        actions: [
          TextButton(
            onPressed: () {
              setState(() => mark.note = controller.text);
              Navigator.pop(context);
            },
            child: const Text("Save"),
          ),
        ],
      ),
    );
  }

  void _mergeAndAddMark(TextMark newMark) {
    marks.removeWhere(
      (m) => !(newMark.end <= m.start || newMark.start >= m.end),
    );
    marks.add(newMark);
  }

  // ================= SUBMIT =================
  Widget _bottomSubmitBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            marks.clear();
            mcq1 = null;
            mcq4 = null;
            tf2 = null;
            tf3 = null;
            sentence5Controller.clear();
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => const ReadingResultPage(),
              ),
            );
          });
        },
        style: ElevatedButton.styleFrom(backgroundColor: primaryBlue),
        child: const Text("Submit Reading Test", style: TextStyle(color: Colors.white),),
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
