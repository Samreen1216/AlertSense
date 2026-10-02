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
import 'package:alertsense/core/theme/theme_provider.dart';
import 'package:alertsense/data/models/alert_event.dart';
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

  @override
  Future<void> deleteAccount(String userId) async {
    mockUser = null;
    mockSession = null;
    mockProfile = null;
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
    ThemeType? themeType,
  }) {
    if (authenticated) {
      mockAuthDataSource.mockUser = customUser ??
          const User(
            id: '12345678-abcd-ef01-2345-6789abcdef01',
            appMetadata: {},
            userMetadata: {'full_name': 'John Doe'},
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
        if (themeType != null)
          themeTypeProvider.overrideWith((ref) => ThemeTypeNotifier(prefs)..state = themeType),
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

      // Sound detection profile section is removed from user account sheet as requested
      expect(find.text('SOUND DETECTION PROFILE'), findsNothing);
      expect(find.text('Customize Sound Detection Profiles'), findsNothing);

      // Simple options are present
      expect(find.text('Edit Name'), findsNothing);
      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Delete Account'), findsOneWidget);

      // Account action is visible
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

      const user = User(
        id: 'sam-user-999',
        appMetadata: {},
        userMetadata: {'full_name': 'Samreen Developer'},
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

    testWidgets('Settings screen renders Top Hero Header with centered avatar, user details, active badge, and manage/logout buttons', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp(child: const SettingsScreen()));
      await tester.pumpAndSettle();

      // Top Hero Header contains centered avatar with initials JD
      expect(find.text('JD'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('john@example.com'), findsOneWidget);
      expect(find.text('Active Account Session'), findsOneWidget);
      expect(find.text('Manage Account'), findsOneWidget);
      expect(find.text('Log Out'), findsOneWidget);

      // Verify tapping Manage Account opens UserAccountSheet
      await tester.tap(find.text('Manage Account'));
      await tester.pumpAndSettle();

      expect(find.text('User Account Details'), findsOneWidget);

      // Close sheet
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      // Verify tapping Log Out opens confirmation dialog
      await tester.tap(find.text('Log Out'));
      await tester.pumpAndSettle();

      expect(find.text('Are you sure you want to log out of AlertSense? You will need to sign in again to access your account.'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
    });

    testWidgets('Top Hero Header adapts color topology to High Contrast mode', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp(
        child: const SettingsScreen(),
        themeType: ThemeType.highContrast,
      ));
      await tester.pumpAndSettle();

      // Ensure Hero Header is rendered in High Contrast mode
      expect(find.text('JD'), findsOneWidget);
      expect(find.text('John Doe'), findsOneWidget);
      expect(find.text('Active Account Session'), findsOneWidget);
      expect(find.text('Manage Account'), findsOneWidget);
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

    testWidgets('UserAccountSheet shows simple options (Change Password, Reset Password, Delete Account once) and removes sound profiles and edit name tile', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(createTestApp(child: const SettingsScreen()));
      await tester.pumpAndSettle();

      // Open UserAccountSheet via Manage Account
      await tester.tap(find.text('Manage Account'));
      await tester.pumpAndSettle();

      // Verify "App Settings & Preferences" is REMOVED
      expect(find.text('App Settings & Preferences'), findsNothing);

      // Verify "SOUND DETECTION PROFILE" section is REMOVED
      expect(find.text('SOUND DETECTION PROFILE'), findsNothing);
      expect(find.text('Customize Sound Detection Profiles'), findsNothing);

      // Verify "Edit Name" tile is REMOVED
      expect(find.text('Edit Name'), findsNothing);

      // Verify simple options are present
      expect(find.text('Change Password'), findsOneWidget);
      expect(find.text('Reset Password'), findsOneWidget);

      // Verify "Delete Account" is present EXACTLY ONCE (no duplicate!)
      expect(find.text('Delete Account'), findsOneWidget);

      // Test tapping Change Password opens Change Password dialog
      await tester.tap(find.text('Change Password'));
      await tester.pumpAndSettle();

      expect(find.text('New Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);

      // Cancel dialog
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // Close sheet
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();
    });

    testWidgets('Delete Account confirmation dialog displays options, enforces safeguard checkbox, and executes deletion', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      // Seed local storage with user auth data
      await storage.saveUserAuthDetails(
        email: 'john@example.com',
        fullName: 'John Doe',
        userId: '12345678-abcd-ef01-2345-6789abcdef01',
      );
      // Seed an alert event to test wiping
      await alertRepo.addAlert(
        AlertEvent(
          id: 'alert-to-wipe',
          soundCategory: 'Smoke Alarm',
          confidence: 0.95,
          priorityLevel: 'Critical',
          timestamp: DateTime.now(),
        ),
      );
      expect(alertRepo.getAll().length, 1);

      await tester.pumpWidget(createTestApp(child: const SettingsScreen()));
      await tester.pumpAndSettle();

      // Open UserAccountSheet
      await tester.tap(find.text('Manage Account'));
      await tester.pumpAndSettle();

      // Tap Delete Account option (scroll into view if needed)
      final deleteTileFinder = find.text('Delete Account');
      await tester.ensureVisible(deleteTileFinder);
      await tester.pumpAndSettle();
      await tester.tap(deleteTileFinder);
      await tester.pumpAndSettle();

      // Dialog should be visible
      expect(find.byType(AlertDialog), findsOneWidget);
      expect(find.text('Delete Account'), findsWidgets);
      expect(find.text('This action is permanent and irreversible. Once deleted, your account and associated personal data cannot be recovered.'), findsOneWidget);
      expect(find.text('Wipe all recorded alert logs & notification history'), findsOneWidget);
      expect(find.text('I understand that my account will be permanently deleted and cannot be undone.'), findsOneWidget);

      // Confirm button inside dialog
      final deleteDialogButton = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.byType(FilledButton),
      );
      expect(deleteDialogButton, findsOneWidget);

      // Verify button is disabled when confirmation checkbox is unchecked
      final filledBtn = tester.widget<FilledButton>(deleteDialogButton);
      expect(filledBtn.onPressed, isNull);

      // Check the confirmation checkbox
      await tester.tap(find.text('I understand that my account will be permanently deleted and cannot be undone.'));
      await tester.pumpAndSettle();

      // Now the button should be enabled
      final enabledBtn = tester.widget<FilledButton>(deleteDialogButton);
      expect(enabledBtn.onPressed, isNotNull);

      // Tap the enabled Delete Account button
      await tester.tap(deleteDialogButton);
      await tester.pumpAndSettle();

      // Dialog is dismissed
      expect(find.byType(AlertDialog), findsNothing);

      // SnackBar confirmation is displayed
      expect(find.text('Your account and data have been permanently deleted.'), findsOneWidget);

      // Local storage auth details wiped
      expect(storage.getSavedUserEmail(), isNull);
      expect(storage.getSavedUserFullName(), isNull);
      expect(storage.getSavedUserId(), isNull);

      // Alert history wiped
      expect(alertRepo.getAll().isEmpty, isTrue);
    });
  });
}
