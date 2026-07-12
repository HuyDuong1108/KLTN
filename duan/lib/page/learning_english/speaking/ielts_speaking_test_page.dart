import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:fluttertoast/fluttertoast.dart';
import '../../../data/ielts_gemini_service.dart';
import '../../../data/ielts_speaking_store.dart';
import '../../../data/azure_pronunciation_service.dart';
import '../../../models/ielts_speaking_session.dart';
import '../../../data/ai_partner_gemini_service.dart'; // TurnScoreResult
import 'ielts_speaking_result_page.dart';

// ─────────────────────────────────────────────────────────────
// Phase enum
// ─────────────────────────────────────────────────────────────
enum _IeltsPhase { intro, part1, part2Prep, part2Speaking, part3, result }

// ─────────────────────────────────────────────────────────────
// Main widget
// ─────────────────────────────────────────────────────────────
class IeltsSpeakingTestPage extends StatefulWidget {
  const IeltsSpeakingTestPage({super.key});

  @override
  State<IeltsSpeakingTestPage> createState() => _IeltsSpeakingTestPageState();
}

class _IeltsSpeakingTestPageState extends State<IeltsSpeakingTestPage>
    with TickerProviderStateMixin {
  // ── Colors ──────────────────────────────────────────────────
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color bgColor = Color(0xFFF6FAFF);
  static const Color textGrey = Color(0xFF607D8B);
  static const Color recordRed = Color(0xFFE53935);
  static const Color teal = Color(0xFF00897B);
  static const Color purple = Color(0xFF7B1FA2);

  // ── Services ────────────────────────────────────────────────
  final _gemini = IeltsGeminiService.instance;
  final _store = IeltsSpeakingStore.instance;
  final _azureService = AzurePronunciationService.instance;
  final FlutterTts _tts = FlutterTts();

  // ── Phase ───────────────────────────────────────────────────
  _IeltsPhase _phase = _IeltsPhase.intro;

  // ── Test data (cached on intro load) ────────────────────────
  List<String> _part1Questions = [];
  IeltsCueCard? _cueCard;
  List<String> _part3Questions = [];
  bool _loadingQuestions = true;
  String _loadingStatus = 'Preparing test...';

  // ── Part 1 state ────────────────────────────────────────────
  int _part1QuestionIndex = 0;
  List<IeltsTurn> _part1Turns = [];
  int _part1Timer = 5 * 60;
  Timer? _part1TimerRef;

  // ── Part 2 prep state ───────────────────────────────────────
  int _prepTimer = 60;
  int _prepTimeUsed = 0;
  Timer? _prepTimerRef;

  // ── Part 2 speaking state ───────────────────────────────────
  IeltsTurn? _part2Turn;
  int _part2Timer = 2 * 60;
  Timer? _part2TimerRef;

  // ── Part 3 state ────────────────────────────────────────────
  int _part3QuestionIndex = 0;
  List<IeltsTurn> _part3Turns = [];
  int _part3Timer = 4 * 60;
  Timer? _part3TimerRef;

  // ── Recording ───────────────────────────────────────────────
  bool _isRecording = false;
  bool _isProcessing = false;
  bool _isSpeaking = false;
  bool _startingRecording = false;
  DateTime? _recordingStartTime;
  String _liveTranscript = '';

  // ── Session timing ──────────────────────────────────────────
  DateTime _sessionStart = DateTime.now();

  // ── Examiner intro text ─────────────────────────────────────
  String _currentExaminerText = '';

  // ── Mic animation ───────────────────────────────────────────
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
    _loadAllQuestions();
  }

  @override
  void dispose() {
    _micPulseCtrl.dispose();
    _part1TimerRef?.cancel();
    _prepTimerRef?.cancel();
    _part2TimerRef?.cancel();
    _part3TimerRef?.cancel();
    if (_isRecording) _azureService.cancelRecording();
    _tts.stop();
    super.dispose();
  }

  // ─────────────────────────────────────────────────────────────
  // Init
  // ─────────────────────────────────────────────────────────────
  Future<void> _initTts() async {
    await _tts.setLanguage('en-GB');
    await _tts.setSpeechRate(0.55);
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

  Future<void> _loadAllQuestions() async {
    setState(() {
      _loadingQuestions = true;
      _loadingStatus = 'Generating Part 1 questions...';
    });
    try {
      final p1 = await _gemini.generatePart1Questions();
      if (mounted) {
        setState(() => _loadingStatus = 'Generating cue card...');
      }
      final card = await _gemini.generateCueCard();
      if (mounted) {
        setState(() => _loadingStatus = 'Generating Part 3 questions...');
      }
      final p3 = await _gemini.generatePart3Questions(card.topic);
      if (mounted) {
        setState(() {
          _part1Questions = p1;
          _cueCard = card;
          _part3Questions = p3;
          _loadingQuestions = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _part1Questions = [
            'Can you tell me about your hometown?',
            'What do you do in your free time?',
            'Do you prefer indoor or outdoor activities?',
            'What kind of music do you enjoy?',
            'How do you usually spend your weekends?',
          ];
          _cueCard = const IeltsCueCard(
            topic: 'Describe a memorable journey you have taken.',
            bulletPoints: [
              'Where you went',
              'Who you went with',
              'What you did there',
              'Explain why it was memorable',
            ],
          );
          _part3Questions = [
            'How important is travel for personal development?',
            'In what ways has tourism changed over the past decade?',
            'What are the environmental impacts of mass tourism?',
            'Should governments invest more in public transport?',
          ];
          _loadingQuestions = false;
        });
        Fluttertoast.showToast(msg: 'Using default questions (network issue)');
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Phase transitions
  // ─────────────────────────────────────────────────────────────
  Future<void> _startTest() async {
    _sessionStart = DateTime.now();
    setState(() {
      _phase = _IeltsPhase.part1;
      _part1QuestionIndex = 0;
      _part1Turns = [];
      _currentExaminerText = '';
      _isProcessing = true;
    });
    try {
      final intro = await _gemini.generatePartIntro(part: 1);
      if (mounted) {
        setState(() {
          _currentExaminerText = intro;
          _isProcessing = false;
        });
        await _speakText(intro);
        await Future.delayed(const Duration(milliseconds: 800));
        await _speakCurrentQuestion();
        _startPart1Timer();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _currentExaminerText =
              "I'd like to ask you some questions about yourself.";
          _isProcessing = false;
        });
        _startPart1Timer();
      }
    }
  }

  void _startPart1Timer() {
    _part1TimerRef?.cancel();
    _part1Timer = 5 * 60;
    _part1TimerRef = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _part1Timer--);
      if (_part1Timer <= 0) {
        t.cancel();
        _forceMoveToPrep();
      }
    });
  }

  void _forceMoveToPrep() {
    if (_phase != _IeltsPhase.part1) return;
    _part1TimerRef?.cancel();
    _transitionToPart2Prep();
  }

  Future<void> _transitionToPart2Prep() async {
    _part1TimerRef?.cancel();
    setState(() {
      _phase = _IeltsPhase.part2Prep;
      _prepTimer = 60;
      _prepTimeUsed = 0;
      _isProcessing = true;
      _currentExaminerText = '';
    });
    try {
      final intro = await _gemini.generatePartIntro(part: 2, cueCard: _cueCard);
      if (mounted) {
        setState(() {
          _currentExaminerText = intro;
          _isProcessing = false;
        });
        await _speakText(intro);
        _startPrepTimer();
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isProcessing = false);
        _startPrepTimer();
      }
    }
  }

  void _startPrepTimer() {
    _prepTimerRef?.cancel();
    _prepTimerRef = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() {
        _prepTimer--;
        _prepTimeUsed++;
      });
      if (_prepTimer <= 0) {
        t.cancel();
        _transitionToPart2Speaking();
      }
    });
  }

  Future<void> _transitionToPart2Speaking() async {
    _prepTimerRef?.cancel();
    setState(() {
      _phase = _IeltsPhase.part2Speaking;
      _part2Timer = 2 * 60;
      _liveTranscript = '';
    });
    _startPart2Timer();
    await Future.delayed(const Duration(milliseconds: 600));
    await _startRecording();
  }

  void _startPart2Timer() {
    _part2TimerRef?.cancel();
    _part2TimerRef = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _part2Timer--);
      if (_part2Timer <= 0) {
        t.cancel();
        if (_isRecording) _stopRecordingPart2();
      }
    });
  }

  Future<void> _transitionToPart3() async {
    _part2TimerRef?.cancel();
    setState(() {
      _phase = _IeltsPhase.part3;
      _part3QuestionIndex = 0;
      _part3Turns = [];
      _isProcessing = true;
      _currentExaminerText = '';
    });
    try {
      final intro = await _gemini.generatePartIntro(part: 3);
      if (mounted) {
        setState(() {
          _currentExaminerText = intro;
          _isProcessing = false;
        });
        await _speakText(intro);
        await Future.delayed(const Duration(milliseconds: 800));
        await _speakCurrentQuestion();
        _startPart3Timer();
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _currentExaminerText =
              "We've been talking about that topic. I'd like to discuss some wider questions now.";
          _isProcessing = false;
        });
        _startPart3Timer();
      }
    }
  }

  void _startPart3Timer() {
    _part3TimerRef?.cancel();
    _part3Timer = 4 * 60;
    _part3TimerRef = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _part3Timer--);
      if (_part3Timer <= 0) {
        t.cancel();
        _finishTest();
      }
    });
  }

  // ─────────────────────────────────────────────────────────────
  // Recording — Part 1 & 3 toggle
  // ─────────────────────────────────────────────────────────────
  Future<void> _toggleRecording() async {
    if (_isProcessing || _isSpeaking) return;
    if (_isRecording) {
      await _stopRecordingTurn();
    } else {
      await _startRecording();
    }
  }

  Future<void> _startRecording() async {
    if (_isProcessing || _isSpeaking || _isRecording || _startingRecording) {
      return;
    }
    _startingRecording = true;
    try {
      await _azureService.startRecording();
      _recordingStartTime = DateTime.now();
      if (mounted) setState(() => _isRecording = true);
    } catch (e) {
      _showError('Microphone error: $e');
    } finally {
      _startingRecording = false;
    }
  }

  Future<void> _stopRecordingTurn() async {
    if (!_isRecording) return;
    if (_recordingStartTime != null) {
      final elapsed = DateTime.now().difference(_recordingStartTime!);
      const minDuration = Duration(milliseconds: 1500);
      if (elapsed < minDuration) {
        await Future.delayed(minDuration - elapsed);
      }
    }
    if (!mounted || !_isRecording) return;

    setState(() {
      _isRecording = false;
      _isProcessing = true;
      _liveTranscript = 'Processing...';
    });
    _recordingStartTime = null;

    try {
      final path = await _azureService.stopRecording();
      if (path == null || path.isEmpty) throw Exception('Empty recording');

      final azureResult = await _azureService.assessPronunciation(
        audioPath: path,
      );
      final transcript = azureResult.transcript.trim();

      if (transcript.isEmpty) {
        setState(() {
          _isProcessing = false;
          _liveTranscript = '';
        });
        Fluttertoast.showToast(
          msg: 'No speech detected, please try again',
          gravity: ToastGravity.CENTER,
        );
        return;
      }

      setState(() => _liveTranscript = transcript);
      await _scoreTurn(transcript, azureData: azureResult);
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _liveTranscript = '';
      });
      _showError('Recording error: $e');
    }
  }

  Future<void> _scoreTurn(String transcript, {AzurePronunciationResult? azureData}) async {
    final isP1 = _phase == _IeltsPhase.part1;
    final part = isP1 ? 1 : 3;
    final history = isP1 ? _part1Turns : _part3Turns;
    final question = isP1
        ? (_part1Questions.isNotEmpty
              ? _part1Questions[_part1QuestionIndex]
              : '')
        : (_part3Questions.isNotEmpty
              ? _part3Questions[_part3QuestionIndex]
              : '');

    TurnScoreResult score;
    try {
      score = await _gemini.scoreIeltsTurn(
        transcript: transcript,
        question: question,
        part: part,
        history: history,
        azureData: azureData,
      );
    } catch (_) {
      score = TurnScoreResult(
        fluency: 5.0,
        lexical: 5.0,
        grammar: 5.0,
        pronunciation: 5.0,
        overallBand: 5.0,
        feedbackVN: 'Đã ghi nhận.',
        improvementTip: 'Keep practising!',
        strengths: [],
        weaknesses: [],
      );
    }

    final turn = IeltsTurn(
      turnIndex: history.length,
      part: part,
      question: question,
      transcript: transcript,
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

    if (isP1) {
      _part1Turns = [..._part1Turns, turn];
    } else {
      _part3Turns = [..._part3Turns, turn];
    }

    setState(() {
      _isProcessing = false;
      _liveTranscript = '';
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.auto_awesome, color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Band ${score.overallBand.toStringAsFixed(1)} — ${score.improvementTip}',
                  maxLines: 2,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF512DA8),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    if (isP1) {
      if (_part1QuestionIndex < _part1Questions.length - 1) {
        setState(() => _part1QuestionIndex++);
        await Future.delayed(const Duration(milliseconds: 500));
        await _speakCurrentQuestion();
      } else {
        _forceMoveToPrep();
      }
    } else {
      if (_part3QuestionIndex < _part3Questions.length - 1) {
        setState(() => _part3QuestionIndex++);
        await Future.delayed(const Duration(milliseconds: 500));
        await _speakCurrentQuestion();
      } else {
        _finishTest();
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Recording — Part 2 monologue
  // ─────────────────────────────────────────────────────────────
  Future<void> _stopRecordingPart2() async {
    if (!_isRecording) return;
    _part2TimerRef?.cancel();

    if (_recordingStartTime != null) {
      final elapsed = DateTime.now().difference(_recordingStartTime!);
      const minDuration = Duration(milliseconds: 1500);
      if (elapsed < minDuration) {
        await Future.delayed(minDuration - elapsed);
      }
    }
    if (!mounted) return;

    setState(() {
      _isRecording = false;
      _isProcessing = true;
      _liveTranscript = 'Processing your speech...';
    });
    _recordingStartTime = null;

    try {
      final path = await _azureService.stopRecording();
      if (path == null || path.isEmpty) throw Exception('Empty recording');

      final azureResult = await _azureService.assessPronunciation(
        audioPath: path,
      );
      final transcript = azureResult.transcript.trim();

      if (transcript.isEmpty) {
        setState(() {
          _isProcessing = false;
          _liveTranscript = '';
        });
        _part2Turn = IeltsTurn(
          turnIndex: 0,
          part: 2,
          question: _cueCard?.topic ?? '',
          transcript: '(skipped)',
          fluencyScore: 0,
          lexicalScore: 0,
          grammarScore: 0,
          pronunciationScore: 0,
          overallBand: 0,
          feedbackVN: '',
          improvementTip: '',
          strengths: [],
          weaknesses: [],
          timestamp: DateTime.now(),
        );
        await _transitionToPart3();
        return;
      }

      setState(() => _liveTranscript = transcript);

      TurnScoreResult score;
      try {
        score = await _gemini.scoreIeltsTurn(
          transcript: transcript,
          question: _cueCard?.topic ?? '',
          part: 2,
          history: [],
          azureData: azureResult,
        );
      } catch (_) {
        score = TurnScoreResult(
          fluency: 5.0,
          lexical: 5.0,
          grammar: 5.0,
          pronunciation: 5.0,
          overallBand: 5.0,
          feedbackVN: 'Đã ghi nhận.',
          improvementTip: 'Keep practising!',
          strengths: [],
          weaknesses: [],
        );
      }

      _part2Turn = IeltsTurn(
        turnIndex: 0,
        part: 2,
        question: _cueCard?.topic ?? '',
        transcript: transcript,
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

      setState(() {
        _isProcessing = false;
        _liveTranscript = '';
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Part 2 — Band ${score.overallBand.toStringAsFixed(1)}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            backgroundColor: purple,
            duration: const Duration(seconds: 3),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }

      await _transitionToPart3();
    } catch (e) {
      setState(() {
        _isProcessing = false;
        _liveTranscript = '';
      });
      _showError('Error processing Part 2: $e');
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Finish test & save
  // ─────────────────────────────────────────────────────────────
  Future<void> _finishTest() async {
    _part1TimerRef?.cancel();
    _prepTimerRef?.cancel();
    _part2TimerRef?.cancel();
    _part3TimerRef?.cancel();
    if (_isRecording) {
      await _azureService.cancelRecording();
      setState(() => _isRecording = false);
    }
    if (mounted) setState(() => _isProcessing = true);

    double r(double v) => (v * 2).round() / 2.0;

    double partBand(List<IeltsTurn> turns) {
      final scored = turns.where((t) => !t.isSkipped).toList();
      if (scored.isEmpty) return 0.0;
      return r(
        scored.map((t) => t.overallBand).reduce((a, b) => a + b) /
            scored.length,
      );
    }

    final p1Band = partBand(_part1Turns);
    final p2Band = (_part2Turn != null && !_part2Turn!.isSkipped)
        ? r(_part2Turn!.overallBand)
        : 0.0;
    final p3Band = partBand(_part3Turns);

    final allScored = [
      ..._part1Turns.where((t) => !t.isSkipped),
      if (_part2Turn != null && !_part2Turn!.isSkipped) _part2Turn!,
      ..._part3Turns.where((t) => !t.isSkipped),
    ];

    double avg(double Function(IeltsTurn) fn) {
      if (allScored.isEmpty) return 0.0;
      return r(allScored.map(fn).reduce((a, b) => a + b) / allScored.length);
    }

    final avgFluency = avg((t) => t.fluencyScore);
    final avgLexical = avg((t) => t.lexicalScore);
    final avgGrammar = avg((t) => t.grammarScore);
    final avgPron = avg((t) => t.pronunciationScore);

    final bandParts = [p1Band, p2Band, p3Band].where((b) => b > 0).toList();
    final overallBand = bandParts.isEmpty
        ? 0.0
        : r(bandParts.reduce((a, b) => a + b) / bandParts.length);

    String closing = '';
    try {
      closing = await _gemini.generateTestClosingMessage(
        overallBand: overallBand,
        part1Band: p1Band,
        part2Band: p2Band,
        part3Band: p3Band,
      );
      await _speakText(closing);
    } catch (_) {}

    final session = IeltsSpeakingSession(
      sessionId: '',
      userId: '',
      cueCard:
          _cueCard ??
          const IeltsCueCard(topic: 'General Speaking', bulletPoints: []),
      prepTimeUsed: _prepTimeUsed,
      part1Turns: _part1Turns,
      part2Turn: _part2Turn,
      part3Turns: _part3Turns,
      part1Band: p1Band,
      part2Band: p2Band,
      part3Band: p3Band,
      avgFluency: avgFluency,
      avgLexical: avgLexical,
      avgGrammar: avgGrammar,
      avgPronunciation: avgPron,
      overallBand: overallBand,
      startedAt: _sessionStart,
      endedAt: DateTime.now(),
    );

    try {
      await _store.saveSession(session);
    } catch (_) {}

    if (mounted) {
      setState(() => _isProcessing = false);
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => IeltsSpeakingResultPage(
            session: session,
            closingMessage: closing,
          ),
        ),
      );
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Skip turn
  // ─────────────────────────────────────────────────────────────
  Future<void> _skipTurn() async {
    final isP1 = _phase == _IeltsPhase.part1;
    final history = isP1 ? _part1Turns : _part3Turns;
    final part = isP1 ? 1 : 3;
    final question = isP1
        ? (_part1Questions.isNotEmpty
              ? _part1Questions[_part1QuestionIndex]
              : '')
        : (_part3Questions.isNotEmpty
              ? _part3Questions[_part3QuestionIndex]
              : '');

    final skipped = IeltsTurn(
      turnIndex: history.length,
      part: part,
      question: question,
      transcript: '(skipped)',
      fluencyScore: 0,
      lexicalScore: 0,
      grammarScore: 0,
      pronunciationScore: 0,
      overallBand: 0,
      feedbackVN: '',
      improvementTip: '',
      strengths: [],
      weaknesses: [],
      timestamp: DateTime.now(),
    );

    if (isP1) {
      _part1Turns = [..._part1Turns, skipped];
      if (_part1QuestionIndex < _part1Questions.length - 1) {
        setState(() => _part1QuestionIndex++);
        await _speakCurrentQuestion();
      } else {
        _forceMoveToPrep();
      }
    } else {
      _part3Turns = [..._part3Turns, skipped];
      if (_part3QuestionIndex < _part3Questions.length - 1) {
        setState(() => _part3QuestionIndex++);
        await _speakCurrentQuestion();
      } else {
        _finishTest();
      }
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Helpers
  // ─────────────────────────────────────────────────────────────
  Future<void> _speakCurrentQuestion() async {
    final isP1 = _phase == _IeltsPhase.part1;
    final questions = isP1 ? _part1Questions : _part3Questions;
    final index = isP1 ? _part1QuestionIndex : _part3QuestionIndex;
    if (questions.isEmpty || index >= questions.length) return;
    await _speakText(questions[index]);
  }

  Future<void> _speakText(String text) async {
    if (text.isEmpty) return;
    try {
      await _tts.stop();
      await _tts.speak(text);
    } catch (_) {}
  }

  void _showError(String msg) {
    if (!mounted) return;
    Fluttertoast.showToast(msg: msg, gravity: ToastGravity.CENTER);
  }

  String _formatTimer(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  // ─────────────────────────────────────────────────────────────
  // BUILD
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: _buildAppBar(),
      body: _buildBody(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    String partLabel = 'IELTS Speaking';
    switch (_phase) {
      case _IeltsPhase.part1:
        partLabel = 'Part 1 / 3';
        break;
      case _IeltsPhase.part2Prep:
      case _IeltsPhase.part2Speaking:
        partLabel = 'Part 2 / 3';
        break;
      case _IeltsPhase.part3:
        partLabel = 'Part 3 / 3';
        break;
      default:
        break;
    }
    return AppBar(
      backgroundColor: Colors.white,
      foregroundColor: primaryBlue,
      elevation: 0,
      title: const Text(
        'IELTS Speaking Test',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              decoration: BoxDecoration(
                color: primaryBlue.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                partLabel,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                  fontSize: 13,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBody() {
    switch (_phase) {
      case _IeltsPhase.intro:
        return _buildIntroPhase();
      case _IeltsPhase.part1:
        return _buildQAPhase(part: 1);
      case _IeltsPhase.part2Prep:
        return _buildPrepPhase();
      case _IeltsPhase.part2Speaking:
        return _buildPart2SpeakingPhase();
      case _IeltsPhase.part3:
        return _buildQAPhase(part: 3);
      case _IeltsPhase.result:
        return const Center(child: CircularProgressIndicator());
    }
  }

  // ─────────────────────────────────────────────────────────────
  // Intro Phase
  // ─────────────────────────────────────────────────────────────
  Widget _buildIntroPhase() {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF1565C0), Color(0xFF42A5F5)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            children: [
              const Icon(Icons.headset_mic, color: Colors.white, size: 52),
              const SizedBox(height: 16),
              const Text(
                'IELTS Speaking Test',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Simulated exam conditions\nAI examiner powered by Gemini',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white70, height: 1.5),
              ),
              if (_loadingQuestions) ...[
                const SizedBox(height: 20),
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 10),
                Text(
                  _loadingStatus,
                  style: const TextStyle(color: Colors.white70, fontSize: 13),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Test structure
        _infoCard(
          icon: Icons.format_list_numbered,
          color: primaryBlue,
          title: 'Test Structure',
          children: [
            _structureRow(
              'Part 1',
              'Introduction & Interview',
              '5 min',
              Icons.chat_bubble_outline,
              primaryBlue,
            ),
            const Divider(height: 20),
            _structureRow(
              'Part 2',
              'Individual Long Turn',
              '1–2 min',
              Icons.record_voice_over,
              purple,
            ),
            const Divider(height: 20),
            _structureRow(
              'Part 3',
              'Two-way Discussion',
              '4 min',
              Icons.forum_outlined,
              teal,
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Instructions
        _infoCard(
          icon: Icons.info_outline,
          color: Colors.orange,
          title: 'Instructions',
          children: [
            _bulletPoint('Speak clearly in English for each question'),
            _bulletPoint('Part 1: Answer 5 personal questions'),
            _bulletPoint(
              'Part 2: 60 sec to prepare, then speak 1–2 min on the cue card',
            ),
            _bulletPoint('Part 3: Discuss 4 abstract questions in depth'),
            _bulletPoint('Tap the mic button to start/stop recording'),
            _bulletPoint('You can skip any question if you get stuck'),
          ],
        ),
        const SizedBox(height: 32),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: _loadingQuestions ? null : _startTest,
            icon: const Icon(Icons.play_arrow_rounded),
            label: Text(
              _loadingQuestions ? 'Preparing...' : 'Start Test',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              disabledBackgroundColor: Colors.grey.shade300,
            ),
          ),
        ),
      ],
    );
  }

  Widget _infoCard({
    required IconData icon,
    required Color color,
    required String title,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }

  Widget _structureRow(
    String part,
    String desc,
    String time,
    IconData icon,
    Color color,
  ) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                part,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: color,
                  fontSize: 13,
                ),
              ),
              Text(desc, style: const TextStyle(fontSize: 12, color: textGrey)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            time,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }

  Widget _bulletPoint(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Padding(
            padding: EdgeInsets.only(top: 5),
            child: Icon(Icons.circle, size: 6, color: textGrey),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: textGrey,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Part 1 & 3 Q&A Phase
  // ─────────────────────────────────────────────────────────────
  Widget _buildQAPhase({required int part}) {
    final questions = part == 1 ? _part1Questions : _part3Questions;
    final index = part == 1 ? _part1QuestionIndex : _part3QuestionIndex;
    final total = questions.length;
    final timer = part == 1 ? _part1Timer : _part3Timer;
    final color = part == 1 ? primaryBlue : teal;
    final partTitle = part == 1
        ? 'Part 1 — Introduction & Interview'
        : 'Part 3 — Two-way Discussion';
    final question = questions.isNotEmpty ? questions[index] : '...';

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _partHeader(
          title: partTitle,
          subtitle: part == 1
              ? 'Answer naturally and in detail.'
              : 'Discuss broadly — give opinions and reasons.',
          timer: _formatTimer(timer),
          timerColor: timer < 60 ? Colors.red : color,
          progress: total > 0 ? (index + 1) / total : 0,
          progressLabel: 'Q${index + 1} / $total',
          color: color,
        ),
        const SizedBox(height: 16),

        if (_currentExaminerText.isNotEmpty)
          _examinerBubble(_currentExaminerText),
        const SizedBox(height: 16),

        _questionCard(questionNum: index + 1, question: question, color: color),
        const SizedBox(height: 20),

        if (_liveTranscript.isNotEmpty) _transcriptCard(_liveTranscript),

        const SizedBox(height: 20),

        _recordingPanel(
          isRecording: _isRecording,
          isProcessing: _isProcessing,
          isSpeaking: _isSpeaking,
          onTap: _toggleRecording,
          color: color,
        ),
        const SizedBox(height: 16),

        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: (_isProcessing || _isRecording) ? null : _skipTurn,
                icon: const Icon(Icons.skip_next, size: 18),
                label: const Text('Skip'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: textGrey,
                  side: const BorderSide(color: textGrey),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: (_isProcessing || _isSpeaking)
                    ? null
                    : _speakCurrentQuestion,
                icon: const Icon(Icons.volume_up, size: 18),
                label: const Text('Repeat Question'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: color,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Center(
          child: TextButton(
            onPressed: (_isProcessing || _isRecording) ? null : _finishTest,
            child: Text(
              'End test early',
              style: TextStyle(color: Colors.red.shade400, fontSize: 13),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Part 2 Prep Phase
  // ─────────────────────────────────────────────────────────────
  Widget _buildPrepPhase() {
    final card = _cueCard;
    final timerFraction = (_prepTimer / 60.0).clamp(0.0, 1.0);
    final timerColor = _prepTimer <= 15 ? Colors.red : purple;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _partHeader(
          title: 'Part 2 — Individual Long Turn',
          subtitle: 'Read the card. Prepare your speech.',
          timer: _formatTimer(_prepTimer),
          timerColor: timerColor,
          progress: timerFraction,
          progressLabel: 'Prep time left',
          color: purple,
        ),
        const SizedBox(height: 16),

        if (_currentExaminerText.isNotEmpty)
          _examinerBubble(_currentExaminerText),
        const SizedBox(height: 16),

        // Cue card
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: purple.withOpacity(0.3), width: 1.5),
            boxShadow: [
              BoxShadow(
                color: purple.withOpacity(0.06),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  'TASK CARD',
                  style: TextStyle(
                    color: purple,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 1,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                card?.topic ?? '...',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'You should say:',
                style: TextStyle(
                  color: textGrey,
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                ),
              ),
              const SizedBox(height: 10),
              ...(card?.bulletPoints ?? []).map(
                (b) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        margin: const EdgeInsets.only(top: 5),
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          color: purple,
                          shape: BoxShape.circle,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          b,
                          style: const TextStyle(fontSize: 14, height: 1.4),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: timerFraction,
            backgroundColor: Colors.grey.shade200,
            valueColor: AlwaysStoppedAnimation<Color>(timerColor),
            minHeight: 10,
          ),
        ),
        const SizedBox(height: 24),

        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              _prepTimerRef?.cancel();
              _transitionToPart2Speaking();
            },
            icon: const Icon(Icons.mic),
            label: const Text(
              "I'm Ready — Start Speaking",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: purple,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Part 2 Speaking Phase
  // ─────────────────────────────────────────────────────────────
  Widget _buildPart2SpeakingPhase() {
    final card = _cueCard;
    final timerFraction = (_part2Timer / (2 * 60)).clamp(0.0, 1.0);
    final timerColor = _part2Timer <= 30 ? Colors.red : purple;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _partHeader(
          title: 'Part 2 — Speaking Now',
          subtitle: 'Speak for 1–2 minutes. Cover all bullet points.',
          timer: _formatTimer(_part2Timer),
          timerColor: timerColor,
          progress: timerFraction,
          progressLabel: 'Time remaining',
          color: purple,
        ),
        const SizedBox(height: 16),

        // Compact cue card reminder
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: purple.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: purple.withOpacity(0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                card?.topic ?? '',
                style: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: (card?.bulletPoints ?? [])
                    .map(
                      (b) => Chip(
                        label: Text(b, style: const TextStyle(fontSize: 11)),
                        backgroundColor: purple.withOpacity(0.07),
                        side: BorderSide(color: purple.withOpacity(0.2)),
                        padding: EdgeInsets.zero,
                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                    )
                    .toList(),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        if (_liveTranscript.isNotEmpty) _transcriptCard(_liveTranscript),
        const SizedBox(height: 20),

        _recordingPanel(
          isRecording: _isRecording,
          isProcessing: _isProcessing,
          isSpeaking: false,
          onTap: _isRecording
              ? _stopRecordingPart2
              : (_isProcessing ? null : _startRecording),
          color: purple,
          label: _isRecording
              ? 'Tap to finish speaking'
              : _isProcessing
              ? 'Processing...'
              : 'Tap to start speaking',
        ),
        const SizedBox(height: 16),

        if (_isRecording)
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _stopRecordingPart2,
              icon: const Icon(Icons.stop),
              label: const Text(
                'Finish Speaking',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: recordRed,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Shared widgets
  // ─────────────────────────────────────────────────────────────
  Widget _partHeader({
    required String title,
    required String subtitle,
    required String timer,
    required Color timerColor,
    required double progress,
    required String progressLabel,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.75)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  timer,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            subtitle,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: Colors.white.withOpacity(0.2),
                    valueColor: const AlwaysStoppedAnimation(Colors.white),
                    minHeight: 6,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                progressLabel,
                style: const TextStyle(color: Colors.white70, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _examinerBubble(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: const BoxDecoration(
            color: primaryBlue,
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.school, color: Colors.white, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: const BoxDecoration(
              color: Color(0xFFE3F2FD),
              borderRadius: BorderRadius.only(
                topRight: Radius.circular(16),
                bottomLeft: Radius.circular(16),
                bottomRight: Radius.circular(16),
              ),
            ),
            child: Text(
              text,
              style: const TextStyle(fontSize: 13, height: 1.4),
            ),
          ),
        ),
      ],
    );
  }

  Widget _questionCard({
    required int questionNum,
    required String question,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Question $questionNum',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 10),
          Text(question, style: const TextStyle(fontSize: 18, height: 1.5)),
          const SizedBox(height: 12),
          const Text(
            'Aim for 20–40 seconds per answer',
            style: TextStyle(
              color: textGrey,
              fontStyle: FontStyle.italic,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _transcriptCard(String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your answer:',
            style: TextStyle(
              fontSize: 11,
              color: textGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 6),
          Text(text, style: const TextStyle(fontSize: 13, height: 1.5)),
        ],
      ),
    );
  }

  Widget _recordingPanel({
    required bool isRecording,
    required bool isProcessing,
    required bool isSpeaking,
    required VoidCallback? onTap,
    required Color color,
    String? label,
  }) {
    final buttonColor = isRecording ? recordRed : color;
    final displayLabel =
        label ??
        (isProcessing
            ? 'Processing...'
            : isRecording
            ? 'Tap to stop recording'
            : isSpeaking
            ? 'Examiner speaking...'
            : 'Tap to record your answer');

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          GestureDetector(
            onTap: onTap,
            child: AnimatedBuilder(
              animation: _micPulse,
              builder: (context, child) {
                final scale = isRecording ? _micPulse.value : 1.0;
                return Transform.scale(
                  scale: scale,
                  child: Container(
                    width: 76,
                    height: 76,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: buttonColor,
                      boxShadow: isRecording
                          ? [
                              BoxShadow(
                                color: recordRed.withOpacity(0.4),
                                blurRadius: 16,
                                spreadRadius: 4,
                              ),
                            ]
                          : [],
                    ),
                    child: Icon(
                      isProcessing
                          ? Icons.hourglass_empty
                          : isRecording
                          ? Icons.stop
                          : Icons.mic,
                      color: Colors.white,
                      size: 34,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 14),
          Text(
            displayLabel,
            style: TextStyle(
              color: isRecording ? recordRed : textGrey,
              fontWeight: isRecording ? FontWeight.bold : FontWeight.normal,
              fontSize: 13,
            ),
          ),
          if (isRecording) ...[
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: recordRed,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                const Text(
                  'Recording',
                  style: TextStyle(
                    color: recordRed,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
          if (isProcessing) ...[
            const SizedBox(height: 10),
            const SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
    );
  }
}
