import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class SpeakingPage extends StatefulWidget {
  const SpeakingPage({super.key});

  @override
  State<SpeakingPage> createState() => _SpeakingPageState();
}

class _SpeakingPageState extends State<SpeakingPage> {
  final FlutterTts _tts = FlutterTts();
  final SpeechToText _stt = SpeechToText();

  // 1. DỮ LIỆU THỰC - KHỞI TẠO TRỐNG (Bỏ toàn bộ dữ liệu mẫu)
  String language = 'ja'; 
  String selectedTopic = 'Giao tiếp hằng ngày';
  String aiSentence = '';
  String meaning = ''; 
  String userSpeech = '';
  int? score;
  String feedback = '';
  
  bool isLoading = false;
  bool isListening = false;

  final List<String> topics = [
    'Giao tiếp hằng ngày',
    'Du lịch & Khách sạn',
    'Công việc & Phỏng vấn',
    'Mua sắm & Giá cả',
    'Nhà hàng & Ẩm thực',
    'Sở thích & Giải trí'
  ];

  final Color primaryOrange = const Color(0xFFFF7043);
  final Color lightOrange = const Color(0xFFFFF3E0);
  final Color darkOrange = const Color(0xFFE64A19);
  final Color bgBackground = const Color(0xFFFDFDFD);

  @override
  void initState() {
    super.initState();
    // 2. TỰ ĐỘNG GỌI AI KHI VỪA VÀO TRANG
    _generateSentence();
  }

  // ===== LOGIC KẾT NỐI AI THỰC TẾ =====

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
    final url = 'https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent?key=$apiKey';

    final prompt = '''
Bạn là giáo viên dạy ngoại ngữ. Ngôn ngữ: $language. Chủ đề: $selectedTopic.
Tạo 1 câu ngắn gọn và dịch sang tiếng Việt. 
Chỉ trả về JSON duy nhất: {"sentence": "...", "meaning": "..."}
''';

    try {
      final res = await http.post(Uri.parse(url), 
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"contents": [{"parts": [{"text": prompt}]}]}),
      );
      
      final data = jsonDecode(res.body);
      String rawText = data['candidates'][0]['content']['parts'][0]['text'];
      
      // Xử lý loại bỏ markdown nếu AI trả về (```json ... ```)
      rawText = rawText.replaceAll('```json', '').replaceAll('```', '').trim();
      final decoded = jsonDecode(rawText);

      setState(() {
        aiSentence = decoded['sentence'];
        meaning = decoded['meaning'];
        isLoading = false;
      });
      _speak(aiSentence);
    } catch (e) {
      setState(() {
        aiSentence = "Lỗi kết nối. Vui lòng kiểm tra API Key.";
        isLoading = false;
      });
    }
  }

  Future<void> _scorePronunciation() async {
    if (userSpeech.isEmpty) return;
    setState(() => isLoading = true);

    final apiKey = dotenv.env['API_KEY'];
    final url = 'https://generativelanguage.googleapis.com/v1/models/gemini-2.0-flash:generateContent?key=$apiKey';
  
    final prompt = '''
Chấm điểm phát âm. 
Câu chuẩn: "$aiSentence"
Người nói: "$userSpeech"
So sánh và trả về JSON: {"score": 0-100, "feedback": "nhận xét ngắn gọn bằng tiếng Việt"}
''';

    try {
      final res = await http.post(Uri.parse(url), 
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({"contents": [{"parts": [{"text": prompt}]}]}),
      );
      
      final data = jsonDecode(res.body);
      String rawText = data['candidates'][0]['content']['parts'][0]['text'];
      rawText = rawText.replaceAll('```json', '').replaceAll('```', '').trim();
      final decoded = jsonDecode(rawText);

      setState(() {
        score = decoded['score'];
        feedback = decoded['feedback'];
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
    }
  }

  // ===== GIỮ NGUYÊN CÁC HÀM TTS/STT =====

  Future<void> _speak(String text) async {
    if (text.isEmpty) return;
    await _tts.setLanguage(language == 'ja' ? 'ja-JP' : language == 'ko' ? 'ko-KR' : 'zh-CN');
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
      });
      await _stt.listen(
        localeId: language == 'ja' ? 'ja_JP' : language == 'ko' ? 'ko_KR' : 'zh_CN',
        onResult: (result) {
          setState(() {
            userSpeech = result.recognizedWords;
            if (result.finalResult) {
              isListening = false;
              // Tự động chấm điểm sau khi nói xong 1 giây
              Future.delayed(const Duration(seconds: 1), _scorePronunciation);
            }
          });
        },
      );
    }
  }

  // ===== UI/UX GIỮ NGUYÊN Y CHANG BẢN GỐC =====

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgBackground,
      appBar: AppBar(
        title: const Text("AI Speaking Coach", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
        backgroundColor: primaryOrange,
        centerTitle: true,
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
                  if (score != null) _buildResultCard(),
                  if (isLoading && aiSentence.isNotEmpty && score == null)
                    const Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: Colors.orange)),
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
      decoration: BoxDecoration(
        color: primaryOrange,
        borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(30), bottomRight: Radius.circular(30)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _langBtn("🇯🇵 Nhật", "ja"),
              _langBtn("🇰🇷 Hàn", "ko"),
              _langBtn("🇨🇳 Trung", "zh"),
            ],
          ),
          const SizedBox(height: 15),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(15)),
            child: DropdownButton<String>(
              value: selectedTopic,
              dropdownColor: primaryOrange,
              isExpanded: true,
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down, color: Colors.white),
              items: topics.map((String value) => DropdownMenuItem<String>(
                  value: value,
                  child: Text(value, style: const TextStyle(color: Colors.white)),
                )).toList(),
              onChanged: (newValue) {
                setState(() => selectedTopic = newValue!);
                _generateSentence(); // Đổi chủ đề tự động đổi câu mới
              },
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
        borderRadius: BorderRadius.circular(25),
        boxShadow: [BoxShadow(color: primaryOrange.withOpacity(0.1), blurRadius: 20, spreadRadius: 2)],
        border: Border.all(color: lightOrange),
      ),
      child: Column(
        children: [
          const Text("CÂU LUYỆN TẬP", style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey, letterSpacing: 1.2)),
          const SizedBox(height: 15),
          if (isLoading && aiSentence.isEmpty)
            const CircularProgressIndicator(color: Colors.orange)
          else ...[
            Text(aiSentence, textAlign: TextAlign.center, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: darkOrange)),
            const SizedBox(height: 8),
            Text("($meaning)", textAlign: TextAlign.center, style: TextStyle(fontSize: 16, color: Colors.grey[600], fontStyle: FontStyle.italic)),
            const SizedBox(height: 10),
            IconButton(icon: Icon(Icons.volume_up, size: 30, color: primaryOrange), onPressed: () => _speak(aiSentence)),
          ]
        ],
      ),
    );
  }

  Widget _buildMicSection() {
    return Column(
      children: [
        GestureDetector(
          onTap: isListening ? null : _listen,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            height: 90, width: 90,
            decoration: BoxDecoration(
              color: isListening ? Colors.redAccent : primaryOrange,
              shape: BoxShape.circle,
              boxShadow: [BoxShadow(color: (isListening ? Colors.redAccent : primaryOrange).withOpacity(0.4), blurRadius: 20, spreadRadius: 5)],
            ),
            child: Icon(isListening ? Icons.graphic_eq : Icons.mic, color: Colors.white, size: 40),
          ),
        ),
        const SizedBox(height: 12),
        Text(isListening ? "Đang nghe... Nói đi bạn!" : "Nhấn Micro để đọc", 
          style: TextStyle(color: isListening ? Colors.red : Colors.grey[600], fontWeight: FontWeight.w500)),
      ],
    );
  }

  Widget _buildUserSpeechCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.grey[100], borderRadius: BorderRadius.circular(15)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("BẠN ĐÃ NÓI:", style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.blueGrey)),
          const SizedBox(height: 5),
          Text(userSpeech, style: const TextStyle(fontSize: 16, fontStyle: FontStyle.italic)),
        ],
      ),
    );
  }

  Widget _buildResultCard() {
    Color statusColor = score! >= 80 ? Colors.green : (score! >= 50 ? Colors.orange : Colors.red);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: statusColor.withOpacity(0.3)),
        boxShadow: [BoxShadow(color: statusColor.withOpacity(0.05), blurRadius: 15)],
      ),
      child: Column(
        children: [
          const Text("KẾT QUẢ PHÁT ÂM", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blueGrey, letterSpacing: 1.1)),
          const SizedBox(height: 20),
          Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                height: 100, width: 100,
                child: CircularProgressIndicator(
                  value: score! / 100,
                  strokeWidth: 8,
                  backgroundColor: Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(statusColor),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("$score", style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: statusColor)),
                  const Text("điểm", style: TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 25),
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(color: statusColor.withOpacity(0.05), borderRadius: BorderRadius.circular(15)),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.lightbulb_outline, color: statusColor, size: 24),
                const SizedBox(width: 10),
                Expanded(child: Text(feedback, style: const TextStyle(fontSize: 14, height: 1.5, color: Colors.black87))),
              ],
            ),
          ),
          const SizedBox(height: 25),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: _generateSentence,
              icon: const Icon(Icons.navigate_next, color: Colors.white),
              label: const Text("HỌC CÂU TIẾP THEO", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(backgroundColor: statusColor, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15))),
            ),
          )
        ],
      ),
    );
  }

  Widget _langBtn(String label, String code) {
    bool isSelected = language == code;
    return GestureDetector(
      onTap: () {
        setState(() => language = code);
        _generateSentence(); // Đổi ngôn ngữ đổi câu luôn
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white : Colors.white.withOpacity(0.2),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(label, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? primaryOrange : Colors.white)),
      ),
    );
  }
}