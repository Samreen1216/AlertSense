import 'package:flutter/foundation.dart';
import '../core/constants/sound_categories.dart';

/// Manages cooldown periods and deduplicates repeated alerts
/// (e.g. continuous fire alarm or repeated knocking).
class DeduplicationService {
  final Map<String, DateTime> _lastAlertTimestamps = {};
  final Map<String, int> _ongoingEventCounts = {};
  final Map<String, DateTime> _ongoingEventStartTimes = {};

  /// Default cooldown durations in seconds.
  static const Map<String, int> defaultCooldowns = {
    'fireAlarm': 30,
    'smokeAlarm': 30,
    'emergencySiren': 30,
    'glassBreaking': 25,
    'doorbell': 15,
    'knocking': 12,
    'babyCrying': 20,
    'dogBarking': 15,
    'vehicleHorn': 10,
  };

  /// Check whether an alert for [category] should be accepted or suppressed.
  bool shouldTriggerAlert({
    required SoundCategory category,
    Map<String, int>? customCooldowns,
  }) {
    final now = DateTime.now();
    final lastTime = _lastAlertTimestamps[category.name];

    final cooldownSeconds = customCooldowns?[category.name] ??
        defaultCooldowns[category.name] ??
        20;

    if (lastTime == null) {
      _lastAlertTimestamps[category.name] = now;
      _ongoingEventStartTimes[category.name] = now;
      _ongoingEventCounts[category.name] = 1;
      return true;
    }

    final difference = now.difference(lastTime).inSeconds;

    if (difference < cooldownSeconds) {
      // Within cooldown: increment count and update ongoing event duration
      _ongoingEventCounts[category.name] = (_ongoingEventCounts[category.name] ?? 1) + 1;
      debugPrint(
        '[DeduplicationService] Suppressed ${category.label} (cooldown: ${cooldownSeconds - difference}s remaining, count: ${_ongoingEventCounts[category.name]})',
      );
      return false;
    }

    // Cooldown passed: reset and trigger new alert
    _lastAlertTimestamps[category.name] = now;
    _ongoingEventStartTimes[category.name] = now;
    _ongoingEventCounts[category.name] = 1;
    return true;
  }

  /// Get the duration in seconds for an ongoing event.
  int getOngoingDurationSeconds(SoundCategory category) {
    final start = _ongoingEventStartTimes[category.name];
    if (start == null) return 0;
    return DateTime.now().difference(start).inSeconds;
  }

  /// Get the number of times this category was detected continuously within cooldown.
  int getOngoingCount(SoundCategory category) {
    return _ongoingEventCounts[category.name] ?? 1;
  }

  /// Reset history for all or a specific category.
  void reset([String? categoryName]) {
    if (categoryName != null) {
      _lastAlertTimestamps.remove(categoryName);
      _ongoingEventCounts.remove(categoryName);
      _ongoingEventStartTimes.remove(categoryName);
    } else {
      _lastAlertTimestamps.clear();
      _ongoingEventCounts.clear();
      _ongoingEventStartTimes.clear();
    }
  }
}
