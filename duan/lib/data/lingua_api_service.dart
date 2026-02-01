// lib/data/lingua_api_service.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

const String kLinguaBaseUrl = 'http://127.0.0.1:8000';

class SrsReviewResponse {
  final String cardId;
  final dynamic due;
  final String state;
  final Map<String, dynamic> cardJson;

  SrsReviewResponse({
    required this.cardId,
    required this.due,
    required this.state,
    required this.cardJson,
  });

  factory SrsReviewResponse.fromJson(Map<String, dynamic> json) {
    final cj = json['card_json'];

    Map<String, dynamic> cardJsonMap = {};
    if (cj is String) {
      try {
        final parsed = jsonDecode(cj);
        if (parsed is Map<String, dynamic>) {
          cardJsonMap = parsed;
        } else if (parsed is Map) {
          cardJsonMap = Map<String, dynamic>.from(parsed);
        }
      } catch (_) {
        cardJsonMap = {};
      }
    } else if (cj is Map<String, dynamic>) {
      cardJsonMap = cj;
    } else if (cj is Map) {
      cardJsonMap = Map<String, dynamic>.from(cj);
    }

    return SrsReviewResponse(
      cardId: json['cardId'] as String,
      due: json['due'],
      state: json['state'] as String,
      cardJson: cardJsonMap,
    );
  }
}

class LinguaApiService {
  LinguaApiService._();

  static Uri _buildUri(String path) {
    return Uri.parse('$kLinguaBaseUrl$path');
  }

  static String _requireUid() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw Exception('Missing Firebase uid for X-User-Id.');
    }
    return uid;
  }

  /// POST /srs/review
  static Future<SrsReviewResponse> reviewCard({
    required String cardId,
    required int rating,
  }) async {
    final uri = _buildUri('/srs/review');
    final uid = _requireUid();

    final res = await http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        'X-User-Id': uid,
      },
      body: jsonEncode({
        'card_id': cardId,
        'rating': rating,
      }),
    );

    if (res.statusCode >= 200 && res.statusCode < 300) {
      final data = jsonDecode(res.body) as Map<String, dynamic>;
      return SrsReviewResponse.fromJson(data);
    }

    throw Exception('SRS review failed (${res.statusCode}): ${res.body}');
  }
}
