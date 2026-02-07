import 'package:flutter/material.dart';

class FlashcardStudyResultPage extends StatelessWidget {
  final String setTitle;
  final int totalCards;
  final int again;
  final int hard;
  final int good;
  final int easy;


  final WidgetBuilder? retryBuilder;

  const FlashcardStudyResultPage({
    super.key,
    required this.setTitle,
    required this.totalCards,
    required this.again,
    required this.hard,
    required this.good,
    required this.easy,
    this.retryBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final totalRated = again + hard + good + easy;

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade400,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Kết quả ôn tập',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: _ResultCard(
                          icon: Icons.auto_stories_rounded,
                          title: 'Hoàn thành ôn tập!',
                          subtitle: setTitle,
                          children: [
                            _InfoBox(
                              title: 'Tổng thẻ đã chấm: $totalRated / $totalCards',
                              child: Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: [
                                  _ChipStat(label: 'Again', value: again),
                                  _ChipStat(label: 'Hard', value: hard),
                                  _ChipStat(label: 'Good', value: good),
                                  _ChipStat(label: 'Easy', value: easy),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    _BottomButtons(
                      leftText: 'Về bộ thẻ',
                      rightText: 'Ôn lại ngay',
                      onLeft: () => Navigator.pop(context),
                      onRight: retryBuilder == null
                          ? null
                          : () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: retryBuilder!),
                              );
                            },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class QuizResultPage extends StatelessWidget {
  final String setTitle;
  final int score;
  final int total;
  final List<String> needReviewLines;
  final WidgetBuilder? retryBuilder;

  const QuizResultPage({
    super.key,
    required this.setTitle,
    required this.score,
    required this.total,
    required this.needReviewLines,
    this.retryBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0 : ((score / total) * 100).round();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade400,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Kết quả kiểm tra',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: _ResultCard(
                          icon: Icons.emoji_events_outlined,
                          title: 'Hoàn thành bài kiểm tra!',
                          subtitle: setTitle,
                          children: [
                            const SizedBox(height: 6),
                            Text(
                              '$score / $total',
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '$percent%',
                              style: TextStyle(
                                fontSize: 16,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (needReviewLines.isNotEmpty)
                              _InfoBox(
                                title: 'Cần xem lại:',
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: needReviewLines
                                      .take(6)
                                      .map(
                                        (line) => Padding(
                                          padding: const EdgeInsets.only(bottom: 6),
                                          child: Text('• $line'),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    _BottomButtons(
                      leftText: 'Về bộ thẻ',
                      rightText: 'Làm lại',
                      onLeft: () => Navigator.pop(context),
                      onRight: retryBuilder == null
                          ? null
                          : () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: retryBuilder!),
                              );
                            },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TypingResultPage extends StatelessWidget {
  final String setTitle;
  final int correct;
  final int total;
  final List<String> needPracticeLines;
  final WidgetBuilder? retryBuilder;

  const TypingResultPage({
    super.key,
    required this.setTitle,
    required this.correct,
    required this.total,
    required this.needPracticeLines,
    this.retryBuilder,
  });

  @override
  Widget build(BuildContext context) {
    final percent = total == 0 ? 0 : ((correct / total) * 100).round();

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        backgroundColor: Colors.blue.shade400,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
        title: const Text(
          'Kết quả gõ từ',
          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black),
        ),
      ),
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverFillRemaining(
              hasScrollBody: false,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Center(
                      child: ConstrainedBox(
                        constraints: const BoxConstraints(maxWidth: 520),
                        child: _ResultCard(
                          icon: Icons.keyboard_alt_outlined,
                          title: 'Hoàn thành bài gõ từ!',
                          subtitle: setTitle,
                          children: [
                            const SizedBox(height: 6),
                            Text(
                              '$percent%',
                              style: const TextStyle(
                                fontSize: 40,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              'Chính xác: $correct / $total',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey.shade700,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            if (needPracticeLines.isNotEmpty)
                              _InfoBox(
                                title: 'Cần luyện thêm:',
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: needPracticeLines
                                      .take(8)
                                      .map(
                                        (line) => Padding(
                                          padding: const EdgeInsets.only(bottom: 6),
                                          child: Text('• $line'),
                                        ),
                                      )
                                      .toList(),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const Spacer(),
                    _BottomButtons(
                      leftText: 'Về bộ thẻ',
                      rightText: 'Luyện lại',
                      onLeft: () => Navigator.pop(context),
                      onRight: retryBuilder == null
                          ? null
                          : () {
                              Navigator.pushReplacement(
                                context,
                                MaterialPageRoute(builder: retryBuilder!),
                              );
                            },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),

    );
  }
}

/// ---------- Shared UI ----------

class _ResultCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final List<Widget> children;

  const _ResultCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 34, color: Colors.black87),
          const SizedBox(height: 10),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final String title;
  final Widget child;

  const _InfoBox({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _ChipStat extends StatelessWidget {
  final String label;
  final int value;

  const _ChipStat({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.blue.shade200),
        color: Colors.blue.shade50,
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(fontWeight: FontWeight.w800),
      ),
    );
  }
}

class _BottomButtons extends StatelessWidget {
  final String leftText;
  final String rightText;
  final VoidCallback onLeft;
  final VoidCallback? onRight;

  const _BottomButtons({
    required this.leftText,
    required this.rightText,
    required this.onLeft,
    required this.onRight,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: SizedBox(
            height: 50,
            child: OutlinedButton(
              onPressed: onLeft,
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.blue.shade700,
                side: BorderSide(color: Colors.blue.shade300, width: 1.2),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(leftText, style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 50,
            child: ElevatedButton(
              onPressed: onRight,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue.shade400,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(rightText, style: const TextStyle(fontWeight: FontWeight.w900)),
            ),
          ),
        ),
      ],
    );
  }
}
