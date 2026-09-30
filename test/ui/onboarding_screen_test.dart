import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/services.dart';
import 'package:alertsense/data/datasources/local_storage.dart';
import 'package:alertsense/data/repositories/settings_repository.dart';
import 'package:alertsense/main.dart';
import 'package:alertsense/providers/auth_providers.dart';
import 'package:alertsense/providers/settings_providers.dart';
import 'package:alertsense/ui/onboarding/onboarding_screen.dart';
import 'package:go_router/go_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late LocalStorage localStorage;
  late SettingsRepository settingsRepo;

  setUp(() async {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      (MethodCall methodCall) async {
        if (methodCall.method == 'checkPermissionStatus') {
          return 1; // PermissionStatus.granted
        }
        if (methodCall.method == 'requestPermissions') {
          final List<dynamic> permissions = methodCall.arguments;
          final result = <int, int>{};
          for (final p in permissions) {
            result[p as int] = 1; // PermissionStatus.granted
          }
          return result;
        }
        return null;
      },
    );

    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    localStorage = LocalStorage(prefs);
    settingsRepo = SettingsRepository(localStorage);
    await settingsRepo.init();
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      null,
    );
  });

  Widget buildTestOnboarding(ProviderContainer container) {
    final router = GoRouter(
      initialLocation: '/onboarding',
      routes: [
        GoRoute(
          path: '/onboarding',
          builder: (context, state) => const OnboardingScreen(),
        ),
        GoRoute(
          path: '/home',
          builder: (context, state) => const Scaffold(body: Text('Home Destination')),
        ),
        GoRoute(
          path: '/login',
          builder: (context, state) => const Scaffold(body: Text('Login Destination')),
        ),
      ],
    );

    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp.router(
        routerConfig: router,
      ),
    );
  }

  testWidgets('OnboardingScreen initial render displays page 1 and Skip button', (tester) async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        localStorageProvider.overrideWithValue(localStorage),
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        isAuthenticatedProvider.overrideWithValue(true),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(buildTestOnboarding(container));
    await tester.pumpAndSettle();

    expect(find.text('Sounds You Can See'), findsOneWidget);
    expect(find.text('Skip'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);
    expect(localStorage.isOnboardingComplete(), isFalse);
    expect(container.read(userSettingsProvider).onboardingCompleted, isFalse);
  });

  testWidgets('Tapping Skip completes onboarding persistence', (tester) async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        localStorageProvider.overrideWithValue(localStorage),
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        isAuthenticatedProvider.overrideWithValue(true),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(buildTestOnboarding(container));
    await tester.pumpAndSettle();

    // Verify initially false
    expect(localStorage.isOnboardingComplete(), isFalse);
    expect(container.read(userSettingsProvider).onboardingCompleted, isFalse);

    // Tap Skip
    await tester.tap(find.text('Skip'));
    await tester.pumpAndSettle();

    // Verify persisted
    expect(localStorage.isOnboardingComplete(), isTrue);
    expect(container.read(userSettingsProvider).onboardingCompleted, isTrue);
    expect(find.text('Home Destination'), findsOneWidget);

    // Recreate a new LocalStorage instance from the same SharedPreferences to verify disk persistence
    final diskStorage = LocalStorage(prefs);
    expect(diskStorage.isOnboardingComplete(), isTrue);
  });

  testWidgets('Navigating through pages and finishing completes onboarding', (tester) async {
    final container = ProviderContainer(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        localStorageProvider.overrideWithValue(localStorage),
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        isAuthenticatedProvider.overrideWithValue(true),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(buildTestOnboarding(container));
    await tester.pumpAndSettle();

    // Page 1 -> Next
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text('Alerts You Can Feel'), findsOneWidget);
    expect(find.text('Next'), findsOneWidget);

    // Page 2 -> Next
    await tester.tap(find.text('Next'));
    await tester.pumpAndSettle();

    expect(find.text("Let's Set Up"), findsOneWidget);
    expect(find.text('Get Started'), findsOneWidget);

    // Page 3 -> Get Started
    await tester.tap(find.text('Get Started'));
    await tester.pumpAndSettle();

    expect(localStorage.isOnboardingComplete(), isTrue);
    expect(container.read(userSettingsProvider).onboardingCompleted, isTrue);
    expect(find.text('Home Destination'), findsOneWidget);
  });

  test('LocalStorage setOnboardingComplete directly sets both prefs and model', () async {
    expect(localStorage.isOnboardingComplete(), isFalse);
    await localStorage.setOnboardingComplete();
    expect(localStorage.isOnboardingComplete(), isTrue);

    // Ensure dedicated pref key is set
    expect(prefs.getBool('onboarding_completed'), isTrue);

    // Ensure UserSettings in storage also reflect onboardingCompleted
    final loaded = localStorage.loadSettings();
    expect(loaded.onboardingCompleted, isTrue);
  });

  test('LocalStorage.loadSettings synchronizes onboardingCompleted when direct pref is set', () async {
    final freshPrefs = await SharedPreferences.getInstance();
    await freshPrefs.setBool('onboarding_completed', true);
    // UserSettings JSON is deliberately not present
    final freshStorage = LocalStorage(freshPrefs);
    final settings = freshStorage.loadSettings();
    expect(settings.onboardingCompleted, isTrue);

    final repo = SettingsRepository(freshStorage);
    await repo.init();
    expect(repo.settings.onboardingCompleted, isTrue);
    expect(repo.isOnboardingComplete(), isTrue);
  });
}
