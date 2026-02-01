class Vocabulary {
  final String word;
  final String romaji;
  final String meaning;
  final String imageUrl;

  final String example;
  final String exampleMeaning;
  final String exampleExplain;

  // SRS fields
  double ef; // ease factor
  int interval; // số ngày
  int repetition; // số lần lặp thành công
  int nextReview; // epoch ms

  Vocabulary({
    required this.word,
    this.imageUrl = '',
    this.romaji = '',
    this.meaning = '',
    this.example = '',
    this.exampleMeaning = '',
    this.exampleExplain = '',
    double? ef,
    int? interval,
    int? repetition,
    int? nextReview,
  }) : ef = ef ?? 2.5,
       interval = interval ?? 1,
       repetition = repetition ?? 0,
       nextReview = nextReview ?? DateTime.now().millisecondsSinceEpoch;

  // tạo từ Map (Firestore)
  factory Vocabulary.fromMap(Map<String, dynamic> map) {
    return Vocabulary(
      word: map['word'] ?? '',
      romaji: map['romaji'] ?? '',
      meaning: map['meaning'] ?? '',
      imageUrl: map['imageUrl'] ?? '',
      example: map['example'] ?? '',
      exampleMeaning: map['exampleMeaning'] ?? '',
      exampleExplain: map['exampleExplain'] ?? '',
      ef: (map['ef'] != null) ? (map['ef'] as num).toDouble() : 2.5,
      interval: (map['interval'] != null)
          ? (map['interval'] as num).toInt()
          : 1,
      repetition: (map['repetition'] != null)
          ? (map['repetition'] as num).toInt()
          : 0,
      nextReview: (map['nextReview'] != null)
          ? (map['nextReview'] as num).toInt()
          : DateTime.now().millisecondsSinceEpoch,
    );
  }

  // chuyển sang Map để lưu Firestore
  Map<String, dynamic> toJson() {
    return {
      "word": word,
      "romaji": romaji,
      "meaning": meaning,
      "imageUrl": imageUrl,
      "example": example,
      "exampleMeaning": exampleMeaning,
      "exampleExplain": exampleExplain,
      "ef": ef,
      "interval": interval,
      "repetition": repetition,
      "nextReview": nextReview,
    };
  }
}
