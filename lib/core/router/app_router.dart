import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/alert_event.dart';
import '../../ui/onboarding/onboarding_screen.dart';
import '../../ui/home/home_screen.dart';
import '../../ui/history/history_screen.dart';
import '../../ui/stats/stats_screen.dart';
import '../../ui/settings/settings_screen.dart';
import '../../ui/settings/sound_management_screen.dart';
import '../../ui/settings/profile_editor_screen.dart';
import '../../ui/settings/vibration_designer_screen.dart';
import '../../ui/settings/sensitivity_screen.dart';
import '../../ui/settings/emergency_contacts_screen.dart';
import '../../ui/quick_scan/quick_scan_screen.dart';
import '../../ui/alert/alert_details_screen.dart';
import '../../ui/sleep/sleep_mode_screen.dart';
import '../../ui/alert/full_screen_alert.dart';
import '../../ui/shared/app_scaffold.dart';
import '../../ui/widget/home_widget_showcase_screen.dart';

// Route paths
class AppRoutes {
  static const onboarding = '/onboarding';
  static const home = '/home';
  static const history = '/history';
  static const stats = '/stats';
  static const quickScan = '/quick-scan';
  static const alertDetails = '/alert-details';
  static const settings = '/settings';
  static const settingsHistory = '/settings/history';
  static const soundManagement = '/settings/sounds';
  static const profileEditor = '/settings/profiles';
  static const vibrationDesigner = '/settings/vibration';
  static const sensitivity = '/settings/sensitivity';
  static const emergencyContacts = '/settings/emergency-contacts';
  static const widgetShowcase = '/settings/widget';
  static const sleepMode = '/sleep';
  static const fullScreenAlert = '/alert';
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: AppRoutes.home,
    routes: [
      // Onboarding
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (context, state) => const OnboardingScreen(),
      ),

      // Main shell with bottom navigation
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppScaffold(navigationShell: navigationShell);
        },
        branches: [
          // Home tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.home,
                builder: (context, state) => const HomeScreen(),
              ),
            ],
          ),
          // Stats tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.stats,
                builder: (context, state) => const StatsScreen(),
              ),
            ],
          ),
          // History tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: AppRoutes.history,
                builder: (context, state) => const HistoryScreen(),
              ),
            ],
          ),
        ],
      ),

      // Quick Scan (dedicated full screen)
      GoRoute(
        path: AppRoutes.quickScan,
        builder: (context, state) => const QuickScanScreen(),
      ),

      // Alert Details (dedicated full screen)
      GoRoute(
        path: AppRoutes.alertDetails,
        builder: (context, state) {
          final alert = state.extra as AlertEvent?;
          if (alert == null) {
            return const HistoryScreen();
          }
          return AlertDetailsScreen(alert: alert);
        },
      ),

      // Settings (full screen)
      GoRoute(
        path: AppRoutes.settings,
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: AppRoutes.settingsHistory,
        builder: (context, state) => const HistoryScreen(),
      ),
      GoRoute(
        path: AppRoutes.soundManagement,
        builder: (context, state) => const SoundManagementScreen(),
      ),
      GoRoute(
        path: AppRoutes.profileEditor,
        builder: (context, state) => const ProfileEditorScreen(),
      ),
      GoRoute(
        path: AppRoutes.vibrationDesigner,
        builder: (context, state) => const VibrationDesignerScreen(),
      ),
      GoRoute(
        path: AppRoutes.sensitivity,
        builder: (context, state) => const SensitivityScreen(),
      ),
      GoRoute(
        path: AppRoutes.emergencyContacts,
        builder: (context, state) => const EmergencyContactsScreen(),
      ),
      GoRoute(
        path: AppRoutes.widgetShowcase,
        builder: (context, state) => const HomeWidgetShowcaseScreen(),
      ),

      // Sleep mode (full screen)
      GoRoute(
        path: AppRoutes.sleepMode,
        builder: (context, state) => const SleepModeScreen(),
      ),

      // Full-screen alert overlay
      GoRoute(
        path: AppRoutes.fullScreenAlert,
        builder: (context, state) {
          final alertData = state.extra as Map<String, dynamic>?;
          return FullScreenAlert(alertData: alertData ?? {});
        },
      ),
    ],
  );
});
