import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/sound_categories.dart';
import '../../core/router/app_router.dart';
import '../../providers/service_providers.dart';

class AppScaffold extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;
  const AppScaffold({super.key, required this.navigationShell});

  @override
  ConsumerState<AppScaffold> createState() => _AppScaffoldState();
}

class _AppScaffoldState extends ConsumerState<AppScaffold> {
  StreamSubscription? _urgentSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _subscribeToUrgentAlerts());
  }

  void _subscribeToUrgentAlerts() {
    final dispatcher = ref.read(alertDispatcherServiceProvider);
    _urgentSub = dispatcher.urgentAlertStream.listen((alert) {
      if (!mounted) return;

      // Resolve emoji from category
      String emoji = '🚨';
      try {
        final cat = SoundCategory.values.firstWhere((c) => c.name == alert.soundCategory);
        emoji = cat.emoji;
      } catch (_) {}

      context.push(AppRoutes.fullScreenAlert, extra: {
        'id': alert.id,
        'soundCategory': alert.soundCategory,
        'emoji': emoji,
        'confidence': (alert.confidence * 100).toStringAsFixed(0),
        'priorityLevel': alert.priorityLevel,
        'timestamp': alert.timestamp,
      });
    });
  }

  @override
  void dispose() {
    _urgentSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: widget.navigationShell.currentIndex,
        onDestinationSelected: (index) {
          widget.navigationShell.goBranch(
            index,
            initialLocation: index == widget.navigationShell.currentIndex,
          );
        },
        height: 72,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
            tooltip: 'Home — Live Sound Monitor',
          ),
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Insights',
            tooltip: 'Insights — Alert Statistics',
          ),
          NavigationDestination(
            icon: Icon(Icons.history_outlined),
            selectedIcon: Icon(Icons.history_rounded),
            label: 'History',
            tooltip: 'History — Past Alerts',
          ),
        ],
      ),
    );
  }
}
