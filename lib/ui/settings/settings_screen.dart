import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/theme_provider.dart';
import '../../data/datasources/local_storage.dart';
import '../../main.dart';
import '../../providers/alert_providers.dart';
import '../../providers/audio_providers.dart';
import '../../providers/auth_providers.dart';
import '../../providers/settings_providers.dart';
import '../history/history_screen.dart';
import '../home/widgets/user_account_sheet.dart';
import 'widgets/theme_appearance_bottom_sheet.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(userSettingsProvider);
    final themeType = ref.watch(themeTypeProvider);
    final textScale = ref.watch(textScaleProvider);
    final enabledSounds = ref.watch(enabledSoundsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isHighContrast = themeType == ThemeType.highContrast;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings & Preferences'),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to Home',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // ── Top Hero Header: Account & Authentication Session ──
          _buildHeroAccountHeader(context, ref),

          // ── Section 1: Sound Detection ──
          _buildSectionHeader(context, 'SOUND DETECTION & PROFILES', Icons.graphic_eq_rounded),
          _buildSettingsCard(
            context,
            children: [
              ListTile(
                leading: _buildLeadingIcon(
                  Icons.category_rounded,
                  const Color(0xFF0062FF),
                  isDark: isDark,
                  isHighContrast: isHighContrast,
                ),
                title: const Text('Manage Sounds'),
                subtitle: Text('${enabledSounds.length} of 9 sounds enabled'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(AppRoutes.soundManagement),
              ),
              const Divider(height: 1),
              ListTile(
                leading: _buildLeadingIcon(
                  Icons.speed_rounded,
                  const Color(0xFF0062FF),
                  isDark: isDark,
                  isHighContrast: isHighContrast,
                ),
                title: const Text('Sensitivity Thresholds'),
                subtitle: const Text('Fine-tune AI confidence per sound category'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(AppRoutes.sensitivity),
              ),
              const Divider(height: 1),
              ListTile(
                leading: _buildLeadingIcon(
                  Icons.tune_rounded,
                  const Color(0xFF0062FF),
                  isDark: isDark,
                  isHighContrast: isHighContrast,
                ),
                title: const Text('Sound Profiles'),
                subtitle: const Text('Configure Home, Sleep, and Outdoor detection modes'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(AppRoutes.profileEditor),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Section 2: Alert Outputs ──
          _buildSectionHeader(context, 'HAPTIC & VISUAL ALERTS', Icons.notifications_active_rounded),
          _buildSettingsCard(
            context,
            children: [
              SwitchListTile(
                secondary: _buildLeadingIcon(
                  Icons.vibration_rounded,
                  const Color(0xFF8B5CF6),
                  isDark: isDark,
                  isHighContrast: isHighContrast,
                ),
                title: const Text('Haptic Vibration'),
                subtitle: const Text('Vibrate phone with distinct coded rhythms'),
                value: settings.vibrationEnabled,
                onChanged: (val) {
                  ref.read(userSettingsProvider.notifier).setVibrationEnabled(val);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: _buildLeadingIcon(
                  Icons.music_note_rounded,
                  const Color(0xFF8B5CF6),
                  isDark: isDark,
                  isHighContrast: isHighContrast,
                ),
                title: const Text('Custom Vibration Designer'),
                subtitle: const Text('Tap screen to record your own vibration patterns'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(AppRoutes.vibrationDesigner),
              ),
              const Divider(height: 1),
              SwitchListTile(
                secondary: _buildLeadingIcon(
                  Icons.flash_on_rounded,
                  const Color(0xFFF59E0B),
                  isDark: isDark,
                  isHighContrast: isHighContrast,
                ),
                title: const Text('Camera Flash Strobe'),
                subtitle: const Text('Flash LED strobe on all sound detections (High, Medium, Low)'),
                value: settings.flashEnabled,
                onChanged: (val) {
                  ref.read(userSettingsProvider.notifier).setFlashEnabled(val);
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: _buildLeadingIcon(
                  Icons.timer_outlined,
                  const Color(0xFFEC4899),
                  isDark: isDark,
                  isHighContrast: isHighContrast,
                ),
                title: const Text('Alert Cooldown & Deduplication'),
                subtitle: const Text('Prevent repeated alarms from spamming notifications'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _showCooldownDialog(context, ref),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Section 3: Visual Accessibility ──
          _buildSectionHeader(context, 'ACCESSIBILITY & APPEARANCE', Icons.accessibility_new_rounded),
          _buildSettingsCard(
            context,
            children: [
              ListTile(
                leading: _buildLeadingIcon(
                  Icons.palette_outlined,
                  const Color(0xFF10B981),
                  isDark: isDark,
                  isHighContrast: isHighContrast,
                ),
                title: const Text('Theme Mode'),
                subtitle: Text(_getThemeName(themeType)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _showThemeDialog(context, ref, themeType),
              ),
              const Divider(height: 1),
              ListTile(
                leading: _buildLeadingIcon(
                  Icons.format_size_rounded,
                  const Color(0xFF10B981),
                  isDark: isDark,
                  isHighContrast: isHighContrast,
                ),
                title: const Text('Font Size & Scaling'),
                subtitle: Text(_getFontScaleName(textScale)),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _showFontScaleDialog(context, ref, textScale),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Section 4: Emergency Contacts ──
          _buildSectionHeader(context, 'SAFETY & EMERGENCY', Icons.health_and_safety_rounded),
          _buildSettingsCard(
            context,
            children: [
              ListTile(
                leading: _buildLeadingIcon(
                  Icons.contact_phone_outlined,
                  const Color(0xFFEF4444),
                  isDark: isDark,
                  isHighContrast: isHighContrast,
                ),
                title: const Text('Emergency Contacts'),
                subtitle: Text(
                  settings.emergencyContacts.isEmpty
                      ? 'No contacts set for auto-SMS'
                      : '${settings.emergencyContacts.length} contact(s) configured',
                ),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(AppRoutes.emergencyContacts),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Section 5: Data Management ──
          _buildSectionHeader(context, 'DATA & STORAGE', Icons.storage_rounded),
          _buildSettingsCard(
            context,
            children: [
              ListTile(
                leading: _buildLeadingIcon(
                  Icons.history_rounded,
                  const Color(0xFF6366F1),
                  isDark: isDark,
                  isHighContrast: isHighContrast,
                ),
                title: const Text('View Alert History'),
                subtitle: const Text('View and export all recorded alerts'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () {
                  try {
                    context.push(AppRoutes.settingsHistory);
                  } catch (_) {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => const HistoryScreen()),
                    );
                  }
                },
              ),
              const Divider(height: 1),
              ListTile(
                leading: _buildLeadingIcon(
                  Icons.delete_sweep_rounded,
                  const Color(0xFFEF4444),
                  isDark: isDark,
                  isHighContrast: isHighContrast,
                ),
                title: const Text('Clear All Alert History', style: TextStyle(color: Colors.red)),
                subtitle: const Text('Permanently erase saved history from local storage'),
                onTap: () {
                  showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Clear History?'),
                      content: const Text('This will delete all saved alerts.'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(ctx),
                          child: const Text('Cancel'),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: Colors.red),
                          onPressed: () {
                            ref.read(alertListProvider.notifier).clear();
                            Navigator.pop(ctx);
                            final messenger = ScaffoldMessenger.of(context);
                            messenger.clearSnackBars();
                            final controller = messenger.showSnackBar(
                              SnackBar(
                                content: const Text('History cleared successfully'),
                                duration: const Duration(seconds: 3),
                                behavior: SnackBarBehavior.floating,
                                margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                            );
                            Timer(const Duration(milliseconds: 3000), () {
                              try {
                                controller.close();
                              } catch (_) {}
                            });
                          },
                          child: const Text('Clear'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Section 6: App Information ──
          _buildSectionHeader(context, 'ABOUT ALERTSENSE', Icons.info_outline_rounded),
          _buildSettingsCard(
            context,
            children: [
              ListTile(
                leading: _buildLeadingIcon(
                  Icons.help_outline_rounded,
                  const Color(0xFF64748B),
                  isDark: isDark,
                  isHighContrast: isHighContrast,
                ),
                title: const Text('User Guide & FAQ'),
                subtitle: const Text('How AlertSense works and troubleshooting'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _showHelpDialog(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: _buildLeadingIcon(
                  Icons.share_rounded,
                  const Color(0xFF0284C7),
                  isDark: isDark,
                  isHighContrast: isHighContrast,
                ),
                title: const Text('Share App'),
                subtitle: const Text('Recommend AlertSense to friends and family'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _shareApp(context),
              ),
              const Divider(height: 1),
              ListTile(
                leading: _buildLeadingIcon(
                  Icons.star_rate_rounded,
                  const Color(0xFFF59E0B),
                  isDark: isDark,
                  isHighContrast: isHighContrast,
                ),
                title: const Text('Rate Us'),
                subtitle: const Text('Rate your experience and support our mission'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => _showRatingDialog(context, ref),
              ),
              const Divider(height: 1),
              ListTile(
                leading: _buildLeadingIcon(
                  Icons.code_rounded,
                  const Color(0xFF64748B),
                  isDark: isDark,
                  isHighContrast: isHighContrast,
                ),
                title: const Text('Version'),
                subtitle: const Text('AlertSense v1.0.0 (On-Device Pure-DSP AI Engine)'),
              ),
            ],
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildLeadingIcon(
    IconData icon,
    Color color, {
    bool isDark = false,
    bool isHighContrast = false,
  }) {
    if (isHighContrast) {
      return Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.hcPrimary, width: 1.5),
        ),
        child: Icon(icon, color: AppColors.hcPrimary, size: 20),
      );
    }
    return Container(
      width: 38,
      height: 38,
      decoration: BoxDecoration(
        color: isDark
            ? color.withValues(alpha: 0.18)
            : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Icon(icon, color: color, size: 20),
    );
  }

  Widget _buildHeroAccountHeader(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    final profileAsync = ref.watch(userProfileProvider);
    final profile = profileAsync.valueOrNull;
    final themeType = ref.watch(themeTypeProvider);
    final isHighContrast = themeType == ThemeType.highContrast;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    LocalStorage? storage;
    try {
      storage = ref.read(localStorageProvider);
    } catch (_) {}

    final savedName = storage?.getSavedUserFullName();
    final savedEmail = storage?.getSavedUserEmail();

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
                        : (user?.email?.split('@').first ?? 'AlertSense User')))));

    final email = profile?.email.isNotEmpty == true
        ? profile!.email
        : (user?.email ?? (savedEmail?.isNotEmpty == true ? savedEmail! : ''));

    final isUserActive = user != null || (savedEmail?.isNotEmpty == true);

    String initials = '';
    if (name.isNotEmpty) {
      final parts = name.trim().split(RegExp(r'\s+'));
      if (parts.length >= 2 && parts[0].isNotEmpty && parts[1].isNotEmpty) {
        initials = '${parts[0][0]}${parts[1][0]}'.toUpperCase();
      } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
        initials = parts[0][0].toUpperCase();
      }
    }

    final heroDecoration = isHighContrast
        ? BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: AppColors.hcPrimary, width: 2.0),
          )
        : BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            gradient: isDark
                ? LinearGradient(
                    colors: [
                      const Color(0xFF1E293B),
                      const Color(0xFF0F172A).withValues(alpha: 0.95),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [
                      Colors.white,
                      Color(0xFFF8FAFC),
                    ],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            border: Border.all(
              color: isDark
                  ? Colors.white.withValues(alpha: 0.12)
                  : const Color(0xFFE2E8F0),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.35)
                    : const Color(0xFF0062FF).withValues(alpha: 0.06),
                blurRadius: 18,
                offset: const Offset(0, 6),
              ),
            ],
          );

    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
      decoration: heroDecoration,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Centered Avatar Hero
          Center(
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                GestureDetector(
                  onTap: () => UserAccountSheet.show(context),
                  child: Container(
                    width: 84,
                    height: 84,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isHighContrast
                          ? Colors.black
                          : (isUserActive ? null : const Color(0xFFE2E8F0)),
                      gradient: (!isHighContrast && isUserActive)
                          ? const LinearGradient(
                              colors: [Color(0xFF0072FF), Color(0xFF00C6FF)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            )
                          : null,
                      border: Border.all(
                        color: isHighContrast
                            ? AppColors.hcPrimary
                            : (isDark
                                ? Colors.white24
                                : const Color(0xFF0072FF).withValues(alpha: 0.25)),
                        width: isHighContrast ? 2.5 : 2.0,
                      ),
                      boxShadow: [
                        if (!isHighContrast && isUserActive)
                          BoxShadow(
                            color: const Color(0xFF0072FF).withValues(alpha: 0.35),
                            blurRadius: 16,
                            offset: const Offset(0, 6),
                          ),
                      ],
                    ),
                    child: Center(
                      child: initials.isNotEmpty
                          ? Text(
                              initials,
                              style: TextStyle(
                                color: isHighContrast ? AppColors.hcPrimary : Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.0,
                              ),
                            )
                          : Icon(
                              Icons.person_rounded,
                              size: 44,
                              color: isHighContrast
                                  ? AppColors.hcPrimary
                                  : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                            ),
                    ),
                  ),
                ),
                // Corner status indicator badge
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    width: 26,
                    height: 26,
                    decoration: BoxDecoration(
                      color: isHighContrast
                          ? Colors.black
                          : (isUserActive ? AppColors.success : const Color(0xFF94A3B8)),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isHighContrast
                            ? AppColors.hcPrimary
                            : (isDark ? const Color(0xFF1E293B) : Colors.white),
                        width: 2.0,
                      ),
                    ),
                    child: Icon(
                      isUserActive ? Icons.check_rounded : Icons.lock_outline_rounded,
                      size: 14,
                      color: isHighContrast ? AppColors.hcPrimary : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // User Name
          Text(
            name.isNotEmpty ? name : 'AlertSense Guest',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.3,
              color: isHighContrast
                  ? Colors.white
                  : (isDark ? Colors.white : const Color(0xFF0F172A)),
            ),
          ),
          const SizedBox(height: 4),

          // User Email or Session Label
          Text(
            email.isNotEmpty
                ? email
                : (isUserActive ? 'Authenticated Session' : 'Offline Guest Session'),
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isHighContrast
                  ? AppColors.hcPrimary
                  : (isDark ? Colors.white70 : const Color(0xFF64748B)),
            ),
          ),
          const SizedBox(height: 12),

          // Status Badge Pill
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: isHighContrast
                  ? Colors.black
                  : (isUserActive
                      ? AppColors.success.withValues(alpha: 0.12)
                      : const Color(0xFF64748B).withValues(alpha: 0.12)),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isHighContrast
                    ? AppColors.hcPrimary
                    : (isUserActive
                        ? AppColors.success.withValues(alpha: 0.35)
                        : const Color(0xFF64748B).withValues(alpha: 0.3)),
                width: 1.0,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isHighContrast
                        ? AppColors.hcPrimary
                        : (isUserActive ? AppColors.success : const Color(0xFF94A3B8)),
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  isUserActive ? 'Active Account Session' : 'Guest Mode',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isHighContrast
                        ? AppColors.hcPrimary
                        : (isUserActive ? AppColors.success : const Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Action Buttons: Manage Account & Log Out
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 44,
                  child: OutlinedButton.icon(
                    style: isHighContrast
                        ? OutlinedButton.styleFrom(
                            foregroundColor: AppColors.hcPrimary,
                            side: const BorderSide(color: AppColors.hcPrimary, width: 1.5),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          )
                        : OutlinedButton.styleFrom(
                            foregroundColor: isDark ? Colors.white : const Color(0xFF0062FF),
                            side: BorderSide(
                              color: isDark
                                  ? Colors.white24
                                  : const Color(0xFF0062FF).withValues(alpha: 0.35),
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          ),
                    onPressed: () => UserAccountSheet.show(context),
                    icon: const Icon(Icons.manage_accounts_rounded, size: 18),
                    label: const Text(
                      'Manage Account',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                height: 44,
                child: isUserActive
                    ? OutlinedButton.icon(
                        style: isHighContrast
                            ? OutlinedButton.styleFrom(
                                foregroundColor: AppColors.hcHighAlert,
                                side: const BorderSide(color: AppColors.hcHighAlert, width: 1.5),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              )
                            : OutlinedButton.styleFrom(
                                foregroundColor: const Color(0xFFEF4444),
                                side: const BorderSide(
                                  color: Color(0xFFEF4444),
                                  width: 1.2,
                                ),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                        onPressed: () => _showLogoutDialog(context, ref),
                        icon: const Icon(Icons.logout_rounded, size: 18),
                        label: const Text(
                          'Log Out',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      )
                    : FilledButton.icon(
                        style: isHighContrast
                            ? FilledButton.styleFrom(
                                backgroundColor: AppColors.hcPrimary,
                                foregroundColor: Colors.black,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              )
                            : FilledButton.styleFrom(
                                backgroundColor: const Color(0xFF0062FF),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              ),
                        onPressed: () => context.push(AppRoutes.login),
                        icon: const Icon(Icons.login_rounded, size: 18),
                        label: const Text(
                          'Sign In',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                      ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(BuildContext context, String title, IconData icon) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 12, 4, 8),
      child: Row(
        children: [
          Icon(icon, size: 16, color: theme.colorScheme.primary),
          const SizedBox(width: 6),
          Text(
            title,
            style: theme.textTheme.labelMedium?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.primary,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsCard(BuildContext context, {required List<Widget> children}) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withValues(alpha: 0.5),
        ),
      ),
      child: Column(children: children),
    );
  }

  String _getThemeName(ThemeType type) {
    switch (type) {
      case ThemeType.light:
        return 'Standard Light';
      case ThemeType.dark:
        return 'Cyber Dark';
      case ThemeType.highContrast:
        return 'High Contrast (AMOLED)';
      case ThemeType.colorBlindSafe:
        return 'Color-Blind Accessible';
    }
  }

  String _getFontScaleName(double scale) {
    if (scale <= 1.0) return 'Standard (100%)';
    if (scale <= 1.25) return 'Large (125%)';
    if (scale <= 1.5) return 'Extra Large (150%)';
    return 'Maximum Accessibility (200%)';
  }

  void _showThemeDialog(BuildContext context, WidgetRef ref, ThemeType current) {
    ThemeAppearanceBottomSheet.show(context);
  }

  void _showFontScaleDialog(BuildContext context, WidgetRef ref, double current) {
    final scales = [1.0, 1.25, 1.5, 2.0];
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Font Size & Scaling'),
        content: RadioGroup<double>(
          groupValue: current,
          onChanged: (selected) {
            if (selected != null) {
              ref.read(textScaleProvider.notifier).setScale(selected);
              Navigator.pop(ctx);
            }
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: scales.map((scale) {
              return RadioListTile<double>(
                title: Text(_getFontScaleName(scale)),
                value: scale,
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  void _showCooldownDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Alert Deduplication'),
        content: const Text(
          'AlertSense automatically collapses repeated sounds into a single persistent alert.\n\n'
          '• High Priority Alarms: 30-second cooldown\n'
          '• Medium Attention Sounds: 15-second cooldown\n'
          '• Low Ambient Sounds: 10-second cooldown\n\n'
          'This prevents constant vibration while keeping you fully protected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Got It'),
          ),
        ],
      ),
    );
  }

  void _showHelpDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                AppAssets.appIcon,
                width: 32,
                height: 32,
                fit: BoxFit.contain,
              ),
            ),
            const SizedBox(width: 12),
            const Text('About AlertSense'),
          ],
        ),
        content: const SingleChildScrollView(
          child: Text(
            'AlertSense is an AI-powered accessibility tool designed specifically for deaf and hard-of-hearing individuals.\n\n'
            'HOW IT WORKS:\n'
            '1. Listens through your microphone in 0.975s audio windows.\n'
            '2. Evaluates environmental acoustics with an on-device neural network.\n'
            '3. Classifies critical sounds: Fire Alarms, Doorbells, Baby Crying, Knocking, etc.\n'
            '4. Translates sound into recognizable vibrations and full-screen flashing alerts.\n\n'
            '100% PRIVATE & OFFLINE:\n'
            'All audio classification runs completely on your device. No audio recordings ever leave your phone.',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Close'),
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
              Navigator.pop(ctx);
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

  void _shareApp(BuildContext context) async {
    final box = context.findRenderObject() as RenderBox?;
    final sharePositionOrigin = box != null
        ? box.localToGlobal(Offset.zero) & box.size
        : null;

    const message =
        'AlertSense - AI Environmental Sound Awareness System\n\n'
        'Turn important sounds like fire alarms, emergency sirens, doorbells, knocks, '
        'and baby crying into visual notifications and custom vibrations!\n\n'
        'Download and explore AlertSense:\n'
        'https://github.com/Samreen1216/AlertSense';

    try {
      await Share.share(
        message,
        subject: 'Check out AlertSense — AI Sound Awareness',
        sharePositionOrigin: sharePositionOrigin,
      );
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open share menu: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _showRatingDialog(BuildContext context, WidgetRef ref) {
    final hostContext = context;
    int selectedRating = 0;
    final feedbackController = TextEditingController();

    showDialog(
      context: hostContext,
      builder: (ctx) => StatefulBuilder(
        builder: (dialogCtx, setState) {
          final isHighContrast = Theme.of(dialogCtx).colorScheme.primary == const Color(0xFF00FF41);
          final starColor = isHighContrast ? const Color(0xFFFFD600) : const Color(0xFFF59E0B);

          String ratingLabel;
          switch (selectedRating) {
            case 5:
              ratingLabel = 'Loved it! ⭐⭐⭐⭐⭐';
              break;
            case 4:
              ratingLabel = 'Great experience! ⭐⭐⭐⭐';
              break;
            case 3:
              ratingLabel = 'It is good, can be better ⭐⭐⭐';
              break;
            case 2:
              ratingLabel = 'Needs improvement ⭐⭐';
              break;
            case 1:
              ratingLabel = 'Did not meet expectations ⭐';
              break;
            default:
              ratingLabel = 'Tap a star to rate';
          }

          final labelColor = selectedRating == 0
              ? (isHighContrast ? Colors.white70 : Colors.grey.shade600)
              : (isHighContrast ? const Color(0xFF00FF41) : starColor);

          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: isHighContrast
                  ? const BorderSide(color: Color(0xFF00FF41), width: 2)
                  : BorderSide.none,
            ),
            title: Row(
              children: [
                Icon(
                  selectedRating == 0 ? Icons.star_outline_rounded : Icons.star_rounded,
                  color: selectedRating == 0
                      ? (isHighContrast ? Colors.white54 : Colors.grey.shade400)
                      : starColor,
                  size: 28,
                ),
                const SizedBox(width: 8),
                const Text('Rate AlertSense'),
              ],
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text(
                    'Your feedback helps us make environmental sound awareness accessible and reliable for everyone.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 13, height: 1.4),
                  ),
                  const SizedBox(height: 18),
                  // Interactive Star Rating Bar (starts empty and uncolored)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (index) {
                      final starIndex = index + 1;
                      final isSelected = starIndex <= selectedRating;
                      return IconButton(
                        iconSize: 34,
                        padding: const EdgeInsets.symmetric(horizontal: 2),
                        icon: Icon(
                          isSelected
                              ? Icons.star_rounded
                              : Icons.star_outline_rounded,
                          color: isSelected
                              ? starColor
                              : (isHighContrast ? Colors.white54 : Colors.grey.shade400),
                        ),
                        onPressed: () {
                          HapticFeedback.selectionClick();
                          setState(() {
                            selectedRating = starIndex;
                          });
                        },
                      );
                    }),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    ratingLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: labelColor,
                    ),
                  ),
                  if (selectedRating > 0) ...[
                    const SizedBox(height: 14),
                    TextField(
                      controller: feedbackController,
                      maxLines: 2,
                      decoration: InputDecoration(
                        hintText: selectedRating < 4
                            ? 'What can we improve? (optional)'
                            : 'What did you like most? (optional)',
                        hintStyle: const TextStyle(fontSize: 12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Maybe Later'),
              ),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: isHighContrast
                      ? const Color(0xFF00FF41)
                      : Theme.of(dialogCtx).colorScheme.primary,
                  foregroundColor: isHighContrast ? Colors.black : Colors.white,
                ),
                icon: const Icon(
                  Icons.check_rounded,
                  size: 16,
                ),
                label: const Text('Submit Feedback'),
                onPressed: selectedRating == 0
                    ? null
                    : () async {
                        final rating = selectedRating;
                        final feedback = feedbackController.text.trim();

                        // Save rating and feedback to local storage
                        try {
                          final prefs = ref.read(sharedPreferencesProvider);
                          await prefs?.setInt('user_app_rating', rating);
                          if (feedback.isNotEmpty) {
                            await prefs?.setString('user_app_feedback', feedback);
                          }
                        } catch (_) {}

                        if (ctx.mounted) {
                          Navigator.pop(ctx);
                        }

                        if (hostContext.mounted) {
                          final messenger = ScaffoldMessenger.of(hostContext);
                          messenger.clearSnackBars();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(
                                rating >= 4
                                    ? 'Thank you for rating AlertSense $rating star${rating > 1 ? 's' : ''}! Your feedback helps us improve.'
                                    : 'Thank you! Your feedback helps us improve AlertSense.',
                              ),
                              duration: const Duration(seconds: 3),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
              ),
            ],
          );
        },
      ),
    );
  }
}
