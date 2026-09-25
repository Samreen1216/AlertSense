import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shimmer/shimmer.dart';
import '../../core/constants/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/theme_provider.dart';
import '../../main.dart';
import '../../providers/settings_providers.dart';

/// Interactive shockwave model created when user touches the screen.
class _Shockwave {
  final Offset position;
  final DateTime createdAt;
  final Color color;

  _Shockwave({
    required this.position,
    required this.createdAt,
    required this.color,
  });
}

/// Floating acoustic particle node.
class _AcousticParticle {
  final double xRatio;
  final double yRatio;
  final double radius;
  final double speed;
  final double phase;
  final double verticalRange;

  _AcousticParticle({
    required this.xRatio,
    required this.yRatio,
    required this.radius,
    required this.speed,
    required this.phase,
    required this.verticalRange,
  });
}

/// Theme-specific color configuration for the splash screen.
class _SplashThemeColors {
  final List<Color> backgroundGradient;
  final Color primaryGlow;
  final Color secondaryAccent;
  final Color radarColor;
  final Color titleColor;
  final Color subtitleColor;
  final Color cardBackground;
  final Color cardBorder;
  final double cardBorderWidth;
  final Color equalizerColorStart;
  final Color equalizerColorEnd;
  final Color progressFill;
  final Color badgeBackground;
  final Color badgeText;
  final bool isHighContrast;

  const _SplashThemeColors({
    required this.backgroundGradient,
    required this.primaryGlow,
    required this.secondaryAccent,
    required this.radarColor,
    required this.titleColor,
    required this.subtitleColor,
    required this.cardBackground,
    required this.cardBorder,
    required this.cardBorderWidth,
    required this.equalizerColorStart,
    required this.equalizerColorEnd,
    required this.progressFill,
    required this.badgeBackground,
    required this.badgeText,
    this.isHighContrast = false,
  });

  factory _SplashThemeColors.resolve(ThemeType themeType) {
    switch (themeType) {
      case ThemeType.light:
        return const _SplashThemeColors(
          backgroundGradient: [
            Color(0xFFFFFFFF),
            Color(0xFFF0F5FA),
            Color(0xFFE2E8F0),
          ],
          primaryGlow: Color(0xFF0055D4),
          secondaryAccent: Color(0xFF0284C7),
          radarColor: Color(0xFF0055D4),
          titleColor: Color(0xFF0B192C),
          subtitleColor: Color(0xFF475569),
          cardBackground: Color(0xF2FFFFFF),
          cardBorder: Color(0xFFCBD5E1),
          cardBorderWidth: 1.0,
          equalizerColorStart: Color(0xFF0055D4),
          equalizerColorEnd: Color(0xFF06B6D4),
          progressFill: Color(0xFF0055D4),
          badgeBackground: Color(0xFFE0E7FF),
          badgeText: Color(0xFF1E40AF),
          isHighContrast: false,
        );

      case ThemeType.dark:
        return const _SplashThemeColors(
          backgroundGradient: [
            Color(0xFF131D38),
            Color(0xFF0A0F1D),
            Color(0xFF04060C),
          ],
          primaryGlow: Color(0xFF00E5FF),
          secondaryAccent: Color(0xFF38BDF8),
          radarColor: Color(0xFF00E5FF),
          titleColor: Colors.white,
          subtitleColor: Color(0xFF94A3B8),
          cardBackground: Color(0xCC162035),
          cardBorder: Color(0xFF1E3A5F),
          cardBorderWidth: 1.2,
          equalizerColorStart: Color(0xFF00E5FF),
          equalizerColorEnd: Color(0xFF3B82F6),
          progressFill: Color(0xFF00E5FF),
          badgeBackground: Color(0xFF1E293B),
          badgeText: Color(0xFF38BDF8),
          isHighContrast: false,
        );

      case ThemeType.highContrast:
        return const _SplashThemeColors(
          backgroundGradient: [
            Color(0xFF000000),
            Color(0xFF000000),
          ],
          primaryGlow: Color(0xFF00FF41),
          secondaryAccent: Color(0xFFFFD600),
          radarColor: Color(0xFF00FF41),
          titleColor: Colors.white,
          subtitleColor: Color(0xFF00FF41),
          cardBackground: Color(0xFF000000),
          cardBorder: Color(0xFF00FF41),
          cardBorderWidth: 2.0,
          equalizerColorStart: Color(0xFF00FF41),
          equalizerColorEnd: Color(0xFFFFD600),
          progressFill: Color(0xFF00FF41),
          badgeBackground: Color(0xFF000000),
          badgeText: Color(0xFFFFD600),
          isHighContrast: true,
        );

      case ThemeType.colorBlindSafe:
        return const _SplashThemeColors(
          backgroundGradient: [
            Color(0xFFFDFEFE),
            Color(0xFFF1F5F9),
            Color(0xFFE2E8F0),
          ],
          primaryGlow: Color(0xFF0077BB),
          secondaryAccent: Color(0xFFEE7733),
          radarColor: Color(0xFF0077BB),
          titleColor: Color(0xFF0F172A),
          subtitleColor: Color(0xFF334155),
          cardBackground: Color(0xF5FFFFFF),
          cardBorder: Color(0xFF94A3B8),
          cardBorderWidth: 1.2,
          equalizerColorStart: Color(0xFF0077BB),
          equalizerColorEnd: Color(0xFFEE7733),
          progressFill: Color(0xFF0077BB),
          badgeBackground: Color(0xFFE0F2FE),
          badgeText: Color(0xFF0369A1),
          isHighContrast: false,
        );
    }
  }
}

/// A premium, highly animated, and fully interactive splash screen suitable for all themes.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with TickerProviderStateMixin {
  // Animation controllers
  late final AnimationController _pulseController;
  late final AnimationController _orbitController;
  late final AnimationController _eqController;
  late final AnimationController _introController;
  late final AnimationController _progressController;
  late final AnimationController _touchTicker;

  // Staggered intro animations
  late final Animation<double> _logoScale;
  late final Animation<double> _logoOpacity;
  late final Animation<double> _titleSlide;
  late final Animation<double> _titleOpacity;
  late final Animation<double> _subtitleOpacity;
  late final Animation<double> _pillsOpacity;
  late final Animation<double> _progressOpacity;

  // Interactive touch state
  final List<_Shockwave> _shockwaves = [];
  Offset _pointerOffset = Offset.zero;
  int _interactivePulseCount = 0;
  bool _navigated = false;
  double _touchExcitement = 0.0;

  // Pre-generated static particles for smooth trigonometric animation
  late final List<_AcousticParticle> _particles;

  // Sound categories showcased on splash
  static const List<Map<String, dynamic>> _soundHighlights = [
    {
      'label': 'Siren & Emergency',
      'icon': Icons.warning_amber_rounded,
      'color': AppColors.emergencySiren,
    },
    {
      'label': 'Fire & Smoke',
      'icon': Icons.local_fire_department_rounded,
      'color': AppColors.fireAlarm,
    },
    {
      'label': 'Doorbell & Knock',
      'icon': Icons.doorbell_rounded,
      'color': AppColors.doorbell,
    },
    {
      'label': 'Baby Crying',
      'icon': Icons.child_care_rounded,
      'color': AppColors.babyCrying,
    },
    {
      'label': 'Haptic Pulse',
      'icon': Icons.vibration_rounded,
      'color': Color(0xFF8B5CF6),
    },
    {
      'label': 'Strobe Alert',
      'icon': Icons.flash_on_rounded,
      'color': Color(0xFFF59E0B),
    },
  ];

  @override
  void initState() {
    super.initState();

    // 1. Radar wave breathing & expansion (3000ms loop)
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3000),
    )..repeat();

    // 2. Orbital satellite rotation (8000ms loop)
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 8000),
    )..repeat();

    // 3. Audio equalizer dynamic frequency bounce (1100ms loop)
    _eqController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    )..repeat(reverse: true);

    // 4. Staggered intro animation (1600ms once)
    _introController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    );

    _logoScale = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.55, curve: Curves.easeOutBack),
    );

    _logoOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.0, 0.4, curve: Curves.easeIn),
    );

    _titleSlide = Tween<double>(begin: 24.0, end: 0.0).animate(
      CurvedAnimation(
        parent: _introController,
        curve: const Interval(0.35, 0.75, curve: Curves.easeOutCubic),
      ),
    );

    _titleOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.35, 0.70, curve: Curves.easeIn),
    );

    _subtitleOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.55, 0.85, curve: Curves.easeIn),
    );

    _pillsOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.65, 0.95, curve: Curves.easeIn),
    );

    _progressOpacity = CurvedAnimation(
      parent: _introController,
      curve: const Interval(0.75, 1.0, curve: Curves.easeIn),
    );

    // 5. Intelligent progress loading sequence (2800ms)
    _progressController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    _progressController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        // Automatically proceed after loading completes smoothly
        Future.delayed(const Duration(milliseconds: 450), () {
          if (mounted && !_navigated) {
            _proceedToApp();
          }
        });
      }
    });

    // 6. Touch shockwave updater ticker
    _touchTicker = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..addListener(() {
        if (_shockwaves.isNotEmpty) {
          final now = DateTime.now();
          _shockwaves.removeWhere(
              (w) => now.difference(w.createdAt).inMilliseconds > 900);
          if (_touchExcitement > 0.01) {
            _touchExcitement *= 0.94;
          } else {
            _touchExcitement = 0.0;
          }
          setState(() {});
        }
      });
    _touchTicker.repeat();

    // Generate 26 harmonic ambient particles
    final random = math.Random(42);
    _particles = List.generate(26, (i) {
      return _AcousticParticle(
        xRatio: random.nextDouble(),
        yRatio: random.nextDouble(),
        radius: 1.5 + random.nextDouble() * 3.5,
        speed: 0.4 + random.nextDouble() * 1.2,
        phase: random.nextDouble() * math.pi * 2,
        verticalRange: 12.0 + random.nextDouble() * 24.0,
      );
    });

    // Start intro and progress
    _introController.forward();
    _progressController.forward();
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _orbitController.dispose();
    _eqController.dispose();
    _introController.dispose();
    _progressController.dispose();
    _touchTicker.dispose();
    super.dispose();
  }

  void _handlePointerTap(TapDownDetails details, _SplashThemeColors colors) {
    HapticFeedback.lightImpact();
    setState(() {
      _shockwaves.add(_Shockwave(
        position: details.localPosition,
        createdAt: DateTime.now(),
        color: colors.primaryGlow,
      ));
      _interactivePulseCount++;
      _touchExcitement = 1.0;
      _pointerOffset = details.localPosition;
    });
  }

  void _handlePointerMove(PointerMoveEvent details, _SplashThemeColors colors) {
    setState(() {
      _pointerOffset = details.localPosition;
    });
    // Add lightweight wave on drag periodically
    if (_shockwaves.isEmpty ||
        DateTime.now().difference(_shockwaves.last.createdAt).inMilliseconds > 180) {
      setState(() {
        _shockwaves.add(_Shockwave(
          position: details.localPosition,
          createdAt: DateTime.now(),
          color: colors.secondaryAccent,
        ));
      });
    }
  }

  void _proceedToApp() {
    if (_navigated || !mounted) return;
    _navigated = true;

    // Check if opened as modal preview or cold launch
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
      return;
    }

    final settings = ref.read(userSettingsProvider);
    final localStorage = ref.read(localStorageProvider);
    final isOnboarded =
        settings.onboardingCompleted || localStorage.isOnboardingComplete();

    if (!isOnboarded) {
      context.go(AppRoutes.onboarding);
    } else {
      context.go(AppRoutes.home);
    }
  }

  void _cycleTheme(ThemeType currentTheme) {
    HapticFeedback.selectionClick();
    const values = ThemeType.values;
    final nextIndex = (values.indexOf(currentTheme) + 1) % values.length;
    ref.read(themeTypeProvider.notifier).setTheme(values[nextIndex]);
  }

  String _getThemeName(ThemeType type) {
    switch (type) {
      case ThemeType.light:
        return 'Light';
      case ThemeType.dark:
        return 'Dark';
      case ThemeType.highContrast:
        return 'High Contrast';
      case ThemeType.colorBlindSafe:
        return 'Color-Blind Safe';
    }
  }

  IconData _getThemeIcon(ThemeType type) {
    switch (type) {
      case ThemeType.light:
        return Icons.light_mode_rounded;
      case ThemeType.dark:
        return Icons.dark_mode_rounded;
      case ThemeType.highContrast:
        return Icons.contrast_rounded;
      case ThemeType.colorBlindSafe:
        return Icons.color_lens_rounded;
    }
  }

  String _getStatusText(double progress) {
    if (progress < 0.28) {
      return 'Calibrating Neural Acoustic Engine...';
    } else if (progress < 0.60) {
      return 'Loading YAMNet Environmental Sound Models...';
    } else if (progress < 0.88) {
      return 'Synchronizing Haptic & Visual Channels...';
    } else {
      return 'AlertSense Neural Engine Active • Ready';
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTheme = ref.watch(themeTypeProvider);
    final splashColors = _SplashThemeColors.resolve(currentTheme);
    final size = MediaQuery.of(context).size;

    // Normalized tilt offset for 3D card effect (-1.0 to 1.0)
    final tiltX = (_pointerOffset.dy - (size.height / 2)) / (size.height / 2);
    final tiltY = (_pointerOffset.dx - (size.width / 2)) / (size.width / 2);
    final safeTiltX = tiltX.clamp(-1.0, 1.0) * 0.08;
    final safeTiltY = tiltY.clamp(-1.0, 1.0) * 0.08;

    return Scaffold(
      backgroundColor: splashColors.backgroundGradient.last,
      body: Listener(
        onPointerMove: (e) => _handlePointerMove(e, splashColors),
        child: GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTapDown: (d) => _handlePointerTap(d, splashColors),
          child: Stack(
            children: [
              // ── 1. Theme-Adaptive Background Gradient ──────────────────
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: RadialGradient(
                      center: const Alignment(0, -0.15),
                      radius: 1.15,
                      colors: splashColors.backgroundGradient,
                    ),
                  ),
                ),
              ),

              // ── 2. Ambient Acoustic Radar Rings & Shockwaves ────────────
              Positioned.fill(
                child: AnimatedBuilder(
                  animation: Listenable.merge([_pulseController, _orbitController]),
                  builder: (context, _) {
                    return CustomPaint(
                      painter: _AcousticRadarPainter(
                        pulseProgress: _pulseController.value,
                        orbitAngle: _orbitController.value * math.pi * 2,
                        colors: splashColors,
                        shockwaves: _shockwaves,
                        particles: _particles,
                        touchExcitement: _touchExcitement,
                      ),
                    );
                  },
                ),
              ),

              // ── 3. Main Centerpiece & Interactive Content ───────────────
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isCompact = constraints.maxHeight < 680;
                    return Column(
                      children: [
                        // Top Bar: Theme Switcher & Skip Button
                        _buildTopBar(currentTheme, splashColors),

                        const Spacer(flex: 2),

                        // Center Emblem with 3D Parallax & Breathing Glow
                        _buildCenterEmblem(splashColors, safeTiltX, safeTiltY, isCompact),

                        SizedBox(height: isCompact ? 16 : 28),

                        // Animated Title & Tagline
                        _buildBrandTypography(splashColors, isCompact),

                        SizedBox(height: isCompact ? 16 : 24),

                        // Live Acoustic Frequency Equalizer
                        _buildEqualizer(splashColors),

                        SizedBox(height: isCompact ? 12 : 20),

                        // Dynamic Feature Pills Horizontal Ribbon
                        _buildFeaturePills(splashColors),

                        const Spacer(flex: 3),

                        // Progress Bar & Initialization State
                        _buildStatusProgress(splashColors, isCompact),

                        SizedBox(height: isCompact ? 12 : 20),

                        // Action Button ("Get Started / Continue")
                        _buildActionButton(splashColors),

                        const SizedBox(height: 12),
                      ],
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Top Bar Controls ────────────────────────────────────────────────────────
  Widget _buildTopBar(ThemeType currentTheme, _SplashThemeColors colors) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Theme Switcher Button with Active Theme Icon
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () => _cycleTheme(currentTheme),
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colors.cardBorder,
                    width: colors.cardBorderWidth,
                  ),
                  boxShadow: colors.isHighContrast
                      ? null
                      : [
                          BoxShadow(
                            color: colors.primaryGlow.withValues(alpha: 0.12),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getThemeIcon(currentTheme),
                      size: 16,
                      color: colors.primaryGlow,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _getThemeName(currentTheme),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.titleColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.swap_horiz_rounded,
                      size: 14,
                      color: colors.subtitleColor,
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Skip Button
          Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: _proceedToApp,
              borderRadius: BorderRadius.circular(20),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: colors.cardBackground,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: colors.cardBorder,
                    width: colors.cardBorderWidth,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.subtitleColor,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 16,
                      color: colors.subtitleColor,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Center Brand Emblem ───────────────────────────────────────────────────
  Widget _buildCenterEmblem(
    _SplashThemeColors colors,
    double tiltX,
    double tiltY,
    bool isCompact,
  ) {
    final emblemSize = isCompact ? 110.0 : 138.0;

    return AnimatedBuilder(
      animation: Listenable.merge([_introController, _pulseController]),
      builder: (context, child) {
        // Breathing scale oscillation
        final breathingScale = 1.0 + 0.04 * math.sin(_pulseController.value * math.pi * 2);
        final effectiveScale = _logoScale.value * breathingScale;

        return Transform(
          alignment: Alignment.center,
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.001)
            ..rotateX(tiltX)
            ..rotateY(tiltY)
            ..scale(effectiveScale, effectiveScale, 1.0),
          child: Opacity(
            opacity: _logoOpacity.value,
            child: SizedBox(
              width: emblemSize + 40,
              height: emblemSize + 40,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Outer Ambient Breathing Glow
                  Container(
                    width: emblemSize + 26,
                    height: emblemSize + 26,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: colors.primaryGlow.withValues(
                            alpha: colors.isHighContrast ? 0.3 : 0.45,
                          ),
                          blurRadius: colors.isHighContrast ? 16 : 38,
                          spreadRadius: colors.isHighContrast ? 2 : 8,
                        ),
                      ],
                    ),
                  ),

                  // Emblem Outer Orbital Glass Ring
                  Container(
                    width: emblemSize,
                    height: emblemSize,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: colors.cardBackground,
                      border: Border.all(
                        color: colors.cardBorder,
                        width: colors.cardBorderWidth + 0.5,
                      ),
                      boxShadow: colors.isHighContrast
                          ? null
                          : [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.12),
                                blurRadius: 18,
                                offset: const Offset(0, 8),
                              ),
                            ],
                    ),
                    child: Center(
                      child: Container(
                        width: emblemSize - 20,
                        height: emblemSize - 20,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              colors.primaryGlow,
                              colors.secondaryAccent,
                            ],
                          ),
                        ),
                        child: Center(
                          child: Icon(
                            Icons.hearing_rounded,
                            size: emblemSize * 0.46,
                            color: colors.isHighContrast
                                ? Colors.black
                                : Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Floating AI Shield Overlay Badge
                  Positioned(
                    bottom: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.all(5),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: colors.isHighContrast
                            ? Colors.black
                            : colors.primaryGlow,
                        border: Border.all(
                          color: colors.isHighContrast
                              ? colors.primaryGlow
                              : Colors.white,
                          width: 2.0,
                        ),
                      ),
                      child: Icon(
                        Icons.shield_rounded,
                        size: 15,
                        color: colors.isHighContrast
                            ? colors.primaryGlow
                            : Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ── Brand Typography ──────────────────────────────────────────────────────
  Widget _buildBrandTypography(_SplashThemeColors colors, bool isCompact) {
    return AnimatedBuilder(
      animation: _introController,
      builder: (context, child) {
        return Transform.translate(
          offset: Offset(0, _titleSlide.value),
          child: Opacity(
            opacity: _titleOpacity.value,
            child: Column(
              children: [
                // App Title with Shimmer Glow
                Shimmer.fromColors(
                  baseColor: colors.titleColor,
                  highlightColor: colors.primaryGlow,
                  period: const Duration(milliseconds: 3200),
                  child: Text(
                    'AlertSense',
                    style: TextStyle(
                      fontSize: isCompact ? 28 : 36,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: colors.titleColor,
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // AI Environmental Awareness Tag
                Opacity(
                  opacity: _subtitleOpacity.value,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: colors.badgeBackground,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: colors.cardBorder,
                        width: colors.cardBorderWidth,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: colors.primaryGlow,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'AI Environmental Sound Awareness',
                          style: TextStyle(
                            fontSize: isCompact ? 11 : 12,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.3,
                            color: colors.badgeText,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 6),

                // Subtitle
                Opacity(
                  opacity: _subtitleOpacity.value,
                  child: Text(
                    'Turn important sounds into alerts you can see and feel',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: isCompact ? 12 : 13,
                      fontWeight: FontWeight.w500,
                      color: colors.subtitleColor,
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

  // ── Live Acoustic Equalizer ───────────────────────────────────────────────
  Widget _buildEqualizer(_SplashThemeColors colors) {
    return AnimatedBuilder(
      animation: Listenable.merge([_introController, _eqController]),
      builder: (context, child) {
        return Opacity(
          opacity: _progressOpacity.value,
          child: Container(
            height: 38,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(15, (index) {
                // Wave height calculations with harmonic frequency shifts
                final basePhase = (index * 0.45) + (_eqController.value * math.pi * 2);
                final waveHeight = 6.0 +
                    18.0 * (0.5 + 0.5 * math.sin(basePhase)) +
                    (_touchExcitement * 10.0 * math.sin(index.toDouble()));
                final clampedHeight = waveHeight.clamp(4.0, 36.0);

                return Container(
                  width: 3.5,
                  height: clampedHeight,
                  margin: const EdgeInsets.symmetric(horizontal: 2.2),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(3),
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        colors.equalizerColorStart,
                        colors.equalizerColorEnd,
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      },
    );
  }

  // ── Dynamic Feature Pills Ribbon ──────────────────────────────────────────
  Widget _buildFeaturePills(_SplashThemeColors colors) {
    return AnimatedBuilder(
      animation: _introController,
      builder: (context, child) {
        return Opacity(
          opacity: _pillsOpacity.value,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: _soundHighlights.map((item) {
                final color = item['color'] as Color;
                final icon = item['icon'] as IconData;
                final label = item['label'] as String;

                return Container(
                  margin: const EdgeInsets.only(right: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                  decoration: BoxDecoration(
                    color: colors.cardBackground,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: colors.cardBorder,
                      width: colors.cardBorderWidth,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(icon, size: 14, color: color),
                      const SizedBox(width: 5),
                      Text(
                        label,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.titleColor,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  // ── Status & Intelligent Progress ─────────────────────────────────────────
  Widget _buildStatusProgress(_SplashThemeColors colors, bool isCompact) {
    return AnimatedBuilder(
      animation: Listenable.merge([_introController, _progressController]),
      builder: (context, child) {
        final progress = _progressController.value;
        final statusText = _getStatusText(progress);

        return Opacity(
          opacity: _progressOpacity.value,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              children: [
                // Dynamic Status Text
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        statusText,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: colors.subtitleColor,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '${(progress * 100).toInt()}%',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: colors.primaryGlow,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Progress Track
                Container(
                  height: 6,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: colors.cardBorder.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FractionallySizedBox(
                    alignment: Alignment.centerLeft,
                    widthFactor: progress.clamp(0.01, 1.0),
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(3),
                        gradient: LinearGradient(
                          colors: [
                            colors.equalizerColorStart,
                            colors.equalizerColorEnd,
                          ],
                        ),
                        boxShadow: colors.isHighContrast
                            ? null
                            : [
                                BoxShadow(
                                  color: colors.primaryGlow.withValues(alpha: 0.5),
                                  blurRadius: 6,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Interactive Hint / Pulse Counter
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.touch_app_rounded,
                      size: 13,
                      color: colors.primaryGlow,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _interactivePulseCount == 0
                          ? 'Tap anywhere on screen to emit acoustic waves'
                          : 'Acoustic pulses emitted: $_interactivePulseCount',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: colors.subtitleColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── Action Button ("Get Started") ─────────────────────────────────────────
  Widget _buildActionButton(_SplashThemeColors colors) {
    return AnimatedBuilder(
      animation: _progressController,
      builder: (context, child) {
        final isReady = _progressController.value > 0.85;

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              onPressed: _proceedToApp,
              style: ElevatedButton.styleFrom(
                backgroundColor: isReady
                    ? colors.primaryGlow
                    : colors.cardBackground,
                foregroundColor: isReady
                    ? (colors.isHighContrast ? Colors.black : Colors.white)
                    : colors.titleColor,
                elevation: isReady && !colors.isHighContrast ? 4 : 0,
                shadowColor: colors.primaryGlow.withValues(alpha: 0.4),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(
                    color: colors.cardBorder,
                    width: colors.cardBorderWidth,
                  ),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    isReady ? 'Get Started' : 'Enter AlertSense',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: isReady
                          ? (colors.isHighContrast ? Colors.black : Colors.white)
                          : colors.titleColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(
                    Icons.arrow_forward_rounded,
                    size: 18,
                    color: isReady
                        ? (colors.isHighContrast ? Colors.black : Colors.white)
                        : colors.titleColor,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Custom painter for concentric acoustic radar pulses, floating particles, and touch shockwaves.
class _AcousticRadarPainter extends CustomPainter {
  final double pulseProgress;
  final double orbitAngle;
  final _SplashThemeColors colors;
  final List<_Shockwave> shockwaves;
  final List<_AcousticParticle> particles;
  final double touchExcitement;

  _AcousticRadarPainter({
    required this.pulseProgress,
    required this.orbitAngle,
    required this.colors,
    required this.shockwaves,
    required this.particles,
    required this.touchExcitement,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height * 0.38);

    // ── 1. Concentric Acoustic Waves Outward from Emblem ──────────────────
    final ringPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final ringCount = colors.isHighContrast ? 3 : 4;
    for (int i = 0; i < ringCount; i++) {
      final ringProgress = (pulseProgress + (i / ringCount)) % 1.0;
      final radius = 70.0 + (ringProgress * 230.0);
      final opacity = colors.isHighContrast
          ? (1.0 - ringProgress).clamp(0.2, 0.9)
          : ((1.0 - ringProgress) * 0.38).clamp(0.0, 0.4);

      ringPaint.color = colors.radarColor.withValues(alpha: opacity);
      ringPaint.strokeWidth = colors.isHighContrast ? 2.0 : 1.2;

      canvas.drawCircle(center, radius, ringPaint);

      // Draw acoustic wave arc accents on the outer rings
      if (!colors.isHighContrast && i % 2 == 0) {
        final arcPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0
          ..color = colors.secondaryAccent.withValues(alpha: opacity * 0.85);

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: radius),
          orbitAngle + (i * math.pi / 2),
          math.pi / 3,
          false,
          arcPaint,
        );
      }
    }

    // ── 2. Rotating Orbital Satellites ──────────────────────────────────────
    final orbitRadius = 88.0 + (touchExcitement * 8.0);
    final satellitePaint = Paint()..style = PaintingStyle.fill;

    for (int s = 0; s < 2; s++) {
      final angle = orbitAngle + (s * math.pi);
      final satPos = Offset(
        center.dx + orbitRadius * math.cos(angle),
        center.dy + orbitRadius * math.sin(angle),
      );

      satellitePaint.color = s == 0 ? colors.primaryGlow : colors.secondaryAccent;
      canvas.drawCircle(satPos, colors.isHighContrast ? 4.5 : 3.5, satellitePaint);

      if (!colors.isHighContrast) {
        final glowPaint = Paint()
          ..color = satellitePaint.color.withValues(alpha: 0.3)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(satPos, 6.0, glowPaint);
      }
    }

    // ── 3. Harmonic Ambient Floating Particles ──────────────────────────────
    final particlePaint = Paint()..style = PaintingStyle.fill;
    final nowMs = DateTime.now().millisecondsSinceEpoch;

    for (final p in particles) {
      final t = (nowMs / 1000.0) * p.speed + p.phase;
      final dyOffset = math.sin(t) * p.verticalRange;
      final dxOffset = math.cos(t * 0.7) * (p.verticalRange * 0.4);

      final pPos = Offset(
        (p.xRatio * size.width) + dxOffset,
        (p.yRatio * size.height) + dyOffset,
      );

      final particleOpacity = colors.isHighContrast
          ? 0.8
          : (0.25 + 0.35 * (0.5 + 0.5 * math.sin(t))).clamp(0.1, 0.7);

      particlePaint.color = colors.primaryGlow.withValues(alpha: particleOpacity);
      canvas.drawCircle(pPos, p.radius, particlePaint);
    }

    // ── 4. Interactive Touch Shockwaves ─────────────────────────────────────
    final now = DateTime.now();
    for (final shockwave in shockwaves) {
      final elapsedMs = now.difference(shockwave.createdAt).inMilliseconds;
      if (elapsedMs > 900) continue;

      final progress = (elapsedMs / 900.0).clamp(0.0, 1.0);
      final waveRadius = progress * 160.0;
      final waveOpacity = ((1.0 - progress) * 0.75).clamp(0.0, 1.0);

      final wavePaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = (3.5 * (1.0 - progress)).clamp(1.0, 3.5)
        ..color = shockwave.color.withValues(alpha: waveOpacity);

      canvas.drawCircle(shockwave.position, waveRadius, wavePaint);

      // Second trailing echo ring
      if (progress > 0.15) {
        final echoProgress = (progress - 0.15) / 0.85;
        final echoRadius = echoProgress * 120.0;
        final echoOpacity = ((1.0 - echoProgress) * 0.45).clamp(0.0, 1.0);

        final echoPaint = Paint()
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.2
          ..color = colors.secondaryAccent.withValues(alpha: echoOpacity);

        canvas.drawCircle(shockwave.position, echoRadius, echoPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _AcousticRadarPainter oldDelegate) => true;
}
