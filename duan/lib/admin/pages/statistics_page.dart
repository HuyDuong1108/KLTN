import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

class StatisticsPage extends StatelessWidget {
  const StatisticsPage({super.key});

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
            "Statistics Dashboard",
            style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 20),

          /// SUMMARY CARDS
          Row(
            children: [
              statCard("Users", "1,240", const Color(0xFF4FC3F7)),
              statCard("Active Today", "310", const Color(0xFF81C784)),
              statCard("Flashcards", "540", const Color(0xFFFFB74D)),
              statCard("Tests", "120", const Color(0xFFBA68C8)),
            ],
          ),

          const SizedBox(height: 30),

          /// CHART AREA
          Expanded(
            child: Row(
              children: [

                /// USER GROWTH
                Expanded(
                  flex: 2,
                  child: chartCard(
                    "User Growth",
                    LineChart(
                      LineChartData(
                        gridData: const FlGridData(show: true),
                        titlesData: const FlTitlesData(show: true),
                        borderData: FlBorderData(show: false),
                        lineBarsData: [
                          LineChartBarData(
                            spots: const [
                              FlSpot(1, 50),
                              FlSpot(2, 80),
                              FlSpot(3, 120),
                              FlSpot(4, 150),
                              FlSpot(5, 220),
                              FlSpot(6, 300),
                            ],
                            isCurved: true,
                            barWidth: 4,
                            color: const Color(0xFF4FC3F7),
                          )
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                /// PIE CHART
                Expanded(
                  child: chartCard(
                    "Skill Distribution",
                    PieChart(
                      PieChartData(
                        sections: [
                          PieChartSectionData(
                            value: 30,
                            color: const Color(0xFF4FC3F7),
                            title: "Listening",
                          ),
                          PieChartSectionData(
                            value: 25,
                            color: const Color(0xFFFFB74D),
                            title: "Reading",
                          ),
                          PieChartSectionData(
                            value: 20,
                            color: const Color(0xFFBA68C8),
                            title: "Writing",
                          ),
                          PieChartSectionData(
                            value: 25,
                            color: const Color(0xFF81C784),
                            title: "Speaking",
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          /// TOP FLASHCARDS
          Expanded(
            child: chartCard(
              "Top Flashcards",
              ListView(
                children: const [
                  ListTile(
                    leading: Icon(Icons.star, color: Colors.orange),
                    title: Text("Abandon"),
                    subtitle: Text("Learned 340 times"),
                  ),
                  ListTile(
                    leading: Icon(Icons.star, color: Colors.orange),
                    title: Text("Resilient"),
                    subtitle: Text("Learned 290 times"),
                  ),
                  ListTile(
                    leading: Icon(Icons.star, color: Colors.orange),
                    title: Text("Meticulous"),
                    subtitle: Text("Learned 250 times"),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  /// SUMMARY CARD
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
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.3),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
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
                fontSize: 24,
                fontWeight: FontWeight.bold,
              ),
            )
          ],
        ),
      ),
    );
  }

  /// CHART CARD
  Widget chartCard(String title, Widget child) {
    return Container(
      padding: const EdgeInsets.all(20),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [

          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),

          const SizedBox(height: 20),

          Expanded(child: child),
        ],
      ),
    );
  }
}