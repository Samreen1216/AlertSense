import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/alert_providers.dart';
import '../../../providers/audio_providers.dart';

class ProfileSelector extends ConsumerWidget {
  const ProfileSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProfile = ref.watch(activeProfileProvider);

    return SizedBox(
      height: 48,
      width: double.infinity,
      child: SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'home', icon: Icon(Icons.home), label: Text('Home')),
          ButtonSegment(value: 'sleep', icon: Icon(Icons.nightlight_round), label: Text('Sleep')),
          ButtonSegment(value: 'outdoor', icon: Icon(Icons.park), label: Text('Outdoor')),
        ],
        selected: {activeProfile},
        onSelectionChanged: (Set<String> newSelection) {
          final profile = newSelection.first;
          // Update active profile
          ref.read(activeProfileProvider.notifier).state = profile;
          // Wire: update enabled sound categories to match profile
          ref.read(enabledSoundsProvider.notifier).setProfile(profile);
        },
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith<Color>(
            (states) => states.contains(WidgetState.selected)
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surface,
          ),
        ),
      ),
    );
  }
}
