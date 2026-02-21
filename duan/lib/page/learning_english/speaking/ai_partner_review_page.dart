import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../../../models/ai_partner_session.dart';
import '../../../models/conversation_turn.dart';

class AiPartnerReviewPage extends StatefulWidget {
  final AiPartnerSession session;
  const AiPartnerReviewPage({super.key, required this.session});

  @override
  State<AiPartnerReviewPage> createState() => _AiPartnerReviewPageState();
}

class _AiPartnerReviewPageState extends State<AiPartnerReviewPage> {
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color teal = Color(0xFF00897B);
  static const Color bgColor = Color(0xFFF6FAFF);
  static const Color textGrey = Color(0xFF607D8B);

  final FlutterTts _tts = FlutterTts();
  int? _playingIndex;

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('en-GB');
    _tts.setSpeechRate(0.58);
    _tts.setCompletionHandler(() {
      if (mounted) setState(() => _playingIndex = null);
    });
    _tts.setErrorHandler((_) {
      if (mounted) setState(() => _playingIndex = null);
    });
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _play(int index, String text) async {
    if (_playingIndex == index) {
      await _tts.stop();
      setState(() => _playingIndex = null);
    } else {
      await _tts.stop();
      setState(() => _playingIndex = index);
      await _tts.speak(text);
    }
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes;
    final s = d.inSeconds % 60;
    return '${m}m ${s}s';
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.session;
    final scoredTurns = session.turns
        .where((t) => t.userTranscript != '(skipped)')
        .toList();

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: primaryBlue,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              session.isFreeMode ? 'Free Conversation' : session.topic,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Band ${session.overallBand.toStringAsFixed(1)} - ${_formatDuration(session.duration)}',
              style: const TextStyle(fontSize: 12, color: textGrey),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildSummaryCard(session),
          const SizedBox(height: 20),
          if (session.closingMessage.isNotEmpty) ...[
            _buildClosingCard(session.closingMessage),
            const SizedBox(height: 20),
          ],
          _buildCriteriaCard(session),
          const SizedBox(height: 20),
          const Text(
            'Turn by Turn Review',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 12),
          ...scoredTurns.asMap().entries.map(
            (e) => _buildTurnCard(e.key + 1, e.value),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSummaryCard(AiPartnerSession session) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [primaryBlue, Colors.blue.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Overall Band',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              Text(
                session.overallBand.toStringAsFixed(1),
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 56,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _miniScore('Fluency', session.avgFluency),
                const SizedBox(height: 6),
                _miniScore('Lexical', session.avgLexical),
                const SizedBox(height: 6),
                _miniScore('Grammar', session.avgGrammar),
                const SizedBox(height: 6),
                _miniScore('Pronunciation', session.avgPronunciation),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniScore(String label, double score) {
    return Row(
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 12),
          ),
        ),
        Expanded(
          child: LinearProgressIndicator(
            value: score / 9.0,
            backgroundColor: Colors.white24,
            valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(
          score.toStringAsFixed(1),
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 13,
          ),
        ),
      ],
    );
  }

  Widget _buildClosingCard(String message) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: teal.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: teal.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.smart_toy, color: teal, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "AI's Closing Message",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: teal,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  message,
                  style: const TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: Colors.black87,
                  ),
                ),
              ],
            ),
          ),
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
            'Criteria Breakdown',
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
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: scoreColor.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        score.toStringAsFixed(1),
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: scoreColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
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

  Widget _buildTurnCard(int num, ConversationTurn turn) {
    final Color bandColor = turn.overallBand >= 7.0
        ? Colors.green
        : turn.overallBand >= 5.5
        ? Colors.orange
        : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.06),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(20),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: primaryBlue,
                  child: Text(
                    '$num',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'Turn $num',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: primaryBlue,
                    fontSize: 15,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: bandColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    'Band ${turn.overallBand.toStringAsFixed(1)}',
                    style: TextStyle(
                      color: bandColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // AI Question
                _contentBlock(
                  label: 'AI Question',
                  content: turn.aiQuestion,
                  icon: Icons.smart_toy,
                  iconColor: teal,
                  trailing: IconButton(
                    icon: Icon(
                      _playingIndex == (num * 10)
                          ? Icons.pause_circle
                          : Icons.play_circle_outline,
                      color: teal,
                      size: 24,
                    ),
                    onPressed: () => _play(num * 10, turn.aiQuestion),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ),
                const SizedBox(height: 12),

                // User Answer
                _contentBlock(
                  label: 'Your Answer',
                  content: turn.userTranscript,
                  icon: Icons.person_outline,
                  iconColor: primaryBlue,
                ),
                const SizedBox(height: 12),

                // AI Response (if any)
                if (turn.aiResponse.isNotEmpty) ...[
                  _contentBlock(
                    label: 'AI Response',
                    content: turn.aiResponse,
                    icon: Icons.chat_bubble_outline,
                    iconColor: teal,
                    trailing: IconButton(
                      icon: Icon(
                        _playingIndex == (num * 10 + 1)
                            ? Icons.pause_circle
                            : Icons.play_circle_outline,
                        color: teal,
                        size: 24,
                      ),
                      onPressed: () => _play(num * 10 + 1, turn.aiResponse),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Scores grid
                _buildScoreGrid(turn),
                const SizedBox(height: 12),

                // Feedback VN
                if (turn.feedbackVN.isNotEmpty) ...[
                  _contentBlock(
                    label: 'Feedback (VI)',
                    content: turn.feedbackVN,
                    icon: Icons.feedback_outlined,
                    iconColor: Colors.orange,
                  ),
                  const SizedBox(height: 12),
                ],

                // Improvement tip
                if (turn.improvementTip.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.amber.withOpacity(0.4)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          color: Colors.amber,
                          size: 18,
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            turn.improvementTip,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // Strengths & Weaknesses
                if (turn.strengths.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  _buildTagRow('Strengths', turn.strengths, Colors.green),
                ],
                if (turn.weaknesses.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  _buildTagRow('Improve', turn.weaknesses, Colors.orange),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _contentBlock({
    required String label,
    required String content,
    required IconData icon,
    required Color iconColor,
    Widget? trailing,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: iconColor,
              ),
            ),
            if (trailing != null) ...[const Spacer(), trailing],
          ],
        ),
        const SizedBox(height: 4),
        Text(
          content,
          style: const TextStyle(
            fontSize: 14,
            height: 1.5,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildScoreGrid(ConversationTurn turn) {
    return Row(
      children: [
        _scoreChip('Fluency', turn.fluencyScore),
        const SizedBox(width: 8),
        _scoreChip('Lexical', turn.lexicalScore),
        const SizedBox(width: 8),
        _scoreChip('Grammar', turn.grammarScore),
        const SizedBox(width: 8),
        _scoreChip('Pronun.', turn.pronunciationScore),
      ],
    );
  }

  Widget _scoreChip(String label, double score) {
    final Color c = score >= 7.0
        ? Colors.green
        : score >= 5.5
        ? Colors.orange
        : Colors.red;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
          color: c.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: c.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text(
              score.toStringAsFixed(1),
              style: TextStyle(
                color: c,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: const TextStyle(fontSize: 10, color: textGrey),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTagRow(String title, List<String> items, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: items
              .map(
                (item) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: color.withOpacity(0.4)),
                  ),
                  child: Text(
                    item,
                    style: TextStyle(fontSize: 12, color: color),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}
