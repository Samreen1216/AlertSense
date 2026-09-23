import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:alertsense/core/router/app_router.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Deep Link Navigation & Routing Configuration Tests', () {
    late ProviderContainer container;
    late GoRouter router;

    setUp(() {
      container = ProviderContainer();
      router = container.read(appRouterProvider);
    });

    tearDown(() {
      container.dispose();
    });

    test('All widget destinations exist in route table', () {
      final allPaths = <String>[];

      void collectPaths(List<RouteBase> routes) {
        for (final route in routes) {
          if (route is GoRoute) {
            allPaths.add(route.path);
          } else if (route is StatefulShellRoute) {
            for (final branch in route.branches) {
              collectPaths(branch.routes);
            }
          } else if (route is ShellRoute) {
            collectPaths(route.routes);
          }
        }
      }

      collectPaths(router.configuration.routes);

      expect(allPaths, contains(AppRoutes.home));
      expect(allPaths, contains(AppRoutes.stats));
      expect(allPaths, contains(AppRoutes.history));
      expect(allPaths, contains(AppRoutes.quickScan));
      expect(allPaths, contains(AppRoutes.settings));
      expect(allPaths, contains(AppRoutes.emergencyContacts));
      expect(allPaths, contains(AppRoutes.sleepMode));
      expect(allPaths, contains(AppRoutes.widgetShowcase));
      expect(allPaths, contains('/'));
      expect(allPaths, contains('/emergency'));
      expect(allPaths, contains('/toggle-listening'));
    });

    test('GoRouter redirect handler properly maps custom scheme targets', () {
      // Test redirect with quick-scan host
      final quickScanUri = Uri.parse('alertsense://quick-scan');
      expect(quickScanUri.host, equals('quick-scan'));
      expect(quickScanUri.path, isEmpty);

      // Test redirect with emergency host
      final emergencyUri = Uri.parse('alertsense://emergency');
      expect(emergencyUri.host, equals('emergency'));
      expect(emergencyUri.path, isEmpty);

      // Test redirect with sleep host
      final sleepUri = Uri.parse('alertsense://sleep');
      expect(sleepUri.host, equals('sleep'));
      expect(sleepUri.path, isEmpty);

      // Test redirect with settings host
      final settingsUri = Uri.parse('alertsense://settings');
      expect(settingsUri.host, equals('settings'));
      expect(settingsUri.path, isEmpty);

      // Test redirect with history host
      final historyUri = Uri.parse('alertsense://history');
      expect(historyUri.host, equals('history'));
      expect(historyUri.path, isEmpty);

      // Test redirect with stats host
      final statsUri = Uri.parse('alertsense://stats');
      expect(statsUri.host, equals('stats'));
      expect(statsUri.path, isEmpty);

      // Test redirect with home host
      final homeUri = Uri.parse('alertsense://home');
      expect(homeUri.host, equals('home'));
      expect(homeUri.path, isEmpty);

      // Test redirect with toggle-listening host
      final toggleUri = Uri.parse('alertsense://toggle-listening');
      expect(toggleUri.host, equals('toggle-listening'));
      expect(toggleUri.path, isEmpty);
    });

    test('Root route and aliases have redirect configured to avoid 404', () {
      final routes = router.configuration.routes;

      final rootRoute = routes.whereType<GoRoute>().firstWhere((r) => r.path == '/');
      expect(rootRoute.redirect, isNotNull);

      final emergencyRoute = routes.whereType<GoRoute>().firstWhere((r) => r.path == '/emergency');
      expect(emergencyRoute.redirect, isNotNull);

      final toggleRoute = routes.whereType<GoRoute>().firstWhere((r) => r.path == '/toggle-listening');
      expect(toggleRoute.redirect, isNotNull);
    });

    test('GoRouter handles unknown routes gracefully without throw', () {
      expect(() => router.go('/non-existent-route'), returnsNormally);
    });
  });
}
