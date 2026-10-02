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
import 'package:alertsense/ui/settings/widgets/theme_appearance_bottom_sheet.dart';

class _MockNotificationService extends NotificationService {}

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

  Widget buildSettingsWidget({ThemeType initialTheme = ThemeType.light}) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        alertRepositoryProvider.overrideWithValue(alertRepo),
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        notificationServiceProvider.overrideWithValue(_MockNotificationService()),
      ],
      child: Consumer(
        builder: (context, ref, child) {
          final theme = ref.watch(themeModeProvider);
          return MaterialApp(
            theme: theme,
            home: const SettingsScreen(),
          );
        },
      ),
    );
  }

  testWidgets('Theme Mode tile renders cleanly and displays current theme name', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSettingsWidget());
    await tester.pumpAndSettle();

    // Verify Theme Mode title and details exist
    expect(find.text('Theme Mode'), findsOneWidget);
    expect(find.text('Standard Light'), findsOneWidget);
  });

  testWidgets('Tapping Theme Mode opens Appearance & Color Theme bottom sheet and switches theme', (tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildSettingsWidget());
    await tester.pumpAndSettle();

    // Tap the Theme Mode tile to open bottom sheet
    await tester.tap(find.text('Theme Mode'));
    await tester.pumpAndSettle();

    // Verify Bottom Sheet is displayed
    expect(find.text('Appearance & Color Theme'), findsOneWidget);
    expect(find.text('Select a theme that works best for your eyesight'), findsOneWidget);

    // Verify all 4 themes are in the sheet
    expect(find.text('Standard Light'), findsWidgets);
    expect(find.text('Cyber Dark'), findsWidgets);
    expect(find.text('High Contrast (AMOLED)'), findsWidgets);
    expect(find.text('Color-Blind Accessible (IBM)'), findsWidgets);

    // Tap Cyber Dark option in the sheet
    await tester.tap(find.text('Cyber Dark').first);
    await tester.pumpAndSettle();

    // Tap Done to dismiss
    await tester.tap(find.text('Done'));
    await tester.pumpAndSettle();

    // Bottom sheet is dismissed and settings screen displays Cyber Dark
    expect(find.text('Appearance & Color Theme'), findsNothing);
    expect(find.text('Cyber Dark'), findsOneWidget);
  });

  testWidgets('ThemeAppearanceBottomSheet standalone show method works seamlessly with close button', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                onPressed: () => ThemeAppearanceBottomSheet.show(ctx),
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Open Sheet'));
    await tester.pumpAndSettle();

    expect(find.text('Appearance & Color Theme'), findsOneWidget);
    expect(find.text('Color-Blind Accessible (IBM)'), findsOneWidget);

    // Tap the close button
    await tester.tap(find.byTooltip('Close'));
    await tester.pumpAndSettle();

    expect(find.text('Appearance & Color Theme'), findsNothing);
  });
}
