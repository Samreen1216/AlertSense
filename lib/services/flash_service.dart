import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:torch_light/torch_light.dart';

/// Service controlling the device camera flashlight for high/medium priority alerts.
class FlashService {
  bool _isStrobing = false;
  Timer? _strobeTimer;

  bool get isStrobing => _isStrobing;

  /// Trigger a flashing strobe sequence at a given frequency.
  Future<void> triggerStrobe({
    int frequencyHz = 5,
    Duration duration = const Duration(seconds: 4),
  }) async {
    if (_isStrobing) return;

    try {
      final isTorchAvailable = await TorchLight.isTorchAvailable();
      if (!isTorchAvailable) {
        debugPrint('[FlashService] Torch is not available on this device');
        return;
      }
    } catch (e) {
      debugPrint('[FlashService] Torch check error: $e');
      return;
    }

    _isStrobing = true;
    final intervalMs = (1000 / (frequencyHz * 2)).round();
    bool isOn = false;

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
