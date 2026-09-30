import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../providers/auth_providers.dart';
import 'widgets/auth_primary_button.dart';

class EmailVerificationScreen extends ConsumerStatefulWidget {
  final String email;

  const EmailVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  ConsumerState<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends ConsumerState<EmailVerificationScreen>
    with WidgetsBindingObserver {
  int _cooldownSeconds = 0;
  Timer? _cooldownTimer;
  StreamSubscription? _authSub;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Start with a 30s resend cooldown
    _startCooldown(30);

    // Listen to Supabase auth state changes — if email link logs user in, navigate immediately
    _authSub = ref.read(authRepositoryProvider).authStateChanges.listen((state) {
      if (!mounted) return;
      final user = ref.read(currentUserProvider);
      if (user != null && user.emailConfirmedAt != null) {
        context.go(AppRoutes.home);
      }
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // User may have verified in email app and returned
      _checkVerificationStatus();
    }
  }

  @override
  void dispose() {
    _cooldownTimer?.cancel();
    _authSub?.cancel();
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  void _startCooldown(int seconds) {
    setState(() => _cooldownSeconds = seconds);
    _cooldownTimer?.cancel();
    _cooldownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_cooldownSeconds <= 1) {
        timer.cancel();
        if (mounted) setState(() => _cooldownSeconds = 0);
      } else {
        if (mounted) setState(() => _cooldownSeconds--);
      }
    });
  }

  Future<void> _handleResend() async {
    if (_cooldownSeconds > 0) return;
    if (widget.email.isEmpty) return;

    final success = await ref
        .read(authControllerProvider.notifier)
        .resendVerificationEmail(widget.email);

    if (success && mounted) {
      _startCooldown(60);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Verification email resent! Check your inbox and spam folder.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _checkVerificationStatus() async {
    final user = ref.read(currentUserProvider);
    if (user != null && user.emailConfirmedAt != null) {
      if (mounted) context.go(AppRoutes.home);
    } else {
      // Refresh current session
      try {
        final repo = ref.read(authRepositoryProvider);
        if (repo.currentUser != null) {
          // If session is active and confirmed
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Email verified! Welcome to AlertSense.'),
                backgroundColor: AppColors.success,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
            context.go(AppRoutes.home);
          }
          return;
        }
      } catch (_) {}

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Email not confirmed yet. Please click the link in your email.'),
            backgroundColor: AppColors.warning,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to Login',
          onPressed: () {
            ref.read(authControllerProvider.notifier).clearMessages();
            context.go(AppRoutes.login);
          },
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Envelope Emblem with Sonic Pulse
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [
                          AppColors.primary,
                          AppColors.secondary,
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.mark_email_unread_rounded,
                        color: Colors.white,
                        size: 46,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),

                  Text(
                    'Verify Your Email',
                    style: theme.textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Text(
                      'We have sent an activation link to:',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.75),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF111C35)
                          : const Color(0xFFE2E8F0).withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.email.isNotEmpty ? widget.email : 'your email address',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: isDark ? AppColors.hcPrimary : AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12.0),
                    child: Text(
                      'Please open your inbox and click the confirmation link to activate your account. You will then have access to real-time sound detection.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.7),
                        height: 1.45,
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // "I've Verified My Email" Button
                  AuthPrimaryButton(
                    text: "I've Verified My Email",
                    icon: Icons.check_circle_rounded,
                    isLoading: authState.isLoading,
                    onPressed: _checkVerificationStatus,
                  ),
                  const SizedBox(height: 14),

                  // Resend Email Button
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: OutlinedButton.icon(
                      style: OutlinedButton.styleFrom(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant,
                          width: 1.0,
                        ),
                      ),
                      onPressed: (_cooldownSeconds > 0 || authState.isLoading)
                          ? null
                          : _handleResend,
                      icon: const Icon(Icons.refresh_rounded, size: 20),
                      label: Text(
                        _cooldownSeconds > 0
                            ? 'Resend Email in ${_cooldownSeconds}s'
                            : 'Resend Verification Email',
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Back to Login Link
                  TextButton.icon(
                    onPressed: () {
                      ref.read(authControllerProvider.notifier).clearMessages();
                      context.go(AppRoutes.login);
                    },
                    icon: const Icon(Icons.arrow_back_rounded, size: 18),
                    label: const Text(
                      'Back to Login',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
