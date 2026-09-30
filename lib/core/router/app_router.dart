import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../data/models/alert_event.dart';
import '../../main.dart';
import '../../providers/auth_providers.dart';
import '../../providers/settings_providers.dart';
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
import '../../ui/splash/splash_screen.dart';
import '../../ui/auth/login_screen.dart';
import '../../ui/auth/signup_screen.dart';
import '../../ui/auth/forgot_password_screen.dart';
import '../../ui/auth/reset_password_screen.dart';
import '../../ui/auth/email_verification_screen.dart';

// Route paths
class AppRoutes {
  static const splash = '/splash';
  static const onboarding = '/onboarding';
  static const login = '/login';
  static const signup = '/signup';
  static const forgotPassword = '/forgot-password';
  static const resetPassword = '/reset-password';
  static const verifyEmail = '/verify-email';
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
  bool checkOnboardingComplete() {
    try {
      final userSettings = ref.read(userSettingsProvider);
      final localStorage = ref.read(localStorageProvider);
      return userSettings.onboardingCompleted || localStorage.isOnboardingComplete();
    } catch (_) {
      try {
        final userSettings = ref.read(userSettingsProvider);
        return userSettings.onboardingCompleted;
      } catch (_) {
        return false;
      }
    }
  }

  bool checkAuthenticated() {
    try {
      return ref.read(isAuthenticatedProvider);
    } catch (_) {
      try {
        final authRepo = ref.read(authRepositoryProvider);
        return authRepo.isAuthenticated;
      } catch (_) {
        return false;
      }
    }
  }

  final initialOnboarding = checkOnboardingComplete();
  final redirectNotifier = ref.watch(authRedirectListenableProvider);

  return GoRouter(
    initialLocation: initialOnboarding ? AppRoutes.home : AppRoutes.splash,
    refreshListenable: redirectNotifier,
    errorBuilder: (context, state) {
      return const HomeScreen();
    },
    redirect: (context, state) {
      final uri = state.uri;
      final path = uri.path;
      final host = uri.host;
      final isOnboardingComplete = checkOnboardingComplete();
      final isAuthenticated = checkAuthenticated();

      // Guard: If authenticated, redirect away from login/signup/forgot-password to /home
      if (isAuthenticated &&
          (path == AppRoutes.login ||
              path == AppRoutes.signup ||
              path == AppRoutes.forgotPassword)) {
        return AppRoutes.home;
      }

      // Guard: If onboarding completed, redirect /onboarding access
      if (isOnboardingComplete &&
          (path == AppRoutes.onboarding || path == '/onboarding' || host == 'onboarding')) {
        return isAuthenticated ? AppRoutes.home : AppRoutes.login;
      }

      // Handle root '/' or empty path with custom scheme host
      if (path == '/' || path.isEmpty) {
        if (host.isNotEmpty) {
          switch (host) {
            case 'login':
              return AppRoutes.login;
            case 'signup':
              return AppRoutes.signup;
            case 'auth-callback':
            case 'login-callback':
              final type = uri.queryParameters['type'];
              if (type == 'recovery') {
                return AppRoutes.resetPassword;
              }
              return isAuthenticated ? AppRoutes.home : AppRoutes.login;
            case 'quick-scan':
              return '${AppRoutes.quickScan}?autoStart=true';
            case 'emergency':
              return AppRoutes.emergencyContacts;
            case 'sleep':
              return AppRoutes.sleepMode;
            case 'settings':
              return AppRoutes.settings;
            case 'history':
              return AppRoutes.history;
            case 'stats':
              return AppRoutes.stats;
            case 'onboarding':
              return isOnboardingComplete
                  ? (isAuthenticated ? AppRoutes.home : AppRoutes.login)
                  : AppRoutes.onboarding;
            case 'home':
            case 'toggle-listening':
            default:
              return isOnboardingComplete ? AppRoutes.home : AppRoutes.splash;
          }
        }
        return isOnboardingComplete ? AppRoutes.home : AppRoutes.splash;
      }

      // Handle path-based aliases from deep links
      if (path == '/emergency') {
        return AppRoutes.emergencyContacts;
      }
      if (path == '/toggle-listening') {
        return AppRoutes.home;
      }
      if (path == '/auth-callback' || path == '/login-callback') {
        final type = uri.queryParameters['type'];
        if (type == 'recovery') {
          return AppRoutes.resetPassword;
        }
        return isAuthenticated ? AppRoutes.home : AppRoutes.login;
      }

      return null;
    },
    routes: [
      // Root route redirect to home for onboarded users, splash for cold new launches
      GoRoute(
        path: '/',
        redirect: (context, state) =>
            checkOnboardingComplete() ? AppRoutes.home : AppRoutes.splash,
      ),

      // Splash screen
      GoRoute(
        path: AppRoutes.splash,
        builder: (context, state) => const SplashScreen(),
      ),

      // Authentication Routes
      GoRoute(
        path: AppRoutes.login,
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: AppRoutes.signup,
        builder: (context, state) => const SignupScreen(),
      ),
      GoRoute(
        path: AppRoutes.forgotPassword,
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.resetPassword,
        builder: (context, state) => const ResetPasswordScreen(),
      ),
      GoRoute(
        path: AppRoutes.verifyEmail,
        builder: (context, state) {
          final email = state.uri.queryParameters['email'] ?? '';
          return EmailVerificationScreen(email: email);
        },
      ),

      // Aliases for deep links
      GoRoute(
        path: '/emergency',
        redirect: (context, state) => AppRoutes.emergencyContacts,
      ),
      GoRoute(
        path: '/toggle-listening',
        redirect: (context, state) => AppRoutes.home,
      ),

      // Onboarding
      GoRoute(
        path: AppRoutes.onboarding,
        redirect: (context, state) =>
            checkOnboardingComplete() ? AppRoutes.home : null,
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
        builder: (context, state) {
          final autoStart = state.uri.queryParameters['autoStart'] == 'true';
          return QuickScanScreen(autoStart: autoStart);
        },
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
