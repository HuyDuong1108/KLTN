import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// bổ sung thêm
import '../../data/stats_api.dart';
import '../../models/stats_summary.dart';
import 'statistics/statistics_detail_page.dart';
import 'edit_profile_page.dart';

// update ProfilePage thành StatefulWidget
class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late Future<StatsSummary> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = StatsApi.instance.fetchSummary();
  }

  Future<void> _refresh() async {
    setState(() {
      _statsFuture = StatsApi.instance.fetchSummary();
    });
    await _statsFuture;
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Color(0xFFF3F9FF),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: FutureBuilder<StatsSummary>(
          future: _statsFuture,
          builder: (context, snapshot) {
            final stats = snapshot.data; // có thể null khi loading/error

            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _profileCard(user),
                  const SizedBox(height: 20),

                  // ✅ stats từ backend
                  _learningStatistics(stats, error: snapshot.hasError),

                  const SizedBox(height: 20),
                  _achievements(stats),
                  const SizedBox(height: 20),
                  _skillProgress(),
                  const SizedBox(height: 20),
                  _logoutButton(context),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ---------------------------
  // helpers format
  // ---------------------------
  String _fmtInt(int n) {
    final s = n.toString();
    return s.replaceAllMapped(
      RegExp(r'(\d)(?=(\d{3})+(?!\d))'),
      (m) => '${m[1]},',
    );
  }

  String _pct(double v) => '${(v * 100).round()}%';

  // ----------------------------------------------------------
  // 🟦 PROFILE CARD
  // ----------------------------------------------------------
  Widget _profileCard(User? user) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _boxDecoration(),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(50),
            child: Image.asset(
              "lib/image/dung.png",
              width: 70,
              height: 70,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(width: 16),

          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user?.email?.split('@')[0] ?? "User Name",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user?.email ?? "No Email",
                  style: TextStyle(color: Colors.grey[600]),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  height: 32,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      final user = FirebaseAuth.instance.currentUser;
                      if (user != null) {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => EditProfilePage(uid: user.uid),
                          ),
                        );
                      }
                    },
                    child: const Text(
                      "Edit Profile",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // 📊 LEARNING STATISTICS (✅ lấy backend)
  // ----------------------------------------------------------
  Widget _learningStatistics(StatsSummary? stats, {required bool error}) {
    // fallback khi loading/error
    final days = stats?.daysActiveTotal;
    final streak = stats?.streakCurrent;
    final xp = stats?.xpTotal;
    final successAll = stats?.successRateAllTime;

    final daysText = days == null ? "— Days" : "${days} Days";
    final streakText = streak == null ? "—-Day Streak" : "${streak}-Day Streak";
    final xpText = xp == null ? "— XP" : "${_fmtInt(xp)} XP";
    final successText = successAll == null ? "—%" : _pct(successAll);

    return InkWell(
      borderRadius: BorderRadius.circular(18),
      onTap: () {
        Navigator.of(
          context,
        ).push(MaterialPageRoute(builder: (_) => const StatisticsDetailPage()));
      },
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: _boxDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Learning Statistics",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),

            if (error)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Text(
                  "Không tải được thống kê (kéo xuống để refresh).",
                  style: TextStyle(color: Colors.red.shade400),
                ),
              ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _statItem(Icons.calendar_month, daysText),
                _statItem(Icons.local_fire_department, streakText),
                _statItem(Icons.star, xpText),
                _statItem(Icons.check_circle, successText),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statItem(IconData icon, String value) {
    return Column(
      children: [
        Icon(icon, color: Colors.blue, size: 28),
        const SizedBox(height: 4),
        Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _achievements(StatsSummary? stats) {
    final streak = stats?.streakCurrent ?? 0;
    final xp = stats?.xpTotal ?? 0;
    final success = stats?.successRateAllTime ?? 0.0;
    final days = stats?.daysActiveTotal ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Achievements",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _achievementItem(
                emoji: "🔥",
                label: "7-Day Streak",
                unlocked: streak >= 7,
                activeColor: Colors.orange,
                description:
                    "Maintain a learning streak for 7 consecutive days.",
                requirement: "Reach 7-day streak",
                current: streak.toDouble(),
                target: 7,
              ),
              _achievementItem(
                emoji: "⚡",
                label: "Fast Learner",
                unlocked: xp >= 1000,
                activeColor: Colors.blue,
                description: "Earn 1000 XP from practice activities.",
                requirement: "Reach 1000 XP",
                current: xp.toDouble(),
                target: 1000,
              ),
              _achievementItem(
                emoji: "💎",
                label: "Perfect Score",
                unlocked: success >= 0.9,
                activeColor: Colors.purple,
                description: "Achieve 90%+ overall success rate.",
                requirement: "Reach 90% accuracy",
                current: success * 100,
                target: 90,
              ),
              _achievementItem(
                emoji: "🏅",
                label: "Silver Badge",
                unlocked: days >= 30,
                activeColor: Colors.amber,
                description: "Stay active for 30 learning days.",
                requirement: "Reach 30 active days",
                current: days.toDouble(),
                target: 30,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _achievementItem({
    required String emoji,
    required String label,
    required bool unlocked,
    required Color activeColor,
    required String description,
    required String requirement,
    required double current,
    required double target,
  }) {
    final color = unlocked ? activeColor : Colors.grey.shade400;

    return GestureDetector(
      onTap: () {
        _showAchievementDetail(
          emoji: emoji,
          title: label,
          unlocked: unlocked,
          activeColor: activeColor,
          description: description,
          requirement: requirement,
          current: current,
          target: target,
        );
      },
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: unlocked
                  ? activeColor.withOpacity(0.15)
                  : Colors.grey.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Text(emoji, style: TextStyle(fontSize: 28, color: color)),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAchievementDetail({
    required String emoji,
    required String title,
    required bool unlocked,
    required Color activeColor,
    required String description,
    required String requirement,
    required double current,
    required double target,
  }) {
    final progress = (current / target).clamp(0.0, 1.0);

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),

              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: unlocked
                      ? activeColor.withOpacity(0.15)
                      : Colors.grey.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Text(
                  emoji,
                  style: TextStyle(
                    fontSize: 40,
                    color: unlocked ? activeColor : Colors.grey,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                description,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF607D8B)),
              ),

              const SizedBox(height: 20),

              // ===== PROGRESS =====
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Progress: ${current.toStringAsFixed(0)} / ${target.toStringAsFixed(0)}",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 8),

              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: Colors.grey.withOpacity(0.15),
                  valueColor: AlwaysStoppedAnimation(activeColor),
                ),
              ),

              const SizedBox(height: 16),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: unlocked
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  unlocked ? "Achieved 🎉" : requirement,
                  style: TextStyle(
                    color: unlocked ? Colors.green : Colors.red,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),

              const SizedBox(height: 20),
            ],
          ),
        );
      },
    );
  }

  // ----------------------------------------------------------
  // 🎯 SKILL PROGRESS – PASTEL STYLE (MATCH LEARNING PAGE)
  // ----------------------------------------------------------
  Widget _skillProgress() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "IELTS Skill Progress",
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),

          _skillItem(
            icon: Icons.headphones,
            skill: "Listening",
            band: 6.0,
            progress: 0.7,
            color: const Color(0xFF4FC3F7),
          ),

          const SizedBox(height: 18),

          _skillItem(
            icon: Icons.menu_book,
            skill: "Reading",
            band: 6.0,
            progress: 0.75,
            color: const Color(0xFFFFB74D),
          ),

          const SizedBox(height: 18),

          _skillItem(
            icon: Icons.edit,
            skill: "Writing",
            band: 5.5,
            progress: 0.6,
            color: const Color(0xFFBA68C8),
          ),

          const SizedBox(height: 18),

          _skillItem(
            icon: Icons.record_voice_over,
            skill: "Speaking",
            band: 5.0,
            progress: 0.55,
            color: const Color(0xFF81C784),
          ),
        ],
      ),
    );
  }

  Widget _skillItem({
    required IconData icon,
    required String skill,
    required double band,
    required double progress,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.18),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 12),

              Text(
                skill,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const Spacer(),

              Text(
                "Band ${band.toStringAsFixed(1)}",
                style: TextStyle(color: color, fontWeight: FontWeight.w600),
              ),
            ],
          ),

          const SizedBox(height: 12),

          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: color.withOpacity(0.12),
              valueColor: AlwaysStoppedAnimation(color),
            ),
          ),
        ],
      ),
    );
  }

  // ----------------------------------------------------------
  // LOGOUT BUTTON
  // ----------------------------------------------------------
  Widget _logoutButton(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: OutlinedButton.icon(
        icon: const Icon(Icons.logout_rounded),
        label: const Text(
          "Log Out",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        style: OutlinedButton.styleFrom(
          foregroundColor: const Color(0xFFD32F2F), // đỏ dịu
          side: const BorderSide(
            color: Color(0xFFEF9A9A), // viền đỏ nhạt
            width: 1.5,
          ),
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        onPressed: () async {
          await FirebaseAuth.instance.signOut();
          Navigator.pop(context);
        },
      ),
    );
  }

  // ----------------------------------------------------------
  // DECORATION
  // ----------------------------------------------------------
  BoxDecoration _boxDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          spreadRadius: 2,
          blurRadius: 8,
        ),
      ],
    );
  }
}
