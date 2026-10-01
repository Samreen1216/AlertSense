import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alertsense/core/theme/theme_provider.dart';
import 'package:alertsense/data/datasources/local_storage.dart';
import 'package:alertsense/data/repositories/alert_repository.dart';
import 'package:alertsense/data/repositories/settings_repository.dart';
import 'package:alertsense/main.dart';
import 'package:alertsense/providers/service_providers.dart';
import 'package:alertsense/services/notification_service.dart';
import 'package:alertsense/ui/settings/settings_screen.dart';

class MockNotificationService extends NotificationService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late LocalStorage storage;
  late AlertRepository alertRepo;
  late SettingsRepository settingsRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    storage = LocalStorage(prefs);
    alertRepo = AlertRepository(storage);
    await alertRepo.init();
    settingsRepo = SettingsRepository(storage);
    await settingsRepo.init();
  });

  Widget buildSettingsApp(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: SettingsScreen(),
      ),
    );
  }

  testWidgets('Settings screen contains Share App and Rate Us and removes onboarding and splash preview', (tester) async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        localStorageProvider.overrideWithValue(storage),
        alertRepositoryProvider.overrideWithValue(alertRepo),
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        notificationServiceProvider.overrideWithValue(MockNotificationService()),
      ],
    );

    await tester.pumpWidget(buildSettingsApp(container));
    await tester.pumpAndSettle();

    // Verify removed tiles are NOT present
    expect(find.text('Replay Onboarding Tutorial'), findsNothing);
    expect(find.text('Preview Animated Splash Screen'), findsNothing);

    // Scroll down to the About section
    await tester.scrollUntilVisible(
      find.text('Share App'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    // Verify Share App and Rate Us are present
    expect(find.text('Share App'), findsOneWidget);
    expect(find.text('Recommend AlertSense to friends and family'), findsOneWidget);
    expect(find.text('Rate Us'), findsOneWidget);
    expect(find.text('Rate your experience and support our mission'), findsOneWidget);

    container.dispose();
  });

  testWidgets('Tapping Rate Us opens interactive rating dialog with stars and labels', (tester) async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        localStorageProvider.overrideWithValue(storage),
        alertRepositoryProvider.overrideWithValue(alertRepo),
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        notificationServiceProvider.overrideWithValue(MockNotificationService()),
      ],
    );

    await tester.pumpWidget(buildSettingsApp(container));
    await tester.pumpAndSettle();

    // Scroll down to Rate Us
    await tester.scrollUntilVisible(
      find.text('Rate Us'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    // Tap Rate Us
    await tester.tap(find.text('Rate Us'));
    await tester.pumpAndSettle();

    // Verify Dialog opened
    expect(find.text('Rate AlertSense'), findsOneWidget);
    expect(find.text('Loved it! ⭐⭐⭐⭐⭐'), findsOneWidget);
    expect(find.text('Rate on Store'), findsOneWidget);
    expect(find.text('Maybe Later'), findsOneWidget);

    // Tap the 2nd star in the dialog to change rating
    final starButtons = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(IconButton),
    );
    expect(starButtons, findsNWidgets(5));
    // Tap the second star button
    await tester.tap(starButtons.at(1));
    await tester.pumpAndSettle();

    // Verify text updated for lower rating
    expect(find.text('Needs improvement ⭐⭐'), findsOneWidget);
    expect(find.text('Submit Feedback'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Dismiss dialog
    await tester.tap(find.text('Maybe Later'));
    await tester.pumpAndSettle();

    expect(find.text('Rate AlertSense'), findsNothing);

    container.dispose();
  });
}
