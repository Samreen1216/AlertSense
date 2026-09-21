import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_svg_icons.dart';
import '../../../core/constants/priority_levels.dart';
import '../../../providers/audio_providers.dart';

class HeroSoundRadar extends ConsumerStatefulWidget {
  const HeroSoundRadar({super.key});

  @override
  ConsumerState<HeroSoundRadar> createState() => _HeroSoundRadarState();
}

class _HeroSoundRadarState extends ConsumerState<HeroSoundRadar>
    with SingleTickerProviderStateMixin {
  late AnimationController _sweepController;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();
  }

  @override
  void dispose() {
    _sweepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isListening = ref.watch(isListeningProvider);
    final detectedSounds = ref.watch(detectedSoundsProvider);

    if (!isListening && _sweepController.isAnimating) {
      _sweepController.stop();
    } else if (isListening && !_sweepController.isAnimating) {
      _sweepController.repeat();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final size = min(constraints.maxWidth, constraints.maxHeight);
        final radarRadius = size / 2;

        return Center(
          child: SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // 1. Radar Grid & Sweep Canvas
                AnimatedBuilder(
                  animation: _sweepController,
                  builder: (context, child) {
                    return CustomPaint(
                      size: Size(size, size),
                      painter: _RadarBackgroundPainter(
                        sweepAngle: isListening ? _sweepController.value * 2 * pi : 0,
                        isListening: isListening,
                      ),
                    );
                  },
                ),

                // 2. Detected Sound Nodes
                if (isListening && detectedSounds.isNotEmpty)
                  ...detectedSounds.map((sound) {
                    final dist = (radarRadius * sound.distance).clamp(radarRadius * 0.40, radarRadius * 0.82);
                    final dx = dist * cos(sound.angle);
                    final dy = dist * sin(sound.angle);

                    return Transform.translate(
                      offset: Offset(dx, dy),
                      child: _RadarSoundNode(sound: sound),
                    );
                  }),

                // 3. Center User Node ("YOU")
                GestureDetector(
                  onTap: () {
                    ref.read(isListeningProvider.notifier).toggle();
                  },
                  child: Container(
                    width: 52,
                    height: 52,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF0072FF), Color(0xFF00C6FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF00C6FF).withValues(alpha: 0.5),
                          blurRadius: isListening ? 14 : 6,
                          spreadRadius: isListening ? 2 : 0,
                        ),
                      ],
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.8),
                        width: 1.5,
                      ),
                    ),
                    child: const Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.person_rounded,
                          color: Colors.white,
                          size: 20,
                        ),
                        Text(
                          'YOU',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // 4. Status HUD Chip (When no sounds or paused)
                if (!isListening || detectedSounds.isEmpty)
                  Positioned(
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFF070F26).withValues(alpha: 0.85),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        !isListening ? 'Detection paused' : 'No important sounds detected',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _RadarSoundNode extends StatelessWidget {
  final DetectedSound sound;

  const _RadarSoundNode({required this.sound});

  Color _getNodeColor(PriorityLevel priority) {
    switch (priority) {
      case PriorityLevel.high:
        return const Color(0xFFEF4444); // Red
      case PriorityLevel.medium:
        return const Color(0xFFF59E0B); // Amber/Yellow
      case PriorityLevel.low:
        return const Color(0xFF10B981); // Emerald/Green
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _getNodeColor(sound.priority);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.25),
            border: Border.all(color: color, width: 2),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.6),
                blurRadius: 8,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Center(
            child: AppSvgIcon(
              iconKey: sound.category.name,
              size: 14,
              color: Colors.white,
            ),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.75),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            children: [
              Text(
                sound.category.label,
                style: TextStyle(
                  color: color,
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                '${sound.confidence.toInt()}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 8,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _RadarBackgroundPainter extends CustomPainter {
  final double sweepAngle;
  final bool isListening;

  _RadarBackgroundPainter({
    required this.sweepAngle,
    required this.isListening,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer circular boundary
    final bgPaint = Paint()
      ..color = const Color(0xFF0A132C).withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Concentric Range Rings
    final ringPaint = Paint()
      ..color = const Color(0xFF00C6FF).withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, radius * 0.35, ringPaint);
    canvas.drawCircle(center, radius * 0.65, ringPaint);
    canvas.drawCircle(center, radius * 0.95, ringPaint);

    // Crosshair Lines
    final crosshairPaint = Paint()
      ..color = const Color(0xFF00C6FF).withValues(alpha: 0.15)
      ..strokeWidth = 0.8;

    canvas.drawLine(
      Offset(center.dx - radius * 0.95, center.dy),
      Offset(center.dx + radius * 0.95, center.dy),
      crosshairPaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - radius * 0.95),
      Offset(center.dx, center.dy + radius * 0.95),
      crosshairPaint,
    );

    // Rotating Radar Sweep Sector
    if (isListening && sweepAngle > 0) {
      final sweepPaint = Paint()
        ..shader = SweepGradient(
          startAngle: 0.0,
          endAngle: pi / 2,
          colors: [
            const Color(0xFF00E5FF).withValues(alpha: 0.0),
            const Color(0xFF00E5FF).withValues(alpha: 0.32),
          ],
          transform: GradientRotation(sweepAngle - pi / 2),
        ).createShader(Rect.fromCircle(center: center, radius: radius * 0.95))
        ..style = PaintingStyle.fill;

      canvas.drawCircle(center, radius * 0.95, sweepPaint);

      // Leading beam line
      final beamPaint = Paint()
        ..color = const Color(0xFF00E5FF).withValues(alpha: 0.8)
        ..strokeWidth = 1.6;

      final endPoint = Offset(
        center.dx + radius * 0.95 * cos(sweepAngle),
        center.dy + radius * 0.95 * sin(sweepAngle),
      );
      canvas.drawLine(center, endPoint, beamPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RadarBackgroundPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle ||
        oldDelegate.isListening != isListening;
  }
}
