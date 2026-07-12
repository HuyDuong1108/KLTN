import 'dart:convert';
import 'package:http/http.dart' as http;

class WordDictEntry {
  final String word;
  final String? ipa; // e.g. "/ˈfɑː.ðər/"
  final String? audioUrl; // direct MP3 URL

  const WordDictEntry({required this.word, this.ipa, this.audioUrl});
}

class DictionaryApiService {
  DictionaryApiService._();
  static final DictionaryApiService instance = DictionaryApiService._();

  // In-memory cache — avoids re-fetching the same word within a session
  final Map<String, WordDictEntry?> _cache = {};

  Future<WordDictEntry?> lookupWord(String word) async {
    final key = word.toLowerCase().trim();
    if (key.isEmpty) return null;
    if (_cache.containsKey(key)) return _cache[key];

    try {
      final uri = Uri.parse(
        'https://api.dictionaryapi.dev/api/v2/entries/en/$key',
      );
      final response = await http.get(uri).timeout(const Duration(seconds: 8));

      if (response.statusCode != 200) {
        _cache[key] = null;
        return null;
      }

      final list = jsonDecode(response.body) as List<dynamic>;
      if (list.isEmpty) {
        _cache[key] = null;
        return null;
      }

      final entry = list[0] as Map<String, dynamic>;
      final phonetics = entry['phonetics'] as List<dynamic>? ?? [];

      String? ipa;
      String? audioUrl;

      // Pick the first phonetic entry that has both text and non-empty audio
      for (final p in phonetics) {
        final pMap = p as Map<String, dynamic>;
        final text = pMap['text'] as String?;
        final audio = pMap['audio'] as String?;
        ipa ??= (text?.isNotEmpty == true ? text : null);
        audioUrl ??= (audio?.isNotEmpty == true ? audio : null);
        if (ipa != null && audioUrl != null) break;
      }

      final dictEntry = WordDictEntry(word: key, ipa: ipa, audioUrl: audioUrl);
      _cache[key] = dictEntry;
      return dictEntry;
    } catch (_) {
      _cache[key] = null;
      return null;
    }
  }

  /// Look up multiple words in parallel. Returns a map of word → entry (null if not found).
  Future<Map<String, WordDictEntry?>> lookupWords(
    List<String> words,
  ) async {
    final entries = await Future.wait(
      words.map(
        (w) async => MapEntry(w.toLowerCase().trim(), await lookupWord(w)),
      ),
    );
    return Map.fromEntries(entries);
  }
}
