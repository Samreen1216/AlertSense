import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/priority_levels.dart';
import '../../../core/constants/sound_categories.dart';
import '../../../providers/audio_providers.dart';

class SoundToggleGrid extends ConsumerWidget {
  const SoundToggleGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabledSounds = ref.watch(enabledSoundsProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Wrap(
      spacing: 8.0,
      runSpacing: 10.0,
      children: SoundCategory.values.map((category) {
        final isEnabled = enabledSounds.contains(category.name);
        final color = category.color;
        final isHigh = category.defaultPriority == PriorityLevel.high;

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              ref.read(enabledSoundsProvider.notifier).toggle(category.name);
            },
            borderRadius: BorderRadius.circular(16),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
              decoration: BoxDecoration(
                color: isEnabled
                    ? color.withValues(alpha: isDark ? 0.22 : 0.12)
                    : (isDark
                        ? const Color(0xFF1E2638).withValues(alpha: 0.5)
                        : Colors.grey.withValues(alpha: 0.08)),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isEnabled
                      ? color.withValues(alpha: 0.7)
                      : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                  width: isEnabled ? 1.5 : 1.0,
                ),
                boxShadow: isEnabled
                    ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        )
                      ]
                    : null,
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    category.emoji,
                    style: TextStyle(
                      fontSize: 16,
                      color: isEnabled ? null : Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    category.label,
                    style: TextStyle(
                      fontSize: 12.5,
                      fontWeight:
                          isEnabled ? FontWeight.w700 : FontWeight.w500,
                      color: isEnabled
                          ? (isDark ? Colors.white : Colors.black87)
                          : theme.colorScheme.onSurfaceVariant
                              .withValues(alpha: 0.6),
                    ),
                  ),
                  const SizedBox(width: 6),
                  // Priority indicator dot
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isEnabled
                          ? (isHigh ? Colors.redAccent : color)
                          : Colors.grey.withValues(alpha: 0.4),
                    ),
                  ),
                  if (isEnabled) ...[
                    const SizedBox(width: 6),
                    Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: color,
                    ),
                  ],
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
