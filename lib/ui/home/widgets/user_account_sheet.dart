import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_svg_icons.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/theme_provider.dart';
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
              borderRadius: BorderRadius.circular(28),
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
    final activeProfile = ref.watch(activeProfileProvider);

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
    final savedId = storage?.getSavedUserId();

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

    final email = (user?.email != null && user!.email!.isNotEmpty)
        ? user!.email!
        : (userProfile?.email.isNotEmpty == true
            ? userProfile!.email
            : (savedEmail?.isNotEmpty == true ? savedEmail! : 'Local Offline Session'));

    final userId = (user?.id != null && user!.id.isNotEmpty)
        ? user!.id
        : (userProfile?.id.isNotEmpty == true
            ? userProfile!.id
            : (savedId?.isNotEmpty == true ? savedId! : 'local_device_session'));

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
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
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
                  borderRadius: BorderRadius.circular(2),
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
                                    borderRadius: BorderRadius.circular(10),
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
                            label: 'Account ID',
                            value: '${user.id.substring(0, 12)}...${user.id.substring(user.id.length - 4)}',
                            icon: Icons.fingerprint_rounded,
                            isDark: isDark,
                            isHighContrast: isHighContrast,
                            trailing: IconButton(
                              icon: const Icon(Icons.copy_rounded, size: 18),
                              tooltip: 'Copy UUID',
                              onPressed: () {
                                Clipboard.setData(ClipboardData(text: user.id));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: const Text('Account ID copied to clipboard'),
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                );
                              },
                            ),
                          ),
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

                    // ── 3. Sound Profiles Integration (Maintains app functionality) ──
                    _buildSectionHeader(
                      context,
                      'SOUND DETECTION PROFILE',
                      Icons.tune_rounded,
                      isDark: isDark,
                      isHighContrast: isHighContrast,
                    ),
                    const SizedBox(height: 8),
                    _buildSoundProfileCard(
                      context: context,
                      activeProfile: activeProfile,
                      isDark: isDark,
                      isHighContrast: isHighContrast,
                    ),
                    const SizedBox(height: 18),

                    // ── 4. App Preferences & Security Shortcuts ──
                    _buildSectionHeader(
                      context,
                      'PREFERENCES & SECURITY',
                      Icons.security_rounded,
                      isDark: isDark,
                      isHighContrast: isHighContrast,
                    ),
                    const SizedBox(height: 8),
                    _buildInfoCard(
                      context: context,
                      isDark: isDark,
                      isHighContrast: isHighContrast,
                      children: [
                        ListTile(
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                          leading: _buildTileIcon(
                            Icons.settings_outlined,
                            const Color(0xFF0062FF),
                            isDark: isDark,
                            isHighContrast: isHighContrast,
                          ),
                          title: const Text('App Settings & Preferences', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                          subtitle: const Text('Sensitivities, notifications, vibrations, strobe flash', style: TextStyle(fontSize: 12)),
                          trailing: const Icon(Icons.chevron_right_rounded),
                          onTap: () {
                            Navigator.of(context).pop();
                            context.push(AppRoutes.settings);
                          },
                        ),
                        if (user != null) ...[
                          const Divider(height: 1),
                          ListTile(
                            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                            leading: _buildTileIcon(
                              Icons.lock_reset_rounded,
                              const Color(0xFFF59E0B),
                              isDark: isDark,
                              isHighContrast: isHighContrast,
                            ),
                            title: const Text('Send Password Reset Email', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                            subtitle: const Text('Receive a secure reset link to change your password', style: TextStyle(fontSize: 12)),
                            trailing: const Icon(Icons.chevron_right_rounded),
                            onTap: () => _handleSendPasswordReset(context, ref, user.email ?? ''),
                          ),
                        ],
                      ],
                    ),
                    const SizedBox(height: 22),

                    // ── 5. Session Actions (Log Out or Sign In) ──
                    if (user != null)
                      FilledButton.icon(
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: const Text('Log Out of AlertSense', style: TextStyle(fontWeight: FontWeight.w700)),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: () => _showLogoutDialog(context, ref),
                      )
                    else
                      FilledButton.icon(
                        icon: const Icon(Icons.login_rounded, size: 18),
                        label: const Text('Sign In or Create Account', style: TextStyle(fontWeight: FontWeight.w700)),
                        style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF0062FF),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
        borderRadius: BorderRadius.circular(20),
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
                    borderRadius: BorderRadius.circular(10),
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

  Widget _buildSoundProfileCard({
    required BuildContext context,
    required String activeProfile,
    required bool isDark,
    required bool isHighContrast,
  }) {
    String profileName;
    Color profileColor;
    String profileDescription;

    switch (activeProfile.toLowerCase()) {
      case 'sleep':
        profileName = 'Sleep Mode Profile';
        profileColor = const Color(0xFF8B5CF6);
        profileDescription = 'Critical safety sounds only (Alarms, sirens, baby crying)';
        break;
      case 'outdoor':
        profileName = 'Outdoor Profile';
        profileColor = const Color(0xFF10B981);
        profileDescription = 'Traffic, siren & vehicle horn acoustic awareness';
        break;
      default:
        profileName = 'Home Profile';
        profileColor = const Color(0xFF0062FF);
        profileDescription = 'All configured acoustic detectors active';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isHighContrast
            ? Colors.black
            : (isDark ? const Color(0xFF1E2638) : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighContrast
              ? AppColors.hcPrimary
              : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
          width: isHighContrast ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: profileColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: profileColor.withValues(alpha: 0.4), width: 1),
                ),
                child: Center(
                  child: AppSvgIcon(
                    iconKey: activeProfile,
                    size: 20,
                    color: profileColor,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profileName,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: isHighContrast
                            ? AppColors.hcTextPrimary
                            : (isDark ? Colors.white : const Color(0xFF0F172A)),
                      ),
                    ),
                    Text(
                      profileDescription,
                      style: TextStyle(
                        fontSize: 11,
                        color: isHighContrast
                            ? AppColors.hcTextSecondary
                            : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            icon: const Icon(Icons.tune_rounded, size: 16),
            label: const Text('Customize Sound Detection Profiles', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
            style: OutlinedButton.styleFrom(
              foregroundColor: isHighContrast ? AppColors.hcPrimary : const Color(0xFF0062FF),
              side: BorderSide(
                color: isHighContrast ? AppColors.hcPrimary : const Color(0xFF0062FF).withValues(alpha: 0.5),
              ),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            ),
            onPressed: () {
              Navigator.of(context).pop();
              context.push(AppRoutes.profileEditor);
            },
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

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Update Profile Name'),
        content: TextField(
          controller: controller,
          autofocus: true,
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
            onPressed: () async {
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
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
            },
            child: const Text('Save'),
          ),
        ],
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      success
                          ? 'Password reset email sent! Please check your inbox.'
                          : 'Failed to send reset link. Please try again.',
                    ),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
}
