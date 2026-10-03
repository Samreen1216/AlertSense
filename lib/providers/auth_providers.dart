import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart' hide LocalStorage;
import '../data/datasources/local_storage.dart';
import '../data/datasources/supabase_auth_datasource.dart';
import '../data/models/user_profile.dart';
import '../data/repositories/auth_repository.dart';
import '../main.dart';

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
  try {
    final repository = ref.watch(authRepositoryProvider);
    return repository.authStateChanges;
  } catch (_) {
    return const Stream.empty();
  }
});

/// Currently authenticated Supabase User (or null if signed out).
final currentUserProvider = Provider<User?>((ref) {
  try {
    // Trigger update whenever auth state stream emits
    ref.watch(authStateStreamProvider);
    final repository = ref.watch(authRepositoryProvider);
    return repository.currentUser;
  } catch (_) {
    return null;
  }
});

/// Whether a user is currently authenticated.
final isAuthenticatedProvider = Provider<bool>((ref) {
  try {
    final user = ref.watch(currentUserProvider);
    return user != null;
  } catch (_) {
    return false;
  }
});

/// Provider for the current user's profile from the `profiles` table or cached auth details.
final userProfileProvider = FutureProvider<UserProfile?>((ref) async {
  final user = ref.watch(currentUserProvider);
  LocalStorage? storage;
  try {
    storage = ref.read(localStorageProvider);
  } catch (_) {}

  final savedName = storage?.getSavedUserFullName();
  final savedEmail = storage?.getSavedUserEmail();

  if (user == null) {
    if (savedName != null || savedEmail != null) {
      return UserProfile(
        id: storage?.getSavedUserId() ?? 'local_user',
        fullName: savedName ?? '',
        email: savedEmail ?? '',
      );
    }
    return null;
  }

  final repo = ref.watch(authRepositoryProvider);
  UserProfile? profile;
  try {
    profile = await repo.getProfile(user.id);
  } catch (_) {}

  if (profile != null && profile.fullName.trim().isNotEmpty) {
    storage?.saveUserAuthDetails(
      email: profile.email.isNotEmpty ? profile.email : (user.email ?? ''),
      fullName: profile.fullName,
      userId: profile.id,
    );
    return profile;
  }

  // Resolve best full name from userMetadata, local storage, or email prefix
  final fallbackName = (user.userMetadata?['full_name'] as String?)?.trim().isNotEmpty == true
      ? (user.userMetadata!['full_name'] as String).trim()
      : ((user.userMetadata?['name'] as String?)?.trim().isNotEmpty == true
          ? (user.userMetadata!['name'] as String).trim()
          : ((user.userMetadata?['fullName'] as String?)?.trim().isNotEmpty == true
              ? (user.userMetadata!['fullName'] as String).trim()
              : (savedName?.trim().isNotEmpty == true
                  ? savedName!.trim()
                  : (user.email?.split('@').first ?? 'AlertSense User'))));

  final fallbackEmail = (profile?.email.isNotEmpty == true)
      ? profile!.email
      : (user.email ?? savedEmail ?? '');

  final resolvedProfile = UserProfile(
    id: user.id,
    fullName: fallbackName,
    email: fallbackEmail,
    createdAt: user.createdAt.isNotEmpty ? DateTime.tryParse(user.createdAt) : null,
  );

  // Sync back to local storage
  storage?.saveUserAuthDetails(
    email: fallbackEmail,
    fullName: fallbackName,
    userId: user.id,
  );

  return resolvedProfile;
});

/// Listenable that alerts GoRouter whenever authentication status shifts.
class AuthRedirectNotifier extends ChangeNotifier {
  final Ref _ref;
  StreamSubscription<AuthState>? _sub;
  bool _isPasswordRecovery = false;

  bool get isPasswordRecovery => _isPasswordRecovery;

  AuthRedirectNotifier(this._ref) {
    try {
      final repo = _ref.read(authRepositoryProvider);
      _sub = repo.authStateChanges.listen((state) {
        if (state.event == AuthChangeEvent.passwordRecovery) {
          _isPasswordRecovery = true;
        } else if (state.event == AuthChangeEvent.signedOut ||
            state.event == AuthChangeEvent.userUpdated) {
          _isPasswordRecovery = false;
        }
        notifyListeners();
      });
    } catch (_) {}
  }

  void setPasswordRecovery(bool value) {
    if (_isPasswordRecovery != value) {
      _isPasswordRecovery = value;
      notifyListeners();
    }
  }

  void clearPasswordRecovery() {
    if (_isPasswordRecovery) {
      _isPasswordRecovery = false;
      notifyListeners();
    }
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
  final LocalStorage? _localStorage;

  AuthController(this._repository, [this._localStorage]) : super(const AuthActionState());

  void clearMessages() {
    state = const AuthActionState();
  }

  /// Sign In with Email & Password.
  Future<bool> signIn({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final response = await _repository.signIn(email: normalizedEmail, password: password);
      final user = response.user;
      final nameFromMeta = user?.userMetadata?['full_name'] as String? ??
          user?.userMetadata?['name'] as String? ??
          user?.userMetadata?['fullName'] as String?;
      await _localStorage?.saveUserAuthDetails(
        email: normalizedEmail,
        fullName: nameFromMeta,
        userId: user?.id,
      );
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
    final normalizedEmail = email.trim().toLowerCase();
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      final response = await _repository.signUp(
        email: normalizedEmail,
        password: password,
        fullName: fullName.trim(),
      );
      await _localStorage?.saveUserAuthDetails(
        email: normalizedEmail,
        fullName: fullName.trim(),
        userId: response.user?.id,
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
    final normalizedEmail = email.trim().toLowerCase();
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await _repository.sendPasswordResetEmail(normalizedEmail);
      state = state.copyWith(
        isLoading: false,
        successMessage: 'Password reset link sent! Check your email inbox.',
      );
      return true;
    } on AuthFailure catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (e) {
      final str = e.toString().replaceAll('Exception:', '').trim();
      state = state.copyWith(
        isLoading: false,
        errorMessage: str.contains('rate')
            ? 'Email rate limit reached. Please wait a few minutes before trying again.'
            : 'Failed to send reset link: $str',
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
    final normalizedEmail = email.trim().toLowerCase();
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await _repository.resendVerificationEmail(normalizedEmail);
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
      await _localStorage?.clearUserAuthDetails();
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

  /// Delete the current user's account, wipe local credentials, and reset state.
  Future<bool> deleteAccount(String userId) async {
    state = state.copyWith(isLoading: true, clearError: true, clearSuccess: true);
    try {
      await _repository.deleteAccount(userId);
      await _localStorage?.clearUserAuthDetails();
      state = const AuthActionState();
      return true;
    } on AuthFailure catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: e.message);
      return false;
    } catch (_) {
      state = state.copyWith(isLoading: false, errorMessage: 'Failed to delete account. Please try again.');
      return false;
    }
  }
}

final authControllerProvider = StateNotifierProvider<AuthController, AuthActionState>((ref) {
  final repo = ref.watch(authRepositoryProvider);
  LocalStorage? storage;
  try {
    storage = ref.read(localStorageProvider);
  } catch (_) {}
  return AuthController(repo, storage);
});
