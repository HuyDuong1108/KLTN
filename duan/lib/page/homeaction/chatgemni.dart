import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class ChatGeminiPage extends StatefulWidget {
  const ChatGeminiPage({super.key});

  @override
  State<ChatGeminiPage> createState() => _ChatGeminiPageState();
}

class _ChatGeminiPageState extends State<ChatGeminiPage> {
  static final String _apiKey = dotenv.env['API_KEY'] ?? '';
  static final http.Client _client = http.Client();

  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  bool _isLoading = false;
  bool _isOffline = false;
  bool _isTypingText = false;
  bool _skipTyping = false;

  String _currentFullReply = "";

  final Color primaryBlue = const Color(0xFF42A5F5);
  final Color accentBlue = const Color(0xFF29B6F6);
  final Color lightBlue = const Color(0xFFE3F2FD);
  final Color darkBlue = const Color(0xFF1565C0);
  final Color backgroundColor = const Color(0xFFF5FAFF);

  List<List<Map<String, String>>> chatHistory = [];
  int currentChatIndex = 0;

  late List<Map<String, String>> messages;

  final List<String> suggestions = [
    "How can I improve my IELTS Speaking fluency?",
    "What are the best strategies for IELTS Reading?",
    "How do I write a high-scoring IELTS Writing Task 2 essay?",
    "Tips to improve listening skills for IELTS?",
    "How can I expand my vocabulary for IELTS band 7+?",
  ];

  @override
  void initState() {
    super.initState();
    messages = [
      {"role": "bot", "text": "Hello! How can I help you learn today?"},
    ];
    chatHistory.add(List.from(messages));
  }

  // ================= CONNECTIVITY =================
  Future<bool> _checkConnectivity() async {
    final result = await Connectivity().checkConnectivity();
    return result != ConnectivityResult.none;
  }

  void _showOfflineToast() {
    if (!_isOffline) {
      _isOffline = true;
      Fluttertoast.showToast(
        msg: "No internet connection",
        backgroundColor: Colors.red,
        textColor: Colors.white,
      );
    }
  }

  // ================= GEMINI API =================
  Future<String> _sendToGemini(String message) async {
    if (!await _checkConnectivity()) {
      _showOfflineToast();
      return "No internet connection.";
    }

    try {
      final url = Uri.parse(
        "https://generativelanguage.googleapis.com/v1/models/gemini-2.5-flash:generateContent?key=$_apiKey",
      );

      final body = jsonEncode({
        "contents": [
          {
            "parts": [
              {
                "text":
                    "You are a language learning assistant. "
                    "Reply concisely and directly. "
                    "Format your response using clean Markdown. "
                    "Use headings, bullet points, and short paragraphs. "
                    "Do not include internal reasoning.\n"
                    "User: $message",
              },
            ],
          },
        ],
        "generationConfig": {"maxOutputTokens": 400},
      });

      final response = await _client.post(
        url,
        headers: {HttpHeaders.contentTypeHeader: "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        final text = json["candidates"][0]["content"]["parts"][0]["text"];

        return text;
      } else {
        return "API error.";
      }
    } catch (e) {
      return "Error: $e";
    }
  }

  // ================= AUTO SCROLL =================
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 120),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // ================= TYPEWRITER EFFECT =================
  Future<void> _typeWriterEffect(String fullText) async {
    _isTypingText = true;
    _skipTyping = false;
    _currentFullReply = fullText;

    int index = 0;
    const speed = Duration(milliseconds: 25);

    Timer.periodic(speed, (timer) {
      if (_skipTyping || index >= fullText.length) {
        setState(() {
          messages.last["text"] = fullText;
        });
        timer.cancel();
        _isTypingText = false;
        _scrollToBottom();
        return;
      }

      setState(() {
        messages.last["text"] = messages.last["text"]! + fullText[index];
      });

      index++;
      _scrollToBottom();
    });
  }

  // ================= SEND MESSAGE =================
  void _send(String text) async {
    setState(() {
      messages.add({"role": "user", "text": text});
      _isLoading = true;
    });

    _scrollToBottom();

    final reply = await _sendToGemini(text);

    setState(() {
      _isLoading = false;
      messages.add({"role": "bot", "text": ""});
      chatHistory[currentChatIndex] = List.from(messages);
    });

    _scrollToBottom();
    await _typeWriterEffect(reply);
    chatHistory[currentChatIndex] = List.from(messages);
  }

  // ================= HEADER =================
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF42A5F5), Color(0xFF64B5F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          const CircleAvatar(
            radius: 22,
            backgroundImage: AssetImage("lib/image/logo.png"),
            backgroundColor: Colors.white,
          ),
          const SizedBox(width: 12),
          const Text(
            "AI Learning Assistant",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          IconButton(
            icon: const Icon(Icons.menu, color: Colors.white),
            onPressed: _openChatMenu,
          ),
        ],
      ),
    );
  }

  // ================= CHAT MENU =================
  void _openChatMenu() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              ListTile(
                leading: const Icon(Icons.add, color: Color(0xFF42A5F5)),
                title: const Text("New chat"),
                onTap: () {
                  Navigator.pop(context);
                  setState(() {
                    messages = [
                      {
                        "role": "bot",
                        "text": "Hello! How can I help you learn today?",
                      },
                    ];
                    chatHistory.add(List.from(messages));
                    currentChatIndex = chatHistory.length - 1;
                  });
                },
              ),
              const Divider(),
              Expanded(
                child: ListView.builder(
                  itemCount: chatHistory.length,
                  itemBuilder: (_, index) {
                    final title = chatHistory[index].firstWhere(
                      (m) => m["role"] == "user",
                      orElse: () => {"text": "New conversation"},
                    )["text"]!;
                    return ListTile(
                      leading: const Icon(
                        Icons.chat_bubble_outline,
                        color: Color(0xFF42A5F5),
                      ),
                      title: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      onTap: () {
                        setState(() {
                          messages = List.from(chatHistory[index]);
                          currentChatIndex = index;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMarkdownText(String text) {
    return MarkdownBody(
      data: text,
      selectable: true, // copy text như GPT
      styleSheet: MarkdownStyleSheet(
        p: const TextStyle(
          fontSize: 15.5,
          height: 1.55,
          letterSpacing: 0.2,
          color: Colors.black87,
        ),
        h1: const TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.bold,
          height: 1.6,
        ),
        h2: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          height: 1.6,
        ),
        h3: const TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.bold,
          height: 1.6,
        ),
        strong: const TextStyle(fontWeight: FontWeight.w600),
        em: const TextStyle(fontStyle: FontStyle.italic),
        listBullet: const TextStyle(fontSize: 15),
        blockquote: const TextStyle(
          color: Colors.black54,
          fontStyle: FontStyle.italic,
        ),
        code: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 14,
          backgroundColor: Color(0xFFF5F5F5),
        ),
      ),
    );
  }

  // ================= MESSAGE UI (NO BUBBLE) =================
  Widget _buildMessage(Map<String, String> msg) {
    final isUser = msg["role"] == "user";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: GestureDetector(
        onTap: () {
          if (_isTypingText) {
            setState(() => _skipTyping = true);
          }
        },
        child: Row(
          mainAxisAlignment: isUser
              ? MainAxisAlignment.end
              : MainAxisAlignment.start,
          children: [
            // BOT: text thẳng
            if (!isUser)
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 24),
                  child: _buildMarkdownText(msg["text"]!),
                ),
              ),

            // USER: bubble cam nhạt
            if (isUser)
              Flexible(
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF42A5F5), Color(0xFF29B6F6)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                  ),

                  child: Text(
                    msg["text"]!,
                    softWrap: true,
                    overflow: TextOverflow.visible,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.4,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  // ================= TYPING DOTS =================
  Widget _buildTypingDots() {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Text("Typing...", style: TextStyle(color: Colors.grey)),
    );
  }

  void sendMessageWithText(String text) {
    if (text.trim().isEmpty) return;
    _send(text.trim());
  }

  Widget _buildSuggestions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: suggestions.map((text) {
          return GestureDetector(
            onTap: () => sendMessageWithText(text),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: lightBlue,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: primaryBlue.withOpacity(0.3)),
              ),

              child: Text(
                text,
                style: TextStyle(fontSize: 13, color: darkBlue),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ================= INPUT =================
  Widget _buildInput() {
    final bool isResponding = _isLoading || _isTypingText;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(color: primaryBlue.withOpacity(0.15), blurRadius: 10),
        ],
      ),

      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _controller,
              style: const TextStyle(
                fontSize: 15,
                height: 1.4,
                letterSpacing: 0.1,
              ),
              enabled: !isResponding,
              decoration: const InputDecoration(
                hintText: "Type your question...",
                hintStyle: TextStyle(
                  fontSize: 14,
                  height: 1.3,
                  color: Colors.black54,
                ),
                border: InputBorder.none,
              ),
            ),
          ),

          // ===== ICON ĐỘNG GIỐNG GPT =====
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, animation) =>
                ScaleTransition(scale: animation, child: child),
            child: isResponding
                // ⏹ STOP / SKIP
                ? IconButton(
                    key: const ValueKey("stop"),
                    icon: const Icon(
                      Icons.stop_circle,
                      color: Color(0xFFFF9A62),
                    ),
                    onPressed: () {
                      // 👉 skip typing ngay
                      if (_isTypingText) {
                        setState(() => _skipTyping = true);
                      }
                    },
                  )
                // ✈️ SEND
                : IconButton(
                    key: const ValueKey("send"),
                    icon: const Icon(Icons.send, color: Color(0xFF42A5F5)),
                    onPressed: () {
                      final text = _controller.text.trim();
                      if (text.isNotEmpty) {
                        _controller.clear();
                        _send(text);
                      }
                    },
                  ),
          ),
        ],
      ),
    );
  }

  // ================= BUILD =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(
            child: ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.all(16),
              itemCount: messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index < messages.length) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildMessage(messages[index]),

                      // ✅ HIỆN GỢI Ý NGAY DƯỚI CÂU HELLO
                      if (index == 0 && messages.length == 1)
                        _buildSuggestions(),
                    ],
                  );
                }
                return _buildTypingDots();
              },
            ),
          ),
          _buildInput(),
        ],
      ),
    );
  }
}
