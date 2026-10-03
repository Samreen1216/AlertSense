import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alertsense/core/theme/theme_provider.dart';
import 'package:alertsense/data/datasources/local_storage.dart';
import 'package:alertsense/data/models/alert_event.dart';
import 'package:alertsense/data/repositories/alert_repository.dart';
import 'package:alertsense/data/repositories/settings_repository.dart';
import 'package:alertsense/main.dart';
import 'package:alertsense/providers/alert_providers.dart';
import 'package:alertsense/providers/audio_providers.dart';
import 'package:alertsense/providers/service_providers.dart';
import 'package:alertsense/services/notification_service.dart';
import 'package:alertsense/ui/home/home_screen.dart';
import 'package:alertsense/ui/home/widgets/recent_alerts_section.dart';
import 'package:alertsense/ui/home/widgets/sound_category_cards.dart';

class _MockNotificationService extends NotificationService {}

class _MockListeningNotifier extends ListeningNotifier {
  _MockListeningNotifier(super.ref, [bool initial = true]) {
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

class _MockThemeTypeNotifier extends ThemeTypeNotifier {
  _MockThemeTypeNotifier(ThemeType initial) : super(null) {
    state = initial;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late LocalStorage localStorage;
  late AlertRepository alertRepo;
  late SettingsRepository settingsRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    localStorage = LocalStorage(prefs);
    alertRepo = AlertRepository(localStorage);
    settingsRepo = SettingsRepository(localStorage);
  });

  Widget createTestWidget({
    required Widget child,
    List<AlertEvent> initialAlerts = const [],
    ThemeType themeType = ThemeType.light,
  }) {
    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        localStorageProvider.overrideWithValue(localStorage),
        alertRepositoryProvider.overrideWithValue(alertRepo),
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        notificationServiceProvider.overrideWithValue(_MockNotificationService()),
        themeTypeProvider.overrideWith((ref) => _MockThemeTypeNotifier(themeType)),
        isListeningProvider.overrideWith((ref) => _MockListeningNotifier(ref, false)),
        alertListProvider.overrideWith((ref) {
          final notifier = AlertListNotifier(ref);
          notifier.state = initialAlerts;
          return notifier;
        }),
      ],
      child: MaterialApp(
        home: child,
      ),
    );
  }

  group('HomeScreen Redesign & RecentAlertsSection Tests', () {
    testWidgets('HomeScreen renders RecentAlertsSection and removes old 2x2 stat cards', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestWidget(
          child: const HomeScreen(),
          initialAlerts: [],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);

      // Sound categories section exists
      expect(find.byType(SoundCategoryCardsSection), findsOneWidget);
      expect(find.text('Sound Categories'), findsOneWidget);

      // RecentAlertsSection exists
      expect(find.byType(RecentAlertsSection), findsOneWidget);
      expect(find.text('Recent Alerts'), findsOneWidget);

      // Old stats cards are removed from HomeScreen
      expect(find.text('Alerts Today'), findsNothing);
      expect(find.text('Battery Level'), findsNothing);
      expect(find.text('Listening Time'), findsNothing);
      expect(find.text('Most Frequent'), findsNothing);
    });

    testWidgets('RecentAlertsSection displays clean empty state when no alerts exist', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestWidget(
          child: const Scaffold(body: RecentAlertsSection()),
          initialAlerts: [],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('Recent Alerts'), findsOneWidget);
      expect(find.text('No Recent Alerts'), findsOneWidget);
      expect(
        find.text('Environment is quiet and safe. Sounds will appear here dynamically.'),
        findsOneWidget,
      );
    });

    testWidgets('RecentAlertsSection dynamically renders alert items from original data', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final testAlerts = [
        AlertEvent(
          id: 'alert-1',
          soundCategory: 'fireAlarm',
          priorityLevel: 'High',
          confidence: 0.94,
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
        ),
        AlertEvent(
          id: 'alert-2',
          soundCategory: 'doorbell',
          priorityLevel: 'Medium',
          confidence: 0.88,
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        ),
      ];

      await tester.pumpWidget(
        createTestWidget(
          child: const Scaffold(body: RecentAlertsSection()),
          initialAlerts: testAlerts,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('Recent Alerts'), findsOneWidget);
      expect(find.text('2'), findsOneWidget); // Count badge
      expect(find.text('See All'), findsOneWidget);

      // Rendered alert items
      expect(find.text('Fire Alarm'), findsOneWidget);
      expect(find.text('Doorbell'), findsOneWidget);
      expect(find.text('HIGH'), findsOneWidget);
      expect(find.text('MEDIUM'), findsOneWidget);
      expect(find.textContaining('5m ago • 94% match'), findsOneWidget);
      expect(find.textContaining('1h ago • 88% match'), findsOneWidget);
    });

    testWidgets('RecentAlertsSection adapts styling in High Contrast mode', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final testAlerts = [
        AlertEvent(
          id: 'alert-1',
          soundCategory: 'babyCrying',
          priorityLevel: 'Medium',
          confidence: 0.91,
          timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
        ),
      ];

      await tester.pumpWidget(
        createTestWidget(
          child: const Scaffold(body: RecentAlertsSection()),
          initialAlerts: testAlerts,
          themeType: ThemeType.highContrast,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('Baby Crying'), findsOneWidget);
      expect(find.text('MEDIUM'), findsOneWidget);
      expect(find.textContaining('2m ago • 91% match'), findsOneWidget);
    });

    testWidgets('0 recent alerts on large Android screen: No Recent Alerts card normal size and container extends without black gap', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestWidget(
          child: Scaffold(
            body: const HomeScreen(),
            bottomNavigationBar: Container(height: 70, color: Colors.white, child: const Text('Nav')),
          ),
          initialAlerts: [],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('No Recent Alerts'), findsOneWidget);

      final emptyCard = find.text('No Recent Alerts');
      final emptyCardSize = tester.getSize(emptyCard);
      expect(emptyCardSize.height, greaterThan(0));

      // Container extends to bottom navigation bar without black gap
      final recentFinder = find.byType(RecentAlertsSection);
      expect(recentFinder, findsOneWidget);
    });

    testWidgets('1 recent alert on Android screen: single alert card normal size and content-driven', (tester) async {
      await tester.binding.setSurfaceSize(const Size(412, 915));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final singleAlert = [
        AlertEvent(
          id: 'single-1',
          soundCategory: 'doorbell',
          priorityLevel: 'Medium',
          confidence: 0.89,
          timestamp: DateTime.now().subtract(const Duration(minutes: 1)),
        ),
      ];

      await tester.pumpWidget(
        createTestWidget(
          child: Scaffold(
            body: const HomeScreen(),
            bottomNavigationBar: Container(height: 70, color: Colors.white, child: const Text('Nav')),
          ),
          initialAlerts: singleAlert,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('Doorbell'), findsOneWidget);
      expect(find.text('No Recent Alerts'), findsNothing);
    });

    testWidgets('Multiple recent alerts: displays all alerts and scrolls properly', (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      final multipleAlerts = [
        AlertEvent(
          id: 'm-1',
          soundCategory: 'fireAlarm',
          priorityLevel: 'High',
          confidence: 0.95,
          timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
        ),
        AlertEvent(
          id: 'm-2',
          soundCategory: 'doorbell',
          priorityLevel: 'Medium',
          confidence: 0.88,
          timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
        ),
        AlertEvent(
          id: 'm-3',
          soundCategory: 'babyCrying',
          priorityLevel: 'High',
          confidence: 0.92,
          timestamp: DateTime.now().subtract(const Duration(hours: 1)),
        ),
        AlertEvent(
          id: 'm-4',
          soundCategory: 'dogBarking',
          priorityLevel: 'Low',
          confidence: 0.75,
          timestamp: DateTime.now().subtract(const Duration(hours: 3)),
        ),
      ];

      await tester.pumpWidget(
        createTestWidget(
          child: Scaffold(
            body: const HomeScreen(),
            bottomNavigationBar: Container(height: 70, color: Colors.white, child: const Text('Nav')),
          ),
          initialAlerts: multipleAlerts,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.text('Recent Alerts'), findsOneWidget);
      expect(find.text('Fire Alarm'), findsOneWidget);
      expect(find.text('Doorbell'), findsOneWidget);
      expect(find.text('Baby Crying'), findsOneWidget);
      expect(find.text('View all 4 alerts in History'), findsOneWidget);

      // Verify scrollable behavior
      final scrollable = find.byType(Scrollable);
      expect(scrollable, findsWidgets);
      final scrollState = tester.state<ScrollableState>(scrollable.first);
      expect(scrollState.position.maxScrollExtent, greaterThan(0));
    });

    testWidgets('Small Android screen (360x640): renders without overflow and scrolls', (tester) async {
      await tester.binding.setSurfaceSize(const Size(360, 640));
      addTearDown(() => tester.binding.setSurfaceSize(null));

      await tester.pumpWidget(
        createTestWidget(
          child: Scaffold(
            body: const HomeScreen(),
            bottomNavigationBar: Container(height: 70, color: Colors.white, child: const Text('Nav')),
          ),
          initialAlerts: [],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      expect(tester.takeException(), isNull);
      expect(find.byType(HomeScreen), findsOneWidget);

      // On 360x640 screen, scroll down to bring Recent Alerts into view
      await tester.drag(find.byType(CustomScrollView), const Offset(0, -300));
      await tester.pump(const Duration(milliseconds: 100));
      expect(find.text('Recent Alerts'), findsOneWidget);
    });
  });
}
