part of 'statistics_detail_page.dart';

extension _StatisticsDetailCards on _StatisticsDetailPageState {
  Widget _heroAccuracyCard(StatsSummary? stats) {
    final acc = (stats?.successRate7d ?? stats?.successRateAllTime);
    final accText = acc == null ? '—%' : _pct(acc);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 22, horizontal: 18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.orange.shade700,
            Colors.deepOrange.shade400,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withOpacity(0.25),
            blurRadius: 12,
            offset: const Offset(0, 6),
          )
        ],
      ),
      child: Column(
        children: [
          Text(
            accText,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 46,
              fontWeight: FontWeight.bold,
              height: 1.0,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Thành quả 7 ngày qua đây!',
            style: TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _coachCard(StatsSummary? stats) {
  return FutureBuilder<AiCoachResponse>(
    future: _aiCoachFuture,
    builder: (context, snap) {
      if (snap.connectionState == ConnectionState.waiting) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              _coachIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Đang tải gợi ý từ Lingua Coach...',
                  style: TextStyle(fontFamily: 'Roboto',color: Colors.grey.shade700, fontSize: 13),
                ),
              ),
            ],
          ),
        );
      }

      if (snap.hasError || snap.data == null) {
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: _cardDecoration(),
          child: Row(
            children: [
              _coachIcon(),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Không tải được gợi ý (kéo xuống để thử lại).',
                  style: TextStyle(fontFamily: 'Roboto',color: Colors.red.shade400, fontSize: 13),
                ),
              ),
            ],
          ),
        );
      }

      final coach = snap.data!;
      final strengthText = coach.strengths.isNotEmpty ? coach.strengths.first.detail : 'Chưa có dữ liệu.';
      final improveText = coach.improvements.isNotEmpty ? coach.improvements.first.detail : 'Chưa có dữ liệu.';

      final actionTitle = coach.todayAction.title.isNotEmpty ? coach.todayAction.title : 'Gợi ý hành động hôm nay';
      final actionDetail = coach.todayAction.detail.isNotEmpty ? coach.todayAction.detail : '—';
      String _compactCta(String s) {
          final t = s.trim();
            if (t.isEmpty) return 'Thực hiện';
            return t.length > 14 ? 'Thực hiện' : t;
          }

      final ctaText = _compactCta(
        coach.todayAction.cta.isNotEmpty ? coach.todayAction.cta : 'Thực hiện',
        );

      return Container(
        padding: const EdgeInsets.all(14),
        decoration: _cardDecoration(),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _coachIcon(),
            const SizedBox(width: 12),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header: title + link
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Gợi ý từ Lingua Coach',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      TextButton(
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.zero,
                          minimumSize: const Size(0, 0),
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          foregroundColor: Colors.orange,
                        ),
                        onPressed: () => _openCoachDetails(coach),
                        child: const Text(
                          'Xem chi tiết',
                          style: TextStyle(fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Body: 2 columns
                  LayoutBuilder(
                    builder: (context, c) {
                      final canTwoCol = c.maxWidth >= 430;

                      final leftCol = Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _coachLine(
                            icon: Icons.check_circle,
                            iconColor: Colors.green,
                            title: 'Điểm mạnh',
                            detail: strengthText,
                          ),
                          const SizedBox(height: 10),
                          _coachLine(
                            icon: Icons.warning_amber_rounded,
                            iconColor: Colors.redAccent,
                            title: 'Cần cải thiện',
                            detail: improveText,
                          ),
                        ],
                      );

                      final rightCol = Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF1E8),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: const Color(0xFFFF9A62)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              actionTitle,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 6),
                            Text(
                              actionDetail,
                              style: TextStyle(color: Colors.grey.shade800, fontSize: 13),
                              maxLines: 3,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.orange,
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  elevation: 0,
                                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  minimumSize: const Size(0, 36),
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                ),
                                // onPressed: () => _handleCoachAction(coach.todayAction.action),
                                onPressed: () => _handleCoachPrimaryAction(coach.todayAction.action),
                                child: Text(
                                  ctaText,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  softWrap: false,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );

                      if (!canTwoCol) {
                        // màn hẹp: 1 cột (left trước, action box xuống dưới)
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            leftCol,
                            const SizedBox(height: 12),
                            rightCol,
                          ],
                        );
                      }

                      // đủ rộng: 2 cột (khóa bề rộng cột phải để không bị bóp quá nhỏ)
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: leftCol),
                          const SizedBox(width: 12),
                          SizedBox(width: 210, child: rightCol),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    },
  );
}

Widget _coachLine({
  required IconData icon,
  required String title,
  required String detail,
  Color? iconColor,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 18, color: iconColor ?? Colors.orange),
      const SizedBox(width: 8),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
            const SizedBox(height: 2),
            Text(
              detail,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    ],
  );
}

void _openCoachDetails(AiCoachResponse coach) {
  final strengthText = coach.strengths.isNotEmpty ? coach.strengths.first.detail : '—';
  final improveText = coach.improvements.isNotEmpty ? coach.improvements.first.detail : '—';
  final actionText = coach.todayAction.detail.isNotEmpty ? coach.todayAction.detail : '—';

  final seed = [
    'Tóm tắt:',
    '• Điểm mạnh: $strengthText',
    '• Cần cải thiện: $improveText',
    '• Hành động: $actionText',
  ].join('\n');

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => CoachChatPage(
        horizonDays: _horizonDays,
        seedMessage: seed,
      ),
    ),
  );
}

  Widget _coachIcon() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        width: 44,
        height: 44,
        color: Colors.orange.withOpacity(0.12),
        alignment: Alignment.center,
        child: const Icon(Icons.school, color: Colors.orange),
      ),
    );
  }


  void _handleCoachAction(String action) {
    _tab.animateTo(0);

    final a = action.trim().toLowerCase();
    final scope = (a.contains('today') || a.contains('hom_nay')) ? 'today' : 'now';

    _startDueReviewSession(
      scope: scope,
      title: 'Bắt đầu ôn',
    );
  }


  Widget _overviewCard(StatsSummary? stats, {required bool hasError}) {
    final days = stats?.daysActiveTotal;
    final streak = stats?.streakCurrent;
    final xp = stats?.xpTotal;
    final success = stats?.successRateAllTime;

    final daysText = days == null ? '—' : '$days';
    final streakText = streak == null ? '—' : '$streak';
    final xpText = xp == null ? '—' : _fmtInt(xp);
    final successText = success == null ? '—' : _pct(success);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Overview', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          if (hasError)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Text(
                'Không tải được thống kê (kéo xuống để refresh).',
                style: TextStyle(color: Colors.red.shade400),
              ),
            ),
          Row(
            children: [
              _overviewItem(Icons.calendar_month, daysText, 'Days'),
              _overviewItem(Icons.local_fire_department, streakText, 'Streak'),
              _overviewItem(Icons.star, xpText, 'XP'),
              _overviewItem(Icons.check_circle, successText, 'Success'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _overviewItem(IconData icon, String value, String label) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 6),
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.orange.withOpacity(0.06),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.orange, size: 26),
            const SizedBox(height: 6),
            Text(value, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            const SizedBox(height: 2),
            Text(label, style: TextStyle(color: Colors.grey.shade700, fontSize: 12)),
          ],
        ),
      ),
    );
  }

  Widget _tabsBar() {
  return Container(
    height: 44,
    padding: const EdgeInsets.all(4),
    decoration: _cardDecoration(),
    child: TabBar(
      controller: _tab,
      dividerColor: Colors.transparent,

      indicatorSize: TabBarIndicatorSize.tab,
      indicatorPadding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),

      indicator: BoxDecoration(
        color: Colors.orange,
        borderRadius: BorderRadius.circular(14),
      ),

      labelColor: Colors.white,
      unselectedLabelColor:const Color(0xFF7A4A00),
      labelStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),

      tabs: const [
        Tab(child: Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Ôn tập'))),
        Tab(child: Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Lịch sử'))),
      ],
    ),
  );
}


  Widget _tabsContent(StatsSummary? stats) {
    return AnimatedBuilder(
      animation: _tab,
      builder: (context, _) {
        if (_tab.index == 0) {
          return _studyPlanCard(stats);
        }
        return FutureBuilder<StatsProgress>(
          future: _progressFuture,
          builder: (context, snap) {
            if (snap.hasError) {
              return Container(
                padding: const EdgeInsets.all(16),
                decoration: _cardDecoration(),
                child: Text(
                  'Chưa tải được lịch sử ôn (kéo xuống để thử lại).',
                  style: TextStyle(color: Colors.red.shade400),
                ),
              );
            }
            final p = snap.data;
            if (p == null) return const SizedBox.shrink();
            return _historyTimelineCard(p);
          },
        );
      },
    );
  }

  BoxDecoration _cardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 8,
          offset: const Offset(0, 3),
        )
      ],
    );
  }
}
