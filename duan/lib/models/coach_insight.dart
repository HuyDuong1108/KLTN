class CoachInsight {
  final String headline;
  final String strength;
  final String weakness;
  final String action;
  final List<String> suggestedQuestions;

  CoachInsight({
    required this.headline,
    required this.strength,
    required this.weakness,
    required this.action,
    required this.suggestedQuestions,
  });

  factory CoachInsight.fromJson(Map<String, dynamic> json) {
    final raw = json['suggested_questions'];
    final list = (raw is List) ? raw.map((e) => e.toString()).toList() : <String>[];
    return CoachInsight(
      headline: (json['headline'] ?? '').toString(),
      strength: (json['strength'] ?? '').toString(),
      weakness: (json['weakness'] ?? '').toString(),
      action: (json['action'] ?? '').toString(),
      suggestedQuestions: list,
    );
  }
}
