import 'package:flutter/material.dart';

class AppTypography {
  static const String _fontFamily = 'Inter';

  static TextStyle get headlineLarge => const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 32,
        fontWeight: FontWeight.bold,
      );

  static TextStyle get headlineMedium => const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 24,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get titleLarge => const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 20,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get titleMedium => const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w500,
      );

  static TextStyle get bodyLarge => const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 16,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get bodyMedium => const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w400,
      );

  static TextStyle get labelLarge => const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 14,
        fontWeight: FontWeight.w600,
      );

  static TextStyle get labelSmall => const TextStyle(
        fontFamily: _fontFamily,
        fontSize: 12,
        fontWeight: FontWeight.w500,
      );

  static TextTheme scaledTextTheme(double scaleFactor) {
    return TextTheme(
      headlineLarge: headlineLarge.copyWith(fontSize: headlineLarge.fontSize! * scaleFactor),
      headlineMedium: headlineMedium.copyWith(fontSize: headlineMedium.fontSize! * scaleFactor),
      titleLarge: titleLarge.copyWith(fontSize: titleLarge.fontSize! * scaleFactor),
      titleMedium: titleMedium.copyWith(fontSize: titleMedium.fontSize! * scaleFactor),
      bodyLarge: bodyLarge.copyWith(fontSize: bodyLarge.fontSize! * scaleFactor),
      bodyMedium: bodyMedium.copyWith(fontSize: bodyMedium.fontSize! * scaleFactor),
      labelLarge: labelLarge.copyWith(fontSize: labelLarge.fontSize! * scaleFactor),
      labelSmall: labelSmall.copyWith(fontSize: labelSmall.fontSize! * scaleFactor),
    );
  }
}
