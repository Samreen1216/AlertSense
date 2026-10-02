/// Central Asset definitions for AlertSense.
class AppAssets {
  AppAssets._();

  // ── Brand Assets & App Icons ────────────────────────────────────────────────
  /// Primary App Icon (Square / Squircle with glowing radar-shield emblem)
  static const String appIcon = 'assets/icon/app_icon.png';

  /// Circular App Icon variant
  static const String appIconRound = 'assets/icon/app_icon_round.png';

  // ── AI Model Assets ────────────────────────────────────────────────────────
  static const String yamnetModel = 'assets/models/yamnet.tflite';
  static const String yamnetLabels = 'assets/labels/yamnet_class_map.csv';
}
