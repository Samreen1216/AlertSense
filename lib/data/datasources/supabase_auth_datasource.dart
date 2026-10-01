import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/config/supabase_config.dart';
import '../models/user_profile.dart';

/// Data source interface for Supabase authentication and user profile management.
abstract class ISupabaseAuthDataSource {
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  });

  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  });

  Future<void> signOut();

  Future<void> resetPasswordForEmail(String email);

  Future<UserResponse> updateUserPassword(String newPassword);

  Future<void> resendVerificationEmail(String email);

  Future<void> deleteAccount(String userId);

  Future<UserProfile?> fetchProfile(String userId);

  Future<void> upsertProfile(UserProfile profile);

  User? get currentUser;

  Session? get currentSession;

  Stream<AuthState> get onAuthStateChange;
}

/// Implementation of [ISupabaseAuthDataSource] using the `supabase_flutter` SDK.
class SupabaseAuthDataSource implements ISupabaseAuthDataSource {
  final SupabaseClient? _customClient;

  SupabaseAuthDataSource([this._customClient]);

  SupabaseClient get _client {
    if (_customClient != null) return _customClient;
    return SupabaseConfig.client;
  }

  @override
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required String fullName,
  }) async {
    final response = await _client.auth.signUp(
      email: email.trim(),
      password: password,
      data: {'full_name': fullName.trim()},
      emailRedirectTo: SupabaseConfig.authCallbackUrl,
    );

    // If user was created immediately and has an ID, attempt to populate the profile row
    final user = response.user;
    if (user != null) {
      try {
        await upsertProfile(
          UserProfile(
            id: user.id,
            fullName: fullName.trim(),
            email: email.trim(),
            createdAt: DateTime.now().toUtc(),
            updatedAt: DateTime.now().toUtc(),
          ),
        );
      } catch (e) {
        debugPrint('[SupabaseAuthDataSource] Profile creation note: $e');
      }
    }

    return response;
  }

  @override
  Future<AuthResponse> signInWithPassword({
    required String email,
    required String password,
  }) async {
    return await _client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
  }

  @override
  Future<void> signOut() async {
    await _client.auth.signOut();
  }

  @override
  Future<void> resetPasswordForEmail(String email) async {
    await _client.auth.resetPasswordForEmail(
      email.trim(),
      redirectTo: SupabaseConfig.authCallbackUrl,
    );
  }

  @override
  Future<UserResponse> updateUserPassword(String newPassword) async {
    return await _client.auth.updateUser(
      UserAttributes(password: newPassword),
    );
  }

  @override
  Future<void> resendVerificationEmail(String email) async {
    await _client.auth.resend(
      type: OtpType.signup,
      email: email.trim(),
      emailRedirectTo: SupabaseConfig.authCallbackUrl,
    );
  }

  @override
  Future<void> deleteAccount(String userId) async {
    try {
      await _client.from('profiles').delete().eq('id', userId);
    } catch (e) {
      debugPrint('[SupabaseAuthDataSource] Failed to delete profile row: $e');
    }
    try {
      await _client.rpc('delete_user');
    } catch (e) {
      debugPrint('[SupabaseAuthDataSource] delete_user RPC note: $e');
    }
    await signOut();
  }

  @override
  Future<UserProfile?> fetchProfile(String userId) async {
    try {
      final response = await _client
          .from('profiles')
          .select()
          .eq('id', userId)
          .maybeSingle();

      if (response == null) return null;
      return UserProfile.fromMap(response);
    } catch (e) {
      debugPrint('[SupabaseAuthDataSource] fetchProfile error: $e');
      return null;
    }
  }

  @override
  Future<void> upsertProfile(UserProfile profile) async {
    await _client.from('profiles').upsert(profile.toMap());
  }

  @override
  User? get currentUser {
    try {
      return _client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  @override
  Session? get currentSession {
    try {
      return _client.auth.currentSession;
    } catch (_) {
      return null;
    }
  }

  @override
  Stream<AuthState> get onAuthStateChange {
    try {
      return _client.auth.onAuthStateChange;
    } catch (_) {
      return const Stream.empty();
    }
  }
}
