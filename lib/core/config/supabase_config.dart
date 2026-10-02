import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Configuration and initialization for Supabase in AlertSense.
///
/// Security:
/// - Only the public Anon/Publishable key is used.
/// - Never expose or configure the Service-Role key in the Flutter application.
/// - Credentials can be supplied at build/run time via `--dart-define`:
///   `flutter run --dart-define=SUPABASE_URL=https://xyz.supabase.co --dart-define=SUPABASE_ANON_KEY=your-anon-key`
class SupabaseConfig {
  SupabaseConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://auhvgonuqgfqtdggitef.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImF1aHZnb251cWdmcXRkZ2dpdGVmIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA3ODQxMjgsImV4cCI6MjEwNjM2MDEyOH0.mE5YjVFPB3sYodMdgdT6ezfa3IJqmDEWstn4iXYQXKY',
  );

  /// Custom URL scheme used for deep linking auth redirects (email confirmation, password reset).
  static const String authCallbackUrl = 'alertsense://auth-callback';

  /// Whether Supabase credentials are placeholder values or actual credentials.
  static bool get hasValidCredentials {
    return supabaseUrl.isNotEmpty &&
        !supabaseUrl.contains('placeholder-project') &&
        supabaseAnonKey.isNotEmpty &&
        !supabaseAnonKey.contains('placeholder-anon-key');
  }

  /// Safe initialization of the Supabase client.
  /// Gracefully catches and logs errors (e.g. during offline test execution or placeholder runs).
  static Future<void> initialize({
    String? url,
    String? anonKey,
  }) async {
    final effectiveUrl = url ?? supabaseUrl;
    final effectiveKey = anonKey ?? supabaseAnonKey;

    try {
      await Supabase.initialize(
        url: effectiveUrl,
        // ignore: deprecated_member_use
        anonKey: effectiveKey,
        authOptions: const FlutterAuthClientOptions(
          authFlowType: AuthFlowType.pkce,
          autoRefreshToken: true,
        ),
      );
      debugPrint('[Supabase] Initialized successfully with URL: $effectiveUrl');
    } catch (e) {
      debugPrint('[Supabase] Initialization note: $e');
    }
  }

  /// Convenience accessor for the current Supabase client instance.
  static SupabaseClient get client => Supabase.instance.client;
}
