part of 'statistics_detail_page.dart';

extension _StatisticsDetailStudyPlan on _StatisticsDetailPageState {
  Widget _miniMetric(String title, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _horizonPill(String text, bool active, VoidCallback onTap) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? Colors.orange : Colors.grey.withOpacity(0.12),
          borderRadius: BorderRadius.circular(999),
        ),
        child: Text(
          text,
          style: TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 12,
            color: active ? Colors.white : Colors.grey.shade800,
          ),
        ),
      ),
    );
  }

  Widget _studyPlanCard(StatsSummary? stats) {
    final dueNow = stats?.dueNow;
    final dueToday = stats?.dueToday;
    final List<DueBucket> buckets = stats?.dueNext7d ?? const <DueBucket>[];

    String horizonLabel() {
      if (_horizonDays == 1) return '1 ngày';
      if (_horizonDays == 7) return '1 tuần';
      return '4 tuần';
    }

    return Container(
      key: _studyPlanKey,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Kế hoạch ôn tập',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              _horizonPill('1 ngày', _horizonDays == 1, () => _setHorizon(1)),
              const SizedBox(width: 8),
              _horizonPill('1 tuần', _horizonDays == 7, () => _setHorizon(7)),
              const SizedBox(width: 8),
              _horizonPill('4 tuần', _horizonDays == 28, () => _setHorizon(28)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _openDueCardsSheet(scope: 'now', title: 'Cần ôn ngay', includeCommunity: true),
                  child: _miniMetric('Cần ôn ngay', dueNow == null ? '—' : '$dueNow'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: InkWell(
                  borderRadius: BorderRadius.circular(14),
                  onTap: () => _openDueCardsSheet(scope: 'today', title: 'Trong hôm nay', includeCommunity: true),
                  child: _miniMetric('Trong hôm nay', dueToday == null ? '—' : '$dueToday'),
                ),
              ),
            ],
          ),

          const SizedBox(height: 14),

          // ✅ 1 ngày
          if (_horizonDays == 1) ...[
            const SizedBox(height: 6),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () => _startDueReviewSession(
                  scope: 'now',
                  title: 'Bắt đầu ôn ngay',
                ),
                icon: const Icon(Icons.play_arrow_rounded),
                label: const Text('Bắt đầu ôn ngay', style: TextStyle(fontWeight: FontWeight.w800)),
              ),
            ),
          ] else ...[
            Text(
              'Trong ${horizonLabel()} tới sẽ bận cỡ nào?',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 10),

            // ✅ 7 ngày
            if (_horizonDays == 7) _dueNext7dBarChart(buckets.take(7).toList()),

            // ✅ 4 tuần
            if (_horizonDays == 28) _due28dHeatmap(buckets.take(28).toList()),
          ],
        ],
      ),
    );
  }

  Widget _dueNext7dBarChart(List<dynamic> dueNext7d) {
    if (dueNext7d.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Text('Chưa có dữ liệu 7 ngày tới.', style: TextStyle(color: Colors.grey.shade700)),
      );
    }

    int readCount(dynamic e) {
      try {
        final v = e.count;
        if (v is int) return v;
        return int.tryParse(v.toString()) ?? 0;
      } catch (_) {
        try {
          final v = e['count'];
          if (v is int) return v;
          return int.tryParse(v.toString()) ?? 0;
        } catch (_) {
          return 0;
        }
      }
    }

    dynamic readDayRaw(dynamic e) {
      try {
        return e.day;
      } catch (_) {
        try {
          return e['day'];
        } catch (_) {
          try {
            return e.date;
          } catch (_) {
            try {
              return e['date'];
            } catch (_) {
              return null;
            }
          }
        }
      }
    }

    final counts = dueNext7d.map(readCount).toList();
    final daysRaw = dueNext7d.map(readDayRaw).toList();
    final maxCount = counts.fold<int>(0, (m, x) => x > m ? x : m);

    const gap = 8.0;
    const totalHeight = 150.0;
    const barAreaHeight = 105.0;
    const labelHeight = 18.0;
    const bubbleSize = 22.0;

    double barHeightFor(int c) {
      if (maxCount == 0) return 6.0;
      final usable = barAreaHeight - bubbleSize - 14;
      final ratio = c / maxCount;
      return (ratio * usable).clamp(6.0, usable);
    }

    double bubbleBottomFor(double barH) {
      final maxBottom = barAreaHeight - bubbleSize;
      return (barH + 6).clamp(6.0, maxBottom);
    }

    return SizedBox(
      height: totalHeight,
      child: Column(
        children: [
          SizedBox(
            height: barAreaHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(counts.length, (i) {
                final c = counts[i];
                final barH = barHeightFor(c);
                final isToday = i == 0;

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == counts.length - 1 ? 0 : gap),
                    child: Stack(
                      clipBehavior: Clip.none,
                      alignment: Alignment.bottomCenter,
                      children: [
                        Container(
                          height: barH,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [
                                (isToday ? Colors.orange.shade400 : Colors.orange.shade300)
                                    .withOpacity(0.55),
                                (isToday ? Colors.deepOrange.shade300 : Colors.deepOrange.shade200)
                                    .withOpacity(0.35),
                              ],
                            ),
                            border: Border.all(
                              color: isToday
                                  ? Colors.deepOrange.withOpacity(0.55)
                                  : Colors.orange.withOpacity(0.30),
                              width: isToday ? 1.4 : 1.0,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: bubbleBottomFor(barH),
                          child: Container(
                            width: bubbleSize,
                            height: bubbleSize,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                              border: Border.all(color: Colors.orange.withOpacity(0.35)),
                            ),
                            child: Text(
                              '$c',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: labelHeight,
            child: Row(
              children: List.generate(daysRaw.length, (i) {
                final isToday = i == 0;
                final label = _fmtDayLabel(daysRaw[i]);
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == daysRaw.length - 1 ? 0 : gap),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          label.isEmpty ? '—' : label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isToday ? FontWeight.w700 : FontWeight.w400,
                            color: isToday ? Colors.deepOrange : Colors.grey.shade700,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }

  Widget _due28dHeatmap(List<DueBucket> buckets) {
    DateTime? parseDay(String iso) {
      final s = iso.trim();
      if (s.isEmpty) return null;
      final base = s.contains('T')
          ? s.split('T').first
          : (s.contains(' ') ? s.split(' ').first : s);
      return DateTime.tryParse(base);
    }

    String isoOf(DateTime d) =>
        '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

    String fmtFull(DateTime d) =>
        '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';

    final map = <String, int>{};
    DateTime? minDay;

    for (final b in buckets) {
      final dt = parseDay(b.day);
      if (dt == null) continue;
      final d = DateTime(dt.year, dt.month, dt.day);
      final iso = isoOf(d);
      map[iso] = b.count;
      if (minDay == null || d.isBefore(minDay!)) minDay = d;
    }

    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final todayIso = isoOf(today);

    final horizonStart = minDay ?? today;
    final horizonEnd = horizonStart.add(const Duration(days: 28));

    final anchorMonday =
        horizonStart.subtract(Duration(days: horizonStart.weekday - 1));

    final cells = List.generate(
      4,
      (_) => List<_HeatCell>.filled(7, _HeatCell.empty(), growable: false),
    );

    int maxCount = 0;
    for (int w = 0; w < 4; w++) {
      for (int wd = 0; wd < 7; wd++) {
        final d0 = anchorMonday.add(Duration(days: w * 7 + wd));
        final day = DateTime(d0.year, d0.month, d0.day);
        final iso = isoOf(day);
        final count = map[iso] ?? 0;

        final inRange = !day.isBefore(horizonStart) && day.isBefore(horizonEnd);
        cells[w][wd] = _HeatCell(day: day, iso: iso, count: count, inRange: inRange);

        if (inRange && count > maxCount) maxCount = count;
      }
    }

    Color cellColor(_HeatCell c) {
      if (!c.inRange) return Colors.grey.withOpacity(0.06);
      if (c.count <= 0) return Colors.grey.withOpacity(0.10);
      if (maxCount <= 0) return Colors.orange.withOpacity(0.20);
      final t = (c.count / maxCount).clamp(0.0, 1.0);
      return Colors.orange.withOpacity(0.18 + 0.60 * t);
    }

    void openCellDialog(_HeatCell c) {
      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text('Chi tiết'),
          content: Text('${fmtFull(c.day)}\nSố thẻ đến hạn: ${c.count}'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Đóng')),
          ],
        ),
      );
    }

    const weekdays = ['Th 2', 'Th 3', 'Th 4', 'Th 5', 'Th 6', 'Th 7', 'CN'];
    const gap = 8.0;
    const labelW = 52.0;

    return LayoutBuilder(
      builder: (context, c) {
        final usableW = c.maxWidth - labelW - gap * 6;
        final cellSize = (usableW / 7).clamp(22.0, 44.0);

        Widget cellBox(_HeatCell cell) {
          final isToday = cell.iso == todayIso;

          return Tooltip(
            message: '${fmtFull(cell.day)}: ${cell.count}',
            child: InkWell(
              borderRadius: BorderRadius.circular(10),
              onTap: () => openCellDialog(cell),
              child: Container(
                width: cellSize,
                height: cellSize,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: cellColor(cell),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isToday
                        ? Colors.deepOrange
                        : Colors.orange.withOpacity(cell.inRange ? 0.18 : 0.10),
                    width: isToday ? 2.0 : 1.0,
                  ),
                  boxShadow: isToday
                      ? [
                          BoxShadow(
                            color: Colors.deepOrange.withOpacity(0.18),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Text(
                  '${cell.count}',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                    color: cell.inRange
                        ? (cell.count == 0 ? Colors.grey.shade600 : Colors.deepOrange.shade700)
                        : Colors.grey.shade500,
                  ),
                ),
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const SizedBox(width: labelW),
                for (int i = 0; i < 7; i++) ...[
                  SizedBox(
                    width: cellSize,
                    child: Center(
                      child: Text(
                        weekdays[i],
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 12,
                          color: Colors.grey.shade700,
                        ),
                      ),
                    ),
                  ),
                  if (i != 6) const SizedBox(width: gap),
                ]
              ],
            ),
            const SizedBox(height: 10),
            for (int w = 0; w < 4; w++) ...[
              Row(
                children: [
                  SizedBox(
                    width: labelW,
                    child: Text(
                      'Tuần ${w + 1}',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ),
                  for (int wd = 0; wd < 7; wd++) ...[
                    cellBox(cells[w][wd]),
                    if (wd != 6) const SizedBox(width: gap),
                  ],
                ],
              ),
              if (w != 3) const SizedBox(height: gap),
            ],
          ],
        );
      },
    );
  }
}

class _HeatCell {
  final DateTime day;
  final String iso;
  final int count;
  final bool inRange;

  const _HeatCell({
    required this.day,
    required this.iso,
    required this.count,
    required this.inRange,
  });

  factory _HeatCell.empty() => _HeatCell(
        day: DateTime(1970, 1, 1),
        iso: '1970-01-01',
        count: 0,
        inRange: false,
      );
}
