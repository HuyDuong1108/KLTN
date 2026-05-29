import 'package:flutter/material.dart';
import '../companion_service.dart';
import '../companion_events.dart';
import '../models/companion_character.dart';

/// Popup hiện bên avatar khi có event chủ động.
/// - Tap → mở chat sheet với bubble làm message mở đầu
/// - Nút × → dismiss
/// - Tự biến mất sau ~7s (do service timer)
class CompanionBubblePopup extends StatelessWidget {
  final CompanionBubble bubble;
  const CompanionBubblePopup({super.key, required this.bubble});

  Color _toneColor(CompanionCharacter c) {
    switch (bubble.tone) {
      case "proud":
        return const Color(0xFFFFD54F);
      case "sad":
        return const Color(0xFFB0BEC5);
      case "neutral":
        return Colors.white;
      case "happy":
      default:
        return Colors.white;
    }
  }

  IconData _toneIcon() {
    switch (bubble.tone) {
      case "proud":
        return Icons.emoji_events;
      case "sad":
        return Icons.sentiment_dissatisfied;
      case "neutral":
        return Icons.info_outline;
      case "happy":
      default:
        return Icons.auto_awesome;
    }
  }

  @override
  Widget build(BuildContext context) {
    final service = CompanionService.instance;
    final c = service.character;
    final bg = _toneColor(c);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: service.openFromBubble,
        child: Container(
          constraints: const BoxConstraints(maxWidth: 240),
          padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: c.primaryColor.withOpacity(0.35),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: c.primaryColor.withOpacity(0.25),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                _toneIcon(),
                size: 16,
                color: c.primaryColor,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  bubble.text,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    color: Colors.black87,
                  ),
                ),
              ),
              InkWell(
                borderRadius: BorderRadius.circular(10),
                onTap: service.dismissBubble,
                child: Padding(
                  padding: const EdgeInsets.only(left: 6, top: 2),
                  child: Icon(
                    Icons.close,
                    size: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
