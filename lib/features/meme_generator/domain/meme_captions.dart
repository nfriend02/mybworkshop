/// Top and bottom lines pulled out of a meme request answer.
class MemeCaptions {
  const MemeCaptions({this.top, this.bottom});

  final String? top;
  final String? bottom;
}

/// Reads `**상단 자막:**` and `**하단 자막:**` from Gemini's meme reply.
MemeCaptions parseMemeCaptions(String text) {
  return MemeCaptions(
    top: _pick(text, const ['상단 자막', '상단자막', '위 자막', '윗줄', '위쪽 자막']),
    bottom: _pick(text, const ['하단 자막', '하단자막', '아래 자막', '아랫줄', '아래쪽 자막']),
  );
}

String? _pick(String text, List<String> labels) {
  final joined = labels.map(RegExp.escape).join('|');
  final match = RegExp(
    '(?:\\*\\*)?(?:$joined)(?:\\*\\*)?\\s*[:：]\\s*(.+)',
    multiLine: true,
  ).firstMatch(text);
  if (match == null) return null;
  final cleaned = _clean(match.group(1)!);
  return cleaned.isEmpty ? null : cleaned;
}

String _clean(String raw) {
  var value = raw.trim();
  value = value.replaceAll('*', '');
  value = value.replaceAll(RegExp('^[\\s"“”‘\']+|[\\s"“”‘\']+\$'), '');
  return value.trim();
}
