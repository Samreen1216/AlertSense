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

  /// Canonical base text theme — font sizes are design-token values only.
  /// Actual user-facing scaling is handled exclusively by the MediaQuery
  /// TextScaler in app.dart, preventing exponential double-scaling.
  static TextTheme get baseTextTheme => TextTheme(
        headlineLarge: headlineLarge,
        headlineMedium: headlineMedium,
        titleLarge: titleLarge,
        titleMedium: titleMedium,
        bodyLarge: bodyLarge,
        bodyMedium: bodyMedium,
        labelLarge: labelLarge,
        labelSmall: labelSmall,
      );

  /// Deprecated alias retained for API compatibility.
  /// Returns [baseTextTheme] — the [scaleFactor] parameter is intentionally
  /// ignored because scaling is delegated to MediaQuery.textScaler.
  @Deprecated('Use AppTypography.baseTextTheme. Scaling is handled by MediaQuery.textScaler.')
  static TextTheme scaledTextTheme(double scaleFactor) => baseTextTheme;
}
