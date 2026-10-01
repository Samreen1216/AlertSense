import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../datasources/supabase_auth_datasource.dart';
import '../models/user_profile.dart';

/// Clean user-facing domain exception for authentication failures.
class AuthFailure implements Exception {
  final String message;
  final String? code;

  const AuthFailure(this.message, {this.code});

  @override
  String toString() => message;
}

/// Authentication Repository orchestrating auth operations, profile synchronization,
/// and converting raw Supabase exceptions into clean, user-friendly messages.
class AuthRepository {
  final ISupabaseAuthDataSource _dataSource;

  AuthRepository(this._dataSource);

  User? get currentUser => _dataSource.currentUser;

  bool get isAuthenticated => currentUser != null;

  Session? get currentSession => _dataSource.currentSession;

  Stream<AuthState> get authStateChanges => _dataSource.onAuthStateChange;

  /// Sign in with email and password.
  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dataSource.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } catch (e) {
      throw _mapExceptionToAuthFailure(e);
    }
  }

  /// Sign up with email, password, and full name.
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final response = await _dataSource.signUp(
        email: email,
        password: password,
        fullName: fullName,
      );
      return response;
    } catch (e) {
      throw _mapExceptionToAuthFailure(e);
    }
  }

  /// Sign out the current user and invalidate the local session.
  Future<void> signOut() async {
    try {
      await _dataSource.signOut();
    } catch (e) {
      throw _mapExceptionToAuthFailure(e);
    }
  }

  /// Request a password reset link to be sent to the user's email.
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _dataSource.resetPasswordForEmail(email);
    } catch (e) {
      throw _mapExceptionToAuthFailure(e);
    }
  }

  /// Update password for the currently authenticated user (after recovery link).
  Future<UserResponse> updatePassword(String newPassword) async {
    try {
      final response = await _dataSource.updateUserPassword(newPassword);
      return response;
    } catch (e) {
      throw _mapExceptionToAuthFailure(e);
    }
  }

  /// Resend confirmation / verification email.
  Future<void> resendVerificationEmail(String email) async {
    try {
      await _dataSource.resendVerificationEmail(email);
    } catch (e) {
      throw _mapExceptionToAuthFailure(e);
    }
  }

  /// Delete user account and all remote profile data.
  Future<void> deleteAccount(String userId) async {
    try {
      await _dataSource.deleteAccount(userId);
    } catch (e) {
      throw _mapExceptionToAuthFailure(e);
    }
  }

  /// Retrieve the user profile from the `profiles` table.
  Future<UserProfile?> getProfile(String userId) async {
    try {
      return await _dataSource.fetchProfile(userId);
    } catch (e) {
      debugPrint('[AuthRepository] Failed to fetch profile: $e');
      return null;
    }
  }

  /// Update or save user profile information.
  Future<void> updateProfile(UserProfile profile) async {
    try {
      await _dataSource.upsertProfile(profile);
    } catch (e) {
      throw _mapExceptionToAuthFailure(e);
    }
  }

  /// Map raw exceptions to human-friendly [AuthFailure] messages without leaking stack traces.
  AuthFailure _mapExceptionToAuthFailure(dynamic error) {
    if (error is AuthException) {
      final msg = error.message.toLowerCase();
      final code = error.statusCode?.toString() ?? error.code;

      if (msg.contains('invalid login credentials') ||
          msg.contains('invalid_credentials') ||
          msg.contains('invalid email or password')) {
        return const AuthFailure(
          'Incorrect email or password. Please verify your details and try again.',
          code: 'invalid_credentials',
        );
      }

      if (msg.contains('user already registered') ||
          msg.contains('already registered') ||
          msg.contains('user already exists') ||
          msg.contains('email address already taken')) {
        return const AuthFailure(
          'An account with this email address already exists. Please log in instead.',
          code: 'user_already_exists',
        );
      }

      if (msg.contains('email not confirmed') ||
          msg.contains('not confirmed') ||
          msg.contains('unconfirmed email')) {
        return const AuthFailure(
          'Your email address has not been verified yet. Please check your inbox for the confirmation link.',
          code: 'email_not_confirmed',
        );
      }

      if (msg.contains('password should be at least') ||
          msg.contains('weak password') ||
          msg.contains('password is too short')) {
        return const AuthFailure(
          'Password is too weak. Please use at least 6 characters.',
          code: 'weak_password',
        );
      }

      if (msg.contains('rate limit') ||
          msg.contains('too many requests') ||
          msg.contains('over_email_send_rate_limit') ||
          msg.contains('email rate limit exceeded') ||
          code == '429' ||
          code == 'over_email_send_rate_limit') {
        return const AuthFailure(
          'Email rate limit reached. Supabase temporarily restricts email requests to prevent spam. Please wait a few minutes before trying again.',
          code: 'rate_limit',
        );
      }

      if (msg.contains('network') || msg.contains('connection')) {
        return const AuthFailure(
          'Network connection error. Please verify your internet connection and try again.',
          code: 'network_error',
        );
      }

      return AuthFailure(error.message, code: code);
    }

    if (error is SocketException ||
        error.toString().contains('SocketException') ||
        error.toString().contains('Failed host lookup') ||
        error.toString().contains('ClientException')) {
      return const AuthFailure(
        'Unable to reach AlertSense servers. Please check your internet connection.',
        code: 'network_error',
      );
    }

    return const AuthFailure(
      'An unexpected error occurred. Please try again.',
      code: 'unknown_error',
    );
  }
}
