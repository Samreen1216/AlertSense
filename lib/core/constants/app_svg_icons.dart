import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// Central SVG icon repository for AlertSense.
/// Replaces all system keyboard emojis with scalable, accessible vector icons.
class AppSvgIcons {
  // ── 1. Fire Alarm ──────────────────────────────────────────────────────────
  static const String fireAlarm = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M12 2C10.5 5 8 7 8 10.5C8 12.71 9.79 14.5 12 14.5C14.21 14.5 16 12.71 16 10.5C16 8.5 14.8 6.5 13.5 5C13 7 11.5 8 10.5 8.5C11.5 6.5 12 4.5 12 2Z" fill="currentColor"/>
  <path d="M17.5 11C16.8 9.5 15.5 8.2 14 7.5C14.5 9 14 10.5 13 11.5C14.2 11.8 15 12.8 15 14C15 15.66 13.66 17 12 17C10.34 17 9 15.66 9 14C9 13.2 9.3 12.5 9.8 12C7.5 13.2 6 15.6 6 18.5C6 20.43 7.57 22 9.5 22H14.5C16.43 22 18 20.43 18 18.5C18 15.5 17.8 13.5 17.5 11Z" fill="currentColor" fill-opacity="0.85"/>
  <circle cx="12" cy="18" r="1.5" fill="currentColor"/>
</svg>
''';

  // ── 2. Smoke Alarm ────────────────────────────────────────────────────────
  static const String smokeAlarm = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="2"/>
  <circle cx="12" cy="12" r="5" stroke="currentColor" stroke-width="1.5" stroke-dasharray="2 2"/>
  <circle cx="12" cy="12" r="2" fill="currentColor"/>
  <path d="M7 6C8 4.5 10 3.5 12 3.5M17 6C16 4.5 14 3.5 12 3.5" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
  <path d="M8.5 18C9.5 19 10.7 19.5 12 19.5C13.3 19.5 14.5 19 15.5 18" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
</svg>
''';

  // ── 3. Emergency Siren ───────────────────────────────────────────────────
  static const String emergencySiren = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M6 19H18V21H6V19Z" fill="currentColor"/>
  <path d="M7 18C7 13.58 9.24 10 12 10C14.76 10 17 13.58 17 18H7Z" fill="currentColor"/>
  <path d="M12 3V6M4.5 7.5L6.5 9.5M19.5 7.5L17.5 9.5M3 13H5M21 13H19" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
  <circle cx="12" cy="14" r="1.5" fill="white"/>
</svg>
''';

  // ── 4. Glass Breaking ────────────────────────────────────────────────────
  static const String glassBreaking = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="4" y="3" width="16" height="18" rx="2" stroke="currentColor" stroke-width="1.8"/>
  <path d="M4 10L10 13L8 16L13 14L15 21" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"/>
  <path d="M10 13L15 8L20 11" stroke="currentColor" stroke-width="1.8" stroke-linejoin="round"/>
  <path d="M15 8L13 3" stroke="currentColor" stroke-width="1.8"/>
  <path d="M10 13L5 18" stroke="currentColor" stroke-width="1.5" stroke-dasharray="1 1"/>
</svg>
''';

  // ── 5. Doorbell ──────────────────────────────────────────────────────────
  static const String doorbell = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M12 4C8.69 4 6 6.69 6 10V15L4 17V18H20V17L18 15V10C18 6.69 15.31 4 12 4Z" fill="currentColor"/>
  <path d="M10 19C10 20.1 10.9 21 12 21C13.1 21 14 20.1 14 19H10Z" fill="currentColor"/>
  <path d="M19 8C20.5 9.5 20.5 12.5 19 14" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
  <path d="M5 8C3.5 9.5 3.5 12.5 5 14" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
</svg>
''';

  // ── 6. Knocking ──────────────────────────────────────────────────────────
  static const String knocking = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <rect x="18" y="2" width="3" height="20" rx="1.5" fill="currentColor" fill-opacity="0.3"/>
  <path d="M14 6C13.45 6 13 6.45 13 7V10H12C11.45 10 11 10.45 11 11V11.5H10.5C9.95 11.5 9.5 11.95 9.5 12.5V13H9C8.45 13 8 13.45 8 14V17C8 18.66 9.34 20 11 20H13.5C15.43 20 17 18.43 17 16.5V9C17 7.34 15.66 6 14 6Z" fill="currentColor"/>
  <path d="M5 9L3 11M3 13H5M5 15L3 17" stroke="currentColor" stroke-width="2" stroke-linecap="round"/>
</svg>
''';

  // ── 7. Baby Crying ───────────────────────────────────────────────────────
  static const String babyCrying = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <circle cx="12" cy="12" r="9" stroke="currentColor" stroke-width="1.8"/>
  <path d="M8 9.5C8 9.5 9 8.5 10 9.5" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
  <path d="M14 9.5C14 9.5 15 8.5 16 9.5" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
  <path d="M9.5 16C10.2 14.8 11 14.5 12 14.5C13 14.5 13.8 14.8 14.5 16" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
  <path d="M6.5 11C6.5 12 5.5 13.5 5.5 13.5C5.5 13.5 4.5 12 4.5 11C4.5 10.5 5 10 5.5 10C6 10 6.5 10.5 6.5 11Z" fill="currentColor"/>
  <path d="M19.5 11C19.5 12 18.5 13.5 18.5 13.5C18.5 13.5 17.5 12 17.5 11C17.5 10.5 18 10 18.5 10C19 10 19.5 10.5 19.5 11Z" fill="currentColor"/>
  <path d="M12 3C11.5 4 10.5 4.5 9.5 4.5" stroke="currentColor" stroke-width="1.5" stroke-linecap="round"/>
</svg>
''';

  // ── 8. Dog Barking ───────────────────────────────────────────────────────
  static const String dogBarking = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M4 18L5 15C5 15 4 13.5 4 11C4 8.5 5.5 7 7.5 7C8.5 7 9.5 7.5 10 8.5L12 8L16 5V8L18 9L15 13H12L10 16L7 17L5 19H4V18Z" fill="currentColor"/>
  <circle cx="8" cy="10" r="1" fill="white"/>
  <path d="M19 11C20.5 11.5 21.5 12.8 21.5 14M18 14C19 14.5 19.5 15.3 19.5 16.2" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
</svg>
''';

  // ── 9. Vehicle Horn ──────────────────────────────────────────────────────
  static const String vehicleHorn = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M4 14C3.45 14 3 14.45 3 15V17C3 17.55 3.45 18 4 18H5C5 19.1 5.9 20 7 20C8.1 20 9 19.1 9 18H15C15 19.1 15.9 20 17 20C18.1 20 19 19.1 19 18H20C20.55 18 21 17.55 21 17V15L19 10H5L3.5 13.5C3.8 13.8 4 14 4 14ZM7 17C6.45 17 6 16.55 6 16C6 15.45 6.45 15 7 15C7.55 15 8 15.45 8 16C8 16.55 7.55 17 7 17ZM17 17C16.45 17 16 16.55 16 16C16 15.45 16.45 15 17 15C17.55 15 18 15.45 18 16C18 16.55 17.55 17 17 17ZM6.5 11H17.5L18.7 14H5.3L6.5 11Z" fill="currentColor"/>
  <path d="M10 4L12 6M14 4L12 6M12 6V9" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
  <path d="M21 7C22.5 8 23 9.5 23 11" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
</svg>
''';

  // ── 10. Home Profile ─────────────────────────────────────────────────────
  static const String home = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M12 3L2 12H5V20H19V12H22L12 3Z" fill="currentColor"/>
  <rect x="10" y="13" width="4" height="7" fill="white" fill-opacity="0.9"/>
  <path d="M18 4V7.5L16 5.7V4H18Z" fill="currentColor"/>
</svg>
''';

  // ── 11. Sleep Profile ────────────────────────────────────────────────────
  static const String sleep = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M12.3 2C6.5 2.6 2 7.6 2 13.7C2 20.1 7.2 25.3 13.6 25.3C18.4 25.3 22.5 22.4 24.2 18.2C23.3 18.4 22.4 18.5 21.5 18.5C14.6 18.5 9 12.9 9 6C9 4.6 9.3 3.2 9.7 2C10.5 2 11.4 2 12.3 2Z" fill="currentColor" transform="scale(0.8) translate(2, 0)"/>
  <path d="M19 4L19.5 5.5L21 6L19.5 6.5L19 8L18.5 6.5L17 6L18.5 5.5L19 4Z" fill="currentColor"/>
  <path d="M15 10L15.3 11L16.5 11.3L15.3 11.7L15 12.8L14.7 11.7L13.5 11.3L14.7 11L15 10Z" fill="currentColor"/>
</svg>
''';

  // ── 12. Outdoor Profile ──────────────────────────────────────────────────
  static const String outdoor = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M12 2L8 8H10L6 14H9L7 18H17L15 14H18L14 8H16L12 2Z" fill="currentColor"/>
  <rect x="11" y="18" width="2" height="4" fill="currentColor"/>
  <path d="M3 21C6 20 18 20 21 21" stroke="currentColor" stroke-width="1.8" stroke-linecap="round"/>
</svg>
''';

  // ── 13. General Alert ────────────────────────────────────────────────────
  static const String alertGeneral = '''
<svg viewBox="0 0 24 24" fill="none" xmlns="http://www.w3.org/2000/svg">
  <path d="M12 2L1 21H23L12 2ZM12 6L19.5 19H4.5L12 6ZM11 10V14H13V10H11ZM11 16V18H13V16H11Z" fill="currentColor"/>
</svg>
''';

  /// Resolves the corresponding SVG string by category name, profile ID, or legacy emoji.
  static String getSvg(String key) {
    final normalized = key.trim().toLowerCase();
    switch (normalized) {
      // Categories
      case 'firealarm':
      case 'fire_alarm':
      case 'fire alarm':
      case '🔥':
        return fireAlarm;
      case 'smokealarm':
      case 'smoke_alarm':
      case 'smoke alarm':
      case '💨':
        return smokeAlarm;
      case 'emergencysiren':
      case 'emergency_siren':
      case 'emergency siren':
      case 'siren':
      case '🚓':
      case '🚨':
        return emergencySiren;
      case 'glassbreaking':
      case 'glass_breaking':
      case 'glass breaking':
      case '🪟':
        return glassBreaking;
      case 'doorbell':
      case 'bellring':
      case 'bell_ring':
      case 'bell ring':
      case 'bell':
      case '🔔':
        return doorbell;
      case 'knocking':
      case 'knock':
      case '🚪':
        return knocking;
      case 'babycrying':
      case 'baby_crying':
      case 'baby crying':
      case 'baby':
      case '👶':
        return babyCrying;
      case 'dogbarking':
      case 'dog_barking':
      case 'dog barking':
      case 'dog':
      case '🐕':
        return dogBarking;
      case 'vehiclehorn':
      case 'vehicle_horn':
      case 'vehicle horn':
      case 'horn':
      case '🚗':
        return vehicleHorn;

      // Profiles
      case 'home':
      case '🏠':
        return home;
      case 'sleep':
      case '🌙':
        return sleep;
      case 'outdoor':
      case '🌳':
        return outdoor;

      default:
        return alertGeneral;
    }
  }
}

/// A responsive, accessible SVG Icon widget replacing emoji characters across the app.
class AppSvgIcon extends StatelessWidget {
  final String iconKey;
  final double size;
  final Color? color;

  const AppSvgIcon({
    super.key,
    required this.iconKey,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final svgString = AppSvgIcons.getSvg(iconKey);
    final theme = Theme.of(context);
    final effectiveColor = color ?? theme.colorScheme.primary;

    return SvgPicture.string(
      svgString,
      width: size,
      height: size,
      colorFilter: ColorFilter.mode(effectiveColor, BlendMode.srcIn),
    );
  }
}
