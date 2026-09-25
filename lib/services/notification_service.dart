import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/constants/priority_levels.dart';
import '../core/constants/sound_categories.dart';

/// Manages system notifications with priority channels (heads-up alerts).
class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  bool _initialized = false;

  static const String channelHigh = 'alertsense_high';
  static const String channelMedium = 'alertsense_medium';
  static const String channelLow = 'alertsense_low';

  Future<void> init() async {
    if (_initialized) return;

    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    try {
      await _plugin.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (response) {
          debugPrint('[NotificationService] Selected: ${response.payload}');
        },
      );

      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();

      if (androidPlugin != null) {
        // High priority channel — critical life-safety alerts
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            channelHigh,
            'Critical Safety Alerts',
            description: 'Life-safety alerts like Fire Alarms and Sirens',
            importance: Importance.max,
            enableVibration: true,
            playSound: false,
            showBadge: true,
          ),
        );

        // Medium priority channel
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            channelMedium,
            'Important Environmental Sounds',
            description: 'Doorbell, Knocking, Baby Crying',
            importance: Importance.high,
            enableVibration: true,
            playSound: false,
            showBadge: true,
          ),
        );

        // Low priority channel
        await androidPlugin.createNotificationChannel(
          const AndroidNotificationChannel(
            channelLow,
            'Ambient Sound Updates',
            description: 'Dog Barking, Vehicle Horns',
            importance: Importance.low,
            enableVibration: false,
            playSound: false,
            showBadge: false,
          ),
        );
      }

      _initialized = true;
      debugPrint('[NotificationService] Initialized');
    } catch (e) {
      debugPrint('[NotificationService] Init error: $e');
    }
  }

  Future<void> showAlertNotification({
    required int id,
    required SoundCategory category,
    required PriorityLevel priority,
    required double confidence,
  }) async {
    final String channelId = priority == PriorityLevel.high
        ? channelHigh
        : (priority == PriorityLevel.medium ? channelMedium : channelLow);

    final channelName = priority == PriorityLevel.high
        ? 'Critical Safety Alerts'
        : (priority == PriorityLevel.medium ? 'Important Alerts' : 'Ambient Alerts');

    final importance = priority == PriorityLevel.high
        ? Importance.max
        : (priority == PriorityLevel.medium ? Importance.high : Importance.low);

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: importance,
      priority: priority == PriorityLevel.high ? Priority.max : Priority.high,
      fullScreenIntent: priority == PriorityLevel.high,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      enableVibration: true,
      ticker: '${category.label} detected',
      showWhen: true,
      when: DateTime.now().millisecondsSinceEpoch,
      styleInformation: BigTextStyleInformation(
        'Detected ${category.label} with ${(confidence * 100).toStringAsFixed(0)}% confidence.',
        contentTitle: '${category.label} Detected!',
        summaryText: '${priority.label.toUpperCase()} PRIORITY',
      ),
      color: category.color,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    try {
      await _plugin.show(
        id,
        '${category.label} Detected',
        'Confidence: ${(confidence * 100).toStringAsFixed(0)}%  |  Tap for details',
        notificationDetails,
        payload: category.name,
      );
    } catch (e) {
      debugPrint('[NotificationService] Show error: $e');
    }
  }

  /// Updates an existing alert notification with ongoing/continuous detection status.
  /// Fulfills Proposal Section 8: "Deduplicate continuous alarm triggers into single persistent alerts".
  Future<void> updateOngoingAlertNotification({
    required int id,
    required SoundCategory category,
    required PriorityLevel priority,
    required int count,
    required int durationSeconds,
  }) async {
    final String channelId = priority == PriorityLevel.high
        ? channelHigh
        : (priority == PriorityLevel.medium ? channelMedium : channelLow);

    final channelName = priority == PriorityLevel.high
        ? 'Critical Safety Alerts'
        : (priority == PriorityLevel.medium ? 'Important Alerts' : 'Ambient Alerts');

    final importance = priority == PriorityLevel.high
        ? Importance.max
        : (priority == PriorityLevel.medium ? Importance.high : Importance.low);

    final androidDetails = AndroidNotificationDetails(
      channelId,
      channelName,
      importance: importance,
      priority: priority == PriorityLevel.high ? Priority.max : Priority.high,
      ongoing: true,
      category: AndroidNotificationCategory.alarm,
      visibility: NotificationVisibility.public,
      ticker: '${category.label} continues to be detected',
      showWhen: true,
      when: DateTime.now().millisecondsSinceEpoch,
      styleInformation: BigTextStyleInformation(
        '${category.label} continues to be detected ($count times over ${durationSeconds}s). AlertSense monitoring is actively ongoing.',
        contentTitle: '${category.label} Continues to be Detected',
        summaryText: '${priority.label.toUpperCase()} • PERSISTENT ALERT',
      ),
      color: category.color,
    );

    final notificationDetails = NotificationDetails(android: androidDetails);

    try {
      await _plugin.show(
        id,
        '${category.label} Continues to be Detected',
        'Ongoing: detected $count times over ${durationSeconds}s',
        notificationDetails,
        payload: category.name,
      );
    } catch (e) {
      debugPrint('[NotificationService] Ongoing update error: $e');
    }
  }
}
