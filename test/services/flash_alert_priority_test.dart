import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alertsense/core/constants/priority_levels.dart';
import 'package:alertsense/core/constants/sound_categories.dart';
import 'package:alertsense/data/datasources/local_storage.dart';
import 'package:alertsense/data/models/classification_result.dart';
import 'package:alertsense/data/repositories/alert_repository.dart';
import 'package:alertsense/services/alert_dispatcher_service.dart';
import 'package:alertsense/services/deduplication_service.dart';
import 'package:alertsense/services/flash_service.dart';
import 'package:alertsense/services/notification_service.dart';
import 'package:alertsense/services/priority_engine.dart';
import 'package:alertsense/services/vibration_service.dart';

class MockFlashService extends FlashService {
  final List<({int frequencyHz, Duration duration})> strobeCalls = [];

  @override
  Future<void> triggerStrobe({
    int frequencyHz = 5,
    Duration duration = const Duration(seconds: 4),
  }) async {
    strobeCalls.add((frequencyHz: frequencyHz, duration: duration));
  }

  @override
  Future<void> stopStrobe() async {}
}

class MockVibrationService extends VibrationService {
  @override
  Future<void> vibrateForAlert({
    required SoundCategory category,
    required PriorityLevel priority,
    bool isSleepMode = false,
    List<int>? customPattern,
  }) async {}

  @override
  Future<void> cancel() async {}
}

class MockNotificationService extends NotificationService {
  @override
  Future<void> showAlertNotification({
    required int id,
    required SoundCategory category,
    required PriorityLevel priority,
    required double confidence,
    bool suppressFullScreenIntent = false,
  }) async {}

  Future<void> showForegroundServiceNotification({
    required String title,
    required String text,
  }) async {}

  Future<void> cancelAlert(int id) async {}

  Future<void> cancelAll() async {}
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Flashlight on All Detections Tests', () {
    test('All PriorityLevel values (High, Medium, Low) have enableFlash set to true', () {
      for (final p in PriorityLevel.values) {
        expect(p.enableFlash, isTrue, reason: '${p.label} priority must have enableFlash set to true');
        expect(p.flashFrequencyHz, greaterThan(0), reason: '${p.label} priority must have positive flashFrequencyHz');
      }

      expect(PriorityLevel.high.enableFlash, isTrue);
      expect(PriorityLevel.high.flashFrequencyHz, equals(5));

      expect(PriorityLevel.medium.enableFlash, isTrue);
      expect(PriorityLevel.medium.flashFrequencyHz, equals(2));

      expect(PriorityLevel.low.enableFlash, isTrue);
      expect(PriorityLevel.low.flashFrequencyHz, equals(1));
    });

    late MockFlashService mockFlash;
    late AlertRepository alertRepo;
    late MockVibrationService mockVib;
    late MockNotificationService mockNotif;
    late AlertDispatcherService dispatcher;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorage(prefs);
      alertRepo = AlertRepository(storage);
      await alertRepo.init();

      mockFlash = MockFlashService();
      mockVib = MockVibrationService();
      mockNotif = MockNotificationService();

      dispatcher = AlertDispatcherService(
        priorityEngine: PriorityEngine(),
        deduplicationService: DeduplicationService(),
        vibrationService: mockVib,
        flashService: mockFlash,
        notificationService: mockNotif,
        alertRepository: alertRepo,
      );
    });

    tearDown(() {
      dispatcher.dispose();
    });

    test('High priority alert (fireAlarm) triggers flash strobe at 5 Hz', () async {
      final result = ClassificationResult(
        soundCategory: 'fireAlarm',
        confidence: 0.95,
        timestamp: DateTime.now(),
        topPredictions: const [MapEntry('Fire alarm', 0.95)],
        ambientDbLevel: 70.0,
      );

      final alert = await dispatcher.dispatchClassification(
        result: result,
        flashEnabled: true,
        vibrationEnabled: true,
        enabledCategories: {'fireAlarm'},
      );

      expect(alert, isNotNull);
      expect(mockFlash.strobeCalls.length, equals(1));
      expect(mockFlash.strobeCalls.first.frequencyHz, equals(5));
    });

    test('Medium priority alert (doorbell) triggers flash strobe at 2 Hz', () async {
      final result = ClassificationResult(
        soundCategory: 'doorbell',
        confidence: 0.85,
        timestamp: DateTime.now(),
        topPredictions: const [MapEntry('Doorbell', 0.85)],
        ambientDbLevel: 70.0,
      );

      final alert = await dispatcher.dispatchClassification(
        result: result,
        flashEnabled: true,
        vibrationEnabled: true,
        enabledCategories: {'doorbell'},
      );

      expect(alert, isNotNull);
      expect(mockFlash.strobeCalls.length, equals(1));
      expect(mockFlash.strobeCalls.first.frequencyHz, equals(2));
    });

    test('Low priority alert (dogBarking) triggers flash strobe at 1 Hz', () async {
      final result = ClassificationResult(
        soundCategory: 'dogBarking',
        confidence: 0.88,
        timestamp: DateTime.now(),
        topPredictions: const [MapEntry('Dog', 0.88)],
        ambientDbLevel: 70.0,
      );

      final alert = await dispatcher.dispatchClassification(
        result: result,
        flashEnabled: true,
        vibrationEnabled: true,
        enabledCategories: {'dogBarking'},
      );

      expect(alert, isNotNull);
      expect(mockFlash.strobeCalls.length, equals(1));
      expect(mockFlash.strobeCalls.first.frequencyHz, equals(1));
    });

    test('Low priority alert (vehicleHorn) triggers flash strobe at 1 Hz', () async {
      final result = ClassificationResult(
        soundCategory: 'vehicleHorn',
        confidence: 0.80,
        timestamp: DateTime.now(),
        topPredictions: const [MapEntry('Horn', 0.80)],
        ambientDbLevel: 70.0,
      );

      final alert = await dispatcher.dispatchClassification(
        result: result,
        flashEnabled: true,
        vibrationEnabled: true,
        enabledCategories: {'vehicleHorn'},
      );

      expect(alert, isNotNull);
      expect(mockFlash.strobeCalls.length, equals(1));
      expect(mockFlash.strobeCalls.first.frequencyHz, equals(1));
    });

    test('When flashEnabled is false in settings, flash strobe is not triggered', () async {
      final result = ClassificationResult(
        soundCategory: 'fireAlarm',
        confidence: 0.95,
        timestamp: DateTime.now(),
        topPredictions: const [MapEntry('Fire alarm', 0.95)],
        ambientDbLevel: 70.0,
      );

      final alert = await dispatcher.dispatchClassification(
        result: result,
        flashEnabled: false,
        vibrationEnabled: true,
        enabledCategories: {'fireAlarm'},
      );

      expect(alert, isNotNull);
      expect(mockFlash.strobeCalls.isEmpty, isTrue);
    });

    test('In Sleep Mode with flashEnabled true, critical alerts trigger flash strobe', () async {
      final result = ClassificationResult(
        soundCategory: 'smokeAlarm',
        confidence: 0.92,
        timestamp: DateTime.now(),
        topPredictions: const [MapEntry('Smoke alarm', 0.92)],
        ambientDbLevel: 70.0,
      );

      final alert = await dispatcher.dispatchClassification(
        result: result,
        isSleepMode: true,
        flashEnabled: true,
        vibrationEnabled: true,
        enabledCategories: {'smokeAlarm'},
      );

      expect(alert, isNotNull);
      expect(mockFlash.strobeCalls.length, equals(1));
      expect(mockFlash.strobeCalls.first.frequencyHz, equals(5));
    });
  });
}
