import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../core/utils/auth_validators.dart';
import '../../../data/datasources/local_storage.dart';
import '../../../data/models/user_profile.dart';
import '../../../main.dart';
import '../../../providers/alert_providers.dart';
import '../../../providers/auth_providers.dart';

/// Modal bottom sheet and standalone view displaying user account details,
/// session status, profile management, and direct navigation shortcuts.
class UserAccountSheet extends ConsumerWidget {
  const UserAccountSheet({super.key});

  /// Display the user account details modal sheet (or centered dialog on desktop/tablets).
  static Future<void> show(BuildContext context) {
    HapticFeedback.lightImpact();
    final isTablet = MediaQuery.sizeOf(context).width >= 600;

    if (isTablet) {
      return showDialog(
        context: context,
        builder: (ctx) => Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520, maxHeight: 720),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: const UserAccountSheet(),
            ),
          ),
        ),
      );
    }

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const UserAccountSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final userProfile = profileAsync.valueOrNull;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeType = ref.watch(themeTypeProvider);
    final isHighContrast = themeType == ThemeType.highContrast;

    final sheetBg = isHighContrast
        ? Colors.black
        : (isDark ? const Color(0xFF0F172A) : Colors.white);

    final sheetBorder = isHighContrast
        ? Border.all(color: AppColors.hcPrimary, width: 2.0)
        : Border.all(
            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            width: 1,
          );

    LocalStorage? storage;
    try {
      storage = ref.read(localStorageProvider);
    } catch (_) {}

    final savedName = storage?.getSavedUserFullName();
    final savedEmail = storage?.getSavedUserEmail();

    final resolvedName = userProfile?.fullName.isNotEmpty == true
        ? userProfile!.fullName
        : ((user?.userMetadata?['full_name'] as String?)?.trim().isNotEmpty == true
            ? (user!.userMetadata!['full_name'] as String).trim()
            : ((user?.userMetadata?['name'] as String?)?.trim().isNotEmpty == true
                ? (user!.userMetadata!['name'] as String).trim()
                : ((user?.userMetadata?['fullName'] as String?)?.trim().isNotEmpty == true
                    ? (user!.userMetadata!['fullName'] as String).trim()
                    : (savedName?.trim().isNotEmpty == true
                        ? savedName!.trim()
                        : (user?.email?.split('@').first ?? 'AlertSense User')))));

    final userEmail = user?.email;
    final email = (userEmail != null && userEmail.isNotEmpty)
        ? userEmail
        : (userProfile?.email.isNotEmpty == true
            ? userProfile!.email
            : (savedEmail?.isNotEmpty == true ? savedEmail! : 'Local Offline Session'));

    String initials = '';
    if (resolvedName.isNotEmpty) {
      final parts = resolvedName.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
        initials = parts[0][0].toUpperCase();
      }
    }

    String formattedCreatedDate = 'Recently joined';
    if (user?.createdAt != null) {
      try {
        final parsed = DateTime.tryParse(user!.createdAt);
        if (parsed != null) {
          formattedCreatedDate = DateFormat('MMMM d, yyyy').format(parsed.toLocal());
        }
      } catch (_) {}
    }

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.88,
      ),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: sheetBorder,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle pill
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isHighContrast
                      ? AppColors.hcPrimary
                      : (isDark ? Colors.white24 : Colors.black12),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            ),

            // Top Header Bar
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 6, 12, 10),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: isHighContrast
                          ? AppColors.hcPrimary.withValues(alpha: 0.15)
                          : const Color(0xFF0062FF).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.manage_accounts_rounded,
                      color: isHighContrast ? AppColors.hcPrimary : const Color(0xFF0062FF),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'User Account Details',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isHighContrast
                                ? AppColors.hcTextPrimary
                                : (isDark ? Colors.white : const Color(0xFF0F172A)),
                          ),
                        ),
                        Text(
                          'AlertSense Profile & Security',
                          style: TextStyle(
                            fontSize: 12,
                            color: isHighContrast
                                ? AppColors.hcTextSecondary
                                : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    color: isHighContrast
                        ? AppColors.hcTextSecondary
                        : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),

            const Divider(height: 1),

            // Scrollable Content
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // ── 1. User Hero Card ──
                    _buildUserHeroCard(
                      context: context,
                      ref: ref,
                      user: user,
                      resolvedName: resolvedName,
                      email: email,
                      initials: initials,
                      isDark: isDark,
                      isHighContrast: isHighContrast,
                    ),
                    const SizedBox(height: 18),

                    // ── 2. Account Information Section ──
                    _buildSectionHeader(
                      context,
                      'ACCOUNT INFORMATION',
                      Icons.badge_outlined,
                      isDark: isDark,
                      isHighContrast: isHighContrast,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoCard(
                      context: context,
                      isDark: isDark,
                      isHighContrast: isHighContrast,
                      children: [
                        _buildInfoRow(
                          context,
                          label: 'Full Name',
                          value: resolvedName,
                          icon: Icons.person_outline_rounded,
                          isDark: isDark,
                          isHighContrast: isHighContrast,
                          trailing: user != null
                              ? IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  tooltip: 'Edit Name',
                                  color: const Color(0xFF0062FF),
                                  onPressed: () => _showEditNameDialog(context, ref, resolvedName),
                                )
                              : null,
                        ),
                        const Divider(height: 1),
                        _buildInfoRow(
                          context,
                          label: 'Email Address',
                          value: email,
                          icon: Icons.mail_outline_rounded,
                          isDark: isDark,
                          isHighContrast: isHighContrast,
                          trailing: user != null
                              ? Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: AppColors.success.withValues(alpha: 0.12),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(Icons.check_circle_rounded, size: 12, color: AppColors.success),
                                      SizedBox(width: 4),
                                      Text(
                                        'Verified',
                                        style: TextStyle(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.success,
                                        ),
                                      ),
                                    ],
                                  ),
                                )
                              : null,
                        ),
                        if (user != null) ...[
                          const Divider(height: 1),
                          _buildInfoRow(
                            context,
                            label: 'Member Since',
                            value: formattedCreatedDate,
                            icon: Icons.calendar_today_outlined,
                            isDark: isDark,
                            isHighContrast: isHighContrast,
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 18),

                    // ── 3. Simple Account Options & Security ──
                    _buildSectionHeader(
                      context,
                      'ACCOUNT OPTIONS & SECURITY',
                      Icons.manage_accounts_outlined,
                      isDark: isDark,
                      isHighContrast: isHighContrast,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoCard(
                      context: context,
                      isDark: isDark,
                      isHighContrast: isHighContrast,
                      children: [
                        // Option 1: Change Password (authenticated user)
                        if (user != null) ...[
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                            leading: _buildTileIcon(
                              Icons.lock_outline_rounded,
                              const Color(0xFF10B981),
                              isDark: isDark,
                              isHighContrast: isHighContrast,
                            ),
                            title: const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: const Text('Enter a new password directly', style: TextStyle(fontSize: 12)),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => _showChangePasswordDialog(context, ref),
                          ),
                          const Divider(height: 1),
                          // Option 2: Reset Password (authenticated user)
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                            leading: _buildTileIcon(
                              Icons.lock_reset_rounded,
                              const Color(0xFFF59E0B),
                              isDark: isDark,
                              isHighContrast: isHighContrast,
                            ),
                            title: const Text('Reset Password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: const Text('Send password reset link to your email', style: TextStyle(fontSize: 12)),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => _handleSendPasswordReset(context, ref, user.email ?? ''),
                          ),
                          const Divider(height: 1),
                        ],

                        // Option 4: Delete Account (placed ONLY ONE TIME)
                        const Divider(height: 1),
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                          leading: _buildTileIcon(
                            Icons.delete_forever_rounded,
                            AppColors.error,
                            isDark: isDark,
                            isHighContrast: isHighContrast,
                          ),
                          title: Text(
                            'Delete Account',
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: isHighContrast ? AppColors.hcHighAlert : AppColors.error,
                            ),
                          ),
                          subtitle: Text(
                            user != null
                                ? 'Permanently erase account, profile, and all data'
                                : 'Permanently clear local guest credentials and cached data',
                            style: const TextStyle(fontSize: 12),
                          ),
                          trailing: Icon(
                            Icons.chevron_right_rounded,
                            color: isHighContrast ? AppColors.hcHighAlert : AppColors.error,
                          ),
                          onTap: () => _showDeleteAccountDialog(context, ref, user?.id),
                        ),
                      ],
                    ),
                    const SizedBox(height: 22),

                    // ── 4. Session Action (Log Out or Sign In) ──
                    if (user != null)
                      FilledButton.icon(
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: const Text('Log Out of AlertSense', style: TextStyle(fontWeight: FontWeight.w700)),
                        style: FilledButton.styleFrom(
                          backgroundColor: isHighContrast ? Colors.black : AppColors.error,
                          foregroundColor: isHighContrast ? AppColors.hcHighAlert : Colors.white,
                          side: isHighContrast ? const BorderSide(color: AppColors.hcHighAlert, width: 2) : null,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () => _showLogoutDialog(context, ref),
                      )
                    else
                      FilledButton.icon(
                        icon: const Icon(Icons.login_rounded, size: 18),
                        label: const Text('Sign In or Create Account', style: TextStyle(fontWeight: FontWeight.w700)),
                        style: FilledButton.styleFrom(
                          backgroundColor: isHighContrast ? AppColors.hcPrimary : const Color(0xFF0062FF),
                          foregroundColor: isHighContrast ? Colors.black : Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        onPressed: () {
                          Navigator.of(context).pop();
                          context.push(AppRoutes.login);
                        },
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Helper Widgets ──

  Widget _buildUserHeroCard({
    required BuildContext context,
    required WidgetRef ref,
    required dynamic user,
    required String resolvedName,
    required String email,
    required String initials,
    required bool isDark,
    required bool isHighContrast,
  }) {
    final isAuthenticated = user != null;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isHighContrast
            ? Colors.black
            : (isDark ? const Color(0xFF1E2638) : const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighContrast
              ? AppColors.hcPrimary
              : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
          width: isHighContrast ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        children: [
          // Circular Avatar with online indicator
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: !isHighContrast
                      ? const LinearGradient(
                          colors: [Color(0xFF0072FF), Color(0xFF00C6FF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        )
                      : null,
                  color: isHighContrast ? Colors.black : null,
                  border: Border.all(
                    color: isHighContrast ? AppColors.hcPrimary : Colors.white,
                    width: 2,
                  ),
                  boxShadow: !isHighContrast
                      ? [
                          BoxShadow(
                            color: const Color(0xFF0072FF).withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          ),
                        ]
                      : null,
                ),
                child: Center(
                  child: initials.isNotEmpty
                      ? Text(
                          initials,
                          style: TextStyle(
                            color: isHighContrast ? AppColors.hcPrimary : Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : Icon(
                          Icons.person_rounded,
                          color: isHighContrast ? AppColors.hcPrimary : Colors.white,
                          size: 30,
                        ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: isAuthenticated ? AppColors.success : const Color(0xFFF59E0B),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isDark ? const Color(0xFF1E2638) : Colors.white,
                      width: 2.5,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),

          // User Name & Email & Status
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  resolvedName,
                  style: TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: isHighContrast
                        ? AppColors.hcTextPrimary
                        : (isDark ? Colors.white : const Color(0xFF0F172A)),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 12,
                    color: isHighContrast
                        ? AppColors.hcTextSecondary
                        : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isAuthenticated
                        ? AppColors.success.withValues(alpha: 0.12)
                        : const Color(0xFFF59E0B).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: isAuthenticated
                          ? AppColors.success.withValues(alpha: 0.35)
                          : const Color(0xFFF59E0B).withValues(alpha: 0.35),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isAuthenticated ? Icons.verified_user_rounded : Icons.info_outline_rounded,
                        size: 12,
                        color: isAuthenticated ? AppColors.success : const Color(0xFFF59E0B),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isAuthenticated ? 'Authenticated Account' : 'Guest Session',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: isAuthenticated ? AppColors.success : const Color(0xFFF59E0B),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context,
    String title,
    IconData icon, {
    required bool isDark,
    required bool isHighContrast,
  }) {
    return Row(
      children: [
        Icon(
          icon,
          size: 14,
          color: isHighContrast
              ? AppColors.hcPrimary
              : (isDark ? Colors.white54 : const Color(0xFF64748B)),
        ),
        const SizedBox(width: 6),
        Text(
          title,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.6,
            color: isHighContrast
                ? AppColors.hcPrimary
                : (isDark ? Colors.white54 : const Color(0xFF64748B)),
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard({
    required BuildContext context,
    required bool isDark,
    required bool isHighContrast,
    required List<Widget> children,
  }) {
    final bgColor = isHighContrast
        ? Colors.black
        : (isDark ? const Color(0xFF1E2638) : Colors.white);

    return Material(
      color: bgColor,
      borderRadius: BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isHighContrast
                ? AppColors.hcPrimary
                : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
            width: isHighContrast ? 1.5 : 1.0,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: children,
        ),
      ),
    );
  }

  Widget _buildInfoRow(
    BuildContext context, {
    required String label,
    required String value,
    required IconData icon,
    required bool isDark,
    required bool isHighContrast,
    Widget? trailing,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(
            icon,
            size: 18,
            color: isHighContrast
                ? AppColors.hcPrimary
                : (isDark ? Colors.white60 : const Color(0xFF64748B)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 11,
                    color: isHighContrast
                        ? AppColors.hcTextTertiary
                        : (isDark ? Colors.white54 : const Color(0xFF94A3B8)),
                  ),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: isHighContrast
                        ? AppColors.hcTextPrimary
                        : (isDark ? Colors.white : const Color(0xFF0F172A)),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (trailing != null) trailing,
        ],
      ),
    );
  }

  Widget _buildTileIcon(
    IconData icon,
    Color color, {
    required bool isDark,
    required bool isHighContrast,
  }) {
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(
        color: isHighContrast ? color.withValues(alpha: 0.2) : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Icon(
        icon,
        size: 18,
        color: isHighContrast ? AppColors.hcPrimary : color,
      ),
    );
  }

  // ── Actions ──

  void _showEditNameDialog(BuildContext context, WidgetRef ref, String currentName) {
    final controller = TextEditingController(text: currentName);

    Future<void> saveName(BuildContext ctx) async {
      final newName = controller.text.trim();
      if (newName.isNotEmpty) {
        final user = ref.read(currentUserProvider);
        try {
          try {
            final storage = ref.read(localStorageProvider);
            await storage.saveUserAuthDetails(
              email: user?.email ?? storage.getSavedUserEmail() ?? '',
              fullName: newName,
              userId: user?.id,
            );
          } catch (_) {}

          if (user != null) {
            await ref.read(authRepositoryProvider).updateProfile(
                  UserProfile(
                    id: user.id,
                    fullName: newName,
                    email: user.email ?? '',
                    updatedAt: DateTime.now().toUtc(),
                  ),
                );
          }
          ref.invalidate(userProfileProvider);
          if (context.mounted) {
            Navigator.of(ctx).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: const Text('Profile name updated successfully'),
                duration: const Duration(seconds: 2),
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Failed to update name: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      }
    }

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Profile Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
          keyboardType: TextInputType.name,
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.done,
          onSubmitted: (_) => saveName(ctx),
          decoration: const InputDecoration(
            labelText: 'Full Name',
            hintText: 'Enter your full name',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => saveName(ctx),
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showChangePasswordDialog(BuildContext context, WidgetRef ref) {
    final newPasswordController = TextEditingController();
    final confirmPasswordController = TextEditingController();
    final newPasswordFocusNode = FocusNode();
    final confirmPasswordFocusNode = FocusNode();
    bool obscureNew = true;
    bool obscureConfirm = true;
    String? errorMessage;
    bool isProcessing = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) {
          final theme = Theme.of(ctx);
          final isDark = theme.brightness == Brightness.dark;
          final themeType = ref.read(themeTypeProvider);
          final isHighContrast = themeType == ThemeType.highContrast;

          Future<void> submitPassword() async {
            final newPass = newPasswordController.text;
            final confirmPass = confirmPasswordController.text;

            final passError = AuthValidators.validateStrongPassword(newPass);
            if (passError != null) {
              setState(() => errorMessage = passError);
              return;
            }
            if (newPass != confirmPass) {
              setState(() => errorMessage = 'Passwords do not match.');
              return;
            }

            setState(() {
              isProcessing = true;
              errorMessage = null;
            });

            final success = await ref
                .read(authControllerProvider.notifier)
                .updatePassword(newPass);

            if (ctx.mounted) {
              Navigator.of(ctx).pop();
            }
            if (context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    success
                        ? 'Password successfully updated!'
                        : 'Failed to update password. Please try again.',
                  ),
                  backgroundColor: success ? AppColors.success : AppColors.error,
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              );
            }
          }

          return AlertDialog(
            backgroundColor: isHighContrast
                ? Colors.black
                : (isDark ? const Color(0xFF1E2638) : Colors.white),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: isHighContrast
                  ? const BorderSide(color: AppColors.hcPrimary, width: 2)
                  : (isDark ? const BorderSide(color: Colors.white12) : const BorderSide(color: Color(0xFFE2E8F0))),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0062FF).withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.lock_outline_rounded,
                    color: isHighContrast ? AppColors.hcPrimary : const Color(0xFF0062FF),
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Text('Change Password', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
              ],
            ),
            content: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: newPasswordController,
                    focusNode: newPasswordFocusNode,
                    obscureText: obscureNew,
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.done,
                    autocorrect: false,
                    enableSuggestions: false,
                    onSubmitted: (_) => FocusScope.of(ctx).unfocus(),
                    decoration: InputDecoration(
                      labelText: 'New Password',
                      hintText: 'Enter new password (min. 6 chars)',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(obscureNew ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                        onPressed: () => setState(() => obscureNew = !obscureNew),
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: confirmPasswordController,
                    focusNode: confirmPasswordFocusNode,
                    obscureText: obscureConfirm,
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.done,
                    autocorrect: false,
                    enableSuggestions: false,
                    onSubmitted: (_) => FocusScope.of(ctx).unfocus(),
                    decoration: InputDecoration(
                      labelText: 'Confirm Password',
                      hintText: 'Re-enter new password',
                      border: const OutlineInputBorder(),
                      suffixIcon: IconButton(
                        icon: Icon(obscureConfirm ? Icons.visibility_off_outlined : Icons.visibility_outlined),
                        onPressed: () => setState(() => obscureConfirm = !obscureConfirm),
                      ),
                    ),
                  ),
                  if (errorMessage != null) ...[
                    const SizedBox(height: 10),
                    Text(
                      errorMessage!,
                      style: const TextStyle(color: AppColors.error, fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isProcessing ? null : () => Navigator.of(ctx).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: isProcessing ? null : submitPassword,
                child: isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Update Password'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _handleSendPasswordReset(BuildContext context, WidgetRef ref, String email) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Reset Password?'),
        content: Text('We will send a password reset link to $email.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              final success = await ref
                  .read(authControllerProvider.notifier)
                  .sendPasswordResetEmail(email);
              if (context.mounted) {
                final authState = ref.read(authControllerProvider);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Password reset email sent! Please check your inbox.'
                          : (authState.errorMessage ?? 'Failed to send reset link. Please try again.'),
                    ),
                    backgroundColor: success ? AppColors.success : AppColors.error,
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              }
            },
            child: const Text('Send Email'),
          ),
        ],
      ),
    );
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text(
          'Are you sure you want to log out of AlertSense? You will need to sign in again to access your account.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            onPressed: () async {
              Navigator.pop(ctx); // Close dialog
              Navigator.of(context).pop(); // Close bottom sheet
              await ref.read(authControllerProvider.notifier).signOut();
              if (context.mounted) {
                context.go(AppRoutes.login);
              }
            },
            child: const Text('Log Out'),
          ),
        ],
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, WidgetRef ref, String? userId) {
    bool wipeAlertHistory = true;
    bool confirmIrreversible = false;
    bool isProcessing = false;

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeType = ref.read(themeTypeProvider);
    final isHighContrast = themeType == ThemeType.highContrast;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setState) {
          final dialogBg = isHighContrast
              ? Colors.black
              : (isDark ? const Color(0xFF1E2638) : Colors.white);

          return AlertDialog(
            backgroundColor: dialogBg,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: isHighContrast
                  ? const BorderSide(color: AppColors.hcHighAlert, width: 2)
                  : (isDark ? const BorderSide(color: Colors.white12) : const BorderSide(color: Color(0xFFE2E8F0))),
            ),
            title: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.warning_amber_rounded,
                    color: isHighContrast ? AppColors.hcHighAlert : AppColors.error,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Delete Account',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 18,
                      color: isHighContrast ? AppColors.hcHighAlert : (isDark ? Colors.white : const Color(0xFF0F172A)),
                    ),
                  ),
                ),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'This action is permanent and irreversible. Once deleted, your account and associated personal data cannot be recovered.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      color: isHighContrast ? Colors.white : (isDark ? Colors.white70 : const Color(0xFF475569)),
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Data breakdown box
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isHighContrast
                          ? Colors.black
                          : (isDark ? Colors.black26 : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isHighContrast
                            ? AppColors.hcHighAlert.withValues(alpha: 0.5)
                            : (isDark ? Colors.white12 : const Color(0xFFE2E8F0)),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'The following will be deleted:',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: isHighContrast ? AppColors.hcHighAlert : (isDark ? Colors.white : const Color(0xFF0F172A)),
                          ),
                        ),
                        const SizedBox(height: 6),
                        _buildBulletItem('Account profile, email & login credentials', isHighContrast, isDark),
                        _buildBulletItem('Sound detection configurations & thresholds', isHighContrast, isDark),
                        _buildBulletItem('Local device session & cached auth tokens', isHighContrast, isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),

                  // Option: Wipe local alert logs
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: wipeAlertHistory,
                    activeColor: isHighContrast ? AppColors.hcHighAlert : AppColors.error,
                    title: Text(
                      'Wipe all recorded alert logs & notification history',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isHighContrast ? Colors.white : (isDark ? Colors.white : const Color(0xFF0F172A)),
                      ),
                    ),
                    onChanged: isProcessing
                        ? null
                        : (val) => setState(() => wipeAlertHistory = val ?? true),
                  ),

                  // Safeguard Confirmation Checkbox
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    value: confirmIrreversible,
                    activeColor: isHighContrast ? AppColors.hcHighAlert : AppColors.error,
                    title: Text(
                      'I understand that my account will be permanently deleted and cannot be undone.',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: isHighContrast ? AppColors.hcHighAlert : AppColors.error,
                      ),
                    ),
                    onChanged: isProcessing
                        ? null
                        : (val) => setState(() => confirmIrreversible = val ?? false),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: isProcessing ? null : () => Navigator.pop(ctx),
                child: Text(
                  'Cancel',
                  style: TextStyle(
                    color: isHighContrast ? AppColors.hcTextPrimary : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                  ),
                ),
              ),
              FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: isHighContrast ? Colors.black : AppColors.error,
                  foregroundColor: isHighContrast ? AppColors.hcHighAlert : Colors.white,
                  side: isHighContrast ? const BorderSide(color: AppColors.hcHighAlert, width: 2) : null,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: (!confirmIrreversible || isProcessing)
                    ? null
                    : () async {
                        setState(() => isProcessing = true);
                        try {
                          if (userId != null && userId.isNotEmpty) {
                            await ref.read(authControllerProvider.notifier).deleteAccount(userId);
                          } else {
                            await ref.read(authControllerProvider.notifier).signOut();
                          }

                          try {
                            final storage = ref.read(localStorageProvider);
                            await storage.clearUserAuthDetails();
                          } catch (_) {}

                          if (wipeAlertHistory) {
                            try {
                              await ref.read(alertListProvider.notifier).clear();
                            } catch (_) {}
                          }

                          if (ctx.mounted) {
                            Navigator.pop(ctx); // Close dialog
                          }
                          if (context.mounted) {
                            Navigator.of(context).pop(); // Close bottom sheet
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Row(
                                  children: [
                                    Icon(Icons.check_circle_outline_rounded, color: Colors.white, size: 20),
                                    SizedBox(width: 10),
                                    Expanded(
                                      child: Text('Your account and data have been permanently deleted.'),
                                    ),
                                  ],
                                ),
                                backgroundColor: isHighContrast ? Colors.black : AppColors.error,
                                behavior: SnackBarBehavior.floating,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                duration: const Duration(seconds: 4),
                              ),
                            );
                            context.go(AppRoutes.login);
                          }
                        } catch (e) {
                          if (ctx.mounted) {
                            setState(() => isProcessing = false);
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              SnackBar(
                                content: Text('Failed to delete account: $e'),
                                backgroundColor: AppColors.error,
                              ),
                            );
                          }
                        }
                      },
                child: isProcessing
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Delete Account', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBulletItem(String text, bool isHighContrast, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '• ',
            style: TextStyle(
              color: isHighContrast ? AppColors.hcHighAlert : AppColors.error,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 11,
                color: isHighContrast ? Colors.white70 : (isDark ? Colors.white60 : const Color(0xFF64748B)),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
