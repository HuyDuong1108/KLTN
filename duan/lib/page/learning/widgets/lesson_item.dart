import 'package:flutter/material.dart';

class LessonItem extends StatelessWidget {
  final String title;
  final bool completed;
  final VoidCallback onTap;

  const LessonItem({
    super.key,
    required this.title,
    required this.completed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 5,
                offset: const Offset(0, 3))
          ],
        ),
        child: Row(
          children: [
            Icon(
              completed ? Icons.check_circle : Icons.play_circle,
              color: completed ? Colors.green : Colors.deepOrange,
            ),
            const SizedBox(width: 12),
            Text(title,
                style:
                    const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const Spacer(),
            const Icon(Icons.arrow_forward_ios, size: 16)
          ],
        ),
      ),
    );
  }
}
