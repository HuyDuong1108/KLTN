import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../models/speaking_session.dart';
import '../../../models/word_error.dart';

class SpeakingReviewPage extends StatefulWidget {
  final SpeakingSession session;

  const SpeakingReviewPage({super.key, required this.session});

  @override
  State<SpeakingReviewPage> createState() => _SpeakingReviewPageState();
}

class _SpeakingReviewPageState extends State<SpeakingReviewPage> {
  // ================= COLORS =================
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color bgColor = Color(0xFFF6FAFF);
  static const Color errorRed = Color(0xFFE53935);
  static const Color successGreen = Color(0xFF4CAF50);
  static const Color warningOrange = Color(0xFFFFA726);
  static const Color lightOrange = Color(0xFFFFF3E0);
  static const Color textGrey = Color(0xFF607D8B);

  final FlutterTts _tts = FlutterTts();
  Set<ErrorType> _selectedErrorTypes = {};
  bool _showEnglish = false;

  @override
  void initState() {
    super.initState();
    _initTts();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("en-US");
    await _tts.setSpeechRate(0.45);
  }

  Future<void> _playTargetSentence() async {
    await _tts.speak(widget.session.targetSentence);
  }

  Future<void> _playWord(String word) async {
    await _tts.speak(word);
  }

  List<WordError> get _filteredErrors {
    if (_selectedErrorTypes.isEmpty) {
      return widget.session.wordErrors;
    }
    return widget.session.wordErrors
        .where((error) => _selectedErrorTypes.contains(error.errorType))
        .toList();
  }

  Color _getSeverityColor(int severity) {
    if (severity >= 8) return errorRed;
    if (severity >= 5) return warningOrange;
    return successGreen;
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
          "Speaking Review",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: Icon(
              _showEnglish ? Icons.translate : Icons.translate_outlined,
            ),
            onPressed: () => setState(() => _showEnglish = !_showEnglish),
            tooltip: _showEnglish ? "Show Vietnamese" : "Show English",
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _summaryCard(),
          const SizedBox(height: 24),
          _targetSentenceCard(),
          const SizedBox(height: 24),
          _highlightedTranscriptCard(),
          const SizedBox(height: 24),
          _errorTableCard(),
          const SizedBox(height: 24),
          _feedbackCard(),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _summaryCard() {
    final session = widget.session;
    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(22),
        gradient: LinearGradient(
          colors: session.overallScore >= 70
              ? [successGreen, successGreen.withOpacity(0.7)]
              : [primaryBlue, const Color(0xFF90CAF9)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            session.category ?? "Pronunciation Practice",
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 6),
          Text(
            "Band ${session.bandScore.toStringAsFixed(1)}",
            style: const TextStyle(
              fontSize: 32,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "Overall Score: ${session.overallScore}/100",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _miniStat("Duration", "${session.duration.inSeconds}s"),
              const SizedBox(width: 24),
              _miniStat("Errors", "${session.wordErrors.length}"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _miniStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 12),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ],
    );
  }

  Widget _targetSentenceCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Target Sentence",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            widget.session.targetSentence,
            style: const TextStyle(fontSize: 16, height: 1.5),
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _playTargetSentence,
            icon: const Icon(Icons.volume_up),
            label: const Text("Play Correct Pronunciation"),
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryBlue,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _highlightedTranscriptCard() {
    final words = widget.session.transcript.split(' ');
    final errorMap = <int, WordError>{};

    for (final error in widget.session.wordErrors) {
      if (error.position < words.length) {
        errorMap[error.position] = error;
      }
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Your Speech (Tap words for pronunciation)",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: words.asMap().entries.map((entry) {
              final index = entry.key;
              final word = entry.value;
              final error = errorMap[index];

              return GestureDetector(
                onTap: () {
                  _playWord(word);
                  if (error != null) {
                    _showErrorDialog(error);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: error != null
                        ? _getSeverityColor(error.severity).withOpacity(0.15)
                        : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: error != null
                        ? Border.all(
                            color: _getSeverityColor(error.severity),
                            width: 2,
                          )
                        : null,
                  ),
                  child: Text(
                    word,
                    style: TextStyle(
                      fontSize: 15,
                      color: error != null
                          ? _getSeverityColor(error.severity)
                          : Colors.black87,
                      fontWeight: error != null
                          ? FontWeight.bold
                          : FontWeight.normal,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              _legendItem(errorRed, "High (8-10)"),
              const SizedBox(width: 16),
              _legendItem(warningOrange, "Medium (5-7)"),
              const SizedBox(width: 16),
              _legendItem(successGreen, "Low (1-4)"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _legendItem(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12, color: textGrey)),
      ],
    );
  }

  void _showErrorDialog(WordError error) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Error: ${error.word}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Type: ${error.errorTypeLabel}'),
            const SizedBox(height: 8),
            Text('Severity: ${error.severity}/10'),
            if (error.expectedIPA != null) ...[
              const SizedBox(height: 8),
              Text('Expected: ${error.expectedIPA}'),
            ],
            if (error.actualIPA != null) ...[
              const SizedBox(height: 4),
              Text('Your pronunciation: ${error.actualIPA}'),
            ],
            const SizedBox(height: 12),
            Text(
              error.tip,
              style: const TextStyle(fontStyle: FontStyle.italic),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _playWord(error.word);
            },
            child: const Text('Play'),
          ),
        ],
      ),
    );
  }

  Widget _errorTableCard() {
    if (widget.session.wordErrors.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          children: [
            Icon(Icons.check_circle, color: successGreen, size: 48),
            const SizedBox(height: 12),
            const Text(
              "Perfect! No pronunciation errors detected.",
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      );
    }

    final filteredErrors = _filteredErrors;
    final sortedErrors = List<WordError>.from(filteredErrors)
      ..sort((a, b) => b.severity.compareTo(a.severity));

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Error Details",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: primaryBlue,
                ),
              ),
              Text(
                "${filteredErrors.length} / ${widget.session.wordErrors.length}",
                style: const TextStyle(color: textGrey),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _errorTypeFilter(),
          const SizedBox(height: 16),
          ...sortedErrors.map((error) => _errorRow(error)),
        ],
      ),
    );
  }

  Widget _errorTypeFilter() {
    final allTypes = ErrorType.values;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: allTypes.map((type) {
        final isSelected = _selectedErrorTypes.contains(type);
        final count = widget.session.wordErrors
            .where((e) => e.errorType == type)
            .length;

        if (count == 0) return const SizedBox.shrink();

        return FilterChip(
          label: Text('${type.name} ($count)'),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedErrorTypes.add(type);
              } else {
                _selectedErrorTypes.remove(type);
              }
            });
          },
          selectedColor: primaryBlue.withOpacity(0.2),
          checkmarkColor: primaryBlue,
        );
      }).toList(),
    );
  }

  Widget _errorRow(WordError error) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _getSeverityColor(error.severity).withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _getSeverityColor(error.severity).withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  error.word,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: _getSeverityColor(error.severity),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${error.severity}/10',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                icon: const Icon(Icons.volume_up, size: 20),
                onPressed: () => _playWord(error.word),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(_getErrorIcon(error.errorType), size: 16, color: textGrey),
              const SizedBox(width: 4),
              Text(
                error.errorTypeLabel,
                style: const TextStyle(
                  color: textGrey,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          if (error.expectedIPA != null || error.actualIPA != null) ...[
            const SizedBox(height: 8),
            if (error.expectedIPA != null)
              Text(
                'Expected: ${error.expectedIPA}',
                style: const TextStyle(fontSize: 13, color: textGrey),
              ),
            if (error.actualIPA != null)
              Text(
                'Yours: ${error.actualIPA}',
                style: const TextStyle(fontSize: 13, color: textGrey),
              ),
          ],
          const SizedBox(height: 8),
          Text(
            error.tip,
            style: const TextStyle(
              fontSize: 14,
              fontStyle: FontStyle.italic,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  IconData _getErrorIcon(ErrorType type) {
    switch (type) {
      case ErrorType.stress:
        return Icons.graphic_eq;
      case ErrorType.vowel:
        return Icons.record_voice_over;
      case ErrorType.consonant:
        return Icons.mic;
      case ErrorType.omission:
        return Icons.remove_circle_outline;
      case ErrorType.insertion:
        return Icons.add_circle_outline;
      case ErrorType.substitution:
        return Icons.swap_horiz;
    }
  }

  Widget _feedbackCard() {
    final feedback = widget.session.feedback;
    final summary = _showEnglish ? feedback.summaryEN : feedback.summaryVN;
    final tips = _showEnglish ? feedback.tipsEN : feedback.tipsVN;
    final nextSteps = _showEnglish
        ? feedback.nextStepsEN
        : feedback.nextStepsVN;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: lightOrange,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.psychology, color: primaryBlue),
              const SizedBox(width: 8),
              Text(
                _showEnglish ? "AI Coach Feedback" : "Phản hồi từ AI Coach",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (summary.isNotEmpty) ...[
            Text(summary, style: const TextStyle(fontSize: 15, height: 1.5)),
            const SizedBox(height: 16),
          ],
          if (tips.isNotEmpty) ...[
            Text(
              _showEnglish ? "Tips:" : "Mẹo:",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            ...tips.map(
              (tip) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text("💡 "),
                    Expanded(
                      child: Text(tip, style: const TextStyle(height: 1.4)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          if (nextSteps.isNotEmpty) ...[
            Text(
              _showEnglish ? "Next Steps:" : "Bước tiếp theo:",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Text(nextSteps, style: const TextStyle(height: 1.4)),
          ],
          if (feedback.improvementFocus.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 12),
            Text(
              _showEnglish ? "Focus Areas:" : "Tập trung vào:",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: feedback.improvementFocus.map((focus) {
                return Chip(
                  label: Text(focus),
                  backgroundColor: primaryBlue.withOpacity(0.1),
                  labelStyle: const TextStyle(
                    color: primaryBlue,
                    fontWeight: FontWeight.w600,
                  ),
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}
