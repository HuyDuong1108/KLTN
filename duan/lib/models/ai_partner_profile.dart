import 'package:cloud_firestore/cloud_firestore.dart';

class PendingChange {
  final String value;
  final int occurrenceCount;
  final DateTime lastSeen;

  PendingChange({
    required this.value,
    required this.occurrenceCount,
    required this.lastSeen,
  });

  PendingChange copyWith({int? occurrenceCount, DateTime? lastSeen}) =>
      PendingChange(
        value: value,
        occurrenceCount: occurrenceCount ?? this.occurrenceCount,
        lastSeen: lastSeen ?? this.lastSeen,
      );

  factory PendingChange.fromJson(Map<String, dynamic> j) => PendingChange(
    value: j['value'] as String? ?? '',
    occurrenceCount: (j['occurrenceCount'] as num?)?.toInt() ?? 1,
    lastSeen: j['lastSeen'] is int
        ? DateTime.fromMillisecondsSinceEpoch(j['lastSeen'] as int)
        : DateTime.now(),
  );

  Map<String, dynamic> toJson() => {
    'value': value,
    'occurrenceCount': occurrenceCount,
    'lastSeen': lastSeen.millisecondsSinceEpoch,
  };
}

class AiPartnerProfile {
  final List<String> strengths;
  final List<String> weaknesses;
  final double fluencyLevel;
  final double lexicalLevel;
  final double grammarLevel;
  final double pronunciationLevel;
  final String profileSummary;
  final int sessionCount;

  /// key = feature tag (e.g. "weak_fluency", "strong_lexical")
  final Map<String, PendingChange> pendingChanges;

  AiPartnerProfile({
    required this.strengths,
    required this.weaknesses,
    required this.fluencyLevel,
    required this.lexicalLevel,
    required this.grammarLevel,
    required this.pronunciationLevel,
    required this.profileSummary,
    required this.sessionCount,
    required this.pendingChanges,
  });

  factory AiPartnerProfile.empty() => AiPartnerProfile(
    strengths: [],
    weaknesses: [],
    fluencyLevel: 0.0,
    lexicalLevel: 0.0,
    grammarLevel: 0.0,
    pronunciationLevel: 0.0,
    profileSummary: '',
    sessionCount: 0,
    pendingChanges: {},
  );

  factory AiPartnerProfile.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>? ?? {};

    final rawPending = (d['pendingChanges'] as Map<String, dynamic>? ?? {});
    final pending = rawPending.map(
      (k, v) => MapEntry(k, PendingChange.fromJson(v as Map<String, dynamic>)),
    );

    return AiPartnerProfile(
      strengths: List<String>.from(d['strengths'] as List? ?? []),
      weaknesses: List<String>.from(d['weaknesses'] as List? ?? []),
      fluencyLevel: (d['fluencyLevel'] as num?)?.toDouble() ?? 0.0,
      lexicalLevel: (d['lexicalLevel'] as num?)?.toDouble() ?? 0.0,
      grammarLevel: (d['grammarLevel'] as num?)?.toDouble() ?? 0.0,
      pronunciationLevel: (d['pronunciationLevel'] as num?)?.toDouble() ?? 0.0,
      profileSummary: d['profileSummary'] as String? ?? '',
      sessionCount: (d['sessionCount'] as num?)?.toInt() ?? 0,
      pendingChanges: pending,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'strengths': strengths,
    'weaknesses': weaknesses,
    'fluencyLevel': fluencyLevel,
    'lexicalLevel': lexicalLevel,
    'grammarLevel': grammarLevel,
    'pronunciationLevel': pronunciationLevel,
    'profileSummary': profileSummary,
    'sessionCount': sessionCount,
    'pendingChanges': pendingChanges.map((k, v) => MapEntry(k, v.toJson())),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  AiPartnerProfile copyWith({
    List<String>? strengths,
    List<String>? weaknesses,
    double? fluencyLevel,
    double? lexicalLevel,
    double? grammarLevel,
    double? pronunciationLevel,
    String? profileSummary,
    int? sessionCount,
    Map<String, PendingChange>? pendingChanges,
  }) => AiPartnerProfile(
    strengths: strengths ?? this.strengths,
    weaknesses: weaknesses ?? this.weaknesses,
    fluencyLevel: fluencyLevel ?? this.fluencyLevel,
    lexicalLevel: lexicalLevel ?? this.lexicalLevel,
    grammarLevel: grammarLevel ?? this.grammarLevel,
    pronunciationLevel: pronunciationLevel ?? this.pronunciationLevel,
    profileSummary: profileSummary ?? this.profileSummary,
    sessionCount: sessionCount ?? this.sessionCount,
    pendingChanges: pendingChanges ?? this.pendingChanges,
  );
}
