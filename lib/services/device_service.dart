import 'package:flutter/services.dart';
import 'package:permission_handler/permission_handler.dart';

class DeviceService {
  static const _channel = MethodChannel('com.alertsense/device');

  /// Fetches physical battery percentage (0 to 100).
  Future<int?> getBatteryLevel() async {
    try {
      final int? level = await _channel.invokeMethod<int>('getBatteryLevel');
      return level;
    } on PlatformException {
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Checks if battery optimization is disabled for uninterrupted background monitoring.
  Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      final bool? isIgnoring =
          await _channel.invokeMethod<bool>('isIgnoringBatteryOptimizations');
      return isIgnoring ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Requests user to whitelist AlertSense from battery optimizations.
  Future<bool> requestIgnoreBatteryOptimizations() async {
    try {
      final status = await Permission.ignoreBatteryOptimizations.request();
      return status.isGranted;
    } catch (_) {
      return false;
    }
  }
}
