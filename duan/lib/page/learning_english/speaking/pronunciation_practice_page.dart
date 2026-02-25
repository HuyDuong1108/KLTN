import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../data/speaking_gemini_service.dart';
import '../../../data/speaking_session_store.dart';
import '../../../data/google_cloud_speech_service.dart';
import '../../../models/speaking_session.dart';
import 'speaking_review_page.dart';

class PronunciationPracticePage extends StatefulWidget {
  const PronunciationPracticePage({super.key});

  @override
  State<PronunciationPracticePage> createState() =>
      _PronunciationPracticePageState();
}

class _PronunciationPracticePageState extends State<PronunciationPracticePage> {
  // ================= COLORS =================
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color lightBlue = Color(0xFFE3F2FD);
  static const Color bgColor = Color(0xFFF6FAFF);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFFA726);
  static const Color textGrey = Color(0xFF607D8B);

  // ================= STATE =================
  final FlutterTts _tts = FlutterTts();
  final _geminiService = SpeakingGeminiService.instance;
  final _sessionStore = SpeakingSessionStore.instance;
  final _cloudSpeech = GoogleCloudSpeechService.instance;

  String _selectedCategory = "Individual Sounds";
  String _targetSentence = "";
  String _transcript = "";
  Map<String, double> _confidenceScores = {};
  bool _isRecording = false;
  bool _isUploading = false;
  bool _isAnalyzing = false;
  bool _isGenerating = false;
  SpeakingSession? _currentSession;
  DateTime? _recordingStartTime;
  String? _recordingPath;

  @override
  void initState() {
    super.initState();
    _initTts();
    _generateNewSentence();
  }

  @override
  void dispose() {
    // Do NOT dispose the GoogleCloudSpeechService singleton from a page
    _tts.stop();
    super.dispose();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.45);
  }

  Future<void> _generateNewSentence() async {
    // Prevent firing a second request while one is already in-flight.
    // Without this guard, selecting a category while the page is still
    // loading its first sentence fires 2 concurrent Gemini requests,
    // which can immediately trigger a 429 even on paid Tier 1.
    if (_isGenerating) return;

    setState(() {
      _isGenerating = true;
      _currentSession = null;
      _transcript = "";
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
        _transcript = "";
        _confidenceScores = {};
        _recordingStartTime = DateTime.now();
      });

      final path = await _cloudSpeech.startRecording();
      setState(() {
        _recordingPath = path;
      });
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
      _isUploading = true;
    });

    try {
      final path = await _cloudSpeech.stopRecording();

      if (path == null || path.isEmpty) {
        throw Exception('Recording path is empty');
      }

      // Upload and recognize speech
      final result = await _cloudSpeech.recognizeSpeech(
        audioFilePath: path,
        languageCode: 'en-US',
      );

      setState(() {
        _transcript = result.transcript;
        _confidenceScores = result.wordConfidences;
        _isUploading = false;
      });

      if (_transcript.isNotEmpty) {
        await _analyzeTranscript();
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No speech detected. Please try again.'),
            ),
          );
        }
      }
    } catch (e) {
      setState(() => _isUploading = false);
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Failed to process audio: $e')));
      }
    }
  }

  Future<void> _analyzeTranscript() async {
    if (_transcript.isEmpty || _targetSentence.isEmpty) return;
    // Prevent double-fire (e.g. tapping Retry while a call is already running)
    if (_isAnalyzing) return;

    setState(() => _isAnalyzing = true);

    try {
      final duration = _recordingStartTime != null
          ? DateTime.now().difference(_recordingStartTime!)
          : const Duration(seconds: 5);

      final result = await _geminiService.analyzeTranscript(
        targetSentence: _targetSentence,
        userTranscript: _transcript,
        confidenceScores: _confidenceScores,
        category: _selectedCategory,
      );

      final session = SpeakingSession(
        sessionId: '',
        userId: '',
        timestamp: DateTime.now(),
        targetSentence: _targetSentence,
        transcript: _transcript,
        overallScore: result.overallScore,
        bandScore: result.bandScore,
        duration: duration,
        confidenceScores: _confidenceScores,
        wordErrors: result.wordErrors,
        feedback: result.feedback,
        category: _selectedCategory,
      );

      // Save to Firestore
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
                // Wait 2 s so the previous server-side request can finish
                // before we fire a new one — avoids back-to-back 429s.
                await Future.delayed(const Duration(seconds: 2));
                if (mounted) _analyzeTranscript();
              },
            ),
          ),
        );
      }
    }
  }

  Future<void> _playTargetSentence() async {
    if (_targetSentence.isNotEmpty) {
      await _tts.speak(_targetSentence);
    }
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
          if (_currentSession != null) _feedbackCard(),
        ],
      ),
      bottomNavigationBar: _bottomControlBar(),
    );
  }

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
            _targetSentence.isEmpty
                ? "Generating sentence..."
                : _targetSentence,
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
                  onPressed: _targetSentence.isEmpty
                      ? null
                      : _playTargetSentence,
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
          if (_transcript.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            const Text(
              "Your Speech:",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 4),
            Text(
              _transcript,
              style: const TextStyle(fontSize: 15, color: textGrey),
            ),
          ],
          if (_isUploading) ...[
            const SizedBox(height: 16),
            const Center(
              child: Column(
                children: [
                  CircularProgressIndicator(),
                  SizedBox(height: 8),
                  Text("Uploading audio..."),
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
                  Text("Analyzing pronunciation..."),
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
                  "Score: ${_currentSession!.overallScore}/100 • Band ${((_currentSession!.bandScore * 2).round() / 2).toStringAsFixed(1)}",
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
            "AI Feedback",
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
            ...feedback.tipsVN
                .take(3)
                .map(
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
              "Found ${_currentSession!.wordErrors.length} pronunciation errors",
              style: const TextStyle(
                color: warningOrange,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ],
      ),
    );
  }

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
