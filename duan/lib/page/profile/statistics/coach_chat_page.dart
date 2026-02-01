import 'package:flutter/material.dart';
import 'package:duan/data/stats_api.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class CoachChatPage extends StatefulWidget {
  final int horizonDays;
  final String? seedMessage;

  const CoachChatPage({
    super.key,
    this.horizonDays = 7,
    this.seedMessage,
  });

  @override
  State<CoachChatPage> createState() => _CoachChatPageState();
}

class _CoachChatPageState extends State<CoachChatPage> {
  final TextEditingController _ctl = TextEditingController();
  final ScrollController _scroll = ScrollController();

  bool _loading = false;
  Color get _accent => Color(0xFFFFE0B2);
  Color get _softBg => Colors.orange.withOpacity(0.10);


  final List<Map<String, String>> _messages = [];
  final List<String> _suggestions = const [
    "Hôm nay nên ôn gì?",
    "Khung giờ nào dễ sai?",
    "Vì sao hay Quên/Khó?",
    "Có bị dồn lịch không?",
    "Lập kế hoạch 7 ngày",
  ];
  String _normalizeMarkdown(String raw) {
    var s = raw.replaceAll('\r\n', '\n').trim();
    if (s.isEmpty) return '…';
    s = s.replaceAll('•', '\n- ');

    const labels = <String, String>{
      'Tóm tắt:': '**Tóm tắt:**',
      'Điểm mạnh:': '**Điểm mạnh:**',
      'Cần cải thiện:': '**Cần cải thiện:**',
      'Hành động:': '**Hành động:**',
      'Gợi ý:': '**Gợi ý:**',
      'Tip': '**Tip**',
    };
    labels.forEach((k, v) {
      s = s.replaceAll(k, v);
    });

    return s;
  }

  @override
  void initState() {
    super.initState();
    _messages.add({
      'role': 'bot',
      'text': widget.seedMessage ??
          'Lingua Coach hỗ trợ lập kế hoạch ôn và phân tích thẻ khó. Có thể hỏi theo gợi ý bên dưới.',
    });
  }

  void _sendWithText(String text) {
    _ctl.text = text;
    _send();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scroll.hasClients) {
        _scroll.animateTo(
          _scroll.position.maxScrollExtent,
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _send() async {
    final text = _ctl.text.trim();
    if (text.isEmpty || _loading) return;

    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _loading = true;
      _ctl.clear();
    });
    _scrollToBottom();

    try {
      final reply = await StatsApi.instance.coachChat(
        question: text,
        horizonDays: widget.horizonDays,
      );

      setState(() {
        _messages.add({'role': 'bot', 'text': reply});
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _messages.add({'role': 'bot', 'text': 'Không gọi được Coach. Lỗi: $e'});
        _loading = false;
      });
    }

    _scrollToBottom();
  }
 
  Widget _buildMarkdownText(BuildContext context, String text) {
  final data = _normalizeMarkdown(text);

  return MarkdownBody(
    data: data,
    selectable: true,
    softLineBreak: true,
    styleSheet: MarkdownStyleSheet(
      p: const TextStyle(
        fontSize: 15.5,
        height: 1.55,
        letterSpacing: 0.2,
        color: Colors.black87,
      ),
      h1: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, height: 1.35),
      h2: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, height: 1.35),
      h3: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, height: 1.35),
      strong: const TextStyle(fontWeight: FontWeight.w700),
      em: const TextStyle(fontStyle: FontStyle.italic),
      listBullet: const TextStyle(fontSize: 15),
      blockquote: const TextStyle(color: Colors.black54, fontStyle: FontStyle.italic),
      code: const TextStyle(
        fontFamily: 'monospace',
        fontSize: 14,
        backgroundColor: Color(0xFFF5F5F5),
      ),
    ),
  );
}


  Widget _buildSuggestions() {
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: _suggestions.map((text) {
          return OutlinedButton(
            onPressed: () => _sendWithText(text),
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.orange,
              side: BorderSide(color: Colors.orange.withOpacity(0.55)),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            ),
            child: Text(text, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
          );
        }).toList(),
      ),
    );
  }

  Widget _bubble(BuildContext context, Map<String, String> m) {
    final isUser = m['role'] == 'user';
    final text = (m['text'] ?? '').trim();

    if (isUser) {
      return Align(
        alignment: Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 10),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          constraints: const BoxConstraints(maxWidth: 360),
          decoration: BoxDecoration(
            color: _accent.withOpacity(0.75), // dùng tone app
            borderRadius: BorderRadius.circular(16),
          ),
          child: Text(
            text,
            softWrap: true,
            overflow: TextOverflow.visible,
            style: const TextStyle(fontSize: 15, height: 1.4, letterSpacing: 0.1, color: Colors.black87),
          ),
        ),
      );
    }

    return Padding(
      padding: const EdgeInsets.only(top: 6, bottom: 14, right: 24),
      child: _buildMarkdownText(context, text.isEmpty ? "…" : text),
    );
  }
  Widget _buildHeader() {
  return Container(
    padding: const EdgeInsets.all(16),
    decoration: const BoxDecoration(
      color: Colors.white,
      boxShadow: [BoxShadow(color: Colors.black12, blurRadius: 4)],
    ),
    child: Row(
      children: [
        IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        const SizedBox(width: 6),
        const Text(
          "Lingua Coach",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const Spacer(),
        IconButton(
          icon: const Icon(Icons.menu),
          onPressed: () {
          },
        ),
      ],
    ),
  );
}




  Widget _inputBar() {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.10),
          border: const Border(top: BorderSide(color: Color(0x11000000))),
        ),
        child: Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(color: Colors.black12),
                ),
                child: TextField(
                  controller: _ctl,
                  onSubmitted: (_) => _send(),
                  decoration: const InputDecoration(
                    hintText: 'Type your question...',
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            InkWell(
              onTap: _send,
              borderRadius: BorderRadius.circular(999),
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.orange.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.send, color: Colors.orange),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Lingua Coach', style: TextStyle(fontWeight: FontWeight.w800)),
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              controller: _scroll,
              padding: const EdgeInsets.all(16),
              itemCount: _messages.length + (_loading ? 1 : 0),
              itemBuilder: (_, i) {
                if (i >= _messages.length) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(vertical: 6),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: Text('Typing...', style: TextStyle(color: Colors.grey)),
                    ),
                  );
                }
                final w = _bubble(context,_messages[i]);
                final showSuggestions = (_messages.length == 1 && i == 0);
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    w,
                    if (showSuggestions) _buildSuggestions(),
                  ],
                );
              },
            ),
          ),
          _inputBar(),
        ],
      ),
    );
  }
}
