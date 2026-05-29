import 'dart:convert';
import 'package:http/http.dart' as http;
import 'models/companion_message.dart';
import 'models/companion_character.dart';
import 'companion_context.dart';

/// HTTP client gọi backend /companion/* endpoints.
class CompanionApi {
  CompanionApi._();
  static final CompanionApi instance = CompanionApi._();

  static const String _baseUrl = "http://127.0.0.1:8000";

  /// Gửi tin nhắn + lịch sử + context, nhận reply AI.
  Future<CompanionChatResult> chat({
    required String uid,
    required String message,
    required CompanionCharacter character,
    required List<CompanionMessage> history,
    required CompanionContextSnapshot context,
    String? memorySummary,
  }) async {
    final uri = Uri.parse("$_baseUrl/companion/chat");

    final body = jsonEncode({
      "uid": uid,
      "message": message,
      "character_id": character.id,
      "character_prompt": character.systemPrompt,
      "history": history.map((m) => m.toApiJson()).toList(),
      "context": context.toJson(),
      if (memorySummary != null && memorySummary.isNotEmpty)
        "memory_summary": memorySummary,
    });

    final res = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "X-User-Id": uid,
      },
      body: body,
    );

    if (res.statusCode != 200) {
      throw CompanionApiException(
        "chat failed: ${res.statusCode} ${res.body}",
      );
    }

    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return CompanionChatResult(
      reply: (data["reply"] ?? "").toString(),
      suggestions: (data["suggestions"] as List?)
              ?.map((e) => e.toString())
              .toList() ??
          const [],
    );
  }

  /// Tóm tắt các message cũ thành 1 đoạn memory (Phase 3).
  Future<String> summarize({
    required String uid,
    required CompanionCharacter character,
    required List<CompanionMessage> messages,
    String? previousSummary,
  }) async {
    final uri = Uri.parse("$_baseUrl/companion/summarize");

    final body = jsonEncode({
      "uid": uid,
      "character_prompt": character.systemPrompt,
      if (previousSummary != null && previousSummary.isNotEmpty)
        "previous_summary": previousSummary,
      "messages": messages.map((m) => m.toApiJson()).toList(),
    });

    final res = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "X-User-Id": uid,
      },
      body: body,
    );

    if (res.statusCode != 200) {
      throw CompanionApiException(
        "summarize failed: ${res.statusCode} ${res.body}",
      );
    }

    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return (data["summary"] ?? "").toString();
  }

  /// Phản ứng chủ động theo event (Phase 4).
  Future<CompanionReactResult> react({
    required String uid,
    required String eventType,
    required Map<String, dynamic> payload,
    required CompanionCharacter character,
    required CompanionContextSnapshot context,
  }) async {
    final uri = Uri.parse("$_baseUrl/companion/react");

    final body = jsonEncode({
      "uid": uid,
      "event_type": eventType,
      "payload": payload,
      "character_id": character.id,
      "character_prompt": character.systemPrompt,
      "context": context.toJson(),
    });

    final res = await http.post(
      uri,
      headers: {
        "Content-Type": "application/json",
        "X-User-Id": uid,
      },
      body: body,
    );

    if (res.statusCode != 200) {
      throw CompanionApiException(
        "react failed: ${res.statusCode} ${res.body}",
      );
    }

    final data = jsonDecode(utf8.decode(res.bodyBytes)) as Map<String, dynamic>;
    return CompanionReactResult(
      bubble: (data["bubble"] ?? "").toString(),
      tone: (data["tone"] ?? "neutral").toString(),
    );
  }
}

class CompanionChatResult {
  final String reply;
  final List<String> suggestions;
  CompanionChatResult({required this.reply, required this.suggestions});
}

class CompanionReactResult {
  final String bubble;
  final String tone;
  CompanionReactResult({required this.bubble, required this.tone});
}

class CompanionApiException implements Exception {
  final String message;
  CompanionApiException(this.message);
  @override
  String toString() => "CompanionApiException: $message";
}
