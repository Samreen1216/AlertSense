import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alertsense/core/theme/theme_provider.dart';
import 'package:alertsense/data/datasources/local_storage.dart';
import 'package:alertsense/data/repositories/settings_repository.dart';
import 'package:alertsense/main.dart';
import 'package:alertsense/providers/settings_providers.dart';
import 'package:alertsense/ui/splash/splash_screen.dart';

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

  Widget buildTestSplash(ProviderContainer container) {
    return UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(
        home: SplashScreen(),
      ),
    );
  }

  testWidgets('SplashScreen renders cleanly without exception', (tester) async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        localStorageProvider.overrideWithValue(localStorage),
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
      ],
    );

    await tester.pumpWidget(buildTestSplash(container));
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);
    expect(find.text('AlertSense'), findsOneWidget);
    expect(find.text('AI Environmental Sound Awareness'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);

    container.dispose();
  });

  testWidgets('SplashScreen adapts to all 4 themes cleanly', (tester) async {
    for (final theme in ThemeType.values) {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageProvider.overrideWithValue(localStorage),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
        ],
      );
      container.read(themeTypeProvider.notifier).setTheme(theme);

      await tester.pumpWidget(buildTestSplash(container));
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('AlertSense'), findsOneWidget);

      container.dispose();
    }
  });

  testWidgets('Interactive tap emits acoustic wave and updates pulse count', (tester) async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        localStorageProvider.overrideWithValue(localStorage),
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
      ],
    );

    await tester.pumpWidget(buildTestSplash(container));
    await tester.pump(const Duration(milliseconds: 200));

    // Initially says tap anywhere
    expect(find.text('Tap anywhere on screen to emit acoustic waves'), findsOneWidget);

    // Tap on the center of the screen
    await tester.tapAt(const Offset(200, 300));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Acoustic pulses emitted: 1'), findsOneWidget);

    // Tap again
    await tester.tapAt(const Offset(250, 350));
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('Acoustic pulses emitted: 2'), findsOneWidget);

    container.dispose();
  });

  testWidgets('Tapping theme switcher button cycles theme', (tester) async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        localStorageProvider.overrideWithValue(localStorage),
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
      ],
    );

    await tester.pumpWidget(buildTestSplash(container));
    await tester.pump(const Duration(milliseconds: 100));

    final initialTheme = container.read(themeTypeProvider);

    // Tap theme switcher
    final themeButton = find.byIcon(Icons.swap_horiz_rounded);
    expect(themeButton, findsOneWidget);
    await tester.tap(themeButton);
    await tester.pump(const Duration(milliseconds: 100));

    final nextTheme = container.read(themeTypeProvider);
    expect(nextTheme, isNot(equals(initialTheme)));

    container.dispose();
  });

  testWidgets('SplashScreen displays key sound category highlights', (tester) async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        localStorageProvider.overrideWithValue(localStorage),
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
      ],
    );

    await tester.pumpWidget(buildTestSplash(container));
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Siren & Emergency'), findsOneWidget);
    expect(find.text('Fire & Smoke'), findsOneWidget);
    expect(find.text('Doorbell & Knock'), findsOneWidget);

    container.dispose();
  });
}
