import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alertsense/ui/home/widgets/segmented_profile_selector.dart';
import 'package:alertsense/providers/alert_providers.dart';

void main() {
  testWidgets('Switching to sleep profile does not show any Open Bedside Clock dialog or SnackBar', (tester) async {
    final container = ProviderContainer();
    container.read(activeProfileProvider.notifier).state = 'home';

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: Scaffold(
            body: SegmentedProfileSelector(),
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // Verify initial profile is home
    expect(container.read(activeProfileProvider), 'home');

    // Tap on the Sleep profile tab
    await tester.tap(find.text('Sleep'));
    await tester.pumpAndSettle();

    // Profile state updated to sleep
    expect(container.read(activeProfileProvider), 'sleep');

    // Ensure NO SnackBar or card with 'Open Bedside Clock' appears
    expect(find.text('Open Bedside Clock'), findsNothing);
    expect(find.text('Bedside Clock Display ready'), findsNothing);
    expect(find.byType(SnackBar), findsNothing);
  });
}
