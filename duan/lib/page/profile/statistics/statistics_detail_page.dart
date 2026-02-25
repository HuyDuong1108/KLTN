import 'package:flutter/material.dart';
import '../../../data/stats_api.dart';
import '../../../models/stats_summary.dart';
import '../../../models/stats_progress.dart';
import '../../homeaction/chatgemni.dart';
import '../../../models/coach_insight.dart';
import '../../../models/ai_coach.dart';
import 'coach_chat_page.dart';
import 'due_review_session_page.dart' show DueReviewSessionPage, DueReviewMode;
import '../../../models/due_cards_detail.dart';
import '../../../models/flashcard_set.dart';
import '../../../models/vocabulary.dart';
import '../../flashcard/flashcard_set_detail.dart';

part 'statistics_detail_formatters.dart';
part 'statistics_detail_cards.dart';
part 'statistics_detail_study_plan.dart';
part 'statistics_detail_progress.dart';
part 'statistics_detail_history.dart';

class StatisticsDetailPage extends StatefulWidget {
  const StatisticsDetailPage({super.key});

  @override
  State<StatisticsDetailPage> createState() => _StatisticsDetailPageState();
}

class _StatisticsDetailPageState extends State<StatisticsDetailPage>
    with SingleTickerProviderStateMixin {
    late Future<StatsSummary> _statsFuture;
    late Future<StatsProgress> _progressFuture;
    late final TabController _tab;
    // late Future<CoachInsight> _coachFuture;
    late Future<AiCoachResponse> _aiCoachFuture;

    int _horizonDays = 7; // 1 / 7 / 28
    static const int _coachHorizonDays = 7;
    String _fmtDueLocal(String? isoUtc) {
      if (isoUtc == null || isoUtc.isEmpty) return '—';
      final dt = DateTime.tryParse(isoUtc);
      if (dt == null) return '—';
      final local = dt.toLocal();
      final hh = local.hour.toString().padLeft(2, '0');
      final mm = local.minute.toString().padLeft(2, '0');
      final dd = local.day.toString().padLeft(2, '0');
      final mo = local.month.toString().padLeft(2, '0');
      return '$hh:$mm  $dd/$mo';
    }
    final GlobalKey _studyPlanKey = GlobalKey();
    Future<void> _handleCoachPrimaryAction(String action) async {
      final act = (action).trim();

      if (act == 'start_review_due_now') {
        await _openDueCardsSheet(
          scope: 'now',
          title: 'Cần ôn ngay',
          includeCommunity: true,
        );
        return;
      }

      if (act == 'start_review_today') {
        await _openDueCardsSheet(
          scope: 'today',
          title: 'Trong hôm nay',
          includeCommunity: true,
        );
        return;
      }

      if (act == 'open_study_plan') {
        if (_horizonDays != 1) {
          _setHorizon(1);
        }

        await Future.delayed(const Duration(milliseconds: 60));
        final ctx = _studyPlanKey.currentContext;
        if (ctx != null) {
          Scrollable.ensureVisible(
            ctx,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOut,
          );
        }
        return;
      }

      // fallback an toàn: mở kế hoạch
      if (_horizonDays != 1) {
        _setHorizon(1);
      }
    }



  Future<void> _openReviewLauncher({
    required String scope, // 'now' | 'today'
    required String title,
    String? startCardId,
  }) async {
    final picked = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: false,
      backgroundColor: Colors.transparent,
      builder: (c) {
        return SafeArea(
          child: Container(
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 10),
                Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black12,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
                const SizedBox(height: 12),
                ListTile(
                  title: const Text('Ôn tất cả thẻ đến hạn', style: TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: Text(scope == 'now'
                      ? 'Tất cả thẻ đã tới hạn (<= hiện tại)'
                      : 'Tất cả thẻ đến hạn trong hôm nay'),
                  leading: const Icon(Icons.play_circle_fill, color: Colors.blue),
                  onTap: () => Navigator.pop(c, 'all'),
                ),
                ListTile(
                  title: const Text('Chỉ ôn thẻ quá hạn lâu)', style: TextStyle(fontWeight: FontWeight.w800)),
                  subtitle: const Text('Tập trung xử lý thẻ “kẹt” lâu'),
                  leading: const Icon(Icons.schedule, color: Colors.redAccent),
                  onTap: () => Navigator.pop(c, 'long24h'),
                ),
                const SizedBox(height: 8),
                const Divider(height: 1),
                const SizedBox(height: 8),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
                  child: SizedBox(
                    width: double.infinity,
                    height: 46,
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(c),
                      child: const Text('Đóng'),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    if (picked == null) return;

    await _startDueReviewSession(
      scope: scope,
      title: title,
      startCardId: startCardId,
      mode: picked == 'long24h' ? DueReviewMode.long24h : DueReviewMode.all,
    );
  }
  

  Future<void> _goToSetFromDueMatch(
  DueCardMatch m,
  BuildContext sheetCtx, {
  String? highlightWord,
}) async {
    final isPersonal = m.tab == 'personal';
    final set = FlashcardSet(
      id: m.setId,
      title: m.setTitle,
      description: '',
      vocabList: const <Vocabulary>[],
      participants: 1,
    );

    Navigator.pop(sheetCtx);

    await Future.delayed(Duration.zero);
    if (!mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlashcardSetDetailPage(
          set: set,
          isPersonal: isPersonal,
          highlightWord: highlightWord, //  NEW
        ),
      ),
    );
  }


  Future<void> _openDueCardsSheet({
    required String scope, // now | today
    required String title,
    bool includeCommunity = false,
  }) async {
    // NOTE: để lọc được "Cộng đồng", includeCommunity phải true.
    final future = StatsApi.instance.fetchDueCardsDetail(
      scope: scope,
      includeCommunity: includeCommunity,
    );

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        String tabFilter = 'all'; // all | personal | community
        Set<String> timeFilters = <String>{'all'}; // multi-select

        String _tabLabel(String v) {
          switch (v) {
            case 'personal':
              return 'Cá nhân';
            case 'community':
              return 'Cộng đồng';
            default:
              return 'Tất cả';
          }
        }

        String _timeLabel(Set<String> v, String scope) {
          if (v.contains('all') || v.isEmpty) return 'Tất cả';
          if (v.length == 1) {
            final k = v.first;
            if (k == 'overdue') return 'Vừa quá hạn';
            if (k == 'just') return 'Vừa tới hạn';
            if (k == 'soon') return 'Sắp đến hạn';
            if (k == 'later') return scope == 'today' ? 'Còn lại hôm nay' : 'Khác';
            if (k == 'long') return 'Quá hạn lâu';
            return 'Đã chọn';
          }
          return '${v.length} lựa chọn';
        }
        bool showTopBtn = false;

        Widget _filterPill({
          required String text,
          required VoidCallback onTap,
        }) {
          final maxW = MediaQuery.of(ctx).size.width; // ctx của builder showModalBottomSheet
          return InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(999),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: Colors.black12),
              ),
              child: ConstrainedBox(
                // trừ bớt cho icon filter + khoảng cách
                constraints: BoxConstraints(maxWidth: maxW - 120),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        text,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 6),
                    const Icon(Icons.keyboard_arrow_down, size: 18),
                  ],
                ),
              ),
            ),
          );
        }


        Future<Set<String>?> _pickTimeFilters({
          required BuildContext context,
          required String scope,
          required Set<String> current,
        }) async {
          final result = await showModalBottomSheet<Set<String>>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (c) {
              Set<String> temp = {...current};
              if (temp.isEmpty) temp = {'all'};

              final options = scope == 'today'
                  ? const <Map<String, String>>[
                      {'k': 'all', 't': 'Tất cả'},
                      {'k': 'overdue', 't': 'Quá hạn'},
                      {'k': 'just', 't': 'Vừa tới hạn'},
                      {'k': 'soon', 't': 'Sắp đến hạn'},
                      {'k': 'later', 't': 'Còn lại hôm nay'},
                    ]
                  : const <Map<String, String>>[
                      {'k': 'all', 't': 'Tất cả'},
                      {'k': 'overdue', 't': 'Vừa quá hạn'},
                      {'k': 'just', 't': 'Vừa tới hạn'},
                      {'k': 'long', 't': 'Quá hạn lâu'},
                    ];

              return StatefulBuilder(
                builder: (c, setS) {
                  void toggle(String key, bool v) {
                    setS(() {
                      if (key == 'all') {
                        if (v) {
                          temp = {'all'};
                        } else {
                          temp.clear();
                          temp = {'all'};
                        }
                        return;
                      }

                      if (v) {
                        temp.remove('all');
                        temp.add(key);
                      } else {
                        temp.remove(key);
                        if (temp.isEmpty) temp = {'all'};
                      }
                    });
                  }

                  return SafeArea(
                  child: Container(
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                    ),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                    child: SizedBox(
                      height: MediaQuery.of(c).size.height * 0.65, // <-- giới hạn chiều cao
                      child: Column(
                        children: [
                          Container(
                            width: 44,
                            height: 5,
                            decoration: BoxDecoration(
                              color: Colors.black12,
                              borderRadius: BorderRadius.circular(99),
                            ),
                          ),
                          const SizedBox(height: 12),
                          const Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Chọn trạng thái thẻ',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(height: 8),

                          // <-- quan trọng: bỏ shrinkWrap, dùng Expanded
                          Expanded(
                            child: ListView(
                              children: options.map((o) {
                                final k = o['k']!;
                                final t = o['t']!;
                                final checked = temp.contains(k);
                                return CheckboxListTile(
                                  contentPadding: EdgeInsets.zero,
                                  value: checked,
                                  onChanged: (val) => toggle(k, val ?? false),
                                  title: Text(t, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  controlAffinity: ListTileControlAffinity.leading,
                                );
                              }).toList(),
                            ),
                          ),

                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () => setS(() => temp = {'all'}),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.blue,
                                    side: BorderSide(color: Colors.blue.withOpacity(0.6)),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text('Đặt lại'),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () => Navigator.pop(c, temp.isEmpty ? {'all'} : temp),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.blue,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                  child: const Text(
                                    'Xong',
                                    style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );

                },
              );
            },
          );

          return result;
        }
        Future<String?> _pickTabFilter({
          required BuildContext context,
          required String current,
        }) async {
          final result = await showModalBottomSheet<String>(
            context: context,
            isScrollControlled: true,
            backgroundColor: Colors.transparent,
            builder: (c) {
              String temp = current;

              const options = <Map<String, String>>[
                {'k': 'all', 't': 'Tất cả'},
                {'k': 'community', 't': 'Cộng đồng'},
                {'k': 'personal', 't': 'Cá nhân'},
              ];

              return StatefulBuilder(
                builder: (c, setS) {
                  return SafeArea(
                    child: Container(
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                      ),
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                      child: SizedBox(
                        height: MediaQuery.of(c).size.height * 0.55, // <-- giới hạn chiều cao
                        child: Column(
                          children: [
                            Container(
                              width: 44,
                              height: 5,
                              decoration: BoxDecoration(
                                color: Colors.black12,
                                borderRadius: BorderRadius.circular(99),
                              ),
                            ),
                            const SizedBox(height: 12),
                            const Align(
                              alignment: Alignment.centerLeft,
                              child: Text(
                                'Chọn bộ',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(height: 8),

                            // <-- quan trọng: danh sách cuộn, không còn tràn đáy
                            Expanded(
                              child: ListView(
                                children: options.map((o) {
                                  final k = o['k']!;
                                  final t = o['t']!;
                                  final selected = temp == k;

                                  return ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    onTap: () => setS(() => temp = k),
                                    leading: Icon(
                                      selected ? Icons.check_circle : Icons.circle_outlined,
                                      color: selected ? Colors.blue : Colors.black26,
                                    ),
                                    title: Text(t, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  );
                                }).toList(),
                              ),
                            ),

                            const SizedBox(height: 8),
                            SizedBox(
                              width: double.infinity,
                              height: 46,
                              child: ElevatedButton(
                                onPressed: () => Navigator.pop(c, temp),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.blue,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                                child: const Text(
                                  'Xong',
                                  style: TextStyle(fontWeight: FontWeight.w800, color: Colors.white),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );

                },
              );
            },
          );

          return result;
        }


        return StatefulBuilder(
          builder: (ctx, setModalState) {
            return DraggableScrollableSheet(
              initialChildSize: 0.75,
              minChildSize: 0.45,
              maxChildSize: 0.95,
              builder: (context, controller) {
                final sheetBg = Colors.grey.shade100;
                return Container(
                  decoration: BoxDecoration(
                    color: sheetBg,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
                  ),
                  child: Column(
                    children: [
                      const SizedBox(height: 10),
                      Container(
                        width: 44,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(99),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Title row
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                title,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              onPressed: () => Navigator.pop(ctx),
                              icon: const Icon(Icons.close),
                            ),
                          ],
                        ),
                      ),
                      const Divider(height: 1),

                      Expanded(
                        child: FutureBuilder<DueCardsDetailResponse>(
                          future: future,
                          builder: (context, snap) {
                            if (snap.connectionState != ConnectionState.done) {
                              return const Center(child: CircularProgressIndicator());
                            }
                            if (snap.hasError) {
                              return Padding(
                                padding: const EdgeInsets.all(16),
                                child: Text('Lỗi tải danh sách: ${snap.error}'),
                              );
                            }

                            final data = snap.data;
                            final items = data?.items ?? [];
                            if (items.isEmpty) {
                              return const Center(child: Text('Không có thẻ tới hạn.'));
                            }

                            final nowLocal = DateTime.now();

                            DateTime? parseDueLocal(String? isoUtc) {
                              if (isoUtc == null || isoUtc.isEmpty) return null;
                              final dt = DateTime.tryParse(isoUtc);
                              if (dt == null) return null;
                              return dt.toLocal();
                            }

                            bool passTabFilter(DueCardDetailItem it) {
                              if (tabFilter == 'all') return true;
                              if (it.matches.isEmpty) return false;
                              final t = it.matches.first.tab; // personal | community
                              return t == tabFilter;
                            }

                            // ---- time classification ----
                            const justMins = 15;
                            const longMins = 360;
                            int minsPast(DateTime dueLocal) => nowLocal.difference(dueLocal).inMinutes;
                            bool isOverdueAny(DateTime dueLocal) => minsPast(dueLocal) >= 0;
                            
                            bool isJustDue(DateTime dueLocal) {
                              final m = minsPast(dueLocal);
                              return m >= 0 && m <= justMins;
                            }

                            bool isOverdueLong(DateTime dueLocal) {
                              final m = minsPast(dueLocal);
                              return m >= longMins;
                            }

                            bool isOverdueNormal(DateTime dueLocal) {
                              final m = minsPast(dueLocal);
                              return m > justMins && m < longMins;
                            }

                            bool isDueSoon(DateTime dueLocal) {
                              final mins = dueLocal.difference(nowLocal).inMinutes;
                              return mins > 0 && mins <= 120;
                            }

                            bool isLaterToday(DateTime dueLocal) {
                              final mins = dueLocal.difference(nowLocal).inMinutes;
                              return mins > 120;
                            }

                            bool passTimeFilter(DueCardDetailItem it) {
                              final dueLocal = parseDueLocal(it.due);
                              if (dueLocal == null) return false;

                              if (timeFilters.contains('all') || timeFilters.isEmpty) return true;

                              // NOTE: 'overdue' là nhóm rộng: gồm cả 'just' và 'long'
                              final selectedOverdue = timeFilters.contains('overdue');
                              final selectedJust = timeFilters.contains('just');
                              final selectedLong = timeFilters.contains('long');
                              final selectedSoon = timeFilters.contains('soon');
                              final selectedLater = timeFilters.contains('later');

                              final just = isJustDue(dueLocal);
                              final long = isOverdueLong(dueLocal);
                              final overdueNormal = isOverdueNormal(dueLocal);
                              final soon = isDueSoon(dueLocal);
                              final later = isLaterToday(dueLocal);
                              
                              bool ok = false;

                              if (selectedJust && just) ok = true;
                              if (selectedLong && long) ok = true;
                              if (selectedOverdue && overdueNormal) ok = true;

                              if (scope == 'today') {
                                if (selectedSoon && soon) ok = true;
                                if (selectedLater && later) ok = true;
                              }

                              return ok;
                            }

                            Color badgeColor(DateTime dueLocal) {
                              final diffMin = dueLocal.difference(nowLocal).inMinutes;
                              if (diffMin <= 0) {
                                if (isJustDue(dueLocal)) return Colors.blue.withOpacity(0.95);
                                if (isOverdueLong(dueLocal)) return Colors.red.withOpacity(0.9);
                                return Colors.red.withOpacity(0.85);
                              }
                              if (isDueSoon(dueLocal)) return Colors.amber.withOpacity(0.95);
                              return Colors.grey.withOpacity(0.65);
                            }

                            String _hhmm(DateTime d) {
                              final hh = d.hour.toString().padLeft(2, '0');
                              final mm = d.minute.toString().padLeft(2, '0');
                              return '$hh:$mm';
                            }

                            String badgeText(DateTime dueLocal) {
                              final diffMin = dueLocal.difference(nowLocal).inMinutes;

                              // Past / now
                              if (diffMin <= 0) {
                                final minsPast = nowLocal.difference(dueLocal).inMinutes;
                                if (minsPast <= 15) return 'Vừa tới hạn';
                                if (minsPast < 60) return 'Quá hạn ${minsPast} phút';
                                final hours = minsPast ~/ 60;
                                return 'Quá hạn $hours giờ';
                              }

                              // Future (only meaningful for scope today)
                              final t = _hhmm(dueLocal);
                              if (diffMin <= 120) return 'Sắp đến hạn ($t)';
                              return 'Còn hôm nay ($t)';
                            }

                            // ---- build filtered & sort ----
                            final filtered = items
                                .where((it) => passTabFilter(it) && passTimeFilter(it))
                                .toList()
                              ..sort((a, b) {
                                final da = parseDueLocal(a.due);
                                final db = parseDueLocal(b.due);
                                if (da == null && db == null) return 0;
                                if (da == null) return 1;
                                if (db == null) return -1;
                                return da.compareTo(db);
                              });
                            final totalCount = items.length;
                            final shownCount = filtered.length;

                            // ---- filter bar (dropdown style) ----
                            return Column(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                                  child: Row(
                                    children: [
                                      Text(
                                        'Hiển thị $shownCount / $totalCount thẻ',
                                        style: TextStyle(
                                          color: Colors.grey.shade700,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                      const Spacer(),
                                    ],
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.fromLTRB(16, 10, 16, 10),
                                  child: Wrap(
                                    crossAxisAlignment: WrapCrossAlignment.center,
                                    spacing: 10,
                                    runSpacing: 8,
                                    children: [
                                      Icon(Icons.filter_alt_outlined, color: Colors.grey.shade700),

                                      // Bộ
                                      _filterPill(
                                        text: 'Bộ: ${_tabLabel(tabFilter)}',
                                        onTap: () async {
                                          final picked = await _pickTabFilter(context: ctx, current: tabFilter);
                                          if (picked != null) setModalState(() => tabFilter = picked);
                                        },
                                      ),

                                      // Trạng thái thẻ (multi)
                                      _filterPill(
                                        text: 'Trạng thái thẻ: ${_timeLabel(timeFilters, scope)}',
                                        onTap: () async {
                                          final picked = await _pickTimeFilters(
                                            context: ctx,
                                            scope: scope,
                                            current: timeFilters,
                                          );
                                          if (picked != null) {
                                            setModalState(() => timeFilters = picked.isEmpty ? {'all'} : picked);
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                ),

                                const Divider(height: 1),

                                Expanded(
                                  child: Stack(
                                    children: [
                                      Positioned.fill(
                                        child: filtered.isEmpty
                                            ? const Center(child: Text('Không có thẻ theo bộ lọc.'))
                                            : NotificationListener<ScrollNotification>(
                                                onNotification: (n) {
                                                  // hiện nút khi scroll xuống sâu
                                                  final canScroll = n.metrics.maxScrollExtent > 80; 
                                                  final shouldShow = canScroll && n.metrics.pixels > 160;
                                                  if (shouldShow != showTopBtn) {
                                                    setModalState(() => showTopBtn = shouldShow);
                                                  }
                                                  return false;
                                                },
                                                child: ListView.separated(
                                                  controller: controller,
                                                  padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
                                                  itemCount: filtered.length,
                                                  separatorBuilder: (_, __) => const SizedBox(height: 10),

                                                  itemBuilder: (context, i) {
                                                    final it = filtered[i];
                                                    final dueText = _fmtDueLocal(it.due);
                                                    final dueLocal = parseDueLocal(it.due);

                                                    final hasMatch = it.matches.isNotEmpty;
                                                    final m0 = hasMatch ? it.matches.first : null;

                                                    final tabLabel = !hasMatch
                                                        ? 'Không xác định bộ thẻ'
                                                        : (m0!.tab == 'personal' ? 'Cá nhân' : 'Cộng đồng');

                                                    final setTitle = !hasMatch ? '' : m0!.setTitle;
                                                    final reading = !hasMatch ? null : m0!.reading;
                                                    final meaning = !hasMatch ? null : m0!.meaning;

                                                    final mainTitle = hasMatch ? m0!.word : it.cardId;

                                                    final bColor = dueLocal == null
                                                        ? Colors.grey.withOpacity(0.65)
                                                        : badgeColor(dueLocal);
                                                    final bText =
                                                        dueLocal == null ? '—' : badgeText(dueLocal);

                                                    final card = Container(
                                                      padding: const EdgeInsets.all(12),
                                                      decoration: BoxDecoration(
                                                        color: Colors.white,
                                                        borderRadius: BorderRadius.circular(12),
                                                        border: Border.all(color: Colors.black12),
                                                      ),
                                                      child: Column(
                                                        crossAxisAlignment: CrossAxisAlignment.start,
                                                        children: [
                                                          Row(
                                                            children: [
                                                              Expanded(
                                                                child: Row(
                                                                  children: [
                                                                    Flexible(
                                                                      child: Text(
                                                                        mainTitle,
                                                                        overflow: TextOverflow.ellipsis,
                                                                        style: const TextStyle(
                                                                          fontWeight: FontWeight.bold,
                                                                          fontSize: 15,
                                                                        ),
                                                                      ),
                                                                    ),
                                                                    const SizedBox(width: 8),
                                                                  ],
                                                                ),
                                                              ),
                                                              Container(
                                                                padding: const EdgeInsets.symmetric(
                                                                    horizontal: 10, vertical: 5),
                                                                decoration: BoxDecoration(
                                                                  color: bColor.withOpacity(0.16),
                                                                  borderRadius: BorderRadius.circular(999),
                                                                  border: Border.all(
                                                                      color: bColor.withOpacity(0.35)),
                                                                ),
                                                                child: Text(
                                                                  bText,
                                                                  style: TextStyle(
                                                                    fontSize: 11,
                                                                    fontWeight: FontWeight.w800,
                                                                    color: bColor,
                                                                  ),
                                                                ),
                                                              ),
                                                              const SizedBox(width: 10),
                                                              Text(dueText,
                                                                  style: const TextStyle(color: Colors.grey)),
                                                            ],
                                                          ),
                                                          const SizedBox(height: 6),
                                                          Text(
                                                            '$tabLabel${setTitle.isEmpty ? '' : ' • $setTitle'}',
                                                            style: const TextStyle(color: Colors.black87),
                                                          ),
                                                          if ((reading ?? '').trim().isNotEmpty ||
                                                              (meaning ?? '').trim().isNotEmpty)
                                                            Padding(
                                                              padding: const EdgeInsets.only(top: 4),
                                                              child: Text(
                                                                [
                                                                  if ((reading ?? '').trim().isNotEmpty)
                                                                    'Reading: $reading',
                                                                  if ((meaning ?? '').trim().isNotEmpty)
                                                                    'Meaning: $meaning',
                                                                ].join(' • '),
                                                                style: const TextStyle(color: Colors.grey),
                                                              ),
                                                            ),
                                                          const SizedBox(height: 6),
                                                          Text('State: ${it.state}',
                                                              style: const TextStyle(color: Colors.grey)),
                                                          if (it.matches.length > 1)
                                                            Padding(
                                                              padding: const EdgeInsets.only(top: 6),
                                                              child: Text(
                                                                '+ ${it.matches.length - 1} vị trí khác',
                                                                style: const TextStyle(color: Colors.blue),
                                                              ),
                                                            ),
                                                        ],
                                                      ),
                                                    );

                                                    return InkWell(
                                                      borderRadius: BorderRadius.circular(12),
                                                      onTap: (m0 == null)
                                                          ? null
                                                          : () => _goToSetFromDueMatch(
                                                                m0,
                                                                ctx,
                                                                highlightWord: m0.word,
                                                              ),
                                                      child: card,
                                                    );

                                                  },
                                                ),
                                              ),
                                      ),

                                      if (showTopBtn)
                                        Positioned(
                                          right: 14,
                                          bottom: 14,
                                          child: Material(
                                            color: Colors.white,
                                            elevation: 4,
                                            shape: const CircleBorder(),
                                            child: InkWell(
                                              customBorder: const CircleBorder(),
                                              onTap: () {
                                                controller.animateTo(
                                                  0,
                                                  duration: const Duration(milliseconds: 280),
                                                  curve: Curves.easeOut,
                                                );
                                              },
                                              child: const Padding(
                                                padding: EdgeInsets.all(10),
                                                child: Icon(
                                                  Icons.keyboard_arrow_up,
                                                  size: 26,
                                                  color: Colors.blue,
                                                ),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ],
                                  ),
                                ),

                              ],
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _statsFuture = StatsApi.instance.fetchSummary(horizonDays: _horizonDays);
    _progressFuture = StatsApi.instance.fetchProgress(days: 1, recent: 100);
    _tab = TabController(length: 2, vsync: this);
    // _coachFuture = StatsApi.instance.fetchCoachInsights(horizonDays: _horizonDays);
    _aiCoachFuture = StatsApi.instance.fetchAiCoach(horizonDays: _coachHorizonDays);
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  Future<void> _refresh() async {
    setState(() {
      _statsFuture = StatsApi.instance.fetchSummary(horizonDays: _horizonDays);
      _progressFuture = StatsApi.instance.fetchProgress(days: 1, recent: 100);
       _aiCoachFuture = StatsApi.instance.fetchAiCoach(horizonDays: _coachHorizonDays);
    });
    await Future.wait([_statsFuture, _progressFuture, _aiCoachFuture]);
  }


  void _setHorizon(int days) {
    if (_horizonDays == days) return;
    setState(() {
      _horizonDays = days;
      _statsFuture = StatsApi.instance.fetchSummary(horizonDays: _horizonDays);
      //_aiCoachFuture = StatsApi.instance.fetchAiCoach(horizonDays: _horizonDays);
    });
  }
  Future<DueReviewMode?> _pickReviewMode() async {
  return showModalBottomSheet<DueReviewMode>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (c) {
      return SafeArea(
        child: Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(99),
                ),
              ),
              const SizedBox(height: 12),
              ListTile(
                leading: const Icon(Icons.play_circle_fill, color: Colors.blue),
                title: const Text('Ôn tất cả thẻ đến hạn', style: TextStyle(fontWeight: FontWeight.w800)),
                onTap: () => Navigator.pop(c, DueReviewMode.all),
              ),
              ListTile(
                leading: const Icon(Icons.schedule, color: Colors.redAccent),
                title: const Text('Chỉ ôn thẻ quá hạn lâu (>= 24h)', style: TextStyle(fontWeight: FontWeight.w800)),
                onTap: () => Navigator.pop(c, DueReviewMode.long24h),
              ),
              const SizedBox(height: 8),
            ],
          ),
        ),
      );
    },
  );
}

Future<void> _startDueReviewSession({
  required String scope,
  required String title,
  String? startCardId,
  DueReviewMode? mode,
}) async {
  final reviewMode = mode ?? await _pickReviewMode();
  if (!mounted || reviewMode == null) return;

  final changed = await Navigator.push<bool>(
    context,
    MaterialPageRoute(
      builder: (_) => DueReviewSessionPage(
        scope: scope,
        title: title,
        includeCommunity: true,
        startCardId: startCardId,
        mode: reviewMode,
      ),
    ),
  );

  if (!mounted) return;

  if (changed == true) {
    await _refresh();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Đã cập nhật thống kê sau phiên ôn.')),
    );
  }
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Color(0xFFF3F9FF),
      appBar: AppBar(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.black,
        elevation: 0,
        title: const Text('Statistics',
        style: TextStyle(
          fontWeight: FontWeight.w600,
          fontSize: 22,
        ),
      ),
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<StatsSummary>(
          future: _statsFuture,
          builder: (context, snapshot) {
            final stats = snapshot.data;
            final hasError = snapshot.hasError;

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _heroAccuracyCard(stats),
                  const SizedBox(height: 12),
                  _coachCard(stats),
                  const SizedBox(height: 16),
                  _overviewCard(stats, hasError: hasError),
                  const SizedBox(height: 16),
                  _tabsBar(),
                  const SizedBox(height: 12),
                  _tabsContent(stats),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
