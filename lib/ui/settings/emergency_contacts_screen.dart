import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/theme_provider.dart';
import '../../providers/service_providers.dart';
import '../../providers/settings_providers.dart';
import '../../services/location_service.dart';
import '../../services/sms_service.dart';

class EmergencyContactsScreen extends ConsumerStatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  ConsumerState<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends ConsumerState<EmergencyContactsScreen> {
  late List<TextEditingController> _controllers;
  bool _isTestingGps = false;

  @override
  void initState() {
    super.initState();
    final contacts = ref.read(userSettingsProvider).emergencyContacts;
    _controllers = contacts.map((c) => TextEditingController(text: c)).toList();
    if (_controllers.isEmpty) {
      _controllers.add(TextEditingController());
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  void _save() {
    final numbers = _controllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    ref.read(userSettingsProvider.notifier).setEmergencyContacts(numbers);
    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    final controller = messenger.showSnackBar(
      SnackBar(
        content: const Text('Emergency contacts saved successfully!'),
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
  }

  Future<void> _testEmergencySosMessage() async {
    final numbers = _controllers
        .map((c) => c.text.trim())
        .where((text) => text.isNotEmpty)
        .toList();

    if (numbers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Please enter at least one emergency contact number first.'),
          backgroundColor: Colors.orange.shade800,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final targetContact = numbers.first;
    setState(() => _isTestingGps = true);

    LocationResult? location;
    try {
      location = await ref.read(locationServiceProvider).getCurrentLocation(
        timeout: const Duration(seconds: 4),
        useCache: false,
      );
    } catch (_) {}

    if (!mounted) return;
    setState(() => _isTestingGps = false);

    final testMessage = SmsService.emergencyMessage(
      'Smoke Alarm (TEST)',
      location: location,
    );

    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E222D) : Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(
              color: isDark ? Colors.white12 : Colors.black12,
              width: 1.0,
            ),
          ),
          titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
          contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
          actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.gps_fixed_rounded,
                  color: Colors.redAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Text(
                  'Emergency SOS Test',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // GPS Status Pill
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: location != null
                        ? Colors.green.withValues(alpha: 0.15)
                        : Colors.orange.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: location != null ? Colors.green : Colors.orange,
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        location != null ? Icons.location_on_rounded : Icons.location_off_rounded,
                        color: location != null ? Colors.green : Colors.orange,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          location != null
                              ? 'GPS Locked: ${location.latitude.toStringAsFixed(4)}, ${location.longitude.toStringAsFixed(4)} (${location.formattedAccuracy})'
                              : 'GPS Not Locked (Sending without Pin)',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: location != null
                                ? (isDark ? Colors.greenAccent : Colors.green.shade800)
                                : (isDark ? Colors.orangeAccent : Colors.orange.shade800),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Text(
                  'Target: $targetContact',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Message Preview:',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF272B37) : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: isDark ? Colors.white12 : Colors.black12,
                    ),
                  ),
                  child: SelectableText(
                    testMessage,
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: isDark ? Colors.white70 : Colors.black87,
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF25D366),
                side: const BorderSide(color: Color(0xFF25D366)),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.chat_rounded, size: 18),
              label: const Text('WhatsApp'),
              onPressed: () {
                Navigator.of(ctx).pop();
                SmsService.sendEmergencyWhatsApp(
                  phoneNumber: targetContact,
                  message: testMessage,
                );
              },
            ),
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFFE65100),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              icon: const Icon(Icons.sms_rounded, size: 18),
              label: const Text('Send SMS'),
              onPressed: () {
                Navigator.of(ctx).pop();
                SmsService.sendEmergencySms(
                  recipients: [targetContact],
                  message: testMessage,
                );
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final themeType = ref.watch(themeTypeProvider);
    final isDark = theme.brightness == Brightness.dark;
    final isHighContrast = themeType == ThemeType.highContrast;

    return Scaffold(
      backgroundColor: isHighContrast ? Colors.black : null,
      appBar: AppBar(
        title: const Text('Emergency Contacts'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          tooltip: 'Back to Home',
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            } else {
              context.go(AppRoutes.home);
            }
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check_rounded),
            tooltip: 'Save Contacts',
            onPressed: _save,
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(20.0),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: isHighContrast
                  ? Colors.black
                  : (isDark
                      ? const Color(0xFF1E2638)
                      : theme.colorScheme.primaryContainer.withValues(alpha: 0.3)),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: isHighContrast
                    ? AppColors.hcPrimary
                    : theme.colorScheme.primary.withValues(alpha: 0.25),
                width: isHighContrast ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.sms_outlined,
                  color: isHighContrast ? AppColors.hcPrimary : theme.colorScheme.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'When a critical alarm fires, you can send one-tap SMS messages to these contacts directly from the alert overlay.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: isHighContrast ? Colors.white : null,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Trusted Phone Numbers',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: isHighContrast ? Colors.white : null,
            ),
          ),
          const SizedBox(height: 12),
          ..._controllers.asMap().entries.map((entry) {
            final index = entry.key;
            final controller = entry.value;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      keyboardType: TextInputType.phone,
                      style: TextStyle(
                        color: isHighContrast ? Colors.white : null,
                      ),
                      decoration: InputDecoration(
                        prefixIcon: Icon(
                          Icons.phone_outlined,
                          color: isHighContrast ? AppColors.hcPrimary : null,
                        ),
                        labelText: 'Contact #${index + 1}',
                        labelStyle: TextStyle(
                          color: isHighContrast ? AppColors.hcPrimary : null,
                        ),
                        hintText: '+1 (555) 000-0000',
                        hintStyle: TextStyle(
                          color: isHighContrast ? Colors.white38 : null,
                        ),
                        filled: isHighContrast,
                        fillColor: isHighContrast ? AppColors.hcSurface : null,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isHighContrast ? AppColors.hcPrimary.withValues(alpha: 0.5) : theme.colorScheme.outlineVariant,
                            width: isHighContrast ? 1.5 : 1.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isHighContrast ? AppColors.hcPrimary : theme.colorScheme.primary,
                            width: 2.0,
                          ),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.remove_circle_outline,
                      color: isHighContrast ? AppColors.hcHighAlert : Colors.red,
                    ),
                    tooltip: 'Remove',
                    onPressed: () {
                      setState(() {
                        _controllers[index].dispose();
                        _controllers.removeAt(index);
                      });
                    },
                  ),
                ],
              ),
            );
          }),
          const SizedBox(height: 12),
          SizedBox(
            height: 48,
            child: OutlinedButton.icon(
              style: isHighContrast
                  ? OutlinedButton.styleFrom(
                      foregroundColor: AppColors.hcPrimary,
                      side: const BorderSide(color: AppColors.hcPrimary, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    )
                  : OutlinedButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
              onPressed: () {
                setState(() {
                  _controllers.add(TextEditingController());
                });
              },
              icon: const Icon(Icons.add_rounded),
              label: const Text('Add Another Contact'),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: FilledButton.icon(
              style: isHighContrast
                  ? FilledButton.styleFrom(
                      backgroundColor: AppColors.hcPrimary,
                      foregroundColor: Colors.black,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    )
                  : FilledButton.styleFrom(
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
              onPressed: _save,
              icon: const Icon(Icons.save_rounded),
              label: const Text(
                'Save Contacts',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 50,
            child: OutlinedButton.icon(
              style: isHighContrast
                  ? OutlinedButton.styleFrom(
                      foregroundColor: AppColors.hcPrimary,
                      side: const BorderSide(color: AppColors.hcPrimary, width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    )
                  : OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFFEF4444),
                      side: const BorderSide(color: Color(0xFFEF4444), width: 1.5),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
              onPressed: _isTestingGps ? null : _testEmergencySosMessage,
              icon: _isTestingGps
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFFEF4444)),
                    )
                  : const Icon(Icons.gps_fixed_rounded),
              label: Text(
                _isTestingGps
                    ? 'Acquiring GPS Fix…'
                    : 'Test Emergency SOS Message (with GPS)',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
