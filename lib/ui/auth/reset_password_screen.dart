import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/utils/auth_validators.dart';
import '../../providers/auth_providers.dart';
import 'widgets/auth_header_brand.dart';
import 'widgets/auth_primary_button.dart';
import 'widgets/auth_text_field.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  @override
  void dispose() {
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleUpdatePassword() async {
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(authControllerProvider.notifier)
        .updatePassword(_newPasswordController.text);

    if (success && mounted) {
      ref.read(authRedirectListenableProvider).clearPasswordRecovery();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Password updated successfully! Welcome back.'),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      try {
        context.go(AppRoutes.home);
      } catch (_) {}
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final authState = ref.watch(authControllerProvider);

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back',
          onPressed: () {
            ref.read(authRedirectListenableProvider).clearPasswordRecovery();
            ref.read(authControllerProvider.notifier).clearMessages();
            final isAuth = ref.read(isAuthenticatedProvider);
            try {
              if (Navigator.of(context).canPop()) {
                Navigator.of(context).pop();
              } else {
                context.go(isAuth ? AppRoutes.home : AppRoutes.login);
              }
            } catch (_) {}
          },
        ),
        title: const Text('Reset Password'),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const AuthHeaderBrand(
                      title: 'Update Password',
                      subtitle: 'Choose a strong new password for your AlertSense account',
                      topSpacing: 8,
                    ),

                    // Error Message Banner
                    if (authState.errorMessage != null) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.error.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: AppColors.error.withValues(alpha: 0.35),
                            width: 1.0,
                          ),
                        ),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.error_outline_rounded,
                              color: AppColors.error,
                              size: 20,
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                authState.errorMessage!,
                                style: const TextStyle(
                                  color: AppColors.error,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],

                    // New Password Input
                    AuthTextField(
                      controller: _newPasswordController,
                      labelText: 'New Password',
                      hintText: 'At least 6 characters',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _obscureNewPassword,
                      textInputAction: TextInputAction.next,
                      validator: AuthValidators.validatePassword,
                      enabled: !authState.isLoading,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNewPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        tooltip: _obscureNewPassword ? 'Show password' : 'Hide password',
                        onPressed: () {
                          setState(() {
                            _obscureNewPassword = !_obscureNewPassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Confirm Password Input
                    AuthTextField(
                      controller: _confirmPasswordController,
                      labelText: 'Confirm New Password',
                      hintText: 'Re-enter your new password',
                      prefixIcon: Icons.lock_outline_rounded,
                      obscureText: _obscureConfirmPassword,
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _handleUpdatePassword(),
                      validator: (value) => AuthValidators.validateConfirmPassword(
                        _newPasswordController.text,
                        value,
                      ),
                      enabled: !authState.isLoading,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          size: 20,
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                        ),
                        tooltip: _obscureConfirmPassword ? 'Show password' : 'Hide password',
                        onPressed: () {
                          setState(() {
                            _obscureConfirmPassword = !_obscureConfirmPassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Update Password Button
                    AuthPrimaryButton(
                      text: 'Update Password',
                      icon: Icons.check_circle_outline_rounded,
                      isLoading: authState.isLoading,
                      onPressed: _handleUpdatePassword,
                    ),
                    const SizedBox(height: 16),

                    // Cancel / Back to Login
                    Center(
                      child: TextButton.icon(
                        onPressed: authState.isLoading
                            ? null
                            : () {
                                ref.read(authRedirectListenableProvider).clearPasswordRecovery();
                                ref.read(authControllerProvider.notifier).clearMessages();
                                final isAuth = ref.read(isAuthenticatedProvider);
                                try {
                                  if (Navigator.of(context).canPop()) {
                                    Navigator.of(context).pop();
                                  } else {
                                    context.go(isAuth ? AppRoutes.home : AppRoutes.login);
                                  }
                                } catch (_) {}
                              },
                        icon: const Icon(Icons.arrow_back_rounded, size: 18),
                        label: Text(
                          ref.watch(isAuthenticatedProvider) ? 'Return to Home' : 'Back to Login',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
