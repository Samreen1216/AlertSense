import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_svg_icons.dart';
import '../../core/constants/sound_categories.dart';
import '../../core/utils/responsive_utils.dart';
import '../../providers/alert_providers.dart';
import '../../providers/service_providers.dart';
import '../../providers/settings_providers.dart';
import '../../services/location_service.dart';
import '../../services/sms_service.dart';
import 'widgets/quick_response_card.dart';
import 'dialogs/emergency_call_dialog.dart';
import 'dialogs/manual_sms_dialog.dart';

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

  // Real-time GPS Location Locking
  LocationResult? _lockedLocation;
  bool _isAcquiringLocation = true;
  Future<LocationResult?>? _gpsFuture;

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
      if (mounted) {
        _startAutoDispatchCountdown();
        _acquireGpsLocation();
      }
    });
  }

  Future<void> _acquireGpsLocation() async {
    if (!mounted) return;
    setState(() => _isAcquiringLocation = true);
    try {
      final future = ref.read(locationServiceProvider).getCurrentLocation(
        timeout: const Duration(seconds: 4),
        useCache: false,
      );
      _gpsFuture = future;
      final loc = await future;
      if (mounted) {
        setState(() {
          _lockedLocation = loc;
          _isAcquiringLocation = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isAcquiringLocation = false);
      }
    }
  }

  Future<LocationResult?> _resolveLocation() async {
    if (_lockedLocation != null) return _lockedLocation;
    if (_gpsFuture != null) {
      try {
        final loc = await _gpsFuture!.timeout(const Duration(seconds: 3));
        if (loc != null) {
          if (mounted) setState(() => _lockedLocation = loc);
          return loc;
        }
      } catch (_) {}
    }
    final loc = await ref.read(locationServiceProvider).getCurrentLocation(
      timeout: const Duration(seconds: 4),
    );
    if (loc != null && mounted) {
      setState(() => _lockedLocation = loc);
    }
    return loc;
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
    final number = await EmergencyCallDialog.show(context, initialNumber: '1122');

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

  // ── Alert Family via SMS ─────────────────────────────────────────────────
  Future<void> _handleAlertFamilySms(String soundName, String alertId, {bool isAuto = false}) async {
    _autoDispatchTimer?.cancel();
    _autoDispatchTimer = null;
    final settings = ref.read(userSettingsProvider);
    final savedContacts = settings.emergencyContacts;

    setState(() => _isSending = true);

    // Acquire GPS location asynchronously with strict fast timeout or reuse pre-locked fix
    final loc = await _resolveLocation();

    final message = isAuto
        ? SmsService.autoDispatchEmergencyMessage(
            soundName,
            location: loc,
          )
        : SmsService.emergencyMessage(
            soundName,
            location: loc,
          );

    if (savedContacts.isNotEmpty) {
      final success = await SmsService.sendEmergencySms(
        recipients: savedContacts,
        message: message,
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
                  ? 'Emergency SMS with location auto-dispatched to ${savedContacts.length} contact(s)'
                  : 'SMS sent to ${savedContacts.length} contact(s)'),
              backgroundColor: isAuto ? Colors.deepOrange.shade900 : Colors.green.shade800,
              behavior: SnackBarBehavior.floating,
              duration: const Duration(seconds: 4),
            ),
          );
        } else {
          if (!isAuto) {
            await _showManualSmsDialog(soundName, alertId, savedContacts, prefilledMessage: message);
          }
        }
      }
    } else {
      if (mounted) setState(() => _isSending = false);
      if (!isAuto) {
        await _showManualSmsDialog(soundName, alertId, [], prefilledMessage: message);
      }
    }
  }

  Future<void> _showManualSmsDialog(
    String soundName,
    String alertId,
    List<String> prefill, {
    String? prefilledMessage,
  }) async {
    final loc = await _resolveLocation();
    if (!mounted) return;
    final defaultMsg = prefilledMessage ?? SmsService.emergencyMessage(soundName, location: loc);
    final result = await ManualSmsDialog.show(
      context,
      initialPhone: prefill.isNotEmpty ? prefill.first : '',
      defaultMessage: defaultMsg,
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

    final isLandscape = ResponsiveBreakpoints.isLandscape(context);

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
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: SafeArea(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(
                      maxWidth: ResponsiveBreakpoints.maxTabletWidth,
                    ),
                    child: isLandscape
                        ? _buildLandscapeContent(
                            rawCategory, name, confidence, timestamp, alertId)
                        : _buildPortraitContent(
                            rawCategory, name, confidence, timestamp, alertId),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPortraitContent(
    String rawCategory,
    String name,
    dynamic confidence,
    DateTime timestamp,
    String alertId,
  ) {
    return CustomScrollView(
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
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'CRITICAL ALERT DETECTED',
                        style: TextStyle(
                          color: Color(0xFFD32F2F),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                          fontSize: 13,
                        ),
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
                  const SizedBox(height: 6),
                  _buildGpsStatusBadge(),
                ],
              ),

              const SizedBox(height: 16),

              // ── Bottom action area ───────────────────────────────────
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildAutoDispatchBanner(),
                  _buildActionButtons(name, alertId),
                  const SizedBox(height: 8),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLandscapeContent(
    String rawCategory,
    String name,
    dynamic confidence,
    DateTime timestamp,
    String alertId,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Left pane: SVG icon (scaled to 54), badge, sound name, confidence, auto-SMS countdown timer
        Expanded(
          flex: 5,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  AppSvgIcon(
                    iconKey: rawCategory,
                    size: 54,
                    color: Colors.white,
                  ),
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        'CRITICAL ALERT DETECTED',
                        style: TextStyle(
                          color: Color(0xFFD32F2F),
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.2,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    name,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$confidence% Confidence  •  ${DateFormat.jm().format(timestamp)}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: Colors.white70,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 4),
                  _buildGpsStatusBadge(),
                  const SizedBox(height: 8),
                  _buildAutoDispatchBanner(),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Right pane: Scrollable list of QuickResponseCard action buttons
        Expanded(
          flex: 6,
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
              child: _buildActionButtons(name, alertId),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildGpsStatusBadge() {
    final hasLoc = _lockedLocation != null;
    final isAcquiring = _isAcquiringLocation;

    Color badgeBg;
    Color borderColor;
    Color iconColor;
    Color textColor;
    String statusText;
    IconData icon;

    if (isAcquiring) {
      badgeBg = Colors.black.withValues(alpha: 0.35);
      borderColor = Colors.amberAccent.withValues(alpha: 0.4);
      iconColor = Colors.amberAccent;
      textColor = Colors.white;
      statusText = 'Acquiring GPS location…';
      icon = Icons.location_searching_rounded;
    } else if (hasLoc) {
      badgeBg = const Color(0xFF1B5E20).withValues(alpha: 0.65);
      borderColor = const Color(0xFF69F0AE).withValues(alpha: 0.6);
      iconColor = const Color(0xFF69F0AE);
      textColor = Colors.white;
      statusText = '📍 GPS Location Locked (${_lockedLocation!.formattedAccuracy})';
      icon = Icons.location_on_rounded;
    } else {
      badgeBg = Colors.black.withValues(alpha: 0.35);
      borderColor = Colors.white24;
      iconColor = Colors.white54;
      textColor = Colors.white70;
      statusText = '📍 GPS Offline';
      icon = Icons.location_off_rounded;
    }

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: badgeBg,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: borderColor,
          width: 1.2,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isAcquiring)
            const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Colors.amberAccent,
              ),
            )
          else
            Icon(icon, color: iconColor, size: 15),
          const SizedBox(width: 7),
          Flexible(
            child: Text(
              statusText,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          if (!isAcquiring && !hasLoc) ...[
            const SizedBox(width: 8),
            GestureDetector(
              onTap: _acquireGpsLocation,
              child: const Text(
                'Retry',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Colors.amberAccent,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildAutoDispatchBanner() {
    if (ref.watch(userSettingsProvider).emergencyContacts.isEmpty) {
      return const SizedBox.shrink();
    }
    return Container(
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
    );
  }

  Widget _buildActionButtons(String name, String alertId) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
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

        // Alert Family (SMS)
        QuickResponseCard(
          label: _isSending ? 'Sending Alert…' : 'Alert Family (SMS)',
          icon: Icons.family_restroom_rounded,
          color: const Color(0xFFE65100),
          isLoading: _isSending,
          onPressed: _isSending ? null : () => _handleAlertFamilySms(name, alertId),
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
      ],
    );
  }
}
