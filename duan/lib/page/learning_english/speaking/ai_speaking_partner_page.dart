import 'package:flutter/material.dart';

class AISpeakingPartnerPage extends StatelessWidget {
  const AISpeakingPartnerPage({super.key});

  // ================= COLORS =================
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color bgColor = Color(0xFFF6FAFF);
  static const Color userBubble = Color(0xFF1976D2);
  static const Color aiBubble = Color(0xFFBBDEFB);
  static const Color textGrey = Color(0xFF607D8B);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,

      // ================= APP BAR =================
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: primaryBlue,
        elevation: 0,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("AI Speaking Partner",
                style: TextStyle(fontWeight: FontWeight.bold)),
            SizedBox(height: 2),
            Text(
              "Mode: IELTS Casual Conversation",
              style: TextStyle(fontSize: 12),
            ),
          ],
        ),
        actions: const [
          Padding(
            padding: EdgeInsets.only(right: 16),
            child: Icon(Icons.settings),
          )
        ],
      ),

      // ================= BODY =================
      body: Column(
        children: [
          _aiIntroCard(),
          const SizedBox(height: 6),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _aiMessage(
                  "Hi! Let’s practice speaking together 😊\n"
                  "Can you tell me about your hometown?",
                ),

                _userMessage(
                  "I come from a small city in the south of Vietnam. "
                  "It is not very crowded but quite peaceful.",
                ),

                _aiMessage(
                  "Nice! 👍 That sounds pleasant.\n"
                  "What do you like most about living there?",
                ),
              ],
            ),
          ),

          _liveSupportPanel(),
          _bottomControlBar(),
        ],
      ),
    );
  }

  // ================= AI INTRO =================
  Widget _aiIntroCard() {
    return Container(
      margin: const EdgeInsets.all(16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: lightBlue,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: const [
          CircleAvatar(
            radius: 24,
            backgroundColor: primaryBlue,
            child: Icon(Icons.smart_toy, color: Colors.white),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              "Speak naturally. Don’t worry about mistakes.\n"
              "I’ll help you improve step by step 💬",
              style: TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  // ================= CHAT BUBBLES =================
  Widget _aiMessage(String text) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14, right: 60),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: aiBubble,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(text),
      ),
    );
  }

  Widget _userMessage(String text) {
    return Align(
      alignment: Alignment.centerRight,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14, left: 60),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: userBubble,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Text(
          text,
          style: const TextStyle(color: Colors.white),
        ),
      ),
    );
  }

  // ================= LIVE SUPPORT =================
  Widget _liveSupportPanel() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 6,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: const [
          Icon(Icons.lightbulb_outline, color: Colors.orange),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              "Tip: Instead of “very peaceful”, try “extremely tranquil”",
              style: TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  // ================= CONTROL BAR =================
  Widget _bottomControlBar() {
    return Container(
      padding: const EdgeInsets.all(14),
      color: Colors.white,
      child: Row(
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.refresh),
            color: textGrey,
          ),
          const Spacer(),

          GestureDetector(
            onLongPressStart: (_) {},
            onLongPressEnd: (_) {},
            child: Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: primaryBlue,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: primaryBlue.withOpacity(0.4),
                    blurRadius: 12,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: const Icon(
                Icons.mic,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),

          const Spacer(),
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.analytics_outlined),
            color: primaryBlue,
          ),
        ],
      ),
    );
  }
}
