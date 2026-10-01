import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/datasources/local_storage.dart';
import '../../../main.dart';
import '../../../providers/alert_providers.dart';
import '../../../providers/auth_providers.dart';
import 'notification_center_sheet.dart';
import 'user_account_sheet.dart';

class AlertSenseHeader extends StatelessWidget {
  const AlertSenseHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final isNarrow = mediaQuery.size.width < 340;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: [
          // App Logo Squircle
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              gradient: const LinearGradient(
                colors: [Color(0xFF0072FF), Color(0xFF00C6FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0072FF).withValues(alpha: 0.4),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Icon(
                Icons.hearing_rounded,
                color: Colors.white,
                size: 26,
              ),
            ),
          ),
          const SizedBox(width: 12),

          // Title & Subtitle
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'AlertSense',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                  ),
                ),
                if (!isNarrow)
                  Text(
                    'See • Feel • Stay Safe',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.7),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),

          // Action Buttons: Login Account Profile & Notification Center (right side of Avatar)
          const _ProfileAvatarButton(),
          const SizedBox(width: 8),
          const _HeaderNotificationButton(),
        ],
      ),
    );
  }
}

class _ProfileAvatarButton extends ConsumerWidget {
  const _ProfileAvatarButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.valueOrNull;

    LocalStorage? storage;
    try {
      storage = ref.read(localStorageProvider);
    } catch (_) {}

    final savedName = storage?.getSavedUserFullName();
    final savedEmail = storage?.getSavedUserEmail();

    final themeType = ref.watch(themeTypeProvider);
    final isHighContrast = themeType == ThemeType.highContrast;

    final name = profile?.fullName.isNotEmpty == true
        ? profile!.fullName
        : ((user?.userMetadata?['full_name'] as String?)?.trim().isNotEmpty == true
            ? (user!.userMetadata!['full_name'] as String).trim()
            : ((user?.userMetadata?['name'] as String?)?.trim().isNotEmpty == true
                ? (user!.userMetadata!['name'] as String).trim()
                : ((user?.userMetadata?['fullName'] as String?)?.trim().isNotEmpty == true
                    ? (user!.userMetadata!['fullName'] as String).trim()
                    : (savedName?.trim().isNotEmpty == true
                        ? savedName!.trim()
                        : (user?.email?.split('@').first ?? '')))));

    final email = profile?.email.isNotEmpty == true
        ? profile!.email
        : (user?.email ?? savedEmail ?? '');

    String initials = '';
    if (name.isNotEmpty) {
      final parts = name.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
        initials = parts[0][0].toUpperCase();
      }
    }

    final isUserActive = user != null || name.isNotEmpty || email.isNotEmpty;

    final tooltip = isUserActive
        ? (name.isNotEmpty ? 'Account: $name ($email)' : 'User Account ($email)')
        : 'User Account (Guest)';

    final containerBg = isHighContrast
        ? Colors.black
        : (isUserActive ? null : Colors.white.withValues(alpha: 0.12));

    final gradient = (!isHighContrast && isUserActive)
        ? const LinearGradient(
            colors: [Color(0xFF0072FF), Color(0xFF00C6FF)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          )
        : null;

    final borderColor = isHighContrast
        ? AppColors.hcPrimary
        : Colors.white.withValues(alpha: isUserActive ? 0.45 : 0.18);

    final borderWidth = isHighContrast ? 2.0 : (isUserActive ? 1.5 : 1.0);

    return SizedBox(
      width: 48,
      height: 48,
      child: Tooltip(
        message: tooltip,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => UserAccountSheet.show(context),
            borderRadius: BorderRadius.circular(24),
            child: Center(
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: containerBg,
                      gradient: gradient,
                      border: Border.all(
                        color: borderColor,
                        width: borderWidth,
                      ),
                      boxShadow: (!isHighContrast && user != null)
                          ? [
                              BoxShadow(
                                color: const Color(0xFF0072FF).withValues(alpha: 0.35),
                                blurRadius: 6,
                                offset: const Offset(0, 2),
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
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.5,
                              ),
                            )
                          : Icon(
                              Icons.person_rounded,
                              color: isHighContrast ? AppColors.hcPrimary : Colors.white,
                              size: 20,
                            ),
                    ),
                  ),
                  if (user != null)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 11,
                        height: 11,
                        decoration: BoxDecoration(
                          color: AppColors.success,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: const Color(0xFF070F26),
                            width: 2,
                          ),
                        ),
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

class _HeaderNotificationButton extends ConsumerWidget {
  const _HeaderNotificationButton();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertListProvider);
    final unreadCount = alerts.where((a) => !a.acknowledged).length;
    final themeType = ref.watch(themeTypeProvider);
    final isHighContrast = themeType == ThemeType.highContrast;

    final tooltip = unreadCount > 0
        ? 'Notifications ($unreadCount unread)'
        : 'Notifications (All caught up)';

    final badgeLabel = unreadCount > 9 ? '9+' : '$unreadCount';

    return SizedBox(
      width: 48,
      height: 48,
      child: Tooltip(
        message: tooltip,
        child: Semantics(
          label: tooltip,
          button: true,
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () {
                NotificationCenterSheet.show(context);
              },
              borderRadius: BorderRadius.circular(24),
              child: Center(
                child: Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isHighContrast
                            ? Colors.black
                            : Colors.white.withValues(alpha: 0.12),
                        border: Border.all(
                          color: isHighContrast
                              ? AppColors.hcPrimary
                              : Colors.white.withValues(alpha: 0.18),
                          width: isHighContrast ? 2 : 1,
                        ),
                      ),
                      child: Icon(
                        unreadCount > 0
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_rounded,
                        color: isHighContrast
                            ? AppColors.hcPrimary
                            : Colors.white,
                        size: 20,
                      ),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        top: -2,
                        right: -2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1.5),
                          decoration: BoxDecoration(
                            color: isHighContrast ? Colors.yellow : const Color(0xFFEF4444),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: const Color(0xFF070F26),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFEF4444).withValues(alpha: 0.5),
                                blurRadius: 4,
                                offset: const Offset(0, 1),
                              ),
                            ],
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Center(
                            child: Text(
                              badgeLabel,
                              style: TextStyle(
                                color: isHighContrast ? Colors.black : Colors.white,
                                fontSize: 9.5,
                                fontWeight: FontWeight.w900,
                                height: 1.0,
                              ),
                            ),
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
