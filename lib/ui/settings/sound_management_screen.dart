import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/priority_levels.dart';
import '../../core/constants/sound_categories.dart';
import '../../providers/audio_providers.dart';
import '../shared/sound_icon.dart';

class SoundManagementScreen extends ConsumerWidget {
  const SoundManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabledSounds = ref.watch(enabledSoundsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final highPriority = SoundCategory.values
        .where((c) => c.defaultPriority == PriorityLevel.high)
        .toList();
    final medPriority = SoundCategory.values
        .where((c) => c.defaultPriority == PriorityLevel.medium)
        .toList();
    final lowPriority = SoundCategory.values
        .where((c) => c.defaultPriority == PriorityLevel.low)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Sounds'),
        actions: [
          PopupMenuButton<String>(
            onSelected: (val) {
              if (val == 'all') {
                ref
                    .read(enabledSoundsProvider.notifier)
                    .enableAll(SoundCategory.values.map((c) => c.name).toSet());
              } else if (val == 'none') {
                ref.read(enabledSoundsProvider.notifier).disableAll();
              }
            },
            itemBuilder: (ctx) => [
              const PopupMenuItem(value: 'all', child: Text('Enable All Sounds')),
              const PopupMenuItem(value: 'none', child: Text('Disable All Sounds')),
            ],
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Summary Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF1E2638)
                  : theme.colorScheme.primaryContainer.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.primary.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.tune_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${enabledSounds.length} of ${SoundCategory.values.length} Sounds Active',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Toggled sounds take effect immediately across continuous monitoring and Quick Scan.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // High Priority Section
          _buildCategoryGroup(
            context,
            ref,
            title: 'HIGH PRIORITY ALARMS',
            categories: highPriority,
            enabledSounds: enabledSounds,
            priorityColor: const Color(0xFFEF4444),
          ),
          const SizedBox(height: 16),

          // Medium Priority Section
          _buildCategoryGroup(
            context,
            ref,
            title: 'MEDIUM ATTENTION SOUNDS',
            categories: medPriority,
            enabledSounds: enabledSounds,
            priorityColor: const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 16),

          // Low Priority Section
          _buildCategoryGroup(
            context,
            ref,
            title: 'LOW AMBIENT SOUNDS',
            categories: lowPriority,
            enabledSounds: enabledSounds,
            priorityColor: const Color(0xFF10B981),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildCategoryGroup(
    BuildContext context,
    WidgetRef ref, {
    required String title,
    required List<SoundCategory> categories,
    required Set<String> enabledSounds,
    required Color priorityColor,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: priorityColor,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: priorityColor,
                ),
              ),
            ],
          ),
        ),
        Card(
          elevation: 0,
          color: isDark
              ? const Color(0xFF1E2638)
              : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
            ),
          ),
          child: Column(
            children: categories.asMap().entries.map((entry) {
              final index = entry.key;
              final cat = entry.value;
              final isEnabled = enabledSounds.contains(cat.name);

              return Column(
                children: [
                  if (index > 0) const Divider(height: 1),
                  SwitchListTile(
                    secondary: SoundIcon(
                      emoji: cat.emoji,
                      color: cat.color.withValues(alpha: 0.15),
                    ),
                    title: Text(
                      cat.label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    subtitle: Text(
                      cat.description,
                      style: const TextStyle(fontSize: 12),
                    ),
                    value: isEnabled,
                    activeTrackColor: cat.color.withValues(alpha: 0.5), activeThumbColor: cat.color,
                    onChanged: (val) {
                      ref.read(enabledSoundsProvider.notifier).toggle(cat.name);
                    },
                  ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

