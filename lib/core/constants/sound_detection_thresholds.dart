import 'sound_categories.dart';

/// Centralized sound-specific confidence threshold configuration for AlertSense.
///
/// Ensures each sound category has a dedicated, tunable threshold rather than
/// relying on a single global threshold. Easily tunable using real-world evaluation metrics.
class SoundDetectionThresholds {
  /// Default category-specific confidence thresholds.
  static const Map<SoundCategory, double> values = {
    SoundCategory.fireAlarm: 0.65,
    SoundCategory.smokeAlarm: 0.65,
    SoundCategory.emergencySiren: 0.70,
    SoundCategory.glassBreaking: 0.75,
    SoundCategory.doorbell: 0.70,
    SoundCategory.knocking: 0.70,
    SoundCategory.babyCrying: 0.65,
    SoundCategory.dogBarking: 0.75,
    SoundCategory.vehicleHorn: 0.75,
  };

  final Map<SoundCategory, double> _overrides;

  /// Creates a threshold manager, optionally applying custom category overrides.
  SoundDetectionThresholds([Map<SoundCategory, double>? customOverrides])
      : _overrides = Map.from(values)..addAll(customOverrides ?? {});

  /// Get the standard baseline threshold for a category.
  static double getThreshold(SoundCategory category) =>
      values[category] ?? 0.70;

  /// Get the active threshold for a category, considering any runtime overrides.
  double thresholdFor(SoundCategory category) =>
      _overrides[category] ?? getThreshold(category);

  /// Determine if a confidence score satisfies the category's threshold.
  bool meetsThreshold(SoundCategory category, double confidence) =>
      confidence >= thresholdFor(category);

  /// Return all active thresholds as an unmodifiable map.
  Map<SoundCategory, double> toMap() => Map.unmodifiable(_overrides);
}
