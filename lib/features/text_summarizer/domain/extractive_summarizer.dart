/// Frequency-based extractive summary. No network required.
class ExtractiveSummarizer {
  static String summarize(String text, {int maxSentences = 3}) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return '';
    final sentences = _sentences(trimmed);
    final limit = maxSentences.clamp(1, 8);
    if (sentences.length <= limit) return sentences.join(' ');

    final freq = <String, int>{};
    for (final sentence in sentences) {
      for (final word in _words(sentence)) {
        freq[word] = (freq[word] ?? 0) + 1;
      }
    }

    final scored = <(int, int)>[];
    for (var i = 0; i < sentences.length; i++) {
      var score = sentences.length - i;
      for (final word in _words(sentences[i])) {
        score += freq[word] ?? 0;
      }
      scored.add((score, i));
    }
    scored.sort((a, b) => b.$1.compareTo(a.$1));
    final picked = scored.take(limit).map((row) => row.$2).toList()..sort();
    return picked.map((index) => sentences[index]).join(' ');
  }

  static List<String> _sentences(String text) {
    return text
        .split(RegExp(r'(?<=[.!?。])\s+|\n+'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
  }

  static Iterable<String> _words(String sentence) {
    return RegExp(r'[A-Za-z0-9가-힣]{2,}')
        .allMatches(sentence.toLowerCase())
        .map((match) => match.group(0)!);
  }
}
