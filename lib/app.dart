import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/theme_provider.dart';
import 'providers/audio_providers.dart';
import 'providers/service_providers.dart';

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
    });
  }

  void _handleWidgetUri(Uri uri) {
    final router = ref.read(appRouterProvider);
    final target = uri.host.isNotEmpty ? uri.host : uri.path.replaceAll('/', '');

    switch (target) {
      case 'quick-scan':
        router.push(AppRoutes.quickScan);
        break;
      case 'history':
        router.push(AppRoutes.history);
        break;
      case 'stats':
        router.push(AppRoutes.stats);
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

