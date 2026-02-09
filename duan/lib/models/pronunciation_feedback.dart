class PronunciationFeedback {
  final String summaryVN;
  final String summaryEN;
  final List<String> tipsVN;
  final List<String> tipsEN;
  final String nextStepsVN;
  final String nextStepsEN;
  final List<String> improvementFocus;

  const PronunciationFeedback({
    required this.summaryVN,
    required this.summaryEN,
    required this.tipsVN,
    required this.tipsEN,
    required this.nextStepsVN,
    required this.nextStepsEN,
    required this.improvementFocus,
  });

  factory PronunciationFeedback.fromJson(Map<String, dynamic> json) {
    return PronunciationFeedback(
      summaryVN: json['feedbackVN'] as String? ?? '',
      summaryEN: json['feedbackEN'] as String? ?? '',
      tipsVN:
          (json['tipsVN'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      tipsEN:
          (json['tipsEN'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      nextStepsVN: json['nextStepsVN'] as String? ?? '',
      nextStepsEN: json['nextStepsEN'] as String? ?? '',
      improvementFocus:
          (json['improvementFocus'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'feedbackVN': summaryVN,
      'feedbackEN': summaryEN,
      'tipsVN': tipsVN,
      'tipsEN': tipsEN,
      'nextStepsVN': nextStepsVN,
      'nextStepsEN': nextStepsEN,
      'improvementFocus': improvementFocus,
    };
  }
}
