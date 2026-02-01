import 'package:firebase_auth/firebase_auth.dart';

class ApiHeaders {
  static Map<String, String> standard({FirebaseAuth? auth}) {
    final firebaseAuth = auth ?? FirebaseAuth.instance;
    final uid = firebaseAuth.currentUser?.uid;

    if (uid == null || uid.trim().isEmpty) {
      throw StateError('Missing user uid. Sign-in required before calling backend.');
    }

    return <String, String>{
      'Content-Type': 'application/json',
      'X-User-Id': uid,
    };
  }
}
