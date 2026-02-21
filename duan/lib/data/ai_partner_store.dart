import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/ai_partner_session.dart';
import '../models/ai_partner_profile.dart';
import '../models/conversation_turn.dart';

class AiPartnerStore {
  AiPartnerStore._();
  static final instance = AiPartnerStore._();

  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  // ─────────────────────────────────────────────────────────────
  // Internal helpers
  // ─────────────────────────────────────────────────────────────
  String get _uid {
    final uid = _auth.currentUser?.uid;
    if (uid == null) throw Exception('User not authenticated');
    return uid;
  }

  CollectionReference get _sessions =>
      _db.collection('users').doc(_uid).collection('ai_partner_sessions');

  DocumentReference get _profileDoc => _db
      .collection('users')
      .doc(_uid)
      .collection('ai_partner_profile')
      .doc('summary');

  DocumentReference get _stateDoc => _db
      .collection('users')
      .doc(_uid)
      .collection('ai_partner_state')
      .doc('current');

  // ─────────────────────────────────────────────────────────────
  // Sessions
  // ─────────────────────────────────────────────────────────────
  Future<String> saveSession(AiPartnerSession session) async {
    final ref = await _sessions.add(session.toFirestore());
    return ref.id;
  }

  Stream<List<AiPartnerSession>> watchSessions({int limit = 50}) {
    return _sessions
        .orderBy('startedAtMs', descending: true)
        .limit(limit)
        .snapshots()
        .map(
          (snap) =>
              snap.docs.map((d) => AiPartnerSession.fromFirestore(d)).toList(),
        );
  }

  Future<List<AiPartnerSession>> getSessions({int limit = 20}) async {
    final snap = await _sessions
        .orderBy('startedAtMs', descending: true)
        .limit(limit)
        .get();
    return snap.docs.map((d) => AiPartnerSession.fromFirestore(d)).toList();
  }

  // ─────────────────────────────────────────────────────────────
  // Conversation state (resume support)
  // ─────────────────────────────────────────────────────────────
  Future<void> saveConversationState(Map<String, dynamic> state) async {
    await _stateDoc.set({...state, 'savedAt': FieldValue.serverTimestamp()});
  }

  Future<Map<String, dynamic>?> loadConversationState() async {
    final snap = await _stateDoc.get();
    if (!snap.exists) return null;
    final data = snap.data() as Map<String, dynamic>?;
    if (data == null) return null;
    // Expire state older than 2 hours
    final savedAt = data['savedAt'];
    if (savedAt is! Timestamp) return null;
    final age = DateTime.now().difference(savedAt.toDate());
    if (age.inHours >= 2) {
      await clearConversationState();
      return null;
    }
    return data;
  }

  Future<void> clearConversationState() async {
    await _stateDoc.delete();
  }

  // ─────────────────────────────────────────────────────────────
  // User profile
  // ─────────────────────────────────────────────────────────────
  Future<AiPartnerProfile> getUserProfile() async {
    final snap = await _profileDoc.get();
    if (!snap.exists) return AiPartnerProfile.empty();
    return AiPartnerProfile.fromFirestore(snap);
  }

  Future<void> saveProfile(AiPartnerProfile profile) async {
    await _profileDoc.set(profile.toFirestore());
  }

  /// Called after each completed session.
  /// - Accumulates observations into pendingChanges.
  /// - When a change hits threshold (3 occurrences), promotes to confirmed profile.
  /// Returns the updated profile (already saved).
  Future<AiPartnerProfile> updateProfileWithObservations({
    required List<String> newStrengths,
    required List<String> newWeaknesses,
    required double fluency,
    required double lexical,
    required double grammar,
    required double pronunciation,
  }) async {
    const int promoteThreshold = 3;

    return await _db.runTransaction<AiPartnerProfile>((txn) async {
      final snap = await txn.get(_profileDoc);
      AiPartnerProfile profile = snap.exists
          ? AiPartnerProfile.fromFirestore(snap)
          : AiPartnerProfile.empty();

      // ── Running average for band levels ──
      final count = profile.sessionCount + 1;
      final newFluency = _runningAvg(
        profile.fluencyLevel,
        fluency,
        profile.sessionCount,
      );
      final newLexical = _runningAvg(
        profile.lexicalLevel,
        lexical,
        profile.sessionCount,
      );
      final newGrammar = _runningAvg(
        profile.grammarLevel,
        grammar,
        profile.sessionCount,
      );
      final newPronunciation = _runningAvg(
        profile.pronunciationLevel,
        pronunciation,
        profile.sessionCount,
      );

      // ── Accumulate pending changes ──
      final pending = Map<String, PendingChange>.from(profile.pendingChanges);

      void _accumulatePending(String key, String value) {
        if (pending.containsKey(key)) {
          pending[key] = pending[key]!.copyWith(
            occurrenceCount: pending[key]!.occurrenceCount + 1,
            lastSeen: DateTime.now(),
          );
        } else {
          pending[key] = PendingChange(
            value: value,
            occurrenceCount: 1,
            lastSeen: DateTime.now(),
          );
        }
      }

      for (final s in newStrengths) {
        _accumulatePending(
          'strength_${s.toLowerCase().replaceAll(' ', '_')}',
          s,
        );
      }
      for (final w in newWeaknesses) {
        _accumulatePending(
          'weakness_${w.toLowerCase().replaceAll(' ', '_')}',
          w,
        );
      }

      // ── Promote pending → confirmed once threshold reached ──
      final confirmedStrengths = List<String>.from(profile.strengths);
      final confirmedWeaknesses = List<String>.from(profile.weaknesses);
      final promoted = <String>[];

      pending.forEach((key, change) {
        if (change.occurrenceCount >= promoteThreshold) {
          if (key.startsWith('strength_')) {
            if (!confirmedStrengths.contains(change.value)) {
              confirmedStrengths.add(change.value);
            }
          } else if (key.startsWith('weakness_')) {
            if (!confirmedWeaknesses.contains(change.value)) {
              confirmedWeaknesses.add(change.value);
            }
          }
          promoted.add(key);
        }
      });

      // Remove promoted keys from pending
      for (final k in promoted) {
        pending.remove(k);
      }

      // Keep lists trimmed (max 5 each)
      final trimStrengths = confirmedStrengths.take(5).toList();
      final trimWeaknesses = confirmedWeaknesses.take(5).toList();

      // ── Rebuild profile summary ──
      final summary = _buildSummary(
        fluency: newFluency,
        lexical: newLexical,
        grammar: newGrammar,
        pronunciation: newPronunciation,
        strengths: trimStrengths,
        weaknesses: trimWeaknesses,
        sessionCount: count,
      );

      final updated = profile.copyWith(
        strengths: trimStrengths,
        weaknesses: trimWeaknesses,
        fluencyLevel: newFluency,
        lexicalLevel: newLexical,
        grammarLevel: newGrammar,
        pronunciationLevel: newPronunciation,
        profileSummary: summary,
        sessionCount: count,
        pendingChanges: pending,
      );

      txn.set(_profileDoc, updated.toFirestore());
      return updated;
    });
  }

  // ─────────────────────────────────────────────────────────────
  // Private helpers
  // ─────────────────────────────────────────────────────────────
  double _runningAvg(double oldAvg, double newVal, int oldCount) {
    if (oldCount == 0) return newVal;
    return (oldAvg * oldCount + newVal) / (oldCount + 1);
  }

  String _buildSummary({
    required double fluency,
    required double lexical,
    required double grammar,
    required double pronunciation,
    required List<String> strengths,
    required List<String> weaknesses,
    required int sessionCount,
  }) {
    final overallAvg = (fluency + lexical + grammar + pronunciation) / 4;
    final buf = StringBuffer();
    buf.write(
      'After $sessionCount session(s), overall band ~${overallAvg.toStringAsFixed(1)}. ',
    );
    if (strengths.isNotEmpty) {
      buf.write('Strengths: ${strengths.take(3).join(', ')}. ');
    }
    if (weaknesses.isNotEmpty) {
      buf.write('Key areas to improve: ${weaknesses.take(3).join(', ')}.');
    }
    return buf.toString();
  }
}
