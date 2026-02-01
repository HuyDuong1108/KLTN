part of 'statistics_detail_page.dart';

extension _StatisticsDetailFormatters on _StatisticsDetailPageState {
  String _fmtInt(int n) {
    final s = n.toString();
    return s.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  String _pct(double v) => '${(v * 100).round()}%';

  String _fmtDayLabel(dynamic raw) {
    if (raw == null) return '';

    DateTime? dt;

    if (raw is DateTime) {
      dt = raw;
    } else {
      final s0 = raw.toString().trim();
      if (s0.isEmpty) return '';

      final base = s0.contains('T')
          ? s0.split('T').first
          : (s0.contains(' ') ? s0.split(' ').first : s0);

      try {
        dt = DateTime.parse(base);
      } catch (_) {
        dt = null;
      }
    }

    if (dt == null) return raw.toString();
    String two(int v) => v.toString().padLeft(2, '0');
    return '${two(dt.day)}/${two(dt.month)}';
  }
}
