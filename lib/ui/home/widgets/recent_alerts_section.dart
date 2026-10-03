import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_svg_icons.dart';
import '../../../core/constants/sound_categories.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/models/alert_event.dart';
import '../../../providers/alert_providers.dart';
import '../../shared/priority_badge.dart';

/// Clean, dynamic Recent Alerts section displaying real-time alert logs
/// from the original data repository.
class RecentAlertsSection extends ConsumerWidget {
  const RecentAlertsSection({super.key});

  String _formatTimeAgo(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inSeconds < 45) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return DateFormat('MMM d').format(dt);
  }

  SoundCategory _getCategory(String name) {
    return SoundCategoryExtension.fromName(name) ?? SoundCategory.fireAlarm;
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertListProvider);
    final themeType = ref.watch(themeTypeProvider);
    final isHighContrast = themeType == ThemeType.highContrast;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final primaryActionColor = isHighContrast
        ? AppColors.hcPrimary
        : (isDark ? const Color(0xFF38BDF8) : const Color(0xFF0062FF));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        'Recent Alerts',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isHighContrast
                              ? Colors.white
                              : (isDark ? Colors.white : const Color(0xFF0F172A)),
                          letterSpacing: -0.3,
                        ),
                      ),
                    ),
                    if (alerts.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: primaryActionColor.withValues(alpha: isDark ? 0.2 : 0.12),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: primaryActionColor.withValues(alpha: 0.3),
                            width: 1,
                          ),
                        ),
                        child: Text(
                          '${alerts.length}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            color: primaryActionColor,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Semantics(
                label: 'View all alert history',
                button: true,
                child: InkWell(
                  onTap: () => context.push(AppRoutes.history),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'See All',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: primaryActionColor,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 15,
                          color: primaryActionColor,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Dynamic Alert List or Clean Empty State
        if (alerts.isEmpty)
          _EmptyAlertsCard(
            isDark: isDark,
            isHighContrast: isHighContrast,
          )
        else ...[
          ...alerts.take(3).map((alert) {
            final category = _getCategory(alert.soundCategory);
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _RecentAlertTile(
                alert: alert,
                category: category,
                timeAgo: _formatTimeAgo(alert.timestamp),
                isDark: isDark,
                isHighContrast: isHighContrast,
                onTap: () => context.push(AppRoutes.alertDetails, extra: alert),
              ),
            );
          }),
          if (alerts.length > 3)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Center(
                child: TextButton.icon(
                  onPressed: () => context.push(AppRoutes.history),
                  icon: const Icon(Icons.history_rounded, size: 16),
                  label: Text('View all ${alerts.length} alerts in History'),
                  style: TextButton.styleFrom(
                    foregroundColor: primaryActionColor,
                    textStyle: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ),
        ],
      ],
    );
  }
}

class _EmptyAlertsCard extends StatelessWidget {
  final bool isDark;
  final bool isHighContrast;

  const _EmptyAlertsCard({
    required this.isDark,
    required this.isHighContrast,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isHighContrast
            ? const Color(0xFF0D1424)
            : (isDark ? const Color(0xFF111C35) : const Color(0xFFF0FDF4)),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isHighContrast
              ? AppColors.hcPrimary
              : const Color(0xFF10B981).withValues(alpha: isDark ? 0.3 : 0.25),
          width: 1.0,
        ),
        boxShadow: isHighContrast
            ? null
            : [
                BoxShadow(
                  color: isDark
                      ? Colors.black.withValues(alpha: 0.2)
                      : const Color(0xFF10B981).withValues(alpha: 0.06),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: const Color(0xFF10B981).withValues(alpha: 0.18),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: Color(0xFF10B981),
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'No Recent Alerts',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isHighContrast
                        ? Colors.white
                        : (isDark ? Colors.white : const Color(0xFF0F172A)),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Environment is quiet and safe. Sounds will appear here dynamically.',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: isHighContrast
                        ? Colors.white70
                        : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RecentAlertTile extends StatelessWidget {
  final AlertEvent alert;
  final SoundCategory category;
  final String timeAgo;
  final bool isDark;
  final bool isHighContrast;
  final VoidCallback onTap;

  const _RecentAlertTile({
    required this.alert,
    required this.category,
    required this.timeAgo,
    required this.isDark,
    required this.isHighContrast,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final confidencePct = (alert.confidence * 100).toInt();

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        splashColor: category.color.withValues(alpha: 0.1),
        highlightColor: category.color.withValues(alpha: 0.05),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: isHighContrast
                ? const Color(0xFF0D1424)
                : (isDark ? const Color(0xFF111C35) : Colors.white),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isHighContrast
                  ? AppColors.hcPrimary
                  : (isDark
                      ? Colors.white.withValues(alpha: 0.08)
                      : const Color(0xFFE2E8F0)),
              width: 1.0,
            ),
            boxShadow: isHighContrast
                ? null
                : [
                    BoxShadow(
                      color: isDark
                          ? Colors.black.withValues(alpha: 0.25)
                          : const Color(0xFF64748B).withValues(alpha: 0.06),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
          ),
          child: Row(
            children: [
              // Sound Category Icon Avatar
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isHighContrast
                      ? AppColors.hcSurface
                      : category.color.withValues(alpha: isDark ? 0.22 : 0.14),
                  border: Border.all(
                    color: isHighContrast
                        ? AppColors.hcPrimary
                        : category.color.withValues(alpha: 0.35),
                    width: 1.0,
                  ),
                ),
                child: Center(
                  child: AppSvgIcon(
                    iconKey: category.name,
                    size: 22,
                    color: isHighContrast ? AppColors.hcPrimary : category.color,
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Title, Priority & Details
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            category.label,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isHighContrast
                                  ? Colors.white
                                  : (isDark ? Colors.white : const Color(0xFF0F172A)),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        PriorityBadge(priority: alert.priorityLevel),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '$timeAgo • $confidencePct% match${alert.source == 'Quick Scan' ? ' • Quick Scan' : ''}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isHighContrast
                                  ? Colors.white70
                                  : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Chevron
              Icon(
                Icons.chevron_right_rounded,
                size: 20,
                color: isHighContrast
                    ? AppColors.hcPrimary
                    : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
