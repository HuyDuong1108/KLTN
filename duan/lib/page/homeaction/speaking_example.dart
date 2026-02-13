import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_markdown/flutter_markdown.dart';


class SpeakingPage extends StatefulWidget {
  const SpeakingPage({super.key});

  @override
  State<SpeakingPage> createState() => _SpeakingPageState();
}

class _SpeakingPageState extends State<SpeakingPage> {
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();
  bool hasScored = false;

  // Khởi tạo các giá trị (Gán sẵn dữ liệu mẫu để bạn hình dung giao diện feedback)
  String language = 'en';
  String selectedTopic = 'Hometown';
  String aiSentence = 'Hello, how are you doing today?';
  String meaning = 'Xin chào, bạn khỏe không?';
  String userSpeech = 'I am doing good, thank you!';

  // Dữ liệu Feedback mẫu
  int? score = 85;
  String feedback =
      'Phát âm rất tốt! Bạn đã phát âm rõ ràng các âm tiết. Tuy nhiên, lưu ý nhấn nhẹ hơn ở cuối câu để nghe tự nhiên như người bản xứ.';

  bool isLoading = false;
  bool isListening = false;

  final List<String> topics = [
    'Hometown',
    'Education',
    'Work',
    'Technology',
    'Travel',
    'Environment',
    'Family',
    'Hobbies',
  ];

  // ===== NEW COLOR SYSTEM =====
  final Color primaryBlue = Color(
    0xFF42A5F5,
  ); // xanh tươi chính (giống Overall band card)
  final Color accentBlue = Color(0xFF29B6F6); // xanh sáng nổi bật hơn
  final Color lightBlue = Color(0xFFE3F2FD); // nền card nhẹ
  final Color darkBlue = Color(0xFF1565C0); // xanh đậm text
  final Color backgroundColor = Color(0xFFF5FAFF); // nền page

  // ===== LOGIC CHÍNH =====

  Future<void> _generateSentence() async {
    setState(() {
      isLoading = true;
      score = null;
      feedback = '';
      userSpeech = '';
      aiSentence = '';
      meaning = '';
    });

    final apiKey = dotenv.env['API_KEY'];
    final url =
        'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash-lite:generateContent?key=$apiKey';

    final prompt =
        '''
You are an IELTS Speaking examiner.
Topic: $selectedTopic.

Task:
Generate ONE natural English speaking question suitable for IELTS Part 1 or Part 2.

Return JSON only:
{
  "sentence": "IELTS question here",
  "meaning": "Vietnamese explanation"
}
''';

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
      final raw = jsonDecode(
        res.body,
      )['candidates'][0]['content']['parts'][0]['text'];
      final jsonText = raw.substring(
        raw.indexOf('{'),
        raw.lastIndexOf('}') + 1,
      );
      final decoded = jsonDecode(jsonText);

      setState(() {
        aiSentence = decoded['sentence'];
        meaning = decoded['meaning'];
        isLoading = false;
      });
      _speak(aiSentence);
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _scorePronunciation() async {
    if (userSpeech.isEmpty) return;
    setState(() => isLoading = true);

    final apiKey = dotenv.env['API_KEY'];
    final url =
        'https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash-lite:generateContent?key=$apiKey';

    final prompt =
        '''
You are an IELTS examiner.

Original question: "$aiSentence"
Candidate answer: "$userSpeech"

Score pronunciation from 0 to 100.
Give detailed feedback on:
- Pronunciation
- Fluency
- Intonation

Return JSON only:
{
  "score": 75,
  "feedback": "Detailed IELTS style feedback..."
}
''';

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
      final raw = jsonDecode(
        res.body,
      )['candidates'][0]['content']['parts'][0]['text'];
      final jsonText = raw.substring(
        raw.indexOf('{'),
        raw.lastIndexOf('}') + 1,
      );
      final decoded = jsonDecode(jsonText);

      setState(() {
        score = decoded['score'];
        feedback = decoded['feedback'];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _speak(String text) async {
    if (text.isEmpty) return;
    await _tts.setLanguage('en-US');

    await _tts.setSpeechRate(0.45);
    await _tts.speak(text);
  }

  Future<void> _listen() async {
    bool available = await _stt.initialize();
    if (available) {
      setState(() {
        isListening = true;
        userSpeech = '';
        score = null;
        hasScored = false;
      });
      await _stt.listen(
        localeId: 'en_US',

        listenFor: const Duration(seconds: 100),
        pauseFor: const Duration(seconds: 3),
        onResult: (result) {
          setState(() {
            userSpeech = result.recognizedWords;
            if (result.finalResult && !hasScored) {
              hasScored = true;
              isListening = false;
              _scorePronunciation();
            }
          });
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F8FF),
      appBar: AppBar(
        title: const Text(
          "IELTS Speaking Coach",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: primaryBlue,
        elevation: 0,
      ),

      body: Column(
        children: [
          _buildTopSettings(),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  _buildQuestionCard(),
                  const SizedBox(height: 30),
                  _buildMicSection(),
                  const SizedBox(height: 30),
                  if (userSpeech.isNotEmpty) _buildUserSpeechCard(),
                  const SizedBox(height: 20),
                  // Phần Feedback hiển thị ở đây
                  if (score != null) _buildResultCard(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopSettings() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF42A5F5), Color(0xFF64B5F6)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(30),
          bottomRight: Radius.circular(30),
        ),
      ),

      child: Column(
        children: [
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(15),
            ),
            child: DropdownButton<String>(
              value: selectedTopic,
              dropdownColor: primaryBlue,
              isExpanded: true,
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              items: topics
                  .map(
                    (String value) => DropdownMenuItem<String>(
                      value: value,
                      child: Text(
                        value,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (newValue) =>
                  setState(() => selectedTopic = newValue!),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(25),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: primaryBlue.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),

      child: Column(
        children: [
          const Text(
            "IELTS QUESTION",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
              letterSpacing: 1.2,
            ),
          ),

          const SizedBox(height: 15),
          if (isLoading && aiSentence.isEmpty)
            const CircularProgressIndicator(color: Colors.orange)
          else ...[
            Text(
              aiSentence,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: darkBlue,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "($meaning)",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 10),
            IconButton(
              icon: Icon(Icons.volume_up, size: 30, color: primaryBlue),
              onPressed: () => _speak(aiSentence),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMicSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: (isListening || isLoading) ? null : _listen,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 90,
            width: 90,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: isListening
                    ? [Colors.redAccent, Colors.red]
                    : [primaryBlue, accentBlue],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: primaryBlue.withOpacity(0.4),
                  blurRadius: 25,
                  spreadRadius: 4,
                ),
              ],
            ),

            child: Icon(
              isListening ? Icons.graphic_eq : Icons.mic,
              color: Colors.white,
              size: 40,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          isLoading
              ? "Evaluating your speaking..."
              : isListening
              ? "Listening... Speak clearly"
              : "Tap the mic and answer",
          style: TextStyle(
            color: isListening ? Colors.red : Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildUserSpeechCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "BẠN ĐÃ NÓI:",
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            userSpeech,
            style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    // Xác định màu sắc dựa trên điểm số
    Color statusColor = score! >= 80
        ? Colors.green
        : (score! >= 50 ? Colors.orange : Colors.red);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(color: statusColor.withOpacity(0.05), blurRadius: 15),
        ],
      ),
      child: Column(
        children: [
          const Text(
            "SPEAKING FEEDBACK",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blueGrey,
              letterSpacing: 1.1,
            ),
          ),

          const SizedBox(height: 20),

          // Hiển thị điểm số dạng vòng tròn
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 100,
                width: 100,
                child: CircularProgressIndicator(
                  value: score! / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
              Column(
                children: [
                  Text(
                    "$score",
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                    ),
                  ),
                  const Text(
                    "điểm",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 25),

          // Phần nhận xét chi tiết
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: statusColor.withOpacity(0.05),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline, color: statusColor, size: 24),
                const SizedBox(width: 10),
                Expanded(
                  child: MarkdownBody(
                    data: feedback,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(
                        fontSize: 14,
                        height: 1.6,
                        color: Colors.black87,
                      ),
                      strong: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: statusColor,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 25),

          // Nút hành động
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _generateSentence,
              icon: const Icon(Icons.navigate_next, color: Colors.white),
              label: const Text(
                "HỌC CÂU TIẾP THEO",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _langBtn(String label, String code) {
    bool isSelected = language == code;
    return GestureDetector(
      onTap: () => setState(() => language = code),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isSelected ? primaryBlue : Colors.white,
          ),
        ),
      ),
    );
  }
}
