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
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF0055D4),
        primary: const Color(0xFF0055D4),
        surface: Colors.white,
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

  // ── Dark Theme ───────────────────────────────────────────────────────────────
  static ThemeData getDark() {
    final textTheme = AppTypography.baseTextTheme;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: const Color(0xFF4FC3F7),
        primary: const Color(0xFF4FC3F7),
        surface: const Color(0xFF1E1E1E),
        brightness: Brightness.dark,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF1E2D4A), width: 1.0),
        ),
        elevation: 0,
        color: const Color(0xFF162035),
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
        backgroundColor: const Color(0xFF1E293B),
      ),
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  // ── High Contrast Theme (WCAG AAA) ───────────────────────────────────────────
  static ThemeData getHighContrast() {
    // FontWeight & color overrides retained for AAA legibility.
    // Font SIZE is intentionally absent — delegated to MediaQuery.textScaler.
    final textTheme = AppTypography.baseTextTheme.copyWith(
      headlineLarge: AppTypography.headlineLarge.copyWith(fontWeight: FontWeight.w900, color: Colors.white),
      headlineMedium: AppTypography.headlineMedium.copyWith(fontWeight: FontWeight.w900, color: Colors.white),
      titleLarge: AppTypography.titleLarge.copyWith(fontWeight: FontWeight.w900, color: Colors.white),
      titleMedium: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800, color: Colors.white),
      bodyLarge: AppTypography.bodyLarge.copyWith(fontWeight: FontWeight.w700, color: Colors.white),
      bodyMedium: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w700, color: Colors.white),
      labelLarge: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w900, color: Colors.white),
      labelSmall: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.w800, color: Colors.white),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: Colors.black,
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF00FF41),
        secondary: Color(0xFFFFD600),
        surface: Colors.black,
        onPrimary: Colors.black,
        onSecondary: Colors.black,
        onSurface: Colors.white,
      ),
      textTheme: textTheme,
      cardTheme: CardThemeData(
        color: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white, width: 2),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
            side: const BorderSide(color: Color(0xFF00FF41), width: 2),
          ),
          padding: _minTouchTarget,
          minimumSize: const Size(48, 48),
        ),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: Colors.black,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: const BorderSide(color: Colors.white, width: 2),
        ),
        padding: const EdgeInsets.all(8),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.black,
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Color(0xFF00FF41), width: 2),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: const BorderSide(color: Color(0xFF00FF41), width: 2),
        ),
        backgroundColor: Colors.black,
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
