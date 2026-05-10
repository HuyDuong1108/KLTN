import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import '../companion_service.dart';
import '../models/companion_message.dart';
import '../models/companion_character.dart';
import '../voice/companion_voice.dart';

/// Panel chat hiện bên phải màn hình (web/tablet) hoặc full chiều ngang (mobile).
class CompanionChatSheet extends StatefulWidget {
  final VoidCallback onClose;
  const CompanionChatSheet({super.key, required this.onClose});

  @override
  State<CompanionChatSheet> createState() => _CompanionChatSheetState();
}

class _CompanionChatSheetState extends State<CompanionChatSheet> {
  final _inputController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Khởi tạo TTS/STT sớm để lần nhấn đầu không bị lag vài trăm ms
    CompanionVoice.instance.ensureInit();
  }

  @override
  void dispose() {
    _inputController.dispose();
    _scrollController.dispose();
    CompanionVoice.instance.stopSpeaking();
    CompanionVoice.instance.stopListening();
    super.dispose();
  }

  Future<void> _showVoicePicker() async {
    await CompanionVoice.instance.ensureInit();
    if (!mounted) return;

    final voices = CompanionVoice.instance.availableVoices;
    final selected = CompanionVoice.instance.selectedVoice;

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: const Text(
            "Chọn giọng đọc",
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          contentPadding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
          content: SizedBox(
            width: 400,
            child: voices.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Colors.orange, size: 36),
                        const SizedBox(height: 10),
                        const Text(
                          "Máy bạn chưa có giọng tiếng Việt.",
                          textAlign: TextAlign.center,
                          style: TextStyle(fontWeight: FontWeight.w600),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          "Cách cài thêm:\n"
                          "• Chrome: bật Google voices từ settings TTS\n"
                          "• Windows: Settings → Time & Language → Speech "
                          "→ Manage voices → Add Tiếng Việt\n"
                          "• Android: Settings → Accessibility → TTS Output",
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.grey.shade700,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  )
                : StatefulBuilder(
                    builder: (ctx, setDialogState) {
                      final current = CompanionVoice.instance.selectedVoice;
                      return SingleChildScrollView(
                        child: Column(
                          children: [
                            for (final v in voices)
                              _VoiceRow(
                                voice: v,
                                isSelected: current?['name'] == v['name'],
                                onSelect: () async {
                                  await CompanionVoice.instance.selectVoice(v);
                                  setDialogState(() {});
                                },
                                onTest: () {
                                  CompanionVoice.instance.speak(
                                    "Xin chào, mình đang thử giọng đọc. "
                                    "Bạn nghe có tự nhiên không?",
                                  );
                                },
                              ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
          actions: [
            if (selected != null)
              Text(
                "Đang dùng: ${selected['name']}",
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Đóng"),
            ),
          ],
        );
      },
    );
  }

  Future<void> _toggleMic() async {
    final voice = CompanionVoice.instance;
    if (voice.isListening) {
      await voice.stopListening();
      return;
    }
    final ok = await voice.startListening(
      onResult: (text, isFinal) {
        setState(() {
          _inputController.text = text;
          _inputController.selection = TextSelection.fromPosition(
            TextPosition(offset: _inputController.text.length),
          );
        });
        if (isFinal && text.trim().isNotEmpty) {
          // Tự gửi khi user dừng nói → tiện cho voice-first UX
          _inputController.clear();
          CompanionService.instance.sendMessage(text);
        }
      },
    );
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "Không dùng được microphone (cần HTTPS trên web hoặc cấp quyền).",
          ),
        ),
      );
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final service = CompanionService.instance;
    final character = service.character;
    final screenWidth = MediaQuery.of(context).size.width;
    final isWide = screenWidth >= 600;
    final sheetWidth = isWide ? 400.0 : screenWidth;

    return AnimatedBuilder(
      animation: service,
      builder: (context, _) {
        _scrollToBottom();
        return Material(
          color: Colors.transparent,
          child: Container(
            width: sheetWidth,
            height: double.infinity,
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.12),
                  blurRadius: 20,
                  offset: const Offset(-4, 0),
                ),
              ],
              borderRadius: isWide
                  ? const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      bottomLeft: Radius.circular(20),
                    )
                  : null,
            ),
            clipBehavior: Clip.antiAlias,
            child: Column(
              children: [
                _buildHeader(character),
                Expanded(child: _buildMessageList(service, character)),
                _buildSuggestions(service),
                _buildInput(service),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader(CompanionCharacter c) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 14, 8, 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c.primaryColor, c.accentColor],
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(c.emoji, style: const TextStyle(fontSize: 22)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  c.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  c.tagline,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            icon: Icon(
              CompanionService.instance.autoSpeak
                  ? Icons.volume_up
                  : Icons.volume_off,
              color: Colors.white,
              size: 20,
            ),
            tooltip: CompanionService.instance.autoSpeak
                ? "Tắt đọc to"
                : "Bật đọc to phản hồi",
            onPressed: () {
              final cur = CompanionService.instance.autoSpeak;
              CompanionService.instance.setAutoSpeak(!cur);
              if (cur) CompanionVoice.instance.stopSpeaking();
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune, color: Colors.white, size: 20),
            tooltip: "Chọn giọng / Test",
            onPressed: _showVoicePicker,
          ),
          IconButton(
            icon: const Icon(Icons.swap_horiz, color: Colors.white, size: 22),
            tooltip: "Đổi nhân vật",
            onPressed: () => CompanionService.instance.openCharacterPicker(),
          ),
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white, size: 20),
            tooltip: "Bắt đầu cuộc trò chuyện mới",
            onPressed: () => CompanionService.instance.clearConversation(),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: widget.onClose,
          ),
        ],
      ),
    );
  }

  Widget _buildMessageList(
    CompanionService service,
    CompanionCharacter character,
  ) {
    return Container(
      color: const Color(0xFFF7F9FC),
      child: ListView.builder(
        controller: _scrollController,
        padding: const EdgeInsets.all(14),
        itemCount: service.messages.length + (service.isSending ? 1 : 0),
        itemBuilder: (context, i) {
          if (i == service.messages.length && service.isSending) {
            return _typingBubble(character);
          }
          final msg = service.messages[i];
          return _messageBubble(msg, character);
        },
      ),
    );
  }

  Widget _messageBubble(CompanionMessage msg, CompanionCharacter c) {
    final isUser = msg.isUser;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment:
            isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          if (!isUser) ...[
            _miniAvatar(c),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Column(
              crossAxisAlignment:
                  isUser ? CrossAxisAlignment.end : CrossAxisAlignment.start,
              children: [
                Container(
                  constraints: const BoxConstraints(maxWidth: 300),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 10,
                  ),
                  decoration: BoxDecoration(
                    color: isUser ? c.primaryColor : Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: const Radius.circular(14),
                      topRight: const Radius.circular(14),
                      bottomLeft: Radius.circular(isUser ? 14 : 4),
                      bottomRight: Radius.circular(isUser ? 4 : 14),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: isUser
                      ? Text(
                          msg.content,
                          style:
                              const TextStyle(color: Colors.white, height: 1.35),
                        )
                      : MarkdownBody(
                          data: msg.content,
                          styleSheet: MarkdownStyleSheet(
                            p: const TextStyle(
                              color: Colors.black87,
                              height: 1.4,
                              fontSize: 14,
                            ),
                            strong: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: c.primaryColor,
                            ),
                          ),
                        ),
                ),
                // Nút đọc to cho AI message (không hiện với user message hoặc khi rỗng)
                if (!isUser && msg.content.trim().isNotEmpty)
                  _SpeakButton(text: msg.content, accent: c.primaryColor),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniAvatar(CompanionCharacter c) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [c.primaryColor, c.accentColor],
        ),
        shape: BoxShape.circle,
      ),
      child: Center(
        child: Text(c.emoji, style: const TextStyle(fontSize: 18)),
      ),
    );
  }

  Widget _typingBubble(CompanionCharacter c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          _miniAvatar(c),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 10,
            ),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
            ),
            child: SizedBox(
              width: 36,
              height: 18,
              child: _TypingDots(color: c.primaryColor),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuggestions(CompanionService service) {
    if (service.messages.isEmpty) return const SizedBox.shrink();
    final last = service.messages.last;
    if (last.isUser || last.suggestions.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
      color: const Color(0xFFF7F9FC),
      child: Wrap(
        spacing: 6,
        runSpacing: 6,
        children: last.suggestions.map((s) {
          return ActionChip(
            label: Text(s, style: const TextStyle(fontSize: 12)),
            backgroundColor: Colors.white,
            side: BorderSide(color: service.character.primaryColor, width: 1),
            labelStyle: TextStyle(color: service.character.primaryColor),
            onPressed: () {
              _inputController.clear();
              service.sendMessage(s);
            },
          );
        }).toList(),
      ),
    );
  }

  Widget _buildInput(CompanionService service) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 8, 12),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Color(0xFFE5E9F0))),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _inputController,
              enabled: !service.isSending,
              minLines: 1,
              maxLines: 4,
              textInputAction: TextInputAction.send,
              onSubmitted: (v) => _handleSend(v),
              decoration: InputDecoration(
                hintText: "Nhắn gì đó với ${service.character.name}...",
                filled: true,
                fillColor: const Color(0xFFF7F9FC),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(22),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          // MIC BUTTON
          AnimatedBuilder(
            animation: CompanionVoice.instance,
            builder: (context, _) {
              final isListening = CompanionVoice.instance.isListening;
              return Material(
                color: isListening
                    ? Colors.red
                    : service.character.primaryColor.withOpacity(0.15),
                shape: const CircleBorder(),
                child: InkWell(
                  customBorder: const CircleBorder(),
                  onTap: service.isSending ? null : _toggleMic,
                  child: SizedBox(
                    width: 42,
                    height: 42,
                    child: Icon(
                      isListening ? Icons.stop : Icons.mic,
                      color: isListening
                          ? Colors.white
                          : service.character.primaryColor,
                      size: 20,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 6),
          // SEND BUTTON
          Material(
            color: service.character.primaryColor,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: service.isSending
                  ? null
                  : () => _handleSend(_inputController.text),
              child: const SizedBox(
                width: 42,
                height: 42,
                child: Icon(Icons.send, color: Colors.white, size: 18),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleSend(String text) {
    final v = text.trim();
    if (v.isEmpty) return;
    _inputController.clear();
    CompanionService.instance.sendMessage(v);
  }
}

class _VoiceRow extends StatelessWidget {
  final Map<String, String> voice;
  final bool isSelected;
  final VoidCallback onSelect;
  final VoidCallback onTest;

  const _VoiceRow({
    required this.voice,
    required this.isSelected,
    required this.onSelect,
    required this.onTest,
  });

  String _qualityLabel(String name) {
    final n = name.toLowerCase();
    if (n.contains('google')) return 'Chất lượng cao';
    if (n.contains('neural') || n.contains('natural')) return 'Neural';
    if (n.contains('online')) return 'Online neural';
    if (n.contains('microsoft') || n.contains('desktop')) return 'Local';
    return '';
  }

  Color _qualityColor(String name) {
    final n = name.toLowerCase();
    if (n.contains('google') ||
        n.contains('neural') ||
        n.contains('natural') ||
        n.contains('online')) {
      return Colors.green;
    }
    return Colors.orange;
  }

  @override
  Widget build(BuildContext context) {
    final name = voice['name'] ?? '';
    final locale = voice['locale'] ?? '';
    final quality = _qualityLabel(name);
    final qColor = _qualityColor(name);

    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: onSelect,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF4FC3F7).withOpacity(0.1)
              : const Color(0xFFF7F9FC),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected
                ? const Color(0xFF4FC3F7)
                : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
              size: 18,
              color: isSelected ? const Color(0xFF4FC3F7) : Colors.grey,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.w600,
                      fontSize: 13,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (quality.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: qColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            quality,
                            style: TextStyle(
                              fontSize: 9,
                              color: qColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      if (quality.isNotEmpty) const SizedBox(width: 6),
                      Text(
                        locale,
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.play_circle_outline, size: 22),
              color: const Color(0xFF4FC3F7),
              tooltip: "Nghe thử",
              onPressed: onTest,
            ),
          ],
        ),
      ),
    );
  }
}

class _SpeakButton extends StatelessWidget {
  final String text;
  final Color accent;
  const _SpeakButton({required this.text, required this.accent});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CompanionVoice.instance,
      builder: (context, _) {
        final isSpeaking = CompanionVoice.instance.isSpeaking;
        return Padding(
          padding: const EdgeInsets.only(top: 4, left: 4),
          child: InkWell(
            borderRadius: BorderRadius.circular(20),
            onTap: () {
              if (isSpeaking) {
                CompanionVoice.instance.stopSpeaking();
              } else {
                CompanionVoice.instance.speak(text);
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    isSpeaking ? Icons.stop_circle : Icons.volume_up_outlined,
                    size: 13,
                    color: accent,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isSpeaking ? "Dừng đọc" : "Nghe",
                    style: TextStyle(
                      fontSize: 11,
                      color: accent,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _TypingDots extends StatefulWidget {
  final Color color;
  const _TypingDots({required this.color});

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _ctl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctl,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: List.generate(3, (i) {
            final t = (_ctl.value - i * 0.2) % 1.0;
            final scale = t < 0.5 ? (0.6 + 0.8 * t) : (1.0 - 0.8 * (t - 0.5));
            return Transform.scale(
              scale: scale.clamp(0.6, 1.0),
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: widget.color,
                  shape: BoxShape.circle,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}
