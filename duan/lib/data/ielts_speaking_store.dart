import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ielts_speaking_session.dart';

class IeltsSpeakingStore {
  IeltsSpeakingStore._();
  static final instance = IeltsSpeakingStore._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');
    return uid;
  }

  CollectionReference get _sessions =>
      _db.collection('users').doc(_uid).collection('ielts_test_sessions');

  // ─────────────────────────────────────────────────────────────
  // Save
  // ─────────────────────────────────────────────────────────────
  Future<String> saveSession(IeltsSpeakingSession session) async {
    final ref = await _sessions.add(session.toFirestore());
    return ref.id;
  }

  // ─────────────────────────────────────────────────────────────
  // Real-time stream
  // ─────────────────────────────────────────────────────────────
  Stream<List<IeltsSpeakingSession>> watchSessions({int limit = 50}) {
    return _sessions
        .orderBy('startedAtMs', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) => snap.docs
              .map((d) => IeltsSpeakingSession.fromFirestore(d))
              .toList(),
        );
  }

  // ─────────────────────────────────────────────────────────────
  // One-time fetch
  // ─────────────────────────────────────────────────────────────
  Future<List<IeltsSpeakingSession>> getSessions({int limit = 20}) async {
    final snap = await _sessions
        .orderBy('startedAtMs', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => IeltsSpeakingSession.fromFirestore(d)).toList();
  }
}
