import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alertsense/providers/audio_providers.dart';
import 'package:alertsense/providers/device_providers.dart';
import 'package:alertsense/ui/home/widgets/background_monitoring_sheet.dart';
import 'package:alertsense/ui/home/widgets/hero_battery_card.dart';
import 'package:alertsense/ui/home/widgets/hero_listening_card.dart';

class _FakeListeningNotifier extends ListeningNotifier {
  _FakeListeningNotifier(super.ref, [bool initial = false]) {
    state = initial;
  }
  @override
  Future<void> toggle() async => state = !state;
  @override
  Future<void> start() async => state = true;
  @override
  Future<void> stop() async => state = false;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Background Monitoring UX & Sheet Tests', () {
    testWidgets('BackgroundMonitoringSheet renders comparison between Set and Deny', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            batteryStatusProvider.overrideWith((ref) => Future.value(
                  const BatteryStatus(
                    title: 'Background Limited',
                    subtitle: 'Tap to enable 24/7 alerts',
                    isOptimized: false,
                    requiresAction: true,
                  ),
                )),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: _OpenSheetButton(),
              ),
            ),
          ),
        ),
      );

      // Open the sheet
      await tester.tap(find.text('OPEN_SHEET'));
      await tester.pumpAndSettle();

      // Check header
      expect(find.text('Background Monitoring Setup'), findsOneWidget);
      expect(find.text('Continuous safety awareness when phone is locked'), findsOneWidget);

      // Check Set / Allow section
      expect(find.text('If you Set / Allow'), findsOneWidget);
      expect(find.text('RECOMMENDED'), findsOneWidget);
      expect(find.textContaining('24/7 Locked-Screen Detection'), findsOneWidget);
      expect(find.textContaining('Immediate Emergency Alerts'), findsOneWidget);

      // Check Deny section
      expect(find.text('If you Deny'), findsOneWidget);
      expect(find.text('LIMITED FUNCTIONALITY'), findsOneWidget);
      expect(find.textContaining('Accurate while app is open'), findsOneWidget);
      expect(find.textContaining('Locked-screen may pause'), findsOneWidget);

      // Check action buttons
      expect(find.text('Allow Background Running (Recommended)'), findsOneWidget);
      expect(find.text('Continue in Foreground Only (Deny)'), findsOneWidget);
    });

    testWidgets('BackgroundMonitoringSheet renders verified state when already whitelisted', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            batteryStatusProvider.overrideWith((ref) => Future.value(
                  const BatteryStatus(
                    title: '24/7 Protection',
                    subtitle: 'Active when locked',
                    isOptimized: true,
                    requiresAction: false,
                  ),
                )),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: _OpenSheetButton(),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('OPEN_SHEET'));
      await tester.pumpAndSettle();

      expect(find.text('24/7 Protection Active'), findsOneWidget);
      expect(find.text('Whitelisted from Android battery restrictions'), findsOneWidget);
      expect(find.text('Fully Configured for Maximum Safety'), findsOneWidget);
      expect(find.text('Done'), findsOneWidget);
    });

    testWidgets('HeroBatteryCard displays accurate status and opens sheet on tap', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            batteryStatusProvider.overrideWith((ref) => Future.value(
                  const BatteryStatus(
                    title: 'Background Limited',
                    subtitle: 'Tap to enable 24/7 alerts',
                    isOptimized: false,
                    requiresAction: true,
                  ),
                )),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 300,
                  child: HeroBatteryCard(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Background Limited'), findsOneWidget);
      expect(find.text('Tap to enable 24/7 alerts'), findsOneWidget);
      expect(find.byIcon(Icons.battery_alert_rounded), findsOneWidget);

      // Tapping the card opens BackgroundMonitoringSheet
      await tester.tap(find.byType(HeroBatteryCard));
      await tester.pumpAndSettle();

      expect(find.text('Background Monitoring Setup'), findsOneWidget);
    });

    testWidgets('HeroListeningCard stops listening immediately when currently active', (tester) async {
      late _FakeListeningNotifier listeningNotifier;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            isListeningProvider.overrideWith((ref) {
              listeningNotifier = _FakeListeningNotifier(ref, true);
              return listeningNotifier;
            }),
            ambientDbProvider.overrideWith((ref) => 45.0),
          ],
          child: const MaterialApp(
            home: Scaffold(
              body: Center(
                child: SizedBox(
                  width: 300,
                  child: HeroListeningCard(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Listening...'), findsOneWidget);

      // Tap to toggle off
      await tester.tap(find.byType(HeroListeningCard));
      await tester.pumpAndSettle();

      expect(listeningNotifier.state, isFalse);
    });
  });
}

class _OpenSheetButton extends StatelessWidget {
  const _OpenSheetButton();

  @override
  Widget build(BuildContext context) {
    return Consumer(
      builder: (context, ref, _) {
        return ElevatedButton(
          onPressed: () => showBackgroundMonitoringSheet(context, ref),
          child: const Text('OPEN_SHEET'),
        );
      },
    );
  }
}
