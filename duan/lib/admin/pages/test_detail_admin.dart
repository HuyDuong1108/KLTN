import 'package:flutter/material.dart';

class TestDetailAdminPage extends StatelessWidget {
  final String skill;
  final String testId;
  final Map<String, dynamic> data;
  final Color accentColor;

  const TestDetailAdminPage({
    super.key,
    required this.skill,
    required this.testId,
    required this.data,
    required this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final title = data["title"] ?? "(no title)";

    return Scaffold(
      backgroundColor: const Color(0xffF4F8FB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        foregroundColor: Colors.black87,
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          _headerCard(title),
          const SizedBox(height: 20),
          ..._buildSkillContent(),
        ],
      ),
    );
  }

  Widget _headerCard(String title) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [accentColor, accentColor.withOpacity(0.75)],
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.22),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  skill.toUpperCase(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.2,
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                "ID: $testId",
                style: const TextStyle(color: Colors.white70, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _metaChip(
                Icons.timer_outlined,
                data["duration"] != null ? "${data["duration"]} min" : "-",
              ),
              const SizedBox(width: 10),
              if (data["totalQuestions"] != null)
                _metaChip(
                  Icons.help_outline,
                  "${data["totalQuestions"]} questions",
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _metaChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 12),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildSkillContent() {
    if (skill == "Listening") return _listeningContent();
    if (skill == "Reading") return _readingContent();
    if (skill == "Writing") return _writingContent();
    return [const SizedBox.shrink()];
  }

  List<Widget> _listeningContent() {
    final widgets = <Widget>[];
    final audio = data["audioUrl"];

    if (audio != null && audio.toString().isNotEmpty) {
      widgets.add(_infoRow("Audio URL", audio.toString(), Icons.music_note));
      widgets.add(const SizedBox(height: 20));
    }

    final sections = (data["sections"] as List?) ?? [];
    widgets.add(_sectionTitle("Sections (${sections.length})"));

    for (int i = 0; i < sections.length; i++) {
      final sec = sections[i] as Map<String, dynamic>;
      final type = sec["type"] ?? "";
      final qs = (sec["questions"] as List?) ?? [];

      widgets.add(_card([
        Row(
          children: [
            _tag("Section ${sec["section"] ?? i + 1}", accentColor),
            const SizedBox(width: 8),
            _tag(type.toString().toUpperCase(), Colors.grey),
          ],
        ),
        const SizedBox(height: 12),
        for (int j = 0; j < qs.length; j++)
          _questionTile(j + 1, qs[j] as Map<String, dynamic>),
      ]));
      widgets.add(const SizedBox(height: 14));
    }

    return widgets;
  }

  List<Widget> _readingContent() {
    final widgets = <Widget>[];
    final passages = (data["passages"] as List?) ?? [];

    widgets.add(_sectionTitle("Passages (${passages.length})"));

    for (final p in passages) {
      final pass = p as Map<String, dynamic>;
      final qs = (pass["questions"] as List?) ?? [];

      widgets.add(_card([
        Row(
          children: [
            _tag("Passage ${pass["id"] ?? "-"}", accentColor),
            const SizedBox(width: 8),
            _tag("${qs.length} questions", Colors.grey),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          pass["title"] ?? "",
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        Text(
          pass["content"]?.toString() ?? "",
          maxLines: 6,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(color: Colors.black87, height: 1.5),
        ),
        if ((pass["content"]?.toString().length ?? 0) > 300)
          const Padding(
            padding: EdgeInsets.only(top: 6),
            child: Text(
              "... (truncated)",
              style: TextStyle(color: Colors.grey, fontSize: 12),
            ),
          ),
        const Divider(height: 28),
        for (int j = 0; j < qs.length; j++)
          _questionTile(j + 1, qs[j] as Map<String, dynamic>),
      ]));
      widgets.add(const SizedBox(height: 14));
    }

    return widgets;
  }

  List<Widget> _writingContent() {
    final widgets = <Widget>[];
    final tasks = (data["tasks"] as List?) ?? [];

    widgets.add(_sectionTitle("Tasks (${tasks.length})"));

    for (final t in tasks) {
      final task = t as Map<String, dynamic>;
      widgets.add(_card([
        Row(
          children: [
            _tag(task["taskId"]?.toString() ?? "-", accentColor),
            const SizedBox(width: 8),
            _tag("min ${task["minWords"] ?? "-"} words", Colors.grey),
            if (task["imageType"] != null) ...[
              const SizedBox(width: 8),
              _tag(task["imageType"].toString(), Colors.orange),
            ],
          ],
        ),
        const SizedBox(height: 12),
        Text(
          task["question"]?.toString() ?? "",
          style: const TextStyle(height: 1.5),
        ),
        if (task["imageAsset"] != null) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xffF4F8FB),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                const Icon(Icons.image_outlined, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    task["imageAsset"].toString(),
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.black54,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ]));
      widgets.add(const SizedBox(height: 14));
    }

    return widgets;
  }

  Widget _questionTile(int index, Map<String, dynamic> q) {
    final type = q["type"]?.toString() ?? "";
    final text = q["question"]?.toString() ?? q["label"]?.toString() ?? "";
    final options = (q["options"] as List?) ?? [];
    final answer = q["answer"];
    final correctIndex = q["correctIndex"];

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: accentColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Center(
                  child: Text(
                    "$index",
                    style: TextStyle(
                      color: accentColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  style: const TextStyle(height: 1.4),
                ),
              ),
              if (type.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.only(left: 6),
                  child: _tag(type.toUpperCase(), Colors.grey, small: true),
                ),
            ],
          ),
          if (options.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(34, 6, 0, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: List.generate(options.length, (k) {
                  final isCorrect = correctIndex == k;
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      children: [
                        Icon(
                          isCorrect
                              ? Icons.check_circle
                              : Icons.radio_button_unchecked,
                          size: 14,
                          color: isCorrect ? Colors.green : Colors.grey,
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            options[k].toString(),
                            style: TextStyle(
                              fontSize: 13,
                              color: isCorrect ? Colors.green.shade700 : null,
                              fontWeight: isCorrect
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ),
            ),
          if (answer != null && options.isEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(34, 4, 0, 0),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, size: 14, color: Colors.green),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      "Answer: ${answer.toString()}",
                      style: TextStyle(
                        color: Colors.green.shade700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _sectionTitle(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 4),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _card(List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }

  Widget _tag(String text, Color color, {bool small = false}) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: small ? 6 : 10,
        vertical: small ? 2 : 4,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: small ? 10 : 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: accentColor),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: Colors.grey,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
