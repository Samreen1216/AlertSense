import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;
import 'package:alertsense/data/datasources/local_storage.dart';
import 'package:alertsense/data/datasources/supabase_auth_datasource.dart';
import 'package:alertsense/data/models/user_profile.dart';
import 'package:alertsense/data/repositories/alert_repository.dart';
import 'package:alertsense/data/repositories/auth_repository.dart';
import 'package:alertsense/data/repositories/settings_repository.dart';
import 'package:alertsense/main.dart';
import 'package:alertsense/providers/auth_providers.dart';
import 'package:alertsense/providers/service_providers.dart';
import 'package:alertsense/core/router/app_router.dart';
import 'package:alertsense/data/models/alert_event.dart';
import 'package:alertsense/providers/alert_providers.dart';
import 'package:alertsense/services/notification_service.dart';
import 'package:alertsense/ui/home/widgets/alertsense_header.dart';
import 'package:alertsense/ui/home/widgets/notification_center_sheet.dart';
import 'package:alertsense/ui/home/widgets/user_account_sheet.dart';
import 'package:alertsense/ui/settings/settings_screen.dart';

class _MockNotificationService extends NotificationService {}

class _MockSupabaseAuthDataSource implements ISupabaseAuthDataSource {
  User? mockUser;
  Session? mockSession;
  UserProfile? mockProfile;
  final StreamController<AuthState> authStateController =
      StreamController<AuthState>.broadcast();

  @override
  User? get currentUser => mockUser;

  @override
  Session? get currentSession => mockSession;

  @override
  Stream<AuthState> get onAuthStateChange => authStateController.stream;

  @override
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return AuthResponse(session: mockSession, user: mockUser);
  }

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    return AuthResponse(session: mockSession, user: mockUser);
  }

  @override
  Future<void> signOut() async {}

  @override
  Future<void> resetPasswordForEmail(String email) async {}

  @override
  Future<UserResponse> updateUserPassword(String newPassword) async {
    return UserResponse.fromJson({'user': null});
  }

  @override
  Future<void> resendVerificationEmail(String email) async {}

  @override
  Future<UserProfile?> fetchProfile(String userId) async {
    return mockProfile;
  }

  @override
  Future<void> upsertProfile(UserProfile profile) async {
    mockProfile = profile;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late LocalStorage storage;
  late AlertRepository alertRepo;
  late SettingsRepository settingsRepo;
  late _MockSupabaseAuthDataSource mockAuthDataSource;
  late AuthRepository authRepo;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    storage = LocalStorage(prefs);
    alertRepo = AlertRepository(storage);
    await alertRepo.init();
    settingsRepo = SettingsRepository(storage);
    await settingsRepo.init();

    mockAuthDataSource = _MockSupabaseAuthDataSource();
    mockAuthDataSource.mockProfile = UserProfile(
      id: '12345678-abcd-ef01-2345-6789abcdef01',
      fullName: 'John Doe',
      email: 'john@example.com',
      createdAt: DateTime(2026, 1, 15),
      updatedAt: DateTime(2026, 1, 15),
    );
    authRepo = AuthRepository(mockAuthDataSource);
  });

  Widget createTestApp({
    required Widget child,
    bool authenticated = true,
    User? customUser,
  }) {
    if (authenticated) {
      mockAuthDataSource.mockUser = customUser ??
          User(
            id: '12345678-abcd-ef01-2345-6789abcdef01',
            appMetadata: const {},
            userMetadata: const {'full_name': 'John Doe'},
            aud: 'authenticated',
            createdAt: '2026-01-15T12:00:00.000Z',
            email: 'john@example.com',
          );
    } else {
      mockAuthDataSource.mockUser = null;
    }

    return ProviderScope(
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        localStorageProvider.overrideWithValue(storage),
        alertRepositoryProvider.overrideWithValue(alertRepo),
        settingsRepositoryProvider.overrideWithValue(settingsRepo),
        notificationServiceProvider.overrideWithValue(_MockNotificationService()),
        authDataSourceProvider.overrideWithValue(mockAuthDataSource),
        authRepositoryProvider.overrideWithValue(authRepo),
      ],
      child: MaterialApp(
        home: Scaffold(
          body: child,
        ),
      ),
    );
  }

  group('AlertSenseHeader & User Account Profile Tests', () {
    testWidgets('Header renders branding and notification icon to the right of profile avatar, with no settings gear', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp(child: const AlertSenseHeader()));
      await tester.pumpAndSettle();

      // Verify Brand Title and Subtitle
      expect(find.text('AlertSense'), findsOneWidget);
      expect(find.text('See • Feel • Stay Safe'), findsOneWidget);

      // Verify Settings gear icon is NOT present in the header
      expect(find.byIcon(Icons.settings_rounded), findsNothing);

      // Verify User Initials (JD for John Doe) appear on profile avatar
      expect(find.text('JD'), findsOneWidget);

      // Verify Notification icon is present
      expect(find.byIcon(Icons.notifications_rounded), findsOneWidget);

      // Verify spatial placement: Notification icon is to the right of the profile avatar
      final notificationCenter = tester.getCenter(find.byIcon(Icons.notifications_rounded));
      final profileCenter = tester.getCenter(find.text('JD'));
      expect(notificationCenter.dx, greaterThan(profileCenter.dx));
    });

    testWidgets('Guest session renders default person icon and notification icon in header', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp(
        child: const AlertSenseHeader(),
        authenticated: false,
      ));
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.person_rounded), findsOneWidget);
      expect(find.byIcon(Icons.notifications_rounded), findsOneWidget);
      expect(find.byIcon(Icons.settings_rounded), findsNothing);
    });

    testWidgets('Tapping notification icon opens NotificationCenterSheet with all controls', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Add a test alert event
      final alert = AlertEvent(
        id: 'test-fire-1',
        soundCategory: 'Fire Alarm',
        confidence: 0.96,
        priorityLevel: 'High',
        timestamp: DateTime.now(),
        acknowledged: false,
      );
      await alertRepo.addAlert(alert);

      await tester.pumpWidget(createTestApp(child: const AlertSenseHeader()));
      await tester.pumpAndSettle();

      // Unread badge should show '1'
      expect(find.text('1'), findsOneWidget);
      expect(find.byIcon(Icons.notifications_active_rounded), findsOneWidget);

      // Tap on the notification icon
      await tester.tap(find.byIcon(Icons.notifications_active_rounded));
      await tester.pumpAndSettle();

      // Notification Center Sheet should open
      expect(find.byType(NotificationCenterSheet), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('1 new'), findsOneWidget);
      expect(find.text('Fire Alarm'), findsOneWidget);

      // Verify "View Full Alert History" is removed from notification center
      expect(find.text('View Full Alert History'), findsNothing);

      // Verify swipe card notification for delete
      await tester.drag(find.text('Fire Alarm'), const Offset(-600.0, 0.0));
      await tester.pumpAndSettle();

      // Card is deleted and empty state appears
      expect(find.text('Fire Alarm'), findsNothing);
      expect(find.text('No Notifications Yet'), findsOneWidget);
    });

    testWidgets('Tapping profile avatar opens UserAccountSheet with user details', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp(child: const AlertSenseHeader()));
      await tester.pumpAndSettle();

      // Tap on the profile avatar
      await tester.tap(find.text('JD'));
      await tester.pumpAndSettle();

      // Sheet should be opened
      expect(find.byType(UserAccountSheet), findsOneWidget);
      expect(find.text('User Account Details'), findsOneWidget);
      expect(find.text('John Doe'), findsWidgets);
      expect(find.text('john@example.com'), findsWidgets);
      expect(find.text('Authenticated Account'), findsOneWidget);

      // Sound detection profile integration is preserved
      expect(find.text('SOUND DETECTION PROFILE'), findsOneWidget);
      expect(find.text('Customize Sound Detection Profiles'), findsOneWidget);

      // Account actions are visible
      expect(find.text('Log Out of AlertSense'), findsOneWidget);
    });

    testWidgets('Exact name and email from LocalStorage cache are shown when user logs in', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await storage.saveUserAuthDetails(
        email: 'samreen@alertsense.com',
        fullName: 'Samreen Developer',
        userId: 'sam-user-999',
      );

      final user = User(
        id: 'sam-user-999',
        appMetadata: const {},
        userMetadata: const {'full_name': 'Samreen Developer'},
        aud: 'authenticated',
        createdAt: '2026-02-01T12:00:00.000Z',
        email: 'samreen@alertsense.com',
      );
      mockAuthDataSource.mockProfile = null; // Test fallback to LocalStorage and userMetadata

      await tester.pumpWidget(createTestApp(
        child: const AlertSenseHeader(),
        customUser: user,
      ));
      await tester.pumpAndSettle();

      // Header avatar should show initials 'SD' for 'Samreen Developer'
      expect(find.text('SD'), findsOneWidget);

      // Open User Account Sheet
      await tester.tap(find.text('SD'));
      await tester.pumpAndSettle();

      // Sheet must display exact full name and exact login email
      expect(find.text('Samreen Developer'), findsWidgets);
      expect(find.text('samreen@alertsense.com'), findsWidgets);
    });

    testWidgets('Settings screen contains Sound Profiles under Section 1', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp(child: const SettingsScreen()));
      await tester.pumpAndSettle();

      // Check for Sound Profiles under Section 1
      expect(find.text('Sound Profiles'), findsOneWidget);
      expect(find.text('Configure Home, Sleep, and Outdoor detection modes'), findsOneWidget);
    });

    testWidgets('Cold launch router directs to /splash when unauthenticated even if onboarding complete', (tester) async {
      await storage.setOnboardingComplete();
      // Notice: Not authenticated!
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageProvider.overrideWithValue(storage),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          alertRepositoryProvider.overrideWithValue(alertRepo),
          notificationServiceProvider.overrideWithValue(_MockNotificationService()),
          authDataSourceProvider.overrideWithValue(mockAuthDataSource),
          authRepositoryProvider.overrideWithValue(authRepo),
          isAuthenticatedProvider.overrideWithValue(false),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);
      // Verify initial location is splash
      final initialOnboarding = storage.isOnboardingComplete();
      final initialAuthenticated = container.read(isAuthenticatedProvider);
      expect(initialOnboarding, isTrue);
      expect(initialAuthenticated, isFalse);
      expect(router.routeInformationProvider.value.uri.toString(), AppRoutes.splash);
    });

    testWidgets('Unauthenticated user navigating to /onboarding is allowed without redirection', (tester) async {
      final container = ProviderContainer(
        overrides: [
          sharedPreferencesProvider.overrideWithValue(prefs),
          localStorageProvider.overrideWithValue(storage),
          settingsRepositoryProvider.overrideWithValue(settingsRepo),
          alertRepositoryProvider.overrideWithValue(alertRepo),
          notificationServiceProvider.overrideWithValue(_MockNotificationService()),
          authDataSourceProvider.overrideWithValue(mockAuthDataSource),
          authRepositoryProvider.overrideWithValue(authRepo),
          isAuthenticatedProvider.overrideWithValue(false),
        ],
      );
      addTearDown(container.dispose);

      final router = container.read(appRouterProvider);
      router.go(AppRoutes.onboarding);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp.router(
            routerConfig: router,
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      // Should be on Onboarding route and render OnboardingScreen
      expect(router.routeInformationProvider.value.uri.toString(), AppRoutes.onboarding);
    });
  });
}
