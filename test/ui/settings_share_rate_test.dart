import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

    // Verify Dialog opened with initially unrated empty stars
    expect(find.text('Rate AlertSense'), findsOneWidget);
    expect(find.text('Tap a star to rate'), findsOneWidget);
    // Ensure "Rate on Store" is completely removed
    expect(find.text('Rate on Store'), findsNothing);
    expect(find.text('Submit Feedback'), findsOneWidget);
    expect(find.text('Maybe Later'), findsOneWidget);

    // Verify all 5 stars are initially outline (empty, not filled/colored)
    final starButtons = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(IconButton),
    );
    expect(starButtons, findsNWidgets(5));
    expect(find.byIcon(Icons.star_outline_rounded), findsNWidgets(6)); // 5 in rating bar + 1 in title

    // Tap the 2nd star in the dialog to rate 2 stars
    await tester.tap(starButtons.at(1));
    await tester.pumpAndSettle();

    // Verify text updated for 2-star rating and TextField is present
    expect(find.text('Needs improvement ⭐⭐'), findsOneWidget);
    expect(find.text('Submit Feedback'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);

    // Dismiss dialog
    await tester.tap(find.text('Maybe Later'));
    await tester.pumpAndSettle();

    expect(find.text('Rate AlertSense'), findsNothing);

    container.dispose();
  });

  testWidgets('Tapping Submit Feedback with 5 stars saves rating, dismisses dialog, and displays feedback', (tester) async {
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

    // Ensure Rate on Store button is not present
    expect(find.text('Rate on Store'), findsNothing);

    // Tap 5th star
    final starButtons = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(IconButton),
    );
    await tester.tap(starButtons.at(4));
    await tester.pumpAndSettle();

    expect(find.text('Loved it! ⭐⭐⭐⭐⭐'), findsOneWidget);

    // Tap Submit Feedback
    await tester.tap(find.text('Submit Feedback'));
    await tester.pumpAndSettle();

    // Dialog is dismissed
    expect(find.text('Rate AlertSense'), findsNothing);

    // Verifies rating was saved in SharedPreferences
    expect(prefs.getInt('user_app_rating'), 5);

    // Verifies user feedback is shown on screen
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.textContaining('Thank you for rating AlertSense 5 stars!'), findsOneWidget);

    container.dispose();
  });

  testWidgets('Tapping Submit Feedback for lower rating saves rating, note, and confirms', (tester) async {
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

    // Select 3 stars
    final starButtons = find.descendant(
      of: find.byType(AlertDialog),
      matching: find.byType(IconButton),
    );
    await tester.tap(starButtons.at(2));
    await tester.pumpAndSettle();

    expect(find.text('It is good, can be better ⭐⭐⭐'), findsOneWidget);
    expect(find.text('Submit Feedback'), findsOneWidget);

    // Enter feedback note
    await tester.enterText(find.byType(TextField), 'Add more customizable sounds please.');
    await tester.pumpAndSettle();

    // Tap Submit Feedback
    await tester.tap(find.text('Submit Feedback'));
    await tester.pumpAndSettle();

    // Dialog is dismissed
    expect(find.text('Rate AlertSense'), findsNothing);

    // Verifies rating and feedback saved
    expect(prefs.getInt('user_app_rating'), 3);
    expect(prefs.getString('user_app_feedback'), 'Add more customizable sounds please.');

    // Verifies feedback snackbar
    expect(find.byType(SnackBar), findsOneWidget);
    expect(find.text('Thank you! Your feedback helps us improve AlertSense.'), findsOneWidget);

    container.dispose();
  });
}
