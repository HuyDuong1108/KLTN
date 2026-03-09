import 'package:flutter/material.dart';
import '../pages/user_management.dart';

class AdminSidebar extends StatelessWidget {

  final Function(int) onMenuSelected;

  const AdminSidebar({super.key, required this.onMenuSelected});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      color: const Color(0xff4A90E2),
      child: Column(
        children: [

          const SizedBox(height: 40),

          const Icon(Icons.school,color: Colors.white,size: 40),

          const SizedBox(height: 40),

          sidebarItem(Icons.dashboard, "Dashboard",0),
          sidebarItem(Icons.people, "Users",1),
          sidebarItem(Icons.style, "Flashcards",2),
          sidebarItem(Icons.quiz, "Tests",3),
          sidebarItem(Icons.bar_chart, "Statistics",4),
        ],
      ),
    );
  }

  Widget sidebarItem(IconData icon,String title,int index){
    return ListTile(
      leading: Icon(icon,color: Colors.white),
      title: Text(title,style: const TextStyle(color: Colors.white)),
      onTap: (){
        onMenuSelected(index);
      },
    );
  }
}