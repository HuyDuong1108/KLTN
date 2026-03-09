import 'package:flutter/material.dart';

class AdminTable extends StatelessWidget {
  final List<String> headers;
  final List<List<Widget>> rows;

  const AdminTable({
    super.key,
    required this.headers,
    required this.rows,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ListView(
        children: [

          /// HEADER
          Row(
            children: headers
                .map(
                  (h) => Expanded(
                    child: Text(
                      h,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),

          const Divider(height: 30),

          /// ROWS
          ...rows.map((row) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 12),
              child: Row(
                children: row
                    .map((cell) => Expanded(child: cell))
                    .toList(),
              ),
            );
          }).toList(),
        ],
      ),
    );
  }
}