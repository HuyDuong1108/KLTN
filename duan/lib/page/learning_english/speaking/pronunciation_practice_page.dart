import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:just_audio/just_audio.dart';
import '../../../data/speaking_gemini_service.dart';
import '../../../data/speaking_session_store.dart';
import '../../../data/azure_pronunciation_service.dart';
import '../../../data/dictionary_api_service.dart';
import '../../../models/speaking_session.dart';
import 'speaking_review_page.dart';

class PronunciationPracticePage extends StatefulWidget {
  const PronunciationPracticePage({super.key});

  @override
  State<PronunciationPracticePage> createState() =>
      _PronunciationPracticePageState();
}

class _PronunciationPracticePageState
    extends State<PronunciationPracticePage> {
  // ================= COLORS =================
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color bgColor = Color(0xFFF6FAFF);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFFA726);
  static const Color errorRed = Color(0xFFE53935);
  static const Color textGrey = Color(0xFF607D8B);

  // ================= SERVICES =================
  final FlutterTts _tts = FlutterTts();
  final AudioPlayer _audioPlayer = AudioPlayer();
  final _geminiService = SpeakingGeminiService.instance;
  final _sessionStore = SpeakingSessionStore.instance;
  final _azureService = AzurePronunciationService.instance;
  final _dictService = DictionaryApiService.instance;

  // ================= STATE =================
  String _selectedCategory = "Individual Sounds";
  String _targetSentence = "";
  bool _isRecording = false;
  bool _isAssessing = false; // while Azure processes the audio
  bool _isAnalyzing = false; // while Gemini coaches
  bool _isGenerating = false;
  bool _isPlayingBack = false;
  bool _isTtsTestRunning = false;
  AzurePronunciationResult? _azureResult;
  Map<String, WordDictEntry?> _dictionaryData = {};
  SpeakingSession? _currentSession;
  DateTime? _recordingStartTime;

  @override
  void initState() {
    super.initState();
    _initTts();
    _generateNewSentence();
  }

  @override
  void dispose() {
    _tts.stop();
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.45);
  }

  Future<void> _generateNewSentence() async {
    if (_isGenerating) return;
    setState(() {
      _isGenerating = true;
      _currentSession = null;
      _azureResult = null;
      _dictionaryData = {};
    });
    try {
      final sentence = await _geminiService.generateTargetSentence(
        category: _selectedCategory,
      );
      setState(() {
        _targetSentence = sentence;
        _isGenerating = false;
      });
    } catch (e) {
      setState(() => _isGenerating = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to generate sentence: $e')),
        );
      }
    }
  }

  Future<void> _startRecording() async {
    try {
      setState(() {
        _isRecording = true;
        _azureResult = null;
        _dictionaryData = {};
        _recordingStartTime = DateTime.now();
      });
      await _azureService.startRecording();
    } catch (e) {
      setState(() => _isRecording = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to start recording: $e')),
        );
      }
    }
  }

  Future<void> _stopRecording() async {
    setState(() {
      _isRecording = false;
      _isAssessing = true;
    });

    try {
      final path = await _azureService.stopRecording();
      if (path == null || path.isEmpty) throw Exception('Recording path empty');

      // Azure assesses pronunciation against the target sentence
      final azureResult = await _azureService.assessPronunciation(
        audioPath: path,
        referenceText: _targetSentence,
      );

      setState(() {
        _azureResult = azureResult;
        _isAssessing = false;
      });

      if (azureResult.transcript.isNotEmpty) {
        await _analyzeWithAzure(azureResult);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('No speech detected. Tap "Play My Recording" to check audio.'),
              duration: const Duration(seconds: 5),
              action: _azureService.lastRecordingPath != null
                  ? SnackBarAction(label: 'Play', onPressed: _playRecording)
                  : null,
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isAssessing = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to assess audio: $e')));
      }
    }
  }

  Future<void> _analyzeWithAzure(AzurePronunciationResult azureResult) async {
    if (_isAnalyzing) return;
    setState(() => _isAnalyzing = true);

    try {
      // Look up IPA for mispronounced words in parallel with nothing else
      final mispronounced = azureResult.words
          .where((w) => w.hasError)
          .map((w) => w.word)
          .toList();
      final dictData = mispronounced.isNotEmpty
          ? await _dictService.lookupWords(mispronounced)
          : <String, WordDictEntry?>{};

      setState(() => _dictionaryData = dictData);

      final duration = _recordingStartTime != null
          ? DateTime.now().difference(_recordingStartTime!)
          : const Duration(seconds: 5);

      final result = await _geminiService.analyzeWithAzureData(
        targetSentence: _targetSentence,
        azureResult: azureResult,
        dictionaryData: dictData,
        category: _selectedCategory,
      );

      // Store Azure accuracy scores as confidenceScores for Firestore compat
      final confidenceScores = Map.fromEntries(
        azureResult.words.map((w) => MapEntry(w.word, w.accuracyScore / 100.0)),
      );

      final session = SpeakingSession(
        sessionId: '',
        userId: '',
        timestamp: DateTime.now(),
        targetSentence: _targetSentence,
        transcript: azureResult.transcript,
        overallScore: result.overallScore,
        bandScore: result.bandScore,
        duration: duration,
        confidenceScores: confidenceScores,
        wordErrors: result.wordErrors,
        feedback: result.feedback,
        category: _selectedCategory,
      );

      final sessionId = await _sessionStore.saveSession(session);

      setState(() {
        _currentSession = SpeakingSession(
          sessionId: sessionId,
          userId: session.userId,
          timestamp: session.timestamp,
          targetSentence: session.targetSentence,
          transcript: session.transcript,
          overallScore: session.overallScore,
          bandScore: session.bandScore,
          duration: session.duration,
          confidenceScores: session.confidenceScores,
          wordErrors: session.wordErrors,
          feedback: session.feedback,
          category: session.category,
        );
        _isAnalyzing = false;
      });
    } catch (e) {
      setState(() => _isAnalyzing = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              e.toString().contains('429')
                  ? 'Đang bận, vui lòng thử lại sau 5 giây...'
                  : 'Analysis failed: $e',
            ),
            action: SnackBarAction(
              label: 'Retry',
              onPressed: () async {
                await Future.delayed(const Duration(seconds: 2));
                if (mounted && _azureResult != null) {
                  _analyzeWithAzure(_azureResult!);
                }
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _playTargetSentence() async {
    if (_targetSentence.isNotEmpty) await _tts.speak(_targetSentence);
  }

  Future<void> _runTtsTest() async {
    if (_targetSentence.isEmpty || _isTtsTestRunning) return;
    setState(() {
      _isTtsTestRunning = true;
      _azureResult = null;
      _currentSession = null;
      _dictionaryData = {};
    });

    try {
      final result = await _azureService.testWithTtsAudio(
        sentence: _targetSentence,
      );
      setState(() {
        _azureResult = result;
        _isTtsTestRunning = false;
      });

      if (mounted) {
        final msg = result.transcript.isNotEmpty
            ? 'AI Voice scored ${result.pronunciationScore.toStringAsFixed(0)}/100'
            : 'AI Voice got 0/100 — problem is in API config, not your pronunciation';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            duration: const Duration(seconds: 5),
          ),
        );
      }
    } catch (e) {
      setState(() => _isTtsTestRunning = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('TTS test failed: $e')),
        );
      }
    }
  }

  Future<void> _playRecording() async {
    final path = _azureService.lastRecordingPath;
    if (path == null || !File(path).existsSync()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('No recording file found')),
        );
      }
      return;
    }
    try {
      setState(() => _isPlayingBack = true);
      await _audioPlayer.setFilePath(path);
      _audioPlayer.playerStateStream.listen((state) {
        if (state.processingState == ProcessingState.completed && mounted) {
          setState(() => _isPlayingBack = false);
        }
      });
      await _audioPlayer.play();
    } catch (e) {
      setState(() => _isPlayingBack = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Playback failed: $e')),
        );
      }
    }
  }

  Future<void> _playWordAudio(String url) async {
    try {
      await _audioPlayer.setUrl(url);
      await _audioPlayer.play();
    } catch (_) {}
  }

  void _showWordDetail(AzureWordResult word) {
    final dict = _dictionaryData[word.word];
    final geminiError = _currentSession?.wordErrors
        .where((e) => e.word.toLowerCase() == word.word.toLowerCase())
        .firstOrNull;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  '"${word.word}"',
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 10),
                _accuracyChip(word.accuracyScore, large: true),
                if (dict?.audioUrl != null) ...[
                  const Spacer(),
                  IconButton(
                    icon: const Icon(Icons.volume_up, color: primaryBlue),
                    tooltip: 'Hear reference pronunciation',
                    onPressed: () => _playWordAudio(dict!.audioUrl!),
                  ),
                ],
              ],
            ),
            if (dict?.ipa != null) ...[
              const SizedBox(height: 6),
              Text(
                dict!.ipa!,
                style: const TextStyle(
                  fontSize: 16,
                  color: textGrey,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
            const SizedBox(height: 12),
            _detailRow(
              'Azure Error Type',
              word.errorType,
              Icons.flag_outlined,
            ),
            _detailRow(
              'Accuracy',
              '${word.accuracyScore.toStringAsFixed(0)}/100',
              Icons.analytics_outlined,
            ),
            if (word.phonemes.isNotEmpty) ...[
              const SizedBox(height: 10),
              const Text(
                'Phoneme breakdown',
                style: TextStyle(fontWeight: FontWeight.bold, color: textGrey),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: word.phonemes.map((p) {
                  final c = p.accuracyScore >= 80
                      ? successGreen
                      : p.accuracyScore >= 60
                      ? warningOrange
                      : errorRed;
                  return Chip(
                    label: Text(
                      '/${p.phoneme}/ ${p.accuracyScore.toStringAsFixed(0)}%',
                      style: TextStyle(fontSize: 11, color: c),
                    ),
                    backgroundColor: c.withOpacity(0.1),
                    side: BorderSide(color: c.withOpacity(0.3)),
                    padding: EdgeInsets.zero,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  );
                }).toList(),
              ),
            ],
            if (geminiError?.tip != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: lightBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('💡 '),
                    Expanded(child: Text(geminiError!.tip)),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: textGrey),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: const TextStyle(color: textGrey, fontSize: 13),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _viewDetailedFeedback() {
    if (_currentSession != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SpeakingReviewPage(session: _currentSession!),
        ),
      );
    }
  }

  // ================= BUILD =================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: primaryBlue,
        elevation: 0,
        title: const Text(
          "Pronunciation Practice",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _overviewCard(),
          const SizedBox(height: 28),
          const Text(
            "Practice Categories",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _categoryCard(
            icon: Icons.record_voice_over,
            title: "Individual Sounds",
            subtitle: "Practice difficult English sounds",
            isSelected: _selectedCategory == "Individual Sounds",
            onTap: () {
              setState(() => _selectedCategory = "Individual Sounds");
              _generateNewSentence();
            },
          ),
          _categoryCard(
            icon: Icons.trending_up,
            title: "Word Stress",
            subtitle: "Correct syllable stress",
            isSelected: _selectedCategory == "Word Stress",
            onTap: () {
              setState(() => _selectedCategory = "Word Stress");
              _generateNewSentence();
            },
          ),
          _categoryCard(
            icon: Icons.multitrack_audio,
            title: "Sentence Intonation",
            subtitle: "Sound natural & confident",
            isSelected: _selectedCategory == "Sentence Intonation",
            onTap: () {
              setState(() => _selectedCategory = "Sentence Intonation");
              _generateNewSentence();
            },
          ),
          const SizedBox(height: 28),
          const Text(
            "Practice Session",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _practiceCard(),
          const SizedBox(height: 24),
          if (_azureResult != null && _azureResult!.transcript.isNotEmpty)
            _azureScoreRow(),
          if (_azureResult != null && _azureResult!.words.isNotEmpty) ...[
            const SizedBox(height: 12),
            _wordChipsRow(),
          ],
          if (_currentSession != null) ...[
            const SizedBox(height: 12),
            _feedbackCard(),
          ],
        ],
      ),
      bottomNavigationBar: _bottomControlBar(),
    );
  }

  // ─── Overview card ───────────────────────────────────────────────────────

  Widget _overviewCard() {
    return StreamBuilder(
      stream: _sessionStore.watchStats(),
      builder: (context, snapshot) {
        final stats = snapshot.data;
        final raw = stats?.averageBandScore ?? 0.0;
        final rounded = ((raw * 2).round() / 2);
        final bandScore = raw > 0 ? rounded.toStringAsFixed(1) : '0.0';

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: const LinearGradient(
              colors: [Color(0xFF42A5F5), Color(0xFF90CAF9)],
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Your Pronunciation Level",
                style: TextStyle(color: Colors.white70),
              ),
              const SizedBox(height: 6),
              Text(
                "Band $bandScore",
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Total Sessions: ${stats?.totalSessions ?? 0}",
                style: const TextStyle(color: Colors.white70),
              ),
            ],
          ),
        );
      },
    );
  }

  // ─── Category card ───────────────────────────────────────────────────────

  Widget _categoryCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: isSelected ? primaryBlue.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected ? primaryBlue : Colors.transparent,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: primaryBlue.withOpacity(0.12),
              blurRadius: 10,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: isSelected ? primaryBlue : lightBlue,
              child: Icon(
                icon,
                color: isSelected ? Colors.white : primaryBlue,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: isSelected ? primaryBlue : Colors.black,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: const TextStyle(color: textGrey)),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle : Icons.arrow_forward_ios,
              size: 16,
              color: isSelected ? primaryBlue : textGrey,
            ),
          ],
        ),
      ),
    );
  }

  // ─── Practice card ───────────────────────────────────────────────────────

  Widget _practiceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Practice Sentence",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
              if (_isGenerating)
                const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _targetSentence.isEmpty ? "Generating sentence..." : _targetSentence,
            style: TextStyle(
              fontSize: 16,
              height: 1.5,
              color: _targetSentence.isEmpty ? textGrey : Colors.black,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _iconButton(
                  Icons.volume_up,
                  "Listen",
                  onPressed:
                      _targetSentence.isEmpty ? null : _playTargetSentence,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: _iconButton(
                  _isRecording ? Icons.stop : Icons.mic,
                  _isRecording ? "Stop (10s)" : "Record",
                  onPressed: _isRecording ? _stopRecording : _startRecording,
                  isPrimary: true,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _isTtsTestRunning || _targetSentence.isEmpty
                  ? null
                  : _runTtsTest,
              icon: _isTtsTestRunning
                  ? const SizedBox(
                      width: 14,
                      height: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.science, size: 16),
              label: Text(
                _isTtsTestRunning
                    ? "Testing AI Voice..."
                    : "Test with AI Voice (debug)",
                style: const TextStyle(fontSize: 12),
              ),
              style: OutlinedButton.styleFrom(
                foregroundColor: warningOrange,
                side: const BorderSide(color: warningOrange),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
              ),
            ),
          ),
          if (_azureResult != null &&
              _azureResult!.transcript.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Text(
                  "Your Speech:",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const Spacer(),
                if (_azureService.lastRecordingPath != null)
                  TextButton.icon(
                    onPressed: _isPlayingBack ? null : _playRecording,
                    icon: Icon(
                      _isPlayingBack ? Icons.stop : Icons.headphones,
                      size: 16,
                    ),
                    label: Text(
                      _isPlayingBack ? "Playing..." : "Play My Recording",
                      style: const TextStyle(fontSize: 12),
                    ),
                    style: TextButton.styleFrom(
                      foregroundColor: primaryBlue,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              _azureResult!.transcript,
              style: const TextStyle(fontSize: 15, color: textGrey),
            ),
          ],
          if (_azureResult != null &&
              _azureResult!.transcript.isEmpty &&
              _azureService.lastRecordingPath != null) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: errorRed.withOpacity(0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: errorRed.withOpacity(0.3)),
              ),
              child: Column(
                children: [
                  const Text(
                    'No speech detected (score 0/100)',
                    style: TextStyle(
                      color: errorRed,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _isPlayingBack ? null : _playRecording,
                    icon: Icon(
                      _isPlayingBack ? Icons.stop : Icons.headphones,
                      size: 18,
                    ),
                    label: Text(
                      _isPlayingBack ? "Playing..." : "Play My Recording to verify audio",
                    ),
                    style: TextButton.styleFrom(foregroundColor: primaryBlue),
                  ),
                ],
              ),
            ),
          ],
          if (_isAssessing) ...[
            const SizedBox(height: 16),
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text("Assessing pronunciation..."),
                ],
              ),
            ),
          ],
          if (_isAnalyzing) ...[
            const SizedBox(height: 16),
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text("Generating coaching feedback..."),
                ],
              ),
            ),
          ],
          if (_currentSession != null) ...[
            const SizedBox(height: 16),
            Row(
              children: [
                Icon(
                  _currentSession!.overallScore >= 70
                      ? Icons.check_circle
                      : Icons.warning,
                  color: _currentSession!.overallScore >= 70
                      ? successGreen
                      : warningOrange,
                ),
                const SizedBox(width: 8),
                Text(
                  "Score: ${_currentSession!.overallScore}/100"
                  " • Band ${((_currentSession!.bandScore * 2).round() / 2).toStringAsFixed(1)}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _viewDetailedFeedback,
              icon: const Icon(Icons.visibility),
              label: const Text("View Detailed Feedback"),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryBlue,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 44),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Azure 4-score row ───────────────────────────────────────────────────

  Widget _azureScoreRow() {
    final r = _azureResult!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _scorePill('Accuracy', r.accuracyScore),
          _scorePill('Fluency', r.fluencyScore),
          _scorePill('Complete', r.completenessScore),
          _scorePill('Prosody', r.prosodyScore),
        ],
      ),
    );
  }

  Widget _scorePill(String label, double score) {
    final color = score >= 80
        ? successGreen
        : score >= 60
        ? warningOrange
        : errorRed;
    return Column(
      children: [
        Text(
          score.toStringAsFixed(0),
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: textGrey)),
      ],
    );
  }

  // ─── Word chips row ──────────────────────────────────────────────────────

  Widget _wordChipsRow() {
    final words = _azureResult!.words;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Word-by-word accuracy  (tap for details)',
            style: TextStyle(
              fontSize: 12,
              color: textGrey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: words.map((w) => _wordChip(w)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _wordChip(AzureWordResult word) {
    final color = word.accuracyScore >= 80
        ? successGreen
        : word.accuracyScore >= 60
        ? warningOrange
        : errorRed;
    final hasDictData = _dictionaryData.containsKey(word.word) &&
        (_dictionaryData[word.word]?.ipa != null ||
            _dictionaryData[word.word]?.audioUrl != null);
    return GestureDetector(
      onTap: word.hasError || hasDictData ? () => _showWordDetail(word) : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              word.word,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
            if (word.hasError || hasDictData) ...[
              const SizedBox(width: 4),
              Icon(Icons.info_outline, size: 12, color: color),
            ],
          ],
        ),
      ),
    );
  }

  Widget _accuracyChip(double score, {bool large = false}) {
    final color = score >= 80
        ? successGreen
        : score >= 60
        ? warningOrange
        : errorRed;
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: large ? 10 : 6,
        vertical: large ? 4 : 2,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        '${score.toStringAsFixed(0)}%',
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.bold,
          fontSize: large ? 14 : 11,
        ),
      ),
    );
  }

  // ─── AI Feedback card ────────────────────────────────────────────────────

  Widget _feedbackCard() {
    if (_currentSession == null) return const SizedBox.shrink();
    final feedback = _currentSession!.feedback;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: lightBlue,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "AI Coaching Feedback",
            style: TextStyle(fontWeight: FontWeight.bold, color: primaryBlue),
          ),
          const SizedBox(height: 10),
          if (feedback.summaryVN.isNotEmpty) ...[
            Text(
              feedback.summaryVN,
              style: const TextStyle(height: 1.6, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
          ],
          if (feedback.tipsVN.isNotEmpty) ...[
            ...feedback.tipsVN.take(3).map(
              (tip) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("💡 "),
                    Expanded(child: Text(tip)),
                  ],
                ),
              ),
            ),
          ],
          if (_currentSession!.wordErrors.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              "Found ${_currentSession!.wordErrors.length} pronunciation error(s) — tap a word chip above for details",
              style: const TextStyle(
                color: warningOrange,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─── Bottom bar ──────────────────────────────────────────────────────────

  Widget _bottomControlBar() {
    return Container(
      padding: const EdgeInsets.all(14),
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
      child: Row(
        children: [
          const Spacer(),
          ElevatedButton.icon(
            onPressed: _isGenerating ? null : _generateNewSentence,
            icon: const Icon(Icons.navigate_next),
            label: const Text("Next Sentence"),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Shared button helper ────────────────────────────────────────────────

  Widget _iconButton(
    IconData icon,
    String label, {
    VoidCallback? onPressed,
    bool isPrimary = false,
  }) {
    if (isPrimary) {
      return ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: _isRecording ? Colors.red : primaryBlue,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12),
        ),
      );
    }
    return OutlinedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: OutlinedButton.styleFrom(
        foregroundColor: primaryBlue,
        side: const BorderSide(color: primaryBlue),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        padding: const EdgeInsets.symmetric(vertical: 12),
      ),
    );
  }
}
