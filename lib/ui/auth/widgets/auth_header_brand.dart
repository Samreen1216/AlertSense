import 'package:flutter/material.dart';
import '../../../core/constants/app_assets.dart';
import '../../../core/constants/app_colors.dart';

/// Reusable AlertSense Brand Header for authentication screens.
/// Matches the visual language of the Splash screen and App Header.
class AuthHeaderBrand extends StatelessWidget {
  final String title;
  final String subtitle;
  final double topSpacing;

  const AuthHeaderBrand({
    super.key,
    required this.title,
    required this.subtitle,
    this.topSpacing = 24.0,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(height: topSpacing),
        // AlertSense App Icon Emblem — Matches App Icon exactly
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF0072FF).withValues(alpha: 0.35),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.asset(
              AppAssets.appIcon,
              width: 72,
              height: 72,
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 18),
        // App Name Badge
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
          decoration: BoxDecoration(
            color: isDark
                ? AppColors.primary.withValues(alpha: 0.16)
                : AppColors.primary.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.25),
              width: 1.0,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.secondary,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'ALERTSENSE AI',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.2,
                  color: isDark ? AppColors.hcPrimary : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        // Screen Title ("Welcome back", "Create Account", etc.)
        Text(
          title,
          textAlign: TextAlign.center,
          style: theme.textTheme.headlineMedium?.copyWith(
            fontWeight: FontWeight.bold,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        // Screen Subtitle
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Text(
            subtitle,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.textTheme.bodyMedium?.color?.withValues(alpha: 0.72),
              height: 1.35,
            ),
          ),
        ),
        const SizedBox(height: 28),
      ],
    );
  }
}
