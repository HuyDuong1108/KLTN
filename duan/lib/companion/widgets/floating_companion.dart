import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../companion_service.dart';
import 'companion_avatar.dart';
import 'companion_chat_sheet.dart';
import 'companion_bubble_popup.dart';
import 'character_picker_sheet.dart';

/// Widget bao quanh app — inject floating avatar + chat sheet phủ lên mọi page.
///
/// Cách wire:
/// ```dart
/// MaterialApp(
///   builder: (ctx, child) => FloatingCompanion(child: child ?? const SizedBox()),
///   ...
/// );
/// ```
///
/// Companion layer chạy trong một `Overlay` riêng nên Tooltip / Dialog / SnackBar
/// bên trong chat sheet không bị crash do thiếu Overlay ancestor.
class FloatingCompanion extends StatefulWidget {
  final Widget child;
  const FloatingCompanion({super.key, required this.child});

  @override
  State<FloatingCompanion> createState() => _FloatingCompanionState();
}

class _FloatingCompanionState extends State<FloatingCompanion> {
  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snap) {
        final loggedIn = snap.data != null;

        return AnimatedBuilder(
          animation: CompanionService.instance,
          builder: (context, _) {
            final show =
                loggedIn && !CompanionService.instance.isSuppressed;
            return Stack(
              children: [
                widget.child,
                if (show)
                  Positioned.fill(
                    child: _CompanionOverlayHost(),
                  ),
              ],
            );
          },
        );
      },
    );
  }
}

/// Host tạo một Overlay riêng cho companion layer, nhờ vậy widget bên trong
/// (Tooltip, Dialog, v.v.) có Overlay ancestor hợp lệ.
class _CompanionOverlayHost extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Overlay(
      initialEntries: [
        OverlayEntry(
          // Để touch xuyên qua các vùng không có avatar/sheet.
          maintainState: true,
          builder: (ctx) => const _CompanionLayer(),
        ),
      ],
    );
  }
}

/// Layer thực tế — listen CompanionService, render avatar + chat sheet.
class _CompanionLayer extends StatefulWidget {
  const _CompanionLayer();

  @override
  State<_CompanionLayer> createState() => _CompanionLayerState();
}

class _CompanionLayerState extends State<_CompanionLayer> {
  Offset? _avatarOffset;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: CompanionService.instance,
      builder: (context, _) {
        final service = CompanionService.instance;
        final screen = MediaQuery.of(context).size;
        const avatarSize = 64.0;
        const padding = 18.0;

        final defaultOffset = Offset(
          screen.width - avatarSize - padding,
          screen.height - avatarSize - padding - 60,
        );
        final offset = _avatarOffset ?? defaultOffset;

        return Stack(
          children: [
            // Lớp "trong suốt" không chặn input bên dưới khi sheet đóng.
            // Mỗi widget con chỉ chiếm vùng của nó → hit test chính xác.

            if (service.isOpen) _buildChatSheet(service, screen),

            // CHARACTER PICKER: overlay đè lên chat sheet khi được mở
            if (service.showCharacterPicker)
              Positioned.fill(
                child: Stack(
                  children: [
                    GestureDetector(
                      onTap: service.closeCharacterPicker,
                      child: Container(color: Colors.black38),
                    ),
                    Align(
                      alignment: Alignment.centerRight,
                      child: CharacterPickerSheet(
                        onClose: service.closeCharacterPicker,
                      ),
                    ),
                  ],
                ),
              ),

            // BUBBLE POPUP: hiện bên trái avatar khi có event proactive
            if (!service.isOpen && service.bubble != null)
              Positioned(
                // đặt bubble căn phải cùng mép phải của avatar, cao hơn avatar một chút
                right: screen.width - (offset.dx + avatarSize),
                top: (offset.dy - 70).clamp(16.0, screen.height - 80),
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 260),
                  switchInCurve: Curves.easeOut,
                  child: Padding(
                    key: ValueKey(service.bubble!.createdAt),
                    padding: const EdgeInsets.only(right: 4, bottom: 6),
                    child: CompanionBubblePopup(bubble: service.bubble!),
                  ),
                ),
              ),

            if (!service.isOpen)
              Positioned(
                left: offset.dx,
                top: offset.dy,
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onPanUpdate: (details) {
                    setState(() {
                      final current = _avatarOffset ?? defaultOffset;
                      _avatarOffset = current + details.delta;
                    });
                  },
                  onPanEnd: (_) {
                    setState(() {
                      final current = _avatarOffset ?? defaultOffset;
                      final dx = current.dx.clamp(
                        padding,
                        screen.width - avatarSize - padding,
                      );
                      final dy = current.dy.clamp(
                        padding + 40,
                        screen.height - avatarSize - padding - 20,
                      );
                      _avatarOffset = Offset(dx, dy);
                    });
                  },
                  child: CompanionAvatar(onTap: service.open),
                ),
              ),
          ],
        );
      },
    );
  }

  Widget _buildChatSheet(CompanionService service, Size screen) {
    return Positioned.fill(
      child: Stack(
        children: [
          // Scrim (mobile only)
          if (screen.width < 600)
            GestureDetector(
              onTap: service.close,
              child: Container(color: Colors.black26),
            ),
          Align(
            alignment: Alignment.centerRight,
            child: CompanionChatSheet(onClose: service.close),
          ),
        ],
      ),
    );
  }
}
