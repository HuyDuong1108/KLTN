import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
// bổ sung thêm 
import '../../data/stats_api.dart';
import '../../models/stats_summary.dart';
import 'statistics/statistics_detail_page.dart';

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
                  _achievements(),
                  const SizedBox(height: 20),
                  _languages(),
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
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
                    onPressed: () {},
                    child: const Text("Edit Profile", style: TextStyle(color: Colors.white)),
                  ),
                )
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
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const StatisticsDetailPage()),
    );
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
        )
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

  // ----------------------------------------------------------
  // 🏆 ACHIEVEMENTS
  // ----------------------------------------------------------
  Widget _achievements() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Achievements", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _achievementIcon("🔥", "7-Day Streak"),
              _achievementIcon("⚡", "Fast Learner"),
              _achievementIcon("💎", "Perfect Score"),
              _achievementIcon("🏅", "Silver Badge"),
            ],
          )
        ],
      ),
    );
  }

  Widget _achievementIcon(String emoji, String label) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 32)),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 13)),
      ],
    );
  }

  // ----------------------------------------------------------
  // 🌍 LANGUAGE PROGRESS (đang hardcode, chưa nối backend)
  // ----------------------------------------------------------
  Widget _languages() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: _boxDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("My Languages", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),

          _languageItem(
            flag: "🇯🇵",
            name: "Japanese",
            level: 4,
            progress: 0.72,
            words: 350,
            gradient: [Colors.red, Colors.pinkAccent],
          ),
          const SizedBox(height: 22),

          _languageItem(
            flag: "🇰🇷",
            name: "Korean",
            level: 3,
            progress: 0.45,
            words: 210,
            gradient: [Colors.blue, Colors.lightBlueAccent],
          ),
          const SizedBox(height: 22),

          _languageItem(
            flag: "🇨🇳",
            name: "Chinese",
            level: 2,
            words: 150,
            progress: 0.30,
            gradient: [Colors.orange, Colors.deepOrangeAccent],
          ),
        ],
      ),
    );
  }

  Widget _languageItem({
    required String flag,
    required String name,
    required int level,
    required double progress,
    required int words,
    required List<Color> gradient,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(0.12),
            blurRadius: 12,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        children: [
          Text(flag, style: const TextStyle(fontSize: 40)),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "$name  •  Level $level",
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    height: 10,
                    decoration: BoxDecoration(gradient: LinearGradient(colors: gradient)),
                    width: progress * 200,
                  ),
                ),
                const SizedBox(height: 6),
                Text("$words words learned", style: TextStyle(color: Colors.grey.shade600)),
              ],
            ),
          )
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
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w700,
        ),
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
        )
      ],
    );
  }
}