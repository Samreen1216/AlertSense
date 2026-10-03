import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../providers/audio_providers.dart';
import '../../../providers/device_providers.dart';

/// Shows the educational Bottom Sheet explaining why AlertSense requires
/// background / unrestricted battery permissions for 24/7 acoustic safety,
/// clearly outlining the operational differences between 'Set / Allow' and 'Deny'.
Future<void> showBackgroundMonitoringSheet(
  BuildContext context,
  WidgetRef ref, {
  VoidCallback? onAllowSelected,
  VoidCallback? onForegroundSelected,
}) async {
  final theme = Theme.of(context);
  final themeType = ref.read(themeTypeProvider);
  final isDark = theme.brightness == Brightness.dark;
  final isHighContrast = themeType == ThemeType.highContrast;

  await showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    barrierColor: Colors.black.withValues(alpha: 0.65),
    builder: (ctx) => _BackgroundMonitoringSheetContent(
      isDark: isDark,
      isHighContrast: isHighContrast,
      onAllowSelected: onAllowSelected,
      onForegroundSelected: onForegroundSelected,
    ),
  );
}

class _BackgroundMonitoringSheetContent extends ConsumerStatefulWidget {
  final bool isDark;
  final bool isHighContrast;
  final VoidCallback? onAllowSelected;
  final VoidCallback? onForegroundSelected;

  const _BackgroundMonitoringSheetContent({
    required this.isDark,
    required this.isHighContrast,
    this.onAllowSelected,
    this.onForegroundSelected,
  });

  @override
  ConsumerState<_BackgroundMonitoringSheetContent> createState() =>
      _BackgroundMonitoringSheetContentState();
}

class _BackgroundMonitoringSheetContentState
    extends ConsumerState<_BackgroundMonitoringSheetContent> {
  bool _isLoading = false;

  Future<void> _handleAllow() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('battery_optimization_rationale_seen', true);

    if (widget.onAllowSelected != null) {
      if (mounted) Navigator.pop(context);
      widget.onAllowSelected!();
      return;
    }

    final service = ref.read(deviceServiceProvider);
    final granted = await service.requestIgnoreBatteryOptimizations();
    ref.invalidate(batteryStatusProvider);

    // If listening is not already running, start it
    if (!ref.read(isListeningProvider)) {
      await ref.read(isListeningProvider.notifier).start();
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                granted ? Icons.check_circle_rounded : Icons.info_outline_rounded,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  granted
                      ? '24/7 Background Protection enabled! Alerts will sound when phone is locked.'
                      : 'Foreground mode active. Locked-screen alerts may be delayed by Android.',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor:
              granted ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _handleForegroundOnly() async {
    setState(() => _isLoading = true);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('battery_optimization_rationale_seen', true);

    if (widget.onForegroundSelected != null) {
      if (mounted) Navigator.pop(context);
      widget.onForegroundSelected!();
      return;
    }

    // Start listening in foreground mode
    if (!ref.read(isListeningProvider)) {
      await ref.read(isListeningProvider.notifier).start();
    }

    if (mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.visibility_rounded, color: Colors.white, size: 20),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Monitoring active while app is open. Tap Battery Card below anytime to enable 24/7 alerts.',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          backgroundColor: const Color(0xFF2563EB),
          duration: const Duration(seconds: 4),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusAsync = ref.watch(batteryStatusProvider);
    final isAlreadyWhitelisted = statusAsync.value?.isOptimized ?? false;

    final sheetBg = widget.isHighContrast
        ? Colors.black
        : (widget.isDark ? const Color(0xFF0F1A3A) : Colors.white);

    final borderColor = widget.isHighContrast
        ? AppColors.hcPrimary
        : (widget.isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0));

    final textPrimary = widget.isHighContrast
        ? Colors.white
        : (widget.isDark ? Colors.white : const Color(0xFF0F172A));

    final textSecondary = widget.isHighContrast
        ? AppColors.hcTextSecondary
        : (widget.isDark ? Colors.white.withValues(alpha: 0.7) : const Color(0xFF64748B));

    return Container(
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: Border.all(color: borderColor, width: widget.isHighContrast ? 2 : 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 12,
        bottom: MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: widget.isDark ? Colors.white24 : Colors.black12,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Top Header: Icon + Title + Subtitle
            Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color: isAlreadyWhitelisted
                        ? const Color(0xFF10B981).withValues(alpha: 0.2)
                        : const Color(0xFF00E5FF).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isAlreadyWhitelisted
                          ? const Color(0xFF10B981)
                          : const Color(0xFF00E5FF).withValues(alpha: 0.4),
                      width: 1.5,
                    ),
                  ),
                  child: Icon(
                    isAlreadyWhitelisted
                        ? Icons.verified_user_rounded
                        : Icons.security_rounded,
                    color: isAlreadyWhitelisted
                        ? const Color(0xFF10B981)
                        : const Color(0xFF00E5FF),
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isAlreadyWhitelisted
                            ? '24/7 Protection Active'
                            : 'Background Monitoring Setup',
                        style: TextStyle(
                          color: textPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        isAlreadyWhitelisted
                            ? 'Whitelisted from Android battery restrictions'
                            : 'Continuous safety awareness when phone is locked',
                        style: TextStyle(
                          color: textSecondary,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: Icon(Icons.close_rounded, color: textSecondary, size: 20),
                  tooltip: 'Close',
                ),
              ],
            ),
            const SizedBox(height: 18),

            // When already whitelisted, show confirmed benefits
            if (isAlreadyWhitelisted) ...[
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle_rounded,
                            color: Color(0xFF10B981), size: 18),
                        SizedBox(width: 8),
                        Text(
                          'Fully Configured for Maximum Safety',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AlertSense is whitelisted from Android battery optimizations. Continuous sound detection and instant vibrations run uninterrupted even when the screen is locked or in sleep mode.',
                      style: TextStyle(
                        color: textPrimary,
                        fontSize: 12.5,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: const Text(
                  'Done',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ] else ...[
              // Rationale comparison: SET vs DENY
              Text(
                'Android asks "Let app always run in background?" so life-safety alarms can alert you when your phone is in your pocket or screen is locked:',
                style: TextStyle(
                  color: textSecondary,
                  fontSize: 12.5,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 14),

              // CARD 1: SET / ALLOW (Recommended)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? const Color(0xFF132247)
                      : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFF10B981).withValues(alpha: 0.6),
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.verified_user_rounded,
                            color: Color(0xFF10B981), size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'If you Set / Allow',
                          style: TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFF10B981).withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'RECOMMENDED',
                            style: TextStyle(
                              color: Color(0xFF10B981),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildFeatureBullet(
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: const Color(0xFF10B981),
                      title: '24/7 Locked-Screen Detection',
                      desc:
                          'Monitors surrounding audio continuously even when phone is in your pocket or locked.',
                      textColor: textPrimary,
                      dimColor: textSecondary,
                    ),
                    const SizedBox(height: 6),
                    _buildFeatureBullet(
                      icon: Icons.flash_on_rounded,
                      iconColor: const Color(0xFF10B981),
                      title: 'Immediate Emergency Alerts',
                      desc:
                          'Instant vibrations, screen flash & sound for fire alarms, smoke detectors, and sirens.',
                      textColor: textPrimary,
                      dimColor: textSecondary,
                    ),
                    const SizedBox(height: 6),
                    _buildFeatureBullet(
                      icon: Icons.battery_charging_full_rounded,
                      iconColor: const Color(0xFF10B981),
                      title: 'Ultra-Low Battery Draw',
                      desc: 'Optimized neural DSP uses less than 2% battery per day.',
                      textColor: textPrimary,
                      dimColor: textSecondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),

              // CARD 2: DENY (Foreground Only)
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: widget.isDark
                      ? const Color(0xFF151D2F)
                      : const Color(0xFFFFFBEB),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Color(0xFFF59E0B), size: 18),
                        const SizedBox(width: 8),
                        const Text(
                          'If you Deny',
                          style: TextStyle(
                            color: Color(0xFFF59E0B),
                            fontSize: 13.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Spacer(),
                        Container(
                          padding:
                              const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            'LIMITED FUNCTIONALITY',
                            style: TextStyle(
                              color: Color(0xFFF59E0B),
                              fontSize: 9.5,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _buildFeatureBullet(
                      icon: Icons.check_circle_outline_rounded,
                      iconColor: const Color(0xFF3B82F6),
                      title: 'Accurate while app is open',
                      desc:
                          'Real-time sound detection works accurately whenever AlertSense is on screen.',
                      textColor: textPrimary,
                      dimColor: textSecondary,
                    ),
                    const SizedBox(height: 6),
                    _buildFeatureBullet(
                      icon: Icons.cancel_outlined,
                      iconColor: const Color(0xFFEF4444),
                      title: 'Locked-screen may pause',
                      desc:
                          'Android battery saver will sleep or kill listening when screen is turned off.',
                      textColor: textPrimary,
                      dimColor: textSecondary,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Action Buttons
              if (_isLoading)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 12),
                    child: CircularProgressIndicator(),
                  ),
                )
              else ...[
                // Primary: Allow Background Running
                ElevatedButton.icon(
                  onPressed: _handleAllow,
                  icon: const Icon(Icons.check_circle_rounded, size: 18),
                  label: const Text(
                    'Allow Background Running (Recommended)',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF00E5FF),
                    foregroundColor: const Color(0xFF0B1229),
                    minimumSize: const Size.fromHeight(48),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                const SizedBox(height: 8),

                // Secondary: Continue in Foreground Only
                OutlinedButton.icon(
                  onPressed: _handleForegroundOnly,
                  icon: const Icon(Icons.visibility_outlined, size: 17),
                  label: const Text(
                    'Continue in Foreground Only (Deny)',
                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: textSecondary,
                    side: BorderSide(color: borderColor),
                    minimumSize: const Size.fromHeight(44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureBullet({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String desc,
    required Color textColor,
    required Color dimColor,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(top: 1),
          child: Icon(icon, color: iconColor, size: 14),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: RichText(
            text: TextSpan(
              style: TextStyle(fontSize: 12, height: 1.35, color: dimColor),
              children: [
                TextSpan(
                  text: '$title: ',
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    color: textColor,
                  ),
                ),
                TextSpan(text: desc),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
