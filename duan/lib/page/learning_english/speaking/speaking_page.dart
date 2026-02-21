import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'ielts_speaking_test_page.dart';
import 'ai_speaking_partner_page.dart';
import 'ai_partner_review_page.dart';
import 'pronunciation_practice_page.dart';
import 'speaking_review_page.dart';
import 'speaking_user_guide_page.dart';
import '../../../data/speaking_session_store.dart';
import '../../../data/ai_partner_store.dart';
import '../../../models/speaking_session.dart';
import '../../../models/ai_partner_session.dart';

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
      ],
    );
  }

  Widget _progressTab() {
    return StreamBuilder(
      stream: _sessionStore.watchStats(),
      builder: (context, statsSnapshot) {
        final stats = statsSnapshot.data;

        return FutureBuilder<List<SpeakingSession>>(
          future: _sessionStore.getSessions(limit: 20),
          builder: (context, sessionsSnapshot) {
            if (!sessionsSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator());
            }

            final sessions = sessionsSnapshot.data!;

            return ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _statsOverviewCard(stats),
                const SizedBox(height: 24),
                _bandScoreChartCard(sessions),
                const SizedBox(height: 24),
                _errorBreakdownCard(stats),
                const SizedBox(height: 24),
                _achievementsCard(stats),
              ],
            );
          },
        );
      },
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

  Widget _overallSpeakingCard() {
    return StreamBuilder(
      stream: _sessionStore.watchStats(),
      builder: (context, snapshot) {
        final stats = snapshot.data;
        final bandScore = stats?.averageBandScore.toStringAsFixed(1) ?? "0.0";

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

  Widget _statsOverviewCard(stats) {
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
            "Statistics Overview",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _statItem(
                "Total",
                "${stats?.totalSessions ?? 0}",
                Icons.headset_mic,
              ),
              _statItem(
                "Avg Band",
                stats?.averageBandScore.toStringAsFixed(1) ?? "0.0",
                Icons.grade,
              ),
              _statItem(
                "Errors",
                "${stats?.commonErrors.values.fold<int>(0, (sum, count) => sum + count) ?? 0}",
                Icons.warning_amber,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statItem(String label, String value, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: primaryBlue, size: 32),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: primaryBlue,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(color: textGrey, fontSize: 13)),
      ],
    );
  }

  Widget _bandScoreChartCard(List<SpeakingSession> sessions) {
    if (sessions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Center(child: Text("No data to display yet")),
      );
    }

    final recentSessions = sessions.take(10).toList().reversed.toList();

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
            "Band Score Progress",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 200,
            child: LineChart(
              LineChartData(
                gridData: FlGridData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      reservedSize: 40,
                      getTitlesWidget: (value, meta) {
                        return Text(
                          value.toInt().toString(),
                          style: const TextStyle(fontSize: 12),
                        );
                      },
                    ),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        if (index >= 0 && index < recentSessions.length) {
                          return Text(
                            (index + 1).toString(),
                            style: const TextStyle(fontSize: 12),
                          );
                        }
                        return const Text('');
                      },
                    ),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                ),
                borderData: FlBorderData(show: false),
                minY: 0,
                maxY: 9,
                lineBarsData: [
                  LineChartBarData(
                    spots: recentSessions
                        .asMap()
                        .entries
                        .map((e) => FlSpot(e.key.toDouble(), e.value.bandScore))
                        .toList(),
                    isCurved: true,
                    color: primaryBlue,
                    barWidth: 3,
                    dotData: FlDotData(show: true),
                    belowBarData: BarAreaData(
                      show: true,
                      color: primaryBlue.withOpacity(0.1),
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

  Widget _errorBreakdownCard(stats) {
    if (stats == null || stats.commonErrors.isEmpty) {
      return const SizedBox.shrink();
    }

    final sortedErrors = stats.commonErrors.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

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
            "Most Common Errors",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          ...sortedErrors.take(5).map((entry) {
            final total = stats.commonErrors.values.fold<int>(
              0,
              (sum, count) => sum + count,
            );
            final percentage = (entry.value / total * 100).round();

            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        entry.key,
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                      Text(
                        "${entry.value} ($percentage%)",
                        style: const TextStyle(color: textGrey),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  LinearProgressIndicator(
                    value: entry.value / total,
                    backgroundColor: Colors.grey.shade200,
                    valueColor: AlwaysStoppedAnimation<Color>(primaryBlue),
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryBlue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.lightbulb, color: primaryBlue, size: 20),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Focus on practicing ${sortedErrors.first.key} errors",
                    style: const TextStyle(
                      color: primaryBlue,
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

  Widget _achievementsCard(stats) {
    final achievements = <Map<String, dynamic>>[];

    if (stats != null && stats.totalSessions >= 1) {
      achievements.add({
        'title': 'First Session',
        'icon': Icons.celebration,
        'unlocked': true,
      });
    }

    if (stats != null && stats.totalSessions >= 10) {
      achievements.add({
        'title': '10 Sessions',
        'icon': Icons.local_fire_department,
        'unlocked': true,
      });
    }

    if (stats != null && stats.averageBandScore >= 6.0) {
      achievements.add({
        'title': 'Band 6.0',
        'icon': Icons.stars,
        'unlocked': true,
      });
    }

    if (stats != null && stats.averageBandScore >= 7.0) {
      achievements.add({
        'title': 'Band 7.0',
        'icon': Icons.emoji_events,
        'unlocked': true,
      });
    }

    // Add locked achievements
    if (stats == null || stats.totalSessions < 10) {
      achievements.add({
        'title': '10 Sessions',
        'icon': Icons.lock,
        'unlocked': false,
      });
    }

    if (stats == null || stats.averageBandScore < 7.0) {
      achievements.add({
        'title': 'Band 7.0',
        'icon': Icons.lock,
        'unlocked': false,
      });
    }

    if (achievements.isEmpty) return const SizedBox.shrink();

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
            "Achievements",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: primaryBlue,
            ),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: achievements.map((achievement) {
              final unlocked = achievement['unlocked'] as bool;
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: unlocked ? Colors.amber.shade50 : Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: unlocked ? Colors.amber : Colors.grey.shade300,
                    width: 2,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      achievement['icon'] as IconData,
                      color: unlocked ? Colors.amber.shade700 : textGrey,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      achievement['title'] as String,
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: unlocked ? Colors.amber.shade900 : textGrey,
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
