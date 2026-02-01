import 'package:flutter/material.dart';
import '../../models/flashcard_set.dart';
import '../../models/vocabulary.dart';
import 'flashcard_study_page.dart';
import 'flashcard_quiz_page.dart';
import 'flashcard_typing_page.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert'; // jsonDecode
import 'package:http/http.dart' as http; // http.get
import 'package:flutter_dotenv/flutter_dotenv.dart'; // dotenv
import 'package:flutter_markdown/flutter_markdown.dart';
// import '../../data/set_review_history_store.dart';

final FlutterTts _flutterTts = FlutterTts();

class FlashcardSetDetailPage extends StatefulWidget {
  final FlashcardSet set;
  final bool isPersonal;
  final String? highlightWord;

  const FlashcardSetDetailPage({
    super.key,
    required this.set,
    this.isPersonal = false,
    this.highlightWord,
  });

  @override
  State<FlashcardSetDetailPage> createState() => _FlashcardSetDetailPageState();
}

class _FlashcardSetDetailPageState extends State<FlashcardSetDetailPage> {
  late List<Vocabulary> vocabList;
  String? _highlightWord;
  bool _didScrollToHighlight = false;
  final List<GlobalKey> _vocabKeys = [];

  @override
  void initState() {
    super.initState();

     _highlightWord = widget.highlightWord;

    _highlightWord = widget.highlightWord;
  }

  void _syncVocabKeys(int n) {
    if (_vocabKeys.length == n) return;
    _vocabKeys
      ..clear()
      ..addAll(List.generate(n, (_) => GlobalKey()));
  }

  bool _isHighlight(String word) {
    final a = word.trim();
    final b = (_highlightWord ?? '').trim();
    return a.isNotEmpty && b.isNotEmpty && a == b;
  }
 void _clearHighlight() {
    if (_highlightWord == null) return;
    setState(() => _highlightWord = null);
  }
  void _clearHighlightIfAnyInteraction() {
    if ((_highlightWord ?? '').trim().isEmpty) return;
    _clearHighlight();
  }

  void _scrollToHighlightIfNeeded(List<Vocabulary> list) {
    if (_didScrollToHighlight) return;

    final hw = (_highlightWord ?? '').trim();
    if (hw.isEmpty) return;

    final idx = list.indexWhere((v) => v.word.trim() == hw);
    if (idx < 0) return;

    _didScrollToHighlight = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      if (idx >= _vocabKeys.length) return;

      final ctx = _vocabKeys[idx].currentContext;
      if (ctx == null) return;

      Scrollable.ensureVisible(
        ctx,
        duration: const Duration(milliseconds: 320),
        curve: Curves.easeOut,
        alignment: 0.25,
      );
    });
  }

  Future<void> _speak(String text) async {
    try {
      await _flutterTts.setLanguage("ja-JP");
      await _flutterTts.setSpeechRate(0.5);
      await _flutterTts.setVolume(1.0);
      await _flutterTts.stop();
      await _flutterTts.speak(text);
    } catch (_) {}
  }

  Future<String> translateToVietnamese({
    required String word,
    required String meaningEn,
    required String language, // "ja" | "ko" | "zh"
  }) async {
    final apiKey = dotenv.env['API_KEY'];
    final url =
        'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash-lite:generateContent?key=$apiKey';

    final prompt =
        '''
Bạn là từ điển học ngôn ngữ.

Từ: "$word"
Ngôn ngữ: $language
Nhiệm vụ:
- Trả về NGHĨA TIẾNG VIỆT ngắn gọn
- Nếu có meaning tiếng Anh thì dùng để suy luận: "$meaningEn"

Chỉ trả về TEXT, không markdown.
''';

    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt},
            ],
          },
        ],
      }),
    );

    final data = jsonDecode(res.body);
    return data['candidates'][0]['content']['parts'][0]['text'].trim();
  }

  Future<Map<String, String>> fetchPronunciationAndMeaning({
    required String word,
    required String language, // ja | zh | ko
  }) async {
    final apiKey = dotenv.env['API_KEY'];
    final url =
        'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash-lite:generateContent?key=$apiKey';

    final prompt =
        """
Bạn là từ điển học ngôn ngữ.

Từ: "$word"
Ngôn ngữ: $language

Yêu cầu:
- Trả về phát âm LATIN:
  + ja → romaji
  + zh → pinyin (có dấu)
  + ko → hangul latin
- Trả về nghĩa tiếng Việt NGẮN GỌN

CHỈ TRẢ VỀ JSON:

{
  "pronunciation": "...",
  "meaning_vi": "..."
}
CHỈ TRẢ VỀ JSON, MỖI FIELD PHẢI LÀ STRING
KHÔNG OBJECT, KHÔNG ARRAY

Ví dụ hợp lệ:
{
  "pronunciation": "taberu",
  "meaning_vi": "ăn"
}

""";

    final res = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        "contents": [
          {
            "parts": [
              {"text": prompt},
            ],
          },
        ],
      }),
    );

    final data = jsonDecode(res.body);
    final raw = data['candidates'][0]['content']['parts'][0]['text'];

    final jsonText = raw.substring(raw.indexOf('{'), raw.lastIndexOf('}') + 1);

    final decoded = jsonDecode(jsonText);

    String pronunciation = '';
    String meaningVi = '';

    if (decoded['pronunciation'] is String) {
      pronunciation = decoded['pronunciation'];
    } else if (decoded['pronunciation'] is Map) {
      pronunciation = decoded['pronunciation'].values.first.toString();
    }

    if (decoded['meaning_vi'] is String) {
      meaningVi = decoded['meaning_vi'];
    } else if (decoded['meaning_vi'] is Map) {
      meaningVi = decoded['meaning_vi'].values.first.toString();
    }

    return {"pronunciation": pronunciation, "meaning_vi": meaningVi};
  }

  Future<void> fetchPixabayImages({
    required String keyword,
    required void Function(void Function()) setModalState,
    required List<String> imageResults,
    required void Function(bool) setLoading,
  }) async {
    if (keyword.trim().isEmpty) return;

    setModalState(() {
      setLoading(true);
      imageResults.clear();
    });

    final apiKey = dotenv.env['PIXABAY_API_KEY'];
    final url =
        'https://pixabay.com/api/?key=$apiKey&q=$keyword&image_type=photo&per_page=12&safesearch=true';

    try {
      final res = await http.get(Uri.parse(url));
      final data = jsonDecode(res.body);

      if (data['hits'] != null) {
        setModalState(() {
          imageResults.addAll(
            List<String>.from(data['hits'].map((e) => e['webformatURL'])),
          );
        });
      }
    } catch (e) {
      debugPrint('Pixabay error: $e');
    } finally {
      setModalState(() => setLoading(false));
    }
  }


  void addVocabulary(Vocabulary vocab) {
    setState(() {
      vocabList.add(vocab);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser?.uid ?? "anonymous";

    final DocumentReference vocabRef = widget.isPersonal
        ? FirebaseFirestore.instance
              .collection('flashcards')
              .doc(userId)
              .collection('userFlashcards')
              .doc(widget.set.id)
        : FirebaseFirestore.instance
              .collection('flashcard_sets')
              .doc(widget.set.id);

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        backgroundColor: Colors.orange.shade400,
        title: Text(
          widget.set.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
        elevation: 0,
      ),
      floatingActionButton: widget.isPersonal
          ? FloatingActionButton(
              backgroundColor: Colors.orange,
              onPressed: () => showAddVocabularySheet(context, userId: userId),
              child: const Icon(Icons.add, color: Colors.white),
            )
          : null,

      /// 🔥 REALTIME FIRESTORE
      body: StreamBuilder<DocumentSnapshot>(
        stream: vocabRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || !snapshot.data!.exists) {
            return const Center(child: Text("Chưa có từ vựng"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;
          final raw = data['vocabList'];

          List vocabListRaw = [];

          if (raw is List) {
            vocabListRaw = raw;
          } else if (raw is Map) {
            // 🔧 cứu data cũ bị hỏng
            vocabListRaw = raw.values.toList();
          }

          final vocabList = vocabListRaw
              .map<Vocabulary>(
                (e) => Vocabulary.fromMap(Map<String, dynamic>.from(e)),
              )
              .toList();
          
          _syncVocabKeys(vocabList.length);
          _scrollToHighlightIfNeeded(vocabList);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                /// Mô tả bộ
                if (widget.set.description.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 5,
                          offset: const Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Text(
                      widget.set.description,
                      style: const TextStyle(
                        color: Colors.black87,
                        fontSize: 15,
                      ),
                    ),
                  ),

                const SizedBox(height: 20),

                /// Study modes
                const Text(
                  "Study Modes",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    _modeCard(
                      icon: Icons.view_carousel,
                      label: "Flashcard",
                      colors: [Colors.blue, Colors.indigo],
                      page: FlashcardStudyPage(
                        vocabList: vocabList,
                        setId: widget.set.id,
                        isPersonal: widget.isPersonal,
                        setTitle: widget.set.title,
                      ), // Pass the setTitle here
                      context: context,
                    ),
                    _modeCard(
                      icon: Icons.quiz,
                      label: "Quiz",
                      colors: [Colors.orange, Colors.deepOrange],
                      page: FlashcardQuizPage(vocabList: vocabList, setTitle: widget.set.title, setId: widget.set.id,isPersonal : widget.isPersonal,),
                      context: context,
                    ),
                    _modeCard(
                      icon: Icons.keyboard,
                      label: "Typing",
                      colors: [Colors.green, Colors.teal],
                      page: FlashcardTypingPage(vocabList: vocabList, setTitle: widget.set.title, setId: widget.set.id,isPersonal: widget.isPersonal,),
                      context: context,
                    ),
                  ],
                ),

               

                /// Vocabulary list
                Text(
                  "Vocabulary (${vocabList.length})",
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),

                ...vocabList.asMap().entries.map((entry) {
                  final i = entry.key;
                  final v = entry.value;
                  final hi = _isHighlight(v.word);

                  return Container(
                    key: _vocabKeys[i],
                    child: _vocabCard(v, i, isHighlight: hi),
                  );
                }).toList(),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _modeCard({
    required IconData icon,
    required String label,
    required List<Color> colors,
    required Widget page,
    required BuildContext context,
  }) {
    return Expanded(
      child: InkWell(
        onTap: () async {
          await Navigator.push(context, MaterialPageRoute(builder: (_) => page));
        
        },
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: colors.first.withOpacity(0.1),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            children: [
              Icon(icon, color: colors.last, size: 30),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  color: colors.last,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showVocabDetailDialog(Vocabulary vocab, int index) {
    bool isLoading = false;
    String geminiResult = '';

    final bool hasExample =
        vocab.example.isNotEmpty &&
        vocab.exampleMeaning.isNotEmpty &&
        vocab.exampleExplain.isNotEmpty;

    if (hasExample) {
      geminiResult =
          """
**Câu ví dụ:** ${vocab.example}

**Nghĩa:** ${vocab.exampleMeaning}

**Giải thích:** ${vocab.exampleExplain}
""";
    } else {
      isLoading = true;
    }

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        bool hasCalledGemini = false;
        return StatefulBuilder(
          builder: (context, setState) {
            /// GỌI GEMINI KHI DIALOG VỪA MỞ
            Future<void> fetchGeminiExample() async {
              final bool allowSave = widget.isPersonal;

              final apiKey = dotenv.env['API_KEY'];
              final url =
                  'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash-lite:generateContent?key=$apiKey';

              final prompt =
                  """
Bạn là trợ lý học từ vựng.

Nhiệm vụ:
- Tạo MỘT câu ví dụ NGẮN, TỰ NHIÊN 
- Câu ví dụ PHẢI chứa từ: "${vocab.word}"
- Trong câu ví dụ, từ "${vocab.word}" PHẢI được bao quanh bằng ** ** để in đậm
- Sau đó cung cấp nghĩa TIẾNG VIỆT của TOÀN BỘ câu
- Cuối cùng giải thích ngắn gọn cách dùng từ "${vocab.word}" (dưới 20 từ)

QUAN TRỌNG:
- CHỈ trả về JSON
- KHÔNG thêm bất kỳ chữ nào ngoài JSON
- KHÔNG dùng markdown bên ngoài JSON

Format JSON bắt buộc:

{
  "example": "câu ví dụ (có **${vocab.word}**)",
  "meaning_vi": "nghĩa tiếng Việt của cả câu",
  "explanation": "giải thích ngắn gọn cách dùng từ"
}
""";

              try {
                final res = await http.post(
                  Uri.parse(url),
                  headers: {'Content-Type': 'application/json'},
                  body: jsonEncode({
                    "contents": [
                      {
                        "parts": [
                          {"text": prompt},
                        ],
                      },
                    ],
                  }),
                );

                final data = jsonDecode(res.body);

                if (data['candidates'] == null ||
                    data['candidates'].isEmpty ||
                    data['candidates'][0]['content'] == null ||
                    data['candidates'][0]['content']['parts'] == null ||
                    data['candidates'][0]['content']['parts'].isEmpty ||
                    data['candidates'][0]['content']['parts'][0]['text'] ==
                        null) {
                  throw Exception(
                    data['error']?['message'] ??
                        'Gemini không trả về nội dung hợp lệ',
                  );
                }

                final raw =
                    data['candidates'][0]['content']['parts'][0]['text'];

                final jsonText = raw.substring(
                  raw.indexOf('{'),
                  raw.lastIndexOf('}') + 1,
                );

                final result = jsonDecode(jsonText);

                // 1️⃣ Lấy document hiện tại
                final DocumentReference docRef = widget.isPersonal
                    ? FirebaseFirestore.instance
                          .collection('flashcards')
                          .doc(FirebaseAuth.instance.currentUser!.uid)
                          .collection('userFlashcards')
                          .doc(widget.set.id)
                    : FirebaseFirestore.instance
                          .collection('flashcard_sets')
                          .doc(widget.set.id);

                final snap = await docRef.get();

                // 2️⃣ Clone vocabList hiện tại
                final docData = snap.data() as Map<String, dynamic>;

                final List vocabListRaw = List.from(docData['vocabList'] ?? []);
                // 3️⃣ Tạo vocab mới (FULL FIELD – KHÔNG MẤT DATA)
                final updatedVocab = {
                  "word": vocab.word,
                  "romaji": vocab.romaji,
                  "meaning": vocab.meaning,
                  "imageUrl": vocab.imageUrl,
                  "example": result['example'],
                  "exampleMeaning": result['meaning_vi'],
                  "exampleExplain": result['explanation'],
                };

                // 4️⃣ Ghi đè đúng index
                vocabListRaw[index] = updatedVocab;

                // 5️⃣ Update lại TOÀN BỘ vocabList
                if (allowSave) {
                  await docRef.update({"vocabList": vocabListRaw});
                }
                setState(() {
                  geminiResult =
                      """
**Câu ví dụ:** ${result['example']}

**Nghĩa:** ${result['meaning_vi']}

**Giải thích:** ${result['explanation']}
""";
                  isLoading = false;
                });
              } catch (e) {
                setState(() {
                  geminiResult = "❌ Lỗi Gemini: $e";
                  isLoading = false;
                });
              }
            }

            /// CHỈ GỌI 1 LẦN
            if (!hasExample && isLoading && !hasCalledGemini) {
              hasCalledGemini = true;
              fetchGeminiExample();
            }

            return Dialog(
              backgroundColor: Colors.grey.shade100,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// ẢNH
                    if (vocab.imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(14),
                        child: Image.network(
                          vocab.imageUrl,
                          height: 180,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),

                    const SizedBox(height: 12),

                    /// TỪ
                    Text(
                      vocab.word,
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    Text(
                      vocab.romaji,
                      style: const TextStyle(color: Colors.grey),
                    ),

                    const SizedBox(height: 6),

                    Text(
                      "Nghĩa: ${vocab.meaning}",
                      style: const TextStyle(fontSize: 16),
                    ),

                    const Divider(height: 30),

                    const Text(
                      "📘 Ví dụ & giải thích (AI)",
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 10),

                    if (isLoading)
                      const Center(child: CircularProgressIndicator())
                    else
                      MarkdownBody(
                        data: geminiResult,
                        styleSheet: MarkdownStyleSheet(
                          p: const TextStyle(fontSize: 15),
                          strong: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange,
                          ),
                        ),
                      ),
                    const SizedBox(height: 20),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text("ĐÓNG"),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
//   Widget _langBadge(String word) {
//   final lang = detectLanguage(word: vocab.word, reading: vocab.romaji);

//   String flag;
//   String label;

//   switch (lang) {
//     case 'ja':
//       flag = '🇯🇵';
//       label = 'JA';
//       break;
//     case 'ko':
//       flag = '🇰🇷';
//       label = 'KO';
//       break;
//     case 'zh':
//       flag = '🇨🇳';
//       label = 'ZH';
//       break;
//     default:
//       flag = '🌐';
//       label = 'Other';
//   }

//   return Container(
//     padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
//     decoration: BoxDecoration(
//       color: Colors.orange.withOpacity(0.10),
//       borderRadius: BorderRadius.circular(999),
//       border: Border.all(color: Colors.orange.withOpacity(0.45)),
//     ),
//     child: Text(
//       '$flag $label',
//       style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w800),
//     ),
//   );
// }

  Widget _vocabCard(Vocabulary vocab, int index, {bool isHighlight = false}) {
    // final lang = detectLanguage(word: vocab.word, reading: vocab.romaji);
    return InkWell(
      onTap: () {
        _clearHighlightIfAnyInteraction();
        _showVocabDetailDialog(vocab, index);
      },
      onLongPress: widget.isPersonal
          ? () => _showVocabActions(vocab, index)
          : null,
      child: AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighlight ? Colors.orange.shade50 : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighlight ? Colors.orange.shade300 : Colors.transparent,
          width: isHighlight ? 2.0 : 0.0,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x14000000), 
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vocab.word,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    vocab.romaji,
                    style: const TextStyle(color: Colors.grey),
                  ),
                  Text(
                    vocab.meaning,
                    style: const TextStyle(color: Colors.black54),
                  ),
                ],
              ),
            ),
              // _langFlagPill(lang: lang),
            // const SizedBox(width: 8),
            IconButton(
              icon: const Icon(
                Icons.volume_up_rounded,
                color: Colors.indigo,
                size: 28,
              ),
              onPressed: () {
                _clearHighlightIfAnyInteraction();
                _speak(vocab.word);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showVocabActions(Vocabulary vocab, int index) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade100,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.edit, color: Colors.orangeAccent),
                title: const Text("Chỉnh sửa"),
                onTap: () {
                  Navigator.pop(context);
                  _showEditVocabularySheet(vocab, index);
                },
              ),

              ListTile(
                leading: const Icon(Icons.delete, color: Colors.orangeAccent),
                title: const Text("Xóa"),
                onTap: () {
                  Navigator.pop(context);

                  Future.delayed(const Duration(milliseconds: 120), () {
                    if (!mounted) return;
                    _confirmDeleteVocabulary(vocab, index);
                  });
                },
              ),


              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  String detectLanguage({
    required String word,
    String? reading, // vocab.romaji
  }) {
    final text = word.trim();
    final rd = (reading ?? '').trim().toLowerCase();

    final jpKana = RegExp(r'[\u3040-\u30ff]'); // Hiragana + Katakana
    final krHangul = RegExp(r'[\uac00-\ud7af]'); // Hangul
    final han = RegExp(r'[\u4e00-\u9fff]'); // Han (Chinese characters, also used in JP)

    if (krHangul.hasMatch(text)) return 'ko';
    if (jpKana.hasMatch(text)) return 'ja';

    if (han.hasMatch(text)) {

      if (rd.isNotEmpty) {
        final looksChinese =
            rd.contains('zh') || rd.contains(' x') || rd.contains(' q') || rd.contains('x') || rd.contains('q') || rd.contains(' ') ||
            RegExp(r'[āáǎàēéěèīíǐìōóǒòūúǔùǖǘǚǜ]').hasMatch(rd);

        if (looksChinese) return 'zh';
        return 'ja';
      }

      return 'other';
    }

    return 'other';
  }
  String _flagEmoji(String lang) {
    final c = lang.toLowerCase().trim();
    if (c == 'ja' || c == 'jp') return '🇯🇵';
    if (c == 'ko' || c == 'kr') return '🇰🇷';
    if (c == 'zh' || c == 'cn') return '🇨🇳';
    return '🏳️';
  }

  String _langLabel(String lang) {
    final c = lang.toLowerCase().trim();
    if (c == 'ja' || c == 'jp') return 'Japanese';
    if (c == 'ko' || c == 'kr') return 'Korean';
    if (c == 'zh' || c == 'cn') return 'Chinese';
    return 'Other';
  }

  Widget _langFlagPill({required String lang}) {
    final emoji = _flagEmoji(lang);
    final label = _langLabel(lang);

    return Tooltip(
      message: label,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.orange.shade50,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: Colors.orange.shade200, width: 1.2),
        ),
        child: Text(emoji, style: const TextStyle(fontSize: 12)),
      ),
    );
  }



  Future<void> _deleteVocabulary(int index) async {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    final docRef = FirebaseFirestore.instance
        .collection('flashcards')
        .doc(userId)
        .collection('userFlashcards')
        .doc(widget.set.id);

    final snap = await docRef.get();
    final List list = List.from(snap.data()!['vocabList']);

    list.removeAt(index);

    await docRef.update({"vocabList": list});
  }
    void _confirmDeleteVocabulary(Vocabulary vocab, int index) {
    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (dialogCtx) {
        bool isDeleting = false;

        return StatefulBuilder(
          builder: (ctx, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.symmetric(horizontal: 22),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(22),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.12),
                      blurRadius: 22,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: Colors.orange.shade50,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.delete_outline_rounded,
                        color: Colors.red.shade400,
                        size: 28,
                      ),
                    ),
                    const SizedBox(height: 12),

                    const Text(
                      "Xóa từ vựng",
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 8),

                    Text(
                      'Bạn có chắc muốn xóa "${vocab.word}" không?',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),

                    Row(
                      children: [
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: OutlinedButton(
                              onPressed: isDeleting
                                  ? null
                                  : () => Navigator.pop(dialogCtx),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.orange.shade700,
                                side: BorderSide(
                                  color: Colors.orange.shade300,
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              child: const Text(
                                "Hủy",
                                style: TextStyle(fontWeight: FontWeight.w800),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: SizedBox(
                            height: 46,
                            child: ElevatedButton(
                              onPressed: isDeleting
                                  ? null
                                  : () async {
                                      setState(() => isDeleting = true);
                                      try {
                                        await _deleteVocabulary(index);

                                        if (!mounted) return;
                                        Navigator.pop(dialogCtx);

                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text(
                                              'Đã xóa "${vocab.word}"',
                                              style: TextStyle(
                                                color: Colors.orange.shade800,
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                            backgroundColor: Colors.orange.shade50,
                                            behavior: SnackBarBehavior.floating,
                                            margin: const EdgeInsets.all(16),
                                          ),
                                        );
                                      } catch (e) {
                                        if (!mounted) return;
                                        Navigator.pop(dialogCtx);
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(
                                            content: Text("Lỗi: $e"),
                                            backgroundColor: Colors.red.shade200,
                                            behavior: SnackBarBehavior.floating,
                                            margin: const EdgeInsets.all(16),
                                          ),
                                        );
                                      }
                                    },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.red.shade400,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                elevation: 0,
                              ),
                              child: isDeleting
                                  ? const SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: Colors.white,
                                      ),
                                    )
                                  : const Text(
                                      "Xóa",
                                      style: TextStyle(fontWeight: FontWeight.w900),
                                    ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }


  void _showEditVocabularySheet(Vocabulary vocab, int index) {
    String word = vocab.word;
    String romaji = vocab.romaji;
    String meaning = vocab.meaning;
    String selectedImageUrl = vocab.imageUrl;

    bool loading = false;
    List<String> imageResults = [];
    bool isLoadingImages = false;

    final userId = FirebaseAuth.instance.currentUser!.uid;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.grey.shade100,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    "Chỉnh sửa từ vựng",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),

                  /// WORD
                  TextField(
                    decoration: InputDecoration(
                      labelText: "Từ",
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.orange.shade200,
                          width: 2,
                        ),
                      ),
                    ),
                    controller: TextEditingController(text: word),
                    onChanged: (v) {
                      word = v;
                      fetchPixabayImages(
                        keyword: v,
                        setModalState: setState,
                        imageResults: imageResults,
                        setLoading: (v) => isLoadingImages = v,
                      );
                    },
                  ),
                  const SizedBox(height: 12),

                  /// ROMAJI
                  TextField(
                    decoration: InputDecoration(
                      labelText: "Phát âm",
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.orange.shade200,
                          width: 2,
                        ),
                      ),
                    ),
                    controller: TextEditingController(text: romaji),
                    onChanged: (v) => romaji = v,
                  ),
                  const SizedBox(height: 12),

                  /// MEANING
                  TextField(
                    decoration: InputDecoration(
                      labelText: "Nghĩa",
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.orange.shade200,
                          width: 2,
                        ),
                      ),
                    ),
                    controller: TextEditingController(text: meaning),
                    onChanged: (v) => meaning = v,
                  ),

                  const SizedBox(height: 12),

                  /// IMAGE PICK
                  if (imageResults.isNotEmpty)
                    GridView.builder(
                      shrinkWrap: true,
                      itemCount: imageResults.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 6,
                            mainAxisSpacing: 6,
                          ),
                      itemBuilder: (_, i) {
                        final img = imageResults[i];
                        return GestureDetector(
                          onTap: () => setState(() => selectedImageUrl = img),
                          child: Image.network(img, fit: BoxFit.cover),
                        );
                      },
                    ),

                  const SizedBox(height: 20),

                  /// SAVE
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: loading
                          ? null
                          : () async {
                              setState(() => loading = true);

                              final docRef = FirebaseFirestore.instance
                                  .collection('flashcards')
                                  .doc(userId)
                                  .collection('userFlashcards')
                                  .doc(widget.set.id);

                              final snap = await docRef.get();
                              final List list = List.from(
                                snap.data()!['vocabList'],
                              );

                              list[index] = {
                                "word": word,
                                "romaji": romaji,
                                "meaning": meaning,
                                "imageUrl": selectedImageUrl,
                                "example": vocab.example,
                                "exampleMeaning": vocab.exampleMeaning,
                                "exampleExplain": vocab.exampleExplain,
                              };

                              await docRef.update({"vocabList": list});

                              Navigator.pop(context);
                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "LƯU",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }

  void showAddVocabularySheet(BuildContext context, {required String userId}) {
    if (!widget.isPersonal) return;

    final wordController = TextEditingController();
    final romajiController = TextEditingController();
    final meaningController = TextEditingController();

    bool loading = false;
    String selectedImageUrl = '';
    List<String> imageResults = [];
    bool isLoadingImages = false;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.grey.shade100,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Padding(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context).viewInsets.bottom,
                left: 20,
                right: 20,
                top: 20,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    "Thêm từ mới",
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: wordController,
                    decoration: InputDecoration(
                      labelText: "Từ",
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.orange.shade200,
                          width: 2,
                        ),
                      ),
                    ),
                    onChanged: (v) async {
                      if (v.trim().isEmpty) return;

                      final lang = detectLanguage(word: v);

                      final result = await fetchPronunciationAndMeaning(
                        word: v,
                        language: lang,
                      );

                      setState(() {
                        romajiController.text = result['pronunciation'] ?? '';
                        meaningController.text = result['meaning_vi'] ?? '';
                      });
                      fetchPixabayImages(
                        keyword: v,
                        setModalState: setState,
                        imageResults: imageResults,
                        setLoading: (v) => isLoadingImages = v,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: romajiController,
                    decoration: InputDecoration(
                      labelText: "Phát âm",
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.orange.shade200,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: meaningController,
                    decoration: InputDecoration(
                      labelText: "Nghĩa",
                      labelStyle: const TextStyle(fontWeight: FontWeight.w600),
                      filled: true,
                      fillColor: Colors.white,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide(
                          color: Colors.orange.shade200,
                          width: 2,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),

                  if (isLoadingImages)
                    const Padding(
                      padding: EdgeInsets.all(8),
                      child: CircularProgressIndicator(),
                    ),

                  if (imageResults.isNotEmpty)
                    GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: imageResults.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 4,
                            crossAxisSpacing: 6,
                            mainAxisSpacing: 6,
                          ),
                      itemBuilder: (_, i) {
                        final img = imageResults[i];
                        final isSelected = img == selectedImageUrl;

                        return GestureDetector(
                          onTap: () {
                            setState(() => selectedImageUrl = img);
                          },
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: isSelected
                                    ? Colors.orange
                                    : Colors.transparent,
                                width: 3,
                              ),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(img, fit: BoxFit.cover),
                            ),
                          ),
                        );
                      },
                    ),

                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: loading
                          ? null
                          : () async {
                              if (wordController.text.trim().isEmpty ||
                                  meaningController.text.trim().isEmpty)
                                return;

                              setState(() => loading = true);

                              final newVocab = Vocabulary(
                                word: wordController.text.trim(),
                                romaji: romajiController.text.trim(),
                                meaning: meaningController.text.trim(),
                                imageUrl: selectedImageUrl,
                              );

                              try {
                                final vocabRef = FirebaseFirestore.instance
                                    .collection('flashcards')
                                    .doc(userId)
                                    .collection('userFlashcards')
                                    .doc(widget.set.id);

                                await vocabRef.set({
                                  "vocabList": FieldValue.arrayUnion([
                                    {
                                      "word": newVocab.word,
                                      "romaji": newVocab.romaji,
                                      "meaning": newVocab.meaning,
                                      "imageUrl": newVocab.imageUrl,
                                    },
                                  ]),
                                }, SetOptions(merge: true));

                                final snap = await vocabRef.get();
                                final list = snap.data()?['vocabList'] ?? [];

                                setState(() {
                                  vocabList = list
                                      .map<Vocabulary>(
                                        (e) => Vocabulary.fromMap(e),
                                      )
                                      .toList();
                                });

                                Navigator.pop(context);

                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text(
                                      "Thêm từ thành công!",
                                      style: TextStyle(color: Colors.orange),
                                    ),
                                    backgroundColor: Colors.orange.shade100,
                                    behavior: SnackBarBehavior.floating,
                                    margin: const EdgeInsets.all(16),
                                  ),
                                );
                              } catch (e) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text("Lỗi: $e"),
                                    backgroundColor: Colors.red.shade200,
                                  ),
                                );
                              } finally {
                                setState(() => loading = false);
                              }
                            },

                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text(
                              "LƯU",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            );
          },
        );
      },
    );
  }
}
