import 'package:flutter/material.dart';
import '../../../models/ielts_speaking_session.dart';
import 'speaking_page.dart';

class IeltsSpeakingResultPage extends StatelessWidget {
  final IeltsSpeakingSession session;
  final String closingMessage;

  const IeltsSpeakingResultPage({
    super.key,
    required this.session,
    this.closingMessage = '',
  });

  // ── Colors ──────────────────────────────────────────────────
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color bgColor = Color(0xFFF6FAFF);
  static const Color textGrey = Color(0xFF607D8B);
  static const Color teal = Color(0xFF00897B);
  static const Color purple = Color(0xFF7B1FA2);

  // ─────────────────────────────────────────────────────────────
  // Band color
  // ─────────────────────────────────────────────────────────────
  Color _bandColor(double band) {
    if (band >= 7.0) return Colors.green;
    if (band >= 5.5) return Colors.orange;
    if (band > 0) return Colors.red;
    return textGrey;
  }

  String _bandLabel(double band) {
    if (band >= 8.0) return 'Expert';
    if (band >= 7.0) return 'Good User';
    if (band >= 6.0) return 'Competent';
    if (band >= 5.0) return 'Modest';
    if (band >= 4.0) return 'Limited';
    if (band > 0) return 'Beginner';
    return '—';
  }

  // ─────────────────────────────────────────────────────────────
  // Build
  // ─────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: Colors.white,
        foregroundColor: primaryBlue,
        elevation: 0,
        title: const Text(
          'Test Results',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        automaticallyImplyLeading: false,
        actions: [
          TextButton.icon(
            onPressed: () => Navigator.pushAndRemoveUntil(
              context,
              MaterialPageRoute(builder: (_) => const SpeakingPage()),
              (route) => false,
            ),
            icon: const Icon(Icons.home_outlined, size: 18),
            label: const Text('Home'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _overallBandCard(),
          const SizedBox(height: 16),
          _partScoresRow(),
          const SizedBox(height: 16),
          if (closingMessage.isNotEmpty) ...[
            _examinerMessageCard(),
            const SizedBox(height: 16),
          ],
          _cueCardCard(),
          const SizedBox(height: 16),
          _turnsSection(
            'Part 1 — Introduction & Interview',
            session.part1Turns,
            primaryBlue,
          ),
          const SizedBox(height: 12),
          if (session.part2Turn != null) ...[
            _turnsSection('Part 2 — Individual Long Turn', [
              session.part2Turn!,
            ], purple),
            const SizedBox(height: 12),
          ],
          _turnsSection(
            'Part 3 — Two-way Discussion',
            session.part3Turns,
            teal,
          ),
          const SizedBox(height: 32),
          _doneButton(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Overall band hero card
  // ─────────────────────────────────────────────────────────────
  Widget _overallBandCard() {
    final band = session.overallBand;
    final color = _bandColor(band);
    final label = _bandLabel(band);
    final dur = session.duration;
    final mins = dur.inMinutes;
    final secs = dur.inSeconds % 60;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withOpacity(0.85), color],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          const Text(
            'Overall Band Score',
            style: TextStyle(
              color: Colors.white70,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            band > 0 ? band.toStringAsFixed(1) : '—',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 64,
              fontWeight: FontWeight.bold,
              height: 1,
            ),
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _statChip(
                Icons.access_time,
                '${mins}m ${secs.toString().padLeft(2, '0')}s',
              ),
              const SizedBox(width: 12),
              _statChip(Icons.headset_mic, 'IELTS Test'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.18),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Per-part scores row
  // ─────────────────────────────────────────────────────────────
  Widget _partScoresRow() {
    return Row(
      children: [
        Expanded(
          child: _partBandCard(
            'Part 1',
            session.part1Band,
            Icons.chat_bubble_outline,
            primaryBlue,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _partBandCard(
            'Part 2',
            session.part2Band,
            Icons.record_voice_over,
            purple,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _partBandCard(
            'Part 3',
            session.part3Band,
            Icons.forum_outlined,
            teal,
          ),
        ),
      ],
    );
  }

  Widget _partBandCard(String label, double band, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(height: 8),
          Text(
            band > 0 ? band.toStringAsFixed(1) : '—',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: _bandColor(band),
            ),
          ),
          const SizedBox(height: 2),
          Text(label, style: const TextStyle(fontSize: 11, color: textGrey)),
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // 4-criteria bar card
  // ─────────────────────────────────────────────────────────────
  Widget _criteriaCard() {
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
          const Row(
            children: [
              Icon(Icons.analytics_outlined, color: primaryBlue, size: 20),
              SizedBox(width: 8),
              Text(
                'IELTS Speaking Criteria',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _criteriaRow('Fluency & Coherence', session.avgFluency, Colors.blue),
          const SizedBox(height: 12),
          _criteriaRow('Lexical Resource', session.avgLexical, Colors.purple),
          const SizedBox(height: 12),
          _criteriaRow('Grammatical Range', session.avgGrammar, Colors.orange),
          const SizedBox(height: 12),
          _criteriaRow('Pronunciation', session.avgPronunciation, Colors.teal),
        ],
      ),
    );
  }

  Widget _criteriaRow(String label, double score, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: textGrey)),
            Text(
              score > 0 ? score.toStringAsFixed(1) : '—',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: color,
              ),
            ),
          ],
        ),
        const SizedBox(height: 5),
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: LinearProgressIndicator(
            value: score > 0 ? score / 9.0 : 0,
            backgroundColor: Colors.grey.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Examiner closing message
  // ─────────────────────────────────────────────────────────────
  Widget _examinerMessageCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F2FD),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: primaryBlue.withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(
              color: primaryBlue,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.school, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Examiner\'s Remarks',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                    color: primaryBlue,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  closingMessage,
                  style: const TextStyle(
                    fontSize: 13,
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

  // ─────────────────────────────────────────────────────────────
  // Cue card reminder
  // ─────────────────────────────────────────────────────────────
  Widget _cueCardCard() {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: purple.withOpacity(0.25), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: purple.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: const Text(
                  'PART 2 TASK CARD',
                  style: TextStyle(
                    color: purple,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            session.cueCard.topic,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              height: 1.4,
            ),
          ),
          if (session.cueCard.bulletPoints.isNotEmpty) ...[
            const SizedBox(height: 8),
            ...session.cueCard.bulletPoints.map(
              (b) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 5),
                      child: Icon(Icons.circle, size: 5, color: purple),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        b,
                        style: const TextStyle(fontSize: 12, color: textGrey),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ─────────────────────────────────────────────────────────────
  // Turn-by-turn feedback section
  // ─────────────────────────────────────────────────────────────
  Widget _turnsSection(String title, List<IeltsTurn> turns, Color color) {
    if (turns.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  color: color,
                ),
              ),
            ],
          ),
        ),
        ...turns.map((t) => _turnCard(t, color)),
      ],
    );
  }

  Widget _turnCard(IeltsTurn turn, Color color) {
    return _TurnCard(turn: turn, color: color);
  }

  // ─────────────────────────────────────────────────────────────
  // Done button
  // ─────────────────────────────────────────────────────────────
  Widget _doneButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () => Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const SpeakingPage()),
          (route) => false,
        ),
        icon: const Icon(Icons.done_all),
        label: const Text(
          'Done — Back to Speaking',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryBlue,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────
// Expandable turn card (stateful for expand/collapse)
// ─────────────────────────────────────────────────────────────
class _TurnCard extends StatefulWidget {
  final IeltsTurn turn;
  final Color color;
  const _TurnCard({required this.turn, required this.color});

  @override
  State<_TurnCard> createState() => _TurnCardState();
}

class _TurnCardState extends State<_TurnCard> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final t = widget.turn;
    final color = widget.color;
    final isSkipped = t.isSkipped;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSkipped ? Colors.grey.shade200 : color.withOpacity(0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Header row
          InkWell(
            onTap: isSkipped
                ? null
                : () => setState(() => _expanded = !_expanded),
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: isSkipped
                          ? Colors.grey.shade100
                          : color.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      'Q${t.turnIndex + 1}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: isSkipped ? Colors.grey : color,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t.question,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: isSkipped ? Colors.grey : Colors.black87,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (isSkipped)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Text(
                        'Skipped',
                        style: TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    )
                  else ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        t.overallBand.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Icon(
                      _expanded ? Icons.expand_less : Icons.expand_more,
                      color: Colors.grey,
                      size: 18,
                    ),
                  ],
                ],
              ),
            ),
          ),

          // Expanded detail
          if (_expanded && !isSkipped) ...[
            const Divider(height: 1),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Transcript
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Your answer:',
                          style: TextStyle(
                            fontSize: 11,
                            color: Color(0xFF607D8B),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          t.transcript,
                          style: const TextStyle(fontSize: 13, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Mini criteria bars
                  _miniCriteria('Fluency', t.fluencyScore, Colors.blue),
                  const SizedBox(height: 6),
                  _miniCriteria('Lexical', t.lexicalScore, Colors.purple),
                  const SizedBox(height: 6),
                  _miniCriteria('Grammar', t.grammarScore, Colors.orange),
                  const SizedBox(height: 6),
                  _miniCriteria(
                    'Pronunciation',
                    t.pronunciationScore,
                    Colors.teal,
                  ),
                  const SizedBox(height: 12),

                  // Feedback VN
                  if (t.feedbackVN.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: color.withOpacity(0.15)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.comment_outlined, color: color, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              t.feedbackVN,
                              style: const TextStyle(fontSize: 12, height: 1.4),
                            ),
                          ),
                        ],
                      ),
                    ),

                  // Improvement tip
                  if (t.improvementTip.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.lightbulb_outline,
                          color: Colors.amber,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            t.improvementTip,
                            style: const TextStyle(
                              fontSize: 12,
                              height: 1.4,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Strengths & weaknesses
                  if (t.strengths.isNotEmpty || t.weaknesses.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (t.strengths.isNotEmpty)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.check_circle_outline,
                                      color: Colors.green,
                                      size: 14,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'Strengths',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ...t.strengths.map(
                                  (s) => Padding(
                                    padding: const EdgeInsets.only(bottom: 3),
                                    child: Text(
                                      '• $s',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF607D8B),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        if (t.strengths.isNotEmpty && t.weaknesses.isNotEmpty)
                          const SizedBox(width: 12),
                        if (t.weaknesses.isNotEmpty)
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: Colors.orange,
                                      size: 14,
                                    ),
                                    SizedBox(width: 4),
                                    Text(
                                      'To Improve',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.orange,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                ...t.weaknesses.map(
                                  (w) => Padding(
                                    padding: const EdgeInsets.only(bottom: 3),
                                    child: Text(
                                      '• $w',
                                      style: const TextStyle(
                                        fontSize: 11,
                                        color: Color(0xFF607D8B),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _miniCriteria(String label, double score, Color color) {
    return Row(
      children: [
        SizedBox(
          width: 88,
          child: Text(
            label,
            style: const TextStyle(fontSize: 11, color: Color(0xFF607D8B)),
          ),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: score > 0 ? score / 9.0 : 0,
              backgroundColor: Colors.grey.shade100,
              valueColor: AlwaysStoppedAnimation<Color>(color),
              minHeight: 6,
            ),
          ),
        ),
        const SizedBox(width: 6),
        SizedBox(
          width: 26,
          child: Text(
            score > 0 ? score.toStringAsFixed(1) : '—',
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
