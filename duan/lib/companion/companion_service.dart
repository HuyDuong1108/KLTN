import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models/companion_message.dart';
import 'models/companion_character.dart';
import 'companion_api.dart';
import 'companion_context.dart';
import 'companion_memory_store.dart';
import 'companion_events.dart';
import 'voice/companion_voice.dart';

/// Singleton + ChangeNotifier quản lý state của companion.
/// UI listen vào service này qua AnimatedBuilder / ListenableBuilder.
class CompanionService extends ChangeNotifier {
  CompanionService._();
  static final CompanionService instance = CompanionService._();

  // ----------------- state -----------------
  CompanionCharacter _character = CompanionCharacter.mira;
  final List<CompanionMessage> _messages = [];
  bool _isOpen = false;
  bool _isSending = false;
  bool _hasGreeted = false;
  bool _suppressed = false;

  // Memory (Phase 3)
  String _memorySummary = "";
  bool _historyLoaded = false;
  bool _isLoadingHistory = false;
  String? _loadedForUid;

  // Proactive (Phase 4)
  CompanionBubble? _bubble;
  Timer? _bubbleTimer;
  final Map<String, DateTime> _lastEventAt = {};
  static const _bubbleAutoDismiss = Duration(seconds: 7);
  static const _eventDedupWindow = Duration(minutes: 5);

  // Character picker UI (Phase 5)
  bool _showCharacterPicker = false;

  // Voice / streaming (Phase 6)
  bool _autoSpeak = false;
  bool _isStreaming = false;

  // Ngưỡng kích hoạt tóm tắt (xem comment ở _maybeSummarize)
  static const int _summarizeTriggerCount = 40;
  static const int _keepRecentWhenSummarize = 20;

  String? _errorMessage;

  // getters
  CompanionCharacter get character => _character;
  List<CompanionMessage> get messages => List.unmodifiable(_messages);
  bool get isOpen => _isOpen;
  bool get isSending => _isSending;
  bool get isSuppressed => _suppressed;
  bool get isLoadingHistory => _isLoadingHistory;
  String get memorySummary => _memorySummary;
  String? get errorMessage => _errorMessage;
  CompanionBubble? get bubble => _bubble;
  bool get showCharacterPicker => _showCharacterPicker;
  bool get autoSpeak => _autoSpeak;
  bool get isStreaming => _isStreaming;

  void openCharacterPicker() {
    _showCharacterPicker = true;
    notifyListeners();
  }

  void closeCharacterPicker() {
    _showCharacterPicker = false;
    notifyListeners();
  }

  void setAutoSpeak(bool v) {
    if (_autoSpeak == v) return;
    _autoSpeak = v;
    notifyListeners();
  }

  /// Dùng cho các màn hình không muốn companion hiện.
  void setSuppressed(bool value) {
    if (_suppressed == value) return;
    _suppressed = value;
    if (value) _isOpen = false;
    notifyListeners();
  }

  // ----------------- character -----------------
  Future<void> setCharacter(CompanionCharacter c) async {
    if (_character.id == c.id) return;
    _character = c;

    // Chèn 1 transition message từ nhân vật mới để user thấy rõ đã đổi.
    final transitionMsg = CompanionMessage(
      role: "model",
      content: c.transitionMessage,
      suggestions: const ["Giới thiệu bản thân", "Mình học gì giờ?"],
    );
    _messages.add(transitionMsg);
    _hasGreeted = true;

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) {
      // Persist character + transition message (non-blocking)
      CompanionMemoryStore.instance
          .saveCharacter(uid, c.id)
          .catchError((_) {});
      CompanionMemoryStore.instance
          .appendMessage(uid, transitionMsg)
          .catchError((_) => "");
    }
    notifyListeners();
  }

  // ----------------- open/close sheet -----------------
  void open() {
    _isOpen = true;
    _ensureHistoryLoaded();
    notifyListeners();
  }

  void close() {
    _isOpen = false;
    // Dừng TTS khi đóng sheet để không đọc tiếp trong nền
    CompanionVoice.instance.stopSpeaking();
    CompanionVoice.instance.stopListening();
    notifyListeners();
  }

  void toggle() {
    _isOpen ? close() : open();
  }

  /// Lazy load: lần đầu mở sheet với uid này sẽ fetch từ Firestore.
  Future<void> _ensureHistoryLoaded() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    if (_historyLoaded && _loadedForUid == user.uid) return;
    if (_isLoadingHistory) return;

    _isLoadingHistory = true;
    notifyListeners();

    try {
      // Load profile + recent messages song song
      final results = await Future.wait([
        CompanionMemoryStore.instance.loadProfile(user.uid),
        CompanionMemoryStore.instance.loadRecent(user.uid, limit: 20),
      ]);
      final profile = results[0] as CompanionProfile;
      final history = results[1] as List<CompanionMessage>;

      _memorySummary = profile.memorySummary;
      if (profile.characterId != null) {
        _character = CompanionCharacter.byId(profile.characterId!);
      }
      _messages
        ..clear()
        ..addAll(history);

      _historyLoaded = true;
      _loadedForUid = user.uid;

      // Chỉ show greeting khi thực sự chưa có tin nào
      if (_messages.isEmpty && !_hasGreeted) {
        _addGreeting();
      }
    } catch (e) {
      _errorMessage = "Không tải được lịch sử chat: $e";
    } finally {
      _isLoadingHistory = false;
      notifyListeners();
    }
  }

  void _addGreeting() {
    _messages.add(CompanionMessage(
      role: "model",
      content: _character.greeting,
      suggestions: const [
        "Luyện từ vựng",
        "Chữa ngữ pháp",
        "Mình nên học gì?",
      ],
    ));
    _hasGreeted = true;
  }

  // ----------------- messaging -----------------
  Future<void> sendMessage(String text) async {
    final trimmed = text.trim();
    if (trimmed.isEmpty || _isSending) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      _errorMessage = "Bạn cần đăng nhập để dùng companion.";
      notifyListeners();
      return;
    }

    final userMsg = CompanionMessage(role: "user", content: trimmed);
    _messages.add(userMsg);
    _isSending = true;
    _errorMessage = null;
    notifyListeners();

    // Persist user message vào Firestore (non-blocking — chat vẫn tiếp tục nếu fail)
    CompanionMemoryStore.instance
        .appendMessage(user.uid, userMsg)
        .catchError((_) => "");

    try {
      final ctx = await CompanionContextService.instance.collect();

      // History gửi lên API: tất cả messages trước tin vừa add
      // KHÔNG bao gồm greeting (là tin đầu nếu có)
      List<CompanionMessage> historyForApi;
      if (_messages.isNotEmpty &&
          _messages.first.role == "model" &&
          _messages.length == 2) {
        // chỉ có greeting + user msg vừa gửi → history rỗng
        historyForApi = const [];
      } else {
        historyForApi = _messages.take(_messages.length - 1).toList();
        // Bỏ greeting khỏi history nếu là tin đầu
        if (historyForApi.isNotEmpty &&
            historyForApi.first.role == "model" &&
            historyForApi.first.content == _character.greeting) {
          historyForApi = historyForApi.skip(1).toList();
        }
      }

      final result = await CompanionApi.instance.chat(
        uid: user.uid,
        message: trimmed,
        character: _character,
        history: historyForApi,
        context: ctx,
        memorySummary: _memorySummary.isEmpty ? null : _memorySummary,
      );

      final fullText = result.reply;
      final suggestions = result.suggestions;
      final createdAt = DateTime.now();

      // Persist NGAY bản đầy đủ vào Firestore (không cần đợi reveal xong)
      final finalAiMsg = CompanionMessage(
        role: "model",
        content: fullText,
        suggestions: suggestions,
        createdAt: createdAt,
      );
      CompanionMemoryStore.instance
          .appendMessage(user.uid, finalAiMsg)
          .catchError((_) => "");

      // Auto-speak bắt đầu ngay với full text — độc lập với reveal
      if (_autoSpeak && fullText.trim().isNotEmpty) {
        CompanionVoice.instance.speak(fullText);
      }

      // Fake streaming: chèn 1 placeholder rỗng rồi reveal theo chunk
      _isSending = false;
      _isStreaming = true;
      _messages.add(CompanionMessage(
        role: "model",
        content: "",
        createdAt: createdAt,
      ));
      notifyListeners();

      const chunkSize = 4;
      const tickDuration = Duration(milliseconds: 22);
      int i = chunkSize;
      while (i < fullText.length) {
        await Future.delayed(tickDuration);
        _messages[_messages.length - 1] = CompanionMessage(
          role: "model",
          content: fullText.substring(0, i),
          createdAt: createdAt,
        );
        notifyListeners();
        i += chunkSize;
      }

      // Final frame: full text + suggestions
      _messages[_messages.length - 1] = finalAiMsg;
      _isStreaming = false;
      notifyListeners();

      // Trigger summarize background (không block user)
      unawaited(_maybeSummarize(user.uid));
      return;
    } on CompanionApiException catch (e) {
      _messages.add(CompanionMessage(
        role: "model",
        content: "(Xin lỗi, mình đang không kết nối được với server 🥲)",
      ));
      _errorMessage = e.message;
    } catch (e) {
      _messages.add(CompanionMessage(
        role: "model",
        content: "(Lỗi không xác định, bạn thử lại sau nhé)",
      ));
      _errorMessage = "$e";
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  /// Khi tổng số message trong Firestore > threshold:
  /// - Lấy các message cũ hơn 20 tin mới nhất
  /// - Gọi backend tóm tắt (gộp với summary cũ nếu có)
  /// - Lưu summary mới, xoá message cũ
  Future<void> _maybeSummarize(String uid) async {
    try {
      final count = await CompanionMemoryStore.instance.countMessages(uid);
      if (count <= _summarizeTriggerCount) return;

      final older = await CompanionMemoryStore.instance.loadOlderThanRecent(
        uid,
        keepRecent: _keepRecentWhenSummarize,
      );
      if (older.isEmpty) return;

      final newSummary = await CompanionApi.instance.summarize(
        uid: uid,
        character: _character,
        messages: older,
        previousSummary: _memorySummary.isEmpty ? null : _memorySummary,
      );

      if (newSummary.trim().isNotEmpty) {
        _memorySummary = newSummary.trim();
        await CompanionMemoryStore.instance
            .saveMemorySummary(uid, _memorySummary);
        await CompanionMemoryStore.instance.deleteOlderThanRecent(
          uid,
          keepRecent: _keepRecentWhenSummarize,
        );
      }
    } catch (_) {
      // Non-fatal: lần sau trigger lại.
    }
  }

  Future<void> clearConversation() async {
    final user = FirebaseAuth.instance.currentUser;
    _messages.clear();
    _memorySummary = "";
    _hasGreeted = false;
    _errorMessage = null;
    _addGreeting();
    notifyListeners();

    if (user != null) {
      try {
        await CompanionMemoryStore.instance.clearAll(user.uid);
      } catch (_) {
        // non-fatal
      }
    }
  }

  /// Reset hoàn toàn khi đăng xuất — KHÔNG xoá Firestore, chỉ clear local state.
  void onLogout() {
    _messages.clear();
    _hasGreeted = false;
    _isOpen = false;
    _errorMessage = null;
    _memorySummary = "";
    _historyLoaded = false;
    _loadedForUid = null;
    _character = CompanionCharacter.mira;
    _bubble = null;
    _bubbleTimer?.cancel();
    _lastEventAt.clear();
    _autoSpeak = false;
    _isStreaming = false;
    CompanionVoice.instance.stopSpeaking();
    CompanionVoice.instance.stopListening();
    CompanionContextService.instance.clearCache();
    notifyListeners();
  }

  // ----------------- Proactive events (Phase 4) -----------------

  /// Page bắn event — companion gọi backend /companion/react để lấy
  /// bubble ngắn, hiện cạnh avatar trong ~7s. Tự dedup để tránh spam.
  Future<void> fireEvent(
    String eventType, {
    Map<String, dynamic>? payload,
    bool force = false,
  }) async {
    if (_suppressed) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final now = DateTime.now();
    if (!force) {
      final last = _lastEventAt[eventType];
      if (last != null && now.difference(last) < _eventDedupWindow) {
        return; // Cùng event vừa fire gần đây — bỏ qua
      }
    }
    _lastEventAt[eventType] = now;

    try {
      final ctx = await CompanionContextService.instance.collect();
      final result = await CompanionApi.instance.react(
        uid: user.uid,
        eventType: eventType,
        payload: payload ?? const {},
        character: _character,
        context: ctx,
      );

      if (result.bubble.trim().isEmpty) return;
      _showBubble(result.bubble.trim(), result.tone);
    } catch (_) {
      // Non-fatal, không làm gián đoạn user flow
    }
  }

  void _showBubble(String text, String tone) {
    _bubble = CompanionBubble(text: text, tone: tone);
    _bubbleTimer?.cancel();
    _bubbleTimer = Timer(_bubbleAutoDismiss, () {
      _bubble = null;
      notifyListeners();
    });
    notifyListeners();
  }

  void dismissBubble() {
    if (_bubble == null) return;
    _bubble = null;
    _bubbleTimer?.cancel();
    notifyListeners();
  }

  /// User tap bubble → mở chat sheet và giữ bubble là lời chào mở màn
  /// (append vào messages để user thấy bubble đã nói gì).
  Future<void> openFromBubble() async {
    final b = _bubble;
    if (b != null) {
      // Chèn bubble message vào danh sách để tiếp nối cuộc trò chuyện
      _messages.add(CompanionMessage(
        role: "model",
        content: b.text,
        suggestions: const [],
      ));
      final uid = FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) {
        CompanionMemoryStore.instance
            .appendMessage(uid, _messages.last)
            .catchError((_) => "");
      }
    }
    _bubble = null;
    _bubbleTimer?.cancel();
    open();
  }
}

