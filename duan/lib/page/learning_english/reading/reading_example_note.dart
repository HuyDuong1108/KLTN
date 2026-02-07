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
  static const Color highlightPurple = Color(0xFFE1BEE7); // THÊM MÀU TÍM
static const Color highlightOrange = Color(0xFFFFE0B2);
  static const Color bgColor = Color(0xFFF6FAFF);
  static const Color textGrey = Color(0xFF455A64);

  // ================= STATE =================

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
      // XÓA GestureDetector onTapUp - không cần nữa
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
// ================= CHECK NOTE AT POSITION =================
void _checkNoteAtPosition(Offset localPosition, String text, int passageIndex) {
  final marks = passageMarks[passageIndex] ?? [];
  
  // Tính toán vị trí ký tự dựa trên localPosition (ước lượng đơn giản)
  // Font size 15, line height 1.6 => mỗi dòng ~24px
  const double charWidth = 8; // Trung bình
  const double lineHeight = 24;
  
  int estimatedLine = (localPosition.dy / lineHeight).floor();
  int estimatedChar = (localPosition.dx / charWidth).floor();
  int estimatedPosition = (estimatedLine * 50) + estimatedChar; // Ước lượng 50 char/line
  
  // Tìm note mark chứa vị trí này
  for (var mark in marks) {
    if (mark.type == MarkType.note && 
        mark.note != null &&
        estimatedPosition >= mark.start && 
        estimatedPosition <= mark.end) {
      // Hiển thị note tooltip tại vị trí global
      final RenderBox renderBox = context.findRenderObject() as RenderBox;
      final globalPosition = renderBox.localToGlobal(localPosition);
      _showNoteTooltip(mark.note!, globalPosition);
      break;
    }
  }
}
// ================= SHOW NOTE TOOLTIP =================
void _showNoteTooltip(String note, Offset position) {
  final overlay = Overlay.of(context);
  OverlayEntry? overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => GestureDetector(
      onTap: () => overlayEntry?.remove(),
      behavior: HitTestBehavior.translucent,
      child: Stack(
        children: [
          Positioned(
            left: position.dx - 125,
            top: position.dy + 20,
            child: Material(
              elevation: 12,
              borderRadius: BorderRadius.circular(16),
              color: Colors.transparent,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 280),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [primaryBlue, primaryBlue.withOpacity(0.8)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: primaryBlue.withOpacity(0.3),
                      blurRadius: 15,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Icon(Icons.lightbulb, size: 18, color: Colors.white),
                        SizedBox(width: 8),
                        Text(
                          "Your Note",
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      note,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        height: 1.4,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    ),
  );

  overlay.insert(overlayEntry);

  Future.delayed(const Duration(seconds: 5), () {
    overlayEntry?.remove();
  });
}

// ================= FLOATING HIGHLIGHT MENU =================
void _showFloatingHighlightMenu() {
  if (selectionPosition == null) return;

  final overlay = Overlay.of(context);
  OverlayEntry? overlayEntry;

  overlayEntry = OverlayEntry(
    builder: (context) => Positioned(
      left: selectionPosition!.dx - 200,
      top: selectionPosition!.dy - 80,
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
              // Các nút màu highlight
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
              Container(
                height: 30,
                width: 1,
                color: Colors.grey.shade300,
              ),
              
              const SizedBox(width: 8),
              
              // NÚT NOTE - MỚI THÊM
              _noteButton(overlayEntry),
              
              const SizedBox(width: 8),
              
              // Divider dọc
              Container(
                height: 30,
                width: 1,
                color: Colors.grey.shade300,
              ),
              
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

// ================= NOTE BUTTON =================
Widget _noteButton(OverlayEntry? overlayEntry) {
  return GestureDetector(
    onTap: () {
      overlayEntry?.remove();
      setState(() {
        isMenuOpen = false;
      });
      _showNoteDialog();
    },
    child: Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.amber.shade200,
          width: 2,
        ),
      ),
      child: Icon(
        Icons.sticky_note_2,
        size: 18,
        color: Colors.amber.shade700,
      ),
    ),
  );
}

// ================= SHOW NOTE DIALOG =================
void _showNoteDialog() {
  final TextEditingController noteController = TextEditingController();

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      elevation: 0,
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.1),
              blurRadius: 20,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Icon & Title
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.edit_note_rounded,
                size: 40,
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              "Add Your Note",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Jot down your thoughts about this passage",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            
            // TextField
            Container(
              decoration: BoxDecoration(
                color: bgColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: primaryBlue.withOpacity(0.2),
                  width: 2,
                ),
              ),
              child: TextField(
                controller: noteController,
                maxLines: 5,
                autofocus: true,
                style: const TextStyle(fontSize: 15, height: 1.5),
                decoration: InputDecoration(
                  hintText: "Type your note here...",
                  hintStyle: TextStyle(color: Colors.grey.shade400),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.all(16),
                ),
              ),
            ),
            const SizedBox(height: 24),
            
            // Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      side: BorderSide(color: Colors.grey.shade300, width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      if (noteController.text.isNotEmpty &&
                          currentSelection != null &&
                          currentPassageIndex != null) {
                        if (!passageMarks.containsKey(currentPassageIndex)) {
                          passageMarks[currentPassageIndex!] = [];
                        }

                        passageMarks[currentPassageIndex!]!.add(
                          TextMark(
                            start: currentSelection!.start,
                            end: currentSelection!.end,
                            note: noteController.text,
                            type: MarkType.note,
                          ),
                        );

                        setState(() {
                          currentSelection = null;
                        });

                        Navigator.pop(context);
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryBlue,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: const Text(
                      "Save Note",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    ),
  );
}

// ================= FLOATING COLOR BUTTON =================
Widget _floatingColorButton(Color color, OverlayEntry? overlayEntry) {
  return GestureDetector(
    onTap: () {
      if (currentSelection != null && currentPassageIndex != null) {
        if (!passageMarks.containsKey(currentPassageIndex)) {
          passageMarks[currentPassageIndex!] = [];
        }
        
        passageMarks[currentPassageIndex!]!.add(
          TextMark(
            start: currentSelection!.start,
            end: currentSelection!.end,
            color: color,
            type: MarkType.highlight, // THÊM TYPE
          ),
        );
        
        overlayEntry?.remove();
        
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
        border: Border.all(
          color: Colors.grey.shade300,
          width: 2,
        ),
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
  if (passageMarks[passageIndex] == null ||
      passageMarks[passageIndex]!.isEmpty) {
    return TextSpan(text: text);
  }

  final marks = passageMarks[passageIndex]!;
  final sortedMarks = List<TextMark>.from(marks)
    ..sort((a, b) => a.start.compareTo(b.start));

  List<InlineSpan> spans = []; // ĐỔI từ TextSpan sang InlineSpan
  int currentIndex = 0;

  for (var mark in sortedMarks) {
    if (mark.start < 0 || mark.end > text.length || mark.start >= mark.end) {
      continue;
    }

    // Text trước mark
    if (currentIndex < mark.start) {
      spans.add(TextSpan(text: text.substring(currentIndex, mark.start)));
    }

    // Text được mark
    if (mark.type == MarkType.highlight) {
      // Style cho highlight
      spans.add(
        TextSpan(
          text: text.substring(mark.start, mark.end),
          style: TextStyle(backgroundColor: mark.color),
        ),
      );
    } else if (mark.type == MarkType.note) {
      // NOTE - WRAP VỚI WIDGETSPAN ĐỂ BẮT TAP
      spans.add(
        WidgetSpan(
          child: GestureDetector(
            onTap: () {
              // Lấy vị trí global để hiện tooltip
              final RenderBox? box = context.findRenderObject() as RenderBox?;
              if (box != null) {
                final position = box.localToGlobal(Offset.zero);
                _showNoteTooltip(
                  mark.note!,
                  Offset(position.dx + 100, position.dy + 100),
                );
              }
            },
            child: Container(
              decoration: BoxDecoration(
                color: Colors.amber.shade50.withOpacity(0.3),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.amber.shade600,
                    width: 2,
                    style: BorderStyle.solid,
                  ),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    text.substring(mark.start, mark.end),
                    style: TextStyle(
                      fontStyle: FontStyle.italic,
                      color: textGrey,
                      fontSize: 15,
                      height: 1.6,
                    ),
                  ),
                  const SizedBox(width: 2),
                  const Text(
                    "📝",
                    style: TextStyle(fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    currentIndex = mark.end;
  }

  // Text còn lại
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

class TextMark {
  final int start;
  final int end;
  Color? color;  // Đổi thành nullable
  String? note;
  final MarkType type; // note hoặc highlight

  TextMark({
    required this.start,
    required this.end,
    this.color,
    this.note,
    required this.type,
  });
}

enum MarkType {
  highlight,
  note,
}
