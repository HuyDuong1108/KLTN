import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';

class TestResultsPage extends StatefulWidget {
  const TestResultsPage({super.key});

  @override
  State<TestResultsPage> createState() => _TestResultsPageState();
}

class _TestResultsPageState extends State<TestResultsPage> {
  String filterSkill = "All";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text(
          "Test Results Analytics",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: FutureBuilder<_CombinedResults>(
        future: _loadResults(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final r = snap.data!;
          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _buildStatCards(r),
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _attemptsChart(r)),
                  const SizedBox(width: 20),
                  Expanded(child: _bandDistribution(r)),
                ],
              ),
              const SizedBox(height: 24),
              _topTests(r),
              const SizedBox(height: 24),
              _recentResults(r),
            ],
          );
        },
      ),
    );
  }

  Future<_CombinedResults> _loadResults() async {
    final fs = FirebaseFirestore.instance;
    final l = await fs
        .collection("listening_results")
        .orderBy("submittedAt", descending: true)
        .limit(500)
        .get();
    final r = await fs
        .collection("reading_results")
        .orderBy("submittedAt", descending: true)
        .limit(500)
        .get();

    final all = <_ResultRow>[];
    for (final d in l.docs) {
      all.add(_ResultRow.fromDoc("Listening", d));
    }
    for (final d in r.docs) {
      all.add(_ResultRow.fromDoc("Reading", d));
    }
    all.sort((a, b) => b.submittedAt.compareTo(a.submittedAt));

    return _CombinedResults(all);
  }

  Widget _buildStatCards(_CombinedResults r) {
    final total = r.rows.length;
    final avgBand = r.rows.isEmpty
        ? 0.0
        : r.rows.map((e) => e.band).reduce((a, b) => a + b) / r.rows.length;
    final totalCorrect =
        r.rows.fold<int>(0, (sum, row) => sum + row.correct);
    final totalAttempted = r.rows.fold<int>(
      0,
      (sum, row) => sum + row.correct + row.incorrect,
    );
    final accuracy =
        totalAttempted == 0 ? 0.0 : (totalCorrect / totalAttempted) * 100;

    final today = DateTime.now();
    final todayCount = r.rows
        .where((row) =>
            row.submittedAt.year == today.year &&
            row.submittedAt.month == today.month &&
            row.submittedAt.day == today.day)
        .length;

    return Row(
      children: [
        _statCard("Total Attempts", "$total", const Color(0xFF4FC3F7),
            Icons.assignment_turned_in),
        _statCard("Avg Band", avgBand.toStringAsFixed(1),
            const Color(0xFF81C784), Icons.star),
        _statCard("Accuracy", "${accuracy.toStringAsFixed(1)}%",
            const Color(0xFFFFB74D), Icons.track_changes),
        _statCard("Today", "$todayCount", const Color(0xFFBA68C8),
            Icons.today),
      ],
    );
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

  Widget _attemptsChart(_CombinedResults r) {
    final now = DateTime.now();
    final days = List.generate(7, (i) {
      return DateTime(now.year, now.month, now.day - (6 - i));
    });

    final counts = days.map((day) {
      return r.rows
          .where((row) =>
              row.submittedAt.year == day.year &&
              row.submittedAt.month == day.month &&
              row.submittedAt.day == day.day)
          .length
          .toDouble();
    }).toList();

    final maxY =
        counts.isEmpty ? 10.0 : (counts.reduce((a, b) => a > b ? a : b) + 2);

    return _card(
      title: "Attempts — Last 7 days",
      child: SizedBox(
        height: 220,
        child: LineChart(
          LineChartData(
            minY: 0,
            maxY: maxY,
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: (maxY / 4).ceilToDouble().clamp(1, 100),
            ),
            titlesData: FlTitlesData(
              rightTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              topTitles:
                  const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 28,
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
                  reservedSize: 28,
                  interval: (maxY / 4).ceilToDouble().clamp(1, 100),
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
                dotData: const FlDotData(show: true),
                belowBarData: BarAreaData(
                  show: true,
                  color: const Color(0xFF4FC3F7).withOpacity(0.15),
                ),
                spots: List.generate(
                  counts.length,
                  (i) => FlSpot(i.toDouble(), counts[i]),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bandDistribution(_CombinedResults r) {
    final buckets = <String, int>{
      "0-4": 0,
      "4-5": 0,
      "5-6": 0,
      "6-7": 0,
      "7-8": 0,
      "8-9": 0,
    };

    for (final row in r.rows) {
      final b = row.band;
      if (b < 4) buckets["0-4"] = buckets["0-4"]! + 1;
      else if (b < 5) buckets["4-5"] = buckets["4-5"]! + 1;
      else if (b < 6) buckets["5-6"] = buckets["5-6"]! + 1;
      else if (b < 7) buckets["6-7"] = buckets["6-7"]! + 1;
      else if (b < 8) buckets["7-8"] = buckets["7-8"]! + 1;
      else buckets["8-9"] = buckets["8-9"]! + 1;
    }

    final colors = [
      const Color(0xFFEF5350),
      const Color(0xFFFF9800),
      const Color(0xFFFFB74D),
      const Color(0xFF4FC3F7),
      const Color(0xFF81C784),
      const Color(0xFF66BB6A),
    ];

    final entries = buckets.entries.toList();
    final total = r.rows.length;

    return _card(
      title: "Band Distribution",
      child: SizedBox(
        height: 220,
        child: total == 0
            ? const Center(
                child: Text("No data", style: TextStyle(color: Colors.grey)))
            : Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: PieChart(
                      PieChartData(
                        sectionsSpace: 2,
                        centerSpaceRadius: 40,
                        sections: List.generate(entries.length, (i) {
                          final v = entries[i].value.toDouble();
                          if (v == 0) {
                            return PieChartSectionData(
                                value: 0, color: colors[i], radius: 0);
                          }
                          return PieChartSectionData(
                            value: v,
                            color: colors[i],
                            title: "${(v / total * 100).toStringAsFixed(0)}%",
                            titleStyle: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            radius: 58,
                          );
                        }),
                      ),
                    ),
                  ),
                  Expanded(
                    flex: 2,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: List.generate(entries.length, (i) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(
                            children: [
                              Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                  color: colors[i],
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                "${entries[i].key}",
                                style: const TextStyle(fontSize: 11),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                "(${entries[i].value})",
                                style: const TextStyle(
                                  fontSize: 11,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _topTests(_CombinedResults r) {
    final groups = <String, _TestStat>{};
    for (final row in r.rows) {
      final key = "${row.skill}|${row.testId}";
      final ex = groups[key];
      if (ex == null) {
        groups[key] = _TestStat(row.skill, row.testId, 1, row.band);
      } else {
        ex.attempts++;
        ex.totalBand += row.band;
      }
    }
    final top = groups.values.toList()
      ..sort((a, b) => b.attempts.compareTo(a.attempts));
    final showing = top.take(5).toList();

    return _card(
      title: "Top Tests by Attempts",
      child: showing.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text("No data", style: TextStyle(color: Colors.grey)),
              ),
            )
          : Column(
              children: List.generate(showing.length, (i) {
                final t = showing[i];
                final avg = (t.totalBand / t.attempts).toStringAsFixed(1);
                final skillColor = t.skill == "Listening"
                    ? const Color(0xFF4FC3F7)
                    : const Color(0xFFFFB74D);
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    children: [
                      Container(
                        width: 32,
                        height: 32,
                        decoration: BoxDecoration(
                          color: skillColor.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Center(
                          child: Text(
                            "#${i + 1}",
                            style: TextStyle(
                              color: skillColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(t.testId,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w500)),
                            Text(
                              "${t.skill} • Avg band $avg",
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 5,
                        ),
                        decoration: BoxDecoration(
                          color: skillColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          "${t.attempts} attempts",
                          style: TextStyle(
                            color: skillColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
    );
  }

  Widget _recentResults(_CombinedResults r) {
    final showing = r.rows.take(10).toList();
    return _card(
      title: "Recent Results",
      child: showing.isEmpty
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 18),
              child: Center(
                child: Text("No data", style: TextStyle(color: Colors.grey)),
              ),
            )
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    children: const [
                      Expanded(
                          flex: 2,
                          child: Text("Test ID",
                              style:
                                  TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(
                          child: Text("Skill",
                              style:
                                  TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(
                          child: Text("Band",
                              style:
                                  TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(
                          child: Text("Score",
                              style:
                                  TextStyle(fontWeight: FontWeight.bold))),
                      Expanded(
                          flex: 2,
                          child: Text("Submitted",
                              style:
                                  TextStyle(fontWeight: FontWeight.bold))),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ...showing.map((row) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Row(
                      children: [
                        Expanded(flex: 2, child: Text(row.testId)),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            margin: const EdgeInsets.only(right: 4),
                            decoration: BoxDecoration(
                              color: (row.skill == "Listening"
                                      ? const Color(0xFF4FC3F7)
                                      : const Color(0xFFFFB74D))
                                  .withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              row.skill,
                              style: TextStyle(
                                fontSize: 11,
                                color: row.skill == "Listening"
                                    ? const Color(0xFF0288D1)
                                    : const Color(0xFFE65100),
                                fontWeight: FontWeight.w600,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ),
                        Expanded(
                            child: Text(row.band.toStringAsFixed(1),
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600))),
                        Expanded(
                            child: Text("${row.correct}/${row.correct + row.incorrect}")),
                        Expanded(
                          flex: 2,
                          child: Text(
                            _fmt(row.submittedAt),
                            style:
                                const TextStyle(fontSize: 12, color: Colors.grey),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
    );
  }

  String _fmt(DateTime d) {
    return "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year} "
        "${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}";
  }

  Widget _card({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(18),
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
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _ResultRow {
  final String skill;
  final String testId;
  final double band;
  final int correct;
  final int incorrect;
  final DateTime submittedAt;

  _ResultRow({
    required this.skill,
    required this.testId,
    required this.band,
    required this.correct,
    required this.incorrect,
    required this.submittedAt,
  });

  factory _ResultRow.fromDoc(String skill, QueryDocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    double band = 0;
    final b = d["band"];
    if (b is num) band = b.toDouble();

    DateTime ts = DateTime.now();
    final sa = d["submittedAt"];
    if (sa is Timestamp) ts = sa.toDate();

    return _ResultRow(
      skill: skill,
      testId: (d["testId"] ?? "-").toString(),
      band: band,
      correct: (d["correct"] ?? 0) is num ? (d["correct"] as num).toInt() : 0,
      incorrect:
          (d["incorrect"] ?? 0) is num ? (d["incorrect"] as num).toInt() : 0,
      submittedAt: ts,
    );
  }
}

class _CombinedResults {
  final List<_ResultRow> rows;
  _CombinedResults(this.rows);
}

class _TestStat {
  final String skill;
  final String testId;
  int attempts;
  double totalBand;
  _TestStat(this.skill, this.testId, this.attempts, this.totalBand);
}
