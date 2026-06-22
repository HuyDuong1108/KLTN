import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'ielts_speaking_test_page.dart';
import 'ai_speaking_partner_page.dart';
import 'ai_partner_review_page.dart';
import 'pronunciation_practice_page.dart';
import 'gemini_live_voice_page.dart';
import 'speaking_review_page.dart';
import 'speaking_user_guide_page.dart';
import '../../../data/speaking_session_store.dart';
import '../../../data/ai_partner_store.dart';
import '../../../models/speaking_session.dart';
import '../../../models/ai_partner_session.dart';
import '../../../data/ielts_speaking_store.dart';
import '../../../models/ielts_speaking_session.dart';
import 'ielts_speaking_result_page.dart';

class SpeakingPage extends StatefulWidget {
  const SpeakingPage({super.key});

  @override
  State<SpeakingPage> createState() => _SpeakingPageState();
}

class _SpeakingPageState extends State<SpeakingPage>
    with SingleTickerProviderStateMixin {
  static const Color primaryBlue = Color(0xFF1976D2);
  static const Color bgColor = Color(0xFFF6FAFF);
  static const Color textGrey = Color(0xFF607D8B);

  late TabController _tabController;
  final _sessionStore = SpeakingSessionStore.instance;
  final _aiPartnerStore = AiPartnerStore.instance;
  final _ieltsStore = IeltsSpeakingStore.instance;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          "Speaking",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SpeakingUserGuidePage(),
                ),
              );
            },
            tooltip: "Hướng dẫn sử dụng",
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: primaryBlue,
          unselectedLabelColor: textGrey,
          indicatorColor: primaryBlue,
          tabs: const [
            Tab(text: "Practice"),
            Tab(text: "Progress"),
            Tab(text: "History"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_practiceTab(), _progressTab(), _historyTab()],
      ),
    );
  }

  Widget _practiceTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _overallSpeakingCard(),
        const SizedBox(height: 28),
        const Text(
          "Practice Modes",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const IeltsSpeakingTestPage(),
              ),
            );
          },
          child: _modeCard(
            icon: Icons.headset_mic,
            title: "IELTS Speaking Test",
            subtitle: "Simulate real IELTS speaking exam",
            color: primaryBlue,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const AISpeakingPartnerPage(),
              ),
            );
          },
          child: _modeCard(
            icon: Icons.chat_bubble_outline,
            title: "AI Speaking Partner",
            subtitle: "Practice speaking like a real conversation",
            color: Colors.teal,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const PronunciationPracticePage(),
              ),
            );
          },
          child: _modeCard(
            icon: Icons.record_voice_over,
            title: "Pronunciation Practice",
            subtitle: "Improve pronunciation & intonation",
            color: Colors.orange,
          ),
        ),
        GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const GeminiLiveVoicePage(),
              ),
            );
          },
          child: _modeCard(
            icon: Icons.graphic_eq,
            title: "Live Voice Companion",
            subtitle: "Real-time voice chat with Gemini",
            color: Colors.deepPurple,
          ),
        ),
      ],
    );
  }

  Widget _progressTab() {
    return StreamBuilder<SpeakingStats>(
      stream: _sessionStore.watchStats(),
      builder: (context, statsSnap) {
        return StreamBuilder<List<SpeakingSession>>(
          stream: _sessionStore.watchSessions(limit: 20),
          builder: (context, pronSnap) {
            return StreamBuilder<List<AiPartnerSession>>(
              stream: _aiPartnerStore.watchSessions(limit: 20),
              builder: (context, aiSnap) {
                return StreamBuilder<List<IeltsSpeakingSession>>(
                  stream: _ieltsStore.watchSessions(limit: 20),
                  builder: (context, ieltsSnap) {
                    if (statsSnap.connectionState == ConnectionState.waiting ||
                        pronSnap.connectionState == ConnectionState.waiting ||
                        aiSnap.connectionState == ConnectionState.waiting ||
                        ieltsSnap.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    final stats = statsSnap.data;
                    final pronSessions = pronSnap.data ?? [];
                    final aiSessions = aiSnap.data ?? [];
                    final ieltsSessions = ieltsSnap.data ?? [];
                    final hasAnyData =
                        (stats != null && stats.totalSessions > 0) ||
                        aiSessions.isNotEmpty ||
                        ieltsSessions.isNotEmpty;

                    if (!hasAnyData) {
                      return _progressEmptyState();
                    }

                    return ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      children: [
                        _dashboardSummaryRow(stats, aiSessions, ieltsSessions),
                        const SizedBox(height: 20),
                        if (stats != null && stats.commonErrors.isNotEmpty) ...[
                          _errorBreakdownCard(stats),
                          const SizedBox(height: 20),
                        ],
                        _recentActivityCard(pronSessions, aiSessions),
                        const SizedBox(height: 20),
                        _achievementsCard(stats, aiSessions, ieltsSessions),
                      ],
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _progressEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.bar_chart, size: 72, color: textGrey.withOpacity(0.3)),
          const SizedBox(height: 16),
          const Text(
            'No data yet',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textGrey,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Complete a practice session\nto see your progress here',
            textAlign: TextAlign.center,
            style: TextStyle(color: textGrey),
          ),
        ],
      ),
    );
  }

  // ── 1. Summary KPI row ──────────────────────────────────────
  Widget _dashboardSummaryRow(
    SpeakingStats? stats,
    List<AiPartnerSession> aiSessions,
    List<IeltsSpeakingSession> ieltsSessions,
  ) {
    final pronCount = stats?.totalSessions ?? 0;
    final aiCount = aiSessions.length;
    final ieltsCount = ieltsSessions.length;
    final totalSessions = pronCount + aiCount + ieltsCount;

    double overallBand = 0;
    if (aiSessions.isNotEmpty) {
      final aiAvg =
          aiSessions.map((s) => s.overallBand).reduce((a, b) => a + b) /
          aiSessions.length;
      overallBand = aiAvg;
    } else if (stats != null && stats.averageBandScore > 0) {
      overallBand = stats.averageBandScore;
    }
    // Round to nearest IELTS 0.5
    final displayBand = overallBand > 0 ? (overallBand * 2).round() / 2 : 0.0;
    final bandColor = displayBand >= 7.0
        ? Colors.green
        : displayBand >= 5.5
        ? Colors.orange
        : displayBand > 0
        ? Colors.red
        : textGrey;

    return Row(
      children: [
        Expanded(
          child: _kpiCard(
            icon: Icons.layers,
            iconColor: primaryBlue,
            label: 'Total\nSessions',
            value: '$totalSessions',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _kpiCard(
            icon: Icons.grade,
            iconColor: bandColor,
            label: 'Overall\nBand',
            value: displayBand > 0 ? displayBand.toStringAsFixed(1) : '—',
            valueColor: bandColor,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _kpiCard(
            icon: Icons.smart_toy,
            iconColor: const Color(0xFF00897B),
            label: 'AI Conv.\nSessions',
            value: '$aiCount',
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _kpiCard(
            icon: Icons.headset_mic,
            iconColor: const Color(0xFF7B1FA2),
            label: 'IELTS\nTests',
            value: '$ieltsCount',
          ),
        ),
      ],
    );
  }

  Widget _kpiCard({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    Color? valueColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
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
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: iconColor.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: valueColor ?? primaryBlue,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, color: textGrey),
          ),
        ],
      ),
    );
  }

  // ── 2. AI 4-Criteria card ────────────────────────────────────
  Widget _aiCriteriaCard(List<AiPartnerSession> aiSessions) {
    if (aiSessions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Row(
          children: [
            const Icon(Icons.smart_toy, color: Color(0xFF00897B), size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'AI Speaking Partner — bắt đầu hội thoại đầu tiên\nđể xem phân tích 4 tiêu chí IELTS',
                style: const TextStyle(color: textGrey, fontSize: 13),
              ),
            ),
          ],
        ),
      );
    }

    final fluency =
        aiSessions.map((s) => s.avgFluency).reduce((a, b) => a + b) /
        aiSessions.length;
    final lexical =
        aiSessions.map((s) => s.avgLexical).reduce((a, b) => a + b) /
        aiSessions.length;
    final grammar =
        aiSessions.map((s) => s.avgGrammar).reduce((a, b) => a + b) /
        aiSessions.length;
    final pronunciation =
        aiSessions.map((s) => s.avgPronunciation).reduce((a, b) => a + b) /
        aiSessions.length;

    const teal = Color(0xFF00897B);

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
              const Icon(Icons.smart_toy, color: teal, size: 20),
              const SizedBox(width: 8),
              const Text(
                'IELTS Speaking — 4 Tiêu Chí',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: teal,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: teal.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${aiSessions.length} sessions',
                  style: const TextStyle(
                    fontSize: 11,
                    color: teal,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _criteriaRow('Fluency & Coherence', fluency, Colors.blue),
          const SizedBox(height: 12),
          _criteriaRow('Lexical Resource', lexical, Colors.purple),
          const SizedBox(height: 12),
          _criteriaRow('Grammatical Range', grammar, Colors.orange),
          const SizedBox(height: 12),
          _criteriaRow('Pronunciation', pronunciation, Colors.teal),
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
              score.toStringAsFixed(1),
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
            value: score / 9.0,
            backgroundColor: Colors.grey.shade100,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 8,
          ),
        ),
      ],
    );
  }

  // ── 3. Band trend chart (both sources) ──────────────────────
  Widget _bandTrendCard(
    List<SpeakingSession> pronSessions,
    List<AiPartnerSession> aiSessions,
    List<IeltsSpeakingSession> ieltsSessions,
  ) {
    // Build a combined timeline of (date, band, source)
    final List<Map<String, dynamic>> combined = [
      ...pronSessions.map(
        (s) => {'date': s.timestamp, 'band': s.bandScore, 'source': 'pron'},
      ),
      ...aiSessions.map(
        (s) => {'date': s.startedAt, 'band': s.overallBand, 'source': 'ai'},
      ),
      ...ieltsSessions.map(
        (s) => {'date': s.startedAt, 'band': s.overallBand, 'source': 'ielts'},
      ),
    ];
    combined.sort(
      (a, b) => (a['date'] as DateTime).compareTo(b['date'] as DateTime),
    );

    // Take last 12
    final shown = combined.length > 12
        ? combined.sublist(combined.length - 12)
        : combined;

    // Single combined series with colored dots per source
    final allSpots = <FlSpot>[];
    for (int i = 0; i < shown.length; i++) {
      final band = (shown[i]['band'] as double).clamp(0.0, 9.0);
      allSpots.add(FlSpot(i.toDouble(), band));
    }

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
              const Icon(Icons.show_chart, color: primaryBlue, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Band Score Trend',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Legend
          Wrap(
            spacing: 14,
            runSpacing: 4,
            children: [
              _legendDot(primaryBlue, 'Pronunciation'),
              _legendDot(const Color(0xFF00897B), 'AI Partner'),
              _legendDot(const Color(0xFF7B1FA2), 'IELTS Test'),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                clipData: const FlClipData.all(),
                minX: 0,
                maxX: shown.isEmpty ? 1 : (shown.length - 1).toDouble(),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (v) =>
                      FlLine(color: Colors.grey.shade100, strokeWidth: 1),
                ),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 32,
                      interval: 1,
                      getTitlesWidget: (v, _) => Text(
                        v.toInt().toString(),
                        style: const TextStyle(fontSize: 10, color: textGrey),
                      ),
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 22,
                      interval: 1,
                      getTitlesWidget: (v, meta) {
                        final i = v.toInt();
                        if (i < 0 || i >= shown.length) {
                          return const SizedBox.shrink();
                        }
                        final d = shown[i]['date'] as DateTime;
                        return Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: Text(
                            '${d.day}/${d.month}',
                            style: const TextStyle(
                              fontSize: 9,
                              color: textGrey,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                  topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 1,
                maxY: 9,
                lineBarsData: [
                  if (allSpots.isNotEmpty)
                    LineChartBarData(
                      spots: allSpots,
                      isCurved: allSpots.length > 2,
                      curveSmoothness: 0.3,
                      color: Colors.grey.shade300,
                      barWidth: 2,
                      dotData: FlDotData(
                        show: true,
                        getDotPainter: (spot, _, __, index) {
                          final src = shown[index]['source'] as String;
                          final c = src == 'pron'
                              ? primaryBlue
                              : src == 'ai'
                              ? const Color(0xFF00897B)
                              : const Color(0xFF7B1FA2);
                          return FlDotCirclePainter(
                            radius: 5,
                            color: c,
                            strokeWidth: 2,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        color: primaryBlue.withOpacity(0.04),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 11, color: textGrey)),
      ],
    );
  }

  // ── 4. Error breakdown ────────────────────────────────────────
  Widget _errorBreakdownCard(SpeakingStats stats) {
    final sorted = stats.commonErrors.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = sorted.take(5).toList();
    final total = stats.commonErrors.values.fold<int>(0, (s, c) => s + c);
    if (total == 0) return const SizedBox.shrink();

    final barColors = [
      Colors.red.shade400,
      Colors.orange.shade400,
      Colors.amber.shade400,
      Colors.blue.shade300,
      Colors.purple.shade300,
    ];

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
              const Icon(Icons.warning_amber, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              const Text(
                'Lỗi Phát Âm Hay Mắc',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...top.asMap().entries.map((e) {
            final idx = e.key;
            final entry = e.value;
            final pct = entry.value / total;
            final color = barColors[idx % barColors.length];
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  SizedBox(
                    width: 120,
                    child: Text(
                      entry.key,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: Colors.grey.shade100,
                        valueColor: AlwaysStoppedAnimation<Color>(color),
                        minHeight: 10,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    width: 36,
                    child: Text(
                      '${entry.value}',
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: 12,
                        color: color,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.08),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb, color: Colors.orange, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Tập trung cải thiện: ${top.first.key}',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.orange,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── 5. Recent activity ────────────────────────────────────────
  Widget _recentActivityCard(
    List<SpeakingSession> pron,
    List<AiPartnerSession> ai,
  ) {
    final List<Map<String, dynamic>> items = [
      ...pron
          .take(3)
          .map(
            (s) => {
              'title': s.category ?? 'Pronunciation',
              'sub':
                  'Band ${s.bandScore.toStringAsFixed(1)} · ${s.wordErrors.length} errors',
              'date': s.timestamp,
              'icon': Icons.record_voice_over,
              'color': primaryBlue,
            },
          ),
      ...ai
          .take(3)
          .map(
            (s) => {
              'title': s.isFreeMode ? 'Free Conversation' : s.topic,
              'sub':
                  'Band ${s.overallBand.toStringAsFixed(1)} · ${s.turns.length} turns',
              'date': s.startedAt,
              'icon': Icons.smart_toy,
              'color': const Color(0xFF00897B),
            },
          ),
    ];
    items.sort(
      (a, b) => (b['date'] as DateTime).compareTo(a['date'] as DateTime),
    );
    final shown = items.take(5).toList();
    if (shown.isEmpty) return const SizedBox.shrink();

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
              Icon(Icons.access_time, color: primaryBlue, size: 20),
              SizedBox(width: 8),
              Text(
                'Hoạt Động Gần Đây',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: primaryBlue,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...shown.map((item) {
            final date = item['date'] as DateTime;
            final color = item['color'] as Color;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      item['icon'] as IconData,
                      color: color,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item['title'] as String,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          item['sub'] as String,
                          style: const TextStyle(fontSize: 11, color: textGrey),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    _formatDate(date),
                    style: const TextStyle(fontSize: 11, color: textGrey),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  // ── 6. Achievements ──────────────────────────────────────────
  Widget _achievementsCard(
    SpeakingStats? stats,
    List<AiPartnerSession> aiSessions,
    List<IeltsSpeakingSession> ieltsSessions,
  ) {
    final pronCount = stats?.totalSessions ?? 0;
    final aiCount = aiSessions.length;
    final ieltsCount = ieltsSessions.length;
    final totalSessions = pronCount + aiCount + ieltsCount;
    final avgBand = stats?.averageBandScore ?? 0.0;
    final aiAvgBand = aiSessions.isEmpty
        ? 0.0
        : aiSessions.map((s) => s.overallBand).reduce((a, b) => a + b) /
              aiSessions.length;
    final ieltsAvgBand = ieltsSessions.isEmpty
        ? 0.0
        : ieltsSessions.map((s) => s.overallBand).reduce((a, b) => a + b) /
              ieltsSessions.length;

    final all = <Map<String, dynamic>>[
      {
        'title': 'Buổi đầu tiên',
        'icon': Icons.celebration,
        'color': Colors.amber,
        'unlocked': totalSessions >= 1,
        'desc': 'Hoàn thành 1 buổi luyện',
      },
      {
        'title': '5 Buổi liên tiếp',
        'icon': Icons.local_fire_department,
        'color': Colors.orange,
        'unlocked': totalSessions >= 5,
        'desc': '5 buổi luyện tập',
      },
      {
        'title': '10 Buổi',
        'icon': Icons.military_tech,
        'color': Colors.deepOrange,
        'unlocked': totalSessions >= 10,
        'desc': '10 buổi luyện tập',
      },
      {
        'title': 'AI Partner',
        'icon': Icons.smart_toy,
        'color': const Color(0xFF00897B),
        'unlocked': aiCount >= 1,
        'desc': 'Bắt đầu hội thoại AI',
      },
      {
        'title': 'Band 5.5+',
        'icon': Icons.stars,
        'color': Colors.blue,
        'unlocked': avgBand >= 5.5 || aiAvgBand >= 5.5 || ieltsAvgBand >= 5.5,
        'desc': 'Đạt Band 5.5',
      },
      {
        'title': 'Band 7.0+',
        'icon': Icons.emoji_events,
        'color': Colors.amber.shade700,
        'unlocked': avgBand >= 7.0 || aiAvgBand >= 7.0 || ieltsAvgBand >= 7.0,
        'desc': 'Đạt Band 7.0',
      },
      {
        'title': 'IELTS Test',
        'icon': Icons.headset_mic,
        'color': const Color(0xFF7B1FA2),
        'unlocked': ieltsCount >= 1,
        'desc': 'Hoàn thành IELTS test đầu tiên',
      },
      {
        'title': '3 IELTS Tests',
        'icon': Icons.workspace_premium,
        'color': const Color(0xFF7B1FA2),
        'unlocked': ieltsCount >= 3,
        'desc': 'Hoàn thành 3 IELTS tests',
      },
      {
        'title': 'IELTS Band 7+',
        'icon': Icons.star_purple500,
        'color': Colors.deepPurple,
        'unlocked': ieltsAvgBand >= 7.0,
        'desc': 'IELTS Band trung bình ≥ 7.0',
      },
    ];

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
              Icon(Icons.emoji_events, color: Colors.amber, size: 20),
              SizedBox(width: 8),
              Text(
                'Thành Tích',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 0.95,
            children: all.map((a) {
              final unlocked = a['unlocked'] as bool;
              final color = a['color'] as Color;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 6,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: unlocked
                      ? color.withOpacity(0.08)
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: unlocked
                        ? color.withOpacity(0.4)
                        : Colors.grey.shade200,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      a['icon'] as IconData,
                      color: unlocked ? color : textGrey.withOpacity(0.4),
                      size: 26,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      a['title'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: unlocked ? color : textGrey.withOpacity(0.5),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      a['desc'] as String,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 9,
                        color: unlocked ? textGrey : textGrey.withOpacity(0.35),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _historyTab() {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── AI Conversations Section ──
        Row(
          children: [
            const Icon(Icons.smart_toy, color: Color(0xFF00897B), size: 20),
            const SizedBox(width: 8),
            const Text(
              'AI Conversations',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF00897B),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<AiPartnerSession>>(
          stream: _aiPartnerStore.watchSessions(limit: 30),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final aiSessions = snapshot.data ?? [];
            if (aiSessions.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.smart_toy,
                        size: 40,
                        color: textGrey.withOpacity(0.4),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'No AI conversations yet',
                        style: TextStyle(color: textGrey),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Column(
              children: aiSessions
                  .map((s) => _aiPartnerSessionCard(s))
                  .toList(),
            );
          },
        ),

        const SizedBox(height: 24),

        // ── IELTS Tests Section ──
        const Row(
          children: [
            Icon(Icons.headset_mic, color: Color(0xFF7B1FA2), size: 20),
            SizedBox(width: 8),
            Text(
              'IELTS Tests',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Color(0xFF7B1FA2),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<IeltsSpeakingSession>>(
          stream: _ieltsStore.watchSessions(limit: 30),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final ieltsSessionsList = snapshot.data ?? [];
            if (ieltsSessionsList.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.headset_mic,
                        size: 40,
                        color: textGrey.withOpacity(0.4),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'No IELTS tests yet',
                        style: TextStyle(color: textGrey),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Column(
              children: ieltsSessionsList
                  .map((s) => _ieltsSessionCard(s))
                  .toList(),
            );
          },
        ),

        const SizedBox(height: 24),

        // ── Pronunciation Practice Section ──
        Row(
          children: [
            const Icon(Icons.record_voice_over, color: primaryBlue, size: 20),
            const SizedBox(width: 8),
            const Text(
              'Pronunciation Practice',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: primaryBlue,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        StreamBuilder<List<SpeakingSession>>(
          stream: _sessionStore.watchSessions(limit: 50),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 20),
                child: Center(child: CircularProgressIndicator()),
              );
            }
            final sessions = snapshot.data ?? [];
            if (sessions.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    children: [
                      Icon(
                        Icons.history,
                        size: 40,
                        color: textGrey.withOpacity(0.4),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'No practice sessions yet',
                        style: TextStyle(color: textGrey),
                      ),
                    ],
                  ),
                ),
              );
            }
            return Column(
              children: sessions.map((s) => _historySessionCard(s)).toList(),
            );
          },
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _aiPartnerSessionCard(AiPartnerSession session) {
    final Color bandColor = session.overallBand >= 7.0
        ? Colors.green
        : session.overallBand >= 5.5
        ? Colors.orange
        : Colors.red;
    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AiPartnerReviewPage(session: session),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFF00897B).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(
                Icons.smart_toy,
                color: Color(0xFF00897B),
                size: 24,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          session.isFreeMode
                              ? 'Free Conversation'
                              : session.topic,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: bandColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'Band ${session.overallBand.toStringAsFixed(1)}',
                          style: TextStyle(
                            color: bandColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${session.turns.length} turns',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Color(0xFF607D8B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF607D8B), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _ieltsSessionCard(IeltsSpeakingSession session) {
    const purple = Color(0xFF7B1FA2);
    final Color bandColor = session.overallBand >= 7.0
        ? Colors.green
        : session.overallBand >= 5.5
        ? Colors.orange
        : session.overallBand > 0
        ? Colors.red
        : textGrey;
    final dur = session.duration;
    final mins = dur.inMinutes;
    final secs = dur.inSeconds % 60;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => IeltsSpeakingResultPage(session: session),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.headset_mic, color: purple, size: 24),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          session.cueCard.topic,
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: bandColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          session.overallBand > 0
                              ? 'Band ${session.overallBand.toStringAsFixed(1)}'
                              : '—',
                          style: TextStyle(
                            color: bandColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'P1: ${session.part1Band.toStringAsFixed(1)}  '
                    'P2: ${session.part2Band > 0 ? session.part2Band.toStringAsFixed(1) : "—"}  '
                    'P3: ${session.part3Band.toStringAsFixed(1)}  '
                    '· ${mins}m${secs.toString().padLeft(2, '0')}s',
                    style: const TextStyle(fontSize: 11, color: textGrey),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: textGrey, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _overallSpeakingCard() {
    return StreamBuilder(
      stream: _sessionStore.watchStats(),
      builder: (context, snapshot) {
        final stats = snapshot.data;
        final raw = stats?.averageBandScore ?? 0.0;
        final rounded = ((raw * 2).round() / 2);
        final bandScore = raw > 0 ? rounded.toStringAsFixed(1) : '0.0';

        return Container(
          padding: const EdgeInsets.all(22),
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
                "Your Speaking Level",
                style: TextStyle(color: Colors.white70, fontSize: 14),
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
                style: const TextStyle(color: Colors.white),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _modeCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: color.withOpacity(0.15),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(subtitle, style: const TextStyle(color: textGrey)),
              ],
            ),
          ),
          const Icon(Icons.arrow_forward_ios, size: 16, color: textGrey),
        ],
      ),
    );
  }

  Widget _historySessionCard(SpeakingSession session) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => SpeakingReviewPage(session: session),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
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
                Expanded(
                  child: Text(
                    session.category ?? "Pronunciation Practice",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: primaryBlue.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    "Band ${session.bandScore.toStringAsFixed(1)}",
                    style: const TextStyle(
                      color: primaryBlue,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              session.targetSentence,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: textGrey, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(Icons.score, size: 16, color: textGrey),
                const SizedBox(width: 4),
                Text(
                  "${session.overallScore}/100",
                  style: const TextStyle(color: textGrey, fontSize: 13),
                ),
                const SizedBox(width: 16),
                Icon(Icons.error_outline, size: 16, color: textGrey),
                const SizedBox(width: 4),
                Text(
                  "${session.wordErrors.length} errors",
                  style: const TextStyle(color: textGrey, fontSize: 13),
                ),
                const Spacer(),
                Text(
                  _formatDate(session.timestamp),
                  style: const TextStyle(color: textGrey, fontSize: 12),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      return "Today";
    } else if (difference.inDays == 1) {
      return "Yesterday";
    } else if (difference.inDays < 7) {
      return "${difference.inDays} days ago";
    } else {
      return "${date.day}/${date.month}/${date.year}";
    }
  }
}
