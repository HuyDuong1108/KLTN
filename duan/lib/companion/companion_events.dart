/// Các loại sự kiện companion có thể react.
/// Page gọi: `CompanionService.instance.fireEvent(CompanionEventType.testCompleted, payload: {...})`.
class CompanionEventType {
  static const sessionStart = "session_start";
  static const testCompleted = "test_completed";
  static const flashcardReviewed = "flashcard_reviewed";
  static const streakBroken = "streak_broken";
  static const login = "login";
}

/// State của bubble popup hiện bên avatar.
class CompanionBubble {
  final String text;
  final String tone; // "happy" | "neutral" | "sad" | "proud"
  final DateTime createdAt;

  CompanionBubble({
    required this.text,
    required this.tone,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();
}
