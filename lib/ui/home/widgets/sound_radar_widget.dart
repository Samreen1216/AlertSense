import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_svg_icons.dart';
import '../../../providers/audio_providers.dart';

class SoundRadarWidget extends ConsumerStatefulWidget {
  const SoundRadarWidget({super.key});

  @override
  ConsumerState<SoundRadarWidget> createState() => _SoundRadarWidgetState();
}

class _SoundRadarWidgetState extends ConsumerState<SoundRadarWidget>
    with TickerProviderStateMixin {
  late AnimationController _sweepController;
  late AnimationController _pulseController;
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _sweepController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();
  }

  @override
  void dispose() {
    _sweepController.dispose();
    _pulseController.dispose();
    _waveController.dispose();
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

    return Container(
      height: 300,
      decoration: BoxDecoration(
        gradient: const RadialGradient(
          center: Alignment.center,
          radius: 0.9,
          colors: [
            Color(0xFF141E33),
            Color(0xFF090D16),
          ],
        ),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: isListening
              ? const Color(0xFF00E5FF).withValues(alpha: 0.3)
              : Colors.white.withValues(alpha: 0.08),
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isListening
                ? const Color(0xFF00E5FF).withValues(alpha: 0.12)
                : Colors.black.withValues(alpha: 0.3),
            blurRadius: 24,
            spreadRadius: isListening ? 2 : 0,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          // Background grid & radar
          Positioned.fill(
            child: isListening
                ? LayoutBuilder(
                    builder: (context, constraints) {
                      final radius =
                          min(constraints.maxWidth, constraints.maxHeight) / 2.3;

                      return Stack(
                        alignment: Alignment.center,
                        children: [
                          // Compass ticks & radar circles
                          AnimatedBuilder(
                            animation: _sweepController,
                            builder: (context, child) {
                              return CustomPaint(
                                size: Size(constraints.maxWidth,
                                    constraints.maxHeight),
                                painter: _ModernRadarPainter(
                                  sweepAngle: _sweepController.value * 2 * pi,
                                  radius: radius,
                                ),
                              );
                            },
                          ),

                          // Center microphone node
                          AnimatedBuilder(
                            animation: _pulseController,
                            builder: (context, child) {
                              final glow = _pulseController.value * 8;
                              return Container(
                                width: 56,
                                height: 56,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  gradient: const LinearGradient(
                                    colors: [Color(0xFF00E5FF), Color(0xFF0055D4)],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: const Color(0xFF00E5FF)
                                          .withValues(alpha: 0.6),
                                      blurRadius: 16 + glow,
                                      spreadRadius: 2,
                                    ),
                                  ],
                                ),
                                child: const Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.mic_rounded,
                                        color: Colors.white, size: 24),
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
                              );
                            },
                          ),

                          // Detected sound pins
                          ...detectedSounds.map((sound) {
                            final distance = radius *
                                (1.0 - (sound.confidence / 100).clamp(0.2, 0.9));
                            final dx = distance * cos(sound.angle);
                            final dy = distance * sin(sound.angle);

                            final category = sound.category;
                            final dotColor = category.color;
                            final label = category.label;

                            return AnimatedBuilder(
                              animation: _pulseController,
                              builder: (context, child) {
                                final scale = 1.0 +
                                    (_pulseController.value *
                                        0.2 *
                                        (sound.confidence / 100));
                                return Positioned(
                                  left: (constraints.maxWidth / 2) + dx - 36,
                                  top: (constraints.maxHeight / 2) + dy - 36,
                                  child: Transform.scale(
                                    scale: scale,
                                    child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.all(10),
                                          decoration: BoxDecoration(
                                            color: dotColor,
                                            shape: BoxShape.circle,
                                            boxShadow: [
                                              BoxShadow(
                                                color: dotColor
                                                    .withValues(alpha: 0.7),
                                                blurRadius: 16,
                                                spreadRadius: 4,
                                              ),
                                            ],
                                          ),
                                          child: AppSvgIcon(
                                            iconKey: category.name,
                                            size: 18,
                                            color: Colors.white,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.black.withValues(
                                                alpha: 0.8),
                                            borderRadius:
                                                BorderRadius.circular(10),
                                            border: Border.all(
                                              color: dotColor.withValues(
                                                  alpha: 0.5),
                                              width: 1,
                                            ),
                                          ),
                                          child: Text(
                                            '$label (${sound.confidence.toInt()}%)',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            );
                          }),
                        ],
                      );
                    },
                  )
                : _buildIdleState(context),
          ),

          // Top Header Overlay inside Radar
          Positioned(
            top: 14,
            left: 18,
            right: 18,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isListening
                            ? const Color(0xFF00E676)
                            : Colors.white38,
                        boxShadow: isListening
                            ? [
                                const BoxShadow(
                                  color: Color(0xFF00E676),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                )
                              ]
                            : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isListening ? '360° ACOUSTIC RADAR' : 'RADAR STANDBY',
                      style: TextStyle(
                        color: isListening
                            ? const Color(0xFF00E5FF)
                            : Colors.white54,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
                if (isListening)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.3),
                      ),
                    ),
                    child: const Text(
                      'LIVE DSP SCAN',
                      style: TextStyle(
                        color: Color(0xFF00E5FF),
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.8,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIdleState(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          GestureDetector(
            onTap: () => ref.read(isListeningProvider.notifier).start(),
            child: AnimatedBuilder(
              animation: _waveController,
              builder: (context, child) {
                return Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const LinearGradient(
                      colors: [Color(0xFF1E293B), Color(0xFF0F172A)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    border: Border.all(
                      color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF00E5FF).withValues(alpha: 0.15),
                        blurRadius: 20,
                        spreadRadius: 4,
                      ),
                    ],
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.play_arrow_rounded,
                      color: Color(0xFF00E5FF),
                      size: 44,
                    ),
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 18),
          const Text(
            'TAP TO START RADAR',
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
              letterSpacing: 1.8,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Real-time sound direction & AI detection',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.5),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class _ModernRadarPainter extends CustomPainter {
  final double sweepAngle;
  final double radius;

  _ModernRadarPainter({required this.sweepAngle, required this.radius});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);

    // Grid circles
    final circlePaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.12)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawCircle(center, radius * 0.35, circlePaint);
    canvas.drawCircle(center, radius * 0.70, circlePaint);
    canvas.drawCircle(center, radius, circlePaint);

    // Crosshairs
    final crossPaint = Paint()
      ..color = const Color(0xFF00E5FF).withValues(alpha: 0.15)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawLine(Offset(center.dx, center.dy - radius),
        Offset(center.dx, center.dy + radius), crossPaint);
    canvas.drawLine(Offset(center.dx - radius, center.dy),
        Offset(center.dx + radius, center.dy), crossPaint);

    // Radial sweep gradient
    final sweepPaint = Paint()
      ..shader = SweepGradient(
        colors: [
          Colors.transparent,
          const Color(0xFF00E5FF).withValues(alpha: 0.05),
          const Color(0xFF00E5FF).withValues(alpha: 0.35),
        ],
        stops: const [0.0, 0.85, 1.0],
        transform: GradientRotation(sweepAngle - pi / 2),
      ).createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.fill;

    canvas.drawCircle(center, radius, sweepPaint);

    // Leading sweep beam
    final linePaint = Paint()
      ..color = const Color(0xFF00E5FF)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke
      ..maskFilter = const MaskFilter.blur(BlurStyle.solid, 2);

    final dx = radius * cos(sweepAngle);
    final dy = radius * sin(sweepAngle);
    canvas.drawLine(center, Offset(center.dx + dx, center.dy + dy), linePaint);
  }

  @override
  bool shouldRepaint(covariant _ModernRadarPainter oldDelegate) {
    return oldDelegate.sweepAngle != sweepAngle || oldDelegate.radius != radius;
  }
}
