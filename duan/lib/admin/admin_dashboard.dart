import 'package:flutter/material.dart';
import 'widgets/admin_sidebar.dart';
import 'widgets/admin_card.dart';
import 'pages/user_management.dart';
import 'pages/dashboard_home.dart';
import 'pages/flashcard_management.dart';
import 'pages/test_management.dart';
import 'pages/statistics_page.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {

  int selectedIndex = 0;

  final pages = [
    const DashboardHome(),
    const UserManagementPage(),
    const FlashcardManagementPage(),
    const TestManagementPage(),
    const StatisticsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xffF4F8FB),
      body: Row(
        children: [

          /// SIDEBAR
          AdminSidebar(
            onMenuSelected: (index) {
              setState(() {
                selectedIndex = index;
              });
            },
          ),

          /// CONTENT
          Expanded(
            child: pages[selectedIndex],
          )
        ],
      ),
    );
  }
}