import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../models/vocabulary.dart';
import '../../data/lingua_api_service.dart';
import 'study_result_pages.dart';
import '../../data/set_review_history_store.dart';
import 'package:intl/intl.dart';
import '../../companion/companion_context.dart';
import '../../companion/companion_service.dart';
import '../../companion/companion_events.dart';


class FlashcardStudyPage extends StatefulWidget {
  final List<Vocabulary> vocabList;
  final String setId; // ID bộ flashcard
  final bool isPersonal; // true: Cá nhân, false: Cộng đồng
  final String setTitle;

  const FlashcardStudyPage({
    super.key,
    required this.vocabList,
    required this.setId,
    required this.isPersonal,
    required this.setTitle,
  });

  @override
  State<FlashcardStudyPage> createState() => _FlashcardStudyPageState();
}

class _FlashcardStudyPageState extends State<FlashcardStudyPage> {
  int currentIndex = 0;
  bool showMeaning = false;
  bool isNext = true; // để xác định hướng slide
  bool _isSubmitting = false;
  int _again = 0;
  int _hard = 0;
  int _good = 0;
  int _easy = 0;
  final FlutterTts tts = FlutterTts();
  final Map<int, int> _ratedByIndex = {};

  @override
  void initState() {
    super.initState();
    tts.setLanguage("en-US");
    tts.setSpeechRate(0.4);
    tts.setPitch(1.1);
  }
Future<void> _updateFlashcardDailyGoal() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final today = DateFormat('yyyy-MM-dd').format(DateTime.now());

  final docRef = FirebaseFirestore.instance
      .collection('users')
      .doc(user.uid)
      .collection('dailyGoals')
      .doc(today);

  final snap = await docRef.get();

  if (!snap.exists) {
    await docRef.set({
      "listeningReadingCount": 0,
      "flashcardSetCount": 1,
      "speakingCount": 0,
      "date": today,
    });
  } else {
    await docRef.update({
      "flashcardSetCount": FieldValue.increment(1),
    });
  }
}

  void speak(String text) => tts.speak(text);

  // ------------------ SRS Update Function (FSRS backend) ------------------
  Future<void> updateSRS(Vocabulary v, int rating) async {
    final idx = currentIndex;
    if (_ratedByIndex.containsKey(idx)) {
      if (!mounted) return;
      _snack('Thẻ đã được chấm.');

      return;
    }
    if (_isSubmitting) return;

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      _snack('Bạn chưa đăng nhập.');
      return;
    }
    final userId = user.uid;

    if (rating < 1 || rating > 4) {
      if (!mounted) return;
      _snack('Rating phải trong khoảng 1..4');
      return;
    }

    setState(() => _isSubmitting = true);

    final cardId = 'user_$userId::set_${widget.setId}::word_${v.word}';

    try {
      final res = await LinguaApiService.reviewCard(
        cardId: cardId,
        rating: rating,
      );

      final fsrsData = <String, dynamic>{
        'cardId': res.cardId,
        'due': res.due,
        'state': res.state,
        'card': res.cardJson,
      };

      if (widget.isPersonal) {
        final docRef = FirebaseFirestore.instance
            .collection('flashcards')
            .doc(userId)
            .collection('userFlashcards')
            .doc(widget.setId);

        final snap = await docRef.get();
        final raw = (snap.data()?['vocabList'] as List<dynamic>?) ?? [];
        final list = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();

        bool found = false;
        final updated = list.map((item) {
          if ((item['word'] ?? '') == v.word) {
            found = true;
            return {...item, 'fsrs': fsrsData};
          }
          return item;
        }).toList();

        if (!found) {
          updated.add({
            'word': v.word,
            'romaji': v.romaji,
            'meaning': v.meaning,
            'fsrs': fsrsData,
          });
        }
        await docRef.set({'vocabList': updated}, SetOptions(merge: true));
      } else {
        final progressRef = FirebaseFirestore.instance
            .collection('flashcard_sets')
            .doc(widget.setId)
            .collection('userProgress')
            .doc(userId);

        final snap = await progressRef.get();
        final raw = (snap.data()?['vocabList'] as List<dynamic>?) ?? [];
        final list = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();

        bool found = false;
        final updated = list.map((item) {
          if ((item['word'] ?? '') == v.word) {
            found = true;
            return {...item, 'fsrs': fsrsData};
          }
          return item;
        }).toList();

        if (!found) {
          updated.add({
            'word': v.word,
            'romaji': v.romaji,
            'meaning': v.meaning,
            'fsrs': fsrsData,
          });
        }

        await progressRef.set(
          {
            'vocabList': updated,
            'updatedAt': FieldValue.serverTimestamp(),
          },
          SetOptions(merge: true),
        );
      }
      setState(() {
        _ratedByIndex[idx] = rating;
        if (rating == 1) _again++;
        if (rating == 2) _hard++;
        if (rating == 3) _good++;
        if (rating == 4) _easy++;
      });


      _nextAfterRating();
    } catch (e) {
      if (!mounted) return;
      _snack('Lỗi gửi đánh giá FSRS: $e');
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
  void _finishSession() {
    _finishOrWarn();
  }
  void _nextFromNav() {
    void prevCard() {
      if (_isSubmitting) return;
      setState(() {
        if (currentIndex > 0) {
          isNext = false;
          currentIndex--;
          showMeaning = false;
        }
      });
    }

    final total = widget.vocabList.length;

    if (!_ratedByIndex.containsKey(currentIndex)) {
      _snack('Chưa chọn mức độ nên thẻ chưa được ghi nhận.');
    }

    if (currentIndex < total - 1) {
      setState(() {
        isNext = true;
        currentIndex++;
        showMeaning = false;
      });
    } else {
      _finishOrWarn();
    }
  }

  void _nextAfterRating() {
    final total = widget.vocabList.length;

    if (currentIndex < total - 1) {
      setState(() {
        isNext = true;
        currentIndex++;
        showMeaning = false;
      });
    } else {
      _finishOrWarn();
    }
  }


  void nextCard() {
    _nextFromNav();
  }

  void prevCard() {
    setState(() {
      if (currentIndex > 0) {
        isNext = false;
        currentIndex--;
        showMeaning = false;
      }
    });
  }
  void _jumpToFirstUnrated() {
    final total = widget.vocabList.length;
    for (int i = 0; i < total; i++) {
      if (!_ratedByIndex.containsKey(i)) {
        setState(() {
          currentIndex = i;
          showMeaning = false;
          isNext = true;
        });
        return;
      }
    }
  }
  void _snack(String msg) {
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);

    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: Text(msg),
        duration: const Duration(milliseconds: 900), 
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 14),
      ),
    );
  }


  void _finishOrWarn() async{
    final total = widget.vocabList.length;
    final remaining = total - _ratedByIndex.length;

    if (remaining > 0) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (_) {
          return Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              padding: const EdgeInsets.fromLTRB(18, 18, 18, 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      Icons.warning_amber_rounded,
                      color: Colors.blue.shade700,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Chưa chấm hết thẻ',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Còn $remaining thẻ chưa chọn mức độ.\nChọn “Xem lại” để quay về thẻ chưa chấm.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      height: 1.35,
                      color: Colors.grey.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 14),

                  Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              Navigator.pop(context); // về bộ thẻ
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.blue.shade700,
                              side: BorderSide(color: Colors.blue.shade300, width: 1.2),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text(
                              'Thoát',
                              style: TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 46,
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context);
                              _jumpToFirstUnrated();
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue.shade400,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                              elevation: 0,
                            ),
                            child: const Text(
                              'Xem lại',
                              style: TextStyle(fontWeight: FontWeight.w900),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );

      return;
    }
    try {
      await SetReviewHistoryStore.instance.addEntry(
        setId: widget.setId,
        isPersonal: widget.isPersonal,
        entry: SetReviewHistoryEntry(
          id: '',
          createdAt: DateTime.now(),
          mode: 'flashcard',
          total: total,
          again: _again,
          hard: _hard,
          good: _good,
          easy: _easy,
        ),
      );
    } catch (_) {}

await _updateFlashcardDailyGoal();

    // Companion: ghi nhận activity + bắn event cho Mira/Luka/Aki react
    CompanionContextService.instance.setRecentActivity(
      "Vừa ôn xong $total thẻ ở bộ \"${widget.setTitle}\" "
      "(dễ: $_easy, tốt: $_good, khó: $_hard, again: $_again)",
    );

    CompanionService.instance.fireEvent(
      CompanionEventType.flashcardReviewed,
      payload: {
        "set_title": widget.setTitle,
        "count": total,
        "again": _again,
        "hard": _hard,
        "good": _good,
        "easy": _easy,
        "success_rate": total == 0
            ? 0
            : ((_good + _easy) / total * 100).round(),
      },
      force: true,
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => FlashcardStudyResultPage(
          setTitle: widget.setTitle,
          totalCards: total,
          again: _again,
          hard: _hard,
          good: _good,
          easy: _easy,
          retryBuilder: (_) => FlashcardStudyPage(
            vocabList: widget.vocabList,
            setId: widget.setId,
            isPersonal: widget.isPersonal,
            setTitle: widget.setTitle,
          ),
        ),
      ),
    );
  }


  // --- [MỚI] Hàm xử lý layout nút bấm Responsive ---
  Widget _buildResponsiveActionButtons(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    bool isMobile = screenWidth < 600; // Coi dưới 600px là mobile dọc

    final v = widget.vocabList[currentIndex];

    // Tạo sẵn 4 nút để tái sử dụng
    final btnAgain = _ratingCard(
      title: 'Again',
      subtitle: 'Forgot',
      color: Colors.red.shade800,
      icon: Icons.refresh,
      onTap: () => updateSRS(v, 1),
    );
    final btnHard = _ratingCard(
      title: 'Hard',
      subtitle: 'Review',
      color: Colors.red.shade400,
      icon: Icons.sentiment_dissatisfied,
      onTap: () => updateSRS(v, 2),
    );
    final btnGood = _ratingCard(
      title: 'Good',
      subtitle: 'Practice',
      color: Colors.amber.shade700,
      icon: Icons.sentiment_neutral,
      onTap: () => updateSRS(v, 3),
    );
    final btnEasy = _ratingCard(
      title: 'Easy',
      subtitle: 'Known',
      color: Colors.green.shade600,
      icon: Icons.sentiment_satisfied,
      onTap: () => updateSRS(v, 4),
    );

    if (isMobile) {
      // Layout 2x2 cho điện thoại
      return Column(
        children: [
          Row(children: [btnAgain, const SizedBox(width: 10), btnHard]),
          const SizedBox(height: 10),
          Row(children: [btnGood, const SizedBox(width: 10), btnEasy]),
        ],
      );
    } else {
      // Layout 1 hàng ngang cho Tablet/PC
      return Row(
        children: [
          btnAgain, const SizedBox(width: 10),
          btnHard, const SizedBox(width: 10),
          btnGood, const SizedBox(width: 10),
          btnEasy,
        ],
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final total = widget.vocabList.length;
    if (total == 0) {
      return Scaffold(
        appBar: AppBar(
          title: Text('Flashcards - ${widget.setTitle}'),
          backgroundColor: Colors.blue.shade400,
        ),
        body: const Center(child: Text('Deck trống.')),
      );
    }

    final v = widget.vocabList[currentIndex];

    return Scaffold(
      backgroundColor: const Color(0xFFF3F9FF),
      appBar: AppBar(
        title: Text(
          'Flashcards - ${widget.setTitle}',
          style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.blue.shade400,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          child: Column(
            children: [
              // ===== Top info row =====
              Row(
                children: [
                  _pill(text: 'Card ${currentIndex + 1} of $total'),
                  const Spacer(),
                  _pill(text: '+5 XP', trailing: const Icon(Icons.star, size: 16)),
                ],
              ),
              const SizedBox(height: 12),

              // ===== Flashcard display =====
              Expanded(
                child: AnimatedSwitcher(
                  duration: const Duration(milliseconds: 250),
                  transitionBuilder: (child, animation) {
                    final offsetAnimation = Tween<Offset>(
                      begin: Offset(isNext ? 0.15 : -0.15, 0),
                      end: Offset.zero,
                    ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
                    return SlideTransition(position: offsetAnimation, child: child);
                  },
                  child: GestureDetector(
                    key: ValueKey(currentIndex),
                    onTap: () => setState(() => showMeaning = !showMeaning),
                    child: Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.06),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: const Text('Word', style: TextStyle(fontSize: 12)),
                              ),
                              const Spacer(),
                              IconButton(
                                icon: Icon(Icons.volume_up_rounded, size: 26, color: Colors.blue.shade400),
                                onPressed: () => speak(v.word),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Text(
                            showMeaning ? v.romaji : v.word,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 10),
                          if (showMeaning)
                            Text(
                              v.meaning,
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade800,
                              ),
                            )
                          else
                            Text(
                              'Tap to flip',
                              style: TextStyle(color: Colors.grey.shade500),
                            ),
                          const Spacer(),
                        ],
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // ===== Prev / Flip / Next row =====
              Row(
                children: [
                  _circleNavButton(icon: Icons.chevron_left, onTap: prevCard),
                  const SizedBox(width: 10),
                  Expanded(
                    child: SizedBox(
                      height: 52,
                      child: ElevatedButton(
                        onPressed: () => setState(() => showMeaning = !showMeaning),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue.shade400,
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                          elevation: 0,
                        ),
                        child: const Text('Lật thẻ', style: TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _circleNavButton(icon: Icons.chevron_right, onTap: _nextFromNav),
                ],
              ),

              const SizedBox(height: 12),

              // ===== Prompt =====
              Align(
                alignment: Alignment.center,
                child: Text(
                  'Mức độ ghi nhớ?',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey.shade900),
                ),
              ),

              const SizedBox(height: 10),

              // ===== Rating buttons (ĐÃ SỬA: Gọi hàm responsive) =====
              _buildResponsiveActionButtons(context),
            ],
          ),
        ),
      ),
    );
  }

  // ===== small helpers =====

  Widget _pill({required String text, Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(text, style: const TextStyle(fontWeight: FontWeight.w700)),
          if (trailing != null) ...[const SizedBox(width: 6), trailing],
        ],
      ),
    );
  }

  Widget _circleNavButton({required IconData icon, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(999),
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Icon(icon, color: Colors.grey.shade800, size: 28),
      ),
    );
  }

  // ĐÃ SỬA: Thêm Expanded và xử lý overflow cho text
  Widget _ratingCard({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: _isSubmitting ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: _isSubmitting ? 0.6 : 1.0,
          child: Container(
            height: 70, // Giảm nhẹ chiều cao nếu cần
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Expanded( // Quan trọng: Giúp text không bị tràn ra ngoài
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.9), fontSize: 11),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (_isSubmitting)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}