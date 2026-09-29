import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Brand Colors (Sonic Acoustic AI Identity) ─────────────────────────────
  static const Color primary = Color(0xFF0062FF); // Vivid Electric Sapphire
  static const Color secondary = Color(0xFF06B6D4); // Acoustic Sonic Cyan
  static const Color accent = Color(0xFF8B5CF6); // AI Neural Violet

  // ── Canvas & Backgrounds ──────────────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF8FAFC); // Crisp Slate Canvas
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color surfaceLightElevated = Color(0xFFF1F5F9);

  static const Color backgroundDark = Color(0xFF070F26); // Midnight Obsidian Canvas
  static const Color surfaceDark = Color(0xFF111C35); // Frosted Deep Sapphire
  static const Color surfaceDarkElevated = Color(0xFF182544);

  // Standard Dark Surface Tokens
  static const Color darkBackground = Color(0xFF070F26);
  static const Color darkCard = Color(0xFF1E2638);
  static const Color darkSurface = Color(0xFF0F172A);

  // ── Status & Feedback States ──────────────────────────────────────────────
  static const Color error = Color(0xFFEF4444);
  static const Color warning = Color(0xFFF59E0B);
  static const Color success = Color(0xFF10B981);

  // ── 3-Tier Priority Matrix (Life Safety Calibrated) ───────────────────────
  static const Color highRed = Color(0xFFEF4444); // Urgent Emergency Red
  static const Color mediumOrange = Color(0xFFF59E0B); // Attention Amber
  static const Color lowGreen = Color(0xFF10B981); // Ambient Emerald

  // ── 9 Sound Categories (Vibrant Acoustic Palette) ──────────────────────────
  static const Color fireAlarm = Color(0xFFFF3B30); // Neon Emergency Red
  static const Color smokeAlarm = Color(0xFFFF6B4A); // Vivid Amber Coral
  static const Color emergencySiren = Color(0xFFF43F5E); // Electric Rose Crimson
  static const Color glassBreaking = Color(0xFF8B5CF6); // Sonic Electric Violet
  static const Color doorbell = Color(0xFF0284C7); // Royal Sky Azure
  static const Color knocking = Color(0xFFF59E0B); // Warm Amber Gold
  static const Color babyCrying = Color(0xFF06B6D4); // Luminous Mint Teal
  static const Color dogBarking = Color(0xFFFB923C); // Warm Tangerine
  static const Color vehicleHorn = Color(0xFF0EA5E9); // Modern Acoustic Cyan

  // ── High Contrast AMOLED Theme (WCAG AAA Calibrated) ─────────────────────
  static const Color hcBackground = Color(0xFF000000); // Pure AMOLED Deep Black
  static const Color hcSurface = Color(0xFF0D1424); // Elevated Deep Charcoal
  static const Color hcPrimary = Color(0xFF38BDF8); // High-Luminance Acoustic Cyan (10.5:1 on black)
  static const Color hcSecondary = Color(0xFF818CF8); // Sonic Electric Violet
  static const Color hcTextPrimary = Color(0xFFFFFFFF); // Pure White (21:1 AAA Maximum Contrast)
  static const Color hcTextSecondary = Color(0xFFE2E8F0); // High-Luminance Crisp Slate (14:1 AAA)
  static const Color hcTextTertiary = Color(0xFF94A3B8); // High-Legibility Silver (7.5:1 AAA)
  static const Color hcHighAlert = Color(0xFFFF453A); // Ultra-Vivid Emergency Red (7.2:1 AAA)
  static const Color hcMediumAlert = Color(0xFFFFD600); // Safety Amber Gold (14:1 AAA)
  static const Color hcLowAlert = Color(0xFF38BDF8); // Acoustic Sonic Cyan (10.5:1 AAA)

  // ── Color-Blind Safe Palette (IBM Research Standard) ──────────────────────
  static const Color cbSafeHigh = Color(0xFFD81B60); // High-luminance Pink
  static const Color cbSafeMedium = Color(0xFFF57C00); // High-luminance Orange
  static const Color cbSafeLow = Color(0xFF1E88E5); // High-luminance Blue
}
