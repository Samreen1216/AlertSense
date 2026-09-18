import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Brand Colors
  static const Color primary = Color(0xFF1A73E8);
  static const Color secondary = Color(0xFF00897B);

  // Backgrounds
  static const Color backgroundLight = Color(0xFFF5F5F5);
  static const Color backgroundDark = Color(0xFF121212);

  // Surfaces
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceDark = Color(0xFF1E1E1E);

  // States
  static const Color error = Color(0xFFB00020);
  static const Color warning = Color(0xFFFF9800);
  static const Color success = Color(0xFF4CAF50);

  // Priorities
  static const Color highRed = Color(0xFFD32F2F);
  static const Color mediumOrange = Color(0xFFF57C00);
  static const Color lowGreen = Color(0xFF388E3C);

  // Sound Categories
  static const Color fireAlarm = Color(0xFFD32F2F);
  static const Color smokeAlarm = Color(0xFFE64A19);
  static const Color emergencySiren = Color(0xFFC2185B);
  static const Color glassBreaking = Color(0xFF7B1FA2);
  static const Color doorbell = Color(0xFF1976D2);
  static const Color knocking = Color(0xFF388E3C);
  static const Color babyCrying = Color(0xFF00796B);
  static const Color dogBarking = Color(0xFFF57C00);
  static const Color vehicleHorn = Color(0xFF5D4037);

  // High Contrast Theme
  static const Color hcBackground = Color(0xFF000000);
  static const Color hcTextPrimary = Color(0xFF39FF14); // Neon Green
  static const Color hcTextSecondary = Color(0xFFFFFF00); // Neon Yellow
  static const Color hcTextTertiary = Color(0xFF00FFFF); // Cyan

  // Color-blind Safe Palette (Blue, Orange, Pink instead of Red/Green)
  static const Color cbSafeHigh = Color(0xFFD81B60); // Pink
  static const Color cbSafeMedium = Color(0xFFF57C00); // Orange
  static const Color cbSafeLow = Color(0xFF1E88E5); // Blue
}
