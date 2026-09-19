import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/audio_providers.dart';

class HeroListeningCard extends ConsumerStatefulWidget {
  const HeroListeningCard({super.key});

  @override
  ConsumerState<HeroListeningCard> createState() => _HeroListeningCardState();
}

class _HeroListeningCardState extends ConsumerState<HeroListeningCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isListening = ref.watch(isListeningProvider);
    final ambientDb = ref.watch(ambientDbProvider);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          ref.read(isListeningProvider.notifier).toggle();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1A3A).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isListening
                  ? const Color(0xFF00E5FF).withValues(alpha: 0.3)
                  : Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Top Status Row
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isListening
                          ? const Color(0xFF10B981)
                          : const Color(0xFF6B7280),
                      boxShadow: isListening
                          ? [
                              BoxShadow(
                                color: const Color(0xFF10B981).withValues(alpha: 0.8),
                                blurRadius: 6,
                                spreadRadius: 1,
                              )
                            ]
                          : null,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isListening ? 'Listening...' : 'Paused',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 2),
              Padding(
                padding: const EdgeInsets.only(left: 18),
                child: Text(
                  isListening ? 'Real-time sound detection' : 'Tap to start monitoring',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 10,
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Bottom Row: Equalizer Waveform + Ambient dB
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  // Animated Waveform Equalizer
                  Expanded(
                    child: SizedBox(
                      height: 28,
                      child: AnimatedBuilder(
                        animation: _waveController,
                        builder: (context, child) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.start,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: List.generate(12, (i) {
                              double height = 4.0;
                              if (isListening) {
                                final normDb = (ambientDb / 100.0).clamp(0.1, 1.0);
                                final wave = sin((_waveController.value * 2 * pi) + (i * 0.5));
                                height = (8.0 + (wave.abs() * 18.0 * normDb)).clamp(4.0, 26.0);
                              }
                              return Container(
                                width: 3,
                                height: height,
                                margin: const EdgeInsets.only(right: 3),
                                decoration: BoxDecoration(
                                  color: isListening
                                      ? const Color(0xFF00E5FF)
                                      : Colors.white.withValues(alpha: 0.25),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              );
                            }),
                          );
                        },
                      ),
                    ),
                  ),

                  // dB Readout
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        isListening
                            ? '${ambientDb.toStringAsFixed(0)} dB'
                            : '-- dB',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                      Text(
                        'Ambient Noise',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.6),
                          fontSize: 9,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
