import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alertsense/core/constants/priority_levels.dart';
import 'package:alertsense/core/constants/sound_categories.dart';
import 'package:alertsense/providers/audio_providers.dart';
import 'package:alertsense/ui/home/widgets/hero_sound_radar.dart';

class _TestListeningNotifier extends StateNotifier<bool> {
  _TestListeningNotifier([super.initialState = false]);
  void toggle() => state = !state;
  void setListening(bool value) => state = value;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('HeroSoundRadar utilizes RepaintBoundary layers to isolate repaints (standby mode)', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: MaterialApp(
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
    await tester.pump();

    // Verify multiple RepaintBoundary widgets exist (root boundary, static grid, dynamic sweep, YOU node, HUD)
    final repaintBoundaries = find.byType(RepaintBoundary);
    expect(repaintBoundaries, findsAtLeastNWidgets(4));

    // Verify "YOU" node is present
    expect(find.text('YOU'), findsOneWidget);

    // When listening is inactive, status HUD shows "Detection paused"
    expect(find.text('Detection paused'), findsOneWidget);
  });

  testWidgets('HeroSoundRadar shows "No important sounds detected" when listening without sounds', (tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isListeningProvider.overrideWith((ref) => _TestListeningNotifier(true)),
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
    await tester.pump();

    expect(find.text('YOU'), findsOneWidget);
    expect(find.text('No important sounds detected'), findsOneWidget);
  });

  testWidgets('HeroSoundRadar renders detected sound nodes inside RepaintBoundary when listening', (tester) async {
    final sound = DetectedSound(
      category: SoundCategory.fireAlarm,
      confidence: 94.0,
      angle: 1.2,
      distance: 0.6,
      priority: PriorityLevel.high,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isListeningProvider.overrideWith((ref) => _TestListeningNotifier(true)),
          detectedSoundsProvider.overrideWith((ref) => [sound]),
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
    await tester.pump();

    // Verify sound node label and confidence percentage are rendered
    expect(find.text('Fire Alarm'), findsOneWidget);
    expect(find.text('94%'), findsOneWidget);

    // Verify that sound node is wrapped in its own RepaintBoundary
    final soundNode = find.text('Fire Alarm');
    expect(
      find.ancestor(of: soundNode, matching: find.byType(RepaintBoundary)),
      findsWidgets,
    );
  });

  testWidgets('Tapping center YOU button toggles listening state', (tester) async {
    final testNotifier = _TestListeningNotifier(false);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          isListeningProvider.overrideWith((ref) => testNotifier),
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
    await tester.pump();

    expect(testNotifier.state, isFalse);

    // Tap "YOU" center button
    await tester.tap(find.text('YOU'));
    await tester.pump();

    expect(testNotifier.state, isTrue);
  });
}
