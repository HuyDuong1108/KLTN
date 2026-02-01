import 'package:flutter/material.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

import '../../../data/stats_api.dart';
import '../../../data/lingua_api_service.dart';
import '../../../models/due_cards_detail.dart';
import '../../../models/flashcard_set.dart';
import '../../../models/vocabulary.dart';
import '../../flashcard/flashcard_set_detail.dart';
import '../../../data/set_review_history_store.dart';

enum DueReviewMode { all, long24h }

class DueReviewSessionPage extends StatefulWidget {
  final String scope; // now | today
  final String title;
  final bool includeCommunity;
  final String? startCardId;
  final DueReviewMode mode;

  const DueReviewSessionPage({
    super.key,
    required this.scope,
    required this.title,
    this.includeCommunity = true,
    this.startCardId,
    this.mode = DueReviewMode.all,
  });

  @override
  State<DueReviewSessionPage> createState() => _DueReviewSessionPageState();
}

class _DueReviewSessionPageState extends State<DueReviewSessionPage> {
  bool _loading = true;
  String? _error;

  List<DueCardDetailItem> _items = [];
  int _index = 0;

  bool _showMeaning = false;
  bool _submitting = false;
  bool _hasReviewed = false;

  bool _isNext = true;
  int _sessTotal = 0;
  int _sessAgain = 0;
  int _sessHard = 0;
  int _sessGood = 0;
  int _sessEasy = 0;


  final FlutterTts _tts = FlutterTts();

  @override
  void initState() {
    super.initState();
    _tts.setLanguage('ja-JP');
    _tts.setSpeechRate(0.4);
    _tts.setPitch(1.1);
    _load();
  }

  @override
  void dispose() {
    _tts.stop();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
      _items = [];
      _index = 0;
      _showMeaning = false;
      _submitting = false;
      _hasReviewed = false;
      _isNext = true;
      _sessTotal = 0;
      _sessAgain = 0;
      _sessHard = 0;
      _sessGood = 0;
      _sessEasy = 0;

    });

    try {
      final res = await StatsApi.instance.fetchDueCardsDetail(
        scope: widget.scope,
        includeCommunity: widget.includeCommunity,
      );

      final nowLocal = DateTime.now();

      DateTime? parseDueLocal(String? isoUtc) {
        if (isoUtc == null || isoUtc.isEmpty) return null;
        final dt = DateTime.tryParse(isoUtc);
        return dt?.toLocal();
      }

      bool passMode(DueCardDetailItem it) {
        if (widget.mode == DueReviewMode.all) return true;
        final dueLocal = parseDueLocal(it.due);
        if (dueLocal == null) return false;
        final minsPast = nowLocal.difference(dueLocal).inMinutes;
        return minsPast >= 1440;
      }

      final filtered = res.items.where(passMode).toList();

      var idx = 0;
      if (widget.startCardId != null && widget.startCardId!.trim().isNotEmpty) {
        final found = filtered.indexWhere((x) => x.cardId == widget.startCardId);
        if (found >= 0) idx = found;
      }

      if (!mounted) return;
      setState(() {
        _items = filtered;
        _index = idx.clamp(0, filtered.isEmpty ? 0 : filtered.length - 1);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  DueCardMatch? _bestMatch(DueCardDetailItem it) {
    if (it.matches.isEmpty) return null;
    return it.matches.first;
  }

  void _speakCurrent() {
    if (_items.isEmpty) return;
    final it = _items[_index];
    final m0 = _bestMatch(it);
    final text = (m0?.word ?? '').trim();
    if (text.isEmpty) return;
    _tts.speak(text);
  }

  Future<void> _writeFsrsToFirestore({
    required DueCardDetailItem it,
    required Map<String, dynamic> fsrsData,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final m0 = _bestMatch(it);
    if (m0 == null) return;

    final uid = user.uid;
    final isPersonal = m0.tab == 'personal';

    if (isPersonal) {
      final docRef = FirebaseFirestore.instance
          .collection('flashcards')
          .doc(uid)
          .collection('userFlashcards')
          .doc(m0.setId);

      final snap = await docRef.get();
      final raw = (snap.data()?['vocabList'] as List<dynamic>?) ?? [];
      final list = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();

      bool found = false;
      final updated = list.map((item) {
        if ((item['word'] ?? '') == m0.word) {
          found = true;
          return {...item, 'fsrs': fsrsData};
        }
        return item;
      }).toList();

      if (!found) {
        updated.add({
          'word': m0.word,
          'romaji': m0.reading ?? '',
          'meaning': m0.meaning ?? '',
          'fsrs': fsrsData,
        });
      }

      await docRef.set({'vocabList': updated}, SetOptions(merge: true));
      return;
    }

    final progressRef = FirebaseFirestore.instance
        .collection('flashcard_sets')
        .doc(m0.setId)
        .collection('userProgress')
        .doc(uid);

    final snap = await progressRef.get();
    final raw = (snap.data()?['vocabList'] as List<dynamic>?) ?? [];
    final list = raw.map((e) => Map<String, dynamic>.from(e as Map)).toList();

    bool found = false;
    final updated = list.map((item) {
      if ((item['word'] ?? '') == m0.word) {
        found = true;
        return {...item, 'fsrs': fsrsData};
      }
      return item;
    }).toList();

    if (!found) {
      updated.add({
        'word': m0.word,
        'romaji': m0.reading ?? '',
        'meaning': m0.meaning ?? '',
        'fsrs': fsrsData,
      });
    }

    await progressRef.set(
      {'vocabList': updated, 'updatedAt': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  }

  Future<void> _rate(int rating) async {
    if (_submitting) return;
    if (_items.isEmpty) return;

    final it = _items[_index];

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Chưa đăng nhập.')),
      );
      return;
    }

    setState(() => _submitting = true);

    try {
      final res = await LinguaApiService.reviewCard(
        cardId: it.cardId,
        rating: rating,
      );

      final fsrsData = <String, dynamic>{
        'cardId': res.cardId,
        'due': res.due,
        'state': res.state,
        'card': res.cardJson,
      };

      await _writeFsrsToFirestore(it: it, fsrsData: fsrsData);
      _hasReviewed = true;

      if (!mounted) return;

      if (_index >= _items.length - 1) {
        await showDialog(
          context: context,
          builder: (_) => AlertDialog(
            title: const Text('Hoàn thành'),
            content: const Text('Đã ôn xong danh sách thẻ.'),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
        if (mounted) Navigator.pop(context, _hasReviewed);
        return;
      }

      setState(() {
        _isNext = true;
        _index += 1;
        _showMeaning = false;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi gửi đánh giá: $e')),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  void _nextCard() {
    if (_items.isEmpty) return;
    if (_index >= _items.length - 1) return;
    setState(() {
      _isNext = true;
      _index += 1;
      _showMeaning = false;
    });
  }

  void _prevCard() {
    if (_items.isEmpty) return;
    if (_index <= 0) return;
    setState(() {
      _isNext = false;
      _index -= 1;
      _showMeaning = false;
    });
  }

  void _openSetOfCurrentCard() {
    if (_items.isEmpty) return;
    final it = _items[_index];
    final m0 = _bestMatch(it);
    if (m0 == null) return;

    final set = FlashcardSet(
      id: m0.setId,
      title: m0.setTitle,
      description: '',
      vocabList: const <Vocabulary>[],
      participants: 1,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlashcardSetDetailPage(
          set: set,
          isPersonal: m0.tab == 'personal',
        ),
      ),
    );
  }

  Widget _pill({required Widget child}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.black12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: child,
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

  Widget _ratingCard({
    required String title,
    required String subtitle,
    required Color color,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: InkWell(
        onTap: _submitting ? null : onTap,
        borderRadius: BorderRadius.circular(16),
        child: Opacity(
          opacity: _submitting ? 0.6 : 1.0,
          child: Container(
            height: 70,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(title,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                          )),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (_submitting)
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

  Widget _buildResponsiveActionButtons() {
    final btnAgain = _ratingCard(
      title: 'Again',
      subtitle: 'Forgot',
      color: Colors.red.shade800,
      icon: Icons.refresh,
      onTap: () => _rate(1),
    );
    final btnHard = _ratingCard(
      title: 'Hard',
      subtitle: 'Review',
      color: Colors.red.shade400,
      icon: Icons.sentiment_dissatisfied,
      onTap: () => _rate(2),
    );
    final btnGood = _ratingCard(
      title: 'Good',
      subtitle: 'Practice',
      color: Colors.amber.shade700,
      icon: Icons.sentiment_neutral,
      onTap: () => _rate(3),
    );
    final btnEasy = _ratingCard(
      title: 'Easy',
      subtitle: 'Known',
      color: Colors.green.shade600,
      icon: Icons.sentiment_satisfied,
      onTap: () => _rate(4),
    );

    final w = MediaQuery.of(context).size.width;
    final isMobile = w < 600;

    if (isMobile) {
      return Column(
        children: [
          Row(children: [btnAgain, const SizedBox(width: 10), btnHard]),
          const SizedBox(height: 10),
          Row(children: [btnGood, const SizedBox(width: 10), btnEasy]),
        ],
      );
    }
    return Row(
      children: [
        btnAgain,
        const SizedBox(width: 10),
        btnHard,
        const SizedBox(width: 10),
        btnGood,
        const SizedBox(width: 10),
        btnEasy,
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.orange.shade400,
          foregroundColor: Colors.black,
          title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.orange.shade400,
          foregroundColor: Colors.black,
          title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('Lỗi tải danh sách: $_error'),
                const SizedBox(height: 12),
                ElevatedButton(
                  onPressed: _load,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                  child: const Text('Tải lại', style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_items.isEmpty) {
      final msg = widget.mode == DueReviewMode.long24h
          ? 'Không có thẻ quá hạn lâu để ôn.'
          : 'Không có thẻ cần ôn.';
      return WillPopScope(
        onWillPop: () async {
          Navigator.pop(context, _hasReviewed);
          return false;
        },
        child: Scaffold(
          appBar: AppBar(
            backgroundColor: Colors.orange.shade400,
            foregroundColor: Colors.black,
            title: Text(widget.title, style: const TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: Center(child: Text(msg)),
          backgroundColor: Colors.grey.shade100,
        ),
      );
    }

    final it = _items[_index];
    final m0 = _bestMatch(it);

    final word = (m0?.word ?? it.cardId).trim();
    final reading = (m0?.reading ?? '').trim();
    final meaning = (m0?.meaning ?? '').trim();
    final tabLabel = (m0 == null) ? '—' : (m0.tab == 'personal' ? 'Cá nhân' : 'Cộng đồng');
    final setTitle = (m0?.setTitle ?? '').trim();

    return WillPopScope(
      onWillPop: () async {
        Navigator.pop(context, _hasReviewed);
        return false;
      },
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: Text(widget.title, style: const TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
          backgroundColor: Colors.orange.shade400,
          elevation: 0,
          iconTheme: const IconThemeData(color: Colors.black),
          actions: [
            IconButton(
              onPressed: _openSetOfCurrentCard,
              icon: const Icon(Icons.open_in_new),
              tooltip: 'Mở bộ thẻ',
            ),
          ],
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              children: [
                Row(
                  children: [
                    _pill(
                      child: Text(
                        'Card ${_index + 1} / ${_items.length}',
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                    ),
                    const SizedBox(width: 8),
                    _pill(
                      child: Text(tabLabel, style: const TextStyle(fontWeight: FontWeight.w800)),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _pill(
                        child: Text(
                          setTitle.isEmpty ? '—' : setTitle,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Expanded(
                  child: AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    transitionBuilder: (child, animation) {
                      final offsetAnimation = Tween<Offset>(
                        begin: Offset(_isNext ? 0.15 : -0.15, 0),
                        end: Offset.zero,
                      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
                      return SlideTransition(position: offsetAnimation, child: child);
                    },
                    child: GestureDetector(
                      key: ValueKey(_index),
                      onTap: () => setState(() => _showMeaning = !_showMeaning),
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
                                  icon: Icon(Icons.volume_up_rounded, size: 26, color: Colors.orange.shade400),
                                  onPressed: _speakCurrent,
                                ),
                              ],
                            ),
                            const Spacer(),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                _showMeaning ? (reading.isNotEmpty ? reading : word) : word,
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 34, fontWeight: FontWeight.w800),
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (_showMeaning && meaning.isNotEmpty)
                              Text(
                                meaning,
                                textAlign: TextAlign.center,
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.grey.shade800,
                                ),
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                              )
                            else
                              Text('Chạm để lật', style: TextStyle(color: Colors.grey.shade500)),
                            const Spacer(),
                            Text('State: ${it.state}', style: const TextStyle(color: Colors.grey)),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 12),

                Row(
                  children: [
                    _circleNavButton(icon: Icons.chevron_left, onTap: _prevCard),
                    const SizedBox(width: 10),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: () => setState(() => _showMeaning = !_showMeaning),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange.shade400,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                            elevation: 0,
                          ),
                          child: const Text('Lật thẻ', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    _circleNavButton(icon: Icons.chevron_right, onTap: _nextCard),
                  ],
                ),

                const SizedBox(height: 12),

                Align(
                  alignment: Alignment.center,
                  child: Text(
                    'Mức độ ghi nhớ?',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontWeight: FontWeight.w700, color: Colors.grey.shade900),
                  ),
                ),

                const SizedBox(height: 10),

                _buildResponsiveActionButtons(),
              ],
            ),
          ),
        ),
      ),
    );
  }
  String _reviewHistoryKey({required String uid, required String setId}) {
  return 'set_review_history__${uid}__$setId';
}


}
