import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Live password criteria indicator providing real-time visual feedback.
/// Visually highlights satisfied and pending rules as the user types.
class PasswordRequirementsView extends StatelessWidget {
  final String password;
  final bool isVisible;

  const PasswordRequirementsView({
    super.key,
    required this.password,
    this.isVisible = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!isVisible) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final hasMinLength = password.length >= 6;
    final hasLetter = password.contains(RegExp(r'[a-zA-Z]'));
    final hasDigit = password.contains(RegExp(r'[0-9]'));
    final hasSpecial = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>\-_=+[\]\\;/`~]'));

    final allMet = hasMinLength && hasLetter && hasDigit && hasSpecial;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      margin: const EdgeInsets.only(top: 8, bottom: 4),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: isDark
            ? (allMet
                ? AppColors.success.withValues(alpha: 0.12)
                : const Color(0xFF111C35).withValues(alpha: 0.5))
            : (allMet
                ? AppColors.success.withValues(alpha: 0.08)
                : const Color(0xFFF1F5F9).withValues(alpha: 0.7)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: allMet
              ? AppColors.success.withValues(alpha: 0.45)
              : theme.colorScheme.outlineVariant.withValues(alpha: 0.35),
          width: 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                allMet ? Icons.verified_rounded : Icons.shield_outlined,
                size: 14,
                color: allMet ? AppColors.success : theme.colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                allMet ? 'Strong password' : 'Password requirements:',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: allMet
                      ? AppColors.success
                      : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.85),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              _buildCriterionChip(
                label: '6+ chars',
                isMet: hasMinLength,
                theme: theme,
                isDark: isDark,
              ),
              _buildCriterionChip(
                label: 'Letters (A-Z / a-z)',
                isMet: hasLetter,
                theme: theme,
                isDark: isDark,
              ),
              _buildCriterionChip(
                label: 'Numbers (0-9)',
                isMet: hasDigit,
                theme: theme,
                isDark: isDark,
              ),
              _buildCriterionChip(
                label: 'Special char (!@#\$)',
                isMet: hasSpecial,
                theme: theme,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCriterionChip({
    required String label,
    required bool isMet,
    required ThemeData theme,
    required bool isDark,
  }) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isMet
            ? AppColors.success.withValues(alpha: 0.15)
            : (isDark
                ? Colors.white.withValues(alpha: 0.04)
                : Colors.black.withValues(alpha: 0.04)),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: isMet
              ? AppColors.success.withValues(alpha: 0.4)
              : Colors.transparent,
          width: 0.8,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isMet ? Icons.check_rounded : Icons.circle_outlined,
            size: 12,
            color: isMet
                ? AppColors.success
                : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.45),
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isMet ? FontWeight.w600 : FontWeight.w400,
              color: isMet
                  ? (isDark ? const Color(0xFF6EE7B7) : const Color(0xFF047857))
                  : theme.textTheme.bodySmall?.color?.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }
}
