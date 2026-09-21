import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_svg_icons.dart';
import '../../core/constants/sound_categories.dart';
import '../../providers/alert_providers.dart';
import '../../providers/settings_providers.dart';
import '../../services/sms_service.dart';
import 'widgets/quick_response_card.dart';

class FullScreenAlert extends ConsumerStatefulWidget {
  final Map<String, dynamic> alertData;
  const FullScreenAlert({super.key, required this.alertData});

  @override
  ConsumerState<FullScreenAlert> createState() => _FullScreenAlertState();
}

class _FullScreenAlertState extends ConsumerState<FullScreenAlert>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<Color?> _colorAnimation;
  bool _isSendingSms = false;
  bool _isCalling = false;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);

    _colorAnimation = ColorTween(
      begin: const Color(0xFFB71C1C),
      end: const Color(0xFFD32F2F),
    ).animate(_pulseController);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  // ── Resolve human-readable label from category enum name ────────────────
  String _resolveName(String raw) {
    try {
      return SoundCategory.values.firstWhere((c) => c.name == raw).label;
    } catch (_) {
      return raw;
    }
  }

  // ── Emergency Call ───────────────────────────────────────────────────────
  Future<void> _handleEmergencyCall(String alertId) async {
    // Show a dialog so user can confirm/change the number (supports all countries)
    final controller = TextEditingController(text: '1122');
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white24, width: 1.0),
        ),
        title: const Row(
          children: [
            Icon(Icons.local_phone_rounded, color: Colors.red, size: 28),
            SizedBox(width: 12),
            Text('Emergency Call', style: TextStyle(color: Colors.white, fontSize: 20)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confirm emergency number to dial:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              keyboardType: TextInputType.phone,
              autofocus: true,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\+\-\(\) ]'))],
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.phone, color: Colors.red),
                hintText: 'e.g. 1122 / 115 / 911',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: const Color(0xFF2C2C2C),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Pakistan: 1122 (Rescue) · 115 (Edhi) · 15 (Police)\nUS/Canada: 911 · UK: 999 · EU: 112',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('CALL NOW'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      setState(() => _isCalling = true);
      final number = controller.text.trim().replaceAll(' ', '');
      final success = await SmsService.dialEmergencyNumber(number);
      if (mounted) setState(() => _isCalling = false);

      if (!success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not open dialer for $number'),
            backgroundColor: Colors.red.shade900,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Acknowledge alert
      ref.read(alertListProvider.notifier).acknowledgeAlert(alertId, action: 'called_emergency');
    }
    controller.dispose();
  }

  // ── Alert Family via SMS ─────────────────────────────────────────────────
  Future<void> _handleAlertFamily(String soundName, String alertId) async {
    final settings = ref.read(userSettingsProvider);
    final savedContacts = settings.emergencyContacts;

    if (savedContacts.isNotEmpty) {
      // Has saved contacts → send immediately, show confirmation
      setState(() => _isSendingSms = true);
      final success = await SmsService.sendEmergencySms(
        recipients: savedContacts,
        message: SmsService.emergencyMessage(soundName),
      );
      if (mounted) setState(() => _isSendingSms = false);

      if (mounted) {
        if (success) {
          ref.read(alertListProvider.notifier).acknowledgeAlert(alertId, action: 'alerted_family');
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('SMS sent to ${savedContacts.length} contact(s)'),
              backgroundColor: Colors.green.shade800,
              behavior: SnackBarBehavior.floating,
            ),
          );
        } else {
          // url_launcher returned false — fallback to manual entry
          await _showManualSmsDialog(soundName, alertId, savedContacts);
        }
      }
    } else {
      // No contacts saved → let user enter number right now
      await _showManualSmsDialog(soundName, alertId, []);
    }
  }

  Future<void> _showManualSmsDialog(String soundName, String alertId, List<String> prefill) async {
    final message = SmsService.emergencyMessage(soundName);
    final phoneController = TextEditingController(
      text: prefill.isNotEmpty ? prefill.first : '',
    );
    final messageController = TextEditingController(text: message);

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1A1A),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: const BorderSide(color: Colors.white24, width: 1.0),
        ),
        title: const Row(
          children: [
            Icon(Icons.sms_rounded, color: Color(0xFFE65100), size: 28),
            SizedBox(width: 12),
            Text('Alert Family', style: TextStyle(color: Colors.white, fontSize: 20)),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Phone number to SMS:',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                autofocus: true,
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\+\-\(\) ]'))],
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.phone, color: Color(0xFFE65100)),
                  hintText: 'Enter phone number',
                  hintStyle: const TextStyle(color: Colors.white38),
                  filled: true,
                  fillColor: const Color(0xFF2C2C2C),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE65100)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE65100)),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Message (editable):',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: messageController,
                maxLines: 4,
                style: const TextStyle(color: Colors.white, fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: const Color(0xFF2C2C2C),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Colors.white24),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: () => Navigator.pop(ctx, false),
                child: const Text(
                  'Tip: Save contacts in Settings → Emergency Contacts for one-tap sending.',
                  style: TextStyle(color: Colors.white38, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE65100)),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('SEND SMS'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      final number = phoneController.text.trim();
      final msg = messageController.text.trim();
      if (number.isNotEmpty) {
        setState(() => _isSendingSms = true);
        final success = await SmsService.sendEmergencySms(
          recipients: [number],
          message: msg,
        );
        if (mounted) {
          setState(() => _isSendingSms = false);
          if (success) {
            ref.read(alertListProvider.notifier).acknowledgeAlert(alertId, action: 'alerted_family');
          } else {
            // Last resort: open generic SMS app
            final uri = Uri(scheme: 'sms', path: number, queryParameters: {'body': msg});
            if (await canLaunchUrl(uri)) await launchUrl(uri);
          }
        }
      }
    }

    phoneController.dispose();
    messageController.dispose();
  }

  // ── I'm Safe ────────────────────────────────────────────────────────────
  Future<void> _handleImSafe(String soundName, String alertId) async {
    final settings = ref.read(userSettingsProvider);
    final contacts = settings.emergencyContacts;
    if (contacts.isNotEmpty) {
      setState(() => _isSendingSms = true);
      await SmsService.sendEmergencySms(
        recipients: contacts,
        message: SmsService.safeMessage(soundName),
      );
      if (mounted) setState(() => _isSendingSms = false);
    }
    ref.read(alertListProvider.notifier).acknowledgeAlert(alertId, action: 'safe');
    if (mounted) context.pop();
  }

  @override
  Widget build(BuildContext context) {
    final rawCategory = widget.alertData['soundCategory'] as String? ?? 'fireAlarm';
    final name = _resolveName(rawCategory);
    final confidence = widget.alertData['confidence'] ?? 95;
    final alertId = widget.alertData['id'] as String? ?? '';
    final timestamp = widget.alertData['timestamp'] as DateTime? ?? DateTime.now();

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: AnimatedBuilder(
          animation: _colorAnimation,
          builder: (context, child) {
            return Container(
              width: double.infinity,
              height: double.infinity,
              color: _colorAnimation.value,
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 36.0),
              child: SafeArea(child: child!),
            );
          },
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),

              // SVG Alert Icon
              AppSvgIcon(
                iconKey: rawCategory,
                size: 84,
                color: Colors.white,
              ),
              const SizedBox(height: 16),

              // Badge
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: const Text(
                  'CRITICAL ALERT DETECTED',
                  style: TextStyle(
                    color: Color(0xFFD32F2F),
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.5,
                    fontSize: 14,
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Sound name
              Text(
                name,
                style: const TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              // Confidence + time
              Text(
                '$confidence% Confidence  •  ${DateFormat.jm().format(timestamp)}',
                style: const TextStyle(
                  fontSize: 16,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),

              const Spacer(),

              // ── Action buttons ──────────────────────────────────────────

              // I'm Safe
              QuickResponseCard(
                label: "I'm Safe (False Alarm)",
                icon: Icons.check_circle_outline_rounded,
                color: const Color(0xFF2E7D32),
                isLoading: false,
                onPressed: () => _handleImSafe(name, alertId),
              ),
              const SizedBox(height: 12),

              // Call Emergency
              QuickResponseCard(
                label: _isCalling ? 'Opening dialer…' : 'Call Emergency Services',
                icon: Icons.local_phone_rounded,
                color: const Color(0xFFC62828),
                isLoading: _isCalling,
                onPressed: _isCalling ? null : () => _handleEmergencyCall(alertId),
              ),
              const SizedBox(height: 12),

              // Alert Family
              QuickResponseCard(
                label: _isSendingSms ? 'Sending SMS…' : 'Alert Family via SMS',
                icon: Icons.family_restroom_rounded,
                color: const Color(0xFFE65100),
                isLoading: _isSendingSms,
                onPressed: _isSendingSms ? null : () => _handleAlertFamily(name, alertId),
              ),
              const SizedBox(height: 12),

              // Dismiss
              QuickResponseCard(
                label: 'Acknowledge & Dismiss',
                icon: Icons.close_rounded,
                color: const Color(0xFF424242),
                isLoading: false,
                onPressed: () {
                  if (alertId.isNotEmpty) {
                    ref.read(alertListProvider.notifier).acknowledgeAlert(alertId, action: 'dismissed');
                  }
                  context.pop();
                },
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
