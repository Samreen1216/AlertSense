import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/theme_provider.dart';
import 'data/models/alert_event.dart';
import 'providers/alert_providers.dart';
import 'providers/audio_providers.dart';
import 'providers/service_providers.dart';
import 'providers/settings_providers.dart';
import 'providers/stats_providers.dart';

class AlertSenseApp extends ConsumerStatefulWidget {
  const AlertSenseApp({super.key});

  @override
  ConsumerState<AlertSenseApp> createState() => _AlertSenseAppState();
}

class _AlertSenseAppState extends ConsumerState<AlertSenseApp> {
  StreamSubscription<Uri>? _widgetLaunchSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final widgetService = ref.read(homeWidgetServiceProvider);
      _widgetLaunchSub = widgetService.widgetLaunchStream.listen(_handleWidgetUri);
      
      // Delay consumption of cold-start deep link until GoRouter initial build settles
      Future.delayed(const Duration(milliseconds: 350), () {
        if (mounted) {
          widgetService.consumePendingInitialUri(_handleWidgetUri);
        }
      });
      _syncHomeWidget();
    });
  }

  void _handleWidgetUri(Uri uri) {
    final router = ref.read(appRouterProvider);
    final target = uri.host.isNotEmpty ? uri.host : uri.path.replaceAll('/', '');

    switch (target) {
      case 'quick-scan':
        WidgetsBinding.instance.addPostFrameCallback((_) {
          router.push('${AppRoutes.quickScan}?autoStart=true');
        });
        break;
      case 'history':
        router.go(AppRoutes.history);
        break;
      case 'stats':
        router.go(AppRoutes.stats);
        break;
      case 'sleep':
        router.push(AppRoutes.sleepMode);
        break;
      case 'emergency':
        router.push(AppRoutes.emergencyContacts);
        break;
      case 'settings':
        router.push(AppRoutes.settings);
        break;
      case 'toggle-listening':
        ref.read(isListeningProvider.notifier).toggle();
        break;
      case 'home':
      default:
        router.go(AppRoutes.home);
        break;
    }
  }

  void _syncHomeWidget() {
    try {
      final widgetService = ref.read(homeWidgetServiceProvider);
      final isListening = ref.read(isListeningProvider);
      final profile = ref.read(activeProfileProvider);
      final db = ref.read(ambientDbProvider);
      final todayCount = ref.read(alertsTodayCountProvider);
      final highCount = ref.read(highPriorityCountProvider);
      final lastAlert = ref.read(lastAlertProvider);
      final enabledCount = ref.read(enabledSoundsProvider).length;

      widgetService.syncData(
        isListening: isListening,
        activeProfile: profile,
        ambientDb: db,
        lastAlert: lastAlert,
        alertsTodayCount: todayCount,
        highPriorityCount: highCount,
        monitoredCount: enabledCount,
      );
    } catch (_) {}
  }

  @override
  void dispose() {
    _widgetLaunchSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = ref.watch(themeModeProvider);
    final textScale = ref.watch(textScaleProvider);
    final router = ref.watch(appRouterProvider);

    // Dynamic widget synchronization listeners
    ref.listen<String>(activeProfileProvider, (prev, next) {
      if (prev != next) {
        // Sync the enabled sounds widget count to the new profile
        ref.read(enabledSoundsProvider.notifier).setProfile(next);
        // Clear stale cross-profile sounds from the radar immediately
        ref.read(isListeningProvider.notifier).clearRadar();
        // Update foreground service notification title/status to match new profile
        ref.read(isListeningProvider.notifier).updateForegroundStatus();
        // Persist active profile ID to settings repo
        ref.read(userSettingsProvider.notifier).setActiveProfileId(next);
        _syncHomeWidget();
      }
    });
    ref.listen<List<AlertEvent>>(alertListProvider, (_, __) {
      _syncHomeWidget();
    });
    ref.listen<Set<String>>(enabledSoundsProvider, (_, __) {
      _syncHomeWidget();
    });
    ref.listen<bool>(isListeningProvider, (_, __) {
      _syncHomeWidget();
    });

    return MaterialApp.router(
      title: 'AlertSense',
      debugShowCheckedModeBanner: false,
      theme: theme,
      routerConfig: router,
      builder: (context, child) {
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(textScale),
          ),
          child: child ?? const SizedBox.shrink(),
        );
      },
    );
  }
}
