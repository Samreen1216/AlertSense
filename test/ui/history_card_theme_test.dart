import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alertsense/core/constants/app_colors.dart';
import 'package:alertsense/core/theme/app_theme.dart';
import 'package:alertsense/core/theme/theme_provider.dart';
import 'package:alertsense/data/datasources/local_storage.dart';
import 'package:alertsense/data/models/alert_event.dart';
import 'package:alertsense/data/repositories/alert_repository.dart';
import 'package:alertsense/data/repositories/settings_repository.dart';
import 'package:alertsense/main.dart';
import 'package:alertsense/providers/service_providers.dart';
import 'package:alertsense/services/notification_service.dart';
import 'package:alertsense/ui/history/history_screen.dart';
import 'package:alertsense/ui/shared/sound_icon.dart';

class MockNotificationService extends NotificationService {}

class FakeThemeTypeNotifier extends ThemeTypeNotifier {
  FakeThemeTypeNotifier(ThemeType initial) : super(null) {
    state = initial;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('HistoryScreen Card Border & Theme Calibration Tests', () {
    late AlertRepository alertRepo;
    late SettingsRepository settingsRepo;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      final prefs = await SharedPreferences.getInstance();
      final storage = LocalStorage(prefs);
      alertRepo = AlertRepository(storage);
      await alertRepo.init();
      settingsRepo = SettingsRepository(storage);
      await settingsRepo.init();

      // Add high, medium, and low priority alerts
      await alertRepo.addAlert(
        AlertEvent(
          id: 'alert_high',
          soundCategory: 'fireAlarm',
          priorityLevel: 'high',
          confidence: 0.95,
          timestamp: DateTime.now(),
          acknowledged: false,
          source: 'live_mic',
        ),
      );
      await alertRepo.addAlert(
        AlertEvent(
          id: 'alert_med',
          soundCategory: 'knocking',
          priorityLevel: 'medium',
          confidence: 0.85,
          timestamp: DateTime.now().subtract(const Duration(minutes: 5)),
          acknowledged: false,
          source: 'live_mic',
        ),
      );
      await alertRepo.addAlert(
        AlertEvent(
          id: 'alert_low',
          soundCategory: 'dogBarking',
          priorityLevel: 'low',
          confidence: 0.78,
          timestamp: DateTime.now().subtract(const Duration(minutes: 10)),
          acknowledged: false,
          source: 'live_mic',
        ),
      );
    });

    Future<void> pumpHistoryScreen(
      WidgetTester tester, {
      required ThemeType themeType,
      required ThemeData themeData,
    }) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            alertRepositoryProvider.overrideWithValue(alertRepo),
            settingsRepositoryProvider.overrideWithValue(settingsRepo),
            notificationServiceProvider.overrideWithValue(MockNotificationService()),
            themeTypeProvider.overrideWith((ref) => FakeThemeTypeNotifier(themeType)),
          ],
          child: MaterialApp(
            theme: themeData,
            home: const HistoryScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    testWidgets('Light mode cards have clean slate border, 16px radius, and white surface', (tester) async {
      await pumpHistoryScreen(
        tester,
        themeType: ThemeType.light,
        themeData: AppTheme.getLight(),
      );

      final cards = tester.widgetList<Card>(find.byType(Card)).toList();
      expect(cards.length, greaterThanOrEqualTo(3));

      for (final card in cards) {
        expect(card.color, equals(Colors.white));
        final shape = card.shape as RoundedRectangleBorder;
        expect(shape.borderRadius, equals(BorderRadius.circular(16)));
        // Border color is clean slate (0xFFE2E8F0), NOT dirty alpha red or orange
        expect(shape.side.color, equals(const Color(0xFFE2E8F0)));
        expect(shape.side.color, isNot(equals(const Color(0xFFEF4444).withValues(alpha: 0.4))));
        expect(shape.side.color, isNot(equals(const Color(0xFFF59E0B).withValues(alpha: 0.4))));
      }
    });

    testWidgets('Dark mode cards have clean dark sapphire border and surfaceDark', (tester) async {
      await pumpHistoryScreen(
        tester,
        themeType: ThemeType.dark,
        themeData: AppTheme.getDark(),
      );

      final cards = tester.widgetList<Card>(find.byType(Card)).toList();
      expect(cards.length, greaterThanOrEqualTo(3));

      for (final card in cards) {
        expect(card.color, equals(AppColors.surfaceDark));
        final shape = card.shape as RoundedRectangleBorder;
        expect(shape.borderRadius, equals(BorderRadius.circular(16)));
        // Border color is clean dark sapphire (0xFF1E2D4E)
        expect(shape.side.color, equals(const Color(0xFF1E2D4E)));
      }
    });

    testWidgets('High Contrast mode cards have accessible cyan border and AMOLED surface', (tester) async {
      await pumpHistoryScreen(
        tester,
        themeType: ThemeType.highContrast,
        themeData: AppTheme.getHighContrast(),
      );

      final cards = tester.widgetList<Card>(find.byType(Card)).toList();
      expect(cards.length, greaterThanOrEqualTo(3));

      for (final card in cards) {
        expect(card.color, equals(AppColors.hcSurface));
        final shape = card.shape as RoundedRectangleBorder;
        expect(shape.borderRadius, equals(BorderRadius.circular(16)));
        // Border color is hcPrimary (0xFF38BDF8) with 1.5 width
        expect(shape.side.color, equals(AppColors.hcPrimary));
        expect(shape.side.width, equals(1.5));
      }
    });

    testWidgets('Color-Blind Safe mode cards have clean neutral border and white surface', (tester) async {
      await pumpHistoryScreen(
        tester,
        themeType: ThemeType.colorBlindSafe,
        themeData: AppTheme.getColorBlindSafe(),
      );

      final cards = tester.widgetList<Card>(find.byType(Card)).toList();
      expect(cards.length, greaterThanOrEqualTo(3));

      for (final card in cards) {
        expect(card.color, equals(Colors.white));
        final shape = card.shape as RoundedRectangleBorder;
        expect(shape.borderRadius, equals(BorderRadius.circular(16)));
        // Border color is clean neutral border (0xFFD0D7DE)
        expect(shape.side.color, equals(const Color(0xFFD0D7DE)));
      }
    });

    testWidgets('Cards have no one-sided colored stripe and SoundIcon is centered at start of card', (tester) async {
      await pumpHistoryScreen(
        tester,
        themeType: ThemeType.light,
        themeData: AppTheme.getLight(),
      );

      // Verify SoundIcons exist in card
      final soundIcons = find.byType(SoundIcon);
      expect(soundIcons, findsWidgets);

      // Verify card inner row uses CrossAxisAlignment.center
      final rows = tester.widgetList<Row>(find.descendant(
        of: find.byType(Card),
        matching: find.byType(Row),
      ));

      // The main card row that contains SoundIcon should have CrossAxisAlignment.center
      final cardMainRows = rows.where((row) =>
          row.crossAxisAlignment == CrossAxisAlignment.center &&
          row.children.any((child) => child is SoundIcon));

      expect(cardMainRows, isNotEmpty);

      // Verify no colored stripe container with width 4.5 exists
      final stripeContainers = tester.widgetList<Container>(find.descendant(
        of: find.byType(Card),
        matching: find.byType(Container),
      )).where((c) => c.constraints?.maxWidth == 4.5 || (c.constraints != null && c.constraints!.minWidth == 4.5));

      expect(stripeContainers, isEmpty);

      // Verify SoundIcons have enhanced, vibrant iconColor and borderColor (not washed out)
      final soundIconWidgets = tester.widgetList<SoundIcon>(soundIcons).toList();
      for (final icon in soundIconWidgets) {
        expect(icon.iconColor, isNotNull);
        expect(icon.borderColor, isNotNull);
        expect(icon.size, equals(44));
        expect(icon.iconSize, equals(22));
      }
    });
  });
}
