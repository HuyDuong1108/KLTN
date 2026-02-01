import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_tts/flutter_tts.dart';

//thêm 
import 'package:firebase_auth/firebase_auth.dart';
import '../../../data/learning_to_flashcards_service.dart';
import '../../../data/learning_continue_service.dart';

import 'korean_quiz_page.dart';

class KoreanLessonDetailPage extends StatefulWidget {
  final DocumentSnapshot lessonDoc;
  final bool openReview;

  const KoreanLessonDetailPage({
    super.key,
    required this.lessonDoc,
    this.openReview = false,
  });

  @override
  State<KoreanLessonDetailPage> createState() => _KoreanLessonDetailPageState();
}

class _KoreanLessonDetailPageState extends State<KoreanLessonDetailPage> {
  final FlutterTts _tts = FlutterTts();

  // Thêm : tạo bộ thẻ flashcards từ Lessons
  final LearningToFlashcardsService _playlistSvc =
      LearningToFlashcardsService(FirebaseFirestore.instance);
  
  // mới thêm
  bool _selecting = false;
  final Set<int> _selected =<int>{};

  final LearningContinueService _continueSvc =
    LearningContinueService(FirebaseFirestore.instance);

  @override
  void initState() {
    super.initState();
    _initTts();
    // mới thêm : lưu tiếp tục học
    _upsertContinueState();
  }
  void _upsertContinueState() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final data = widget.lessonDoc.data() as Map<String, dynamic>? ?? {};
    final lessonTitle = (data["title"] ?? "").toString();

    final lessonRef = widget.lessonDoc.reference;

    final courseRef = lessonRef.parent.parent;
    final courseId = courseRef?.id;

    final languageRef = courseRef?.parent.parent;
    final languageCode = languageRef?.id;

    _continueSvc.upsert(
      uid: uid,
      lessonPath: lessonRef.path,
      lessonId: widget.lessonDoc.id,
      lessonTitle: lessonTitle,
      languageCode: languageCode ?? "ko",
      courseId: courseId,
    );

    Future.microtask(() async {
      try {
        String? courseTitle;
        String? courseSubtitle;
        String? languageName;

        if (courseRef != null) {
          final cSnap = await courseRef.get();
          final cData = cSnap.data() as Map<String, dynamic>? ?? {};
          courseTitle = (cData["title"] ?? "").toString();
          courseSubtitle = (cData["subtitle"] ?? "").toString();
        }

        if (languageRef != null) {
          final lSnap = await languageRef.get();
          final lData = lSnap.data() as Map<String, dynamic>? ?? {};
          languageName = (lData["name"] ?? "").toString();
        }

        await _continueSvc.upsert(
          uid: uid,
          lessonPath: lessonRef.path,
          lessonId: widget.lessonDoc.id,
          lessonTitle: lessonTitle,
          languageCode: languageCode ?? "ko",
          languageName: languageName?.isEmpty == true ? null : languageName,
          courseId: courseId,
          courseTitle: courseTitle?.isEmpty == true ? null : courseTitle,
          courseSubtitle: courseSubtitle?.isEmpty == true ? null : courseSubtitle,
        );
      } catch (_) {}
    });
  }

  Future<void> _initTts() async {
    await _tts.setLanguage("ko-KR");
    await _tts.setSpeechRate(0.45);
    await _tts.setPitch(1.0);
  }

  Future<void> _speak(String text) async {
    await _tts.stop();
    await _tts.speak(text);
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  // mới thêm
  void _setSelecting(bool v) {
    setState(() {
      _selecting = v;
      if (!v) _selected.clear();
    });
  }
  // mới thêm 
  List<Map<String, dynamic>> _flattenLessonItems(Map<String, dynamic> content) {
    final sections = content["sections"];
    if (sections is! List) return <Map<String, dynamic>>[];

    final out = <Map<String, dynamic>>[];
    for (final sec in sections) {
      if (sec is! Map) continue;
      final items = sec["items"];
      if (items is! List) continue;

      for (final it in items) {
        if (it is Map) {
          out.add(Map<String, dynamic>.from(it));
        }
      }
    }
    return out;
  }

  List<Map<String, dynamic>> _itemsToVocabs(List<Map<String, dynamic>> items) {
    return items.map((it) {
      final word = (it["jp"] ?? "").toString().trim();
      final romaji = (it["romaji"] ?? "").toString().trim();
      final meaning = (it["vi"] ?? "").toString().trim();
      final imageUrl = (it["image"] ?? "").toString().trim();

      return {
        "word": word,
        "romaji": romaji,
        "meaning": meaning,
        "imageUrl": imageUrl,
        "example": "",
        "exampleMeaning": "",
        "exampleExplain": "",
      };
    }).where((v) {
      final w = (v["word"] ?? "").toString().trim();
      final m = (v["meaning"] ?? "").toString().trim();
      return w.isNotEmpty || m.isNotEmpty;
    }).toList();
  }

  Future<void> _openAddToFlashcardsSheet({
    required BuildContext context,
    required String uid,
    required List<Map<String, dynamic>> vocabs,
    required Map<String, dynamic> sourceMeta,
    required String defaultTitle,
    required String defaultDesc,
  }) async {
    if (vocabs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Không có từ để thêm")),
      );
      return;
    }

    final titleCtrl = TextEditingController(text: defaultTitle);
    final descCtrl = TextEditingController(text: defaultDesc);

    String mode = "existing"; // existing | new
    String? pickedSetId;
    bool saving = false;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            Future<void> doSave() async {
              if (saving) return;
              setModalState(() => saving = true);

              String formatSkipped(List<String> words) {
                if (words.isEmpty) return "";
                const maxShow = 5;
                final shown = words.take(maxShow).join(", ");
                if (words.length > maxShow) return "$shown, ...";
                return shown;
              }

              try {
                final enriched = vocabs.map((v) {
                  final m = Map<String, dynamic>.from(v);
                  m["source"] = sourceMeta;
                  return m;
                }).toList();

                AddVocabsResult res;

                if (mode == "existing") {
                  if (pickedSetId == null) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Hãy chọn một bộ thẻ để thêm vào.")),
                      );
                    }
                    setModalState(() => saving = false);
                    return;
                  }

                  res = await _playlistSvc.addVocabsToSetWithResult(
                    uid: uid,
                    setId: pickedSetId!,
                    vocabs: enriched,
                  );
                } else {
                  final t = titleCtrl.text.trim();
                  final d = descCtrl.text.trim();

                  if (t.isEmpty) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Tiêu đề không được để trống.")),
                      );
                    }
                    setModalState(() => saving = false);
                    return;
                  }

                  final out = await _playlistSvc.createSetWithVocabsWithResult(
                    uid: uid,
                    title: t,
                    description: d,
                    vocabs: enriched,
                    source: sourceMeta,
                  );
                  res = out.result;
                }

                if (!context.mounted) return;

                Navigator.pop(ctx);

                String msg;
                if (res.added == 0) {
                  msg = "Các từ bạn chọn đã có sẵn trong bộ thẻ. Không có từ mới để thêm.";
                } else if (res.skipped > 0) {
                  final preview = formatSkipped(res.skippedWords);
                  msg = "Đã thêm ${res.added} từ. Bỏ qua ${res.skipped} từ đã có"
                      "${preview.isEmpty ? "" : ": $preview"}.";
                } else {
                  msg = "Đã thêm ${res.added} từ vào Flashcards.";
                }

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(msg),
                    behavior: SnackBarBehavior.floating,
                    margin: const EdgeInsets.all(16),
                  ),
                );
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Lỗi: $e")),
                  );
                }
              } finally {
                setModalState(() => saving = false);
              }
            }

            return SafeArea(
              top: false,
              child: Padding(
                padding: EdgeInsets.only(
                  left: 16,
                  right: 16,
                  bottom: MediaQuery.of(ctx).viewInsets.bottom + 16,
                ),
                child: Container(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.10),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 48,
                        height: 5,
                        decoration: BoxDecoration(
                          color: Colors.black12,
                          borderRadius: BorderRadius.circular(999),
                        ),
                      ),
                      const SizedBox(height: 10),
                      const Text(
                        "Thêm vào Flashcards",
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        "Bạn muốn thêm bài học này vào đâu?",
                        style: TextStyle(
                          color: Colors.grey.shade700,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Tabs dạng pill
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(999),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _pillTab(
                                text: "Tạo bộ mới",
                                active: mode == "new",
                                onTap: () => setModalState(() => mode = "new"),
                              ),
                            ),
                            const SizedBox(width: 6),
                            Expanded(
                              child: _pillTab(
                                text: "Thêm vào bộ có sẵn",
                                active: mode == "existing",
                                onTap: () => setModalState(() => mode = "existing"),
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Preview card (giống mẫu)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(color: Colors.black12),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.folder_outlined, color: Colors.black54),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    (titleCtrl.text.trim().isEmpty ? defaultTitle : titleCtrl.text.trim()),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.w900),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    defaultDesc,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: Colors.grey.shade700,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 10),
                            Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: Colors.green.withOpacity(0.12),
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, size: 16, color: Colors.green),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 12),

                      if (mode == "new") ...[
                        TextField(
                          controller: titleCtrl,
                          onChanged: (_) => setModalState(() {}),
                          decoration: InputDecoration(
                            labelText: "Tên bộ học",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Colors.black12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: descCtrl,
                          decoration: InputDecoration(
                            labelText: "Mô tả",
                            filled: true,
                            fillColor: Colors.white,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(14),
                              borderSide: const BorderSide(color: Colors.black12),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                      ],

                      if (mode == "existing")
                        SizedBox(
                          height: MediaQuery.of(ctx).size.height * 0.34,
                          child: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                            stream: _playlistSvc.watchUserSets(uid),
                            builder: (ctx2, snap) {
                              if (!snap.hasData) {
                                return const Center(child: CircularProgressIndicator());
                              }
                              final docs = snap.data!.docs;
                              if (docs.isEmpty) {
                                return const Center(child: Text("Chưa có bộ thẻ cá nhân"));
                              }

                              return ListView.separated(
                                itemCount: docs.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 10),
                                itemBuilder: (_, i) {
                                  final d = docs[i];
                                  final data = d.data();
                                  final t = (data["title"] ?? "Untitled").toString();
                                  final desc = (data["description"] ?? "").toString();
                                  final selected = pickedSetId == d.id;

                                  return InkWell(
                                    onTap: () => setModalState(() => pickedSetId = d.id),
                                    borderRadius: BorderRadius.circular(16),
                                    child: Container(
                                      padding: const EdgeInsets.all(12),
                                      decoration: BoxDecoration(
                                        color: Colors.white,
                                        borderRadius: BorderRadius.circular(16),
                                        border: Border.all(
                                          color: selected ? Colors.orange : Colors.black12,
                                          width: selected ? 1.3 : 1,
                                        ),
                                      ),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 36,
                                            height: 36,
                                            decoration: BoxDecoration(
                                              color: Colors.orange.withOpacity(0.10),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: const Icon(Icons.collections_bookmark_outlined,
                                                color: Colors.orange, size: 18),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  t,
                                                  maxLines: 1,
                                                  overflow: TextOverflow.ellipsis,
                                                  style: const TextStyle(fontWeight: FontWeight.w900),
                                                ),
                                                if (desc.isNotEmpty)
                                                  Padding(
                                                    padding: const EdgeInsets.only(top: 2),
                                                    child: Text(
                                                      desc,
                                                      maxLines: 1,
                                                      overflow: TextOverflow.ellipsis,
                                                      style: TextStyle(
                                                        color: Colors.grey.shade700,
                                                        fontWeight: FontWeight.w600,
                                                      ),
                                                    ),
                                                  ),
                                              ],
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Icon(
                                            selected ? Icons.radio_button_checked : Icons.radio_button_off,
                                            color: selected ? Colors.orange : Colors.black38,
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: saving ? null : doSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: saving
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                                )
                              : const Text(
                                  "LƯU",
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900),
                                ),
                        ),
                      ),

                      const SizedBox(height: 8),
                      TextButton(
                        onPressed: saving ? null : () => Navigator.pop(ctx),
                        child: Text(
                          "HỦY",
                          style: TextStyle(color: Colors.grey.shade700, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );

          },
        );
      },
    );
  }

  void _showPlaylistMenu({
  required BuildContext context,
  required String uid,
  required String lessonTitle,
  required List<Map<String, dynamic>> allVocabs,
}) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    isScrollControlled: false,
    barrierColor: Colors.black.withOpacity(0.35), // chỉ tối nền
    builder: (sheetCtx) {
      return SafeArea(
        top: false,
        child: Container(
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: BoxDecoration(
            color: Colors.grey.shade100, // trùng nền app
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.10),
                blurRadius: 18,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 48,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.black12,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 10),
              const Text(
                'Thêm vào Flashcards',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 6),
              Text(
                'Chọn cách thêm nội dung',
                style: TextStyle(
                  color: Colors.grey.shade700,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 14),

              _playlistChoiceTile(
                icon: Icons.add,
                title: 'Thêm toàn bộ bài',
                subtitle: 'Tất cả từ vựng trong bài học',
                onTap: () async {
                  Navigator.pop(sheetCtx);

                  final sourceMeta = {
                    'type': 'learning',
                    'languageCode': 'ko',
                    'lessonId': widget.lessonDoc.id,
                    'lessonTitle': lessonTitle,
                  };

                  await _openAddToFlashcardsSheet(
                    context: context,
                    uid: uid,
                    vocabs: allVocabs,
                    sourceMeta: sourceMeta,
                    defaultTitle: lessonTitle.isEmpty ? 'Bài học mới' : lessonTitle,
                    defaultDesc: 'Tạo từ lesson (Learning)',
                  );
                },
              ),
              const SizedBox(height: 12),
              _playlistChoiceTile(
                icon: Icons.checklist_rounded,
                title: 'Chọn từ để thêm',
                subtitle: 'Lựa chọn cá nhân',
                onTap: () {
                  Navigator.pop(sheetCtx);
                  _setSelecting(true);
                },
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _pillTab({
  required String text,
  required bool active,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(999),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 160),
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? Colors.orange : Colors.transparent,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        text,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: active ? Colors.white : Colors.black87,
          fontWeight: FontWeight.w900,
        ),
      ),
    ),
  );
}

Widget _buildSelectingBar({
  required int total,
  required Future<void> Function() onAdd,
}) {
  final selectedCount = _selected.length;
  final allSelected = total > 0 && selectedCount == total;

  return SafeArea(
    top: false,
    child: Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            // HỦY (pill)
            OutlinedButton.icon(
              onPressed: () => _setSelecting(false),
              icon: const Icon(Icons.close, size: 18),
              label: const Text("Hủy"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),

            const SizedBox(width: 10),

            // CHỌN TẤT CẢ (pill)
            OutlinedButton.icon(
              onPressed: () {
                setState(() {
                  _selected.clear();
                  if (!allSelected) {
                    _selected.addAll(List<int>.generate(total, (i) => i));
                  }
                });
              },
              icon: Icon(allSelected ? Icons.remove_done : Icons.done_all, size: 18),
              label: Text(allSelected ? "Bỏ chọn" : "Chọn tất cả"),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.black87,
                side: BorderSide(color: Colors.grey.shade300),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(999),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                textStyle: const TextStyle(fontWeight: FontWeight.w800),
              ),
            ),

            const Spacer(),

            // CTA THÊM (cam)
            SizedBox(
              height: 42,
              child: ElevatedButton(
                onPressed: selectedCount == 0 ? null : () => onAdd(),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                  disabledBackgroundColor: Colors.orange.withOpacity(0.35),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.add, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    const Text(
                      "Thêm",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        "$selectedCount",
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}


Widget _playlistChoiceTile({
  required IconData icon,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(18),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.orange, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.chevron_right, color: Colors.black45),
        ],
      ),
    ),
  );
}

Widget _sheetHandle() {
  return Container(
    width: 48,
    height: 5,
    decoration: BoxDecoration(
      color: Colors.black12,
      borderRadius: BorderRadius.circular(999),
    ),
  );
}

Widget _choiceCard({
  required IconData icon,
  required String title,
  required String subtitle,
  required VoidCallback onTap,
}) {
  return InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.14),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: Colors.orange, size: 22),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          const Icon(Icons.chevron_right, color: Colors.black45),
        ],
      ),
    ),
  );
}

  @override
  Widget build(BuildContext context) {
    final data = widget.lessonDoc.data() as Map<String, dynamic>;
    final title = data["title"] ?? "";
    final content = data["content"] as Map<String, dynamic>;
    final List tests = data["test"] ?? [];

    // mới thêm : flatten items thành vocab list
    final flatItems = _flattenLessonItems(content);
    final allVocabs = _itemsToVocabs(flatItems);
    
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.orange.shade400,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),

        // mới thêm : action
         actions: [
          IconButton(
            icon: const Icon(Icons.playlist_add),
            onPressed: () {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid == null) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text("Cần đăng nhập để dùng Flashcards cá nhân")),
                );
                return;
              }
              _showPlaylistMenu(
                context: context,
                uid: uid,
                lessonTitle: title,
                allVocabs: allVocabs,
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // ===== INTRO CARD =====
                _whiteCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle("📌 Giới thiệu"),
                      const SizedBox(height: 8),
                      Text(
                        content["introduction"] ?? "",
                        style: const TextStyle(fontSize: 15),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // ===== OUTCOME CARD =====
                _whiteCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _sectionTitle("🎯 Sau khi học xong"),
                      const SizedBox(height: 8),
                      ...content["outcome"].map<Widget>(
                        (e) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 6),
                          child: Row(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  e,
                                  style: const TextStyle(fontSize: 14),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // ===== SECTIONS =====
                // mới thêm : 
                Builder(
                  builder: (context) {
                    int idx = -1;

                    final sections = content["sections"];
                    if (sections is! List) return const SizedBox.shrink();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: sections.map<Widget>((section) {
                        final sec = section as Map<String, dynamic>;
                        final items = sec["items"] as List? ?? [];

                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _sectionTitle((sec["title"] ?? "").toString()),
                            const SizedBox(height: 12),
                            ...items.map<Widget>((item) {
                              idx += 1;
                              return _hiraganaCard(
                                Map<String, dynamic>.from(item as Map),
                                index: idx,
                              );
                            }).toList(),
                            const SizedBox(height: 20),
                          ],
                        );
                      }).toList(),
                    );
                  },
                ),
              ],
            ),
          ),

          // ===== QUIZ BUTTON =====
          // mới thêm 
          if (_selecting)
          _buildSelectingBar(
            total: flatItems.length,
            onAdd: () async {
              final uid = FirebaseAuth.instance.currentUser?.uid;
              if (uid == null) return;

              final pickedItems = _selected.toList()..sort();
              final picked = pickedItems
                  .where((i) => i >= 0 && i < flatItems.length)
                  .map((i) => flatItems[i])
                  .toList();

              final vocabs = _itemsToVocabs(picked);

              final sourceMeta = {
                "type": "learning",
                "languageCode": "ko",
                "lessonId": widget.lessonDoc.id,
                "lessonTitle": title,
              };

              await _openAddToFlashcardsSheet(
                context: context,
                uid: uid,
                vocabs: vocabs,
                sourceMeta: sourceMeta,
                defaultTitle: title.isEmpty ? "Từ đã chọn" : "$title (đã chọn)",
                defaultDesc: "Tạo từ lesson (Learning)",
              );

              _setSelecting(false);
            },
          ),
        
        // mới cập nhật
        // ===== QUIZ BUTTON =====
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              height: 52,
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.orange,
                   shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: tests.isEmpty
                    ? null
                    : () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => KoreanQuizPage(
                              tests: tests,
                              lessonDoc: widget.lessonDoc,
                              isReview: widget.openReview,
                              ),
                            ),
                          );
                        },
                  child: Text(
                    tests.isEmpty ? "Không có bài test" : "Làm bài test (${tests.length} câu)",
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= UI COMPONENTS =================

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
    );
  }

  Widget _whiteCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

//mới cập nhật: thêm index
  Widget _hiraganaCard(Map<String, dynamic> item, {required int index}) {
    final checked = _selected.contains(index);
    
    return GestureDetector(
      onTap: !_selecting
          ? null
          : () {
              setState(() {
                if (checked) {
                  _selected.remove(index);
                } else {
                  _selected.add(index);
                }
              });
            },
      child:  Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            children: [
                // mới thêm : checkbox
               if (_selecting)
                  Checkbox(
                    value: checked,
                    onChanged: (v) {
                      setState(() {
                        if (v == true) {
                           _selected.add(index);
                        } else {
                            _selected.remove(index);
                        }
                      });
                    },
                  ),
                // IMAGE
                if (item["image"] != null)
                  Container(
                    height: 72,
                    width: 72,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Image.network(item["image"], fit: BoxFit.contain),
                  ),

                const SizedBox(width: 14),

                // TEXT
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item["jp"],
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "${item["romaji"]} • ${item["vi"]}",
                        style: const TextStyle(fontSize: 14, color: Colors.grey),
                      ),
                    ],
                  ),
                ),

                // AUDIO BUTTON
                GestureDetector(
                  onTap: () => _speak(item["jp"]),
                  child: Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: Colors.orange.withOpacity(0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.volume_up,
                      color: Colors.orange,
                      size: 24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      }
}
