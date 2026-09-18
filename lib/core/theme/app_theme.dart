import 'package:flutter/material.dart';
import 'app_typography.dart';

class AppTheme {
  static const EdgeInsets _minTouchTarget = EdgeInsets.symmetric(horizontal: 24, vertical: 16);

  static ThemeData getLight(double textScale) {
    final textTheme = AppTypography.scaledTextTheme(textScale);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 1,
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
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  static ThemeData getDark(double textScale) {
    final textTheme = AppTypography.scaledTextTheme(textScale);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 2,
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
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
      ),
    );
  }

  static ThemeData getHighContrast(double textScale) {
    final baseTextTheme = AppTypography.scaledTextTheme(textScale);
    final textTheme = baseTextTheme.copyWith(
      headlineLarge: baseTextTheme.headlineLarge?.copyWith(fontWeight: FontWeight.w900, color: Colors.white),
      headlineMedium: baseTextTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w900, color: Colors.white),
      titleLarge: baseTextTheme.titleLarge?.copyWith(fontWeight: FontWeight.w900, color: Colors.white),
      titleMedium: baseTextTheme.titleMedium?.copyWith(fontWeight: FontWeight.w800, color: Colors.white),
      bodyLarge: baseTextTheme.bodyLarge?.copyWith(fontWeight: FontWeight.w700, color: Colors.white),
      bodyMedium: baseTextTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w700, color: Colors.white),
      labelLarge: baseTextTheme.labelLarge?.copyWith(fontWeight: FontWeight.w900, color: Colors.white),
      labelSmall: baseTextTheme.labelSmall?.copyWith(fontWeight: FontWeight.w800, color: Colors.white),
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
      appBarTheme: const AppBarTheme(
        elevation: 0,
        backgroundColor: Colors.black,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.white),
      ),
    );
  }

  static ThemeData getColorBlindSafe(double textScale) {
    final textTheme = AppTypography.scaledTextTheme(textScale);
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
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 1,
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
      appBarTheme: const AppBarTheme(
        elevation: 0,
        centerTitle: true,
      ),
    );
  }
}
