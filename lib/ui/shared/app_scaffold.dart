import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import '../../core/router/app_router.dart';
import '../../data/models/alert_event.dart';
import '../../providers/service_providers.dart';
import 'in_app_notification_banner.dart';

class AppScaffold extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const AppScaffold({super.key, required this.navigationShell});

  @override
  ConsumerState<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends ConsumerState<AppScaffold> {
  StreamSubscription? _urgentSub;
  StreamSubscription? _allAlertsSub;
  AlertEvent? _activeBannerAlert;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _subscribeToAlerts());
  }

  void _subscribeToAlerts() {
    final dispatcher = ref.read(alertDispatcherServiceProvider);

    // 1. High-priority full-screen overlay for critical alarms
    _urgentSub = dispatcher.urgentAlertStream.listen((alert) {
      if (!mounted) return;

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
    _urgentSub?.cancel();
    _allAlertsSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return WithForegroundTask(
      child: Scaffold(
        body: Stack(
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
        ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0D1424) : Colors.white,
          boxShadow: [
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
                _NavItem(
                  icon: Icons.home_rounded,
                  label: 'Home',
                  isSelected: currentIndex == 0,
                  isDark: isDark,
                  onTap: () {
                    widget.navigationShell.goBranch(0, initialLocation: currentIndex == 0);
                  },
                ),

                // 2. Insights
                _NavItem(
                  icon: Icons.bar_chart_rounded,
                  label: 'Insights',
                  isSelected: currentIndex == 1,
                  isDark: isDark,
                  onTap: () {
                    widget.navigationShell.goBranch(1, initialLocation: currentIndex == 1);
                  },
                ),

                // 3. Elevated Quick Scan (Center)
                GestureDetector(
                  onTap: () => context.push(AppRoutes.quickScan),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0072FF), Color(0xFF00C6FF)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF0072FF).withValues(alpha: 0.45),
                              blurRadius: 12,
                              spreadRadius: 1,
                              offset: const Offset(0, 3),
                            ),
                          ],
                        ),
                        child: const Center(
                          child: Icon(
                            Icons.graphic_eq_rounded,
                            color: Colors.white,
                            size: 24,
                          ),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Quick Scan',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white70 : const Color(0xFF334155),
                        ),
                      ),
                    ],
                  ),
                ),

                // 4. History
                _NavItem(
                  icon: Icons.history_rounded,
                  label: 'History',
                  isSelected: currentIndex == 2,
                  isDark: isDark,
                  onTap: () {
                    widget.navigationShell.goBranch(2, initialLocation: currentIndex == 2);
                  },
                ),

                // 5. Settings
                _NavItem(
                  icon: Icons.settings_rounded,
                  label: 'Settings',
                  isSelected: false,
                  isDark: isDark,
                  onTap: () => context.push(AppRoutes.settings),
                ),
              ],
            ),
          ),
        ),
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
  final VoidCallback onTap;

  const _NavItem({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    const activeColor = Color(0xFF0055D4);
    final inactiveColor = isDark ? Colors.white60 : const Color(0xFF64748B);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
              ),
            ),
            const SizedBox(height: 2),
            Container(
              width: 20,
              height: 2,
              decoration: BoxDecoration(
                color: isSelected ? activeColor : Colors.transparent,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
