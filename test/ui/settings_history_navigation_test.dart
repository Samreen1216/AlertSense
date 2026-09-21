import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alertsense/core/router/app_router.dart';
import 'package:alertsense/data/datasources/local_storage.dart';
import 'package:alertsense/data/repositories/alert_repository.dart';
import 'package:alertsense/data/repositories/settings_repository.dart';
import 'package:alertsense/main.dart';
import 'package:alertsense/providers/service_providers.dart';
import 'package:alertsense/services/notification_service.dart';
import 'package:alertsense/ui/history/history_screen.dart';
import 'package:alertsense/ui/settings/settings_screen.dart';

class MockNotificationService extends NotificationService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Settings screen View Alert History navigates without error', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final storage = LocalStorage(prefs);
    final alertRepo = AlertRepository(storage);
    await alertRepo.init();
    final settingsRepo = SettingsRepository(storage);
    await settingsRepo.init();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          alertRepositoryProvider.overrideWithValue(alertRepo),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          notificationServiceProvider.overrideWithValue(MockNotificationService()),
        ],
        child: MaterialApp(
          routes: {
            AppRoutes.settingsHistory: (context) => const HistoryScreen(),
          },
          home: const SettingsScreen(),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Scroll until 'View Alert History' is visible
    await tester.scrollUntilVisible(
      find.text('View Alert History'),
      200,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.pumpAndSettle();

    // Verify View Alert History tile is visible
    expect(find.text('View Alert History'), findsOneWidget);

    // Tap View Alert History
    await tester.tap(find.text('View Alert History'));
    await tester.pumpAndSettle();

    // Verify History screen is successfully displayed without throwing
    expect(find.text('Alert History'), findsOneWidget);
    expect(find.text('All Alerts'), findsOneWidget);
  });
}
