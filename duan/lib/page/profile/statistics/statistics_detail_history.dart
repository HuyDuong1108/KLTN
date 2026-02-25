part of 'statistics_detail_page.dart';

extension _StatisticsDetailHistory on _StatisticsDetailPageState {
  List<_ReviewSession> _buildSessions(List<ReviewEvent> recent) {
    final events = recent
        .where((e) => e.ts.isNotEmpty)
        .map((e) {
          DateTime dt;
          try {
            dt = DateTime.parse(e.ts).toLocal();
          } catch (_) {
            dt = DateTime.now();
          }
          return (dt: dt, rating: e.rating, match: e.match);
        })
        .toList()
      ..sort((a, b) => b.dt.compareTo(a.dt));

    const gap = Duration(minutes: 25);
    final List<_ReviewSession> sessions = [];

    _ReviewSession? cur;

    for (final ev in events) {
      if (cur == null) {
        cur = _ReviewSession(start: ev.dt, end: ev.dt);
        cur.add(ev.rating, match: ev.match);
        sessions.add(cur);
        continue;
      }
      final diff = cur.start.difference(ev.dt);
      if (diff <= gap) {
        cur.end = ev.dt;
        cur.add(ev.rating, match: ev.match);
      } else {
        cur = _ReviewSession(start: ev.dt, end: ev.dt);
        cur.add(ev.rating, match: ev.match);
        sessions.add(cur);
      }
    }

    return sessions;
  }

  String _sessionTitle(DateTime start) {
    final now = DateTime.now();
    final d0 = DateTime(now.year, now.month, now.day);
    final d1 = DateTime(start.year, start.month, start.day);
    final diffDays = d0.difference(d1).inDays;

    String two(int v) => v.toString().padLeft(2, '0');
    final time = '${two(start.hour)}:${two(start.minute)}';

    if (diffDays == 0) return 'Hôm nay, $time';
    if (diffDays == 1) return 'Hôm qua, $time';
    return '${two(start.day)}/${two(start.month)}, $time';
  }

  String _sessionBreakdownFull(_ReviewSession s) {
    int c(int r) => s.counts[r] ?? 0;
    return 'Again ${c(1)} • Hard ${c(2)} • Good ${c(3)} • Easy ${c(4)}';
  }
  String _sessionBreakdownCompact(_ReviewSession s) {
    int c(int r) => s.counts[r] ?? 0;
    final parts = <String>[];
    final a = c(1); if (a > 0) parts.add('Again $a');
    final h = c(2); if (h > 0) parts.add('Hard $h');
    final g = c(3); if (g > 0) parts.add('Good $g');
    final e = c(4); if (e > 0) parts.add('Easy $e');
    if (parts.isEmpty) return _sessionBreakdownFull(s);
    return parts.join(' • ');
  }
  String? _sessionContextLine(_ReviewSession s) {
    if (s.setCounts.isEmpty) return null;

    final entries = s.setCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final titles = entries.take(2).map((e) => e.key).toList();
    if (titles.isEmpty) return null;

    if (titles.length == 1) return 'Bộ: ${titles[0]}';
    return 'Bộ: ${titles[0]} • ${titles[1]}';
  }



  String _sessionMood(_ReviewSession s) {
    final good = (s.counts[3] ?? 0) + (s.counts[4] ?? 0);
    final bad = (s.counts[1] ?? 0) + (s.counts[2] ?? 0);
    if (bad > good) return 'Còn nợ 😵';
    if (good >= bad && good > 0) return 'Ngon rồi 😎';
    return 'Ổn áp 🙂';
  }

  ({Color bg, Color border, Color fg}) _moodStyle(String mood) {
    final m = mood.toLowerCase();

    if (m.contains('còn nợ')) {
      return (
        bg: Colors.redAccent.withOpacity(0.12),
        border: Colors.redAccent.withOpacity(0.45),
        fg: Colors.redAccent
      );
    }

    if (m.contains('ngon rồi')) {
      return (
        bg: Colors.green.withOpacity(0.14),
        border: Colors.green.withOpacity(0.45),
        fg: Colors.green.shade700
      );
    }

    return (
      bg: Colors.amber.withOpacity(0.18),
      border: Colors.amber.withOpacity(0.55),
      fg: Colors.brown.shade700
    );
  }

  Widget _historyTimelineCard(StatsProgress p) {
    final sessions = _buildSessions(p.recent);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Lịch sử ôn tập Flashcard',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              TextButton(
                onPressed: sessions.isEmpty ? null : () => _openAllSessionsSheet(sessions),
                child: const Text('Xem tất cả'),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (sessions.isEmpty)
            Text('Chưa có lượt ôn nào gần đây.', style: TextStyle(color: Colors.grey.shade700))
          else
            ...sessions.take(3).toList().asMap().entries.map((entry) {
              final i = entry.key;
              final s = entry.value;
              final isLast = i == (sessions.take(3).length - 1);
              final mood = _sessionMood(s);
              final ms = _moodStyle(mood);
              final ctx = _sessionContextLine(s);

              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Column(
                      children: [
                        Container(
                          width: 10,
                          height: 10,
                          decoration: const BoxDecoration(
                            color: Colors.blue,
                            shape: BoxShape.circle,
                          ),
                        ),
                        if (!isLast)
                          Container(
                            width: 2,
                            height: 54,
                            color: Colors.grey.withOpacity(0.25),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.05),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.blue.withOpacity(0.18)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    _sessionTitle(s.start),
                                    style: const TextStyle(fontWeight: FontWeight.w800),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: ms.bg,
                                    borderRadius: BorderRadius.circular(999),
                                    border: Border.all(color: ms.border),
                                  ),
                                  child: Text(
                                    mood,
                                    style: TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontSize: 12,
                                      color: ms.fg,
                                  ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            if (ctx != null) ...[
                              Text(ctx, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
                              const SizedBox(height: 6),
                            ],
                            Tooltip(
                              message: _sessionBreakdownFull(s),
                              child: Text(
                                _sessionBreakdownCompact(s),
                                style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                              ),
                            ),
                          ],
                        ),
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
  String _dayHeader(DateTime day) {
    final now = DateTime.now();
    final d0 = DateTime(now.year, now.month, now.day);
    final d1 = DateTime(day.year, day.month, day.day);
    final diffDays = d0.difference(d1).inDays;

    String two(int v) => v.toString().padLeft(2, '0');

    if (diffDays == 0) return 'Hôm nay';
    if (diffDays == 1) return 'Hôm qua';
    return '${two(day.day)}/${two(day.month)}';
  }

  Map<DateTime, List<_ReviewSession>> _groupSessionsByDay(List<_ReviewSession> sessions) {
    final map = <DateTime, List<_ReviewSession>>{};
    for (final s in sessions) {
      final key = DateTime(s.start.year, s.start.month, s.start.day);
      map.putIfAbsent(key, () => []).add(s);
    }

    // Sort trong từng ngày: mới -> cũ
    for (final list in map.values) {
      list.sort((a, b) => b.start.compareTo(a.start));
    }
    return map;
  }
  Widget _sessionTile(_ReviewSession s) {
    final ctx = _sessionContextLine(s);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.blue.withOpacity(0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _sessionTimeOnly(s.start),
            style: const TextStyle(fontWeight: FontWeight.w800),
          ),
          if (ctx != null) ...[
            const SizedBox(height: 6),
            Text(ctx, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
          ],
          const SizedBox(height: 6),
          Tooltip(
            message: _sessionBreakdownFull(s),
            child: Text(
              _sessionBreakdownCompact(s),
              style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
  String _sessionTimeOnly(DateTime start) {
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(start.hour)}:${two(start.minute)}';
  }


  void _openAllSessionsSheet(List<_ReviewSession> sessions) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Color(0xFFF3F9FF),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) {
        return SafeArea(
          child: Container(
            padding: const EdgeInsets.all(16),
            height: MediaQuery.of(context).size.height * 0.75,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Tất cả lượt ôn',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                Expanded(
                  child: Builder(
                    builder: (_) {
                      final groups = _groupSessionsByDay(sessions);
                      final days = groups.keys.toList()
                        ..sort((a, b) => b.compareTo(a)); // ngày mới -> cũ

                      final children = <Widget>[];
                      for (final day in days) {
                        children.add(
                          Padding(
                            padding: const EdgeInsets.only(top: 6, bottom: 10),
                            child: Text(
                              _dayHeader(day),
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
                            ),
                          ),
                        );

                        final list = groups[day] ?? const <_ReviewSession>[];
                        for (final s in list) {
                          children.add(_sessionTile(s));
                          children.add(const SizedBox(height: 10));
                        }
                      }

                      return ListView(
                        children: children,
                      );
                    },
                  ),
                ),

              ],
            ),
          ),
        );
      },
    );
  }
}

class _ReviewSession {
  DateTime start;
  DateTime end;
  final Map<int, int> counts = {1: 0, 2: 0, 3: 0, 4: 0};
  final Map<String, int> setCounts = {};
  final List<String> sampleWords = [];

  _ReviewSession({required this.start, required this.end});

  void add(int rating, {dynamic match}) {
    if (counts.containsKey(rating)) {
      counts[rating] = (counts[rating] ?? 0) + 1;
    }

    final setTitle = match?.setTitle;
    if (setTitle is String && setTitle.trim().isNotEmpty) {
      setCounts[setTitle] = (setCounts[setTitle] ?? 0) + 1;
    }

    final w = match?.word;
    if (w is String && w.trim().isNotEmpty) {
      if (!sampleWords.contains(w) && sampleWords.length < 2) {
        sampleWords.add(w);
      }
    }
  }
}
