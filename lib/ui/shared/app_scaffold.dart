import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../../core/constants/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/responsive_utils.dart';
import '../../data/models/alert_event.dart';
import '../../providers/service_providers.dart';
import '../../providers/settings_providers.dart';
import '../alert/full_screen_alert.dart';
import 'in_app_notification_banner.dart';

class AppScaffold extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const AppScaffold({super.key, required this.navigationShell});

  @override
  ConsumerState<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends ConsumerState<AppScaffold>
    with SingleTickerProviderStateMixin {
  StreamSubscription? _urgentSub;
  StreamSubscription? _allAlertsSub;
  AlertEvent? _activeBannerAlert;
  late AnimationController _pulseController;
  late Animation<double> _pulseScaleAnimation;
  late Animation<double> _pulseOpacityAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _pulseScaleAnimation = Tween<double>(begin: 1.0, end: 1.16).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _pulseOpacityAnimation = Tween<double>(begin: 0.38, end: 0.06).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _subscribeToAlerts());
  }

  void _subscribeToAlerts() {
    final dispatcher = ref.read(alertDispatcherServiceProvider);

    // 1. High-priority full-screen overlay for critical alarms (suppressed in Sleep Mode)
    _urgentSub = dispatcher.urgentAlertStream.listen((alert) {
      if (!mounted) return;
      final currentProfile = ref.read(currentProfileProvider);
      final isSleep = currentProfile.name.toLowerCase() == 'sleep';
      if (isSleep) return;

      // Prevent stacking duplicate full-screen alerts when one is already active
      if (FullScreenAlert.isAlertActive) {
        debugPrint('[AppScaffold] FullScreenAlert is already active, ignoring duplicate urgent alert push');
        return;
      }

      context.push(AppRoutes.fullScreenAlert, extra: {
        'id': alert.id,
        'soundCategory': alert.soundCategory,
        'confidence': (alert.confidence * 100).toStringAsFixed(0),
        'priorityLevel': alert.priorityLevel,
        'timestamp': alert.timestamp,
      });
    });

    // 2. On-screen heads-up notification banner for all detected sounds (Bell Ring, Knocking, etc.)
    _allAlertsSub = dispatcher.allAlertsStream.listen((alert) {
      if (!mounted) return;
      setState(() {
        _activeBannerAlert = alert;
      });
    });
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _urgentSub?.cancel();
    _allAlertsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;
    final themeType = ref.watch(themeTypeProvider);
    final isHighContrast = themeType == ThemeType.highContrast;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final isSideNav = ResponsiveBreakpoints.isTablet(context) ||
        ResponsiveBreakpoints.isLandscape(context);

    final contentStack = Stack(
      children: [
        widget.navigationShell,
        if (_activeBannerAlert != null)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: InAppNotificationBanner(
              key: ValueKey(_activeBannerAlert!.id),
              alert: _activeBannerAlert!,
              onDismiss: () {
                if (mounted) setState(() => _activeBannerAlert = null);
              },
            ),
          ),
      ],
    );

    return WithForegroundTask(
      child: Scaffold(
        body: isSideNav
            ? Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSideNavigation(
                    context,
                    currentIndex: currentIndex,
                    themeType: themeType,
                    isDark: isDark,
                    isHighContrast: isHighContrast,
                  ),
                  Expanded(child: contentStack),
                ],
              )
            : contentStack,
        bottomNavigationBar: isSideNav
            ? null
            : _buildBottomNavigation(
                context,
                currentIndex: currentIndex,
                themeType: themeType,
                isDark: isDark,
                isHighContrast: isHighContrast,
              ),
      ),
    );
  }

  Widget _buildBottomNavigation(
    BuildContext context, {
    required int currentIndex,
    required ThemeType themeType,
    required bool isDark,
    required bool isHighContrast,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: isHighContrast
            ? Colors.black
            : (isDark ? const Color(0xFF0D1424) : Colors.white),
        border: isHighContrast
            ? const Border(top: BorderSide(color: Colors.white, width: 2.0))
            : null,
        boxShadow: isHighContrast
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                  blurRadius: 12,
                  offset: const Offset(0, -3),
                ),
              ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // 1. Home
              Expanded(
                child: _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isSelected: currentIndex == 0,
                  isDark: isDark,
                  themeType: themeType,
                  onTap: () {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    widget.navigationShell.goBranch(0, initialLocation: currentIndex == 0);
                  },
                ),
              ),

              // 2. Insights
              Expanded(
                child: _NavItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Insights',
                  isSelected: currentIndex == 1,
                  isDark: isDark,
                  themeType: themeType,
                  onTap: () {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    widget.navigationShell.goBranch(1, initialLocation: currentIndex == 1);
                  },
                ),
              ),

              // 3. Elevated Quick Scan (Center) with Breathing Pulse Glow
              Expanded(
                child: Semantics(
                  label: 'Quick Scan',
                  button: true,
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ScaffoldMessenger.of(context).clearSnackBars();
                    context.push(AppRoutes.quickScan);
                  },
                  child: InkResponse(
                    onTap: () {
                      HapticFeedback.selectionClick();
                      ScaffoldMessenger.of(context).clearSnackBars();
                      context.push(AppRoutes.quickScan);
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AnimatedBuilder(
                          animation: _pulseController,
                          builder: (context, child) {
                            return Stack(
                              alignment: Alignment.center,
                              children: [
                                if (!isHighContrast)
                                  Transform.scale(
                                    scale: _pulseScaleAnimation.value,
                                    child: Container(
                                      width: 44,
                                      height: 44,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: const Color(0xFF0072FF).withValues(
                                          alpha: _pulseOpacityAnimation.value,
                                        ),
                                      ),
                                    ),
                                  ),
                                Container(
                                  width: 44,
                                  height: 44,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: isHighContrast
                                        ? null
                                        : const LinearGradient(
                                            colors: [Color(0xFF0062FF), Color(0xFF00C6FF)],
                                            begin: Alignment.topLeft,
                                            end: Alignment.bottomRight,
                                          ),
                                    color: isHighContrast ? AppColors.hcPrimary : null,
                                    border: isHighContrast
                                        ? Border.all(color: Colors.white, width: 2)
                                        : null,
                                    boxShadow: isHighContrast
                                        ? null
                                        : [
                                            BoxShadow(
                                              color: const Color(0xFF0062FF).withValues(alpha: 0.45),
                                              blurRadius: 10,
                                              spreadRadius: 1,
                                              offset: const Offset(0, 2),
                                            ),
                                          ],
                                  ),
                                  child: Center(
                                    child: Icon(
                                      Icons.graphic_eq_rounded,
                                      color: isHighContrast ? Colors.black : Colors.white,
                                      size: 22,
                                    ),
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 3),
                        Flexible(
                          child: FittedBox(
                            fit: BoxFit.scaleDown,
                            child: Text(
                              'Quick Scan',
                              maxLines: 1,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: isHighContrast
                                    ? Colors.white
                                    : (isDark ? Colors.white70 : const Color(0xFF334155)),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // 4. History
              Expanded(
                child: _NavItem(
                  icon: Icons.history_rounded,
                  label: 'History',
                  isSelected: currentIndex == 2,
                  isDark: isDark,
                  themeType: themeType,
                  onTap: () {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    widget.navigationShell.goBranch(2, initialLocation: currentIndex == 2);
                  },
                ),
              ),

              // 5. Settings
              Expanded(
                child: _NavItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  isSelected: false,
                  isDark: isDark,
                  themeType: themeType,
                  onTap: () {
                    ScaffoldMessenger.of(context).clearSnackBars();
                    context.push(AppRoutes.settings);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSideNavigation(
    BuildContext context, {
    required int currentIndex,
    required ThemeType themeType,
    required bool isDark,
    required bool isHighContrast,
  }) {
    return Container(
      width: 78,
      decoration: BoxDecoration(
        color: isHighContrast
            ? Colors.black
            : (isDark ? const Color(0xFF0D1424) : Colors.white),
        border: isHighContrast
            ? const Border(right: BorderSide(color: Colors.white, width: 2.0))
            : Border(
                right: BorderSide(
                  color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
                  width: 1.0,
                ),
              ),
        boxShadow: isHighContrast
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.06),
                  blurRadius: 10,
                  offset: const Offset(3, 0),
                ),
              ],
      ),
      child: SafeArea(
        right: false,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      // 1. Home
                      _SideNavItem(
                        icon: Icons.home_rounded,
                        label: 'Home',
                        isSelected: currentIndex == 0,
                        isDark: isDark,
                        themeType: themeType,
                        onTap: () {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          widget.navigationShell.goBranch(0, initialLocation: currentIndex == 0);
                        },
                      ),

                      // 2. Insights
                      _SideNavItem(
                        icon: Icons.bar_chart_rounded,
                        label: 'Insights',
                        isSelected: currentIndex == 1,
                        isDark: isDark,
                        themeType: themeType,
                        onTap: () {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          widget.navigationShell.goBranch(1, initialLocation: currentIndex == 1);
                        },
                      ),

                      // 3. Center Quick Scan
                      Semantics(
                        label: 'Quick Scan',
                        button: true,
                        onTap: () {
                          HapticFeedback.selectionClick();
                          ScaffoldMessenger.of(context).clearSnackBars();
                          context.push(AppRoutes.quickScan);
                        },
                        child: InkResponse(
                          onTap: () {
                            HapticFeedback.selectionClick();
                            ScaffoldMessenger.of(context).clearSnackBars();
                            context.push(AppRoutes.quickScan);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4.0),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                AnimatedBuilder(
                                  animation: _pulseController,
                                  builder: (context, child) {
                                    return Stack(
                                      alignment: Alignment.center,
                                      children: [
                                        if (!isHighContrast)
                                          Transform.scale(
                                            scale: _pulseScaleAnimation.value,
                                            child: Container(
                                              width: 44,
                                              height: 44,
                                              decoration: BoxDecoration(
                                                shape: BoxShape.circle,
                                                color: const Color(0xFF0072FF).withValues(
                                                  alpha: _pulseOpacityAnimation.value,
                                                ),
                                              ),
                                            ),
                                          ),
                                        Container(
                                          width: 44,
                                          height: 44,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: isHighContrast
                                                ? null
                                                : const LinearGradient(
                                                    colors: [Color(0xFF0062FF), Color(0xFF00C6FF)],
                                                    begin: Alignment.topLeft,
                                                    end: Alignment.bottomRight,
                                                  ),
                                            color: isHighContrast ? AppColors.hcPrimary : null,
                                            border: isHighContrast
                                                ? Border.all(color: Colors.white, width: 2)
                                                : null,
                                            boxShadow: isHighContrast
                                                ? null
                                                : [
                                                    BoxShadow(
                                                      color: const Color(0xFF0062FF).withValues(alpha: 0.45),
                                                      blurRadius: 10,
                                                      spreadRadius: 1,
                                                      offset: const Offset(0, 2),
                                                    ),
                                                  ],
                                          ),
                                          child: Center(
                                            child: Icon(
                                              Icons.graphic_eq_rounded,
                                              color: isHighContrast ? Colors.black : Colors.white,
                                              size: 22,
                                            ),
                                          ),
                                        ),
                                      ],
                                    );
                                  },
                                ),
                                const SizedBox(height: 3),
                                FittedBox(
                                  fit: BoxFit.scaleDown,
                                  child: Text(
                                    'Quick Scan',
                                    maxLines: 1,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: isHighContrast
                                          ? Colors.white
                                          : (isDark ? Colors.white70 : const Color(0xFF334155)),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),

                      // 4. History
                      _SideNavItem(
                        icon: Icons.history_rounded,
                        label: 'History',
                        isSelected: currentIndex == 2,
                        isDark: isDark,
                        themeType: themeType,
                        onTap: () {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          widget.navigationShell.goBranch(2, initialLocation: currentIndex == 2);
                        },
                      ),

                      // 5. Settings
                      _SideNavItem(
                        icon: Icons.settings_rounded,
                        label: 'Settings',
                        isSelected: false,
                        isDark: isDark,
                        themeType: themeType,
                        onTap: () {
                          ScaffoldMessenger.of(context).clearSnackBars();
                          context.push(AppRoutes.settings);
                        },
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isDark;
  final ThemeType themeType;
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.themeType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color activeColor;
    if (themeType == ThemeType.highContrast) {
      activeColor = AppColors.hcPrimary;
    } else if (themeType == ThemeType.colorBlindSafe) {
      activeColor = const Color(0xFF0077BB);
    } else if (isDark) {
      activeColor = const Color(0xFF38BDF8);
    } else {
      activeColor = const Color(0xFF0062FF);
    }

    final inactiveColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    return Semantics(
      label: label,
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 23,
                color: isSelected ? activeColor : inactiveColor,
              ),
              const SizedBox(height: 3),
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                      color: isSelected ? activeColor : inactiveColor,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 20,
                height: 2,
                decoration: BoxDecoration(
                  color: isSelected ? activeColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SideNavItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final bool isDark;
  final ThemeType themeType;
  final VoidCallback onTap;

  const _SideNavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.themeType,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    Color activeColor;
    if (themeType == ThemeType.highContrast) {
      activeColor = AppColors.hcPrimary;
    } else if (themeType == ThemeType.colorBlindSafe) {
      activeColor = const Color(0xFF0077BB);
    } else if (isDark) {
      activeColor = const Color(0xFF38BDF8);
    } else {
      activeColor = const Color(0xFF0062FF);
    }

    final inactiveColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    return Semantics(
      label: label,
      selected: isSelected,
      button: true,
      child: InkWell(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        borderRadius: BorderRadius.circular(16),
        child: Container(
          width: 72,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                size: 23,
                color: isSelected ? activeColor : inactiveColor,
              ),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                    color: isSelected ? activeColor : inactiveColor,
                  ),
                ),
              ),
              const SizedBox(height: 2),
              Container(
                width: 20,
                height: 2,
                decoration: BoxDecoration(
                  color: isSelected ? activeColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
