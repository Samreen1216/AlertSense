import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/app_svg_icons.dart';
import '../../../core/router/app_router.dart';
import '../../../providers/alert_providers.dart';
import '../../../providers/audio_providers.dart';
import '../../../providers/settings_providers.dart';

class ProfileSideNavigation extends ConsumerWidget {
  const ProfileSideNavigation({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProfile = ref.watch(activeProfileProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final profiles = [
      (
        id: 'home',
        title: 'Home',
        subtitle: 'All configured sounds active',
        icon: Icons.home_rounded,
        color: const Color(0xFF0055D4),
      ),
      (
        id: 'sleep',
        title: 'Sleep Mode',
        subtitle: 'Critical safety sounds only (Alarms, sirens, crying)',
        icon: Icons.nightlight_round,
        color: const Color(0xFF8B5CF6),
      ),
      (
        id: 'outdoor',
        title: 'Outdoor',
        subtitle: 'Traffic & siren awareness (Siren, horns, glass)',
        icon: Icons.park_rounded,
        color: const Color(0xFF10B981),
      ),
    ];

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF11192A) : Colors.white,
      surfaceTintColor: Colors.transparent,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(left: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 12),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0055D4).withValues(alpha: 0.12),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.tune_rounded,
                      color: Color(0xFF0055D4),
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sound Profiles',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Switch detection mode',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? Colors.white60 : const Color(0xFF64748B),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    color: isDark ? Colors.white70 : const Color(0xFF64748B),
                    tooltip: 'Close',
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
            ),
            Divider(
              height: 1,
              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            ),
            const SizedBox(height: 12),

            // Profile List
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  ...profiles.map((p) {
                    final isSelected = activeProfile.toLowerCase() == p.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            ref.read(activeProfileProvider.notifier).state = p.id;
                            ref.read(enabledSoundsProvider.notifier).setProfile(p.id);
                            ref.read(userSettingsProvider.notifier).setActiveProfileId(p.id);
                            Navigator.of(context).pop();
                            ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Switched profile to ${p.title}'),
                                behavior: SnackBarBehavior.floating,
                                duration: Duration(seconds: p.id == 'sleep' ? 4 : 2),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                action: p.id == 'sleep'
                                    ? SnackBarAction(
                                        label: 'Open Bedside Clock',
                                        textColor: const Color(0xFF00C6FF),
                                        onPressed: () {
                                          context.push(AppRoutes.sleepMode);
                                        },
                                      )
                                    : null,
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(16),
                          child: Container(
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? (isDark
                                      ? const Color(0xFF1E2D52)
                                      : const Color(0xFFEBF3FE))
                                  : (isDark
                                      ? const Color(0xFF162035)
                                      : const Color(0xFFF8FAFC)),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: isSelected
                                    ? const Color(0xFF0055D4)
                                    : (isDark
                                        ? Colors.white10
                                        : const Color(0xFFE2E8F0)),
                                width: 1.0,
                              ),
                            ),
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Row(
                                  children: [
                                    Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: p.color.withValues(alpha: 0.15),
                                      ),
                                      child: Center(
                                        child: AppSvgIcon(
                                          iconKey: p.id,
                                          size: 22,
                                          color: p.color,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            p.title,
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: isDark
                                                  ? Colors.white
                                                  : const Color(0xFF1E293B),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            p.subtitle,
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: isDark
                                                  ? Colors.white60
                                                  : const Color(0xFF64748B),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    if (isSelected)
                                      const Icon(
                                        Icons.check_circle_rounded,
                                        color: Color(0xFF0055D4),
                                        size: 22,
                                      )
                                    else
                                      Icon(
                                        Icons.circle_outlined,
                                        color: isDark
                                            ? Colors.white24
                                            : const Color(0xFFCBD5E1),
                                        size: 22,
                                      ),
                                  ],
                                ),
                                if (isSelected && p.id == 'sleep') ...[
                                  const SizedBox(height: 10),
                                  InkWell(
                                    onTap: () {
                                      Navigator.of(context).pop();
                                      context.push(AppRoutes.sleepMode);
                                    },
                                    borderRadius: BorderRadius.circular(8),
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                      decoration: BoxDecoration(
                                        color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(8),
                                        border: Border.all(
                                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
                                          width: 1,
                                        ),
                                      ),
                                      child: const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(
                                            Icons.nightlight_round,
                                            size: 15,
                                            color: Color(0xFF8B5CF6),
                                          ),
                                          SizedBox(width: 6),
                                          Text(
                                            'Launch Bedside Screen',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                              color: Color(0xFF8B5CF6),
                                            ),
                                          ),
                                          SizedBox(width: 4),
                                          Icon(
                                            Icons.arrow_forward_rounded,
                                            size: 14,
                                            color: Color(0xFF8B5CF6),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }),
                  const SizedBox(height: 8),

                  // Info card about profiles
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.05)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          size: 16,
                          color: isDark ? Colors.white60 : const Color(0xFF64748B),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Active profile determines which sounds trigger real-time alerts, vibrations, and flash strobe.',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? Colors.white60 : const Color(0xFF64748B),
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Bottom action
            Divider(
              height: 1,
              color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            ),
            Padding(
              padding: const EdgeInsets.all(16),
              child: SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.push(AppRoutes.profileEditor);
                  },
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: const Text('Customize Profiles'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF0055D4),
                    side: const BorderSide(color: Color(0xFF0055D4)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
