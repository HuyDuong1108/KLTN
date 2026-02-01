import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';
import '../models/stats_summary.dart';
import '../models/stats_progress.dart';
import '../models/coach_insight.dart';
import '../models/ai_coach.dart';
//thêm 
import '../models/due_cards_detail.dart';

class StatsApi {
  StatsApi._();
  static final StatsApi instance = StatsApi._();

  static const String baseUrl = 'http://127.0.0.1:8000';

  String _requireUid() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw Exception('Missing Firebase uid for X-User-Id.');
    }
    return uid;
  }

  int _tzOffsetMin() => DateTime.now().timeZoneOffset.inMinutes;
  
  Future<DueCardsDetailResponse> fetchDueCardsDetail({
    required String scope, // "now" | "today"
    int limit = 200,
    bool includeCommunity = false,
  }) async {
    final uid = _requireUid();

    final uri = Uri.parse('$baseUrl/stats/due_cards_detail').replace(
      queryParameters: {
        'uid': uid, // NEW fallback
        'scope': scope,
        'limit': '$limit',
        'tz_offset_min': '${_tzOffsetMin()}',
        'includeCommunity': includeCommunity ? 'true' : 'false',
      },
    );

    final res = await http.get(uri, headers: {'X-User-Id': uid});

    if (res.statusCode != 200) {
      throw Exception('GET /stats/due_cards_detail failed: ${res.statusCode} ${res.body}');
    }

    final Map<String, dynamic> data = json.decode(res.body);
    return DueCardsDetailResponse.fromJson(data);
  }

  Future<StatsSummary> fetchSummary({int horizonDays = 7}) async {
    final uid = _requireUid();
    final tzOffsetMin = DateTime.now().timeZoneOffset.inMinutes;
    final uri = Uri.parse('$baseUrl/stats/summary').replace(
      queryParameters: {
        'horizonDays': '$horizonDays',
        'tz_offset_min': '${_tzOffsetMin()}',
      },
    );

    final res = await http.get(uri, headers: {'X-User-Id': uid});

    if (res.statusCode != 200) {
      throw Exception('GET /stats/summary failed: ${res.statusCode} ${res.body}');
    }

    final Map<String, dynamic> data = json.decode(res.body);
    return StatsSummary.fromJson(data);
  }

  Future<StatsProgress> fetchProgress({int days = 1, int recent = 100}) async {
    final uid = _requireUid();

    final uri = Uri.parse('$baseUrl/stats/progress').replace(
      queryParameters: {
        'days': '$days',
        'recent': '$recent',
        'tz_offset_min': '${_tzOffsetMin()}',
      },
    );

    final res = await http.get(uri, headers: {'X-User-Id': uid});

    if (res.statusCode != 200) {
      throw Exception('GET /stats/progress failed: ${res.statusCode} ${res.body}');
    }

    final Map<String, dynamic> data = json.decode(res.body);
    return StatsProgress.fromJson(data);
  }
  Future<CoachInsight> fetchCoachInsights({int horizonDays = 7}) async {
    final uid = _requireUid();
    final uri = Uri.parse('$baseUrl/ai/coach/insights').replace(
      queryParameters: {
        'horizon_days': '$horizonDays',
        'tz_offset_min': '${_tzOffsetMin()}',
      },
    );

    final res = await http.get(uri, headers: {'X-User-Id': uid});
    if (res.statusCode != 200) {
      throw Exception('GET /ai/coach/insights failed: ${res.statusCode} ${res.body}');
    }
    final Map<String, dynamic> data = json.decode(res.body);
    return CoachInsight.fromJson(data);
}

Future<String> coachChat({
  required String question,
  int horizonDays = 7,
}) async {
  final uid = _requireUid();
  final uri = Uri.parse('$baseUrl/ai/coach/chat');

  final body = jsonEncode({
    'question': question,
    'horizon_days': horizonDays,
    'tz_offset_min': _tzOffsetMin(),
  });

  final res = await http.post(
    uri,
    headers: {
      'X-User-Id': uid,
      'Content-Type': 'application/json',
    },
    body: body,
  );

  if (res.statusCode != 200) {
    throw Exception('POST /ai/coach/chat failed: ${res.statusCode} ${res.body}');
  }

  final Map<String, dynamic> data = json.decode(res.body);
  return (data['answer'] ?? '').toString();
}
Future<AiCoachResponse> fetchAiCoach({int horizonDays = 7}) async {
    final uid = _requireUid();

    final uri = Uri.parse('$baseUrl/ai/learning/coach').replace(
      queryParameters: {
        'horizonDays': '$horizonDays',
        'tzOffsetMin': '${_tzOffsetMin()}',
      },
    );

    final res = await http.get(uri, headers: {'X-User-Id': uid});

    if (res.statusCode != 200) {
      throw Exception('GET /ai/learning/coach failed: ${res.statusCode} ${res.body}');
    }

    final Map<String, dynamic> data = json.decode(res.body);
    return AiCoachResponse.fromJson(data);
  }
}
