part of 'statistics_detail_page.dart';

extension _StatisticsDetailProgress on _StatisticsDetailPageState {
  Widget _progressCard(StatsProgress p) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Progress', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 6),
          Text(
            'Số lượt ôn mỗi ngày (14 ngày gần nhất).',
            style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
          ),
          const SizedBox(height: 12),
          _reviewsPerDayBarChart(p.daily),
        ],
      ),
    );
  }

  Widget _reviewsPerDayBarChart(List<DailyProgress> daily) {
    if (daily.isEmpty) {
      return Text('Chưa có dữ liệu ôn tập.', style: TextStyle(color: Colors.grey.shade700));
    }

    int maxReviews = 0;
    for (final d in daily) {
      if (d.reviews > maxReviews) maxReviews = d.reviews;
    }

    String fmtDayLabel(String iso) {
      try {
        final dt = DateTime.parse(iso);
        String two(int v) => v.toString().padLeft(2, '0');
        return '${two(dt.day)}/${two(dt.month)}';
      } catch (_) {
        return iso;
      }
    }

    final todayUtc = DateTime.now().toUtc();
    String two(int v) => v.toString().padLeft(2, '0');
    final todayIso = '${todayUtc.year}-${two(todayUtc.month)}-${two(todayUtc.day)}';

    const totalHeight = 170.0;
    const barAreaHeight = 110.0;
    const labelHeight = 18.0;
    const valueHeight = 16.0;
    const gap = 8.0;

    double barHeightFor(int v) {
      if (maxReviews == 0) return 6.0;
      final usable = barAreaHeight;
      return (v / maxReviews * usable).clamp(6.0, usable);
    }

    bool showLabel(int i, int n) => i == 0 || i == n - 1 || (i % 2 == 0);

    return SizedBox(
      height: totalHeight,
      child: Column(
        children: [
          SizedBox(
            height: barAreaHeight + valueHeight,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(daily.length, (i) {
                final item = daily[i];
                final v = item.reviews;
                final barH = barHeightFor(v);
                final isToday = item.day == todayIso;

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == daily.length - 1 ? 0 : gap),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        SizedBox(
                          height: valueHeight,
                          child: Center(
                            child: FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                '$v',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 12,
                                  color: isToday ? Colors.deepOrange : Colors.grey.shade800,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Tooltip(
                          message: '${fmtDayLabel(item.day)}: $v lượt ôn',
                          child: Container(
                            height: barH,
                            width: double.infinity,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              gradient: LinearGradient(
                                begin: Alignment.bottomCenter,
                                end: Alignment.topCenter,
                                colors: [
                                  Colors.orange.shade300.withOpacity(0.55),
                                  Colors.deepOrange.shade400.withOpacity(0.25),
                                ],
                              ),
                              border: Border.all(
                                color: isToday
                                    ? Colors.deepOrange.withOpacity(0.65)
                                    : Colors.orange.withOpacity(0.30),
                                width: isToday ? 1.5 : 1.0,
                              ),
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
          const SizedBox(height: 10),
          SizedBox(
            height: labelHeight,
            child: Row(
              children: List.generate(daily.length, (i) {
                final label = fmtDayLabel(daily[i].day);
                final isToday = daily[i].day == todayIso;

                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(right: i == daily.length - 1 ? 0 : gap),
                    child: Center(
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          showLabel(i, daily.length) ? label : '',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: isToday ? FontWeight.w800 : FontWeight.w400,
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
}
