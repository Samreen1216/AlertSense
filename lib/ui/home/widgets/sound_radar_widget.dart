import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:math';
import '../../../core/constants/sound_categories.dart';
import '../../../providers/audio_providers.dart';

class SoundRadarWidget extends ConsumerStatefulWidget {
  const SoundRadarWidget({super.key});

  @override
  ConsumerState<SoundRadarWidget> createState() => _SoundRadarWidgetState();
}

class _SoundRadarWidgetState extends ConsumerState<SoundRadarWidget> with TickerProviderStateMixin {
  late AnimationController _sweepController;
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _sweepController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isListening = ref.watch(isListeningProvider);
    final detectedSounds = ref.watch(detectedSoundsProvider);

    if (!isListening && _sweepController.isAnimating) {
      _sweepController.stop();
      _pulseController.stop();
    } else if (isListening && !_sweepController.isAnimating) {
      _sweepController.repeat();
      _pulseController.repeat(reverse: true);
    }

    return Container(
      height: 280,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F172A), Color(0xFF1E1B4B)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.3),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Center(
        child: isListening
            ? LayoutBuilder(
                builder: (context, constraints) {
                  final radius = min(constraints.maxWidth, constraints.maxHeight) / 2.5;
                  
                  return Stack(
                    alignment: Alignment.center,
                    children: [
                      // Radar Circles and Sweep
                      AnimatedBuilder(
                        animation: _sweepController,
                        builder: (context, child) {
                          return CustomPaint(
                            size: Size(constraints.maxWidth, constraints.maxHeight),
                            painter: _RadarPainter(
                              sweepAngle: _sweepController.value * 2 * pi,
                              radius: radius,
                            ),
                          );
                        },
                      ),
                      
                      // Center Microphone
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Theme.of(context).colorScheme.primary,
                          boxShadow: [
                            BoxShadow(
                              color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                              blurRadius: 20,
                              spreadRadius: 2,
                            )
                          ],
                        ),
                        child: const Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.mic, color: Colors.white),
                            Text('YOU', style: TextStyle(color: Colors.white, fontSize: 8, fontWeight: FontWeight.bold)),
                          ],
                        ),
                      ),
                      
                      // Detected Sounds Dots
                      ...detectedSounds.map((sound) {
                        final distance = radius * (1.0 - (sound.confidence / 100)); // closer = higher confidence
                        final dx = distance * cos(sound.angle);
                        final dy = distance * sin(sound.angle);

                        SoundCategory? category;
                        try {
                          category = SoundCategory.values.firstWhere(
                            (c) => c.name.toLowerCase() == sound.category.toLowerCase() ||
                                   c.label.toLowerCase() == sound.category.toLowerCase(),
                          );
                        } catch (_) {}

                        final dotColor = category?.color ?? Colors.redAccent;
                        final emoji = category?.emoji ?? '🔔';
                        final label = category?.label ?? sound.category;
                        
                        return AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            final scale = 1.0 + (_pulseController.value * 0.25 * (sound.confidence / 100));
                            return Positioned(
                              left: (constraints.maxWidth / 2) + dx - 30,
                              top: (constraints.maxHeight / 2) + dy - 30,
                              child: Transform.scale(
                                scale: scale,
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: dotColor,
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: dotColor.withOpacity(0.6),
                                            blurRadius: 12,
                                            spreadRadius: 3,
                                          )
                                        ],
                                      ),
                                      child: Text(emoji, style: const TextStyle(fontSize: 16)),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      label,
                                      style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                    ),
                                    Text(
                                      '${sound.confidence.toInt()}%',
                                      style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 9, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }
                        );
                      }),
                    ],
                  );
                },
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.radar, size: 64, color: Colors.white.withOpacity(0.2)),
                  const SizedBox(height: 16),
                  Text(
                    'TAP TO START',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontWeight: FontWeight.bold,
                      letterSpacing: 2,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

class _RadarPainter extends CustomPainter {
  final double sweepAngle;
  final double radius;

  _RadarPainter({required this.sweepAngle, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final paint = Paint()
      ..color = Colors.greenAccent.withOpacity(0.3)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    // Concentric circles
    canvas.drawCircle(center, radius / 3, paint);
    canvas.drawCircle(center, radius * 2 / 3, paint);
    canvas.drawCircle(center, radius, paint);

    // Crosshairs
    canvas.drawLine(
        Offset(center.dx, center.dy - radius), Offset(center.dx, center.dy + radius), paint);
    canvas.drawLine(
        Offset(center.dx - radius, center.dy), Offset(center.dx + radius, center.dy), paint);

    // Sweep line
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          Colors.greenAccent.withOpacity(0.1),
          Colors.greenAccent.withOpacity(0.6),
        ],
        stops: const [0.0, 0.9, 1.0],
        transform: GradientRotation(sweepAngle - pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, sweepPaint);

    // Leading edge line
    final linePaint = Paint()
      ..color = Colors.greenAccent
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;
      
    final dx = radius * cos(sweepAngle);
    final dy = radius * sin(sweepAngle);
    canvas.drawLine(center, Offset(center.dx + dx, center.dy + dy), linePaint);
  }

  @override
  bool shouldRepaint(covariant _RadarPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle || oldDelegate.radius != radius;
  }
}
