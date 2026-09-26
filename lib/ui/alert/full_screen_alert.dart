import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_svg_icons.dart';
import '../../core/constants/sound_categories.dart';
import '../../providers/alert_providers.dart';
import '../../providers/service_providers.dart';
import '../../providers/settings_providers.dart';
import '../../services/sms_service.dart';
import 'widgets/alert_family_choice_dialog.dart';
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
  bool _isSending = false;
  bool _isCalling = false;

  // Emergency Uplink Auto-Dispatch (Proposal Section 8)
  int _secondsRemaining = 45;
  Timer? _autoDispatchTimer;
  bool _autoDispatchCancelled = false;
  bool _autoDispatched = false;

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

    // Proposal Section 8: Automatically dispatch SMS alerts if unacknowledged
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _startAutoDispatchCountdown();
    });
  }

  void _startAutoDispatchCountdown() {
    final settings = ref.read(userSettingsProvider);
    if (settings.emergencyContacts.isEmpty) return;

    _autoDispatchTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) return;
      if (_secondsRemaining <= 1) {
        timer.cancel();
        _autoDispatchTimer = null;
        setState(() {
          _secondsRemaining = 0;
          _autoDispatched = true;
        });
        final rawCategory = widget.alertData['soundCategory'] as String? ?? 'fireAlarm';
        final name = _resolveName(rawCategory);
        final alertId = widget.alertData['id'] as String? ?? '';
        _handleAlertFamilySms(name, alertId, isAuto: true);
      } else {
        setState(() => _secondsRemaining--);
      }
    });
  }

  void _stopHardwareAlerts() {
    _autoDispatchTimer?.cancel();
    _autoDispatchTimer = null;
    try {
      ref.read(vibrationServiceProvider).cancel();
    } catch (_) {}
    try {
      ref.read(flashServiceProvider).stopStrobe();
    } catch (_) {}
  }

  @override
  void dispose() {
    _stopHardwareAlerts();
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
    // Show self-contained dialog so user can confirm/change the number safely
    final number = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => const _EmergencyCallDialog(initialNumber: '1122'),
    );

    if (number != null && number.isNotEmpty && mounted) {
      setState(() => _isCalling = true);
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

      // Acknowledge alert & stop active vibrations/flash
      _stopHardwareAlerts();
      ref.read(alertListProvider.notifier).acknowledgeAlert(alertId, action: 'called_emergency');
    }
  }

  // ── Alert Family with 2-Choice Dialog (WhatsApp vs Messages with Just Once) ──
  Future<void> _handleAlertFamilyWithChoice(String soundName, String alertId) async {
    _autoDispatchTimer?.cancel();
    _autoDispatchTimer = null;
    final settings = ref.read(userSettingsProvider);
    final savedContacts = settings.emergencyContacts;

    // Show the interactive dialog with WhatsApp and Messages options
    final choice = await showDialog<AlertChannel>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertFamilyChoiceDialog(
        savedContacts: savedContacts,
        soundName: soundName,
        initialChannel: AlertChannel.whatsapp,
      ),
    );

    if (choice == null || !mounted) return;

    if (choice == AlertChannel.whatsapp) {
      await _handleAlertFamilyWhatsApp(soundName, alertId);
    } else if (choice == AlertChannel.sms) {
      await _handleAlertFamilySms(soundName, alertId);
    }
  }

  // ── Alert Family via WhatsApp ─────────────────────────────────────────────
  Future<void> _handleAlertFamilyWhatsApp(String soundName, String alertId) async {
    _autoDispatchTimer?.cancel();
    _autoDispatchTimer = null;
    final settings = ref.read(userSettingsProvider);
    final savedContacts = settings.emergencyContacts;

    if (savedContacts.isNotEmpty) {
      setState(() => _isSending = true);
      final success = await SmsService.sendEmergencyWhatsApp(
        phoneNumber: savedContacts.first,
        message: SmsService.emergencyMessage(soundName),
      );
      if (mounted) setState(() => _isSending = false);

      if (mounted && success) {
        _stopHardwareAlerts();
        ref.read(alertListProvider.notifier).acknowledgeAlert(
          alertId,
          action: 'alerted_family_whatsapp',
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('WhatsApp alert opened for ${savedContacts.first}'),
            backgroundColor: const Color(0xFF25D366),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      } else if (mounted) {
        await _showManualWhatsAppDialog(soundName, alertId, savedContacts);
      }
    } else {
      await _showManualWhatsAppDialog(soundName, alertId, []);
    }
  }

  Future<void> _showManualWhatsAppDialog(
    String soundName,
    String alertId,
    List<String> prefill,
  ) async {
    final result = await showDialog<({String? phone, String message})>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _ManualWhatsAppDialog(
        initialPhone: prefill.isNotEmpty ? prefill.first : '',
        defaultMessage: SmsService.emergencyMessage(soundName),
      ),
    );

    if (result != null && mounted) {
      setState(() => _isSending = true);
      final success = await SmsService.sendEmergencyWhatsApp(
        phoneNumber: result.phone,
        message: result.message,
      );
      if (mounted) {
        setState(() => _isSending = false);
        if (success) {
          _stopHardwareAlerts();
          ref.read(alertListProvider.notifier).acknowledgeAlert(
            alertId,
            action: 'alerted_family_whatsapp',
          );
        }
      }
    }
  }

  // ── Alert Family via SMS ─────────────────────────────────────────────────
  Future<void> _handleAlertFamilySms(String soundName, String alertId, {bool isAuto = false}) async {
    _autoDispatchTimer?.cancel();
    _autoDispatchTimer = null;
    final settings = ref.read(userSettingsProvider);
    final savedContacts = settings.emergencyContacts;

    if (savedContacts.isNotEmpty) {
      setState(() => _isSending = true);
      final success = await SmsService.sendEmergencySms(
        recipients: savedContacts,
        message: isAuto
            ? 'CRITICAL ALERT: $soundName detected at user location. User is currently unacknowledged. Sent automatically by AlertSense.'
            : SmsService.emergencyMessage(soundName),
      );
      if (mounted) setState(() => _isSending = false);

      if (mounted) {
        if (success) {
          _stopHardwareAlerts();
          ref.read(alertListProvider.notifier).acknowledgeAlert(
            alertId,
            action: isAuto ? 'auto_sms_unacknowledged' : 'alerted_family',
          );
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isAuto
                  ? 'Emergency SMS auto-dispatched to ${savedContacts.length} contact(s)'
                  : 'SMS sent to ${savedContacts.length} contact(s)'),
              backgroundColor: isAuto ? Colors.deepOrange.shade900 : Colors.green.shade800,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          if (!isAuto) {
            await _showManualSmsDialog(soundName, alertId, savedContacts);
          }
        }
      }
    } else {
      if (!isAuto) {
        await _showManualSmsDialog(soundName, alertId, []);
      }
    }
  }

  Future<void> _showManualSmsDialog(String soundName, String alertId, List<String> prefill) async {
    final result = await showDialog<({String phone, String message})>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => _ManualSmsDialog(
        initialPhone: prefill.isNotEmpty ? prefill.first : '',
        defaultMessage: SmsService.emergencyMessage(soundName),
      ),
    );

    if (result != null && mounted) {
      if (result.phone.isNotEmpty) {
        setState(() => _isSending = true);
        final success = await SmsService.sendEmergencySms(
          recipients: [result.phone],
          message: result.message,
        );
        if (mounted) {
          setState(() => _isSending = false);
          if (success) {
            _stopHardwareAlerts();
            ref.read(alertListProvider.notifier).acknowledgeAlert(alertId, action: 'alerted_family');
          }
        }
      }
    }
  }

  // ── I'm Safe ────────────────────────────────────────────────────────────
  Future<void> _handleImSafe(String soundName, String alertId) async {
    _stopHardwareAlerts();
    final settings = ref.read(userSettingsProvider);
    final contacts = settings.emergencyContacts;
    if (contacts.isNotEmpty) {
      setState(() => _isSending = true);
      await SmsService.sendEmergencySms(
        recipients: contacts,
        message: SmsService.safeMessage(soundName),
      );
      if (mounted) setState(() => _isSending = false);
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
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 24.0),
              child: SafeArea(child: child!),
            );
          },
          child: CustomScrollView(
            physics: const BouncingScrollPhysics(),
            slivers: [
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // ── Info section (icon + badge + name + confidence) ──────
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const SizedBox(height: 8),

                        // SVG Alert Icon
                        AppSvgIcon(
                          iconKey: rawCategory,
                          size: 78,
                          color: Colors.white,
                        ),
                        const SizedBox(height: 14),

                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
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
                              fontSize: 13,
                            ),
                          ),
                        ),
                        const SizedBox(height: 14),

                        // Sound name
                        Text(
                          name,
                          style: const TextStyle(
                            fontSize: 30,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 6),

                        // Confidence + time
                        Text(
                          '$confidence% Confidence  •  ${DateFormat.jm().format(timestamp)}',
                          style: const TextStyle(
                            fontSize: 15,
                            color: Colors.white70,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // ── Bottom action area ───────────────────────────────────
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Emergency Auto-Uplink Banner
                        if (ref.watch(userSettingsProvider).emergencyContacts.isNotEmpty)
                          Container(
                            margin: const EdgeInsets.only(bottom: 12),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.35),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _autoDispatched
                                    ? Colors.orangeAccent
                                    : (_autoDispatchCancelled ? Colors.white24 : Colors.amberAccent.withValues(alpha: 0.7)),
                                width: 1.2,
                              ),
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  _autoDispatched
                                      ? Icons.send_rounded
                                      : (_autoDispatchCancelled ? Icons.pause_circle_outline_rounded : Icons.timer_outlined),
                                  color: _autoDispatched
                                      ? Colors.orangeAccent
                                      : (_autoDispatchCancelled ? Colors.white60 : Colors.amberAccent),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _autoDispatched
                                        ? 'Emergency SMS auto-dispatched to family'
                                        : (_autoDispatchCancelled
                                            ? 'Auto-SMS paused'
                                            : 'Auto-SMS to family in ${_secondsRemaining}s if unacknowledged'),
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                                if (!_autoDispatched && !_autoDispatchCancelled)
                                  TextButton(
                                    style: TextButton.styleFrom(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      minimumSize: Size.zero,
                                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      backgroundColor: Colors.white.withValues(alpha: 0.15),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _autoDispatchCancelled = true;
                                        _autoDispatchTimer?.cancel();
                                        _autoDispatchTimer = null;
                                      });
                                    },
                                    child: const Text('Cancel', style: TextStyle(color: Colors.white, fontSize: 11)),
                                  ),
                              ],
                            ),
                          ),

                        // ── Action buttons ───────────────────────────────────

                        // I'm Safe
                        QuickResponseCard(
                          label: "I'm Safe (False Alarm)",
                          icon: Icons.check_circle_outline_rounded,
                          color: const Color(0xFF2E7D32),
                          isLoading: false,
                          onPressed: () => _handleImSafe(name, alertId),
                        ),
                        const SizedBox(height: 10),

                        // Call Emergency
                        QuickResponseCard(
                          label: _isCalling ? 'Opening dialer…' : 'Call Emergency Services',
                          icon: Icons.local_phone_rounded,
                          color: const Color(0xFFC62828),
                          isLoading: _isCalling,
                          onPressed: _isCalling ? null : () => _handleEmergencyCall(alertId),
                        ),
                        const SizedBox(height: 10),

                        // Alert Family (WhatsApp / Messages Dialog with Just Once)
                        QuickResponseCard(
                          label: _isSending ? 'Sending Alert…' : 'Alert Family (WhatsApp / SMS)',
                          icon: Icons.family_restroom_rounded,
                          color: const Color(0xFFE65100),
                          isLoading: _isSending,
                          onPressed: _isSending ? null : () => _handleAlertFamilyWithChoice(name, alertId),
                        ),
                        const SizedBox(height: 10),

                        // Dismiss
                        QuickResponseCard(
                          label: 'Acknowledge & Dismiss',
                          icon: Icons.close_rounded,
                          color: const Color(0xFF424242),
                          isLoading: false,
                          onPressed: () {
                            _stopHardwareAlerts();
                            if (alertId.isNotEmpty) {
                              ref.read(alertListProvider.notifier).acknowledgeAlert(alertId, action: 'dismissed');
                            }
                            context.pop();
                          },
                        ),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


// ─────────────────────────────────────────────────────────────────────────────
// Dedicated Safe Dialog Widgets (prevents controller disposal crash on cancel)
// ─────────────────────────────────────────────────────────────────────────────

class _EmergencyCallDialog extends StatefulWidget {
  final String initialNumber;
  const _EmergencyCallDialog({required this.initialNumber});

  @override
  State<_EmergencyCallDialog> createState() => _EmergencyCallDialogState();
}

class _EmergencyCallDialogState extends State<_EmergencyCallDialog> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNumber);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
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
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confirm emergency number to dial:',
              style: TextStyle(color: Colors.white70),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _controller,
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
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: () {
            final number = _controller.text.trim();
            Navigator.of(context).pop(number.isNotEmpty ? number : null);
          },
          child: const Text('CALL NOW'),
        ),
      ],
    );
  }
}

class _ManualWhatsAppDialog extends StatefulWidget {
  final String initialPhone;
  final String defaultMessage;

  const _ManualWhatsAppDialog({
    required this.initialPhone,
    required this.defaultMessage,
  });

  @override
  State<_ManualWhatsAppDialog> createState() => _ManualWhatsAppDialogState();
}

class _ManualWhatsAppDialogState extends State<_ManualWhatsAppDialog> {
  late final TextEditingController _phoneController;
  late final TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.initialPhone);
    _messageController = TextEditingController(text: widget.defaultMessage);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white24, width: 1.0),
      ),
      title: const Row(
        children: [
          Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 28),
          SizedBox(width: 12),
          Text('Alert via WhatsApp', style: TextStyle(color: Colors.white, fontSize: 20)),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recipient phone number (Optional):',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\+\-\(\) ]'))],
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.phone, color: Color(0xFF25D366)),
                hintText: 'e.g. 0300 1234567 or +92 300 1234567',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF2C2C2C),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF25D366)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF25D366)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Emergency message:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
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
            const SizedBox(height: 10),
            const Text(
              'Tip: You can send directly to a number, or choose any contact/group inside WhatsApp.',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF25D366),
            side: const BorderSide(color: Color(0xFF25D366)),
          ),
          onPressed: () {
            final msg = _messageController.text.trim();
            Navigator.of(context).pop((phone: null, message: msg));
          },
          child: const Text('Choose in WhatsApp'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
          onPressed: () {
            final phone = _phoneController.text.trim();
            final msg = _messageController.text.trim();
            Navigator.of(context).pop((phone: phone.isNotEmpty ? phone : null, message: msg));
          },
          child: const Text('SEND'),
        ),
      ],
    );
  }
}

class _ManualSmsDialog extends StatefulWidget {
  final String initialPhone;
  final String defaultMessage;

  const _ManualSmsDialog({
    required this.initialPhone,
    required this.defaultMessage,
  });

  @override
  State<_ManualSmsDialog> createState() => _ManualSmsDialogState();
}

class _ManualSmsDialogState extends State<_ManualSmsDialog> {
  late final TextEditingController _phoneController;
  late final TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.initialPhone);
    _messageController = TextEditingController(text: widget.defaultMessage);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white24, width: 1.0),
      ),
      title: const Row(
        children: [
          Icon(Icons.sms_rounded, color: Color(0xFFE65100), size: 28),
          SizedBox(width: 12),
          Text('Alert Family via SMS', style: TextStyle(color: Colors.white, fontSize: 20)),
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
              controller: _phoneController,
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
              controller: _messageController,
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
            const Text(
              'Tip: Save contacts in Settings → Emergency Contacts for one-tap sending.',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE65100)),
          onPressed: () {
            final phone = _phoneController.text.trim();
            final msg = _messageController.text.trim();
            if (phone.isNotEmpty) {
              Navigator.of(context).pop((phone: phone, message: msg));
            }
          },
          child: const Text('SEND SMS'),
        ),
      ],
    );
  }
}
