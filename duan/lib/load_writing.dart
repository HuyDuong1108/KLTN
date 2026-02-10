import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await seedWritingDataWithAssets();
  runApp(const MyApp());
}

// ======================================================
// APP (CHỈ ĐỂ XÁC NHẬN SEED OK)
// ======================================================
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: Center(
          child: Text(
            "✅ IELTS Writing data (asset images) seeded successfully!",
            style: TextStyle(fontSize: 18),
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}

// ======================================================
// SEED FIRESTORE – IMAGE FROM ASSET
// ======================================================
Future<void> seedWritingDataWithAssets() async {
  final firestore = FirebaseFirestore.instance;
  final testsCollection = firestore.collection('writing_tests');

  final List<Map<String, dynamic>> tests = [
    {
      "id": "test_1",
      "title": "IELTS Writing Test 1",
      "duration": 60,
      "tasks": [
        {
          "taskId": "task1",
          "type": "task1",
          "minWords": 150,
          "imageType": "process_diagram",
          "imageSource": "asset",
          "imageAsset": "lib/image/test1_task1.jpg",
          "question":
"The diagram below show the stages in the recycling of aluminum drinks can. Summarize the information by selecting and reporting the main features, and make comparisons where relevant."        },
        {
          "taskId": "task2",
          "type": "task2",
          "minWords": 250,
          "imageType": null,
          "imageSource": null,
          "imageAsset": null,
          "question":
"The main purpose of advertising is to increase the sales of products that people don’t really need. To what extent do you agree or disagree."        },
      ],
    },
    {
      "id": "test_2",
      "title": "IELTS Writing Test 2",
      "duration": 60,
      "tasks": [
        {
          "taskId": "task1",
          "type": "task1",
          "minWords": 150,
          "imageType": "bar_chart",
          "imageSource": "asset",
          "imageAsset": "lib/image/test2_task1.png",
          "question":
"The table and the chart below provide a breakdown of the total expenditure and the average amount of money spent by students per week while studying abroad in 4 countries. Summarize the information by selecting and reporting the main features, and make comparisons where relevant."        },
        {
          "taskId": "task2",
          "type": "task2",
          "minWords": 250,
          "imageType": null,
          "imageSource": null,
          "imageAsset": null,
          "question":
"Some people think that people should be given the right to use fresh water as they like. Others believe governments should strictly control the use of fresh water. Discuss both views and give your own opinion."        },
      ],
    },
    {
      "id": "test_3",
      "title": "IELTS Writing Test 3",
      "duration": 60,
      "tasks": [
        {
          "taskId": "task1",
          "type": "task1",
          "minWords": 150,
          "imageType": "line_graph",
          "imageSource": "asset",
          "imageAsset": "lib/image/test3_task1.jpg",
          "question":
              "The first graph shows the number of train passengers from 2000 to 2009; the second compares the percentage of trains running on time and target in the period. Summarise the information by selecting and reporting the main features, and make comparisons where relevant.",
        },
        {
          "taskId": "task2",
          "type": "task2",
          "minWords": 250,
          "imageType": null,
          "imageSource": null,
          "imageAsset": null,
          "question":
              "Some people say that the increasing business and cultural contact between countries has positive effects. Others say it would lead to the loss of national identities. Discuss both views and give your opinion.",
        },
      ],
    },
  ];

  for (final test in tests) {
    await testsCollection.doc(test["id"]).set({
      "title": test["title"],
      "duration": test["duration"],
      "createdAt": FieldValue.serverTimestamp(),
      "tasks": test["tasks"],
    });
  }

  debugPrint("🔥 IELTS Writing seed (asset images) DONE");
}
