import 'dart:convert';

/// Loose JSON action returned by a tool's natural-language request.
class NlpAction {
  const NlpAction({
    required this.tool,
    this.width,
    this.height,
    this.delayMs,
    this.fps,
    this.ratio,
    this.mode,
    this.note = '',
    this.text = '',
    this.kind = '',
    this.chart = '',
    this.style = '',
    this.theme = '',
    this.gain,
    this.speed,
  });

  final String tool;
  final int? width;
  final int? height;
  final int? delayMs;
  final int? fps;
  final String? ratio;
  final String? mode;
  final String note;
  final String text;
  final String kind;
  final String chart;
  final String style;
  final String theme;
  final double? gain;
  final double? speed;

  static NlpAction? tryParse(String raw) {
    final start = raw.indexOf('{');
    final end = raw.lastIndexOf('}');
    if (start < 0 || end <= start) return null;
    try {
      final decoded = jsonDecode(raw.substring(start, end + 1));
      if (decoded is! Map) return null;
      final map = decoded.map((key, value) => MapEntry('$key', value));
      return NlpAction(
        tool: '${map['tool'] ?? ''}'.trim().toLowerCase(),
        width: _int(map['width']),
        height: _int(map['height']),
        delayMs: _int(map['delayMs']),
        fps: _int(map['fps']),
        ratio: _string(map['ratio']),
        mode: _string(map['mode']),
        note: _string(map['note']) ?? '',
        text: _string(map['text']) ?? '',
        kind: _string(map['kind']) ?? '',
        chart: _string(map['chart']) ?? '',
        style: _string(map['style']) ?? '',
        theme: _string(map['theme']) ?? '',
        gain: _double(map['gain']),
        speed: _double(map['speed']),
      );
    } catch (_) {
      return null;
    }
  }

  static int? _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.round();
    return int.tryParse('$value');
  }

  static double? _double(Object? value) {
    if (value is num) return value.toDouble();
    return double.tryParse('$value');
  }

  static String? _string(Object? value) {
    if (value == null) return null;
    final text = '$value'.trim();
    return text.isEmpty ? null : text;
  }
}
