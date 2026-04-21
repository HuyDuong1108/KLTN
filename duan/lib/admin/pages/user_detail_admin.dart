import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class UserDetailAdminPage extends StatelessWidget {
  final String uid;

  const UserDetailAdminPage({super.key, required this.uid});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: const Text(
          "User Detail",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection("users")
            .doc(uid)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.data!.exists) {
            return const Center(child: Text("User not found"));
          }

          final user = snap.data!.data() as Map<String, dynamic>;

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _header(context, user),
              const SizedBox(height: 20),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(flex: 2, child: _profileInfo(user)),
                  const SizedBox(width: 20),
                  Expanded(child: _adminActions(context, user)),
                ],
              ),
              const SizedBox(height: 20),
              _latestTestCard(),
              const SizedBox(height: 20),
              _userFlashcardsCard(),
            ],
          );
        },
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _header(BuildContext context, Map<String, dynamic> u) {
    final name = u["name"] ?? "Unknown";
    final role = (u["role"] ?? "user").toString();
    final banned = u["banned"] == true;

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF4FC3F7), Color(0xFF7C4DFF)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.toString().isNotEmpty
                    ? name.toString()[0].toUpperCase()
                    : "?",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  "UID: $uid",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    _roleBadge(role),
                    if (banned) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.red.shade700,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.block, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text(
                              "BANNED",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleBadge(String role) {
    Color bg;
    switch (role) {
      case "admin":
        bg = Colors.deepPurple;
        break;
      case "premium":
        bg = Colors.amber.shade700;
        break;
      default:
        bg = Colors.white.withOpacity(0.22);
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        role.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 11,
          fontWeight: FontWeight.bold,
          letterSpacing: 1,
        ),
      ),
    );
  }

  // ---------------- PROFILE INFO ----------------
  Widget _profileInfo(Map<String, dynamic> u) {
    return _card(
      title: "Profile",
      child: Column(
        children: [
          _infoRow(Icons.person_outline, "Name", u["name"] ?? "-"),
          _infoRow(Icons.wc, "Gender", u["gender"] ?? "-"),
          _infoRow(
            Icons.calendar_today_outlined,
            "Birthdate",
            u["birthdate"] ?? "-",
          ),
          _infoRow(
            Icons.event_available_outlined,
            "Joined",
            _formatDate(u["createdAt"]),
          ),
        ],
      ),
    );
  }

  String _formatDate(dynamic v) {
    if (v is Timestamp) {
      final d = v.toDate();
      return "${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}";
    }
    return "-";
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: Text(
              value.toString(),
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- ADMIN ACTIONS ----------------
  Widget _adminActions(BuildContext context, Map<String, dynamic> u) {
    final currentRole = (u["role"] ?? "user").toString();
    final banned = u["banned"] == true;

    return _card(
      title: "Admin Actions",
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            "Change Role",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: ["user", "premium", "admin"].contains(currentRole)
                ? currentRole
                : "user",
            decoration: InputDecoration(
              filled: true,
              fillColor: const Color(0xffF5F7FA),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 10,
              ),
            ),
            items: const [
              DropdownMenuItem(value: "user", child: Text("User")),
              DropdownMenuItem(value: "premium", child: Text("Premium")),
              DropdownMenuItem(value: "admin", child: Text("Admin")),
            ],
            onChanged: (v) async {
              if (v == null || v == currentRole) return;
              await FirebaseFirestore.instance
                  .collection("users")
                  .doc(uid)
                  .update({"role": v});
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text("Role updated to $v")),
              );
            },
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              icon: Icon(
                banned ? Icons.lock_open : Icons.block,
                color: Colors.white,
              ),
              label: Text(
                banned ? "Unban User" : "Ban User",
                style: const TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: banned ? Colors.green : Colors.red,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => _confirmBan(context, banned),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmBan(BuildContext context, bool isCurrentlyBanned) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: Text(isCurrentlyBanned ? "Unban user?" : "Ban user?"),
        content: Text(
          isCurrentlyBanned
              ? "This user will regain access to the app."
              : "This user will be marked as banned and should be blocked on login.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: isCurrentlyBanned ? Colors.green : Colors.red,
            ),
            onPressed: () async {
              await FirebaseFirestore.instance
                  .collection("users")
                  .doc(uid)
                  .update({"banned": !isCurrentlyBanned});
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
            },
            child: Text(
              isCurrentlyBanned ? "Unban" : "Ban",
              style: const TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- LATEST TEST ----------------
  Widget _latestTestCard() {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance
          .collection("users")
          .doc(uid)
          .collection("latestTest")
          .doc("result")
          .get(),
      builder: (context, snap) {
        Widget body;
        if (!snap.hasData || !snap.data!.exists) {
          body = Padding(
            padding: const EdgeInsets.symmetric(vertical: 18),
            child: Text(
              "No tests submitted yet",
              style: TextStyle(color: Colors.grey.shade600),
            ),
          );
        } else {
          final d = snap.data!.data() as Map<String, dynamic>;
          final type = d["testType"] ?? "-";
          final testId = d["testId"] ?? "-";
          final band = (d["band"] ?? 0).toString();
          final correct = d["correct"];
          final incorrect = d["incorrect"];
          final submitted = _formatDate(d["submittedAt"]);

          body = Row(
            children: [
              _latestStat("Test", "$type • $testId", Icons.quiz_rounded,
                  const Color(0xFF4FC3F7)),
              _latestStat(
                "Band",
                band,
                Icons.star_rounded,
                const Color(0xFFFFB74D),
              ),
              if (correct != null)
                _latestStat(
                  "Score",
                  "$correct / ${(correct as num) + (incorrect as num? ?? 0)}",
                  Icons.check_circle_outline,
                  const Color(0xFF81C784),
                ),
              _latestStat(
                "Submitted",
                submitted,
                Icons.schedule,
                const Color(0xFFBA68C8),
              ),
            ],
          );
        }

        return _card(title: "Latest Test Result", child: body);
      },
    );
  }

  Widget _latestStat(String label, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 12),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                color: Colors.grey.shade600,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------- USER FLASHCARDS ----------------
  Widget _userFlashcardsCard() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("flashcards")
          .doc(uid)
          .collection("userFlashcards")
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];

        return _card(
          title: "Flashcard Sets (${docs.length})",
          child: docs.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: 18),
                  child: Text(
                    "No personal flashcards",
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                )
              : Column(
                  children: docs.map((doc) {
                    final d = doc.data() as Map<String, dynamic>;
                    final title = d["title"] ?? "(no title)";
                    final vocab = (d["vocabList"] as List?)?.length ?? 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: const Color(0xFF81C784).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(
                              Icons.style_rounded,
                              color: Color(0xFF43A047),
                              size: 18,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  "$vocab words",
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
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

  Widget _card({required String title, required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
}
