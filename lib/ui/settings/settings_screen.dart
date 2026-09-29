import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/theme_provider.dart';
import '../../providers/alert_providers.dart';
import '../../providers/audio_providers.dart';
import '../../providers/settings_providers.dart';
import '../history/history_screen.dart';
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
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        children: [
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
                subtitle: const Text('Flash LED on high-priority life safety alarms'),
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
              _buildThemeModeTile(
                context: context,
                ref: ref,
                themeType: themeType,
                isDark: isDark,
                isHighContrast: isHighContrast,
              ),
              _buildQuickThemeSelector(
                context: context,
                ref: ref,
                activeTheme: themeType,
                isDark: isDark,
                isHighContrast: isHighContrast,
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
                  Icons.school_outlined,
                  const Color(0xFF64748B),
                  isDark: isDark,
                  isHighContrast: isHighContrast,
                ),
                title: const Text('Replay Onboarding Tutorial'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(AppRoutes.onboarding),
              ),
              const Divider(height: 1),
              ListTile(
                leading: _buildLeadingIcon(
                  Icons.auto_awesome_rounded,
                  const Color(0xFF64748B),
                  isDark: isDark,
                  isHighContrast: isHighContrast,
                ),
                title: const Text('Preview Animated Splash Screen'),
                subtitle: const Text('Experience the interactive intro & animations'),
                trailing: const Icon(Icons.chevron_right_rounded),
                onTap: () => context.push(AppRoutes.splash),
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
          border: Border.all(color: const Color(0xFF00FF41), width: 1.5),
        ),
        child: Icon(icon, color: const Color(0xFF00FF41), size: 20),
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

  Widget _buildThemeModeTile({
    required BuildContext context,
    required WidgetRef ref,
    required ThemeType themeType,
    required bool isDark,
    required bool isHighContrast,
  }) {
    final theme = Theme.of(context);
    final primaryColor = _getThemePrimaryColor(themeType);
    final swatches = _getThemeSwatches(themeType);

    return InkWell(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      onTap: () => _showThemeDialog(context, ref, themeType),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: isHighContrast
                    ? Colors.black
                    : primaryColor.withValues(alpha: isDark ? 0.22 : 0.14),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: primaryColor,
                  width: isHighContrast ? 2.0 : 1.2,
                ),
              ),
              child: Icon(
                _getThemeIcon(themeType),
                color: primaryColor,
                size: 22,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Theme Mode',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(
                            color: primaryColor.withValues(alpha: 0.4),
                            width: 0.8,
                          ),
                        ),
                        child: Text(
                          _getThemeTag(themeType),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: primaryColor,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 3),
                  Text(
                    _getThemeName(themeType),
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isHighContrast
                          ? const Color(0xFF00FF41)
                          : primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      ...swatches.map((color) => Container(
                            width: 12,
                            height: 12,
                            margin: const EdgeInsets.only(right: 5),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? Colors.white24 : Colors.black12,
                                width: 0.8,
                              ),
                            ),
                          )),
                      const SizedBox(width: 6),
                      Text(
                        'Tap to customize',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickThemeSelector({
    required BuildContext context,
    required WidgetRef ref,
    required ThemeType activeTheme,
    required bool isDark,
    required bool isHighContrast,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
      child: Row(
        children: ThemeType.values.map((type) {
          final isSelected = activeTheme == type;
          final color = _getThemePrimaryColor(type);
          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(10),
                  onTap: () {
                    HapticFeedback.selectionClick();
                    ref.read(themeTypeProvider.notifier).setTheme(type);
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? (isHighContrast
                              ? Colors.black
                              : color.withValues(alpha: isDark ? 0.22 : 0.12))
                          : (isDark
                              ? Colors.white.withValues(alpha: 0.04)
                              : Colors.black.withValues(alpha: 0.03)),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: isSelected
                            ? color
                            : (isHighContrast
                                ? Colors.white24
                                : (isDark ? Colors.white10 : Colors.black12)),
                        width: isSelected ? (isHighContrast ? 2.0 : 1.6) : 1.0,
                      ),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _getThemeIcon(type),
                          size: 18,
                          color: isSelected
                              ? color
                              : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          _getThemeShortName(type),
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: isSelected
                                ? (isHighContrast ? color : (isDark ? Colors.white : color))
                                : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  IconData _getThemeIcon(ThemeType type) {
    switch (type) {
      case ThemeType.light:
        return Icons.light_mode_rounded;
      case ThemeType.dark:
        return Icons.dark_mode_rounded;
      case ThemeType.highContrast:
        return Icons.contrast_rounded;
      case ThemeType.colorBlindSafe:
        return Icons.remove_red_eye_rounded;
    }
  }

  Color _getThemePrimaryColor(ThemeType type) {
    switch (type) {
      case ThemeType.light:
        return const Color(0xFF0062FF);
      case ThemeType.dark:
        return const Color(0xFF38BDF8);
      case ThemeType.highContrast:
        return const Color(0xFF00FF41);
      case ThemeType.colorBlindSafe:
        return const Color(0xFFD81B60);
    }
  }

  String _getThemeTag(ThemeType type) {
    switch (type) {
      case ThemeType.light:
        return 'Daylight';
      case ThemeType.dark:
        return 'OLED';
      case ThemeType.highContrast:
        return 'WCAG AAA';
      case ThemeType.colorBlindSafe:
        return 'Color-Safe';
    }
  }

  String _getThemeShortName(ThemeType type) {
    switch (type) {
      case ThemeType.light:
        return 'Light';
      case ThemeType.dark:
        return 'Dark';
      case ThemeType.highContrast:
        return 'Contrast';
      case ThemeType.colorBlindSafe:
        return 'Color-Safe';
    }
  }

  List<Color> _getThemeSwatches(ThemeType type) {
    switch (type) {
      case ThemeType.light:
        return const [Color(0xFFF8FAFC), Color(0xFF0062FF), Color(0xFFEF4444), Color(0xFF10B981)];
      case ThemeType.dark:
        return const [Color(0xFF070F26), Color(0xFF38BDF8), Color(0xFF818CF8), Color(0xFF10B981)];
      case ThemeType.highContrast:
        return const [Colors.black, Color(0xFF00FF41), Color(0xFFFFD600), Color(0xFF00FFFF)];
      case ThemeType.colorBlindSafe:
        return const [Colors.white, Color(0xFF0077BB), Color(0xFFD81B60), Color(0xFFEE7733)];
    }
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
        title: const Text('About AlertSense'),
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
}
