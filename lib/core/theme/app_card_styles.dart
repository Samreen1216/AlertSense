import 'package:flutter/material.dart';

/// Central card design system for AlertSense.
/// Ensures consistent 16dp corner radius and 1.0dp subtle border across all cards in the app.
class AppCardStyles {
  static const double borderRadius = 16.0;
  static const double borderWidth = 1.0;

  static BorderRadius get radius => BorderRadius.circular(borderRadius);

  static Color borderColor(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF1E2D4A) : const Color(0xFFE2E8F0);
  }

  static Color cardBackground(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return isDark ? const Color(0xFF162035) : Colors.white;
  }

  static BorderSide borderSide(
    BuildContext context, {
    Color? customColor,
    double? width,
  }) {
    return BorderSide(
      color: customColor ?? borderColor(context),
      width: width ?? borderWidth,
    );
  }

  static RoundedRectangleBorder shape(
    BuildContext context, {
    Color? customBorderColor,
    double? customWidth,
    double? customRadius,
  }) {
    return RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(customRadius ?? borderRadius),
      side: borderSide(context, customColor: customBorderColor, width: customWidth),
    );
  }

  static BoxDecoration decoration(
    BuildContext context, {
    Color? backgroundColor,
    Color? customBorderColor,
    double? customWidth,
    double? customRadius,
    List<BoxShadow>? shadows,
  }) {
    return BoxDecoration(
      color: backgroundColor ?? cardBackground(context),
      borderRadius: BorderRadius.circular(customRadius ?? borderRadius),
      border: Border.all(
        color: customBorderColor ?? borderColor(context),
        width: customWidth ?? borderWidth,
      ),
      boxShadow: shadows,
    );
  }
}
