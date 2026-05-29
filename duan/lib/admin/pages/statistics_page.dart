import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StatisticsPage extends StatefulWidget {
  const StatisticsPage({super.key});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  int _rangeDays = 30;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xffF4F8FB),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [

          Row(
            children: [
              const Text(
                "Statistics",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              _rangeSelector(),
            ],
          ),

          const SizedBox(height: 20),

          _summaryCards(),

          const SizedBox(height: 24),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _userGrowthCard()),
              const SizedBox(width: 20),
              Expanded(child: _skillDistributionCard()),
            ],
          ),

          const SizedBox(height: 24),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: _topFlashcardsCard()),
              const SizedBox(width: 20),
              Expanded(child: _topCommunitySetsCard()),
            ],
          ),
        ],
      ),
    );
  }

  Widget _rangeSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        children: [
          _rangeBtn("7d", 7),
          _rangeBtn("30d", 30),
          _rangeBtn("90d", 90),
        ],
      ),
    );
  }

  Widget _rangeBtn(String label, int days) {
    final active = _rangeDays == days;
    return GestureDetector(
      onTap: () => setState(() => _rangeDays = days),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.all(4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: active
              ? const LinearGradient(
                  colors: [Color(0xFF4FC3F7), Color(0xFF7C4DFF)])
              : null,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: active ? Colors.white : Colors.grey.shade700,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY CARDS
  // ============================================================
  Widget _summaryCards() {
    return FutureBuilder<Map<String, int>>(
      future: _loadSummary(),
      builder: (context, snap) {
        final m = snap.data ?? {};
        return Row(
          children: [
            _statCard(
              "Users",
              "${m['users'] ?? 0}",
              const Color(0xFF4FC3F7),
              Icons.people_alt_rounded,
            ),
            _statCard(
              "Active Today",
              "${m['activeToday'] ?? 0}",
              const Color(0xFF81C784),
              Icons.bolt,
            ),
            _statCard(
              "Flashcards",
              "${m['flashcards'] ?? 0}",
              const Color(0xFFFFB74D),
              Icons.style_rounded,
            ),
            _statCard(
              "Tests",
              "${m['tests'] ?? 0}",
              const Color(0xFFBA68C8),
              Icons.quiz_rounded,
            ),
          ],
        );
      },
    );
  }

  Future<Map<String, int>> _loadSummary() async {
    final fs = FirebaseFirestore.instance;
    final today = DateTime.now();
    final dayStart =
        Timestamp.fromDate(DateTime(today.year, today.month, today.day));

    final users = await fs.collection("users").get();
    final flashcards = await fs.collection("flashcard_sets").get();
    final ls = await fs.collection("listening_tests").get();
    final rs = await fs.collection("reading_tests").get();
    final ws = await fs.collection("writing_tests").get();

    final activeL = await fs
        .collection("listening_results")
        .where("submittedAt", isGreaterThanOrEqualTo: dayStart)
        .get();
    final activeR = await fs
        .collection("reading_results")
        .where("submittedAt", isGreaterThanOrEqualTo: dayStart)
        .get();

    return {
      "users": users.docs.length,
      "flashcards": flashcards.docs.length,
      "tests": ls.docs.length + rs.docs.length + ws.docs.length,
      "activeToday": activeL.docs.length + activeR.docs.length,
    };
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 15),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withOpacity(0.75)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // USER GROWTH (line chart — cumulative users by day)
  // ============================================================
  Widget _userGrowthCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("users").snapshots(),
      builder: (context, snap) {
        final now = DateTime.now();
        final days = List.generate(_rangeDays, (i) {
          return DateTime(now.year, now.month, now.day - (_rangeDays - 1 - i));
        });
        final cum = List.filled(_rangeDays, 0);

        if (snap.hasData) {
          final sortedDocs = snap.data!.docs
              .map((d) {
                final data = d.data() as Map<String, dynamic>;
                final c = data["createdAt"];
                return c is Timestamp ? c.toDate() : null;
              })
              .where((d) => d != null)
              .cast<DateTime>()
              .toList()
            ..sort();

          // count of users created on or before each day
          for (int i = 0; i < days.length; i++) {
            final endOfDay = DateTime(
              days[i].year,
              days[i].month,
              days[i].day,
              23,
              59,
              59,
            );
            cum[i] = sortedDocs.where((d) => !d.isAfter(endOfDay)).length;
          }
        }

        final maxY = cum.isEmpty
            ? 10.0
            : (cum.reduce((a, b) => a > b ? a : b) + 5).toDouble();

        return _chartCard(
          title: "User Growth — last $_rangeDays days",
          height: 260,
          child: LineChart(
            LineChartData(
              minY: 0,
              maxY: maxY,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                horizontalInterval: (maxY / 5).ceilToDouble().clamp(1, 1e6),
              ),
              titlesData: FlTitlesData(
                rightTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                topTitles: const AxisTitles(
                    sideTitles: SideTitles(showTitles: false)),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 28,
                    interval: (days.length / 6).ceilToDouble(),
                    getTitlesWidget: (v, _) {
                      final i = v.toInt();
                      if (i < 0 || i >= days.length) return const SizedBox();
                      return Text(
                        "${days[i].day}/${days[i].month}",
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 32,
                    interval: (maxY / 5).ceilToDouble().clamp(1, 1e6),
                    getTitlesWidget: (v, _) => Text(
                      v.toInt().toString(),
                      style: const TextStyle(fontSize: 10),
                    ),
                  ),
                ),
              ),
              borderData: FlBorderData(show: false),
              lineBarsData: [
                LineChartBarData(
                  isCurved: true,
                  curveSmoothness: 0.3,
                  color: const Color(0xFF4FC3F7),
                  barWidth: 3,
                  dotData: const FlDotData(show: false),
                  belowBarData: BarAreaData(
                    show: true,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF4FC3F7).withOpacity(0.25),
                        const Color(0xFF4FC3F7).withOpacity(0.02),
                      ],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                  spots: List.generate(
                    cum.length,
                    (i) => FlSpot(i.toDouble(), cum[i].toDouble()),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // SKILL DISTRIBUTION (pie — from actual test results)
  // ============================================================
  Widget _skillDistributionCard() {
    return FutureBuilder<Map<String, int>>(
      future: _loadSkillDist(),
      builder: (context, snap) {
        final m = snap.data ?? {};
        final total = m.values.fold<int>(0, (s, v) => s + v);

        final entries = [
          _SkillSlice("Listening", m["listening"] ?? 0,
              const Color(0xFF4FC3F7), Icons.headphones),
          _SkillSlice("Reading", m["reading"] ?? 0,
              const Color(0xFFFFB74D), Icons.menu_book),
        ];

        return _chartCard(
          title: "Test Attempts by Skill",
          height: 260,
          child: total == 0
              ? const Center(
                  child: Text("No data", style: TextStyle(color: Colors.grey)),
                )
              : Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: PieChart(
                        PieChartData(
                          sectionsSpace: 2,
                          centerSpaceRadius: 45,
                          sections: entries.map((e) {
                            final v = e.count.toDouble();
                            if (v == 0) {
                              return PieChartSectionData(
                                value: 0,
                                color: e.color,
                                radius: 0,
                              );
                            }
                            return PieChartSectionData(
                              value: v,
                              color: e.color,
                              title:
                                  "${(v / total * 100).toStringAsFixed(0)}%",
                              titleStyle: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                              radius: 62,
                            );
                          }).toList(),
                        ),
                      ),
                    ),
                    Expanded(
                      flex: 2,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: entries.map((e) {
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 5),
                            child: Row(
                              children: [
                                Container(
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: e.color,
                                    borderRadius: BorderRadius.circular(2),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    e.label,
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ),
                                Text(
                                  "${e.count}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ),
        );
      },
    );
  }

  Future<Map<String, int>> _loadSkillDist() async {
    final fs = FirebaseFirestore.instance;
    final l = await fs.collection("listening_results").get();
    final r = await fs.collection("reading_results").get();
    return {
      "listening": l.docs.length,
      "reading": r.docs.length,
    };
  }

  // ============================================================
  // TOP FLASHCARDS (community sets — by vocab count)
  // ============================================================
  Widget _topFlashcardsCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("flashcard_sets")
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        final items = docs.map((d) {
          final data = d.data() as Map<String, dynamic>;
          final vocab = (data["vocabList"] as List?)?.length ?? 0;
          return _SetStat(
            title: data["title"] ?? "(no title)",
            vocab: vocab,
          );
        }).toList()
          ..sort((a, b) => b.vocab.compareTo(a.vocab));
        final top = items.take(5).toList();

        return _chartCard(
          title: "Top Community Sets by Size",
          height: null,
          child: top.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text("No data",
                        style: TextStyle(color: Colors.grey)),
                  ),
                )
              : Column(
                  children: List.generate(top.length, (i) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: const Color(0xFFFFB74D).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Center(
                              child: Text(
                                "#${i + 1}",
                                style: const TextStyle(
                                  color: Color(0xFFE65100),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              top[i].title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Text(
                            "${top[i].vocab} words",
                            style: const TextStyle(
                              color: Colors.grey,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
        );
      },
    );
  }

  // ============================================================
  // TOP COMMUNITY AUTHORS
  // ============================================================
  Widget _topCommunitySetsCard() {
    return FutureBuilder<List<_TestPopularity>>(
      future: _loadTopTests(),
      builder: (context, snap) {
        final top = snap.data ?? [];
        return _chartCard(
          title: "Most Attempted Tests",
          height: null,
          child: top.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text("No data",
                        style: TextStyle(color: Colors.grey)),
                  ),
                )
              : Column(
                  children: List.generate(top.length, (i) {
                    final color = top[i].skill == "Listening"
                        ? const Color(0xFF4FC3F7)
                        : const Color(0xFFFFB74D);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        children: [
                          Container(
                            width: 30,
                            height: 30,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              top[i].skill == "Listening"
                                  ? Icons.headphones
                                  : Icons.menu_book,
                              size: 14,
                              color: color,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  top[i].testId,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  top[i].skill,
                                  style: TextStyle(
                                    color: color,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "${top[i].attempts}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
        );
      },
    );
  }

  Future<List<_TestPopularity>> _loadTopTests() async {
    final fs = FirebaseFirestore.instance;
    final l = await fs.collection("listening_results").get();
    final r = await fs.collection("reading_results").get();

    final counts = <String, _TestPopularity>{};
    for (final d in l.docs) {
      final data = d.data();
      final id = (data["testId"] ?? "-").toString();
      final key = "Listening|$id";
      counts.update(
        key,
        (e) {
          e.attempts++;
          return e;
        },
        ifAbsent: () => _TestPopularity("Listening", id, 1),
      );
    }
    for (final d in r.docs) {
      final data = d.data();
      final id = (data["testId"] ?? "-").toString();
      final key = "Reading|$id";
      counts.update(
        key,
        (e) {
          e.attempts++;
          return e;
        },
        ifAbsent: () => _TestPopularity("Reading", id, 1),
      );
    }
    final list = counts.values.toList()
      ..sort((a, b) => b.attempts.compareTo(a.attempts));
    return list.take(5).toList();
  }

  Widget _chartCard({
    required String title,
    required double? height,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 15,
            ),
          ),
          const SizedBox(height: 16),
          if (height != null)
            SizedBox(height: height, child: child)
          else
            child,
        ],
      ),
    );
  }
}

class _SkillSlice {
  final String label;
  final int count;
  final Color color;
  final IconData icon;
  _SkillSlice(this.label, this.count, this.color, this.icon);
}

class _SetStat {
  final String title;
  final int vocab;
  _SetStat({required this.title, required this.vocab});
}

class _TestPopularity {
  final String skill;
  final String testId;
  int attempts;
  _TestPopularity(this.skill, this.testId, this.attempts);
}
