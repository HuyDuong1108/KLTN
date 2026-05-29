import 'package:flutter/material.dart';
import '../companion_service.dart';
import '../models/companion_character.dart';

/// Nút floating nhỏ hiện ở góc màn hình — tap để mở chat sheet.
/// Có animation idle (thở nhẹ + bóng đổ pulse).
class CompanionAvatar extends StatefulWidget {
  final VoidCallback onTap;
  const CompanionAvatar({super.key, required this.onTap});

  @override
  State<CompanionAvatar> createState() => _CompanionAvatarState();
}

class _CompanionAvatarState extends State<CompanionAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _breath = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 3),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _breath.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CompanionService.instance,
      builder: (context, _) {
        final c = CompanionService.instance.character;
        return AnimatedBuilder(
          animation: _breath,
          builder: (context, __) {
            final t = _breath.value;
            final scale = 0.96 + 0.04 * t;
            final glow = 8 + 10 * t;
            return Transform.scale(
              scale: scale,
              child: _avatarButton(c, glow),
            );
          },
        );
      },
    );
  }

  Widget _avatarButton(CompanionCharacter c, double glowBlur) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: widget.onTap,
        child: Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [c.primaryColor, c.accentColor],
            ),
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: c.primaryColor.withOpacity(0.45),
                blurRadius: glowBlur,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Center(
            child: Text(
              c.emoji,
              style: const TextStyle(fontSize: 32),
            ),
          ),
        ),
      ),
    );
  }
}
