import 'package:flutter/material.dart';
import 'app_typography.dart';

class AppTheme {
  static const EdgeInsets _minTouchTarget = EdgeInsets.symmetric(horizontal: 24, vertical: 16);

  // ── Light Theme ─────────────────────────────────────────────────────────────
  static ThemeData getLight() {
    final textTheme = AppTypography.baseTextTheme;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: const Color(0xFFF8FAFC),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0062FF),
        primary: const Color(0xFF0062FF),
        secondary: const Color(0xFF06B6D4),
        surface: Colors.white,
        surfaceContainerHighest: const Color(0xFFF1F5F9),
        brightness: Brightness.light,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFE2E8F0), width: 1.0),
        ),
        elevation: 0,
        color: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: _minTouchTarget,
          minimumSize: const Size(48, 48),
          backgroundColor: const Color(0xFF0062FF),
          foregroundColor: Colors.white,
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.all(8),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF0062FF).withValues(alpha: 0.12),
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF0F172A),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Color(0xFFF8FAFC),
        foregroundColor: Color(0xFF0F172A),
        centerTitle: true,
      ),
    );
  }

  // ── Dark Theme ───────────────────────────────────────────────────────────────
  static ThemeData getDark() {
    final textTheme = AppTypography.baseTextTheme;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: const Color(0xFF070F26),
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF38BDF8),
        primary: const Color(0xFF38BDF8),
        secondary: const Color(0xFF818CF8),
        surface: const Color(0xFF111C35),
        surfaceContainerHighest: const Color(0xFF182544),
        brightness: Brightness.dark,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1E2D4E), width: 1.0),
        ),
        elevation: 0,
        color: const Color(0xFF111C35),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: _minTouchTarget,
          minimumSize: const Size(48, 48),
          backgroundColor: const Color(0xFF38BDF8),
          foregroundColor: const Color(0xFF070F26),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.all(8),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF0D1424),
        indicatorColor: const Color(0xFF38BDF8).withValues(alpha: 0.18),
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        backgroundColor: const Color(0xFF1E293B),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Color(0xFF070F26),
        foregroundColor: Colors.white,
        centerTitle: true,
      ),
    );
  }

  // ── High Contrast Theme (WCAG AAA) ───────────────────────────────────────────
  static ThemeData getHighContrast() {
    final textTheme = AppTypography.baseTextTheme.copyWith(
      headlineLarge: AppTypography.headlineLarge.copyWith(fontWeight: FontWeight.w900, color: Colors.white),
      headlineMedium: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w900, color: Colors.white),
      titleLarge: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w900, color: Colors.white),
      titleMedium: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800, color: Colors.white),
      bodyLarge: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700, color: Colors.white),
      bodyMedium: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: const Color(0xFFE2E8F0)),
      labelLarge: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w900, color: Colors.white),
      labelSmall: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w800, color: const Color(0xFFE2E8F0)),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF38BDF8),
        secondary: Color(0xFF818CF8),
        surface: Color(0xFF0D1424),
        surfaceContainerHighest: Color(0xFF131D33),
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: Colors.white,
        outline: Color(0xFF38BDF8),
        outlineVariant: Color(0xFF334155),
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: const Color(0xFF0D1424),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
          ),
          backgroundColor: const Color(0xFF38BDF8),
          foregroundColor: Colors.black,
          padding: _minTouchTarget,
          minimumSize: const Size(48, 48),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: const Color(0xFF0D1424),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.white70, width: 1.5),
        ),
        padding: const EdgeInsets.all(8),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.black,
        indicatorColor: const Color(0xFF38BDF8).withValues(alpha: 0.25),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF38BDF8), width: 1.5),
        ),
        backgroundColor: const Color(0xFF0D1424),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.black,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
    );
  }

  // ── Color-Blind Safe Theme (IBM Palette) ────────────────────────────────────
  static ThemeData getColorBlindSafe() {
    final textTheme = AppTypography.baseTextTheme;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: Color(0xFF0077BB),
        secondary: Color(0xFFEE7733),
        error: Color(0xFFCC3311),
        surface: Colors.white,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFFD0D7DE), width: 1.0),
        ),
        elevation: 0,
        color: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          padding: _minTouchTarget,
          minimumSize: const Size(48, 48),
        ),
      ),
      chipTheme: ChipThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        padding: const EdgeInsets.all(8),
      ),
      navigationBarTheme: NavigationBarThemeData(
        indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
