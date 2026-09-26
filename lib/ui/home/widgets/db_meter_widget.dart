import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../providers/audio_providers.dart';

class DbMeterWidget extends ConsumerWidget {
  const DbMeterWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ambientDb = ref.watch(ambientDbProvider);
    final themeType = ref.watch(themeTypeProvider);
    final progress = (ambientDb / 120.0).clamp(0.0, 1.0);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isHighContrast = themeType == ThemeType.highContrast;

    final noiseColor = _getNoiseColor(ambientDb, themeType);
    final noiseLabel = _getNoiseLabel(ambientDb);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Live Header Indicator
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: noiseColor,
                    shape: BoxShape.circle,
                    boxShadow: isHighContrast
                        ? null
                        : [
                            BoxShadow(
                              color: noiseColor.withValues(alpha: 0.6),
                              blurRadius: 4,
                            ),
                          ],
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${ambientDb.toStringAsFixed(0)} dB',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isHighContrast ? Colors.white : (isDark ? Colors.white : const Color(0xFF0F172A)),
                  ),
                ),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: isHighContrast
                    ? noiseColor
                    : noiseColor.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: isHighContrast ? Colors.white : noiseColor.withValues(alpha: 0.35),
                  width: 1,
                ),
              ),
              child: Text(
                noiseLabel,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: isHighContrast ? Colors.black : noiseColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Animated Fluid Decibel Bar
        TweenAnimationBuilder<double>(
          tween: Tween<double>(begin: 0.0, end: progress),
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOutCubic,
          builder: (context, animatedValue, child) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Container(
                height: 8,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: isHighContrast
                      ? Colors.black
                      : (isDark
                          ? Colors.white.withValues(alpha: 0.08)
                          : theme.colorScheme.surfaceContainerHighest),
                  border: isHighContrast
                      ? Border.all(color: Colors.white, width: 1)
                      : null,
                ),
                child: Stack(
                  children: [
                    FractionallySizedBox(
                      widthFactor: animatedValue,
                      child: Container(
                        decoration: BoxDecoration(
                          color: isHighContrast ? const Color(0xFF00FF41) : null,
                          gradient: isHighContrast
                              ? null
                              : const LinearGradient(
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
            );
          },
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

  String _getNoiseLabel(double db) {
    if (db < 45) return 'Quiet Room';
    if (db < 70) return 'Moderate Ambient';
    if (db < 85) return 'Elevated Noise';
    return 'Loud / Warning';
  }

  Color _getNoiseColor(double db, ThemeType themeType) {
    if (themeType == ThemeType.colorBlindSafe) {
      if (db < 50) return const Color(0xFF1E88E5);
      if (db < 75) return const Color(0xFFF57C00);
      return const Color(0xFFD81B60);
    }
    if (themeType == ThemeType.highContrast) {
      if (db < 80) return const Color(0xFF00FF41);
      return const Color(0xFFFFD600);
    }
    if (db < 50) return const Color(0xFF10B981);
    if (db < 75) return const Color(0xFFF59E0B);
    return const Color(0xFFEF4444);
  }
}
