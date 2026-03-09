import 'package:flutter/material.dart';
import '../widgets/admin_table.dart';

class FlashcardManagementPage extends StatelessWidget {
  const FlashcardManagementPage({super.key});

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
            "Flashcard Management",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          /// STAT CARDS
          Row(
            children: [
              statCard("Total", "540", const Color(0xFF4FC3F7)),
              statCard("Community", "300", const Color(0xFF81C784)),
              statCard("Personal", "240", const Color(0xFFFFB74D)),
            ],
          ),

          const SizedBox(height: 25),

          /// SEARCH + FILTER
          Row(
            children: [

              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: "Search flashcard...",
                    prefixIcon: const Icon(Icons.search),
                    filled: true,
                    fillColor: Colors.white,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
              ),

              const SizedBox(width: 20),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: DropdownButtonHideUnderline(
                  child: DropdownButton(
                    value: "All",
                    items: const [
                      DropdownMenuItem(value: "All", child: Text("All")),
                      DropdownMenuItem(value: "Community", child: Text("Community")),
                      DropdownMenuItem(value: "Personal", child: Text("Personal")),
                    ],
                    onChanged: (value) {},
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 25),

          /// TABLE
          Expanded(
            child: AdminTable(
              headers: const [
                "Word",
                "Meaning",
                "Type",
                "User",
                "Created",
                "Action",
              ],
              rows: [

                [
                  const Text("abandon"),
                  const Text("từ bỏ"),
                  typeBadge("community"),
                  const Text("-"),
                  const Text("12-03-2026"),
                  actionButtons(),
                ],

                [
                  const Text("resilient"),
                  const Text("kiên cường"),
                  typeBadge("personal"),
                  const Text("user123"),
                  const Text("10-03-2026"),
                  actionButtons(),
                ],

                [
                  const Text("meticulous"),
                  const Text("tỉ mỉ"),
                  typeBadge("community"),
                  const Text("-"),
                  const Text("08-03-2026"),
                  actionButtons(),
                ],
              ],
            ),
          )
        ],
      ),
    );
  }

  /// STAT CARD
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

  /// BADGE TYPE
  Widget typeBadge(String type) {
    Color color = type == "community"
        ? const Color(0xFF4FC3F7)
        : const Color(0xFF81C784);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        type,
        style: TextStyle(
          color: color,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  /// ACTION
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