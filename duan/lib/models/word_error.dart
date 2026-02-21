enum ErrorType { stress, vowel, consonant, omission, insertion, substitution }

class WordError {
  final String word;
  final int position;
  final ErrorType errorType;
  final int severity; // 1-10
  final String? expectedIPA;
  final String? actualIPA;
  final String tip;

  const WordError({
    required this.word,
    required this.position,
    required this.errorType,
    required this.severity,
    this.expectedIPA,
    this.actualIPA,
    required this.tip,
  });

  factory WordError.fromJson(Map<String, dynamic> json) {
    return WordError(
      word: json['word'] as String,
      position: json['position'] as int,
      errorType: _parseErrorType(json['errorType'] as String),
      severity: json['severity'] as int,
      expectedIPA: json['expectedIPA'] as String?,
      actualIPA: json['actualIPA'] as String?,
      tip: json['tip'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'word': word,
      'position': position,
      'errorType': errorType.name,
      'severity': severity,
      'expectedIPA': expectedIPA,
      'actualIPA': actualIPA,
      'tip': tip,
    };
  }

  static ErrorType _parseErrorType(String type) {
    switch (type.toLowerCase()) {
      case 'stress':
        return ErrorType.stress;
      case 'vowel':
        return ErrorType.vowel;
      case 'consonant':
        return ErrorType.consonant;
      case 'omission':
        return ErrorType.omission;
      case 'insertion':
        return ErrorType.insertion;
      case 'substitution':
        return ErrorType.substitution;
      default:
        return ErrorType.vowel;
    }
  }

  String get errorTypeLabel {
    switch (errorType) {
      case ErrorType.stress:
        return 'Stress';
      case ErrorType.vowel:
        return 'Vowel';
      case ErrorType.consonant:
        return 'Consonant';
      case ErrorType.omission:
        return 'Omission';
      case ErrorType.insertion:
        return 'Insertion';
      case ErrorType.substitution:
        return 'Substitution';
    }
  }
}
