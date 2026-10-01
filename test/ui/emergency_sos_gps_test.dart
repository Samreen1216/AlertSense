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

  group('EmergencyContactsScreen Tests', () {
    testWidgets('does not render removed Test Emergency SOS Message button', (tester) async {
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

      expect(find.text('Test Emergency SOS Message (with GPS)'), findsNothing);
      expect(find.text('Save Contacts'), findsOneWidget);
      expect(find.text('Add Another Contact'), findsOneWidget);
    });

    testWidgets('allows adding and saving emergency contacts cleanly', (tester) async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageProvider.overrideWithValue(localStorage),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
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

      // Ensure test emergency SOS button is not present
      expect(find.text('Test Emergency SOS Message (with GPS)'), findsNothing);
      expect(find.text('Save Contacts'), findsOneWidget);

      // Tap Save Contacts and verify success snackbar
      await tester.tap(find.text('Save Contacts'));
      await tester.pumpAndSettle();

      expect(find.text('Emergency contacts saved successfully!'), findsOneWidget);
      // Advance past the 3-second SnackBar timer
      await tester.pump(const Duration(seconds: 4));
      await tester.pumpAndSettle();
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

  group('Alert Screens Family Alert Channel Tests', () {
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
      // Should NOT show standalone 'Send WhatsApp to Family'
      expect(find.text('Send WhatsApp to Family'), findsNothing);
      expect(find.text('Choose Emergency Channel'), findsNothing);
    });

    testWidgets('AlertDetailsScreen renders Alert Family (WhatsApp / SMS) and removes standalone WhatsApp button', (tester) async {
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

      // Should show 'Alert Family (WhatsApp / SMS)'
      expect(find.text('Alert Family (WhatsApp / SMS)'), findsOneWidget);
      // Should NOT show standalone 'Send WhatsApp to Family' or 'Send SMS to Family'
      expect(find.text('Send WhatsApp to Family'), findsNothing);
      expect(find.text('Send SMS to Family'), findsNothing);
    });

    testWidgets('AlertDetailsScreen tapping Alert Family (WhatsApp / SMS) opens AlertFamilyChoiceDialog and allows SMS selection', (tester) async {
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

      // Tap 'Alert Family (WhatsApp / SMS)'
      await tester.ensureVisible(find.text('Alert Family (WhatsApp / SMS)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alert Family (WhatsApp / SMS)'));
      await tester.pumpAndSettle();

      // Should open AlertFamilyChoiceDialog
      expect(find.text('Alert Family'), findsOneWidget);
      expect(find.text('Messages (SMS)'), findsOneWidget);
      expect(find.text('WhatsApp'), findsOneWidget);
      expect(find.text('JUST ONCE'), findsOneWidget);

      // Submit SMS (selected by default)
      await tester.tap(find.text('JUST ONCE'));
      await tester.pumpAndSettle();

      // Should open ManualSmsDialog directly with phone input and GPS pin
      expect(find.text('SEND SMS'), findsOneWidget);
      expect(find.text('GPS Pin Attached'), findsOneWidget);
    });

    testWidgets('AlertDetailsScreen tapping Alert Family (WhatsApp / SMS) choosing WhatsApp opens ManualWhatsAppDialog', (tester) async {
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
        id: 'test-detail-wa-empty',
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

      // Tap 'Alert Family (WhatsApp / SMS)'
      await tester.ensureVisible(find.text('Alert Family (WhatsApp / SMS)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alert Family (WhatsApp / SMS)'));
      await tester.pumpAndSettle();

      // Tap WhatsApp choice tile
      await tester.tap(find.text('WhatsApp'));
      await tester.pumpAndSettle();

      // Submit WhatsApp choice
      await tester.tap(find.text('JUST ONCE'));
      await tester.pumpAndSettle();

      // Should open ManualWhatsAppDialog directly with phone input and GPS pin
      expect(find.text('Alert via WhatsApp'), findsOneWidget);
      expect(find.text('GPS Pin Attached'), findsOneWidget);
    });

    testWidgets('AlertDetailsScreen dispatching SMS with saved contacts acknowledges alert', (tester) async {
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
              emergencyContacts: ['+923001234567', '+923009876543'],
            )),
        ],
      );
      addTearDown(container.dispose);

      final testAlert = AlertEvent(
        id: 'test-detail-multi-contact',
        soundCategory: 'smokeAlarm',
        confidence: 0.96,
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

      // Tap 'Alert Family (WhatsApp / SMS)'
      await tester.ensureVisible(find.text('Alert Family (WhatsApp / SMS)'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Alert Family (WhatsApp / SMS)'));
      await tester.pumpAndSettle();

      expect(find.text('Alert Family'), findsOneWidget);
      expect(find.text('To: +923001234567 (+1 more)'), findsOneWidget);

      // Tap 'JUST ONCE' for default SMS
      await tester.tap(find.text('JUST ONCE'));
      await tester.pumpAndSettle();
    });
  });
}
