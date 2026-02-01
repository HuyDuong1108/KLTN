import 'package:flutter/material.dart';
import '../models/vocabulary.dart';

class FlashcardWidget extends StatelessWidget {
  final Vocabulary vocab;
  final bool showMeaning;

  const FlashcardWidget({
    super.key,
    required this.vocab,
    this.showMeaning = false,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Center(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 400),
          transitionBuilder: (child, animation) {
            return ScaleTransition(scale: animation, child: child);
          },
          child: showMeaning
              ? Column(
                  key: const ValueKey("meaning"),
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(vocab.meaning,
                        style: const TextStyle(
                            fontSize: 32, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 10),
                    Text(vocab.romaji,
                        style: const TextStyle(
                            fontSize: 22, color: Colors.deepPurple)),
                  ],
                )
              : Text(
                  vocab.word,
                  key: const ValueKey("word"),
                  style: const TextStyle(
                      fontSize: 64, fontWeight: FontWeight.bold),
                ),
        ),
      ),
    );
  }
}
