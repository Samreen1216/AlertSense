import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/device_providers.dart';
import '../../../providers/stats_providers.dart';

class QuickStatsGrid extends ConsumerWidget {
  const QuickStatsGrid({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alertsToday = ref.watch(alertsTodayCountProvider);
    final listeningTime = ref.watch(listeningTimeFormattedProvider);
    final batteryAsync = ref.watch(batteryLevelProvider);
    final topSound = ref.watch(topSoundProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final batteryLevel = batteryAsync.value ?? 78;
    final mostFrequentLabel = topSound != null ? topSound['name'] : 'None';

    return LayoutBuilder(
      builder: (context, constraints) {
        return Row(
          children: [
            // Left Column (Alerts Today & Battery Level)
            Expanded(
              child: Column(
                children: [
                  _StatTile(
                    icon: Icons.warning_amber_rounded,
                    iconBg: const Color(0xFFFEE2E2),
                    iconColor: const Color(0xFFEF4444),
                    valueText: '$alertsToday',
                    valueColor: const Color(0xFFEF4444),
                    labelText: 'Alerts Today',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _StatTile(
                    icon: Icons.battery_charging_full_rounded,
                    iconBg: const Color(0xFFDCFCE7),
                    iconColor: const Color(0xFF10B981),
                    valueText: '$batteryLevel%',
                    valueColor: const Color(0xFF10B981),
                    labelText: 'Battery Level',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Right Column (Listening Time & Most Frequent)
            Expanded(
              child: Column(
                children: [
                  _StatTile(
                    icon: Icons.access_time_rounded,
                    iconBg: const Color(0xFFDBEAFE),
                    iconColor: const Color(0xFF0055D4),
                    valueText: listeningTime,
                    valueColor: const Color(0xFF0055D4),
                    labelText: 'Listening Time',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 12),
                  _StatTile(
                    icon: Icons.bar_chart_rounded,
                    iconBg: const Color(0xFFF3E8FF),
                    iconColor: const Color(0xFF8B5CF6),
                    valueText: mostFrequentLabel,
                    valueColor: isDark ? Colors.white : const Color(0xFF1E293B),
                    labelText: 'Most Frequent',
                    isSpecialTitle: true,
                    isDark: isDark,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final String valueText;
  final Color valueColor;
  final String labelText;
  final bool isSpecialTitle;
  final bool isDark;

  const _StatTile({
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.valueText,
    required this.valueColor,
    required this.labelText,
    this.isSpecialTitle = false,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1A2234) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
          width: 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.25)
                : const Color(0xFF64748B).withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isDark ? iconColor.withValues(alpha: 0.2) : iconBg,
            ),
            child: Icon(
              icon,
              size: 18,
              color: iconColor,
            ),
          ),
          const SizedBox(height: 10),
          if (isSpecialTitle) ...[
            Text(
              labelText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              valueText,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
          ] else ...[
            Text(
              valueText,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.w900,
                color: valueColor,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              labelText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white60 : const Color(0xFF64748B),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
