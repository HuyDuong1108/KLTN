import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FlashcardDetailAdminPage extends StatefulWidget {
  final String setId;
  final Map<String, dynamic> data;
  final bool isCommunity;
  final String? userId;

  const FlashcardDetailAdminPage({
    super.key,
    required this.setId,
    required this.data,
    required this.isCommunity,
    required this.userId,
  });

  @override
  State<FlashcardDetailAdminPage> createState() =>
      _FlashcardDetailAdminPageState();
}

class _FlashcardDetailAdminPageState extends State<FlashcardDetailAdminPage> {

  DocumentReference get _docRef {
    if (widget.isCommunity) {
      return FirebaseFirestore.instance
          .collection("flashcard_sets")
          .doc(widget.setId);
    }
    return FirebaseFirestore.instance
        .collection("flashcards")
        .doc(widget.userId)
        .collection("userFlashcards")
        .doc(widget.setId);
  }

  @override
  Widget build(BuildContext context) {
    final readOnly = !widget.isCommunity;

    return Scaffold(
      backgroundColor: const Color(0xffF4F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: Row(
          children: [
            const Text(
              "Flashcard Set",
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: widget.isCommunity
                    ? const Color(0xFF4FC3F7).withOpacity(0.14)
                    : const Color(0xFF81C784).withOpacity(0.14),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                widget.isCommunity ? "COMMUNITY" : "PERSONAL",
                style: TextStyle(
                  color: widget.isCommunity
                      ? const Color(0xFF0288D1)
                      : const Color(0xFF388E3C),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
            if (readOnly) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Text(
                  "READ-ONLY",
                  style: TextStyle(
                    color: Colors.black54,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1,
                  ),
                ),
              ),
            ],
          ],
        ),
        actions: [
          if (readOnly)
            IconButton(
              icon: const Icon(Icons.delete, color: Colors.red),
              tooltip: "Delete this set",
              onPressed: _deleteSet,
            ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: _docRef.snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.data!.exists) {
            return const Center(child: Text("Set not found"));
          }

          final data = snap.data!.data() as Map<String, dynamic>;
          final vocab = (data["vocabList"] as List?) ?? [];

          return ListView(
            padding: const EdgeInsets.all(24),
            children: [
              _header(data, vocab.length),
              const SizedBox(height: 20),
              if (readOnly) _readOnlyNotice(),
              if (readOnly) const SizedBox(height: 14),
              _vocabCard(vocab),
            ],
          );
        },
      ),
    );
  }

  // ---------------- HEADER ----------------
  Widget _header(Map<String, dynamic> data, int vocabCount) {
    final title = data["title"] ?? "(no title)";
    final description = data["description"] ?? "";
    final participants = data["participants"] ?? 0;
    final color = widget.isCommunity
        ? const Color(0xFF4FC3F7)
        : const Color(0xFF81C784);

    return Container(
      padding: const EdgeInsets.all(22),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [color, color.withOpacity(0.75)]),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                widget.isCommunity
                    ? Icons.groups_rounded
                    : Icons.person_rounded,
                color: Colors.white,
                size: 18,
              ),
              const SizedBox(width: 6),
              Text(
                widget.isCommunity ? "Community set" : "Personal set",
                style: const TextStyle(
                  color: Colors.white70,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              if (widget.isCommunity)
                IconButton(
                  icon: const Icon(Icons.edit, color: Colors.white),
                  tooltip: "Edit set",
                  onPressed: () => _editSet(title, description),
                ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          if (description.toString().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              description.toString(),
              style: const TextStyle(color: Colors.white70, height: 1.4),
            ),
          ],
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              _metaPill(Icons.style, "$vocabCount words"),
              _metaPill(Icons.group, "$participants participants"),
              if (!widget.isCommunity && widget.userId != null)
                _metaPill(
                  Icons.badge_outlined,
                  "Owner: ${_shortUid(widget.userId!)}",
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _shortUid(String uid) {
    if (uid.length <= 10) return uid;
    return "${uid.substring(0, 10)}…";
  }

  Widget _metaPill(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.22),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 5),
          Text(
            text,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _readOnlyNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.amber.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.amber.withOpacity(0.4)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, color: Colors.amber, size: 20),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              "Personal flashcards belong to the user — admin has view-only access. "
              "Use the delete button in the top bar to remove the entire set if necessary.",
              style: TextStyle(color: Colors.black87, height: 1.4),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- VOCAB CARD ----------------
  Widget _vocabCard(List vocab) {
    final readOnly = !widget.isCommunity;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text(
                "Vocabulary",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const Spacer(),
              if (!readOnly)
                TextButton.icon(
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text("Add word"),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFF4FC3F7),
                  ),
                  onPressed: () => _editVocab(index: null),
                ),
            ],
          ),
          const SizedBox(height: 10),
          if (vocab.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: Text(
                  readOnly
                      ? "This set has no vocabulary yet."
                      : "No vocabulary yet. Click \"Add word\" to start.",
                  style: TextStyle(color: Colors.grey.shade600),
                ),
              ),
            )
          else
            ...List.generate(vocab.length, (i) {
              final v = vocab[i] as Map<String, dynamic>;
              return _vocabRow(i, v, readOnly: readOnly);
            }),
        ],
      ),
    );
  }

  Widget _vocabRow(int index, Map<String, dynamic> v, {required bool readOnly}) {
    final word = v["word"] ?? "";
    final romaji = v["romaji"] ?? "";
    final meaning = v["meaning"] ?? "";
    final example = v["example"] ?? "";
    final exampleMeaning = v["exampleMeaning"] ?? "";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xffF4F8FB),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: const Color(0xFF4FC3F7).withOpacity(0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Center(
                child: Text(
                  "${index + 1}",
                  style: const TextStyle(
                    color: Color(0xFF0288D1),
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Flexible(
                        child: Text(
                          word,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ),
                      if (romaji.toString().isNotEmpty) ...[
                        const SizedBox(width: 8),
                        Text(
                          romaji,
                          style: TextStyle(
                            color: Colors.grey.shade600,
                            fontSize: 12,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ],
                  ),
                  if (meaning.toString().isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      meaning,
                      style: TextStyle(
                        color: Colors.grey.shade800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                  if (example.toString().isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.shade200,
                          width: 1,
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            example,
                            style: const TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                          if (exampleMeaning.toString().isNotEmpty) ...[
                            const SizedBox(height: 3),
                            Text(
                              exampleMeaning,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (!readOnly) ...[
              IconButton(
                icon: const Icon(Icons.edit, color: Colors.blue, size: 20),
                onPressed: () => _editVocab(index: index),
              ),
              IconButton(
                icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                onPressed: () => _deleteVocab(index),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ---------------- EDIT SET (community only) ----------------
  void _editSet(String currentTitle, String currentDescription) {
    final titleCtl = TextEditingController(text: currentTitle);
    final descCtl = TextEditingController(text: currentDescription);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 440,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Edit Set",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              _dialogField(titleCtl, "Title", Icons.title),
              const SizedBox(height: 12),
              _dialogField(
                descCtl,
                "Description",
                Icons.description_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 18),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: const Text(
                      "Cancel",
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.save, color: Colors.white),
                    label: const Text(
                      "Save",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4FC3F7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      await _docRef.update({
                        "title": titleCtl.text.trim(),
                        "description": descCtl.text.trim(),
                      });
                      if (!ctx.mounted) return;
                      Navigator.pop(ctx);
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ---------------- EDIT VOCAB (community only) ----------------
  Future<void> _editVocab({required int? index}) async {
    final docSnap = await _docRef.get();
    final data = (docSnap.data() as Map<String, dynamic>?) ?? {};
    final vocab = List<Map<String, dynamic>>.from(
      (data["vocabList"] as List? ?? [])
          .map((e) => Map<String, dynamic>.from(e)),
    );

    final isEdit = index != null;
    final current = isEdit ? vocab[index] : <String, dynamic>{};

    final wordCtl = TextEditingController(text: current["word"] ?? "");
    final romajiCtl = TextEditingController(text: current["romaji"] ?? "");
    final meaningCtl = TextEditingController(text: current["meaning"] ?? "");
    final exampleCtl = TextEditingController(text: current["example"] ?? "");
    final exampleMeaningCtl =
        TextEditingController(text: current["exampleMeaning"] ?? "");

    if (!mounted) return;
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 480,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEdit ? "Edit Vocabulary" : "Add Vocabulary",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _dialogField(wordCtl, "Word", Icons.text_fields),
                const SizedBox(height: 10),
                _dialogField(
                  romajiCtl,
                  "Pronunciation / Romaji (optional)",
                  Icons.record_voice_over_outlined,
                ),
                const SizedBox(height: 10),
                _dialogField(meaningCtl, "Meaning", Icons.translate),
                const SizedBox(height: 14),
                Text(
                  "Example",
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 8),
                _dialogField(
                  exampleCtl,
                  "Example sentence (optional)",
                  Icons.format_quote,
                  maxLines: 2,
                ),
                const SizedBox(height: 10),
                _dialogField(
                  exampleMeaningCtl,
                  "Example translation (optional)",
                  Icons.chat_bubble_outline,
                  maxLines: 2,
                ),
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      icon: Icon(
                        isEdit ? Icons.save : Icons.add,
                        color: Colors.white,
                      ),
                      label: Text(
                        isEdit ? "Save" : "Add",
                        style: const TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF4FC3F7),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        final w = wordCtl.text.trim();
                        if (w.isEmpty) return;
                        final entry = <String, dynamic>{
                          "word": w,
                          "romaji": romajiCtl.text.trim(),
                          "meaning": meaningCtl.text.trim(),
                          "example": exampleCtl.text.trim(),
                          "exampleMeaning": exampleMeaningCtl.text.trim(),
                        };
                        if (isEdit) {
                          // preserve SRS & other unknown fields
                          vocab[index] = {...vocab[index], ...entry};
                        } else {
                          // init SRS defaults so user app works smoothly
                          entry["imageUrl"] = "";
                          entry["exampleExplain"] = "";
                          entry["ef"] = 2.5;
                          entry["interval"] = 1;
                          entry["repetition"] = 0;
                          entry["nextReview"] =
                              DateTime.now().millisecondsSinceEpoch;
                          vocab.add(entry);
                        }
                        await _docRef.update({"vocabList": vocab});
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- DELETE VOCAB (community only) ----------------
  void _deleteVocab(int index) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text("Delete vocabulary?"),
        content: const Text("This word will be removed from the set."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              final snap = await _docRef.get();
              final data = (snap.data() as Map<String, dynamic>?) ?? {};
              final vocab = List<Map<String, dynamic>>.from(
                (data["vocabList"] as List? ?? [])
                    .map((e) => Map<String, dynamic>.from(e)),
              );
              if (index < vocab.length) vocab.removeAt(index);
              await _docRef.update({"vocabList": vocab});
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- DELETE WHOLE SET (personal — from AppBar) ----------------
  void _deleteSet() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text("Delete this personal set?"),
        content: const Text(
          "The entire set will be permanently removed from this user's account.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await _docRef.delete();
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
              if (!mounted) return;
              Navigator.pop(context);
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _dialogField(
    TextEditingController ctl,
    String label,
    IconData icon, {
    int maxLines = 1,
  }) {
    return TextField(
      controller: ctl,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        filled: true,
        fillColor: const Color(0xffF5F7FA),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
      ),
    );
  }
}
