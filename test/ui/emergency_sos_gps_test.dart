import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alertsense/data/datasources/local_storage.dart';
import 'package:alertsense/data/models/alert_event.dart';
import 'package:alertsense/data/models/user_settings.dart';
import 'package:alertsense/data/repositories/alert_repository.dart';
import 'package:alertsense/data/repositories/settings_repository.dart';
import 'package:alertsense/main.dart';
import 'package:alertsense/providers/alert_providers.dart';
import 'package:alertsense/providers/service_providers.dart';
import 'package:alertsense/providers/settings_providers.dart';
import 'package:alertsense/services/location_service.dart';
import 'package:alertsense/services/notification_service.dart';
import 'package:alertsense/services/sms_service.dart';
import 'package:alertsense/ui/alert/alert_details_screen.dart';
import 'package:alertsense/ui/alert/full_screen_alert.dart';
import 'package:alertsense/ui/settings/emergency_contacts_screen.dart';

class _MockNotificationService extends NotificationService {}

class _FakeLocationService extends LocationService {
  final LocationResult? mockLocation;
  _FakeLocationService({this.mockLocation});

  @override
  Future<LocationResult?> getCurrentLocation({
    Duration timeout = const Duration(seconds: 4),
    bool useCache = true,
  }) async {
    return mockLocation;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late LocalStorage localStorage;
  late SettingsRepository settingsRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    localStorage = LocalStorage(prefs);
    settingsRepo = SettingsRepository(localStorage);
    await settingsRepo.init();
  });

  group('FullScreenAlert GPS Status Indicator Tests', () {
    testWidgets('shows GPS Location Locked when coordinates are resolved', (tester) async {
      final mockLoc = LocationResult(
        latitude: 33.6844,
        longitude: 73.0479,
        accuracy: 14.0,
        timestamp: DateTime.now(),
      );

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageProvider.overrideWithValue(localStorage),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          locationServiceProvider.overrideWithValue(_FakeLocationService(mockLocation: mockLoc)),
          userSettingsProvider.overrideWith((ref) => SettingsNotifier(ref)
            ..state = const UserSettings(
              onboardingCompleted: true,
              emergencyContacts: ['+923001234567'],
            )),
        ],
      );
      addTearDown(container.dispose);

      final alertData = {
        'id': 'test-alert-gps-1',
        'soundCategory': 'fireAlarm',
        'confidence': 97,
        'priorityLevel': 'HIGH',
        'timestamp': DateTime.now(),
      };

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: FullScreenAlert(alertData: alertData),
          ),
        ),
      );

      // Initial pump
      await tester.pump();
      // Allow postFrameCallback to complete
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('📍 GPS Location Locked (±14m)'), findsOneWidget);
    });

    testWidgets('shows GPS Offline when location returns null', (tester) async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageProvider.overrideWithValue(localStorage),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          locationServiceProvider.overrideWithValue(_FakeLocationService(mockLocation: null)),
          userSettingsProvider.overrideWith((ref) => SettingsNotifier(ref)
            ..state = const UserSettings(
              onboardingCompleted: true,
              emergencyContacts: ['+923001234567'],
            )),
        ],
      );
      addTearDown(container.dispose);

      final alertData = {
        'id': 'test-alert-gps-2',
        'soundCategory': 'smokeAlarm',
        'confidence': 90,
        'priorityLevel': 'HIGH',
        'timestamp': DateTime.now(),
      };

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: FullScreenAlert(alertData: alertData),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.text('📍 GPS Offline'), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
    });
  });

  group('EmergencyContactsScreen SOS GPS Test Feature', () {
    testWidgets('renders Test Emergency SOS Message button', (tester) async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageProvider.overrideWithValue(localStorage),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          userSettingsProvider.overrideWith((ref) => SettingsNotifier(ref)
            ..state = const UserSettings(
              onboardingCompleted: true,
              emergencyContacts: ['03001234567'],
            )),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: EmergencyContactsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Emergency SOS Message (with GPS)'), findsOneWidget);
    });

    testWidgets('tapping Test Emergency SOS Message opens preview modal with GPS pin', (tester) async {
      final mockLoc = LocationResult(
        latitude: 31.5204,
        longitude: 74.3587,
        accuracy: 10.0,
        timestamp: DateTime.now(),
      );

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageProvider.overrideWithValue(localStorage),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          locationServiceProvider.overrideWithValue(_FakeLocationService(mockLocation: mockLoc)),
          userSettingsProvider.overrideWith((ref) => SettingsNotifier(ref)
            ..state = const UserSettings(
              onboardingCompleted: true,
              emergencyContacts: ['+923001234567'],
            )),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: EmergencyContactsScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap the test button
      await tester.tap(find.text('Test Emergency SOS Message (with GPS)'));
      await tester.pumpAndSettle();

      // Verify modal dialog appeared
      expect(find.text('Emergency SOS Test'), findsOneWidget);
      expect(find.textContaining('GPS Locked: 31.5204, 74.3587 (±10m)'), findsOneWidget);
      expect(find.text('Target: +923001234567'), findsOneWidget);
      expect(find.textContaining('https://maps.google.com/?q=31.5204,74.3587 (±10m)'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('Send SMS'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Tap Cancel to dismiss
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Emergency SOS Test'), findsNothing);
    });
  });

  group('SmsService Emergency Message Format with Coordinates Tests', () {
    test('formats pin URL correctly with exact coordinates', () {
      final loc = LocationResult(
        latitude: 33.6844,
        longitude: 73.0479,
        accuracy: 8.0,
        timestamp: DateTime(2026, 9, 29),
      );

      final msg = SmsService.emergencyMessage('Smoke Alarm', location: loc);

      expect(msg, contains('📍 Pin: https://maps.google.com/?q=33.6844,73.0479 (±8m)'));
      expect(msg, contains('EMERGENCY ALERT via AlertSense: A Smoke Alarm has been detected at my location!'));
    });
  });

  group('Alert Screens Family Alert Channel Tests (WhatsApp Removed)', () {
    testWidgets('FullScreenAlert renders Alert Family (SMS) button and removes WhatsApp option', (tester) async {
      final mockLoc = LocationResult(
        latitude: 33.6844,
        longitude: 73.0479,
        accuracy: 14.0,
        timestamp: DateTime.now(),
      );

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageProvider.overrideWithValue(localStorage),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          locationServiceProvider.overrideWithValue(_FakeLocationService(mockLocation: mockLoc)),
          userSettingsProvider.overrideWith((ref) => SettingsNotifier(ref)
            ..state = const UserSettings(
              onboardingCompleted: true,
              emergencyContacts: ['+923001234567'],
            )),
        ],
      );
      addTearDown(container.dispose);

      final alertData = {
        'id': 'test-alert-action-1',
        'soundCategory': 'fireAlarm',
        'confidence': 97,
        'priorityLevel': 'HIGH',
        'timestamp': DateTime.now(),
      };

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: FullScreenAlert(alertData: alertData),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Should show 'Alert Family (SMS)'
      expect(find.text('Alert Family (SMS)'), findsOneWidget);
      // Should NOT show 'Alert Family (WhatsApp / SMS)' or WhatsApp actions
      expect(find.text('Alert Family (WhatsApp / SMS)'), findsNothing);
      expect(find.text('Send WhatsApp to Family'), findsNothing);
      expect(find.text('Choose Emergency Channel'), findsNothing);
    });

    testWidgets('AlertDetailsScreen renders Alert Family via SMS and removes WhatsApp button', (tester) async {
      final alertRepo = AlertRepository(localStorage);
      await alertRepo.init();

      final mockLoc = LocationResult(
        latitude: 33.6844,
        longitude: 73.0479,
        accuracy: 14.0,
        timestamp: DateTime.now(),
      );

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageProvider.overrideWithValue(localStorage),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          alertRepositoryProvider.overrideWithValue(alertRepo),
          notificationServiceProvider.overrideWithValue(_MockNotificationService()),
          locationServiceProvider.overrideWithValue(_FakeLocationService(mockLocation: mockLoc)),
          userSettingsProvider.overrideWith((ref) => SettingsNotifier(ref)
            ..state = const UserSettings(
              onboardingCompleted: true,
              emergencyContacts: ['+923001234567'],
            )),
        ],
      );
      addTearDown(container.dispose);

      final testAlert = AlertEvent(
        id: 'test-detail-sms-1',
        soundCategory: 'smokeAlarm',
        confidence: 0.95,
        priorityLevel: 'high',
        timestamp: DateTime.now(),
        source: 'Acoustic Sensor',
        acknowledged: false,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: AlertDetailsScreen(alert: testAlert),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Should show 'Alert Family via SMS'
      expect(find.text('Alert Family via SMS'), findsOneWidget);
      // Should NOT show 'Send WhatsApp to Family' or 'Send SMS to Family'
      expect(find.text('Send WhatsApp to Family'), findsNothing);
      expect(find.text('Send SMS to Family'), findsNothing);
      expect(find.text('Choose Emergency Channel'), findsNothing);
    });

    testWidgets('AlertDetailsScreen tapping Alert Family via SMS with empty contacts opens ManualSmsDialog with GPS pin', (tester) async {
      final alertRepo = AlertRepository(localStorage);
      await alertRepo.init();

      final mockLoc = LocationResult(
        latitude: 33.6844,
        longitude: 73.0479,
        accuracy: 10.0,
        timestamp: DateTime.now(),
      );

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageProvider.overrideWithValue(localStorage),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          alertRepositoryProvider.overrideWithValue(alertRepo),
          notificationServiceProvider.overrideWithValue(_MockNotificationService()),
          locationServiceProvider.overrideWithValue(_FakeLocationService(mockLocation: mockLoc)),
          userSettingsProvider.overrideWith((ref) => SettingsNotifier(ref)
            ..state = const UserSettings(
              onboardingCompleted: true,
              emergencyContacts: [], // No saved contacts
            )),
        ],
      );
      addTearDown(container.dispose);

      final testAlert = AlertEvent(
        id: 'test-detail-sms-empty',
        soundCategory: 'fireAlarm',
        confidence: 0.98,
        priorityLevel: 'high',
        timestamp: DateTime.now(),
        source: 'Acoustic Sensor',
        acknowledged: false,
      );

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: AlertDetailsScreen(alert: testAlert),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Tap 'Alert Family via SMS'
      await tester.tap(find.text('Alert Family via SMS'));
      await tester.pumpAndSettle();

      // Should open ManualSmsDialog directly with phone input and GPS pin
      expect(find.text('SEND SMS'), findsOneWidget);
      expect(find.text('GPS Pin Attached'), findsOneWidget);
      expect(find.text('Choose Emergency Channel'), findsNothing);
      expect(find.text('WhatsApp'), findsNothing);
    });
  });
}
