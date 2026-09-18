import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/sound_categories.dart';
import '../../../providers/audio_providers.dart';

class SoundToggleGrid extends ConsumerWidget {
  const SoundToggleGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabledSounds = ref.watch(enabledSoundsProvider);
    final theme = Theme.of(context);

    return Wrap(
      spacing: 8.0,
      runSpacing: 10.0,
      children: SoundCategory.values.map((category) {
        final isEnabled = enabledSounds.contains(category.name);
        final color = category.color;

        return FilterChip(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          avatar: Text(category.emoji, style: const TextStyle(fontSize: 16)),
          label: Text(category.label),
          selected: isEnabled,
          onSelected: (_) {
            ref.read(enabledSoundsProvider.notifier).toggle(category.name);
          },
          selectedColor: color.withOpacity(0.18),
          checkmarkColor: color,
          labelStyle: TextStyle(
            color: isEnabled ? color : theme.colorScheme.onSurface,
            fontWeight: isEnabled ? FontWeight.bold : FontWeight.w500,
            fontSize: 13,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: BorderSide(
              color: isEnabled ? color : theme.colorScheme.outlineVariant.withOpacity(0.5),
              width: isEnabled ? 1.5 : 1,
            ),
          ),
        );
      }).toList(),
    );
  }
}
