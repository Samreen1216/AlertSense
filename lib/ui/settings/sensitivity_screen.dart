import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/sound_categories.dart';
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
    for (final category in SoundCategory.values) {
      _localThresholds[category.name] = category.defaultThreshold;
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
                }
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Reset to default AI thresholds')),
              );
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
              color: theme.colorScheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: theme.colorScheme.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Higher sensitivity triggers alerts more readily. Lower sensitivity requires higher AI confidence to reduce false positives.',
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

            return Card(
              margin: const EdgeInsets.only(bottom: 12.0),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(
                  color: theme.colorScheme.outlineVariant.withOpacity(0.5),
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
                          emoji: category.emoji,
                          color: category.color.withOpacity(0.15),
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
                        Text('Required Confidence: $percent%', style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text(
                          percent < 60 ? 'Very Sensitive' : (percent > 80 ? 'Strict' : 'Balanced'),
                          style: TextStyle(
                            fontSize: 12,
                            color: percent < 60
                                ? Colors.orange
                                : (percent > 80 ? Colors.blue : Colors.green),
                            fontWeight: FontWeight.w600,
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
                      },
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
