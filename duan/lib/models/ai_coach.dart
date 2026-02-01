class CoachItem {
  final String title;
  final String detail;

  CoachItem({required this.title, required this.detail});

  factory CoachItem.fromJson(Map<String, dynamic> json) {
    return CoachItem(
      title: (json['title'] ?? '').toString(),
      detail: (json['detail'] ?? '').toString(),
    );
  }
}

class CoachAction {
  final String title;
  final String detail;
  final String cta;
  final String action;

  CoachAction({
    required this.title,
    required this.detail,
    required this.cta,
    required this.action,
  });

  factory CoachAction.fromJson(Map<String, dynamic> json) {
    return CoachAction(
      title: (json['title'] ?? '').toString(),
      detail: (json['detail'] ?? '').toString(),
      cta: (json['cta'] ?? '').toString(),
      action: (json['action'] ?? '').toString(),
    );
  }
}

class AiCoachResponse {
  final List<CoachItem> strengths;
  final List<CoachItem> improvements;
  final CoachAction todayAction;
  final Map<String, dynamic> meta;

  AiCoachResponse({
    required this.strengths,
    required this.improvements,
    required this.todayAction,
    required this.meta,
  });

  factory AiCoachResponse.fromJson(Map<String, dynamic> json) {
    final rawStrengths = json['strengths'];
    final rawImprovements = json['improvements'];

    final strengths = (rawStrengths is List)
        ? rawStrengths
            .whereType<Map>()
            .map((e) => CoachItem.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <CoachItem>[];

    final improvements = (rawImprovements is List)
        ? rawImprovements
            .whereType<Map>()
            .map((e) => CoachItem.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <CoachItem>[];

    final rawToday = json['today_action'] ?? json['todayAction'];
    final todayAction = (rawToday is Map)
        ? CoachAction.fromJson(Map<String, dynamic>.from(rawToday))
        : null;

    final rawMeta = json['meta'];
    final meta = (rawMeta is Map) ? Map<String, dynamic>.from(rawMeta) : <String, dynamic>{};

    return AiCoachResponse(
      strengths: strengths,
      improvements: improvements,
      todayAction: todayAction ??
          CoachAction(title: '', detail: '', cta: '', action: ''),
      meta: meta,
    );
  }
}
