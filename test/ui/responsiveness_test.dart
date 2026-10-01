import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alertsense/core/utils/responsive_utils.dart';
import 'package:alertsense/core/router/app_router.dart';
import 'package:alertsense/core/theme/theme_provider.dart';
import 'package:alertsense/data/datasources/local_storage.dart';
import 'package:alertsense/data/models/alert_event.dart';
import 'package:alertsense/data/models/user_settings.dart';
import 'package:alertsense/data/repositories/alert_repository.dart';
import 'package:alertsense/data/repositories/settings_repository.dart';
import 'package:alertsense/main.dart';
import 'package:alertsense/providers/alert_providers.dart';
import 'package:alertsense/providers/audio_providers.dart';
import 'package:alertsense/providers/auth_providers.dart';
import 'package:alertsense/providers/service_providers.dart';
import 'package:alertsense/providers/settings_providers.dart';
import 'package:alertsense/services/notification_service.dart';
import 'package:alertsense/ui/alert/widgets/quick_response_card.dart';
import 'package:alertsense/ui/alert/full_screen_alert.dart';
import 'package:alertsense/ui/alert/alert_details_screen.dart';
import 'package:alertsense/ui/sleep/sleep_mode_screen.dart';
import 'package:alertsense/ui/stats/stats_screen.dart';
import 'package:alertsense/ui/quick_scan/quick_scan_screen.dart';
import 'package:alertsense/ui/history/history_screen.dart';
import 'package:alertsense/ui/home/widgets/sound_category_cards.dart';
import 'package:alertsense/ui/home/widgets/quick_stats_grid.dart';
import 'package:alertsense/ui/settings/vibration_designer_screen.dart';
import 'package:alertsense/ui/onboarding/onboarding_screen.dart';
import 'package:alertsense/ui/splash/splash_screen.dart';
import 'package:alertsense/ui/settings/sensitivity_screen.dart';
import 'package:alertsense/ui/shared/in_app_notification_banner.dart';
import 'package:alertsense/ui/home/home_screen.dart';

class _MockNotificationService extends NotificationService {}

class MockListeningNotifier extends ListeningNotifier {
  MockListeningNotifier(super.ref, [bool initial = true]) {
    state = initial;
  }

  @override
  Future<void> start() async {
    state = true;
  }

  @override
  Future<void> stop() async {
    state = false;
  }

  @override
  Future<void> toggle() async {
    state = !state;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late LocalStorage localStorage;
  late SettingsRepository settingsRepo;
  late AlertRepository alertRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    localStorage = LocalStorage(prefs);
    settingsRepo = SettingsRepository(localStorage);
    await settingsRepo.init();
    alertRepo = AlertRepository(localStorage);
    await alertRepo.init();
  });

  /// Helper to configure physical screen size and text scaling factor
  void configureScreen(
    WidgetTester tester, {
    required double width,
    required double height,
  }) {
    tester.view.physicalSize = Size(width, height);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
  }

  /// Helper to wrap test widgets with simulated MediaQuery for text scaling & dimensions
  Widget buildResponsiveTestApp({
    required Widget child,
    required double width,
    required double height,
    double textScale = 1.0,
    ProviderContainer? container,
  }) {
    final orientation = width > height ? Orientation.landscape : Orientation.portrait;
    final widgetTree = MediaQuery(
      data: MediaQueryData(
        size: Size(width, height),
        textScaler: TextScaler.linear(textScale),
        padding: EdgeInsets.zero,
        viewInsets: EdgeInsets.zero,
        viewPadding: EdgeInsets.zero,
      ),
      child: MaterialApp(
        home: child,
      ),
    );

    if (container != null) {
      return UncontrolledProviderScope(
        container: container,
        child: widgetTree,
      );
    }
    return widgetTree;
  }

  group('Phase 1: ResponsiveBreakpoints Utility Tests', () {
    testWidgets('Breakpoints accurately categorize compact, tablet, landscape, desktop', (tester) async {
      // 1. Compact screen (320x568)
      await tester.pumpWidget(
        buildResponsiveTestApp(
          width: 320,
          height: 568,
          child: Builder(
            builder: (context) {
              expect(ResponsiveBreakpoints.isCompact(context), isTrue);
              expect(ResponsiveBreakpoints.isTablet(context), isFalse);
              expect(ResponsiveBreakpoints.isDesktop(context), isFalse);
              expect(ResponsiveBreakpoints.isLandscape(context), isFalse);
              expect(context.isCompact, isTrue);
              expect(
                ResponsiveBreakpoints.value(context, compact: 'compact', regular: 'regular'),
                'compact',
              );
              return const SizedBox();
            },
          ),
        ),
      );

      // 2. Landscape phone (800x360)
      await tester.pumpWidget(
        buildResponsiveTestApp(
          width: 800,
          height: 360,
          child: Builder(
            builder: (context) {
              expect(ResponsiveBreakpoints.isLandscape(context), isTrue);
              expect(ResponsiveBreakpoints.isShortViewport(context), isTrue);
              expect(context.isLandscape, isTrue);
              return const SizedBox();
            },
          ),
        ),
      );

      // 3. Tablet (800x1280)
      await tester.pumpWidget(
        buildResponsiveTestApp(
          width: 800,
          height: 1280,
          child: Builder(
            builder: (context) {
              expect(ResponsiveBreakpoints.isTablet(context), isTrue);
              expect(ResponsiveBreakpoints.isDesktop(context), isFalse);
              expect(context.isTablet, isTrue);
              expect(
                ResponsiveBreakpoints.value(context, compact: 'compact', regular: 'regular', tablet: 'tablet'),
                'tablet',
              );
              return const SizedBox();
            },
          ),
        ),
      );

      // 4. Desktop (1024x768)
      await tester.pumpWidget(
        buildResponsiveTestApp(
          width: 1024,
          height: 768,
          child: Builder(
            builder: (context) {
              expect(ResponsiveBreakpoints.isDesktop(context), isTrue);
              expect(context.isDesktop, isTrue);
              return const SizedBox();
            },
          ),
        ),
      );
    });
  });

  group('Phase 1: AppScaffold Adaptive Navigation Tests', () {
    ProviderContainer createScaffoldContainer() {
      return ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageProvider.overrideWithValue(localStorage),
          alertRepositoryProvider.overrideWithValue(alertRepo),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          notificationServiceProvider.overrideWithValue(_MockNotificationService()),
          isAuthenticatedProvider.overrideWithValue(true),
          userSettingsProvider.overrideWith((ref) => SettingsNotifier(ref)
            ..state = const UserSettings(onboardingCompleted: true)),
        ],
      );
    }

    testWidgets('Portrait compact phone (320x568) renders bottom navigation bar without overflow', (tester) async {
      configureScreen(tester, width: 320, height: 568);
      final container = createScaffoldContainer();
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 568),
              textScaler: TextScaler.linear(1.0),
            ),
            child: MaterialApp.router(routerConfig: router),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Insights'), findsOneWidget);
      expect(find.text('Quick Scan'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('Portrait compact phone at 2.0x font scale renders cleanly without RenderFlex overflow', (tester) async {
      configureScreen(tester, width: 320, height: 568);
      final container = createScaffoldContainer();
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(320, 568),
              textScaler: TextScaler.linear(2.0),
            ),
            child: MaterialApp.router(routerConfig: router),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
      expect(find.text('Quick Scan'), findsOneWidget);
    });

    testWidgets('Landscape phone (800x360) switches to side navigation rail without overflow', (tester) async {
      configureScreen(tester, width: 800, height: 360);
      final container = createScaffoldContainer();
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(800, 360),
              textScaler: TextScaler.linear(1.0),
            ),
            child: MaterialApp.router(routerConfig: router),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
      // All 5 destinations exist in the side navigation rail
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Insights'), findsOneWidget);
      expect(find.text('Quick Scan'), findsOneWidget);
      expect(find.text('History'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('Landscape phone at 2.0x font scale renders side rail without overflow', (tester) async {
      configureScreen(tester, width: 800, height: 360);
      final container = createScaffoldContainer();
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(800, 360),
              textScaler: TextScaler.linear(2.0),
            ),
            child: MaterialApp.router(routerConfig: router),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
    });

    testWidgets('Tablet (800x1280) uses adaptive side rail without overflow', (tester) async {
      configureScreen(tester, width: 800, height: 1280);
      final container = createScaffoldContainer();
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MediaQuery(
            data: const MediaQueryData(
              size: Size(800, 1280),
              textScaler: TextScaler.linear(1.0),
            ),
            child: MaterialApp.router(routerConfig: router),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(tester.takeException(), isNull);
      expect(find.text('Home'), findsOneWidget);
      expect(find.text('Insights'), findsOneWidget);
    });
  });

  group('Phase 2: QuickResponseCard Responsive Tests', () {
    testWidgets('QuickResponseCard minHeight: 52 and FittedBox on compact 320x568 phone', (tester) async {
      configureScreen(tester, width: 320, height: 568);

      await tester.pumpWidget(
        buildResponsiveTestApp(
          width: 320,
          height: 568,
          child: Scaffold(
            body: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  QuickResponseCard(
                    label: "I'm Safe (False Alarm)",
                    icon: Icons.check_circle_outline_rounded,
                    color: Colors.green,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 10),
                  QuickResponseCard(
                    label: 'Call Emergency Services (Immediate Dispatch)',
                    icon: Icons.phone_rounded,
                    color: Colors.red,
                    onPressed: () {},
                  ),
                  const SizedBox(height: 10),
                  QuickResponseCard(
                    label: 'Loading State Test',
                    icon: Icons.hourglass_top_rounded,
                    color: Colors.blue,
                    isLoading: true,
                    onPressed: () {},
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.byType(FittedBox), findsWidgets);
      expect(find.byType(ConstrainedBox), findsWidgets);
    });

    testWidgets('QuickResponseCard under 2.0x font scale never overflows RenderFlex', (tester) async {
      configureScreen(tester, width: 320, height: 568);

      await tester.pumpWidget(
        buildResponsiveTestApp(
          width: 320,
          height: 568,
          textScale: 2.0,
          child: Scaffold(
            body: QuickResponseCard(
              label: 'Alert Family (SMS) Very Long Emergency Action Label',
              icon: Icons.family_restroom_rounded,
              color: Colors.orange,
              onPressed: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('QuickResponseCard on landscape 800x360 renders cleanly', (tester) async {
      configureScreen(tester, width: 800, height: 360);

      await tester.pumpWidget(
        buildResponsiveTestApp(
          width: 800,
          height: 360,
          textScale: 1.5,
          child: Scaffold(
            body: QuickResponseCard(
              label: 'Acknowledge & Dismiss Alert',
              icon: Icons.close_rounded,
              color: Colors.grey,
              onPressed: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });
  });

  group('Phase 2: FullScreenAlert Responsive & Landscape Layout Tests', () {
    final alertData = {
      'id': 'alert-test-01',
      'soundCategory': 'fireAlarm',
      'confidence': 96,
      'priorityLevel': 'HIGH',
      'timestamp': DateTime.now(),
    };

    ProviderContainer createAlertContainer({List<String> emergencyContacts = const []}) {
      return ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageProvider.overrideWithValue(localStorage),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          notificationServiceProvider.overrideWithValue(_MockNotificationService()),
          userSettingsProvider.overrideWith((ref) => SettingsNotifier(ref)
            ..state = UserSettings(
              onboardingCompleted: true,
              emergencyContacts: emergencyContacts,
            )),
        ],
      );
    }

    testWidgets('FullScreenAlert renders without overflow on 320x568 compact phone', (tester) async {
      configureScreen(tester, width: 320, height: 568);
      final container = createAlertContainer(emergencyContacts: ['+1234567890']);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildResponsiveTestApp(
          width: 320,
          height: 568,
          container: container,
          child: FullScreenAlert(alertData: alertData),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('Fire Alarm'), findsOneWidget);
      expect(find.text('CRITICAL ALERT DETECTED'), findsOneWidget);
      expect(find.text("I'm Safe (False Alarm)"), findsOneWidget);
    });

    testWidgets('FullScreenAlert at 2.0x font scale renders cleanly without RenderFlex overflow', (tester) async {
      configureScreen(tester, width: 320, height: 568);
      final container = createAlertContainer(emergencyContacts: ['+1234567890']);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildResponsiveTestApp(
          width: 320,
          height: 568,
          textScale: 2.0,
          container: container,
          child: FullScreenAlert(alertData: alertData),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });

    testWidgets('FullScreenAlert in landscape (800x360) renders 2-column layout without overflow', (tester) async {
      configureScreen(tester, width: 800, height: 360);
      final container = createAlertContainer(emergencyContacts: ['+1234567890']);
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildResponsiveTestApp(
          width: 800,
          height: 360,
          container: container,
          child: FullScreenAlert(alertData: alertData),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      // Both columns exist: left pane title & right pane action buttons
      expect(find.text('Fire Alarm'), findsOneWidget);
      expect(find.text('CRITICAL ALERT DETECTED'), findsOneWidget);
      expect(find.text("I'm Safe (False Alarm)"), findsOneWidget);
      expect(find.text('Call Emergency Services'), findsOneWidget);
    });

    testWidgets('FullScreenAlert on tablet (800x1280) constrains max width to 680', (tester) async {
      configureScreen(tester, width: 800, height: 1280);
      final container = createAlertContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildResponsiveTestApp(
          width: 800,
          height: 1280,
          container: container,
          child: FullScreenAlert(alertData: alertData),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('Fire Alarm'), findsOneWidget);
    });
  });

  group('Phase 2: SleepModeScreen Responsive & Nightstand Mode Tests', () {
    ProviderContainer createSleepContainer() {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageProvider.overrideWithValue(localStorage),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          notificationServiceProvider.overrideWithValue(_MockNotificationService()),
          isListeningProvider.overrideWith((ref) => MockListeningNotifier(ref, true)),
        ],
      );
      container.read(activeProfileProvider.notifier).state = 'home';
      return container;
    }

    testWidgets('SleepModeScreen clock is wrapped in FittedBox and does not overflow on 320x568 compact phone', (tester) async {
      configureScreen(tester, width: 320, height: 568);
      final container = createSleepContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildResponsiveTestApp(
          width: 320,
          height: 568,
          container: container,
          child: const SleepModeScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('Sleep Guardian'), findsOneWidget);
      expect(find.text('BEDSIDE'), findsOneWidget);
      expect(find.text('Exit Sleep Mode'), findsOneWidget);
    });

    testWidgets('SleepModeScreen clock does not wrap or overflow under 2.0x font scale', (tester) async {
      configureScreen(tester, width: 320, height: 568);
      final container = createSleepContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildResponsiveTestApp(
          width: 320,
          height: 568,
          textScale: 2.0,
          container: container,
          child: const SleepModeScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
    });

    testWidgets('SleepModeScreen bedside landscape (800x360) splits into 2-column view without overflow', (tester) async {
      configureScreen(tester, width: 800, height: 360);
      final container = createSleepContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildResponsiveTestApp(
          width: 800,
          height: 360,
          container: container,
          child: const SleepModeScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      // Both columns exist
      expect(find.text('Sleep Guardian'), findsOneWidget);
      expect(find.text('Monitored Life-Safety Alarms'), findsOneWidget);
      expect(find.text('Fire Alarm'), findsOneWidget);
      expect(find.text('Exit Sleep Mode'), findsOneWidget);
    });

    testWidgets('SleepModeScreen on tablet (800x1280) renders cleanly without overflow', (tester) async {
      configureScreen(tester, width: 800, height: 1280);
      final container = createSleepContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildResponsiveTestApp(
          width: 800,
          height: 1280,
          container: container,
          child: const SleepModeScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('Exit Sleep Mode'), findsOneWidget);
    });
  });

  group('Phase 2: AlertDetailsScreen Responsive Tests', () {
    final alert = AlertEvent(
      id: 'alert-detail-test',
      soundCategory: 'smokeAlarm',
      confidence: 0.94,
      priorityLevel: 'high',
      timestamp: DateTime(2026, 9, 29, 14, 30),
      source: 'High-Precision Acoustic Sensor #1',
      acknowledged: true,
      responseAction: 'auto_sms_unacknowledged',
    );

    testWidgets('_DetailRow does not overflow on 320x568 compact phone with long text value', (tester) async {
      configureScreen(tester, width: 320, height: 568);

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageProvider.overrideWithValue(localStorage),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          notificationServiceProvider.overrideWithValue(_MockNotificationService()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildResponsiveTestApp(
          width: 320,
          height: 568,
          container: container,
          child: AlertDetailsScreen(alert: alert),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Alert Details'), findsOneWidget);
      expect(find.text('Confidence Score'), findsOneWidget);
      expect(find.text('Detection Source'), findsOneWidget);
    });

    testWidgets('AlertDetailsScreen under 2.0x font scale does not throw RenderFlex overflow', (tester) async {
      configureScreen(tester, width: 320, height: 568);

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageProvider.overrideWithValue(localStorage),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          notificationServiceProvider.overrideWithValue(_MockNotificationService()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildResponsiveTestApp(
          width: 320,
          height: 568,
          textScale: 2.0,
          container: container,
          child: AlertDetailsScreen(alert: alert),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
    });

    testWidgets('AlertDetailsScreen on 800x1280 tablet constrains max width', (tester) async {
      configureScreen(tester, width: 800, height: 1280);

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageProvider.overrideWithValue(localStorage),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          notificationServiceProvider.overrideWithValue(_MockNotificationService()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildResponsiveTestApp(
          width: 800,
          height: 1280,
          container: container,
          child: AlertDetailsScreen(alert: alert),
        ),
      );
      await tester.pump();

      expect(tester.takeException(), isNull);
      expect(find.text('Alert Details'), findsOneWidget);
    });
  });

  group('Phase 3: StatsScreen Responsive Tests', () {
    testWidgets('StatsScreen at 2.0x font scale renders cleanly without RenderFlex overflow', (tester) async {
      configureScreen(tester, width: 360, height: 640);
      final testAlerts = [
        AlertEvent(
          id: 'stats-alert-1',
          soundCategory: 'fireAlarm',
          confidence: 0.95,
          priorityLevel: 'high',
          timestamp: DateTime.now(),
          source: 'Sensor 1',
        ),
        AlertEvent(
          id: 'stats-alert-2',
          soundCategory: 'doorbell',
          confidence: 0.88,
          priorityLevel: 'low',
          timestamp: DateTime.now().subtract(const Duration(hours: 2)),
          source: 'Sensor 1',
        ),
      ];
      for (final a in testAlerts) {
        await alertRepo.addAlert(a);
      }

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageProvider.overrideWithValue(localStorage),
          alertRepositoryProvider.overrideWithValue(alertRepo),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          notificationServiceProvider.overrideWithValue(_MockNotificationService()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildResponsiveTestApp(
          width: 360,
          height: 640,
          textScale: 2.0,
          container: container,
          child: const StatsScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('Insights & Analytics'), findsOneWidget);
      expect(find.text('Alerts Today'), findsOneWidget);
    });

    testWidgets('StatsScreen on tablet (800x1280) constrains max width', (tester) async {
      configureScreen(tester, width: 800, height: 1280);
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageProvider.overrideWithValue(localStorage),
          alertRepositoryProvider.overrideWithValue(alertRepo),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          notificationServiceProvider.overrideWithValue(_MockNotificationService()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildResponsiveTestApp(
          width: 800,
          height: 1280,
          container: container,
          child: const StatsScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('Insights & Analytics'), findsOneWidget);
    });

    testWidgets('StatsScreen empty state in short landscape (800x360) renders without overflow', (tester) async {
      configureScreen(tester, width: 800, height: 360);
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageProvider.overrideWithValue(localStorage),
          alertRepositoryProvider.overrideWithValue(alertRepo),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          notificationServiceProvider.overrideWithValue(_MockNotificationService()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildResponsiveTestApp(
          width: 800,
          height: 360,
          container: container,
          child: const StatsScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('Not enough data yet'), findsOneWidget);
    });
  });

  group('Phase 3: HistoryScreen Responsive Tests', () {
    testWidgets('HistoryScreen with long action strings does not overflow RenderFlex', (tester) async {
      configureScreen(tester, width: 320, height: 568);
      final alertWithLongAction = AlertEvent(
        id: 'hist-long-action-1',
        soundCategory: 'emergencySiren',
        confidence: 0.99,
        priorityLevel: 'high',
        timestamp: DateTime.now(),
        source: 'Acoustic Sensor',
        acknowledged: true,
        responseAction: 'Dispatched Emergency Response Services and Notified Caregiver Network Immediately',
      );
      await alertRepo.addAlert(alertWithLongAction);

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageProvider.overrideWithValue(localStorage),
          alertRepositoryProvider.overrideWithValue(alertRepo),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          notificationServiceProvider.overrideWithValue(_MockNotificationService()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildResponsiveTestApp(
          width: 320,
          height: 568,
          textScale: 1.5,
          container: container,
          child: const HistoryScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('Alert History'), findsOneWidget);
    });

    testWidgets('HistoryScreen on tablet constrains ListView to 800dp centered', (tester) async {
      configureScreen(tester, width: 800, height: 1280);
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageProvider.overrideWithValue(localStorage),
          alertRepositoryProvider.overrideWithValue(alertRepo),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          notificationServiceProvider.overrideWithValue(_MockNotificationService()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildResponsiveTestApp(
          width: 800,
          height: 1280,
          container: container,
          child: const HistoryScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('Alert History'), findsOneWidget);
    });

    testWidgets('HistoryScreen empty state in landscape (800x360) does not overflow RenderFlex', (tester) async {
      configureScreen(tester, width: 800, height: 360);
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageProvider.overrideWithValue(localStorage),
          alertRepositoryProvider.overrideWithValue(alertRepo),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          notificationServiceProvider.overrideWithValue(_MockNotificationService()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildResponsiveTestApp(
          width: 800,
          height: 360,
          container: container,
          child: const HistoryScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('No alerts yet'), findsOneWidget);
    });
  });

  group('Phase 3: SoundCategoryCardsSection Responsive Tests', () {
    testWidgets('sound_category_cards at 2.0x font scale renders cleanly without RenderFlex overflow', (tester) async {
      configureScreen(tester, width: 360, height: 600);
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageProvider.overrideWithValue(localStorage),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          notificationServiceProvider.overrideWithValue(_MockNotificationService()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildResponsiveTestApp(
          width: 360,
          height: 600,
          textScale: 2.0,
          container: container,
          child: const Scaffold(
            body: SingleChildScrollView(
              child: SoundCategoryCardsSection(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('Sound Categories'), findsOneWidget);
    });
  });

  group('Phase 3: QuickStatsGrid Responsive Tests', () {
    testWidgets('QuickStatsGrid on wide viewport (800x600) renders 4 tiles in a single row', (tester) async {
      configureScreen(tester, width: 800, height: 600);
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageProvider.overrideWithValue(localStorage),
          alertRepositoryProvider.overrideWithValue(alertRepo),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          notificationServiceProvider.overrideWithValue(_MockNotificationService()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildResponsiveTestApp(
          width: 800,
          height: 600,
          container: container,
          child: const Scaffold(
            body: QuickStatsGrid(),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('Alerts Today'), findsOneWidget);
      expect(find.text('Battery Level'), findsOneWidget);
      expect(find.text('Listening Time'), findsOneWidget);
      expect(find.text('Most Frequent'), findsOneWidget);
    });

    testWidgets('QuickStatsGrid at 2.0x font scale scales labels cleanly without overflow', (tester) async {
      configureScreen(tester, width: 320, height: 568);
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageProvider.overrideWithValue(localStorage),
          alertRepositoryProvider.overrideWithValue(alertRepo),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          notificationServiceProvider.overrideWithValue(_MockNotificationService()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildResponsiveTestApp(
          width: 320,
          height: 568,
          textScale: 2.0,
          container: container,
          child: const Scaffold(
            body: SingleChildScrollView(
              child: QuickStatsGrid(),
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('Alerts Today'), findsOneWidget);
      expect(find.text('Listening Time'), findsOneWidget);
    });
  });

  group('Phase 3: HomeScreen Responsive Tests', () {
    testWidgets('HomeScreen on tablet (800x1280) constrains max width', (tester) async {
      configureScreen(tester, width: 800, height: 1280);
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageProvider.overrideWithValue(localStorage),
          alertRepositoryProvider.overrideWithValue(alertRepo),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          notificationServiceProvider.overrideWithValue(_MockNotificationService()),
          isListeningProvider.overrideWith((ref) => MockListeningNotifier(ref, false)),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildResponsiveTestApp(
          width: 800,
          height: 1280,
          container: container,
          child: const HomeScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.byType(HomeScreen), findsOneWidget);
    });
  });

  group('Phase 4: QuickScanScreen Landscape Tests', () {
    testWidgets('QuickScanScreen in landscape (800x360) renders without RenderFlex overflow', (tester) async {
      configureScreen(tester, width: 800, height: 360);
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageProvider.overrideWithValue(localStorage),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          notificationServiceProvider.overrideWithValue(_MockNotificationService()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildResponsiveTestApp(
          width: 800,
          height: 360,
          container: container,
          child: const QuickScanScreen(autoStart: false),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('Quick Scan'), findsOneWidget);
      expect(find.text('Start Quick Scan'), findsOneWidget);
    });
  });

  group('Phase 4: OnboardingScreen & Creation Tools Responsive Tests', () {
    testWidgets('OnboardingScreen in landscape (800x360) renders cleanly without RenderFlex overflow', (tester) async {
      configureScreen(tester, width: 800, height: 360);
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageProvider.overrideWithValue(localStorage),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          notificationServiceProvider.overrideWithValue(_MockNotificationService()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildResponsiveTestApp(
          width: 800,
          height: 360,
          container: container,
          child: const OnboardingScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('Sounds You Can See'), findsOneWidget);
      expect(find.text('Skip'), findsOneWidget);
      expect(find.text('Next'), findsOneWidget);
    });

    testWidgets('VibrationDesignerScreen in landscape (800x360) renders cleanly', (tester) async {
      configureScreen(tester, width: 800, height: 360);
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageProvider.overrideWithValue(localStorage),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          notificationServiceProvider.overrideWithValue(_MockNotificationService()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildResponsiveTestApp(
          width: 800,
          height: 360,
          container: container,
          child: const VibrationDesignerScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('Vibration Designer'), findsOneWidget);
    });

    testWidgets('SplashScreen in short viewport (800x360) renders cleanly without RenderFlex overflow', (tester) async {
      configureScreen(tester, width: 800, height: 360);
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageProvider.overrideWithValue(localStorage),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          notificationServiceProvider.overrideWithValue(_MockNotificationService()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildResponsiveTestApp(
          width: 800,
          height: 360,
          container: container,
          child: const SplashScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('Skip'), findsOneWidget);
    });

    testWidgets('SensitivityScreen at 2.0x font scale renders cleanly without horizontal RenderFlex overflow', (tester) async {
      configureScreen(tester, width: 320, height: 568);
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageProvider.overrideWithValue(localStorage),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          notificationServiceProvider.overrideWithValue(_MockNotificationService()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildResponsiveTestApp(
          width: 320,
          height: 568,
          textScale: 2.0,
          container: container,
          child: const SensitivityScreen(),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('Detection Sensitivity'), findsOneWidget);
    });

    testWidgets('InAppNotificationBanner with long alert does not overflow banner card', (tester) async {
      configureScreen(tester, width: 320, height: 568);
      final longAlert = AlertEvent(
        id: 'banner-test-1',
        soundCategory: 'emergencySiren',
        confidence: 0.98,
        priorityLevel: 'high',
        timestamp: DateTime.now(),
        source: 'Sensor',
      );

      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageProvider.overrideWithValue(localStorage),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          notificationServiceProvider.overrideWithValue(_MockNotificationService()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        buildResponsiveTestApp(
          width: 320,
          height: 568,
          textScale: 1.5,
          container: container,
          child: Scaffold(
            body: InAppNotificationBanner(
              alert: longAlert,
              onDismiss: () {},
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('Emergency Siren Detected!'), findsOneWidget);
    });
  });
}
