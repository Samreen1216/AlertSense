import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:torch_light/torch_light.dart';

/// Service controlling the device camera flashlight for all alert priority levels.
class FlashService {
  bool _isStrobing = false;
  Timer? _strobeTimer;

  bool get isStrobing => _isStrobing;

  /// Trigger a flashing strobe sequence at a given frequency.
  Future<void> triggerStrobe({
    int frequencyHz = 5,
    Duration duration = const Duration(seconds: 4),
  }) async {
    // If already strobing from a previous event, cancel and restart for the new detection
    if (_isStrobing) {
      await stopStrobe();
    }

    try {
      final isTorchAvailable = await TorchLight.isTorchAvailable();
      if (!isTorchAvailable) {
        debugPrint('[FlashService] Torch is not available on this device');
        return;
      }
    } catch (e) {
      debugPrint('[FlashService] Torch check error: $e');
    }

    _isStrobing = true;
    final safeFrequency = frequencyHz <= 0 ? 1 : frequencyHz;
    final intervalMs = (1000 / (safeFrequency * 2)).round().clamp(100, 1000);
    bool isOn = false;

    // Immediately enable torch for instant optical feedback
    try {
      await TorchLight.enableTorch();
      isOn = true;
    } catch (e) {
      debugPrint('[FlashService] Initial enable torch error: $e');
    }

    final startTime = DateTime.now();

    _strobeTimer = Timer.periodic(Duration(milliseconds: intervalMs), (timer) async {
      if (!_isStrobing || DateTime.now().difference(startTime) >= duration) {
        await stopStrobe();
        return;
      }

      try {
        if (isOn) {
          await TorchLight.disableTorch();
          isOn = false;
        } else {
          await TorchLight.enableTorch();
          isOn = true;
        }
      } catch (e) {
        debugPrint('[FlashService] Strobe toggle error: $e');
      }
    });
  }

  /// Stop any ongoing camera flash strobe.
  Future<void> stopStrobe() async {
    _isStrobing = false;
    _strobeTimer?.cancel();
    _strobeTimer = null;
    try {
      await TorchLight.disableTorch();
    } catch (e) {
      debugPrint('[FlashService] Disable torch error: $e');
    }
  }
}
