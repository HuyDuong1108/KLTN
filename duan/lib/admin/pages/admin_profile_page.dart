import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class AdminProfilePage extends StatefulWidget {
  const AdminProfilePage({super.key});

  @override
  State<AdminProfilePage> createState() => _AdminProfilePageState();
}

class _AdminProfilePageState extends State<AdminProfilePage> {
  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("Not signed in")),
      );
    }

    return Container(
      color: const Color(0xffF4F8FB),
      child: ListView(
        padding: const EdgeInsets.all(24),
        children: [

          const Text(
            "My Profile",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          Text(
            "Manage your admin account settings.",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),

          const SizedBox(height: 28),

          StreamBuilder<DocumentSnapshot>(
            stream: FirebaseFirestore.instance
                .collection("users")
                .doc(user.uid)
                .snapshots(),
            builder: (context, snap) {
              final data = (snap.data?.data() as Map<String, dynamic>?) ?? {};
              final name = data["name"] ?? "Admin";

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _headerCard(user, name),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: _editProfileCard(user, name),
                      ),
                      const SizedBox(width: 20),
                      Expanded(
                        child: _changePasswordCard(user),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  _accountInfoCard(user, data),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ============================================================
  // HEADER
  // ============================================================
  Widget _headerCard(User user, String name) {
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
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : "A",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
          const SizedBox(width: 22),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  user.email ?? "",
                  style: const TextStyle(color: Colors.white70, fontSize: 14),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.verified_user,
                        color: Colors.white,
                        size: 12,
                      ),
                      SizedBox(width: 4),
                      Text(
                        "ADMIN",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // EDIT PROFILE
  // ============================================================
  Widget _editProfileCard(User user, String currentName) {
    final nameCtl = TextEditingController(text: currentName);

    return _card(
      title: "Edit Profile",
      icon: Icons.person_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: nameCtl,
            decoration: _inputDecoration("Display name", Icons.badge_outlined),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.save, color: Colors.white),
              label: const Text(
                "Save Changes",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4FC3F7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () async {
                final newName = nameCtl.text.trim();
                if (newName.isEmpty) return;
                await FirebaseFirestore.instance
                    .collection("users")
                    .doc(user.uid)
                    .update({"name": newName});
                if (!mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Profile updated"),
                    backgroundColor: Colors.green,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // CHANGE PASSWORD
  // ============================================================
  Widget _changePasswordCard(User user) {
    final currentCtl = TextEditingController();
    final newCtl = TextEditingController();
    final confirmCtl = TextEditingController();

    return _card(
      title: "Change Password",
      icon: Icons.lock_outline,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TextField(
            controller: currentCtl,
            obscureText: true,
            decoration:
                _inputDecoration("Current password", Icons.lock_clock_outlined),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: newCtl,
            obscureText: true,
            decoration: _inputDecoration("New password", Icons.lock_outline),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: confirmCtl,
            obscureText: true,
            decoration:
                _inputDecoration("Confirm new password", Icons.lock_outline),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 44,
            child: ElevatedButton.icon(
              icon: const Icon(Icons.check_circle, color: Colors.white),
              label: const Text(
                "Update Password",
                style: TextStyle(color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF7C4DFF),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () => _changePassword(
                user,
                currentCtl.text,
                newCtl.text,
                confirmCtl.text,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _changePassword(
    User user,
    String current,
    String newPass,
    String confirm,
  ) async {
    if (newPass.length < 6) {
      _snack("Password must be at least 6 characters", Colors.red);
      return;
    }
    if (newPass != confirm) {
      _snack("Passwords do not match", Colors.red);
      return;
    }

    try {
      final cred = EmailAuthProvider.credential(
        email: user.email ?? "",
        password: current,
      );
      await user.reauthenticateWithCredential(cred);
      await user.updatePassword(newPass);
      if (!mounted) return;
      _snack("Password updated successfully", Colors.green);
    } on FirebaseAuthException catch (e) {
      String msg = e.message ?? "Unknown error";
      if (e.code == "wrong-password" || e.code == "invalid-credential") {
        msg = "Current password is incorrect.";
      }
      _snack(msg, Colors.red);
    } catch (e) {
      _snack("Error: $e", Colors.red);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: color),
    );
  }

  // ============================================================
  // ACCOUNT INFO
  // ============================================================
  Widget _accountInfoCard(User user, Map<String, dynamic> data) {
    return _card(
      title: "Account Information",
      icon: Icons.info_outline,
      child: Column(
        children: [
          _infoRow("Email", user.email ?? "-", Icons.email_outlined),
          _infoRow(
            "UID",
            user.uid,
            Icons.fingerprint,
            mono: true,
          ),
          _infoRow(
            "Role",
            (data["role"] ?? "-").toString().toUpperCase(),
            Icons.verified_user_outlined,
          ),
          _infoRow(
            "Email verified",
            user.emailVerified ? "Yes" : "No",
            user.emailVerified ? Icons.check_circle : Icons.cancel,
          ),
          _infoRow(
            "Account created",
            _formatTime(user.metadata.creationTime),
            Icons.event_outlined,
          ),
          _infoRow(
            "Last sign-in",
            _formatTime(user.metadata.lastSignInTime),
            Icons.login,
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value, IconData icon,
      {bool mono = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 12),
          SizedBox(
            width: 150,
            child: Text(
              label,
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: mono ? 12 : 14,
                fontFamily: mono ? "monospace" : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime? t) {
    if (t == null) return "-";
    return "${t.day.toString().padLeft(2, '0')}/${t.month.toString().padLeft(2, '0')}/${t.year} "
        "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}";
  }

  // ============================================================
  // COMMON
  // ============================================================
  Widget _card({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: const Color(0xFF4FC3F7)),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }

  InputDecoration _inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
      filled: true,
      fillColor: const Color(0xffF5F7FA),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }
}
