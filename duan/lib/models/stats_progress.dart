import 'due_cards_detail.dart';

class StatsProgress {
  final int days;
  final List<DailyProgress> daily;
  final List<ReviewEvent> recent;

  StatsProgress({
    required this.days,
    required this.daily,
    required this.recent,
  });

  factory StatsProgress.fromJson(Map<String, dynamic> json) {
    return StatsProgress(
      days: (json['days'] as num?)?.toInt() ?? 0,
      daily: ((json['daily'] as List?) ?? [])
          .map((e) => DailyProgress.fromJson(e as Map<String, dynamic>))
          .toList(),
      recent: ((json['recent'] as List?) ?? [])
          .map((e) => ReviewEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DailyProgress {
  final String day; // YYYY-MM-DD (UTC)
  final int reviews;
  final int goodEasy;
  final int xp;
  final double successRate;

  DailyProgress({
    required this.day,
    required this.reviews,
    required this.goodEasy,
    required this.xp,
    required this.successRate,
  });

  factory DailyProgress.fromJson(Map<String, dynamic> json) {
    return DailyProgress(
      day: (json['day'] as String?) ?? '',
      reviews: (json['reviews'] as num?)?.toInt() ?? 0,
      goodEasy: (json['good_easy'] as num?)?.toInt() ?? 0,
      xp: (json['xp'] as num?)?.toInt() ?? 0,
      successRate: (json['success_rate'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class ReviewEvent {
  final String ts; // ISO UTC 'Z'
  final String cardId;
  final int rating;
  final DueCardMatch? match; // DueCardMatch | null

  ReviewEvent({
    required this.ts,
    required this.cardId,
    required this.rating,
    this.match,
  });

  factory ReviewEvent.fromJson(Map<String, dynamic> json) {
    return ReviewEvent(
      ts: (json['ts'] as String?) ?? '',
      cardId: (json['cardId'] as String?) ?? '',
      rating: (json['rating'] as num?)?.toInt() ?? 0,
      match: json['match'] == null
          ? null
          : DueCardMatch.fromJson(json['match'] as Map<String, dynamic>),
    );
  }
}
