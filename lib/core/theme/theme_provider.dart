import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app_theme.dart';

enum ThemeType {
  light,
  dark,
  highContrast,
  colorBlindSafe,
}

class ThemeTypeNotifier extends StateNotifier<ThemeType> {
  final SharedPreferences? prefs;
  static const _themeKey = 'alertsense_theme_type';

  ThemeTypeNotifier(this.prefs) : super(ThemeType.light) {
    _loadTheme();
  }

  void _loadTheme() {
    if (prefs != null) {
      final savedTheme = prefs!.getString(_themeKey);
      if (savedTheme != null) {
        state = ThemeType.values.firstWhere(
          (e) => e.toString() == savedTheme,
          orElse: () => ThemeType.light,
        );
      }
    }
  }

  Future<void> setTheme(ThemeType theme) async {
    state = theme;
    if (prefs != null) {
      await prefs!.setString(_themeKey, theme.toString());
    }
  }
}

class TextScaleNotifier extends StateNotifier<double> {
  final SharedPreferences? prefs;
  static const _scaleKey = 'alertsense_text_scale';

  TextScaleNotifier(this.prefs) : super(1.0) {
    _loadScale();
  }

  void _loadScale() {
    if (prefs != null) {
      final savedScale = prefs!.getDouble(_scaleKey);
      if (savedScale != null) {
        state = savedScale;
      }
    }
  }

  Future<void> setScale(double scale) async {
    state = scale;
    if (prefs != null) {
      await prefs!.setDouble(_scaleKey, scale);
    }
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences?>((ref) => null);

final themeTypeProvider = StateNotifierProvider<ThemeTypeNotifier, ThemeType>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return ThemeTypeNotifier(prefs);
});

final textScaleProvider = StateNotifierProvider<TextScaleNotifier, double>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return TextScaleNotifier(prefs);
});

final themeModeProvider = Provider<ThemeData>((ref) {
  final themeType = ref.watch(themeTypeProvider);
  // textScaleProvider is intentionally NOT watched here.
  // Font scaling is applied at the MediaQuery level in app.dart via
  // TextScaler.linear(textScale), preventing double-scaling.
  switch (themeType) {
    case ThemeType.light:
      return AppTheme.getLight();
    case ThemeType.dark:
      return AppTheme.getDark();
    case ThemeType.highContrast:
      return AppTheme.getHighContrast();
    case ThemeType.colorBlindSafe:
      return AppTheme.getColorBlindSafe();
  }
});

