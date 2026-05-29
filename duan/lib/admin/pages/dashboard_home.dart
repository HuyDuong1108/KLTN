import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xffF4F8FB),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [

          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Dashboard",
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "Welcome back — here's what's happening today.",
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                _todayLabel(),
                style: TextStyle(
                  color: Colors.grey.shade600,
                  fontSize: 13,
                ),
              ),
            ],
          ),

          const SizedBox(height: 28),

          /// STAT CARDS
          const _StatCardsRow(),

          const SizedBox(height: 24),

          /// MAIN ROW
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Column(
                  children: const [
                    _NewUsersChart(),
                    SizedBox(height: 20),
                    _RecentActivities(),
                  ],
                ),
              ),
              const SizedBox(width: 20),
              Expanded(
                flex: 2,
                child: Column(
                  children: const [
                    _SkillBreakdown(),
                    SizedBox(height: 20),
                    _QuickActions(),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _todayLabel() {
    final d = DateTime.now();
    const months = [
      "", "January", "February", "March", "April", "May", "June",
      "July", "August", "September", "October", "November", "December",
    ];
    return "${months[d.month]} ${d.day}, ${d.year}";
  }
}

// ============================================================
// STAT CARDS
// ============================================================
class _StatCardsRow extends StatelessWidget {
  const _StatCardsRow();

  @override
  Widget build(BuildContext context) {
    final fs = FirebaseFirestore.instance;

    return Row(
      children: [
        _liveStat(
          label: "Total Users",
          color: const Color(0xFF4FC3F7),
          icon: Icons.people_alt_rounded,
          stream: fs.collection("users").snapshots(),
        ),
        _liveStat(
          label: "Flashcard Sets",
          color: const Color(0xFF81C784),
          icon: Icons.style_rounded,
          stream: fs.collection("flashcard_sets").snapshots(),
        ),
        _liveTestCount(),
        _activeTodayCard(),
      ],
    );
  }

  Widget _liveStat({
    required String label,
    required Color color,
    required IconData icon,
    required Stream<QuerySnapshot> stream,
  }) {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: stream,
        builder: (context, snap) {
          final count = snap.data?.docs.length ?? 0;
          return _statCard(label, "$count", color, icon);
        },
      ),
    );
  }

  Widget _liveTestCount() {
    final fs = FirebaseFirestore.instance;
    return Expanded(
      child: FutureBuilder<List<QuerySnapshot>>(
        future: Future.wait([
          fs.collection("listening_tests").get(),
          fs.collection("reading_tests").get(),
          fs.collection("writing_tests").get(),
        ]),
        builder: (context, snap) {
          int total = 0;
          if (snap.hasData) {
            for (final s in snap.data!) {
              total += s.docs.length;
            }
          }
          return _statCard(
            "Tests",
            "$total",
            const Color(0xFFFFB74D),
            Icons.quiz_rounded,
          );
        },
      ),
    );
  }

  Widget _activeTodayCard() {
    final fs = FirebaseFirestore.instance;
    final today = DateTime.now();
    final start =
        Timestamp.fromDate(DateTime(today.year, today.month, today.day));

    return Expanded(
      child: FutureBuilder<List<QuerySnapshot>>(
        future: Future.wait([
          fs
              .collection("listening_results")
              .where("submittedAt", isGreaterThanOrEqualTo: start)
              .get(),
          fs
              .collection("reading_results")
              .where("submittedAt", isGreaterThanOrEqualTo: start)
              .get(),
        ]),
        builder: (context, snap) {
          int total = 0;
          if (snap.hasData) {
            for (final s in snap.data!) {
              total += s.docs.length;
            }
          }
          return _statCard(
            "Active Today",
            "$total",
            const Color(0xFFBA68C8),
            Icons.bolt_rounded,
          );
        },
      ),
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Container(
      margin: const EdgeInsets.only(right: 15),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.75)]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.25),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: Colors.white),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// NEW USERS CHART (last 7 days)
// ============================================================
class _NewUsersChart extends StatelessWidget {
  const _NewUsersChart();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection("users").snapshots(),
      builder: (context, snap) {
        final now = DateTime.now();
        final days = List.generate(7, (i) {
          return DateTime(now.year, now.month, now.day - (6 - i));
        });
        final counts = List.filled(7, 0);

        if (snap.hasData) {
          for (final doc in snap.data!.docs) {
            final d = doc.data() as Map<String, dynamic>;
            final c = d["createdAt"];
            if (c is Timestamp) {
              final dt = c.toDate();
              for (int i = 0; i < days.length; i++) {
                if (dt.year == days[i].year &&
                    dt.month == days[i].month &&
                    dt.day == days[i].day) {
                  counts[i]++;
                  break;
                }
              }
            }
          }
        }

        final maxCount = counts.fold<int>(0, (p, c) => c > p ? c : p);

        return _card(
          title: "New Users — Last 7 days",
          child: SizedBox(
            height: 200,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(days.length, (i) {
                final v = counts[i];
                final factor = maxCount == 0
                    ? 0.02
                    : ((v / maxCount).clamp(0.02, 1.0)).toDouble();
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Text(
                          "$v",
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Expanded(
                          child: FractionallySizedBox(
                            alignment: Alignment.bottomCenter,
                            heightFactor: factor,
                            child: Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Color(0xFF4FC3F7),
                                    Color(0xFF7C4DFF),
                                  ],
                                ),
                                borderRadius: BorderRadius.circular(6),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          "${days[i].day}/${days[i].month}",
                          style: const TextStyle(
                            fontSize: 10,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }
}

// ============================================================
// RECENT ACTIVITIES
// ============================================================
class _RecentActivities extends StatelessWidget {
  const _RecentActivities();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<QuerySnapshot>>(
      future: Future.wait([
        FirebaseFirestore.instance
            .collection("listening_results")
            .orderBy("submittedAt", descending: true)
            .limit(5)
            .get(),
        FirebaseFirestore.instance
            .collection("reading_results")
            .orderBy("submittedAt", descending: true)
            .limit(5)
            .get(),
      ]),
      builder: (context, snap) {
        final items = <_ActivityItem>[];
        if (snap.hasData) {
          for (final doc in snap.data![0].docs) {
            final d = doc.data() as Map<String, dynamic>;
            final sa = d["submittedAt"];
            items.add(_ActivityItem(
              skill: "Listening",
              testId: (d["testId"] ?? "-").toString(),
              band: (d["band"] is num) ? (d["band"] as num).toDouble() : 0,
              at: sa is Timestamp ? sa.toDate() : DateTime.now(),
            ));
          }
          for (final doc in snap.data![1].docs) {
            final d = doc.data() as Map<String, dynamic>;
            final sa = d["submittedAt"];
            items.add(_ActivityItem(
              skill: "Reading",
              testId: (d["testId"] ?? "-").toString(),
              band: (d["band"] is num) ? (d["band"] as num).toDouble() : 0,
              at: sa is Timestamp ? sa.toDate() : DateTime.now(),
            ));
          }
          items.sort((a, b) => b.at.compareTo(a.at));
        }
        final showing = items.take(8).toList();

        return _card(
          title: "Recent Activities",
          child: showing.isEmpty
              ? const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      "No recent activity",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              : Column(
                  children: showing.map((it) {
                    final color = it.skill == "Listening"
                        ? const Color(0xFF4FC3F7)
                        : const Color(0xFFFFB74D);
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 7),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Icon(
                              it.skill == "Listening"
                                  ? Icons.headphones
                                  : Icons.menu_book,
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
                                  "${it.skill} test submitted",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  "${it.testId} • Band ${it.band.toStringAsFixed(1)}",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            _ago(it.at),
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        );
      },
    );
  }

  String _ago(DateTime t) {
    final diff = DateTime.now().difference(t);
    if (diff.inMinutes < 1) return "just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    return "${diff.inDays}d ago";
  }
}

class _ActivityItem {
  final String skill;
  final String testId;
  final double band;
  final DateTime at;
  _ActivityItem({
    required this.skill,
    required this.testId,
    required this.band,
    required this.at,
  });
}

// ============================================================
// SKILL BREAKDOWN (counts per collection)
// ============================================================
class _SkillBreakdown extends StatelessWidget {
  const _SkillBreakdown();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<QuerySnapshot>>(
      future: Future.wait([
        FirebaseFirestore.instance.collection("listening_tests").get(),
        FirebaseFirestore.instance.collection("reading_tests").get(),
        FirebaseFirestore.instance.collection("writing_tests").get(),
      ]),
      builder: (context, snap) {
        int lt = 0, rt = 0, wt = 0;
        if (snap.hasData) {
          lt = snap.data![0].docs.length;
          rt = snap.data![1].docs.length;
          wt = snap.data![2].docs.length;
        }
        final total = (lt + rt + wt).clamp(1, 9999);

        return _card(
          title: "Tests by Skill",
          child: Column(
            children: [
              _Bar("Listening", lt, total, const Color(0xFF4FC3F7)),
              _Bar("Reading", rt, total, const Color(0xFFFFB74D)),
              _Bar("Writing", wt, total, const Color(0xFFBA68C8)),
              const _Bar("Speaking", 0, 1, Color(0xFF81C784)),
            ],
          ),
        );
      },
    );
  }
}

class _Bar extends StatelessWidget {
  final String label;
  final int value;
  final int total;
  final Color color;
  const _Bar(this.label, this.value, this.total, this.color);

  @override
  Widget build(BuildContext context) {
    final pct = total == 0 ? 0.0 : value / total;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
              Text(
                "$value",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: LinearProgressIndicator(
              minHeight: 7,
              value: pct,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// QUICK ACTIONS
// ============================================================
class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    return _card(
      title: "Quick Links",
      child: Column(
        children: [
          _linkTile(Icons.people_alt_rounded, "Manage Users", Colors.blue),
          _linkTile(Icons.style_rounded, "Flashcard Sets", Colors.green),
          _linkTile(Icons.quiz_rounded, "Test Library", Colors.orange),
          _linkTile(Icons.bar_chart_rounded, "Statistics", Colors.purple),
        ],
      ),
    );
  }

  Widget _linkTile(IconData icon, String label, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: color.withOpacity(0.07),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            Icon(
              Icons.chevron_right,
              color: color.withOpacity(0.6),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

Widget _card({required String title, required Widget child}) {
  return Container(
    padding: const EdgeInsets.all(20),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 8,
          offset: const Offset(0, 2),
        ),
      ],
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
