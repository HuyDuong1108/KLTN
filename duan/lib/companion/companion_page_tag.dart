import 'package:flutter/material.dart';
import 'companion_context.dart';

/// Wrap body của một page để tự động báo cho companion biết user đang ở đâu.
///
/// Ví dụ:
/// ```dart
/// body: CompanionPageTag(
///   label: "Flashcard — Cộng đồng",
///   child: yourBodyHere,
/// ),
/// ```
///
/// Khi page này mount → setCurrentPage(label).
/// Khi dispose → chỉ clear nếu page này vẫn là page hiện tại
/// (tránh ghi đè lên page khác đã set trong lúc transition).
class CompanionPageTag extends StatefulWidget {
  final String label;
  final Widget child;

  const CompanionPageTag({
    super.key,
    required this.label,
    required this.child,
  });

  @override
  State<CompanionPageTag> createState() => _CompanionPageTagState();
}

class _CompanionPageTagState extends State<CompanionPageTag> {
  @override
  void initState() {
    super.initState();
    CompanionContextService.instance.setCurrentPage(widget.label);
  }

  @override
  void didUpdateWidget(covariant CompanionPageTag oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.label != widget.label) {
      CompanionContextService.instance.setCurrentPage(widget.label);
    }
  }

  @override
  void dispose() {
    final ctx = CompanionContextService.instance;
    if (ctx.currentPage == widget.label) {
      ctx.setCurrentPage(null);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
