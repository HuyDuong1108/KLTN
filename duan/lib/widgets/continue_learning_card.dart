import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ContinueLearningCard extends StatelessWidget {
  final Future<void> Function(String lessonPath) onContinue;

  const ContinueLearningCard({super.key, required this.onContinue});
  String _prettyCourseId(String courseId) {
    if (courseId.startsWith("level_")) {
      final n = courseId.replaceFirst("level_", "");
      return "Level $n";
    }
    return courseId;
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;

    if (uid == null) {
      return _cardShell(
        subtitle: "Đăng nhập để dùng Continue Learning",
        enabled: false,
        onPressed: null,
      );
    }

    final ref = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('learning')
        .doc('continue');

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: ref.snapshots(),
      builder: (context, snapshot) {
        String subtitle = "Chưa có bài đang học";
        String? lessonPath;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() ?? {};

          final lessonTitle = (data['lessonTitle'] ?? '').toString();

          final languageName = (data['languageName'] ?? '').toString();
          final languageCode = (data['languageCode'] ?? '').toString();

          final courseTitle = (data['courseTitle'] ?? '').toString();
          final courseId = (data['courseId'] ?? '').toString();

          final progress = data['progressPercent'];
          final courseSubtitle = (data['courseSubtitle'] ?? '').toString();

          final langLabel = languageName.isNotEmpty
              ? languageName
              : (languageCode.isNotEmpty ? languageCode.toUpperCase() : "");

          final courseLabel = courseTitle.isNotEmpty
              ? courseTitle
              : (courseId.isNotEmpty ? _prettyCourseId(courseId) : "");

          if (lessonTitle.isNotEmpty) {
            if (langLabel.isNotEmpty && courseLabel.isNotEmpty) {
              subtitle = "$langLabel • $courseLabel\n$lessonTitle";
            } else {
              subtitle = lessonTitle;
            }

            if (courseSubtitle.isNotEmpty) {
              subtitle = "$subtitle\n$courseSubtitle";
            }

            if (progress is int) {
              subtitle = "$subtitle\nTiến độ $progress%";
            }
          }

          final lp = (data['lessonPath'] ?? '').toString();
          if (lp.isNotEmpty) lessonPath = lp;
        }

        String? languageCode;

        if (snapshot.hasData && snapshot.data!.exists) {
          final data = snapshot.data!.data() ?? {};
          languageCode = (data['languageCode'] ?? data['lang'] ?? '')
              .toString()
              .trim();
        }

        return _cardShell(
          subtitle: subtitle,
          enabled: lessonPath != null,
          onPressed: lessonPath == null ? null : () => onContinue(lessonPath!),
          languageCode: languageCode,
        );
      },
    );
  }

  String _flagForLanguage({String? languageCode, String? headText}) {
    final code = (languageCode ?? '').toLowerCase().trim();
    if (code == 'ja' ||
        code == 'jp' ||
        (headText ?? '').toLowerCase().contains('japan')) {
      return '🇯🇵';
    }
    if (code == 'ko' ||
        code == 'kr' ||
        (headText ?? '').toLowerCase().contains('korean')) {
      return '🇰🇷';
    }
    if (code == 'zh' ||
        code == 'cn' ||
        (headText ?? '').toLowerCase().contains('chinese')) {
      return '🇨🇳';
    }
    if (code == 'en' || (headText ?? '').toLowerCase().contains('english')) {
      return '🇬🇧';
    }
    if (code == 'vi' || (headText ?? '').toLowerCase().contains('vietnam')) {
      return '🇻🇳';
    }
    return '';
  }

  Widget _subtitleBlock(String subtitle, {String? languageCode}) {
    final parts = subtitle
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final head = parts.isNotEmpty ? parts[0] : '';
    final title = parts.length >= 2 ? parts[1] : '';
    final tail = parts.length >= 3 ? parts.sublist(2).join('\n') : '';

    final flag = _flagForLanguage(languageCode: languageCode, headText: head);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (head.isNotEmpty)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.22),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (flag.isNotEmpty) ...[
                  Text(flag, style: const TextStyle(fontSize: 12)),
                  const SizedBox(width: 6),
                ],
                Flexible(
                  child: Text(
                    head,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        if (head.isNotEmpty) const SizedBox(height: 10),

        if (title.isNotEmpty)
          Text(
            title,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
              height: 1.15,
            ),
          )
        else
          Text(
            subtitle,
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70),
          ),

        if (tail.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(
            tail,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(color: Colors.white70, height: 1.2),
          ),
        ],
      ],
    );
  }

  Widget _cardShell({
    required String subtitle,
    required bool enabled,
    required VoidCallback? onPressed,
    String? languageCode,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Color(0xFF4FC3F7),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Continue Learning",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 10),
                _subtitleBlock(subtitle, languageCode: languageCode),
                const SizedBox(height: 12),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF1976D2),
                    elevation: 3,
                    shadowColor: Color(0x224FC3F7),

                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),

                  onPressed: enabled ? onPressed : null,
                  child: const Text(
                    "Continue",
                    style: TextStyle(
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Container(
            height: 130,
            width: 130,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Image.asset("lib/image/logo.png"),
          ),
        ],
      ),
    );
  }
}
