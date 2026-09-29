import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_svg_icons.dart';
import '../../../core/constants/priority_levels.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../providers/audio_providers.dart';


class HeroSoundRadar extends ConsumerStatefulWidget {
  const HeroSoundRadar({super.key});

  @override
  ConsumerState<HeroSoundRadar> createState() => _HeroSoundRadarState();
}

class _HeroSoundRadarState extends ConsumerState<HeroSoundRadar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _sweepController;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    if (ref.read(isListeningProvider)) {
      _sweepController.repeat();
    }
  }

  @override
  void dispose() {
    _sweepController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    ref.listen<bool>(isListeningProvider, (previous, isListening) {
      if (isListening) {
        if (!_sweepController.isAnimating) _sweepController.repeat();
      } else {
        if (_sweepController.isAnimating) {
          _sweepController.stop();
          _sweepController.reset();
        }
      }
    });

    final isListening = ref.watch(isListeningProvider);
    final detectedSounds = ref.watch(detectedSoundsProvider);
    final ambientDbVal = ref.watch(ambientDbProvider);
    final ambientDb = ambientDbVal == ambientDbVal.roundToDouble()
        ? ambientDbVal.round().toString()
        : ambientDbVal.toStringAsFixed(1);

    void toggleListening() {
      HapticFeedback.lightImpact();
      final notifier = ref.read(isListeningProvider.notifier);
      if (notifier is ListeningNotifier) {
        notifier.toggleListening();
      } else {
        try {
          (notifier as dynamic).toggleListening();
        } catch (_) {
          (notifier as dynamic).toggle();
        }
      }
    }

    return Semantics(
      label: 'Acoustic Sound Radar',
      value: isListening
          ? 'Listening actively. Ambient level $ambientDb decibels.'
          : 'Detection paused',
      hint: 'Double-tap to toggle microphone listening',
      button: true,
      onTap: toggleListening,
      child: RepaintBoundary(
        child: LayoutBuilder(
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
                    // 1. Static Radar Geometry (Concentric rings, crosshairs, radial diagonal lines)
                    // Isolated in its own RepaintBoundary with shouldRepaint: false so it paints once.
                    RepaintBoundary(
                      child: CustomPaint(
                        size: Size(size, size),
                        painter: const _RadarStaticGridPainter(),
                      ),
                    ),

                    // 2. Dynamic 60 FPS Sweep Animation
                    // Isolated in its own RepaintBoundary so that dynamic sweep repaints
                    // do NOT trigger repaints across static geometry, nodes, or parent cards.
                    RepaintBoundary(
                      child: AnimatedBuilder(
                        animation: _sweepController,
                        builder: (context, child) {
                          return CustomPaint(
                            size: Size(size, size),
                            painter: _RadarDynamicSweepPainter(
                              sweepAngle: isListening ? _sweepController.value * 2 * pi : 0,
                              isListening: isListening,
                            ),
                          );
                        },
                      ),
                    ),

                    // 3. Detected Sound Nodes (each isolated with RepaintBoundary)
                    if (isListening && detectedSounds.isNotEmpty)
                      ...detectedSounds.map((sound) {
                        final dist = (radarRadius * sound.distance).clamp(radarRadius * 0.40, radarRadius * 0.82);
                        final dx = dist * cos(sound.angle);
                        final dy = dist * sin(sound.angle);

                        return Transform.translate(
                          offset: Offset(dx, dy),
                          child: RepaintBoundary(
                            child: _RadarSoundNode(sound: sound),
                          ),
                        );
                      }),

                    // 4. Center User Node ("YOU")
                    RepaintBoundary(
                      child: GestureDetector(
                        onTap: toggleListening,
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
                    ),

                    // 5. Status HUD Chip (When no sounds or paused)
                    if (!isListening || detectedSounds.isEmpty)
                      Positioned(
                        bottom: 8,
                        child: RepaintBoundary(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.darkBackground.withValues(alpha: 0.85),
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
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RadarSoundNode extends ConsumerWidget {
  final DetectedSound sound;

  const _RadarSoundNode({required this.sound});

  /// Returns the node color for [priority] based on the active [themeType].
  ///
  /// - **colorBlindSafe** → IBM palette (Pink / Orange / Blue) that remains
  ///   distinguishable for protanopia, deuteranopia, and tritanopia.
  /// - **All other themes** → high-saturation Red / Amber / Green to pop
  ///   against the dark radar background.
  Color _priorityColor(ThemeType themeType, PriorityLevel priority) {
    if (themeType == ThemeType.colorBlindSafe) {
      switch (priority) {
        case PriorityLevel.high:
          return AppColors.cbSafeHigh; // Pink #D81B60
        case PriorityLevel.medium:
          return AppColors.cbSafeMedium; // Orange #F57C00
        case PriorityLevel.low:
          return AppColors.cbSafeLow; // Blue #1E88E5
      }
    }
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
  Widget build(BuildContext context, WidgetRef ref) {
    final themeType = ref.watch(themeTypeProvider);
    final color = _priorityColor(themeType, sound.priority);

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
                '${sound.confidence <= 1.0 ? (sound.confidence * 100).round() : sound.confidence.round()}%',
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



/// Static radar background geometry painter.
///
/// Draws concentric distance rings, cardinal crosshairs, and 45°/135° diagonal radial grid lines.
/// Cached in a [RepaintBoundary] layer; [shouldRepaint] returns false so static geometry
/// is painted only once and never re-rendered at 60 FPS.
class _RadarStaticGridPainter extends CustomPainter {
  const _RadarStaticGridPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer circular boundary
    final bgPaint = Paint()
      ..color = const Color(0xFF0A132C).withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius, bgPaint);

    // Concentric Range Rings (distance scales)
    final ringPaint = Paint()
      ..color = const Color(0xFF00C6FF).withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, radius * 0.35, ringPaint);
    canvas.drawCircle(center, radius * 0.65, ringPaint);
    canvas.drawCircle(center, radius * 0.95, ringPaint);

    // Cardinal Crosshair Lines (horizontal & vertical)
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

    // Diagonal Radial Grid Lines (45° and 135° bearing lines)
    final radialGridPaint = Paint()
      ..color = const Color(0xFF00C6FF).withValues(alpha: 0.08)
      ..strokeWidth = 0.6;

    final diagOffset = radius * 0.95 * 0.70710678; // cos(45°) ~ 0.7071
    canvas.drawLine(
      Offset(center.dx - diagOffset, center.dy - diagOffset),
      Offset(center.dx + diagOffset, center.dy + diagOffset),
      radialGridPaint,
    );
    canvas.drawLine(
      Offset(center.dx - diagOffset, center.dy + diagOffset),
      Offset(center.dx + diagOffset, center.dy - diagOffset),
      radialGridPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _RadarStaticGridPainter oldDelegate) => false;
}

/// Dynamic 60 FPS radar sweep painter.
///
/// Handles only the rotating sweep sector gradient and leading beam line.
/// Isolated inside a [RepaintBoundary] so only this minimal canvas updates every frame.
class _RadarDynamicSweepPainter extends CustomPainter {
  final double sweepAngle;
  final bool isListening;

  const _RadarDynamicSweepPainter({
    required this.sweepAngle,
    required this.isListening,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (!isListening) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Rotating Radar Sweep Sector:
    // Uses full 360-degree stops so the trailing glow smoothly drops to 0 across the
    // trailing 90-degree quadrant and the remaining circle remains fully transparent.
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          const Color(0xFF00E5FF).withValues(alpha: 0.0),
          const Color(0xFF00E5FF).withValues(alpha: 0.05),
          const Color(0xFF00E5FF).withValues(alpha: 0.32),
        ],
        stops: const [0.0, 0.70, 0.85, 1.0],
        transform: GradientRotation(sweepAngle),
      ).createShader(Rect.fromCircle(center: center, radius: radius * 0.95))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius * 0.95, sweepPaint);

    // Leading beam line with vibrant glow
    final beamPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.85)
      ..strokeWidth = 1.8;

    final endPoint = Offset(
      center.dx + radius * 0.95 * cos(sweepAngle),
      center.dy + radius * 0.95 * sin(sweepAngle),
    );
    canvas.drawLine(center, endPoint, beamPaint);
  }

  @override
  bool shouldRepaint(covariant _RadarDynamicSweepPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle ||
        oldDelegate.isListening != isListening;
  }
}
