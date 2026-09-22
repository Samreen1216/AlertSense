import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:home_widget/home_widget.dart';
import '../core/constants/sound_categories.dart';
import '../data/models/alert_event.dart';

class HomeWidgetService {
  static const String appWidgetProviderName = 'AlertSenseWidgetProvider';
  static const String qualifiedWidgetName = 'com.alertsense.AlertSenseWidgetProvider';

  final _widgetLaunchController = StreamController<Uri>.broadcast();
  Stream<Uri> get widgetLaunchStream => _widgetLaunchController.stream;

  StreamSubscription<Uri?>? _widgetClickSub;
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    try {
      // Check if the app was initially launched cold from a home widget click
      final initialUri = await HomeWidget.initiallyLaunchedFromHomeWidget();
      if (initialUri != null) {
        _widgetLaunchController.add(initialUri);
      }

      // Listen for runtime clicks while app is in background/foreground
      _widgetClickSub = HomeWidget.widgetClicked.listen((uri) {
        if (uri != null) {
          _widgetLaunchController.add(uri);
        }
      });
    } catch (e) {
      debugPrint('HomeWidgetService init warning: $e');
    }
  }

  /// Synchronize full app state into Android Home Widget SharedPreferences
  Future<void> syncData({
    required bool isListening,
    required String activeProfile,
    required double ambientDb,
    AlertEvent? lastAlert,
    required int alertsTodayCount,
    required int highPriorityCount,
    int monitoredCount = 9,
  }) async {
    try {
      // 1. Status & Radar Data
      await HomeWidget.saveWidgetData<bool>('is_listening', isListening);
      await HomeWidget.saveWidgetData<String>('active_profile', _formatProfile(activeProfile));
      await HomeWidget.saveWidgetData<String>('ambient_db', '${ambientDb.toStringAsFixed(0)} dB');
      await HomeWidget.saveWidgetData<String>('sound_status', _describeSoundLevel(ambientDb));
      await HomeWidget.saveWidgetData<String>('monitored_sounds', '$monitoredCount Sounds Monitored');

      // 2. Alert Feed Data
      if (lastAlert != null) {
        final cat = _findCategory(lastAlert.soundCategory);
        await HomeWidget.saveWidgetData<String>('last_alert_title', cat.label);
        await HomeWidget.saveWidgetData<String>('last_alert_emoji', cat.emoji);
        await HomeWidget.saveWidgetData<String>('last_alert_priority', lastAlert.priorityLevel.toUpperCase());
        final timeStr = _formatTimeAgo(lastAlert.timestamp);
        final confStr = '${(lastAlert.confidence * 100).toStringAsFixed(0)}%';
        await HomeWidget.saveWidgetData<String>('last_alert_meta', '$confStr Match • $timeStr');
      } else {
        await HomeWidget.saveWidgetData<String>('last_alert_title', 'All Clear');
        await HomeWidget.saveWidgetData<String>('last_alert_emoji', '🛡️');
        await HomeWidget.saveWidgetData<String>('last_alert_priority', 'LOW');
        await HomeWidget.saveWidgetData<String>('last_alert_meta', 'No threats detected • Active');
      }

      await HomeWidget.saveWidgetData<String>('alerts_today', '$alertsTodayCount Alerts Today');

      // 3. Trigger native widget update
      await HomeWidget.updateWidget(
        name: appWidgetProviderName,
        androidName: appWidgetProviderName,
        qualifiedAndroidName: qualifiedWidgetName,
      );
    } catch (e) {
      debugPrint('Error updating home widget data: $e');
    }
  }

  /// Request Android OS to pin the widget to user's home screen launcher
  Future<bool> pinWidgetToHomeScreen() async {
    try {
      final supported = await HomeWidget.isRequestPinWidgetSupported();
      if (supported == true) {
        await HomeWidget.requestPinWidget(
          androidName: appWidgetProviderName,
          qualifiedAndroidName: qualifiedWidgetName,
        );
        return true;
      }
      return false;
    } catch (e) {
      debugPrint('Pin widget error: $e');
      return false;
    }
  }

  String _formatProfile(String profile) {
    switch (profile.toLowerCase()) {
      case 'sleep':
        return 'Sleep';
      case 'outdoor':
        return 'Outdoor';
      default:
        return 'Home';
    }
  }

  String _describeSoundLevel(double db) {
    if (db < 45) return 'Quiet Environment';
    if (db < 65) return 'Normal Ambient Noise';
    if (db < 80) return 'Moderate Activity';
    return 'Loud / Intense Noise';
  }

  SoundCategory _findCategory(String name) {
    return SoundCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == name.toLowerCase(),
      orElse: () => SoundCategory.doorbell,
    );
  }

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void dispose() {
    _widgetClickSub?.cancel();
    _widgetLaunchController.close();
  }
}
