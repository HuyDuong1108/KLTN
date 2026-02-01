import 'package:flutter/material.dart';

class LanguageTestConfig {
  final String languageCode; // ja / ko / zh
  final String title;
  final List<Color> gradient;
  final String firestoreField;
  final List<Map<String, dynamic>> questions;

  const LanguageTestConfig({
    required this.languageCode,
    required this.title,
    required this.gradient,
    required this.firestoreField,
    required this.questions,
  });
}
