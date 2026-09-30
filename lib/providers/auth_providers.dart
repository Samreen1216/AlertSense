import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/datasources/supabase_auth_datasource.dart';
import '../data/models/user_profile.dart';
import '../data/repositories/auth_repository.dart';

/// Provider for the Supabase Auth data source.
final authDataSourceProvider = Provider<ISupabaseAuthDataSource>((ref) {
  return SupabaseAuthDataSource();
});

/// Provider for the AuthRepository.
final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dataSource = ref.watch(authDataSourceProvider);
  return AuthRepository(dataSource);
});

/// Stream of Supabase AuthState events (signedIn, signedOut, passwordRecovery, tokenRefreshed, etc.).
final authStateStreamProvider = StreamProvider<AuthState>((ref) {
  final repository = ref.watch(authRepositoryProvider);
  return repository.authStateChanges;
});

/// Currently authenticated Supabase User (or null if signed out).
final currentUserProvider = Provider<User?>((ref) {
  // Trigger update whenever auth state stream emits
  ref.watch(authStateStreamProvider);
  final repository = ref.watch(authRepositoryProvider);
  return repository.currentUser;
});

/// Whether a user is currently authenticated.
final isAuthenticatedProvider = Provider<bool>((ref) {
  final user = ref.watch(currentUserProvider);
  return user != null;
});

/// Provider for the current user's profile from the `profiles` table.
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  if (user == null) return null;
  final repo = ref.watch(authRepositoryProvider);
  return await repo.getProfile(user.id);
});

/// Listenable that alerts GoRouter whenever authentication status shifts.
class AuthRedirectNotifier extends ChangeNotifier {
  final Ref _ref;
  StreamSubscription<AuthState>? _sub;

  AuthRedirectNotifier(this._ref) {
    final repo = _ref.read(authRepositoryProvider);
    _sub = repo.authStateChanges.listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}

final authRedirectListenableProvider = Provider<AuthRedirectNotifier>((ref) {
  final notifier = AuthRedirectNotifier(ref);
  ref.onDispose(() => notifier.dispose());
  return notifier;
});

/// State of an active asynchronous auth action (Login, Signup, Reset Password, etc.)
class AuthActionState {
  final bool isLoading;
  final String? errorMessage;
  final String? successMessage;

  const AuthActionState({
    this.isLoading = false,
    this.errorMessage,
    this.successMessage,
  });

  AuthActionState copyWith({
    bool? isLoading,
    String? errorMessage,
    String? successMessage,
    bool clearError = false,
    bool clearSuccess = false,
  }) {
    return AuthActionState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      successMessage: clearSuccess ? null : (successMessage ?? this.successMessage),
    );
  }
}

/// State notifier managing auth actions with loading, error, and feedback states.
class AuthController extends StateNotifier<AuthActionState> {
  final AuthRepository _repository;

  AuthController(this._repository) : super(const AuthActionState());

  void clearMessages() {
    state = const AuthActionState();
  }

  /// Sign In with Email & Password.
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await _repository.signIn(email: email, password: password);
      state = state.copyWith(isLoading: false, successMessage: 'Welcome back to AlertSense!');
      return true;
    } on AuthFailure catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'An unexpected error occurred during login. Please try again.',
      );
      return false;
    }
  }

  /// Sign Up with Email, Password & Full Name.
  Future<bool> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final response = await _repository.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      final hasSession = response.session != null;
      state = state.copyWith(
        isLoading: false,
        successMessage: hasSession
            ? 'Account created successfully!'
            : 'Account created! Please check your email to verify your address.',
      );
      return true;
    } on AuthFailure catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to create account. Please try again.',
      );
      return false;
    }
  }

  /// Send password reset link to email.
  Future<bool> sendPasswordResetEmail(String email) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await _repository.sendPasswordResetEmail(email);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Password reset link sent! Check your email inbox.',
      );
      return true;
    } on AuthFailure catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to send reset link. Please try again.',
      );
      return false;
    }
  }

  /// Update password for the current recovery session.
  Future<bool> updatePassword(String newPassword) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await _repository.updatePassword(newPassword);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Password successfully updated! You can now log in.',
      );
      return true;
    } on AuthFailure catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Failed to update password. Please try again.',
      );
      return false;
    }
  }

  /// Resend confirmation email.
  Future<bool> resendVerificationEmail(String email) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await _repository.resendVerificationEmail(email);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Verification email resent! Please check your inbox.',
      );
      return true;
    } on AuthFailure catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Could not resend email. Please try again later.',
      );
      return false;
    }
  }

  /// Sign out the current user.
  Future<bool> signOut() async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await _repository.signOut();
      state = const AuthActionState();
      return true;
    } on AuthFailure catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to sign out.');
      return false;
    }
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthActionState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  return AuthController(repo);
});
