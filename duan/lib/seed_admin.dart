// CHẠY 1 LẦN để tạo tài khoản admin mặc định.
// Cách chạy: `flutter run -t lib/seed_admin.dart`
// Xong có thể xoá file này.

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firebase_options.dart';

const _email = "admin@gmail.com";
const _password = "123456";
const _name = "Admin";

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final result = await _seedAdmin();

  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    home: Scaffold(
      backgroundColor: const Color(0xffF4F8FB),
      body: Center(
        child: Container(
          width: 460,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                result.success
                    ? Icons.check_circle
                    : Icons.error_outline,
                color: result.success ? Colors.green : Colors.red,
                size: 56,
              ),
              const SizedBox(height: 16),
              Text(
                result.success
                    ? "Admin account ready"
                    : "Seed failed",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                result.message,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black87, height: 1.4),
              ),
              const SizedBox(height: 18),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xffF4F8FB),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Column(
                  children: [
                    Text("Email: admin@gmail.com",
                        style: TextStyle(fontFamily: "monospace")),
                    SizedBox(height: 4),
                    Text("Password: 123456",
                        style: TextStyle(fontFamily: "monospace")),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ));
}

class _Result {
  final bool success;
  final String message;
  _Result(this.success, this.message);
}

Future<_Result> _seedAdmin() async {
  final auth = FirebaseAuth.instance;
  final fs = FirebaseFirestore.instance;

  String uid;
  try {
    final cred = await auth.createUserWithEmailAndPassword(
      email: _email,
      password: _password,
    );
    uid = cred.user!.uid;
    debugPrint("✅ Created auth account $uid");
  } on FirebaseAuthException catch (e) {
    if (e.code == "email-already-in-use") {
      // Account đã tồn tại → sign in để lấy uid rồi nâng role
      try {
        final cred = await auth.signInWithEmailAndPassword(
          email: _email,
          password: _password,
        );
        uid = cred.user!.uid;
        debugPrint("ℹ️  Account đã tồn tại, uid=$uid");
      } on FirebaseAuthException catch (e2) {
        return _Result(
          false,
          "Account đã tồn tại nhưng password khác.\n"
          "Hãy đổi lại `_password` trong seed_admin.dart cho khớp với password hiện tại "
          "của admin@gmail.com, hoặc xoá tài khoản trong Firebase Console → Authentication rồi chạy lại.\n\n"
          "Error: ${e2.code}",
        );
      }
    } else {
      return _Result(false, "Auth error: ${e.code} — ${e.message}");
    }
  }

  // Tạo / cập nhật Firestore user doc với role=admin
  await fs.collection("users").doc(uid).set({
    "name": _name,
    "gender": "Other",
    "birthdate": "",
    "role": "admin",
    "banned": false,
    "createdAt": FieldValue.serverTimestamp(),
  }, SetOptions(merge: true));

  debugPrint("✅ Firestore users/$uid.role = admin");

  return _Result(
    true,
    "Account admin@gmail.com đã sẵn sàng.\nBạn có thể quay lại app chính và đăng nhập.",
  );
}
