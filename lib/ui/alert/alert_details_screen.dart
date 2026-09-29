import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_svg_icons.dart';
import '../../core/constants/sound_categories.dart';
import '../../core/theme/theme_provider.dart';
import '../../data/models/alert_event.dart';
import '../../providers/alert_providers.dart';
import '../../providers/service_providers.dart';
import '../../providers/settings_providers.dart';
import '../../services/sms_service.dart';
import '../../core/utils/responsive_utils.dart';
import 'widgets/alert_family_choice_dialog.dart';

class AlertDetailsScreen extends ConsumerWidget {
  final AlertEvent alert;

  const AlertDetailsScreen({super.key, required this.alert});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeType = ref.watch(themeTypeProvider);
    final isDark = theme.brightness == Brightness.dark;
    final isHighContrast = themeType == ThemeType.highContrast;

    SoundCategory? category;
    try {
      category = SoundCategory.values
          .firstWhere((c) => c.name.toLowerCase() == alert.soundCategory.toLowerCase());
    } catch (_) {}

    final label = category?.label ?? alert.soundCategory;
    final priority = alert.priorityLevel.toUpperCase();
    final isHigh = priority == 'HIGH';
    final isMedium = priority == 'MEDIUM';

    Color priorityColor;
    if (themeType == ThemeType.colorBlindSafe) {
      priorityColor = isHigh
          ? AppColors.cbSafeHigh
          : (isMedium ? AppColors.cbSafeMedium : AppColors.cbSafeLow);
    } else if (themeType == ThemeType.highContrast) {
      priorityColor = isHigh
          ? AppColors.hcHighAlert
          : (isMedium ? AppColors.hcMediumAlert : AppColors.hcLowAlert);
    } else {
      priorityColor = isHigh
          ? const Color(0xFFEF4444)
          : (isMedium ? const Color(0xFFF59E0B) : const Color(0xFF10B981));
    }

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
              final messenger = ScaffoldMessenger.of(context);
              messenger.clearSnackBars();
              final controller = messenger.showSnackBar(
                SnackBar(
                  content: const Text('Alert removed from history'),
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
              context.pop();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: ResponsiveBreakpoints.maxTabletWidth),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Header Card ──
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: isHighContrast
                      ? Colors.black
                      : (isDark
                          ? AppColors.darkCard
                          : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: priorityColor.withValues(alpha: isHighContrast ? 1.0 : 0.4),
                    width: isHighContrast ? 2.0 : 1.2,
                  ),
                  boxShadow: isHighContrast
                      ? null
                      : [
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
                        color: priorityColor.withValues(alpha: isHighContrast ? 0.25 : 0.18),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: priorityColor, width: isHighContrast ? 1.5 : 1.2),
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
                color: isHighContrast
                    ? Colors.black
                    : (isDark
                        ? AppColors.darkCard
                        : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.35)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isHighContrast
                        ? AppColors.hcPrimary
                        : theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
                    width: isHighContrast ? 1.5 : 1.0,
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
                      final messenger = ScaffoldMessenger.of(context);
                      messenger.clearSnackBars();
                      final controller = messenger.showSnackBar(
                        SnackBar(
                          content: const Text('Marked as Safe / Acknowledged'),
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
                    final success = await SmsService.dialEmergencyNumber('1122');
                    if (context.mounted) {
                      if (success) {
                        ref
                            .read(alertListProvider.notifier)
                            .acknowledgeAlert(alert.id, action: 'called_emergency');
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Could not open phone dialer'),
                            backgroundColor: Colors.red.shade900,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.phone_rounded),
                  label: const Text('Call Emergency Services',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),

              // Alert Family via WhatsApp action
              SizedBox(
                height: 50,
                child: OutlinedButton.icon(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: const Color(0xFF25D366),
                    side: const BorderSide(color: Color(0xFF25D366), width: 1.5),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () async {
                    final settings = ref.read(userSettingsProvider);
                    final contact = settings.emergencyContacts.isNotEmpty
                        ? settings.emergencyContacts.first
                        : null;

                    final loc = await ref.read(locationServiceProvider).getCurrentLocation();
                    final message = SmsService.emergencyMessage(
                      label,
                      location: loc,
                    );

                    final success = await SmsService.sendEmergencyWhatsApp(
                      phoneNumber: contact,
                      message: message,
                    );
                    if (context.mounted) {
                      if (success) {
                        ref
                            .read(alertListProvider.notifier)
                            .acknowledgeAlert(alert.id, action: 'alerted_family_whatsapp');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(contact != null
                                ? 'WhatsApp opened for $contact'
                                : 'WhatsApp alert ready to send'),
                            backgroundColor: const Color(0xFF25D366),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } else {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: const Text('Could not launch WhatsApp'),
                            backgroundColor: Colors.red.shade900,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.chat_rounded),
                  label: const Text('Send WhatsApp to Family',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(height: 12),

              // Alert Family via SMS / Choice action
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
                    final contacts = settings.emergencyContacts;
                    if (contacts.isEmpty) {
                      final messenger = ScaffoldMessenger.of(context);
                      messenger.clearSnackBars();
                      final controller = messenger.showSnackBar(
                        SnackBar(
                          content: const Text(
                              'No emergency contacts saved in Settings'),
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
                      return;
                    }

                    // Show the 2-choice dialog (WhatsApp vs Messages with "JUST ONCE")
                    final choice = await showDialog<AlertChannel>(
                      context: context,
                      barrierDismissible: true,
                      builder: (ctx) => AlertFamilyChoiceDialog(
                        savedContacts: contacts,
                        soundName: label,
                        initialChannel: AlertChannel.sms,
                      ),
                    );

                    if (choice == null || !context.mounted) return;

                    final loc = await ref.read(locationServiceProvider).getCurrentLocation();
                    final message = SmsService.emergencyMessage(
                      label,
                      location: loc,
                    );

                    if (choice == AlertChannel.sms) {
                      await SmsService.sendEmergencySms(
                        recipients: contacts,
                        message: message,
                      );
                      if (context.mounted) {
                        ref
                            .read(alertListProvider.notifier)
                            .acknowledgeAlert(alert.id, action: 'alerted_family');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Messages (SMS) opened for ${contacts.first}'),
                            backgroundColor: const Color(0xFFE65100),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
                    } else if (choice == AlertChannel.whatsapp) {
                      final success = await SmsService.sendEmergencyWhatsApp(
                        phoneNumber: contacts.first,
                        message: message,
                      );
                      if (context.mounted && success) {
                        ref
                            .read(alertListProvider.notifier)
                            .acknowledgeAlert(alert.id, action: 'alerted_family_whatsapp');
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('WhatsApp opened for ${contacts.first}'),
                            backgroundColor: const Color(0xFF25D366),
                            behavior: SnackBarBehavior.floating,
                            duration: const Duration(seconds: 3),
                          ),
                        );
                      }
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
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            value,
            textAlign: TextAlign.end,
            overflow: TextOverflow.ellipsis,
            maxLines: 2,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: valueColor ?? theme.colorScheme.onSurface,
            ),
          ),
        ),
      ],
    );
  }
}
