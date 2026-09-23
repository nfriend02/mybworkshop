import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bright pastel workshop theme.
class AppTheme {
  static const Color bg = Color(0xFFFFF7FB);
  static const Color surface = Color(0xFFFFFFFF);
  static const Color ink = Color(0xFF3A3158);
  static const Color muted = Color(0xFF7A7194);
  static const Color coral = Color(0xFFFF8BA7);
  static const Color peach = Color(0xFFFFD3C4);
  static const Color mint = Color(0xFFC8F2E0);
  static const Color lavender = Color(0xFFE4D7FF);
  static const Color butter = Color(0xFFFFF1B8);
  static const Color sky = Color(0xFFD4EFFF);
  static const Color lilac = Color(0xFFB9A6FF);
  static const Color border = Color(0xFFF0E4F4);

  static ThemeData light() {
    final base = ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: bg,
      colorScheme: const ColorScheme.light(
        primary: coral,
        secondary: lilac,
        surface: surface,
        onPrimary: Colors.white,
        onSurface: ink,
      ),
    );

    final text = GoogleFonts.notoSansKrTextTheme(base.textTheme).apply(
      bodyColor: ink,
      displayColor: ink,
    );

    return base.copyWith(
      textTheme: text,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: ink,
        titleTextStyle: GoogleFonts.notoSansKr(
          fontSize: 18,
          fontWeight: FontWeight.w800,
          color: ink,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(22),
          side: const BorderSide(color: border),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFFFFCFE),
        hintStyle: const TextStyle(color: muted),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: coral, width: 1.6),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: coral,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          textStyle: GoogleFonts.notoSansKr(fontWeight: FontWeight.w800),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: ink,
          side: const BorderSide(color: Color(0xFFE4D4EE)),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
        ),
      ),
      dividerColor: border,
    );
  }

  static BoxDecoration pageBackground() {
    return const BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFFFFF1F6),
          Color(0xFFF4F8FF),
          Color(0xFFF3FFF8),
        ],
      ),
    );
  }

  static BoxDecoration card({Color? tint}) {
    return BoxDecoration(
      color: surface,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: border),
      boxShadow: [
        BoxShadow(
          color: (tint ?? coral).withValues(alpha: 0.16),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }
}
