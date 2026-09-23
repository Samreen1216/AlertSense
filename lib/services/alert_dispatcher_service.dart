import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';
import '../core/constants/priority_levels.dart';
import '../core/constants/sound_categories.dart';
import '../data/models/alert_event.dart';
import '../data/models/classification_result.dart';
import '../data/repositories/alert_repository.dart';
import 'deduplication_service.dart';
import 'flash_service.dart';
import 'notification_service.dart';
import 'priority_engine.dart';
import 'vibration_service.dart';

/// Central coordinator that receives AI classifications, decides whether to trigger
/// alerts, coordinates sensory feedback (vibration + flash + notification),
/// saves to storage, and notifies the UI.
class AlertDispatcherService {
  final PriorityEngine _priorityEngine;
  final DeduplicationService _deduplicationService;
  final VibrationService _vibrationService;
  final FlashService _flashService;
  final NotificationService _notificationService;
  final AlertRepository _alertRepository;
  final Uuid _uuid = const Uuid();

  // Stream controller to notify the UI when a high-priority alert occurs (for full-screen overlay)
  final _urgentAlertController = StreamController<AlertEvent>.broadcast();
  Stream<AlertEvent> get urgentAlertStream => _urgentAlertController.stream;

  // Stream controller to notify the UI when any alert occurs (for in-app on-screen notifications)
  final _allAlertsController = StreamController<AlertEvent>.broadcast();
  Stream<AlertEvent> get allAlertsStream => _allAlertsController.stream;

  AlertDispatcherService({
    required PriorityEngine priorityEngine,
    required DeduplicationService deduplicationService,
    required VibrationService vibrationService,
    required FlashService flashService,
    required NotificationService notificationService,
    required AlertRepository alertRepository,
  })  : _priorityEngine = priorityEngine,
        _deduplicationService = deduplicationService,
        _vibrationService = vibrationService,
        _flashService = flashService,
        _notificationService = notificationService,
        _alertRepository = alertRepository;

  /// Process an incoming classification result.
  Future<AlertEvent?> dispatchClassification({
    required ClassificationResult result,
    bool isSleepMode = false,
    bool flashEnabled = true,
    bool vibrationEnabled = true,
    Set<String>? enabledCategories,
    Map<String, int>? customCooldowns,
    Map<String, List<int>>? customVibrationPatterns,
    String source = 'Continuous Monitoring',
  }) async {
    // 1. Check if category is enabled in current profile
    if (enabledCategories != null && !enabledCategories.contains(result.soundCategory)) {
      debugPrint('[AlertDispatcher] Category ${result.soundCategory} is disabled in active profile');
      return null;
    }

    // 2. Evaluate priority and confidence threshold
    final priority = _priorityEngine.evaluateAlert(result);
    if (priority == null) {
      return null;
    }
    debugPrint('[Priority] ${priority.name.toUpperCase()}');

    SoundCategory category;
    try {
      category = SoundCategory.values.firstWhere((c) => c.name == result.soundCategory);
    } catch (_) {
      return null;
    }

    // 3. Check deduplication / cooldown
    final allowed = _deduplicationService.shouldTriggerAlert(
      category: category,
      customCooldowns: customCooldowns,
    );
    if (!allowed) {
      debugPrint('[Deduplication] SUPPRESSED');
      debugPrint('[Alert] NOT TRIGGERED');
      return null;
    }
    debugPrint('[Deduplication] PASS');
    debugPrint('[Alert] TRIGGERED');

    // 4. Create and persist the AlertEvent
    final alertEvent = AlertEvent(
      id: _uuid.v4(),
      soundCategory: category.name,
      priorityLevel: priority.name,
      confidence: result.confidence,
      timestamp: result.timestamp,
      acknowledged: false,
      source: source,
    );

    await _alertRepository.addAlert(alertEvent);

    // 5. Trigger vibration feedback
    if (vibrationEnabled) {
      final customPattern = customVibrationPatterns?[category.name];
      _vibrationService.vibrateForAlert(
        category: category,
        priority: priority,
        isSleepMode: isSleepMode,
        customPattern: customPattern,
      );
    }

    // 6. Trigger camera flash if high priority and enabled
    if (flashEnabled && priority.enableFlash) {
      _flashService.triggerStrobe(
        frequencyHz: priority.flashFrequencyHz,
        duration: const Duration(seconds: 3),
      );
    }

    // 7. Post system notification
    await _notificationService.showAlertNotification(
      id: alertEvent.id.hashCode,
      category: category,
      priority: priority,
      confidence: result.confidence,
    );

    // 8. Broadcast to all-alerts stream for in-app on-screen notification overlay
    _allAlertsController.add(alertEvent);

    // 9. If High priority, push to the urgent stream for the full-screen overlay
    if (priority == PriorityLevel.high) {
      _urgentAlertController.add(alertEvent);
    }

    return alertEvent;
  }

  void dispose() {
    _urgentAlertController.close();
    _allAlertsController.close();
  }
}

