import 'package:flutter/foundation.dart';
import 'package:vibration/vibration.dart';
import '../core/constants/priority_levels.dart';
import '../core/constants/sound_categories.dart';
import '../core/utils/vibration_patterns.dart';

/// Handles haptic feedback and custom vibration patterns.
class VibrationService {
  bool _hasCustomVibrations = false;

  VibrationService() {
    _init();
  }

  Future<void> _init() async {
    try {
      final hasCustom = await Vibration.hasCustomVibrationsSupport();
      _hasCustomVibrations = hasCustom == true;
    } catch (e) {
      debugPrint('[VibrationService] Error checking vibration support: $e');
    }
  }

  /// Trigger vibration for a specific sound category and priority.
  Future<void> vibrateForAlert({
    required SoundCategory category,
    required PriorityLevel priority,
    bool isSleepMode = false,
    List<int>? customPattern,
  }) async {
    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator != true) {
        debugPrint('[VibrationService] Device has no vibrator');
        return;
      }

      List<int> pattern = customPattern ?? _getPatternForCategory(category, priority);

      if (isSleepMode) {
        pattern = VibrationPatterns.sleepModeBoost(pattern);
      }

      if (_hasCustomVibrations && pattern.isNotEmpty) {
        await Vibration.vibrate(
          pattern: pattern,
          intensities: List.filled(pattern.length, 255),
        );
      } else {
        // Fallback for basic vibrators
        final duration = priority == PriorityLevel.high ? 1000 : 400;
        await Vibration.vibrate(duration: duration);
      }
    } catch (e) {
      debugPrint('[VibrationService] Vibration failed: $e');
    }
  }

  List<int> _getPatternForCategory(SoundCategory category, PriorityLevel priority) {
    switch (category) {
      case SoundCategory.fireAlarm:
      case SoundCategory.smokeAlarm:
        return VibrationPatterns.fireAlarm;
      case SoundCategory.emergencySiren:
        return VibrationPatterns.emergencySiren;
      case SoundCategory.glassBreaking:
        return VibrationPatterns.glassBreaking;
      case SoundCategory.doorbell:
        return VibrationPatterns.doorbell;
      case SoundCategory.knocking:
        return VibrationPatterns.knocking;
      case SoundCategory.babyCrying:
        return VibrationPatterns.babyCrying;
      case SoundCategory.dogBarking:
        return VibrationPatterns.dogBarking;
      case SoundCategory.vehicleHorn:
        return VibrationPatterns.vehicleHorn;
    }
  }

  /// Stop any currently active vibration.
  Future<void> cancel() async {
    try {
      await Vibration.cancel();
    } catch (e) {
      debugPrint('[VibrationService] Cancel error: $e');
    }
  }
}
