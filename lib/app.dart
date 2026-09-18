import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/router/app_router.dart';
import 'core/theme/theme_provider.dart';

class AlertSenseApp extends ConsumerWidget {
  const AlertSenseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
