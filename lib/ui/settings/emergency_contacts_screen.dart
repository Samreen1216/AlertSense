import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/theme_provider.dart';
import '../../providers/settings_providers.dart';

class EmergencyContactsScreen extends ConsumerStatefulWidget {
  const EmergencyContactsScreen({super.key});

  @override
  ConsumerState<EmergencyContactsScreen> createState() => _EmergencyContactsScreenState();
}

class _EmergencyContactsScreenState extends ConsumerState<EmergencyContactsScreen> {
  late List<TextEditingController> _controllers;

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
                    ? const Color(0xFF00FF41)
                    : theme.colorScheme.primary.withValues(alpha: 0.25),
                width: isHighContrast ? 1.5 : 1.0,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.sms_outlined,
                  color: isHighContrast ? const Color(0xFF00FF41) : theme.colorScheme.primary,
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
              color: isHighContrast ? const Color(0xFF00FF41) : null,
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
                          color: isHighContrast ? const Color(0xFF00FF41) : null,
                        ),
                        labelText: 'Contact #${index + 1}',
                        labelStyle: TextStyle(
                          color: isHighContrast ? const Color(0xFF00FF41) : null,
                        ),
                        hintText: '+1 (555) 000-0000',
                        hintStyle: TextStyle(
                          color: isHighContrast ? Colors.white38 : null,
                        ),
                        filled: isHighContrast,
                        fillColor: isHighContrast ? const Color(0xFF111111) : null,
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isHighContrast ? const Color(0xFF00FF41).withValues(alpha: 0.5) : theme.colorScheme.outlineVariant,
                            width: isHighContrast ? 1.5 : 1.0,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(
                            color: isHighContrast ? const Color(0xFF00FF41) : theme.colorScheme.primary,
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
                      color: isHighContrast ? const Color(0xFFFF5252) : Colors.red,
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
                      foregroundColor: const Color(0xFF00FF41),
                      side: const BorderSide(color: Color(0xFF00FF41), width: 1.5),
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
                      backgroundColor: const Color(0xFF00FF41),
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
        ],
      ),
    );
  }
}
