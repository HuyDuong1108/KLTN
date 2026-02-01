class DueCardMatch {
  final String tab; // personal|community
  final String setId;
  final String setTitle;
  final String word;
  final String? reading;
  final String? meaning;

  DueCardMatch({
    required this.tab,
    required this.setId,
    required this.setTitle,
    required this.word,
    this.reading,
    this.meaning,
  });

  factory DueCardMatch.fromJson(Map<String, dynamic> j) => DueCardMatch(
        tab: (j['tab'] ?? '').toString(),
        setId: (j['setId'] ?? '').toString(),
        setTitle: (j['setTitle'] ?? '').toString(),
        word: (j['word'] ?? '').toString(),
        reading: j['reading']?.toString(),
        meaning: j['meaning']?.toString(),
      );
}

class DueCardDetailItem {
  final String cardId;
  final String? due; // ISO string
  final String state;
  final List<DueCardMatch> matches;

  DueCardDetailItem({
    required this.cardId,
    required this.state,
    this.due,
    required this.matches,
  });

  factory DueCardDetailItem.fromJson(Map<String, dynamic> j) => DueCardDetailItem(
        cardId: (j['cardId'] ?? '').toString(),
        due: j['due']?.toString(),
        state: (j['state'] ?? '').toString(),
        matches: (j['matches'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(DueCardMatch.fromJson)
            .toList(),
      );
}

class DueCardsDetailResponse {
  final String scope; // now|today
  final int total;
  final List<DueCardDetailItem> items;

  DueCardsDetailResponse({
    required this.scope,
    required this.total,
    required this.items,
  });

  factory DueCardsDetailResponse.fromJson(Map<String, dynamic> j) => DueCardsDetailResponse(
        scope: (j['scope'] ?? '').toString(),
        total: (j['total'] is int) ? j['total'] as int : int.tryParse('${j['total']}') ?? 0,
        items: (j['items'] as List? ?? [])
            .whereType<Map<String, dynamic>>()
            .map(DueCardDetailItem.fromJson)
            .toList(),
      );
}
