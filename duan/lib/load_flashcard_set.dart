import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../firebase_options.dart';

import '../data/flashcard_sets.dart'; // nơi chứa communityFlashcardSets


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Upload Flashcard Sets',
      home: UploadPage(),
    );
  }
}

class UploadPage extends StatelessWidget {
  UploadPage({super.key});

  Future<void> uploadCommunityData() async {
    final firestore = FirebaseFirestore.instance;

    for (var set in communityFlashcardSets) {
      await firestore.collection("flashcard_sets").add({
        "title": set.title,
        "description": set.description,
        "participants": set.participants,
        "isCommunity": true,
        "vocabList": set.vocabList.map((v) => {
          "word": v.word,
          "romaji": v.romaji,
          "meaning": v.meaning,
        }).toList(),
      });
    }

    print("UPLOAD COMPLETE!");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Upload Community Sets"),
        backgroundColor: Colors.orange,
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () async {
            await uploadCommunityData();
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Đã upload thành công lên Firebase!")),
            );
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.orange,
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
          child: const Text(
            "UPLOAD COMMUNITY FLASHCARDS",
            style: TextStyle(fontSize: 16, color: Colors.white),
          ),
        ),
      ),
    );
  }
}