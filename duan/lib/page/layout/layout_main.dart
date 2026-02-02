import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login.dart';
import '../home_page.dart';
import '../learning/learning_page.dart';
import '../flashcard/flashcard_page.dart';
import '../profile/profile_page.dart';

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _currentIndex = 0;

  final user = FirebaseAuth.instance.currentUser;

  final List<Widget> _pages = [
    const HomePageContent(),
    const LearningPage(),
    const FlashcardPage(),
    const ProfilePage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.blue.shade400,
        title: Text(
          ["Home", "Learning", "Flashcard", "Profile"][_currentIndex],
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.white),
        ),
        
      ),
      body: _pages[_currentIndex],
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: Colors.white, // nền trắng
        elevation: 8,
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Colors.blue.shade400, // khi chọn -> xanh dương
        unselectedItemColor: Colors.grey, // chưa chọn -> xám
        showUnselectedLabels: true,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        items: [
          _navItem(Icons.home, "Home", 0),
          _navItem(Icons.school, "Learning", 1),
          _navItem(Icons.style, "Flashcard", 2),
          _navItem(Icons.person, "Profile", 3),
        ],
      ),
    );
  }

  /// Custom BottomNavigationBarItem có hiệu ứng icon phóng to khi chọn
  BottomNavigationBarItem _navItem(IconData icon, String label, int index) {
    final isSelected = _currentIndex == index;
    return BottomNavigationBarItem(
      label: label,
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        child: Icon(
          icon,
          size: isSelected ? 28 : 24, // khi chọn thì to hơn
        ),
      ),
    );
  }
}
