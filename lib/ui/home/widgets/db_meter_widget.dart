import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/audio_providers.dart';

class DbMeterWidget extends ConsumerWidget {
  const DbMeterWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ambientDb = ref.watch(ambientDbProvider);
    final progress = (ambientDb / 120.0).clamp(0.0, 1.0);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: Container(
            height: 8,
            width: double.infinity,
            color: isDark
                ? Colors.white.withValues(alpha: 0.08)
                : theme.colorScheme.surfaceContainerHighest,
            child: Stack(
              children: [
                FractionallySizedBox(
                  widthFactor: progress,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFF10B981), // Green
                          Color(0xFF06B6D4), // Cyan
                          Color(0xFFF59E0B), // Orange
                          Color(0xFFEF4444), // Red
                        ],
                      ),
                      borderRadius: BorderRadius.circular(6),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '0 dB (Silence)',
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '60 dB (Normal)',
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              '120 dB (Critical)',
              style: TextStyle(
                fontSize: 10,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
