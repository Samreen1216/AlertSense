import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alertsense/core/constants/sound_categories.dart';
import 'package:alertsense/core/constants/priority_levels.dart';
import 'package:alertsense/data/models/classification_result.dart';
import 'package:alertsense/data/models/sound_profile.dart';
import 'package:alertsense/data/datasources/local_storage.dart';
import 'package:alertsense/data/repositories/alert_repository.dart';
import 'package:alertsense/services/alert_dispatcher_service.dart';
import 'package:alertsense/services/priority_engine.dart';
import 'package:alertsense/services/deduplication_service.dart';
import 'package:alertsense/services/vibration_service.dart';
import 'package:alertsense/services/flash_service.dart';
import 'package:alertsense/services/notification_service.dart';

// Mock NotificationService
class MockNotificationService extends NotificationService {
  final List<String> notificationsShown = [];

  @override
  Future<void> showAlertNotification({
    required int id,
    required SoundCategory category,
    required PriorityLevel priority,
    required double confidence,
  }) async {
    notificationsShown.add('${category.name}:${priority.name}:$confidence');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Background Listening Alert Dispatch Tests', () {
    late AlertDispatcherService dispatcher;
    late MockNotificationService mockNotifications;
    late AlertRepository alertRepo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorage(prefs);
      alertRepo = AlertRepository(storage);
      await alertRepo.init();

      mockNotifications = MockNotificationService();
      dispatcher = AlertDispatcherService(
        priorityEngine: PriorityEngine(),
        deduplicationService: DeduplicationService(),
        vibrationService: VibrationService(),
        flashService: FlashService(),
        notificationService: mockNotifications,
        alertRepository: alertRepo,
      );
    });

    test('Critical sound triggers system notification for background display', () async {
      final result = ClassificationResult(
        soundCategory: 'fireAlarm',
        confidence: 0.95,
        timestamp: DateTime.now(),
        topPredictions: const [MapEntry('Fire alarm', 0.95)],
        ambientDbLevel: 75.0,
      );

      final alert = await dispatcher.dispatchClassification(
        result: result,
        isSleepMode: false,
        flashEnabled: true,
        vibrationEnabled: true,
        enabledCategories: SoundCategory.values.map((c) => c.name).toSet(),
      );

      expect(alert, isNotNull);
      expect(alert!.soundCategory, equals('fireAlarm'));
      expect(alert.priorityLevel, equals('high'));
      expect(mockNotifications.notificationsShown.length, equals(1));
      expect(mockNotifications.notificationsShown.first, contains('fireAlarm:high:0.95'));
    });

    test('Sleep mode filters non-critical sounds from firing background alerts', () async {
      final result = ClassificationResult(
        soundCategory: 'dogBarking',
        confidence: 0.85,
        timestamp: DateTime.now(),
        topPredictions: const [MapEntry('Dog', 0.85)],
        ambientDbLevel: 60.0,
      );

      final alert = await dispatcher.dispatchClassification(
        result: result,
        isSleepMode: true, // Sleep mode filters out dogBarking
        flashEnabled: true,
        vibrationEnabled: true,
        enabledCategories: SoundProfile.sleep().enabledCategories.toSet(),
      );

      expect(alert, isNull);
      expect(mockNotifications.notificationsShown.isEmpty, isTrue);
    });

    test('Sub-threshold sounds do not trigger background alerts', () async {
      final result = ClassificationResult(
        soundCategory: 'doorbell',
        confidence: 0.30, // Below 0.55 threshold
        timestamp: DateTime.now(),
        topPredictions: const [MapEntry('Doorbell', 0.30)],
        ambientDbLevel: 45.0,
      );

      final alert = await dispatcher.dispatchClassification(
        result: result,
        isSleepMode: false,
        flashEnabled: false,
        vibrationEnabled: false,
        enabledCategories: SoundCategory.values.map((c) => c.name).toSet(),
      );

      expect(alert, isNull);
      expect(mockNotifications.notificationsShown.isEmpty, isTrue);
    });
  });
}
