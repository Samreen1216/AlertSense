import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/audio_providers.dart';

class ListeningIndicator extends ConsumerStatefulWidget {
  const ListeningIndicator({super.key});

  @override
  ConsumerState<ListeningIndicator> createState() => _ListeningIndicatorState();
}

class _ListeningIndicatorState extends ConsumerState<ListeningIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  String _getDbLabel(double db) {
    if (db < 45) return 'Quiet (Safe)';
    if (db < 65) return 'Normal Ambient';
    if (db < 80) return 'Elevated Noise';
    return 'Loud / Danger';
  }

  Color _getDbColor(double db) {
    if (db < 45) return const Color(0xFF10B981); // Emerald
    if (db < 65) return const Color(0xFF06B6D4); // Cyan
    if (db < 80) return const Color(0xFFF59E0B); // Amber
    return const Color(0xFFEF4444); // Red
  }

  @override
  Widget build(BuildContext context) {
    final isListening = ref.watch(isListeningProvider);
    final ambientDb = ref.watch(ambientDbProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final dbColor = _getDbColor(ambientDb);
    final dbLabel = _getDbLabel(ambientDb);
    final progress = (ambientDb / 120.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E2638)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: isListening
              ? dbColor.withValues(alpha: 0.3)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isListening
                ? dbColor.withValues(alpha: 0.08)
                : Colors.black.withValues(alpha: 0.03),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Status pill & dB Value
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Status Pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isListening
                      ? const Color(0xFF10B981).withValues(alpha: 0.15)
                      : Colors.grey.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isListening
                        ? const Color(0xFF10B981).withValues(alpha: 0.4)
                        : Colors.grey.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    AnimatedBuilder(
                      animation: _pulseController,
                      builder: (context, child) {
                        return Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isListening
                                ? const Color(0xFF10B981)
                                : Colors.grey,
                            boxShadow: isListening
                                ? [
                                    BoxShadow(
                                      color: const Color(0xFF10B981)
                                          .withValues(alpha: 0.6),
                                      blurRadius:
                                          4 + (_pulseController.value * 6),
                                      spreadRadius: 1,
                                    )
                                  ]
                                : null,
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isListening ? 'LIVE SENSING' : 'STANDBY',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.8,
                        color: isListening
                            ? const Color(0xFF10B981)
                            : (isDark ? Colors.white60 : Colors.black54),
                      ),
                    ),
                  ],
                ),
              ),

              // dB Value & Level Pill
              Row(
                children: [
                  Text(
                    '${ambientDb.toStringAsFixed(1)}',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w900,
                      color: dbColor,
                    ),
                  ),
                  const SizedBox(width: 3),
                  const Text(
                    'dB',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: dbColor.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      dbLabel,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: dbColor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),

          const SizedBox(height: 16),

          // Animated Visualizer Equalizer Bar
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              return SizedBox(
                height: 36,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: List.generate(24, (index) {
                    final factor = isListening
                        ? (sin((index * 0.4) + (_pulseController.value * 3))
                                    .abs() *
                                0.7 +
                            (progress * 0.5))
                            .clamp(0.12, 1.0)
                        : 0.1;
                    return Container(
                      width: 5,
                      height: 36 * factor,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            dbColor.withValues(alpha: 0.4),
                            dbColor,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
