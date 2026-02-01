class DueBucket {
  final String day;
  final int count;

  DueBucket({required this.day, required this.count});

  factory DueBucket.fromJson(Map<String, dynamic> json) {
    return DueBucket(
      day: (json['day'] ?? '').toString(),
      count: (json['count'] is num)
          ? (json['count'] as num).toInt()
          : int.tryParse((json['count'] ?? '0').toString()) ?? 0,
    );
  }
}

class StatsSummary {
  final int cardsTotal;
  final Map<String, int> cardsByState;
  final int dueNow;
  final int dueToday;
  final List<DueBucket> dueNext7d;

  final int reviewsTotal;
  final Map<String, int> reviewsByRating;
  final int reviewsLast7d;
  final double successRate7d;

  final int daysActiveTotal;
  final int streakCurrent;
  final int xpTotal;
  final double successRateAllTime;

  // (optional) nếu backend có trả thêm
  final int? streakLevel;
  final int? horizonDays;

  StatsSummary({
    required this.cardsTotal,
    required this.cardsByState,
    required this.dueNow,
    required this.dueToday,
    required this.dueNext7d,
    required this.reviewsTotal,
    required this.reviewsByRating,
    required this.reviewsLast7d,
    required this.successRate7d,
    required this.daysActiveTotal,
    required this.streakCurrent,
    required this.xpTotal,
    required this.successRateAllTime,
    this.streakLevel,
    this.horizonDays,
  });

  static int _readInt(Map<String, dynamic> j, String a, String b) {
    final v = j[a] ?? j[b];
    if (v == null) return 0;
    if (v is num) return v.toInt();
    return int.tryParse(v.toString()) ?? 0;
  }

  static double _readDouble(Map<String, dynamic> j, String a, String b) {
    final v = j[a] ?? j[b];
    if (v == null) return 0.0;
    if (v is num) return v.toDouble();
    return double.tryParse(v.toString()) ?? 0.0;
  }

  static Map<String, int> _mapInt(dynamic v) {
  if (v is Map) {
    final out = <String, int>{};
    v.forEach((k, val) {
      if (val is num) {
        out[k.toString()] = val.toInt();
      } else {
        out[k.toString()] = int.tryParse(val?.toString() ?? '') ?? 0;
      }
    });
    return out;
  }
  return {};
}

  factory StatsSummary.fromJson(Map<String, dynamic> json) {
    final rawDue = json['due_next_7d'] ?? json['dueNext7d'];
    final dueList = rawDue is List ? rawDue : const [];
    final dueBuckets = dueList
        .whereType<Map>()
        .map((e) => DueBucket.fromJson(Map<String, dynamic>.from(e)))
        .toList();

    return StatsSummary(
      cardsTotal: _readInt(json, 'cards_total', 'cardsTotal'),
      cardsByState: _mapInt(json['cards_by_state'] ?? json['cardsByState']),
      dueNow: _readInt(json, 'due_now', 'dueNow'),
      dueToday: _readInt(json, 'due_today', 'dueToday'),
      dueNext7d: dueBuckets,

      reviewsTotal: _readInt(json, 'reviews_total', 'reviewsTotal'),
      reviewsByRating: _mapInt(json['reviews_by_rating'] ?? json['reviewsByRating']),
      reviewsLast7d: _readInt(json, 'reviews_last_7d', 'reviewsLast7d'),
      successRate7d: _readDouble(json, 'success_rate_7d', 'successRate7d'),

      daysActiveTotal: _readInt(json, 'days_active_total', 'daysActiveTotal'),
      streakCurrent: _readInt(json, 'streak_current', 'streakCurrent'),
      xpTotal: _readInt(json, 'xp_total', 'xpTotal'),
      successRateAllTime: _readDouble(json, 'success_rate_all_time', 'successRateAllTime'),

      streakLevel: (json['streak_level'] ?? json['streakLevel']) is num
          ? (json['streak_level'] ?? json['streakLevel']).toInt()
          : int.tryParse((json['streak_level'] ?? json['streakLevel'] ?? '').toString()),
      horizonDays: (json['horizon_days'] ?? json['horizonDays']) is num
          ? (json['horizon_days'] ?? json['horizonDays']).toInt()
          : int.tryParse((json['horizon_days'] ?? json['horizonDays'] ?? '').toString()),
    );
  }
}
