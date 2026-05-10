class CompanionMessage {
  final String role; // "user" | "model"
  final String content;
  final DateTime createdAt;
  final List<String> suggestions;

  CompanionMessage({
    required this.role,
    required this.content,
    DateTime? createdAt,
    this.suggestions = const [],
  }) : createdAt = createdAt ?? DateTime.now();

  bool get isUser => role == "user";

  Map<String, dynamic> toApiJson() => {
        "role": role,
        "content": content,
      };

  Map<String, dynamic> toFirestore() => {
        "role": role,
        "content": content,
        "createdAt": createdAt.millisecondsSinceEpoch,
        "suggestions": suggestions,
      };

  static CompanionMessage fromFirestore(Map<String, dynamic> data) {
    return CompanionMessage(
      role: (data["role"] ?? "model").toString(),
      content: (data["content"] ?? "").toString(),
      createdAt: data["createdAt"] is int
          ? DateTime.fromMillisecondsSinceEpoch(data["createdAt"] as int)
          : DateTime.now(),
      suggestions: (data["suggestions"] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }
}
