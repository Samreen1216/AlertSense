import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/sound_categories.dart';
import '../../providers/service_providers.dart';
import '../../providers/settings_providers.dart';
import '../shared/priority_badge.dart';
import '../shared/sound_icon.dart';

class SensitivityScreen extends ConsumerStatefulWidget {
  const SensitivityScreen({super.key});

  @override
  ConsumerState<SensitivityScreen> createState() => _SensitivityScreenState();
}

class _SensitivityScreenState extends ConsumerState<SensitivityScreen> {
  final Map<String, double> _localThresholds = {};

  @override
  void initState() {
    super.initState();
    final profile = ref.read(currentProfileProvider);
    for (final category in SoundCategory.values) {
      _localThresholds[category.name] =
          profile.sensitivityOverrides[category.name] ?? category.defaultThreshold;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detection Sensitivity'),
        actions: [
          TextButton(
            onPressed: () {
              setState(() {
                for (final category in SoundCategory.values) {
                  _localThresholds[category.name] = category.defaultThreshold;
                  ref.read(priorityEngineProvider).setThreshold(category.name, category.defaultThreshold);
                }
              });
              final profile = ref.read(currentProfileProvider);
              final updatedProfile = profile.copyWith(sensitivityOverrides: {});
              ref.read(soundProfilesProvider.notifier).saveProfile(updatedProfile);
              final messenger = ScaffoldMessenger.of(context);
              messenger.clearSnackBars();
              final controller = messenger.showSnackBar(
                SnackBar(
                  content: const Text('Reset to default AI thresholds'),
                  duration: const Duration(seconds: 3),
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
              Timer(const Duration(milliseconds: 3000), () {
                try {
                  controller.close();
                } catch (_) {}
              });
            },
            child: const Text('Reset'),
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.tune_rounded, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Lower confidence thresholds catch faint or distant sounds with more alerts. Higher thresholds filter out background ambient noise and require high AI certainty.',
                    style: theme.textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          ...SoundCategory.values.map((category) {
            final threshold = _localThresholds[category.name] ?? category.defaultThreshold;
            final percent = (threshold * 100).toInt();

            final sensitivityLabel = percent < 55
                ? 'High Sensitivity (Faint Sounds)'
                : (percent > 75 ? 'Strict Certainty (Fewer Alerts)' : 'Balanced Detection');

            final sensitivityColor = percent < 55
                ? const Color(0xFFF59E0B)
                : (percent > 75 ? const Color(0xFF0072FF) : const Color(0xFF10B981));

            return Card(
              margin: const EdgeInsets.only(bottom: 12.0),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        SoundIcon(
                          iconName: category.name,
                          color: category.color.withValues(alpha: 0.15),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                category.label,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                category.description,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        PriorityBadge(priority: category.defaultPriority.label),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Required Confidence: $percent%',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: sensitivityColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            sensitivityLabel,
                            style: TextStyle(
                              fontSize: 11,
                              color: sensitivityColor,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                    Slider(
                      value: threshold,
                      min: 0.30,
                      max: 0.95,
                      divisions: 13,
                      label: '$percent%',
                      onChanged: (val) {
                        setState(() {
                          _localThresholds[category.name] = val;
                        });
                        final profile = ref.read(currentProfileProvider);
                        final updatedOverrides = Map<String, double>.from(profile.sensitivityOverrides);
                        updatedOverrides[category.name] = val;
                        final updatedProfile = profile.copyWith(sensitivityOverrides: updatedOverrides);
                        ref.read(soundProfilesProvider.notifier).saveProfile(updatedProfile);
                        ref.read(priorityEngineProvider).setThreshold(category.name, val);
                      },
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            '◀ More Alerts\n(Sensitive)',
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            'Fewer False Alarms ▶\n(Strict Certainty)',
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 10,
                              color: theme.colorScheme.onSurfaceVariant,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
