import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:go_router/go_router.dart';

import 'package:alertsense/core/constants/priority_levels.dart';
import 'package:alertsense/core/constants/sound_categories.dart';
import 'package:alertsense/core/router/app_router.dart';
import 'package:alertsense/data/datasources/local_storage.dart';
import 'package:alertsense/data/models/classification_result.dart';
import 'package:alertsense/data/models/user_settings.dart';
import 'package:alertsense/data/repositories/alert_repository.dart';
import 'package:alertsense/data/repositories/settings_repository.dart';
import 'package:alertsense/main.dart';
import 'package:alertsense/providers/audio_providers.dart';
import 'package:alertsense/providers/settings_providers.dart';
import 'package:alertsense/services/alert_dispatcher_service.dart';
import 'package:alertsense/services/deduplication_service.dart';
import 'package:alertsense/services/flash_service.dart';
import 'package:alertsense/services/notification_service.dart';
import 'package:alertsense/services/priority_engine.dart';
import 'package:alertsense/services/vibration_service.dart';
import 'package:alertsense/ui/home/home_screen.dart';
import 'package:alertsense/ui/home/widgets/hero_sound_radar.dart';
import 'package:alertsense/ui/home/widgets/segmented_profile_selector.dart';
import 'package:alertsense/ui/home/widgets/sound_category_cards.dart';
import 'package:alertsense/ui/onboarding/onboarding_screen.dart';
import 'package:alertsense/ui/settings/sensitivity_screen.dart';
import 'package:alertsense/ui/splash/splash_screen.dart';

class _MockNotificationService extends NotificationService {
  @override
  Future<void> showAlertNotification({
    required int id,
    required SoundCategory category,
    required PriorityLevel priority,
    required double confidence,
    bool suppressFullScreenIntent = false,
  }) async {}
}

class _TestListeningNotifier extends StateNotifier<bool> {
  _TestListeningNotifier([super.initialState = false]);
  void toggle() => state = !state;
  void toggleListening() => state = !state;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late LocalStorage localStorage;
  late SettingsRepository settingsRepo;
  final List<MethodCall> platformCalls = [];
  final List<MethodCall> accessibilityCalls = [];

  setUp(() async {
    platformCalls.clear();
    accessibilityCalls.clear();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, (MethodCall call) async {
      platformCalls.add(call);
      return null;
    });

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.accessibility, (MethodCall call) async {
      accessibilityCalls.add(call);
      return null;
    });

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
            result[p as int] = 1;
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
        .setMockMethodCallHandler(SystemChannels.platform, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.accessibility, null);
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('flutter.baseflow.com/permissions/methods'),
      null,
    );
  });

  group('Day 4: Onboarding Route Guarding & Cold Boot Redirect', () {
    testWidgets('Router redirect guard redirects /onboarding to /home when onboarding completed', (tester) async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageProvider.overrideWithValue(localStorage),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          userSettingsProvider.overrideWith((ref) => SettingsNotifier(ref)
            ..state = const UserSettings(onboardingCompleted: true)),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Since onboardingCompleted is true, cold boot launches straight to HomeScreen
      expect(find.byType(HomeScreen), findsOneWidget);

      // Now attempt to navigate to /onboarding
      router.go(AppRoutes.onboarding);
      await tester.pumpAndSettle();

      // Guarded: stays on HomeScreen, skips OnboardingScreen
      expect(find.byType(HomeScreen), findsOneWidget);
      expect(find.byType(OnboardingScreen), findsNothing);
    });

    testWidgets('Router initial location directs to /home when cold boot has onboarding complete', (tester) async {
      await localStorage.setOnboardingComplete();

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageProvider.overrideWithValue(localStorage),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Cold boot with onboarding complete launches straight to HomeScreen
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('Router initial location directs to /splash when onboarding is NOT complete', (tester) async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageProvider.overrideWithValue(localStorage),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          userSettingsProvider.overrideWith((ref) => SettingsNotifier(ref)
            ..state = const UserSettings(onboardingCompleted: false)),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 100));

      expect(find.byType(SplashScreen), findsOneWidget);
    });
  });

  group('Day 4: Onboarding Microphone Warning Dialog on Skip', () {
    testWidgets('Tapping Skip when mic permission is NOT granted shows warning dialog', (tester) async {
      // Mock permission handler to report mic NOT granted (denied)
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/permissions/methods'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'checkPermissionStatus') {
            return 0; // PermissionStatus.denied
          }
          return null;
        },
      );

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageProvider.overrideWithValue(localStorage),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Skip
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      // Warning dialog should appear
      expect(find.text('Microphone Permission Required'), findsOneWidget);
      expect(find.text('Grant Permission'), findsOneWidget);
      expect(find.text('Proceed Anyway'), findsOneWidget);

      // Tap Proceed Anyway
      await tester.tap(find.text('Proceed Anyway'));
      await tester.pumpAndSettle();

      // Should complete onboarding
      expect(localStorage.isOnboardingComplete(), isTrue);
      expect(container.read(userSettingsProvider).onboardingCompleted, isTrue);
    });

    testWidgets('Tapping Grant Permission in skip dialog requests mic and completes onboarding when granted', (tester) async {
      bool permissionRequested = false;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        const MethodChannel('flutter.baseflow.com/permissions/methods'),
        (MethodCall methodCall) async {
          if (methodCall.method == 'checkPermissionStatus') {
            return 0; // PermissionStatus.denied initially
          }
          if (methodCall.method == 'requestPermissions') {
            permissionRequested = true;
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

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageProvider.overrideWithValue(localStorage),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: OnboardingScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Skip
      await tester.tap(find.text('Skip'));
      await tester.pumpAndSettle();

      expect(find.text('Microphone Permission Required'), findsOneWidget);

      // Tap Grant Permission
      await tester.tap(find.text('Grant Permission'));
      await tester.pumpAndSettle();

      expect(permissionRequested, isTrue);
      expect(localStorage.isOnboardingComplete(), isTrue);
      expect(container.read(userSettingsProvider).onboardingCompleted, isTrue);
    });
  });

  group('Day 4: Semantics & Accessibility Spoken Announcements', () {
    testWidgets('HeroSoundRadar renders rich Semantics in standby and active modes', (tester) async {
      final notifier = _TestListeningNotifier(false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isListeningProvider.overrideWith((ref) => notifier),
            ambientDbProvider.overrideWith((ref) => 38.0),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 300,
                  height: 300,
                  child: HeroSoundRadar(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Standby mode semantics
      final standbySemantics = tester.getSemantics(find.byType(HeroSoundRadar));
      expect(standbySemantics.label, equals('Acoustic Sound Radar'));
      expect(standbySemantics.value, equals('Detection paused'));
      expect(standbySemantics.hint, equals('Double-tap to toggle microphone listening'));
      expect(standbySemantics.hasAction(SemanticsAction.tap), isTrue);

      // Activate listening
      notifier.toggle();
      await tester.pumpAndSettle();

      // Active mode semantics
      final activeSemantics = tester.getSemantics(find.byType(HeroSoundRadar));
      expect(activeSemantics.value, equals('Listening actively. Ambient level 38 decibels.'));
    });

    test('AlertDispatcherService announces threats to screen reader via SemanticsService', () async {
      final alertRepo = AlertRepository(localStorage);
      await alertRepo.init();

      final dispatcher = AlertDispatcherService(
        priorityEngine: PriorityEngine(),
        deduplicationService: DeduplicationService(),
        vibrationService: VibrationService(),
        flashService: FlashService(),
        notificationService: _MockNotificationService(),
        alertRepository: alertRepo,
      );

      final result = ClassificationResult(
        soundCategory: 'fireAlarm',
        confidence: 0.95,
        timestamp: DateTime.now(),
        topPredictions: const [MapEntry('Fire alarm', 0.95)],
        ambientDbLevel: 75.0,
      );

      await dispatcher.dispatchClassification(
        result: result,
        enabledCategories: {'fireAlarm'},
      );

      // Verify that accessibility announcement channel received the threat announcement
      expect(accessibilityCalls.isNotEmpty, isTrue);
      final announceCall = accessibilityCalls.firstWhere((c) => c.method == 'announce');
      expect(announceCall.arguments['message'], contains('Alert detected: Fire Alarm. High Priority.'));
    });

    testWidgets('SoundCategoryCardsSection Edit button exposes rich accessibility Semantics', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SoundCategoryCardsSection(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final editFinder = find.ancestor(
        of: find.text('Edit'),
        matching: find.byType(Semantics),
      ).first;
      final editSemantics = tester.getSemantics(editFinder);
      expect(editSemantics.label, equals('Edit sound categories'));
      expect(editSemantics.hasAction(SemanticsAction.tap), isTrue);
    });

    testWidgets('AppScaffold Quick Scan button exposes rich accessibility Semantics', (tester) async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageProvider.overrideWithValue(localStorage),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          userSettingsProvider.overrideWith((ref) => SettingsNotifier(ref)
            ..state = const UserSettings(onboardingCompleted: true)),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      final quickScanFinder = find.ancestor(
        of: find.text('Quick Scan'),
        matching: find.byType(Semantics),
      ).first;
      final qsSemantics = tester.getSemantics(quickScanFinder);
      expect(qsSemantics.label, equals('Quick Scan'));
      expect(qsSemantics.hasAction(SemanticsAction.tap), isTrue);
    });
  });

  group('Day 4: Tactile Micro-Haptics (HapticFeedback)', () {
    testWidgets('SegmentedProfileSelector profile switch invokes HapticFeedback.selectionClick', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SegmentedProfileSelector(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      platformCalls.clear();

      // Tap Sleep profile tab
      await tester.tap(find.text('Sleep'));
      await tester.pumpAndSettle();

      // Verify haptic feedback selectionClick was invoked
      final hapticCalls = platformCalls.where(
        (c) => c.method == 'HapticFeedback.vibrate' && c.arguments == 'HapticFeedbackType.selectionClick',
      );
      expect(hapticCalls.isNotEmpty, isTrue);

      // Verify Semantics selected state
      final sleepFinder = find.ancestor(of: find.text('Sleep'), matching: find.byType(Semantics)).first;
      final semantics = tester.getSemantics(sleepFinder);
      expect(semantics.isSelected, isTrue);
    });

    testWidgets('SoundCategoryCardsSection toggle invokes HapticFeedback.selectionClick and sets Semantics', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: SoundCategoryCardsSection(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      platformCalls.clear();

      // Tap first category card
      await tester.tap(find.text('Fire / Smoke'));
      await tester.pumpAndSettle();

      // Verify haptic feedback
      final hapticCalls = platformCalls.where(
        (c) => c.method == 'HapticFeedback.vibrate' && c.arguments == 'HapticFeedbackType.selectionClick',
      );
      expect(hapticCalls.isNotEmpty, isTrue);

      final cardSemantics = find.ancestor(
        of: find.text('Fire / Smoke'),
        matching: find.byType(Semantics),
      ).first;
      final semantics = tester.getSemantics(cardSemantics);
      expect(semantics.label, contains('Fire / Smoke'));
    });

    testWidgets('Bottom navigation tab switches in AppScaffold invoke HapticFeedback.selectionClick', (tester) async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageProvider.overrideWithValue(localStorage),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          userSettingsProvider.overrideWith((ref) => SettingsNotifier(ref)
            ..state = const UserSettings(onboardingCompleted: true)),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pumpAndSettle();

      platformCalls.clear();

      // Tap Insights bottom nav tab
      await tester.tap(find.text('Insights'));
      await tester.pumpAndSettle();

      final hapticCalls = platformCalls.where(
        (c) => c.method == 'HapticFeedback.vibrate' && c.arguments == 'HapticFeedbackType.selectionClick',
      );
      expect(hapticCalls.isNotEmpty, isTrue);
    });

    testWidgets('SensitivityScreen slider moves invoke HapticFeedback.selectionClick', (tester) async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageProvider.overrideWithValue(localStorage),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: SensitivityScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      platformCalls.clear();

      final sliderFinder = find.byType(Slider).first;
      await tester.drag(sliderFinder, const Offset(50, 0));
      await tester.pumpAndSettle();

      final hapticCalls = platformCalls.where(
        (c) => c.method == 'HapticFeedback.vibrate' && c.arguments == 'HapticFeedbackType.selectionClick',
      );
      expect(hapticCalls.isNotEmpty, isTrue);
    });

    testWidgets('HeroSoundRadar center YOU tap invokes HapticFeedback.lightImpact', (tester) async {
      final notifier = _TestListeningNotifier(false);

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isListeningProvider.overrideWith((ref) => notifier),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 300,
                  height: 300,
                  child: HeroSoundRadar(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      platformCalls.clear();

      // Tap center YOU button
      await tester.tap(find.text('YOU'));
      await tester.pumpAndSettle();

      final lightImpactCalls = platformCalls.where(
        (c) => c.method == 'HapticFeedback.vibrate' && c.arguments == 'HapticFeedbackType.lightImpact',
      );
      expect(lightImpactCalls.isNotEmpty, isTrue);
    });
  });
}
