import 'package:flutter/material.dart';

class AvatarSpec {
  const AvatarSpec({
    required this.initials,
    required this.background,
    required this.accent,
    required this.ink,
    required this.seed,
    required this.spark,
  });

  final String initials;
  final Color background;
  final Color accent;
  final Color ink;
  final int seed;
  final bool spark;

  factory AvatarSpec.fromName(String name, {bool spark = false}) {
    final trimmed = name.trim().isEmpty ? 'AI' : name.trim();
    final hash = trimmed.codeUnits.fold<int>(
      17,
      (sum, unit) => (sum * 33 + unit) & 0x7fffffff,
    );
    const palette = <Color>[
      Color(0xFFFFC2D4),
      Color(0xFFC8F2E0),
      Color(0xFFFFF1B8),
      Color(0xFFD4EFFF),
      Color(0xFFE4D7FF),
      Color(0xFFFFD3C4),
    ];
    final parts = trimmed.split(RegExp(r'\s+'));
    final initials = parts.length >= 2
        ? '${_char(parts[0])}${_char(parts[1])}'
        : trimmed.characters.take(2).toString().toUpperCase();
    return AvatarSpec(
      initials: initials,
      background: palette[hash % palette.length],
      accent: palette[(hash ~/ 3) % palette.length],
      ink: const Color(0xFF3A3158),
      seed: hash,
      spark: spark,
    );
  }

  static String _char(String word) {
    if (word.isEmpty) return '';
    return word.characters.first.toUpperCase();
  }
}
