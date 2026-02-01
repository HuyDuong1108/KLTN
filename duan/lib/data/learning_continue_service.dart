import 'package:cloud_firestore/cloud_firestore.dart';

class LearningContinueService {
  LearningContinueService(this._db);
  final FirebaseFirestore _db;

  DocumentReference<Map<String, dynamic>> _ref(String uid) {
    return _db.collection('users').doc(uid).collection('learning').doc('continue');
  }

  Future<void> upsert({
    required String uid,
    required String lessonPath,
    required String lessonId,
    required String lessonTitle,
    String? languageCode,
    String? languageName,
    String? courseId,
    String? courseTitle,
    String? courseSubtitle,
    int? progressPercent,
  }) async {
    await _ref(uid).set(
      {
        'lessonPath': lessonPath,
        'lessonId': lessonId,
        'lessonTitle': lessonTitle,
        if (languageCode != null) 'languageCode': languageCode,
        if (languageName != null) 'languageName': languageName,
        if (courseId != null) 'courseId': courseId,
        if (courseTitle != null) 'courseTitle': courseTitle,
        if (courseSubtitle != null) 'courseSubtitle': courseSubtitle,
        if (progressPercent != null) 'progressPercent': progressPercent,
        'updatedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }
}
