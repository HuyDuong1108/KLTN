import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../data/ai_partner_gemini_service.dart';
import '../../../data/ai_partner_store.dart';
import '../../../data/google_cloud_speech_service.dart';
import '../../../models/ai_partner_session.dart';
import '../../../models/ai_partner_profile.dart';
import '../../../models/conversation_turn.dart';
import 'ai_partner_review_page.dart';

//
// Phase enum
//
enum _Phase { topicSelection, conversation, result }

//
// Chat message model (UI only)
//
class _ChatMessage {
  final bool isAi;
  final String text;
  final bool isTyping;
  _ChatMessage({required this.isAi, required this.text, this.isTyping = false});
}

//
// Default IELTS topics
//
const List<Map<String, dynamic>> _kDefaultTopics = [
  {'label': 'Work & Career', 'icon': Icons.work_outline},
  {'label': 'Family & Relationships', 'icon': Icons.people_outline},
  {'label': 'Technology', 'icon': Icons.computer_outlined},
  {'label': 'Education', 'icon': Icons.school_outlined},
  {'label': 'Environment', 'icon': Icons.eco_outlined},
  {'label': 'Travel & Places', 'icon': Icons.travel_explore_outlined},
  {'label': 'Sports & Health', 'icon': Icons.sports_soccer_outlined},
  {'label': 'Culture & Traditions', 'icon': Icons.museum_outlined},
  {'label': 'Food & Cuisine', 'icon': Icons.restaurant_outlined},
];

//
// Main widget
//
class AISpeakingPartnerPage extends StatefulWidget {
  const AISpeakingPartnerPage({super.key});

  @override
  State<AISpeakingPartnerPage> createState() => _AISpeakingPartnerPageState();
}

class _AISpeakingPartnerPageState extends State<AISpeakingPartnerPage>
    with TickerProviderStateMixin {
  //  Colors
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color teal = Color(0xFF00897B);
  static const Color bgColor = Color(0xFFF6FAFF);
  static const Color aiBubbleColor = Color(0xFFE0F2F1);
  static const Color userBubbleColor = Color(0xFF1976D2);
  static const Color textGrey = Color(0xFF607D8B);

  //  Services
  final _gemini = AiPartnerGeminiService.instance;
  final _store = AiPartnerStore.instance;
  final _cloudSpeech = GoogleCloudSpeechService.instance;
  final FlutterTts _tts = FlutterTts();

  //  Phase
  _Phase _phase = _Phase.topicSelection;

  //  Topic selection
  String _selectedTopic = '';
  bool _isFreeMode = false;
  List<String> _geminiTopics = [];
  bool _loadingGeminiTopics = false;
  bool _checkingResume = true;

  //  Profile
  AiPartnerProfile _profile = AiPartnerProfile.empty();

  //  Conversation
  final List<_ChatMessage> _messages = [];
  final List<ConversationTurn> _completedTurns = [];
  final ScrollController _scrollCtrl = ScrollController();
  int _turnCount = 0;
  static const int _maxTurns = 5;
  static const int _maxSeconds = 300;
  int _timerSeconds = _maxSeconds;
  Timer? _countdownTimer;
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isSpeaking = false;
  bool _isEndingConversation = false;
  bool _startingRecording = false; // guard against double-start
  DateTime? _recordingStartTime;
  String _currentAiQuestion = '';
  DateTime _sessionStart = DateTime.now();

  //  Result
  AiPartnerSession? _resultSession;
  AiPartnerProfile? _updatedProfile;

  //  Mic animation
  late AnimationController _micPulseCtrl;
  late Animation<double> _micPulse;

  @override
  void initState() {
    super.initState();
    _micPulseCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..repeat(reverse: true);
    _micPulse = Tween<double>(
      begin: 1.0,
      end: 1.25,
    ).animate(CurvedAnimation(parent: _micPulseCtrl, curve: Curves.easeInOut));
    _initTts();
    _loadProfile();
    _checkResume();
    _loadGeminiTopics();
  }

  @override
  void dispose() {
    _micPulseCtrl.dispose();
    _countdownTimer?.cancel();
    // Do NOT dispose the singleton GoogleCloudSpeechService here —
    // it recreates its recorder internally, but calling dispose from a
    // page still risks a race condition if recording is in progress.
    if (_isRecording) {
      _cloudSpeech.cancelRecording();
    }
    _tts.stop();
    _scrollCtrl.dispose();
    super.dispose();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage('en-GB');
    await _tts.setSpeechRate(0.58);
    await _tts.setPitch(1.0);
    _tts.setStartHandler(() {
      if (mounted) setState(() => _isSpeaking = true);
    });
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _isSpeaking = false);
    });
    _tts.setErrorHandler((_) {
      if (mounted) setState(() => _isSpeaking = false);
    });
  }

  Future<void> _loadProfile() async {
    try {
      final p = await _store.getUserProfile();
      if (mounted) setState(() => _profile = p);
    } catch (_) {}
  }

  Future<void> _loadGeminiTopics() async {
    setState(() => _loadingGeminiTopics = true);
    try {
      final topics = await _gemini.generateFreeTopics();
      if (mounted) setState(() => _geminiTopics = topics);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _loadingGeminiTopics = false);
    }
  }

  Future<void> _checkResume() async {
    try {
      final state = await _store.loadConversationState();
      if (state != null && mounted) {
        final result = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          builder: (_) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
            title: const Text('Resume Conversation?'),
            content: Text(
              'You have an unfinished conversation about "${state['topic']}".\n'
              'Would you like to continue?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text(
                  'Start New',
                  style: TextStyle(color: Colors.red),
                ),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryBlue,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Resume'),
              ),
            ],
          ),
        );
        if (result == true) {
          _restoreState(state);
        } else {
          await _store.clearConversationState();
        }
      }
    } catch (_) {
    } finally {
      if (mounted) setState(() => _checkingResume = false);
    }
  }

  void _restoreState(Map<String, dynamic> state) {
    _selectedTopic = state['topic'] as String? ?? '';
    _isFreeMode = state['isFreeMode'] as bool? ?? false;
    _turnCount = (state['turnCount'] as num?)?.toInt() ?? 0;
    _timerSeconds = (state['timerSeconds'] as num?)?.toInt() ?? _maxSeconds;
    _sessionStart = state['sessionStartMs'] is int
        ? DateTime.fromMillisecondsSinceEpoch(state['sessionStartMs'] as int)
        : DateTime.now();
    _currentAiQuestion = state['currentAiQuestion'] as String? ?? '';

    final rawTurns = state['turns'] as List<dynamic>? ?? [];
    for (final t in rawTurns) {
      final turn = ConversationTurn.fromJson(t as Map<String, dynamic>);
      _completedTurns.add(turn);
      _messages.add(_ChatMessage(isAi: true, text: turn.aiQuestion));
      _messages.add(_ChatMessage(isAi: false, text: turn.userTranscript));
      if (turn.aiResponse.isNotEmpty) {
        _messages.add(_ChatMessage(isAi: true, text: turn.aiResponse));
      }
    }
    if (_currentAiQuestion.isNotEmpty) {
      _messages.add(_ChatMessage(isAi: true, text: _currentAiQuestion));
    }

    setState(() => _phase = _Phase.conversation);
    _startTimer();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());
  }

  Future<void> _startConversation(String topic, bool freeMode) async {
    setState(() {
      _selectedTopic = topic;
      _isFreeMode = freeMode;
      _phase = _Phase.conversation;
      _messages.clear();
      _completedTurns.clear();
      _turnCount = 0;
      _timerSeconds = _maxSeconds;
      _sessionStart = DateTime.now();
      _isProcessing = true;
    });

    _addTypingBubble(isAi: true);

    try {
      final opening = await _gemini.generateOpeningQuestion(
        topic: topic,
        isFreeMode: freeMode,
        profile: _profile,
      );
      _removeTypingBubble();
      setState(() {
        _currentAiQuestion = opening;
        _messages.add(_ChatMessage(isAi: true, text: opening));
        _isProcessing = false;
      });
      _scrollToBottom();
      await _speakAi(opening);
      _startTimer();
      _autosaveState();
    } catch (e) {
      _removeTypingBubble();
      setState(() => _isProcessing = false);
      _showError('Failed to start: $e');
    }
  }

  void _startTimer() {
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _timerSeconds--);
      if (_timerSeconds <= 0) {
        t.cancel();
        if (!_isEndingConversation) _endConversation();
      }
    });
  }

  Future<void> _startRecording() async {
    if (_isProcessing || _isSpeaking || _isRecording || _startingRecording)
      return;
    _startingRecording = true;
    try {
      await _cloudSpeech.startRecording();
      _recordingStartTime = DateTime.now();
      if (mounted) setState(() => _isRecording = true);
    } catch (e) {
      _showError('Microphone error: $e');
    } finally {
      _startingRecording = false;
    }
  }

  Future<void> _stopRecording() async {
    if (!_isRecording) return;

    // Enforce minimum 1.5 s so a tap can never capture empty audio
    if (_recordingStartTime != null) {
      final elapsed = DateTime.now().difference(_recordingStartTime!);
      const minDuration = Duration(milliseconds: 1500);
      if (elapsed < minDuration) {
        await Future.delayed(minDuration - elapsed);
      }
    }
    if (!mounted || !_isRecording) return; // might have been cancelled

    setState(() {
      _isRecording = false;
      _isProcessing = true;
    });
    _recordingStartTime = null;

    try {
      final path = await _cloudSpeech.stopRecording();
      if (path == null || path.isEmpty) throw Exception('Empty recording');

      final stt = await _cloudSpeech.recognizeSpeech(
        audioFilePath: path,
        languageCode: 'en-US',
      );

      final transcript = stt.transcript.trim();
      if (transcript.isEmpty) {
        setState(() => _isProcessing = false);
        Fluttertoast.showToast(
          msg: 'No speech detected, please try again',
          gravity: ToastGravity.CENTER,
        );
        return;
      }

      setState(() {
        _messages.add(_ChatMessage(isAi: false, text: transcript));
      });
      _scrollToBottom();

      final results = await Future.wait([
        _gemini.scoreTurn(
          userTranscript: transcript,
          aiQuestion: _currentAiQuestion,
          turnIndex: _turnCount,
          history: _completedTurns,
        ),
        _gemini.generateConversationResponse(
          topic: _selectedTopic,
          isFreeMode: _isFreeMode,
          history: _completedTurns,
          userTranscript: transcript,
          profile: _profile,
        ),
      ]);

      final score = results[0] as TurnScoreResult;
      final aiResponse = results[1] as String;

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Turn ${_turnCount + 1} - Band ${score.overallBand.toStringAsFixed(1)} - ${score.improvementTip}',
                    maxLines: 2,
                    style: const TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: Colors.teal.shade700,
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 80),
          ),
        );
      }

      final turn = ConversationTurn(
        turnIndex: _turnCount,
        aiQuestion: _currentAiQuestion,
        userTranscript: transcript,
        aiResponse: aiResponse,
        fluencyScore: score.fluency,
        lexicalScore: score.lexical,
        grammarScore: score.grammar,
        pronunciationScore: score.pronunciation,
        overallBand: score.overallBand,
        feedbackVN: score.feedbackVN,
        improvementTip: score.improvementTip,
        strengths: score.strengths,
        weaknesses: score.weaknesses,
        timestamp: DateTime.now(),
      );
      _completedTurns.add(turn);
      _turnCount++;

      final isLastTurn = _turnCount >= _maxTurns;

      if (isLastTurn) {
        _countdownTimer?.cancel();
        setState(() => _isProcessing = false);
        _addTypingBubble(isAi: true);
        final closing = await _gemini.generateClosingMessage(
          turns: _completedTurns,
          topic: _selectedTopic,
        );
        _removeTypingBubble();
        setState(() {
          _messages.add(_ChatMessage(isAi: true, text: closing));
        });
        _scrollToBottom();
        await _speakAi(closing);
        _endConversation(closingMessage: closing);
      } else {
        _addTypingBubble(isAi: true);
        await Future.delayed(const Duration(milliseconds: 400));
        _removeTypingBubble();
        setState(() {
          _currentAiQuestion = aiResponse;
          _messages.add(_ChatMessage(isAi: true, text: aiResponse));
          _isProcessing = false;
        });
        _scrollToBottom();
        await _speakAi(aiResponse);
        _autosaveState();
      }
    } catch (e) {
      setState(() => _isProcessing = false);
      _showError('Processing failed: $e');
    }
  }

  Future<void> _skipTurn() async {
    if (_isProcessing || _isRecording) return;
    setState(() => _isProcessing = true);

    final turn = ConversationTurn(
      turnIndex: _turnCount,
      aiQuestion: _currentAiQuestion,
      userTranscript: '(skipped)',
      aiResponse: '',
      fluencyScore: 0,
      lexicalScore: 0,
      grammarScore: 0,
      pronunciationScore: 0,
      overallBand: 0,
      feedbackVN: 'Luot nay bi bo qua.',
      improvementTip: 'Try to attempt every question.',
      strengths: [],
      weaknesses: [],
      timestamp: DateTime.now(),
    );
    _completedTurns.add(turn);
    _turnCount++;

    if (_turnCount >= _maxTurns) {
      setState(() => _isProcessing = false);
      _endConversation();
      return;
    }

    _addTypingBubble(isAi: true);
    try {
      final next = await _gemini.generateConversationResponse(
        topic: _selectedTopic,
        isFreeMode: _isFreeMode,
        history: _completedTurns,
        userTranscript: 'The learner skipped this turn.',
        profile: _profile,
      );
      _removeTypingBubble();
      setState(() {
        _currentAiQuestion = next;
        _messages.add(_ChatMessage(isAi: true, text: next));
        _isProcessing = false;
      });
      _scrollToBottom();
      await _speakAi(next);
      _autosaveState();
    } catch (e) {
      _removeTypingBubble();
      setState(() => _isProcessing = false);
      _showError('Error: $e');
    }
  }

  Future<void> _endConversation({String closingMessage = ''}) async {
    if (_isEndingConversation) return;
    _isEndingConversation = true;
    _countdownTimer?.cancel();
    setState(() => _isProcessing = true);

    try {
      final scoredTurns = _completedTurns
          .where((t) => t.userTranscript != '(skipped)')
          .toList();

      // IELTS bands are only x.0 or x.5 → round to nearest 0.5
      double calcAvg(List<double> vals) {
        if (vals.isEmpty) return 0.0;
        final avg = vals.reduce((a, b) => a + b) / vals.length;
        return (avg * 2).round() / 2;
      }

      final avgFluency = calcAvg(
        scoredTurns.map((t) => t.fluencyScore).toList(),
      );
      final avgLexical = calcAvg(
        scoredTurns.map((t) => t.lexicalScore).toList(),
      );
      final avgGrammar = calcAvg(
        scoredTurns.map((t) => t.grammarScore).toList(),
      );
      final avgPronunciation = calcAvg(
        scoredTurns.map((t) => t.pronunciationScore).toList(),
      );
      final overallBand = calcAvg([
        avgFluency,
        avgLexical,
        avgGrammar,
        avgPronunciation,
      ]);

      final session = AiPartnerSession(
        sessionId: '',
        userId: '',
        topic: _selectedTopic,
        isFreeMode: _isFreeMode,
        turns: _completedTurns,
        avgFluency: avgFluency,
        avgLexical: avgLexical,
        avgGrammar: avgGrammar,
        avgPronunciation: avgPronunciation,
        overallBand: overallBand,
        closingMessage: closingMessage,
        startedAt: _sessionStart,
        endedAt: DateTime.now(),
      );

      final sessionId = await _store.saveSession(session);

      final allStrengths = scoredTurns.expand((t) => t.strengths).toList();
      final allWeaknesses = scoredTurns.expand((t) => t.weaknesses).toList();

      final updatedProfile = await _store.updateProfileWithObservations(
        newStrengths: allStrengths,
        newWeaknesses: allWeaknesses,
        fluency: avgFluency,
        lexical: avgLexical,
        grammar: avgGrammar,
        pronunciation: avgPronunciation,
      );

      await _store.clearConversationState();

      final savedSession = AiPartnerSession(
        sessionId: sessionId,
        userId: session.userId,
        topic: session.topic,
        isFreeMode: session.isFreeMode,
        turns: session.turns,
        avgFluency: session.avgFluency,
        avgLexical: session.avgLexical,
        avgGrammar: session.avgGrammar,
        avgPronunciation: session.avgPronunciation,
        overallBand: session.overallBand,
        closingMessage: session.closingMessage,
        startedAt: session.startedAt,
        endedAt: session.endedAt,
      );

      setState(() {
        _resultSession = savedSession;
        _updatedProfile = updatedProfile;
        _isProcessing = false;
        _isEndingConversation = false;
        _phase = _Phase.result;
      });
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _isEndingConversation = false;
      });
      _showError('Could not save: $e');
    }
  }

  Future<void> _autosaveState() async {
    try {
      await _store.saveConversationState({
        'topic': _selectedTopic,
        'isFreeMode': _isFreeMode,
        'turnCount': _turnCount,
        'timerSeconds': _timerSeconds,
        'sessionStartMs': _sessionStart.millisecondsSinceEpoch,
        'currentAiQuestion': _currentAiQuestion,
        'turns': _completedTurns.map((t) => t.toJson()).toList(),
      });
    } catch (_) {}
  }

  Future<void> _speakAi(String text) async {
    if (text.isEmpty) return;
    await _tts.speak(text);
  }

  void _addTypingBubble({required bool isAi}) {
    setState(
      () => _messages.add(_ChatMessage(isAi: isAi, text: '', isTyping: true)),
    );
    _scrollToBottom();
  }

  void _removeTypingBubble() {
    setState(() => _messages.removeWhere((m) => m.isTyping));
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollCtrl.hasClients) {
        _scrollCtrl.animateTo(
          _scrollCtrl.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _formatTime(int seconds) {
    final m = (seconds ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: _buildAppBar(),
        body: _checkingResume
            ? const Center(child: CircularProgressIndicator())
            : _buildBody(),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    if (_phase == _Phase.conversation && _completedTurns.isNotEmpty) {
      final leave = await showDialog<bool>(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: const Text('Leave Conversation?'),
          content: const Text(
            'Progress will be saved and you can resume later.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Stay', style: TextStyle(color: primaryBlue)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Leave', style: TextStyle(color: Colors.red)),
            ),
          ],
        ),
      );
      if (leave == true) {
        _countdownTimer?.cancel();
        await _autosaveState();
        return true;
      }
      return false;
    }
    return true;
  }

  AppBar _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: primaryBlue,
      elevation: 0,
      title: _phase == _Phase.conversation
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isFreeMode ? 'Free Conversation' : _selectedTopic,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Turn $_turnCount/$_maxTurns - ${_formatTime(_timerSeconds)}',
                  style: const TextStyle(fontSize: 12, color: textGrey),
                ),
              ],
            )
          : _phase == _Phase.result
          ? const Text(
              'Session Result',
              style: TextStyle(fontWeight: FontWeight.bold),
            )
          : const Text(
              'AI Speaking Partner',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
      actions: [
        if (_phase == _Phase.conversation) ...[
          IconButton(
            icon: Icon(
              _isSpeaking ? Icons.volume_up : Icons.volume_off,
              color: _isSpeaking ? teal : textGrey,
            ),
            onPressed: () => _tts.stop(),
            tooltip: 'Stop AI speech',
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            onSelected: (v) {
              if (v == 'end') _endConversation();
              if (v == 'skip') _skipTurn();
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'skip', child: Text('Skip this turn')),
              const PopupMenuItem(
                value: 'end',
                child: Text('End session', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ],
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case _Phase.topicSelection:
        return _buildTopicSelection();
      case _Phase.conversation:
        return _buildConversation();
      case _Phase.result:
        return _buildResult();
    }
  }

  Widget _buildTopicSelection() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_profile.sessionCount > 0) _buildProfileBanner(),
        if (_profile.sessionCount > 0) const SizedBox(height: 16),
        _buildFreeConversationCard(),
        const SizedBox(height: 20),
        const Text(
          'IELTS Topics',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            childAspectRatio: 1.0,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: _kDefaultTopics.length,
          itemBuilder: (_, i) => _buildTopicCard(_kDefaultTopics[i]),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            const Text(
              'Suggested by AI',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const Spacer(),
            IconButton(
              icon: _loadingGeminiTopics
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.refresh, color: teal),
              onPressed: _loadingGeminiTopics ? null : _loadGeminiTopics,
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (_loadingGeminiTopics)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16),
            child: Center(
              child: Text(
                'AI is generating topics...',
                style: TextStyle(color: textGrey),
              ),
            ),
          )
        else
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _geminiTopics.map(_buildChipTopic).toList(),
          ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildProfileBanner() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: teal.withOpacity(0.1),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: teal.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const CircleAvatar(
            radius: 20,
            backgroundColor: teal,
            child: Icon(Icons.person, color: Colors.white, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${_profile.sessionCount} sessions completed',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: teal,
                  ),
                ),
                if (_profile.profileSummary.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    _profile.profileSummary,
                    style: const TextStyle(fontSize: 12, color: textGrey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreeConversationCard() {
    return GestureDetector(
      onTap: () => _startConversation('Free Conversation', true),
      child: Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.teal.shade400, Colors.teal.shade700],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: teal.withOpacity(0.3),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(Icons.shuffle, color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Free Conversation',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Chat freely - AI adapts to any topic',
                    style: TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                ],
              ),
            ),
            const Icon(
              Icons.arrow_forward_ios,
              color: Colors.white70,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopicCard(Map<String, dynamic> topic) {
    return GestureDetector(
      onTap: () => _startConversation(topic['label'] as String, false),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(topic['icon'] as IconData, color: primaryBlue, size: 28),
            const SizedBox(height: 8),
            Text(
              topic['label'] as String,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChipTopic(String label) {
    return ActionChip(
      avatar: const Icon(Icons.chat_bubble_outline, size: 16, color: teal),
      label: Text(label, style: const TextStyle(fontSize: 13)),
      backgroundColor: teal.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: teal.withOpacity(0.3)),
      ),
      onPressed: () => _startConversation(label, false),
    );
  }

  Widget _buildConversation() {
    return Column(
      children: [
        _buildProgressHeader(),
        Expanded(
          child: ListView.builder(
            controller: _scrollCtrl,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            itemCount: _messages.length,
            itemBuilder: (_, i) => _buildBubble(_messages[i]),
          ),
        ),
        _buildBottomBar(),
      ],
    );
  }

  Widget _buildProgressHeader() {
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      child: Column(
        children: [
          Row(
            children: [
              Text(
                'Turn $_turnCount/$_maxTurns',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  color: primaryBlue,
                ),
              ),
              const Spacer(),
              Icon(
                Icons.timer_outlined,
                size: 16,
                color: _timerSeconds < 60 ? Colors.red : textGrey,
              ),
              const SizedBox(width: 4),
              Text(
                _formatTime(_timerSeconds),
                style: TextStyle(
                  fontWeight: FontWeight.w600,
                  color: _timerSeconds < 60 ? Colors.red : textGrey,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          LinearProgressIndicator(
            value: _turnCount / _maxTurns,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
            borderRadius: BorderRadius.circular(4),
          ),
        ],
      ),
    );
  }

  Widget _buildBubble(_ChatMessage msg) {
    if (msg.isTyping) {
      return Align(
        alignment: msg.isAi ? Alignment.centerLeft : Alignment.centerRight,
        child: Container(
          margin: const EdgeInsets.only(bottom: 12, right: 80),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: msg.isAi ? aiBubbleColor : userBubbleColor,
            borderRadius: BorderRadius.circular(18),
          ),
          child: const _TypingDots(),
        ),
      );
    }

    return Align(
      alignment: msg.isAi ? Alignment.centerLeft : Alignment.centerRight,
      child: Container(
        margin: EdgeInsets.only(
          bottom: 12,
          right: msg.isAi ? 80 : 0,
          left: msg.isAi ? 0 : 80,
        ),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: msg.isAi ? aiBubbleColor : userBubbleColor,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(18),
            topRight: const Radius.circular(18),
            bottomLeft: Radius.circular(msg.isAi ? 4 : 18),
            bottomRight: Radius.circular(msg.isAi ? 18 : 4),
          ),
        ),
        child: Text(
          msg.text,
          style: TextStyle(
            color: msg.isAi ? Colors.black87 : Colors.white,
            fontSize: 15,
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomBar() {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 20),
      child: _isProcessing
          ? _buildProcessingIndicator()
          : _isSpeaking
          ? _buildSpeakingIndicator()
          : _buildMicControls(),
    );
  }

  Widget _buildProcessingIndicator() {
    return const Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
        SizedBox(width: 12),
        Text('Processing...', style: TextStyle(color: textGrey, fontSize: 15)),
      ],
    );
  }

  Widget _buildSpeakingIndicator() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.volume_up, color: teal),
        const SizedBox(width: 8),
        const Text(
          'AI is speaking...',
          style: TextStyle(color: teal, fontWeight: FontWeight.w600),
        ),
        const Spacer(),
        TextButton.icon(
          onPressed: () => _tts.stop(),
          icon: const Icon(Icons.skip_next, color: teal),
          label: const Text('Skip', style: TextStyle(color: teal)),
        ),
      ],
    );
  }

  Widget _buildMicControls() {
    return Row(
      children: [
        OutlinedButton(
          onPressed: _skipTurn,
          style: OutlinedButton.styleFrom(
            foregroundColor: textGrey,
            side: BorderSide(color: Colors.grey.shade300),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
          child: const Text('Skip', style: TextStyle(fontSize: 13)),
        ),
        const Spacer(),
        GestureDetector(
          onTap: () => _isRecording ? _stopRecording() : _startRecording(),
          child: AnimatedBuilder(
            animation: _micPulse,
            builder: (_, child) => Transform.scale(
              scale: _isRecording ? _micPulse.value : 1.0,
              child: child,
            ),
            child: Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: _isRecording ? Colors.red : primaryBlue,
                boxShadow: [
                  BoxShadow(
                    color: (_isRecording ? Colors.red : primaryBlue)
                        .withOpacity(0.4),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Icon(
                _isRecording ? Icons.stop : Icons.mic,
                color: Colors.white,
                size: 32,
              ),
            ),
          ),
        ),
        const Spacer(),
        SizedBox(
          width: 60,
          child: Text(
            _isRecording ? 'Tap to\nstop' : 'Tap to\nspeak',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: textGrey),
          ),
        ),
      ],
    );
  }

  Widget _buildResult() {
    final session = _resultSession;
    if (session == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final scoredTurns = session.turns
        .where((t) => t.userTranscript != '(skipped)')
        .toList();
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _buildOverallBandCard(session),
        const SizedBox(height: 20),
        _buildCriteriaCard(session),
        const SizedBox(height: 20),
        if (_updatedProfile != null) _buildProfileUpdateNotice(),
        if (_updatedProfile != null) const SizedBox(height: 20),
        _buildTurnTimeline(scoredTurns),
        const SizedBox(height: 20),
        _buildResultActions(session),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _buildOverallBandCard(AiPartnerSession session) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue, Colors.blue.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                radius: 20,
                backgroundColor: Colors.white24,
                child: Icon(Icons.smart_toy, color: Colors.white),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      session.isFreeMode ? 'Free Conversation' : session.topic,
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      '${session.turns.length} turns - ${_formatDuration(session.duration)}',
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Band ${session.overallBand.toStringAsFixed(1)}',
            style: const TextStyle(
              fontSize: 52,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          if (session.closingMessage.isNotEmpty) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                session.closingMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  height: 1.4,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildCriteriaCard(AiPartnerSession session) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'IELTS Criteria Scores',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          _criteriaRow('Fluency & Coherence', session.avgFluency, Icons.waves),
          _criteriaRow(
            'Lexical Resource',
            session.avgLexical,
            Icons.book_outlined,
          ),
          _criteriaRow(
            'Grammatical Accuracy',
            session.avgGrammar,
            Icons.spellcheck,
          ),
          _criteriaRow(
            'Pronunciation',
            session.avgPronunciation,
            Icons.record_voice_over,
          ),
        ],
      ),
    );
  }

  Widget _criteriaRow(String label, double score, IconData icon) {
    final Color scoreColor = score >= 7.0
        ? Colors.green
        : score >= 5.5
        ? Colors.orange
        : Colors.red;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          Icon(icon, color: primaryBlue, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      label,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      score.toStringAsFixed(1),
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: scoreColor,
                        fontSize: 15,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: score / 9.0,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  borderRadius: BorderRadius.circular(4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileUpdateNotice() {
    final profile = _updatedProfile!;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: teal.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: teal.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.insights, color: teal, size: 20),
              SizedBox(width: 8),
              Text(
                'Profile Updated',
                style: TextStyle(fontWeight: FontWeight.bold, color: teal),
              ),
            ],
          ),
          const SizedBox(height: 8),
          if (profile.weaknesses.isNotEmpty)
            Text(
              'Areas to improve: ${profile.weaknesses.take(3).join(', ')}',
              style: const TextStyle(fontSize: 13, color: textGrey),
            ),
          if (profile.strengths.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Text(
                'Confirmed strengths: ${profile.strengths.take(3).join(', ')}',
                style: const TextStyle(fontSize: 13, color: textGrey),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildTurnTimeline(List<ConversationTurn> turns) {
    if (turns.isEmpty) return const SizedBox.shrink();
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Turn by Turn',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 12),
          ...turns.asMap().entries.map(
            (e) => _buildTurnTile(e.key + 1, e.value),
          ),
        ],
      ),
    );
  }

  Widget _buildTurnTile(int num, ConversationTurn turn) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        leading: CircleAvatar(
          radius: 16,
          backgroundColor: primaryBlue.withOpacity(0.1),
          child: Text(
            '$num',
            style: const TextStyle(
              color: primaryBlue,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        title: Text(
          'Turn $num  -  Band ${turn.overallBand.toStringAsFixed(1)}',
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
        ),
        subtitle: Text(
          turn.improvementTip,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12, color: textGrey),
        ),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        children: [
          _tileDetail('AI Question', turn.aiQuestion, Icons.smart_toy),
          _tileDetail('Your Answer', turn.userTranscript, Icons.person_outline),
          if (turn.feedbackVN.isNotEmpty)
            _tileDetail('Feedback', turn.feedbackVN, Icons.feedback_outlined),
          if (turn.strengths.isNotEmpty)
            _tileDetail(
              'Strengths',
              turn.strengths.join(', '),
              Icons.thumb_up_outlined,
              color: Colors.green,
            ),
          if (turn.weaknesses.isNotEmpty)
            _tileDetail(
              'Improve',
              turn.weaknesses.join(', '),
              Icons.build_outlined,
              color: Colors.orange,
            ),
        ],
      ),
    );
  }

  Widget _tileDetail(
    String label,
    String value,
    IconData icon, {
    Color? color,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: color ?? textGrey),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: color ?? textGrey,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(fontSize: 13, color: Colors.black87),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultActions(AiPartnerSession session) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => AiPartnerReviewPage(session: session),
              ),
            ),
            icon: const Icon(Icons.analytics_outlined),
            label: const Text('View Full Review'),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () {
                  setState(() {
                    _phase = _Phase.topicSelection;
                    _messages.clear();
                    _completedTurns.clear();
                    _resultSession = null;
                    _updatedProfile = null;
                    _isEndingConversation = false;
                    _turnCount = 0;
                    _timerSeconds = _maxSeconds;
                    _loadGeminiTopics();
                  });
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Practice Again'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: primaryBlue,
                  side: const BorderSide(color: primaryBlue),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.arrow_back),
                label: const Text('Back'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: textGrey,
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<int> _dotCount;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
    _dotCount = StepTween(begin: 1, end: 3).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _dotCount,
      builder: (_, __) => Text(
        '.' * _dotCount.value,
        style: const TextStyle(
          fontSize: 20,
          color: Colors.black54,
          letterSpacing: 4,
        ),
      ),
    );
  }
}
