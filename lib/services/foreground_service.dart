import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';

@pragma('vm:entry-point')
void startForegroundTaskCallback() {
  FlutterForegroundTask.setTaskHandler(AlertSenseTaskHandler());
}

class AlertSenseTaskHandler extends TaskHandler {
  @override
  Future<void> onStart(DateTime timestamp, TaskStarter starter) async {
    debugPrint('[ForegroundTask] Background audio monitoring service active');
  }

  @override
  void onRepeatEvent(DateTime timestamp) {}

  @override
  Future<void> onDestroy(DateTime timestamp) async {
    debugPrint('[ForegroundTask] Background audio monitoring service stopped');
  }
}

class ForegroundService {
  bool _isInitialized = false;

  void init() {
    if (_isInitialized) return;

    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'alertsense_foreground_monitoring',
        channelName: 'AlertSense Background Audio Awareness',
        channelDescription:
            'Keeps real-time acoustic monitoring active when the app is closed or screen is locked',
        channelImportance: NotificationChannelImportance.LOW,
        priority: NotificationPriority.LOW,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: true,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        eventAction: ForegroundTaskEventAction.nothing(),
        autoRunOnBoot: false,
        allowWakeLock: true,
        allowWifiLock: false,
      ),
    );

    _isInitialized = true;
    debugPrint('[ForegroundService] Initialized');
  }

  Future<bool> startMonitoring({
    String title = 'AlertSense Active',
    String text = 'Actively monitoring surrounding sounds in real time...',
  }) async {
    try {
      init();

      // Ensure Android doesn't kill or throttle audio capture when screen is locked
      try {
        if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
          await FlutterForegroundTask.requestIgnoreBatteryOptimization();
        }
      } catch (e) {
        debugPrint('[ForegroundService] Battery optimization request note: $e');
      }

      if (await FlutterForegroundTask.isRunningService) {
        await updateStatus(title: title, text: text);
        return true;
      }

      final result = await FlutterForegroundTask.startService(
        serviceId: 256,
        notificationTitle: title,
        notificationText: text,
        callback: startForegroundTaskCallback,
      );

      final success = result is ServiceRequestSuccess;
      debugPrint('[ForegroundService] startMonitoring: $success');
      return success;
    } catch (e) {
      debugPrint('[ForegroundService] startMonitoring error: $e');
      return false;
    }
  }

  Future<bool> stopMonitoring() async {
    try {
      if (await FlutterForegroundTask.isRunningService) {
        final result = await FlutterForegroundTask.stopService();
        return result is ServiceRequestSuccess;
      }
      return true;
    } catch (e) {
      debugPrint('[ForegroundService] stopMonitoring error: $e');
      return false;
    }
  }

  Future<void> updateStatus({
    required String title,
    required String text,
  }) async {
    try {
      if (await FlutterForegroundTask.isRunningService) {
        await FlutterForegroundTask.updateService(
          notificationTitle: title,
          notificationText: text,
        );
      }
    } catch (e) {
      debugPrint('[ForegroundService] updateStatus error: $e');
    }
  }
}
