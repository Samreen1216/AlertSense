import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:alertsense/core/utils/auth_validators.dart';
import 'package:alertsense/data/datasources/supabase_auth_datasource.dart';
import 'package:alertsense/data/models/user_profile.dart';
import 'package:alertsense/data/repositories/auth_repository.dart';
import 'package:alertsense/providers/auth_providers.dart';
import 'package:alertsense/ui/auth/login_screen.dart';
import 'package:alertsense/ui/auth/signup_screen.dart';
import 'package:alertsense/ui/auth/forgot_password_screen.dart';
import 'package:alertsense/ui/auth/reset_password_screen.dart';
import 'package:alertsense/ui/auth/email_verification_screen.dart';
import 'package:alertsense/ui/auth/widgets/auth_primary_button.dart';
import 'package:alertsense/ui/auth/widgets/password_requirements_view.dart';

class _MockSupabaseAuthDataSource implements ISupabaseAuthDataSource {
  User? mockUser;
  Session? mockSession;
  final StreamController<AuthState> authStateController =
      StreamController<AuthState>.broadcast();

  Future<AuthResponse> Function(String email, String password)? onSignIn;
  Future<AuthResponse> Function(String email, String password, String fullName)?
      onSignUp;
  Future<void> Function()? onSignOut;
  Future<void> Function(String email)? onResetPassword;
  Future<UserResponse> Function(String newPassword)? onUpdatePassword;
  Future<void> Function(String email)? onResendVerification;
  Future<UserProfile?> Function(String userId)? onGetProfile;

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
    if (onSignIn != null) {
      return await onSignIn!(email, password);
    }
    return AuthResponse(session: mockSession, user: mockUser);
  }

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    if (onSignUp != null) {
      return await onSignUp!(email, password, fullName);
    }
    return AuthResponse(session: mockSession, user: mockUser);
  }

  @override
  Future<void> signOut() async {
    if (onSignOut != null) await onSignOut!();
  }

  @override
  Future<void> resetPasswordForEmail(String email) async {
    if (onResetPassword != null) await onResetPassword!(email);
  }

  @override
  Future<UserResponse> updateUserPassword(String newPassword) async {
    if (onUpdatePassword != null) return await onUpdatePassword!(newPassword);
    return UserResponse.fromJson({'user': null});
  }

  @override
  Future<void> resendVerificationEmail(String email) async {
    if (onResendVerification != null) await onResendVerification!(email);
  }

  @override
  Future<UserProfile?> fetchProfile(String userId) async {
    if (onGetProfile != null) return await onGetProfile!(userId);
    return null;
  }

  @override
  Future<UserProfile> upsertProfile(UserProfile profile) async {
    return profile;
  }

  Future<void> Function(String userId)? onDeleteAccount;

  @override
  Future<void> deleteAccount(String userId) async {
    if (onDeleteAccount != null) {
      await onDeleteAccount!(userId);
      return;
    }
    mockUser = null;
    mockSession = null;
  }
}

void main() {
  group('AuthValidators Unit Tests', () {
    test('normalizeEmail trims whitespace and converts to lowercase', () {
      expect(AuthValidators.normalizeEmail(null), '');
      expect(AuthValidators.normalizeEmail(''), '');
      expect(AuthValidators.normalizeEmail('   '), '');
      expect(AuthValidators.normalizeEmail('  user@domain.com  '), 'user@domain.com');
      expect(AuthValidators.normalizeEmail('  User.Name@Example.COM  '), 'user.name@example.com');
      expect(AuthValidators.normalizeEmail('ALERTSENSE@TEST.IO'), 'alertsense@test.io');
    });

    test('validateEmail validates format correctly', () {
      expect(AuthValidators.validateEmail(null), 'Email address is required');
      expect(AuthValidators.validateEmail(''), 'Email address is required');
      expect(AuthValidators.validateEmail('   '), 'Email address is required');
      expect(AuthValidators.validateEmail('notanemail'), 'Please enter a valid email address');
      expect(AuthValidators.validateEmail('test@'), 'Please enter a valid email address');
      expect(AuthValidators.validateEmail('test@domain'), 'Please enter a valid email address');
      expect(AuthValidators.validateEmail('@domain.com'), 'Please enter a valid email address');
      expect(AuthValidators.validateEmail('user space@domain.com'), 'Please enter a valid email address');
      expect(AuthValidators.validateEmail('user@domain.com'), isNull);
      expect(AuthValidators.validateEmail('alert.sense+test@sub.example.co'), isNull);
      expect(AuthValidators.validateEmail('   user@domain.com   '), isNull);
    });

    test('validateLoginPassword allows any non-empty password without strength requirements', () {
      expect(AuthValidators.validateLoginPassword(null), 'Password is required');
      expect(AuthValidators.validateLoginPassword(''), 'Password is required');
      expect(AuthValidators.validateLoginPassword('123'), isNull);
      expect(AuthValidators.validateLoginPassword('simple'), isNull);
      expect(AuthValidators.validateLoginPassword('StrongPass1!'), isNull);
    });

    test('validateStrongPassword enforces production password requirements', () {
      expect(AuthValidators.validateStrongPassword(null), 'Password is required');
      expect(AuthValidators.validateStrongPassword(''), 'Password is required');
      // Less than 8 characters
      expect(
        AuthValidators.validateStrongPassword('Pass1!'),
        'Password must be at least 8 characters long',
      );
      // Missing letter
      expect(
        AuthValidators.validateStrongPassword('12345678!@#'),
        'Password must contain at least 1 letter',
      );
      // Missing number
      expect(
        AuthValidators.validateStrongPassword('Password!@#'),
        'Password must contain at least 1 number',
      );
      // Missing special character
      expect(
        AuthValidators.validateStrongPassword('Password123'),
        'Password must contain at least 1 special character',
      );
      // Valid passwords (both uppercase and lowercase letters are acceptable)
      expect(AuthValidators.validateStrongPassword('password123!'), isNull);
      expect(AuthValidators.validateStrongPassword('PASSWORD123!'), isNull);
      expect(AuthValidators.validateStrongPassword('Password123!'), isNull);
      expect(AuthValidators.validateStrongPassword('AlertSense@2026'), isNull);
      expect(AuthValidators.validateStrongPassword('S3cure#Pass_99'), isNull);
    });

    test('validatePassword enforces configurable minimum length', () {
      expect(AuthValidators.validatePassword(null), 'Password is required');
      expect(AuthValidators.validatePassword(''), 'Password is required');
      expect(AuthValidators.validatePassword('12345'), 'Password must be at least 6 characters long');
      expect(AuthValidators.validatePassword('123456'), isNull);
      expect(AuthValidators.validatePassword('secure-password!123'), isNull);
    });

    test('validateConfirmPassword enforces match', () {
      expect(
        AuthValidators.validateConfirmPassword('secret123', null),
        'Please confirm your password',
      );
      expect(
        AuthValidators.validateConfirmPassword('secret123', ''),
        'Please confirm your password',
      );
      expect(
        AuthValidators.validateConfirmPassword('secret123', 'wrongpassword'),
        'Passwords do not match',
      );
      expect(
        AuthValidators.validateConfirmPassword('secret123', 'secret123'),
        isNull,
      );
    });

    test('validateFullName enforces minimum length', () {
      expect(AuthValidators.validateFullName(null), 'Full name is required');
      expect(AuthValidators.validateFullName(''), 'Full name is required');
      expect(AuthValidators.validateFullName('A'), 'Please enter a valid name (at least 2 characters)');
      expect(AuthValidators.validateFullName('AlertSense User'), isNull);
    });
  });

  group('AuthRepository Exception Mapping Unit Tests', () {
    late _MockSupabaseAuthDataSource mockDataSource;
    late AuthRepository authRepo;

    setUp(() {
      mockDataSource = _MockSupabaseAuthDataSource();
      authRepo = AuthRepository(mockDataSource);
    });

    test('maps invalid login credentials', () async {
      mockDataSource.onSignIn = (email, password) async {
        throw const AuthException('Invalid login credentials');
      };

      expect(
        () => authRepo.signIn(email: 'test@example.com', password: 'wrong'),
        throwsA(isA<AuthFailure>().having(
          (e) => e.message,
          'message',
          contains('Incorrect email or password'),
        )),
      );
    });

    test('maps user already registered', () async {
      mockDataSource.onSignUp = (email, password, fullName) async {
        throw const AuthException('User already registered');
      };

      expect(
        () => authRepo.signUp(
          email: 'exists@example.com',
          password: 'password123',
          fullName: 'Test User',
        ),
        throwsA(isA<AuthFailure>().having(
          (e) => e.message,
          'message',
          contains('already exists'),
        )),
      );
    });

    test('maps email not confirmed', () async {
      mockDataSource.onSignIn = (email, password) async {
        throw const AuthException('Email not confirmed');
      };

      expect(
        () => authRepo.signIn(email: 'unconfirmed@example.com', password: 'password'),
        throwsA(isA<AuthFailure>().having(
          (e) => e.message,
          'message',
          contains('has not been verified yet'),
        )),
      );
    });

    test('maps weak password', () async {
      mockDataSource.onSignUp = (email, password, fullName) async {
        throw const AuthException('Password should be at least 6 characters');
      };

      expect(
        () => authRepo.signUp(
          email: 'test@example.com',
          password: '123',
          fullName: 'Test User',
        ),
        throwsA(isA<AuthFailure>().having(
          (e) => e.message,
          'message',
          contains('Password is too weak'),
        )),
      );
    });

    test('maps rate limit error', () async {
      mockDataSource.onResetPassword = (email) async {
        throw const AuthException('over_email_send_rate_limit');
      };

      expect(
        () => authRepo.sendPasswordResetEmail('rate@example.com'),
        throwsA(isA<AuthFailure>().having(
          (e) => e.message,
          'message',
          contains('rate limit reached'),
        )),
      );
    });

    test('maps network connection error', () async {
      mockDataSource.onSignIn = (email, password) async {
        throw const SocketException('Failed host lookup');
      };

      expect(
        () => authRepo.signIn(email: 'test@example.com', password: 'pass'),
        throwsA(isA<AuthFailure>().having(
          (e) => e.message,
          'message',
          contains('Unable to reach AlertSense servers'),
        )),
      );
    });
  });

  group('AuthController State Transition Tests', () {
    late _MockSupabaseAuthDataSource mockDataSource;
    late ProviderContainer container;

    setUp(() {
      mockDataSource = _MockSupabaseAuthDataSource();
      container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(AuthRepository(mockDataSource)),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    test('initial state is unauthenticated and not loading', () {
      final state = container.read(authControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
      expect(state.successMessage, isNull);
    });

    test('signIn success updates state', () async {
      final controller = container.read(authControllerProvider.notifier);
      final success = await controller.signIn(
        email: 'user@example.com',
        password: 'password123',
      );

      expect(success, isTrue);
      final state = container.read(authControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNull);
    });

    test('signIn failure sets user-friendly error message', () async {
      mockDataSource.onSignIn = (email, password) async {
        throw const AuthException('Invalid login credentials');
      };

      final controller = container.read(authControllerProvider.notifier);
      final success = await controller.signIn(
        email: 'user@example.com',
        password: 'wrongpassword',
      );

      expect(success, isFalse);
      final state = container.read(authControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, contains('Incorrect email or password'));
    });

    test('signUp success sets successMessage', () async {
      final controller = container.read(authControllerProvider.notifier);
      final success = await controller.signUp(
        email: 'newuser@example.com',
        password: 'password123',
        fullName: 'New User',
      );

      expect(success, isTrue);
      final state = container.read(authControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.successMessage, contains('verify'));
    });

    test('signOut clears state', () async {
      final controller = container.read(authControllerProvider.notifier);
      await controller.signOut();
      final state = container.read(authControllerProvider);
      expect(state.isLoading, isFalse);
    });
  });

  group('Auth UI Screens Widget Tests', () {
    late _MockSupabaseAuthDataSource mockDataSource;

    setUp(() {
      mockDataSource = _MockSupabaseAuthDataSource();
    });

    testWidgets('LoginScreen renders branding, inputs, and buttons', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(AuthRepository(mockDataSource)),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ALERTSENSE AI'), findsOneWidget);
      expect(find.text('Sign in to access your sound awareness and emergency alerts'), findsOneWidget);
      expect(find.byType(TextFormField), findsNWidgets(2)); // Email & Password
      expect(find.text('Log In'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
      expect(find.text('Create Account'), findsOneWidget);
    });

    testWidgets('LoginScreen shows validation errors when fields are empty', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(AuthRepository(mockDataSource)),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Tap Log In button with empty fields
      final loginBtn = find.widgetWithText(AuthPrimaryButton, 'Log In');
      await tester.ensureVisible(loginBtn);
      await tester.tap(loginBtn);
      await tester.pumpAndSettle();

      expect(find.text('Email address is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('LoginScreen trims and normalizes email before submitting', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      String? submittedEmail;
      String? submittedPassword;
      mockDataSource.onSignIn = (email, password) async {
        submittedEmail = email;
        submittedPassword = password;
        return AuthResponse(session: mockDataSource.mockSession, user: mockDataSource.mockUser);
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(AuthRepository(mockDataSource)),
          ],
          child: const MaterialApp(
            home: LoginScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), '   User.AlertSense@Example.COM   ');
      // Login does not enforce strong password rules (e.g. simple 4-char string is valid)
      await tester.enterText(fields.at(1), 'simple123');

      final loginBtn = find.widgetWithText(AuthPrimaryButton, 'Log In');
      await tester.ensureVisible(loginBtn);
      await tester.tap(loginBtn);
      await tester.pumpAndSettle();

      expect(submittedEmail, 'user.alertsense@example.com');
      expect(submittedPassword, 'simple123');
    });

    testWidgets('SignupScreen renders all required registration fields', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(AuthRepository(mockDataSource)),
          ],
          child: const MaterialApp(
            home: SignupScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('ALERTSENSE AI'), findsOneWidget);
      expect(find.text('Create Account'), findsNWidgets(2)); // Title header & Primary button
      expect(find.byType(TextFormField), findsNWidgets(4)); // Name, Email, Password, Confirm Password
      expect(find.text('Already have an account? '), findsOneWidget);
      expect(find.text('Log In'), findsOneWidget);
    });

    testWidgets('SignupScreen validates strong password requirement', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(AuthRepository(mockDataSource)),
          ],
          child: const MaterialApp(
            home: SignupScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'John Doe');
      await tester.enterText(fields.at(1), 'john@example.com');
      // Password missing special character
      await tester.enterText(fields.at(2), 'Password123');
      await tester.enterText(fields.at(3), 'Password123');

      final createAccountBtn = find.widgetWithText(AuthPrimaryButton, 'Create Account');
      await tester.ensureVisible(createAccountBtn);
      await tester.tap(createAccountBtn);
      await tester.pumpAndSettle();

      expect(find.text('Password must contain at least 1 special character'), findsOneWidget);
    });

    testWidgets('SignupScreen validates password confirmation mismatch', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(AuthRepository(mockDataSource)),
          ],
          child: const MaterialApp(
            home: SignupScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Enter mismatched passwords
      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'John Doe');
      await tester.enterText(fields.at(1), 'john@example.com');
      await tester.enterText(fields.at(2), 'Password123!');
      await tester.enterText(fields.at(3), 'DifferentPassword123!');

      // Tap Create Account
      final createAccountBtn = find.widgetWithText(AuthPrimaryButton, 'Create Account');
      await tester.ensureVisible(createAccountBtn);
      await tester.tap(createAccountBtn);
      await tester.pumpAndSettle();

      expect(find.text('Passwords do not match'), findsOneWidget);
    });

    testWidgets('SignupScreen normalizes email on valid submission', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      String? registeredEmail;
      mockDataSource.onSignUp = (email, password, fullName) async {
        registeredEmail = email;
        return AuthResponse(session: mockDataSource.mockSession, user: mockDataSource.mockUser);
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(AuthRepository(mockDataSource)),
          ],
          child: const MaterialApp(
            home: SignupScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'Jane Doe');
      await tester.enterText(fields.at(1), '   Jane.Doe@AlertSense.IO   ');
      await tester.enterText(fields.at(2), 'SecurePass2026!');
      await tester.enterText(fields.at(3), 'SecurePass2026!');

      final createAccountBtn = find.widgetWithText(AuthPrimaryButton, 'Create Account');
      await tester.ensureVisible(createAccountBtn);
      await tester.tap(createAccountBtn);
      await tester.pumpAndSettle();

      expect(registeredEmail, 'jane.doe@alertsense.io');
    });

    testWidgets('ForgotPasswordScreen renders email field and submit button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(AuthRepository(mockDataSource)),
          ],
          child: const MaterialApp(
            home: ForgotPasswordScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Forgot Password'), findsOneWidget);
      expect(find.text('Send Reset Link'), findsOneWidget);
      expect(find.text('Back to Login'), findsOneWidget);
      expect(find.byType(TextFormField), findsOneWidget);
    });

    testWidgets('ResetPasswordScreen renders password, confirmation, and requirements checklist', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(AuthRepository(mockDataSource)),
          ],
          child: const MaterialApp(
            home: ResetPasswordScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Update Password'), findsNWidgets(2)); // Header brand & Primary button
      expect(find.byType(TextFormField), findsNWidgets(2));
      expect(find.byType(PasswordRequirementsView), findsOneWidget);
      expect(find.text('Back to Login'), findsOneWidget);
    });

    testWidgets('ResetPasswordScreen submits password update successfully', (tester) async {
      tester.view.physicalSize = const Size(800, 1200);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      bool passwordUpdated = false;
      mockDataSource.onUpdatePassword = (newPass) async {
        passwordUpdated = true;
        return UserResponse.fromJson({'user': null});
      };

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(AuthRepository(mockDataSource)),
          ],
          child: const MaterialApp(
            home: ResetPasswordScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final fields = find.byType(TextFormField);
      await tester.enterText(fields.at(0), 'BrandNewPassword123!');
      await tester.enterText(fields.at(1), 'BrandNewPassword123!');

      final updateBtn = find.widgetWithText(AuthPrimaryButton, 'Update Password');
      await tester.ensureVisible(updateBtn);
      await tester.tap(updateBtn);
      await tester.pumpAndSettle();

      expect(passwordUpdated, isTrue);
    });

    testWidgets('PasswordRequirementsView highlights satisfied criteria in real time', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PasswordRequirementsView(password: 'pass1!'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 'pass1!' satisfies: Letters (A-Z / a-z), Numbers (0-9), Special char (!@#$), but NOT 8+ chars
      expect(find.text('8+ chars'), findsOneWidget);
      expect(find.text('Letters (A-Z / a-z)'), findsOneWidget);
      expect(find.text('Numbers (0-9)'), findsOneWidget);
      expect(find.text('Special char (!@#\$)'), findsOneWidget);
      expect(find.text('Password requirements:'), findsOneWidget);

      // Pump with full strong password
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: PasswordRequirementsView(password: 'password123!'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Strong password'), findsOneWidget);
    });

    testWidgets('EmailVerificationScreen renders verification instructions and resend button', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            authRepositoryProvider.overrideWithValue(AuthRepository(mockDataSource)),
          ],
          child: const MaterialApp(
            home: EmailVerificationScreen(email: 'user@example.com'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Verify Your Email'), findsOneWidget);
      expect(find.text('user@example.com'), findsOneWidget);
      expect(find.textContaining('Resend Email'), findsOneWidget);
      expect(find.text('Back to Login'), findsOneWidget);
    });
  });

  group('Password Recovery & Deep Link Routing Tests', () {
    late _MockSupabaseAuthDataSource mockDataSource;

    setUp(() {
      mockDataSource = _MockSupabaseAuthDataSource();
    });

    test('AuthRedirectNotifier activates recovery mode on AuthChangeEvent.passwordRecovery', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(AuthRepository(mockDataSource)),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authRedirectListenableProvider);
      expect(notifier.isPasswordRecovery, isFalse);

      mockDataSource.authStateController.add(
        const AuthState(AuthChangeEvent.passwordRecovery, null),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(notifier.isPasswordRecovery, isTrue);

      notifier.clearPasswordRecovery();
      expect(notifier.isPasswordRecovery, isFalse);
    });

    test('AuthRedirectNotifier clears recovery mode on AuthChangeEvent.signedOut or userUpdated', () async {
      final container = ProviderContainer(
        overrides: [
          authRepositoryProvider.overrideWithValue(AuthRepository(mockDataSource)),
        ],
      );
      addTearDown(container.dispose);

      final notifier = container.read(authRedirectListenableProvider);
      notifier.setPasswordRecovery(true);
      expect(notifier.isPasswordRecovery, isTrue);

      mockDataSource.authStateController.add(
        const AuthState(AuthChangeEvent.userUpdated, null),
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(notifier.isPasswordRecovery, isFalse);
    });
  });
}
