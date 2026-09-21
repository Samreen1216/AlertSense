import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_svg_icons.dart';
import '../../core/constants/sound_categories.dart';
import '../../data/models/alert_event.dart';
import '../../providers/alert_providers.dart';
import '../../providers/settings_providers.dart';
import '../../services/sms_service.dart';

class AlertDetailsScreen extends ConsumerWidget {
  final AlertEvent alert;

  const AlertDetailsScreen({super.key, required this.alert});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    SoundCategory? category;
    try {
      category = SoundCategory.values
          .firstWhere((c) => c.name.toLowerCase() == alert.soundCategory.toLowerCase());
    } catch (_) {}

    final label = category?.label ?? alert.soundCategory;
    final priority = alert.priorityLevel.toUpperCase();
    final isHigh = priority == 'HIGH';
    final isMedium = priority == 'MEDIUM';
    final priorityColor = isHigh
        ? const Color(0xFFEF4444)
        : (isMedium ? const Color(0xFFF59E0B) : const Color(0xFF10B981));

    final timeStr = DateFormat.jm().format(alert.timestamp);
    final dateStr = DateFormat.yMMMMd().format(alert.timestamp);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert Details'),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded),
            tooltip: 'Delete Alert',
            onPressed: () {
              ref.read(alertListProvider.notifier).removeAlert(alert.id);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Alert removed from history')),
              );
              context.pop();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Card ──
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E2638)
                      : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: priorityColor.withValues(alpha: 0.4),
                    width: 1.2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: priorityColor.withValues(alpha: 0.12),
                      blurRadius: 18,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    AppSvgIcon(
                      iconKey: alert.soundCategory,
                      size: 72,
                      color: priorityColor,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      label,
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 14, vertical: 5),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.18),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: priorityColor, width: 1.2),
                      ),
                      child: Text(
                        '$priority PRIORITY',
                        style: TextStyle(
                          color: priorityColor,
                          fontWeight: FontWeight.w900,
                          fontSize: 12,
                          letterSpacing: 1.2,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // ── Details Card ──
              Card(
                elevation: 0,
                color: isDark
                    ? const Color(0xFF1E2638)
                    : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                    width: 1.0,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    children: [
                      _DetailRow(
                        icon: Icons.analytics_outlined,
                        label: 'Confidence Score',
                        value: '${(alert.confidence * 100).toStringAsFixed(0)}%',
                        valueColor: priorityColor,
                      ),
                      const Divider(height: 24),
                      _DetailRow(
                        icon: Icons.access_time_rounded,
                        label: 'Time Detected',
                        value: timeStr,
                      ),
                      const Divider(height: 24),
                      _DetailRow(
                        icon: Icons.calendar_today_rounded,
                        label: 'Date',
                        value: dateStr,
                      ),
                      const Divider(height: 24),
                      _DetailRow(
                        icon: Icons.sensors_rounded,
                        label: 'Detection Source',
                        value: alert.source,
                        valueColor: theme.colorScheme.primary,
                      ),
                      const Divider(height: 24),
                      _DetailRow(
                        icon: alert.acknowledged
                            ? Icons.check_circle_rounded
                            : Icons.pending_rounded,
                        label: 'Status',
                        value: alert.acknowledged
                            ? 'Acknowledged (${alert.responseAction ?? "checked"})'
                            : 'Unacknowledged',
                        valueColor: alert.acknowledged
                            ? const Color(0xFF10B981)
                            : Colors.grey,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // ── Actions ──
              if (!alert.acknowledged) ...[
                SizedBox(
                  height: 52,
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF10B981),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    onPressed: () {
                      ref
                          .read(alertListProvider.notifier)
                          .acknowledgeAlert(alert.id, action: 'safe');
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Marked as Safe / Acknowledged')),
                      );
                      context.pop();
                    },
                    icon: const Icon(Icons.check_circle_outline_rounded),
                    label: const Text(
                      'I\'m Safe (Acknowledge)',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
              ],

              // Emergency Dial action
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFEF4444),
                    side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    await SmsService.dialEmergencyNumber('1122');
                    ref
                        .read(alertListProvider.notifier)
                        .acknowledgeAlert(alert.id, action: 'called_emergency');
                  },
                  icon: const Icon(Icons.phone_rounded),
                  label: const Text('Call Emergency Services',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),

              // Alert Family action
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFFE65100),
                    side: const BorderSide(color: Color(0xFFE65100), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    final settings = ref.read(userSettingsProvider);
                    if (settings.emergencyContacts.isNotEmpty) {
                      await SmsService.sendEmergencySms(
                        recipients: settings.emergencyContacts,
                        message: SmsService.emergencyMessage(label),
                      );
                      ref
                          .read(alertListProvider.notifier)
                          .acknowledgeAlert(alert.id, action: 'alerted_family');
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                            content: Text(
                                'No emergency contacts saved in Settings')),
                      );
                    }
                  },
                  icon: const Icon(Icons.sms_rounded),
                  label: const Text('Send SMS to Family',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Row(
      children: [
        Icon(icon, size: 20, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: valueColor ?? theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }
}
