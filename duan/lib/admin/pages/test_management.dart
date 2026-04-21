import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/admin_table.dart';
import 'test_detail_admin.dart';
import 'test_results_page.dart';

class TestManagementPage extends StatefulWidget {
  const TestManagementPage({super.key});

  @override
  State<TestManagementPage> createState() => _TestManagementPageState();
}

class _TestManagementPageState extends State<TestManagementPage>
    with SingleTickerProviderStateMixin {

  late TabController tabController;
  String search = "";

  final skills = const [
    _SkillTab("Listening", "listening_tests", Color(0xFF4FC3F7), Icons.headphones),
    _SkillTab("Reading", "reading_tests", Color(0xFFFFB74D), Icons.menu_book),
    _SkillTab("Writing", "writing_tests", Color(0xFFBA68C8), Icons.edit_note),
    _SkillTab("Speaking", null, Color(0xFF81C784), Icons.mic),
  ];

  @override
  void initState() {
    tabController = TabController(length: skills.length, vsync: this);
    tabController.addListener(() => setState(() {}));
    super.initState();
  }

  @override
  void dispose() {
    tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xffF4F8FB),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Row(
            children: [
              const Text(
                "Test Management",
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              if (tabController.index < 3)
                Padding(
                  padding: const EdgeInsets.only(right: 10),
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.add, size: 18, color: Colors.white),
                    label: Text(
                      "New ${skills[tabController.index].label} Test",
                      style: const TextStyle(color: Colors.white),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          skills[tabController.index].color,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () =>
                        _showCreateDialog(skills[tabController.index]),
                  ),
                ),
              ElevatedButton.icon(
                icon: const Icon(Icons.analytics_outlined,
                    size: 18, color: Colors.white),
                label: const Text(
                  "View Results",
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
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => const TestResultsPage(),
                    ),
                  );
                },
              ),
            ],
          ),

          const SizedBox(height: 20),

          /// STAT CARDS (count từ mỗi collection)
          _buildStatCards(),

          const SizedBox(height: 24),

          /// SEARCH
          TextField(
            onChanged: (v) => setState(() => search = v.toLowerCase()),
            decoration: InputDecoration(
              hintText: "Search test by title...",
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: Colors.white,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),

          const SizedBox(height: 20),

          /// TABS
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: tabController,
              labelColor: const Color(0xFF4FC3F7),
              unselectedLabelColor: Colors.grey,
              indicatorColor: const Color(0xFF4FC3F7),
              indicatorWeight: 3,
              tabs: skills.map((s) {
                return Tab(
                  icon: Icon(s.icon, size: 18),
                  text: s.label,
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 16),

          /// TABLE
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: skills.map((s) {
                if (s.label == "Speaking") {
                  return _buildSpeakingCommunity(s);
                }
                if (s.collection == null) {
                  return _buildComingSoon(s);
                }
                return _buildTable(s);
              }).toList(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildStatCards() {
    return Row(
      children: [
        for (final s in skills)
          _StatCard(
            label: s.label,
            collection: s.label == "Speaking" ? "speaking_community" : s.collection,
            color: s.color,
            icon: s.icon,
          ),
      ],
    );
  }

  Widget _buildTable(_SkillTab skill) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection(skill.collection!)
          .snapshots(),
      builder: (context, snap) {
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final filtered = snap.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final title = (data["title"] ?? "").toString().toLowerCase();
          return title.contains(search);
        }).toList();

        if (filtered.isEmpty) {
          return _emptyState("No tests found in ${skill.label}");
        }

        return AdminTable(
          headers: const [
            "Title",
            "Duration",
            "Content",
            "Created",
            "Action",
          ],
          rows: filtered.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final title = data["title"] ?? "(no title)";
            final duration = data["duration"];
            final created = _formatCreated(data["createdAt"]);
            final contentCount = _contentCount(skill.label, data);

            return [
              InkWell(
                onTap: () => _openDetail(skill, doc.id, data),
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Color(0xFF1565C0),
                  ),
                ),
              ),
              Text(duration != null ? "$duration min" : "-"),
              Text(contentCount),
              Text(created),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.visibility, color: Colors.teal),
                    tooltip: "View",
                    onPressed: () => _openDetail(skill, doc.id, data),
                  ),
                  IconButton(
                    icon: const Icon(Icons.edit, color: Colors.blue),
                    tooltip: "Edit",
                    onPressed: () => _showEditDialog(
                      skill,
                      doc.reference,
                      data,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: "Delete",
                    onPressed: () => _confirmDelete(
                      skill.collection!,
                      doc.id,
                      title,
                    ),
                  ),
                ],
              ),
            ];
          }).toList(),
        );
      },
    );
  }

  void _openDetail(_SkillTab skill, String id, Map<String, dynamic> data) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => TestDetailAdminPage(
          skill: skill.label,
          testId: id,
          data: data,
          accentColor: skill.color,
        ),
      ),
    );
  }

  String _contentCount(String skill, Map<String, dynamic> data) {
    if (skill == "Listening") {
      final total = data["totalQuestions"];
      final sections = (data["sections"] as List?)?.length ?? 0;
      return total != null ? "$total Qs • $sections sec" : "$sections sec";
    }
    if (skill == "Reading") {
      final total = data["totalQuestions"];
      final passages = (data["passages"] as List?)?.length ?? 0;
      return total != null ? "$total Qs • $passages psg" : "$passages psg";
    }
    if (skill == "Writing") {
      final tasks = (data["tasks"] as List?)?.length ?? 0;
      return "$tasks tasks";
    }
    return "-";
  }

  String _formatCreated(dynamic createdAt) {
    if (createdAt is Timestamp) {
      final d = createdAt.toDate();
      return "${d.day.toString().padLeft(2, '0')}-${d.month.toString().padLeft(2, '0')}-${d.year}";
    }
    return "-";
  }

  // ---------------- CREATE TEST ----------------
  void _showCreateDialog(_SkillTab skill) {
    final titleCtl = TextEditingController();
    final durationCtl = TextEditingController(
      text: skill.label == "Writing" ? "60" : "30",
    );
    final totalQuestionsCtl = TextEditingController(text: "40");
    final audioUrlCtl = TextEditingController();
    final isWriting = skill.label == "Writing";
    final isListening = skill.label == "Listening";

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
                Row(
                  children: [
                    Icon(skill.icon, color: skill.color),
                    const SizedBox(width: 10),
                    Text(
                      "New ${skill.label} Test",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  "The test will be created with empty content. "
                  "You can fill in ${isWriting ? 'tasks' : isListening ? 'sections' : 'passages'} "
                  "from the detail page after creation, or via the Firestore console.",
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 12),
                ),
                const SizedBox(height: 16),
                _dialogField(titleCtl, "Title", Icons.title),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _dialogField(
                        durationCtl,
                        "Duration (minutes)",
                        Icons.timer_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    if (!isWriting) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: _dialogField(
                          totalQuestionsCtl,
                          "Total questions",
                          Icons.help_outline,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ],
                ),
                if (isListening) ...[
                  const SizedBox(height: 12),
                  _dialogField(
                    audioUrlCtl,
                    "Audio URL (optional)",
                    Icons.music_note,
                  ),
                ],
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
                      icon: const Icon(Icons.check, color: Colors.white),
                      label: const Text(
                        "Create",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: skill.color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        final title = titleCtl.text.trim();
                        if (title.isEmpty) return;

                        final payload = <String, dynamic>{
                          "title": title,
                          "duration":
                              int.tryParse(durationCtl.text.trim()) ?? 30,
                          "createdAt": FieldValue.serverTimestamp(),
                        };

                        if (isWriting) {
                          payload["tasks"] = [];
                        } else if (isListening) {
                          payload["totalQuestions"] =
                              int.tryParse(totalQuestionsCtl.text.trim()) ?? 0;
                          payload["audioUrl"] = audioUrlCtl.text.trim();
                          payload["sections"] = [];
                        } else {
                          // Reading
                          payload["totalQuestions"] =
                              int.tryParse(totalQuestionsCtl.text.trim()) ?? 0;
                          payload["passages"] = [];
                        }

                        await FirebaseFirestore.instance
                            .collection(skill.collection!)
                            .add(payload);
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

  // ---------------- EDIT TEST ----------------
  void _showEditDialog(
    _SkillTab skill,
    DocumentReference ref,
    Map<String, dynamic> data,
  ) {
    final titleCtl = TextEditingController(text: data["title"] ?? "");
    final durationCtl = TextEditingController(
      text: (data["duration"] ?? "").toString(),
    );
    final totalQuestionsCtl = TextEditingController(
      text: (data["totalQuestions"] ?? "").toString(),
    );
    final audioUrlCtl = TextEditingController(text: data["audioUrl"] ?? "");
    final isWriting = skill.label == "Writing";
    final isListening = skill.label == "Listening";

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
                  "Edit ${skill.label} Test",
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _dialogField(titleCtl, "Title", Icons.title),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _dialogField(
                        durationCtl,
                        "Duration (minutes)",
                        Icons.timer_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    if (!isWriting) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: _dialogField(
                          totalQuestionsCtl,
                          "Total questions",
                          Icons.help_outline,
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ],
                ),
                if (isListening) ...[
                  const SizedBox(height: 12),
                  _dialogField(
                    audioUrlCtl,
                    "Audio URL",
                    Icons.music_note,
                  ),
                ],
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
                        backgroundColor: skill.color,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        final payload = <String, dynamic>{
                          "title": titleCtl.text.trim(),
                          "duration":
                              int.tryParse(durationCtl.text.trim()) ??
                                  (data["duration"] ?? 30),
                        };
                        if (!isWriting) {
                          payload["totalQuestions"] = int.tryParse(
                                totalQuestionsCtl.text.trim(),
                              ) ??
                              (data["totalQuestions"] ?? 0);
                        }
                        if (isListening) {
                          payload["audioUrl"] = audioUrlCtl.text.trim();
                        }
                        await ref.update(payload);
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

  Widget _dialogField(
    TextEditingController ctl,
    String label,
    IconData icon, {
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return TextField(
      controller: ctl,
      maxLines: maxLines,
      keyboardType: keyboardType,
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

  void _confirmDelete(String collection, String docId, String title) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(28),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.delete_outline,
                  color: Colors.red,
                  size: 36,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                "Delete Test",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                "Are you sure you want to delete\n\"$title\"?\nThis action cannot be undone.",
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.grey, height: 1.4),
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text(
                        "Cancel",
                        style: TextStyle(color: Colors.grey),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      icon: const Icon(Icons.delete, color: Colors.white),
                      label: const Text(
                        "Delete",
                        style: TextStyle(color: Colors.white),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection(collection)
                            .doc(docId)
                            .delete();
                        if (!ctx.mounted) return;
                        Navigator.pop(ctx);
                      },
                    ),
                  ),
                ],
              ),
            ],
          ),
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
            Icon(
              Icons.inbox_rounded,
              size: 60,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 10),
            Text(
              message,
              style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SPEAKING COMMUNITY (moderation)
  // ============================================================
  Widget _buildSpeakingCommunity(_SkillTab skill) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("speaking_community")
          .snapshots(),
      builder: (context, snap) {
        if (snap.hasError) {
          return _emptyState("Error: ${snap.error}");
        }
        if (!snap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snap.data!.docs.toList()
          ..sort((a, b) {
            final am = a.data() as Map<String, dynamic>;
            final bm = b.data() as Map<String, dynamic>;
            final at = am["timestampMs"];
            final bt = bm["timestampMs"];
            if (at is num && bt is num) return bt.toInt() - at.toInt();
            return 0;
          });

        final filtered = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final t = (data["topic"] ?? "").toString().toLowerCase();
          final ts = (data["transcript"] ?? "").toString().toLowerCase();
          return t.contains(search) || ts.contains(search);
        }).toList();

        if (filtered.isEmpty) {
          return _emptyState("No speaking posts yet");
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.all(14),
          child: ListView.separated(
            itemCount: filtered.length,
            separatorBuilder: (_, __) => const Divider(height: 20),
            itemBuilder: (context, i) {
              final doc = filtered[i];
              final data = doc.data() as Map<String, dynamic>;
              final topic = (data["topic"] ?? "(no topic)").toString();
              final transcript = (data["transcript"] ?? "").toString();
              final band = (data["bandScore"] ?? 0);
              final uid = (data["userId"] ?? "").toString();
              final ts = data["timestampMs"];
              DateTime? when;
              if (ts is num) {
                when = DateTime.fromMillisecondsSinceEpoch(ts.toInt());
              }
              final duration = data["durationSeconds"];

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: skill.color.withOpacity(0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(Icons.mic, color: skill.color, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  topic,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFB74D)
                                      .withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.star,
                                      color: Color(0xFFE65100),
                                      size: 12,
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      "Band ${band is num ? band.toStringAsFixed(1) : band}",
                                      style: const TextStyle(
                                        color: Color(0xFFE65100),
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                Icons.person_outline,
                                size: 13,
                                color: Colors.grey.shade500,
                              ),
                              const SizedBox(width: 3),
                              Text(
                                uid.isEmpty
                                    ? "anonymous"
                                    : (uid.length > 10
                                        ? "${uid.substring(0, 10)}…"
                                        : uid),
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 11,
                                ),
                              ),
                              if (when != null) ...[
                                const SizedBox(width: 10),
                                Icon(
                                  Icons.schedule,
                                  size: 13,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  _formatWhen(when),
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                              if (duration is num) ...[
                                const SizedBox(width: 10),
                                Icon(
                                  Icons.timer_outlined,
                                  size: 13,
                                  color: Colors.grey.shade500,
                                ),
                                const SizedBox(width: 3),
                                Text(
                                  "${duration.toInt()}s",
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 11,
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (transcript.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: const Color(0xffF4F8FB),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                transcript,
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  fontSize: 13,
                                  height: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      tooltip: "Remove post",
                      onPressed: () => _confirmDeletePost(doc.reference, topic),
                    ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }

  String _formatWhen(DateTime d) {
    final diff = DateTime.now().difference(d);
    if (diff.inMinutes < 1) return "just now";
    if (diff.inMinutes < 60) return "${diff.inMinutes}m ago";
    if (diff.inHours < 24) return "${diff.inHours}h ago";
    if (diff.inDays < 30) return "${diff.inDays}d ago";
    return "${d.day}/${d.month}/${d.year}";
  }

  void _confirmDeletePost(DocumentReference ref, String topic) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        title: const Text("Remove speaking post?"),
        content: Text(
          "\"$topic\" will be permanently removed from the community feed.",
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
            child: const Text(
              "Remove",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoon(_SkillTab skill) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: skill.color.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: Icon(skill.icon, size: 40, color: skill.color),
            ),
            const SizedBox(height: 20),
            Text(
              "${skill.label} Tests",
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              "Coming soon",
              style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String? collection;
  final Color color;
  final IconData icon;

  const _StatCard({
    required this.label,
    required this.collection,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 15),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.75)],
          ),
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
                  Text(
                    label,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 6),
                  if (collection == null)
                    const Text(
                      "—",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  else
                    StreamBuilder<QuerySnapshot>(
                      stream: FirebaseFirestore.instance
                          .collection(collection!)
                          .snapshots(),
                      builder: (context, snap) {
                        final count = snap.data?.docs.length ?? 0;
                        return Text(
                          "$count",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SkillTab {
  final String label;
  final String? collection;
  final Color color;
  final IconData icon;
  const _SkillTab(this.label, this.collection, this.color, this.icon);
}
