import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alertsense/data/datasources/local_storage.dart';
import 'package:alertsense/data/models/alert_event.dart';
import 'package:alertsense/data/repositories/alert_repository.dart';
import 'package:alertsense/data/repositories/settings_repository.dart';
import 'package:alertsense/main.dart';
import 'package:alertsense/providers/service_providers.dart';
import 'package:alertsense/services/notification_service.dart';
import 'package:alertsense/ui/history/history_screen.dart';

class MockNotificationService extends NotificationService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Swiping alert card shows SnackBar and auto-dismisses after 4 seconds', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = LocalStorage(prefs);
    final alertRepo = AlertRepository(storage);
    await alertRepo.init();
    final settingsRepo = SettingsRepository(storage);
    await settingsRepo.init();

    final testAlert = AlertEvent(
      id: 'test_alert_1',
      soundCategory: 'doorbell',
      priorityLevel: 'medium',
      confidence: 0.88,
      timestamp: DateTime.now(),
      acknowledged: false,
      source: 'live_mic',
    );
    await alertRepo.addAlert(testAlert);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          alertRepositoryProvider.overrideWithValue(alertRepo),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          notificationServiceProvider.overrideWithValue(MockNotificationService()),
        ],
        child: const MaterialApp(
          home: HistoryScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify the card is visible
    expect(find.byType(Dismissible), findsOneWidget);
    expect(find.text('Doorbell'), findsOneWidget);

    // Swipe card from right to left to delete
    await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
    await tester.pumpAndSettle();

    // Verify card is removed from list
    expect(find.text('Doorbell'), findsNothing);

    // Verify SnackBar is shown with Undo button
    expect(find.text('Removed Doorbell alert'), findsOneWidget);
    expect(find.text('Undo'), findsOneWidget);

    // Advance virtual timer by 4.2 seconds
    await tester.pump(const Duration(milliseconds: 4200));
    await tester.pumpAndSettle();

    // Verify SnackBar has disappeared
    expect(find.text('Removed Doorbell alert'), findsNothing);
  });

  testWidgets('Tapping Undo in SnackBar restores the deleted alert card', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = LocalStorage(prefs);
    final alertRepo = AlertRepository(storage);
    await alertRepo.init();
    final settingsRepo = SettingsRepository(storage);
    await settingsRepo.init();

    final testAlert = AlertEvent(
      id: 'test_alert_2',
      soundCategory: 'doorbell',
      priorityLevel: 'medium',
      confidence: 0.90,
      timestamp: DateTime.now(),
      acknowledged: false,
      source: 'live_mic',
    );
    await alertRepo.addAlert(testAlert);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          alertRepositoryProvider.overrideWithValue(alertRepo),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          notificationServiceProvider.overrideWithValue(MockNotificationService()),
        ],
        child: const MaterialApp(
          home: HistoryScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Swipe to delete
    await tester.drag(find.byType(Dismissible), const Offset(-500, 0));
    await tester.pumpAndSettle();

    expect(find.text('Undo'), findsOneWidget);

    // Tap Undo
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();

    // Verify alert card was restored
    expect(find.text('Doorbell'), findsOneWidget);
  });
}
