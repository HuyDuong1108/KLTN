import 'package:flutter/material.dart';
import '../widgets/admin_table.dart';

class TestManagementPage extends StatefulWidget {
  const TestManagementPage({super.key});

  @override
  State<TestManagementPage> createState() => _TestManagementPageState();
}

class _TestManagementPageState extends State<TestManagementPage>
    with SingleTickerProviderStateMixin {

  late TabController tabController;

  final skills = [
    "Listening",
    "Reading",
    "Writing",
    "Speaking"
  ];

  @override
  void initState() {
    tabController = TabController(length: skills.length, vsync: this);
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: const Color(0xffF4F8FB),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          /// TITLE
          const Text(
            "Test Management",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          /// STAT CARDS
          Row(
            children: [
              statCard("Total", "120", const Color(0xFF4FC3F7)),
              statCard("Listening", "30", const Color(0xFF4FC3F7)),
              statCard("Reading", "35", const Color(0xFFFFB74D)),
              statCard("Writing", "25", const Color(0xFFBA68C8)),
              statCard("Speaking", "30", const Color(0xFF81C784)),
            ],
          ),

          const SizedBox(height: 25),

          /// TABS
          TabBar(
            controller: tabController,
            labelColor: Colors.black,
            tabs: skills.map((e) => Tab(text: e)).toList(),
          ),

          const SizedBox(height: 20),

          /// TABLE
          Expanded(
            child: TabBarView(
              controller: tabController,
              children: [
                buildTable("Listening"),
                buildTable("Reading"),
                buildTable("Writing"),
                buildTable("Speaking"),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget statCard(String title, String value, Color color) {
    return Expanded(
      child: Container(
        margin: const EdgeInsets.only(right: 15),
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [color, color.withOpacity(0.7)],
          ),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Text(
              title,
              style: const TextStyle(color: Colors.white70),
            ),

            const SizedBox(height: 10),

            Text(
              value,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget buildTable(String skill) {
    return AdminTable(
      headers: const [
        "Title",
        "Skill",
        "Level",
        "Questions",
        "Created",
        "Action"
      ],
      rows: [

        [
          const Text("Cambridge Test 1"),
          Text(skill),
          levelBadge("Medium"),
          const Text("40"),
          const Text("12-03-2026"),
          actionButtons(),
        ],

        [
          const Text("Practice Test A"),
          Text(skill),
          levelBadge("Easy"),
          const Text("30"),
          const Text("10-03-2026"),
          actionButtons(),
        ],

        [
          const Text("Mock Test B"),
          Text(skill),
          levelBadge("Hard"),
          const Text("40"),
          const Text("05-03-2026"),
          actionButtons(),
        ],
      ],
    );
  }

  Widget levelBadge(String level) {

    Color color;

    if (level == "Easy") {
      color = Colors.green;
    } else if (level == "Medium") {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        level,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget actionButtons() {
    return Row(
      children: [
        IconButton(
          icon: const Icon(Icons.edit, color: Colors.blue),
          onPressed: () {},
        ),
        IconButton(
          icon: const Icon(Icons.delete, color: Colors.red),
          onPressed: () {},
        ),
      ],
    );
  }
}