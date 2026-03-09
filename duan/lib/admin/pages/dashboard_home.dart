import 'package:flutter/material.dart';
import '../widgets/admin_card.dart';

class DashboardHome extends StatelessWidget {
  const DashboardHome({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          const Text(
            "Admin Dashboard",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 30),

          Row(
            children: const [

              AdminCard(
                title: "Users",
                value: "120",
                icon: Icons.people,
              ),

              SizedBox(width: 20),

              AdminCard(
                title: "Flashcards",
                value: "540",
                icon: Icons.style,
              ),

              SizedBox(width: 20),

              AdminCard(
                title: "Tests",
                value: "85",
                icon: Icons.quiz,
              ),

              SizedBox(width: 20),

              AdminCard(
                title: "Active Today",
                value: "42",
                icon: Icons.bar_chart,
              ),
            ],
          ),

          const SizedBox(height: 30),

          Expanded(
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Center(
                child: Text(
                  "Recent Activities",
                  style: TextStyle(fontSize: 18),
                ),
              ),
            ),
          )
        ],
      ),
    );
  }
}