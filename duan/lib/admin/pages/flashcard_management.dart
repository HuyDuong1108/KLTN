import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/admin_table.dart';
import 'flashcard_detail_admin.dart';

class FlashcardManagementPage extends StatefulWidget {
  const FlashcardManagementPage({super.key});

  @override
  State<FlashcardManagementPage> createState() =>
      _FlashcardManagementPageState();
}

class _FlashcardManagementPageState extends State<FlashcardManagementPage> {
  String _search = "";

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xffF4F8FB),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// TITLE + CREATE
          Row(
            children: [
              const Text(
                "Community Flashcards",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.add, color: Colors.white, size: 18),
                label: const Text(
                  "New Set",
                  style: TextStyle(color: Colors.white),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4FC3F7),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16,
                    vertical: 12,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                onPressed: _showCreateDialog,
              ),
            ],
          ),

          const SizedBox(height: 6),

          Text(
            "Admin chỉ quản lý flashcard cộng đồng. Flashcard cá nhân thuộc về người dùng.",
            style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
          ),

          const SizedBox(height: 20),

          /// STATS CARDS
          _buildStatsRow(),

          const SizedBox(height: 20),

          /// SEARCH
          TextField(
            onChanged: (v) => setState(() => _search = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: "Search by title or description...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 16),

          /// TABLE
          Expanded(child: _buildTable()),
        ],
      ),
    );
  }

  // ============================================================
  // STATS
  // ============================================================
  Widget _buildStatsRow() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("flashcard_sets")
          .snapshots(),
      builder: (context, snap) {
        final docs = snap.data?.docs ?? [];
        int totalWords = 0;
        int totalParticipants = 0;
        for (final d in docs) {
          final data = d.data() as Map<String, dynamic>;
          totalWords += (data["vocabList"] as List?)?.length ?? 0;
          final p = data["participants"];
          if (p is num) totalParticipants += p.toInt();
        }

        return Row(
          children: [
            _statCard(
              "Total Sets",
              "${docs.length}",
              const Color(0xFF4FC3F7),
              Icons.groups_rounded,
            ),
            _statCard(
              "Total Words",
              "$totalWords",
              const Color(0xFFFFB74D),
              Icons.translate_rounded,
            ),
            _statCard(
              "Participants",
              "$totalParticipants",
              const Color(0xFF81C784),
              Icons.people_alt_rounded,
            ),
          ],
        );
      },
    );
  }

  Widget _statCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 15),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(colors: [color, color.withOpacity(0.75)]),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.25),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.22),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 4),
                  Text(value,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      )),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // TABLE
  // ============================================================
  Widget _buildTable() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("flashcard_sets")
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final filtered = snap.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final title = (data["title"] ?? "").toString().toLowerCase();
          final desc = (data["description"] ?? "").toString().toLowerCase();
          return title.contains(_search) || desc.contains(_search);
        }).toList();

        if (filtered.isEmpty) {
          return _emptyState(
            snap.data!.docs.isEmpty
                ? "No community sets yet. Click \"New Set\" to create one."
                : "No results match your search.",
          );
        }

        return AdminTable(
          headers: const [
            "Title",
            "Description",
            "Words",
            "Participants",
            "Action",
          ],
          rows: filtered.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final title = data["title"] ?? "(no title)";
            final description = data["description"] ?? "";
            final vocab = (data["vocabList"] as List?)?.length ?? 0;
            final participants = data["participants"] ?? 0;

            return [
              InkWell(
                onTap: () => _openDetail(doc, data),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ),
              Text(
                description.toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.black54),
              ),
              _countChip("$vocab", const Color(0xFFFFB74D)),
              Text("$participants"),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility,
                        color: Colors.teal, size: 20),
                    tooltip: "View",
                    onPressed: () => _openDetail(doc, data),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit,
                        color: Colors.blue, size: 20),
                    tooltip: "Quick edit",
                    onPressed: () => _quickEditSet(doc.reference, data),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete,
                        color: Colors.red, size: 20),
                    tooltip: "Delete",
                    onPressed: () => _confirmDeleteSet(doc.reference, title),
                  ),
                ],
              ),
            ];
          }).toList(),
        );
      },
    );
  }

  // ============================================================
  // HELPERS
  // ============================================================

  void _openDetail(QueryDocumentSnapshot doc, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => FlashcardDetailAdminPage(
          setId: doc.id,
          data: data,
          isCommunity: true,
          userId: null,
        ),
      ),
    );
  }

  Widget _emptyState(String message) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.inbox_outlined,
                size: 52, color: Colors.grey.shade400),
            const SizedBox(height: 10),
            Text(message,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 14)),
          ],
        ),
      ),
    );
  }

  Widget _countChip(String text, Color color) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.15),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          text,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w700,
            fontSize: 12,
          ),
        ),
      ),
    );
  }

  // ---------------- DIALOGS ----------------

  void _showCreateDialog() {
    final titleCtl = TextEditingController();
    final descCtl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 460,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Row(
                children: [
                  Icon(Icons.groups_rounded, color: Color(0xFF4FC3F7)),
                  SizedBox(width: 10),
                  Text(
                    "New Community Set",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
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
              const SizedBox(height: 20),
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
                    icon: const Icon(Icons.check, color: Colors.white),
                    label: const Text(
                      "Create",
                      style: TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4FC3F7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () async {
                      final title = titleCtl.text.trim();
                      if (title.isEmpty) return;
                      await FirebaseFirestore.instance
                          .collection("flashcard_sets")
                          .add({
                        "title": title,
                        "description": descCtl.text.trim(),
                        "vocabList": [],
                        "participants": 0,
                        "isCommunity": true,
                        "createdAt": FieldValue.serverTimestamp(),
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

  void _quickEditSet(DocumentReference ref, Map<String, dynamic> data) {
    final titleCtl = TextEditingController(text: data["title"] ?? "");
    final descCtl = TextEditingController(text: data["description"] ?? "");

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
                "Edit Community Set",
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
              const SizedBox(height: 20),
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
                      await ref.update({
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

  void _confirmDeleteSet(DocumentReference ref, String title) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text("Delete flashcard set?"),
        content: Text(
          "\"$title\" will be permanently deleted. This action cannot be undone.",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () async {
              await ref.delete();
              if (!ctx.mounted) return;
              Navigator.pop(ctx);
            },
            child: const Text("Delete", style: TextStyle(color: Colors.white)),
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
