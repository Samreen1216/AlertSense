import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alertsense/ui/sleep/sleep_mode_screen.dart';
import 'package:alertsense/providers/alert_providers.dart';

void main() {
  testWidgets('SleepModeScreen renders cleanly without red screen or assertion error', (tester) async {
    final container = ProviderContainer();
    container.read(activeProfileProvider.notifier).state = 'home';

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: SleepModeScreen(),
        ),
      ),
    );

    // Initial pump & postFrameCallback execution
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(tester.takeException(), isNull);

    // Verify key UI elements
    expect(find.text('Sleep Guardian'), findsOneWidget);
    expect(find.text('BEDSIDE'), findsOneWidget);
    expect(find.text('Monitored Life-Safety Alarms'), findsOneWidget);
    expect(find.text('Fire Alarm'), findsOneWidget);
    expect(find.text('Siren'), findsOneWidget);
    expect(find.text('Baby Crying'), findsOneWidget);
    expect(find.text('Exit Sleep Mode'), findsOneWidget);

    // Verify back navigation button exists in header
    final backBtn = find.byTooltip('Back to Home');
    expect(backBtn, findsOneWidget);

    // Verify profile switched to sleep
    expect(container.read(activeProfileProvider), 'sleep');
  });

  testWidgets('SleepModeScreen back button restores previous profile and pops', (tester) async {
    final container = ProviderContainer();
    container.read(activeProfileProvider.notifier).state = 'outdoor';

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SleepModeScreen()),
                  );
                },
                child: const Text('Open Sleep'),
              ),
            ),
          ),
        ),
      ),
    );

    // Open sleep screen
    await tester.tap(find.text('Open Sleep'));
    await tester.pumpAndSettle();

    expect(find.text('Sleep Guardian'), findsOneWidget);
    expect(container.read(activeProfileProvider), 'sleep');

    // Tap back button
    await tester.tap(find.byTooltip('Back to Home'));
    await tester.pumpAndSettle();

    // Verify returned to home screen and profile restored
    expect(find.text('Open Sleep'), findsOneWidget);
    expect(container.read(activeProfileProvider), 'outdoor');
  });

  testWidgets('SleepModeScreen Exit Sleep Mode button restores previous profile', (tester) async {
    final container = ProviderContainer();
    container.read(activeProfileProvider.notifier).state = 'home';

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SleepModeScreen()),
                  );
                },
                child: const Text('Open Sleep'),
              ),
            ),
          ),
        ),
      ),
    );

    // Open sleep screen
    await tester.tap(find.text('Open Sleep'));
    await tester.pumpAndSettle();

    expect(find.text('Exit Sleep Mode'), findsOneWidget);

    // Scroll to exit button if needed and tap
    await tester.ensureVisible(find.text('Exit Sleep Mode'));
    await tester.tap(find.text('Exit Sleep Mode'));
    await tester.pumpAndSettle();

    // Verify returned and profile restored to home
    expect(find.text('Open Sleep'), findsOneWidget);
    expect(container.read(activeProfileProvider), 'home');
  });
}
