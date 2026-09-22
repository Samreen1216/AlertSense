import 'package:flutter/foundation.dart';
import '../core/constants/sound_categories.dart';
import '../core/constants/sound_detection_thresholds.dart';
import '../core/constants/priority_levels.dart';
import '../data/models/classification_result.dart';

/// Maps classified sound categories to priority levels and determines
/// whether an alert should be triggered based on confidence thresholds.
class PriorityEngine {
  /// Custom thresholds override (from user settings).
  final Map<String, double> _customThresholds = {};

  /// Set a custom confidence threshold for a specific category.
  void setThreshold(String categoryName, double threshold) {
    _customThresholds[categoryName] = threshold.clamp(0.3, 0.95);
  }

  /// Load custom thresholds from settings.
  void loadThresholds(Map<String, double> thresholds) {
    _customThresholds.clear();
    _customThresholds.addAll(thresholds);
  }

  /// Get active threshold for category (custom override or centralized default)
  double getThresholdForCategory(SoundCategory category) {
    return _customThresholds[category.name] ?? SoundDetectionThresholds.getThreshold(category);
  }

  /// Determine if a classification result should trigger an alert.
  ///
  /// Returns the [PriorityLevel] if the sound should trigger an alert,
  /// or null if the confidence is below the threshold.
  PriorityLevel? evaluateAlert(ClassificationResult result) {
    try {
      final category = SoundCategory.values.firstWhere(
        (c) => c.name == result.soundCategory,
      );

      // Get the confidence threshold (custom or default centralized threshold)
      final threshold = getThresholdForCategory(category);

      // Check if confidence meets threshold
      if (result.confidence < threshold) {
        debugPrint(
          '[PriorityEngine] ${category.label}: ${(result.confidence * 100).toStringAsFixed(1)}% < '
          '${(threshold * 100).toStringAsFixed(1)}% threshold — skipped',
        );
        return null;
      }

      debugPrint(
        '[PriorityEngine] ${category.label}: ${(result.confidence * 100).toStringAsFixed(1)}% ≥ '
        '${(threshold * 100).toStringAsFixed(1)}% — ALERT ${category.defaultPriority.label}',
      );

      return category.defaultPriority;
    } catch (e) {
      debugPrint('[PriorityEngine] Unknown category: ${result.soundCategory}');
      return null;
    }
  }

  /// Get the priority level for a sound category (ignoring confidence).
  PriorityLevel getPriorityForCategory(String categoryName) {
    try {
      final category = SoundCategory.values.firstWhere(
        (c) => c.name == categoryName,
      );
      return category.defaultPriority;
    } catch (_) {
      return PriorityLevel.low;
    }
  }
}
