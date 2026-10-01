import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/sound_categories.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/theme_provider.dart';
import '../../../data/models/alert_event.dart';
import '../../../providers/alert_providers.dart';
import '../../shared/priority_badge.dart';
import '../../shared/sound_icon.dart';

/// Modal bottom sheet and standalone dialog displaying real-time sound notifications,
/// unread alerts count, quick acknowledgment, and direct navigation to history.
class NotificationCenterSheet extends ConsumerWidget {
  const NotificationCenterSheet({super.key});

  /// Display the notifications modal bottom sheet (or centered dialog on desktop/tablets).
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
              child: const NotificationCenterSheet(),
            ),
          ),
        ),
      );
    }

    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const NotificationCenterSheet(),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertListProvider);
    final unreadAlerts = alerts.where((a) => !a.acknowledged).toList();
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final themeType = ref.watch(themeTypeProvider);
    final isHighContrast = themeType == ThemeType.highContrast;
    final maxHeight = MediaQuery.sizeOf(context).height * 0.85;

    final sheetBg = isHighContrast
        ? Colors.black
        : (isDark ? const Color(0xFF0F172A) : Colors.white);

    final borderColor = isHighContrast
        ? AppColors.hcPrimary
        : (isDark ? Colors.white.withValues(alpha: 0.12) : const Color(0xFFE2E8F0));

    final titleColor = isHighContrast
        ? Colors.white
        : (isDark ? Colors.white : const Color(0xFF0F172A));

    final subtitleColor = isHighContrast
        ? AppColors.hcPrimary
        : (isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B));

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: Border.all(color: borderColor, width: isHighContrast ? 2.0 : 1.0),
        boxShadow: isHighContrast
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.2),
                  blurRadius: 30,
                  offset: const Offset(0, -10),
                ),
              ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Drag Handle Pill ──
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 4.5,
                decoration: BoxDecoration(
                  color: isHighContrast
                      ? AppColors.hcPrimary
                      : (isDark ? Colors.white24 : Colors.black12),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),

            // ── Header Row ──
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 16, 12),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isHighContrast
                          ? Colors.black
                          : const Color(0xFF0072FF).withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isHighContrast
                            ? AppColors.hcPrimary
                            : const Color(0xFF0072FF).withValues(alpha: 0.35),
                        width: 1.5,
                      ),
                    ),
                    child: Icon(
                      unreadAlerts.isNotEmpty
                          ? Icons.notifications_active_rounded
                          : Icons.notifications_rounded,
                      color: isHighContrast
                          ? AppColors.hcPrimary
                          : const Color(0xFF0072FF),
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          crossAxisAlignment: WrapCrossAlignment.center,
                          spacing: 6,
                          runSpacing: 2,
                          children: [
                            Text(
                              'Notifications',
                              style: TextStyle(
                                color: titleColor,
                                fontSize: 18,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (unreadAlerts.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFEF4444),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${unreadAlerts.length} new',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          unreadAlerts.isNotEmpty
                              ? 'Swipe card to delete • Tap to view'
                              : 'All caught up • No unread alerts',
                          style: TextStyle(
                            color: subtitleColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (unreadAlerts.isNotEmpty)
                    TextButton(
                      onPressed: () async {
                        HapticFeedback.selectionClick();
                        for (final alert in unreadAlerts) {
                          await ref
                              .read(alertListProvider.notifier)
                              .acknowledgeAlert(alert.id);
                        }
                      },
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Mark all read',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF0072FF),
                        ),
                      ),
                    ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close_rounded, color: subtitleColor, size: 22),
                    tooltip: 'Close',
                  ),
                ],
              ),
            ),

            const Divider(height: 1, thickness: 1),

            // ── Alert Notifications List or Empty State ──
            Flexible(
              child: alerts.isEmpty
                  ? _buildEmptyState(context, isDark, isHighContrast, titleColor, subtitleColor)
                  : ListView.separated(
                      shrinkWrap: true,
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      itemCount: alerts.length > 8 ? 8 : alerts.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final alert = alerts[index];
                        return _buildNotificationCard(
                          context: context,
                          ref: ref,
                          alert: alert,
                          isDark: isDark,
                          isHighContrast: isHighContrast,
                          titleColor: titleColor,
                          subtitleColor: subtitleColor,
                        );
                      },
                    ),
            ),

            if (alerts.isNotEmpty) ...[
              const Divider(height: 1, thickness: 1),
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 14),
                child: OutlinedButton.icon(
                  onPressed: () async {
                    HapticFeedback.selectionClick();
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (ctx) => AlertDialog(
                        title: const Text('Clear Notifications?'),
                        content: const Text(
                          'This will clear all current notifications from your active list.',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.of(ctx).pop(true),
                            style: TextButton.styleFrom(
                              foregroundColor: const Color(0xFFEF4444),
                            ),
                            child: const Text('Clear All'),
                          ),
                        ],
                      ),
                    );
                    if (confirm == true) {
                      await ref.read(alertListProvider.notifier).clear();
                    }
                  },
                  icon: const Icon(Icons.delete_sweep_rounded, size: 18),
                  label: const Text(
                    'Clear All Notifications',
                    style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: isHighContrast ? AppColors.hcPrimary : const Color(0xFFEF4444),
                    minimumSize: const Size(double.infinity, 44),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    side: BorderSide(
                      color: isHighContrast
                          ? AppColors.hcPrimary
                          : const Color(0xFFEF4444).withValues(alpha: 0.35),
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState(
    BuildContext context,
    bool isDark,
    bool isHighContrast,
    Color titleColor,
    Color subtitleColor,
  ) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: isHighContrast
                    ? Colors.black
                    : (isDark
                        ? Colors.white.withValues(alpha: 0.05)
                        : const Color(0xFFF1F5F9)),
                border: Border.all(
                  color: isHighContrast ? AppColors.hcPrimary : Colors.transparent,
                  width: 2,
                ),
              ),
              child: Icon(
                Icons.notifications_off_outlined,
                size: 36,
                color: isHighContrast
                    ? AppColors.hcPrimary
                    : (isDark ? Colors.white38 : const Color(0xFF94A3B8)),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No Notifications Yet',
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: titleColor,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'AlertSense continuously monitors your environment. Detected hazards and sounds will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: subtitleColor,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotificationCard({
    required BuildContext context,
    required WidgetRef ref,
    required AlertEvent alert,
    required bool isDark,
    required bool isHighContrast,
    required Color titleColor,
    required Color subtitleColor,
  }) {
    final category = SoundCategoryExtension.fromName(alert.soundCategory);
    final cardBg = isHighContrast
        ? Colors.black
        : (alert.acknowledged
            ? (isDark ? const Color(0xFF1E293B).withValues(alpha: 0.6) : const Color(0xFFF8FAFC))
            : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9)));

    final cardBorder = isHighContrast
        ? AppColors.hcPrimary
        : (!alert.acknowledged
            ? const Color(0xFF0072FF).withValues(alpha: 0.45)
            : (isDark ? Colors.white.withValues(alpha: 0.08) : const Color(0xFFE2E8F0)));

    final relativeTime = _formatRelativeTime(alert.timestamp);

    return Dismissible(
      key: ValueKey('notification_dismiss_${alert.id}'),
      direction: DismissDirection.horizontal,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        decoration: BoxDecoration(
          color: isHighContrast ? const Color(0xFFFF453A) : const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
            SizedBox(width: 6),
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
      secondaryBackground: Container(
        margin: const EdgeInsets.symmetric(vertical: 2),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: isHighContrast ? const Color(0xFFFF453A) : const Color(0xFFEF4444),
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Delete',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
            ),
            SizedBox(width: 6),
            Icon(Icons.delete_outline_rounded, color: Colors.white, size: 22),
          ],
        ),
      ),
      onDismissed: (direction) {
        HapticFeedback.mediumImpact();
        ref.read(alertListProvider.notifier).removeAlert(alert.id);
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Removed ${category?.label ?? alert.soundCategory} notification',
            ),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            action: SnackBarAction(
              label: 'Undo',
              textColor: const Color(0xFF00C6FF),
              onPressed: () {
                ref.read(alertListProvider.notifier).addAlert(alert);
              },
            ),
          ),
        );
      },
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () async {
            HapticFeedback.lightImpact();
            if (!alert.acknowledged) {
              await ref.read(alertListProvider.notifier).acknowledgeAlert(alert.id);
            }
            if (context.mounted) {
              Navigator.of(context).pop();
              context.push(AppRoutes.alertDetails, extra: alert);
            }
          },
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: cardBorder, width: !alert.acknowledged ? 1.5 : 1.0),
            ),
            child: Row(
              children: [
                SoundIcon(
                  iconName: alert.soundCategory,
                  color: (category?.color ?? AppColors.emergencySiren).withValues(alpha: 0.25),
                  size: 38,
                  iconSize: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              category?.label ?? alert.soundCategory,
                              style: TextStyle(
                                color: titleColor,
                                fontSize: 15,
                                fontWeight: alert.acknowledged ? FontWeight.w600 : FontWeight.w800,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          PriorityBadge(priority: alert.priorityLevel),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            '${(alert.confidence * 100).toStringAsFixed(0)}% confidence',
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            ' • ',
                            style: TextStyle(color: subtitleColor, fontSize: 12),
                          ),
                          Text(
                            relativeTime,
                            style: TextStyle(
                              color: subtitleColor,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          if (!alert.acknowledged) ...[
                            const Spacer(),
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(
                                color: Color(0xFF0072FF),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatRelativeTime(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inSeconds < 45) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, h:mm a').format(timestamp);
    }
  }
}
