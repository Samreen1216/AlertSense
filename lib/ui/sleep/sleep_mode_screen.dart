import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_svg_icons.dart';
import '../../core/router/app_router.dart';
import '../../providers/alert_providers.dart';
import '../../providers/audio_providers.dart';

class SleepModeScreen extends ConsumerStatefulWidget {
  const SleepModeScreen({super.key});

  @override
  ConsumerState<SleepModeScreen> createState() => _SleepModeScreenState();
}

class _SleepModeScreenState extends ConsumerState<SleepModeScreen> {
  late Timer _timer;
  DateTime _currentTime = DateTime.now();
  String _previousProfile = 'home';
  bool _profileInitialized = false;

  @override
  void initState() {
    super.initState();

    // Delay provider modification until after the widget tree has built
    // to prevent "Tried to modify a provider while the widget tree was building" assertion.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && !_profileInitialized) {
        _previousProfile = ref.read(activeProfileProvider);
        if (_previousProfile != 'sleep') {
          ref.read(activeProfileProvider.notifier).state = 'sleep';
        }
        // Auto-start listening if not already listening so sleep monitoring is guaranteed active
        if (!ref.read(isListeningProvider)) {
          ref.read(isListeningProvider.notifier).start();
        }
        _profileInitialized = true;
      }
    });

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {
          _currentTime = DateTime.now();
        });
      }
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  void _exitSleepMode() {
    if (mounted) {
      ref.read(activeProfileProvider.notifier).state = _previousProfile;
    }
    if (context.mounted) {
      if (Navigator.of(context).canPop()) {
        Navigator.of(context).pop();
      } else {
        context.go(AppRoutes.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isListening = ref.watch(isListeningProvider);

    return PopScope(
      canPop: true,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop && mounted) {
          ref.read(activeProfileProvider.notifier).state = _previousProfile;
        }
      },
      child: Scaffold(
        backgroundColor: const Color(0xFF090D16),
        body: SafeArea(
          child: LayoutBuilder(
            builder: (context, constraints) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                child: ConstrainedBox(
                  constraints: BoxConstraints(minHeight: constraints.maxHeight),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // ── TOP NAVIGATION BAR ──────────────────────────────────────
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(
                                Icons.arrow_back_rounded,
                                color: Colors.white70,
                                size: 28,
                              ),
                              tooltip: 'Back to Home',
                              onPressed: _exitSleepMode,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Sleep Guardian',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amberAccent.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: Colors.amberAccent.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: const Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.bedtime_rounded, color: Colors.amberAccent, size: 14),
                                  SizedBox(width: 4),
                                  Text(
                                    'BEDSIDE',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.amberAccent,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),

                        // ── MAIN CLOCK & STATUS DISPLAY ─────────────────────────────
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 24.0),
                          child: Column(
                            children: [
                              Container(
                                width: 110,
                                height: 110,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: const Color(0xFF131D31),
                                  border: Border.all(
                                    color: Colors.amberAccent.withValues(alpha: 0.25),
                                    width: 2,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.amberAccent.withValues(alpha: 0.1),
                                      blurRadius: 30,
                                      spreadRadius: 4,
                                    ),
                                  ],
                                ),
                                child: const Center(
                                  child: AppSvgIcon(
                                    iconKey: 'sleep',
                                    size: 58,
                                    color: Colors.amberAccent,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 20),
                              Text(
                                DateFormat('hh:mm a').format(_currentTime),
                                style: const TextStyle(
                                  fontSize: 52,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w300,
                                  letterSpacing: 2,
                                ),
                              ),
                              Text(
                                DateFormat('EEEE, MMMM d').format(_currentTime),
                                style: TextStyle(
                                  fontSize: 14,
                                  color: Colors.white.withValues(alpha: 0.6),
                                  letterSpacing: 0.5,
                                ),
                              ),
                              const SizedBox(height: 18),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 7),
                                decoration: BoxDecoration(
                                  color: isListening
                                      ? const Color(0xFF065F46).withValues(alpha: 0.3)
                                      : const Color(0xFF991B1B).withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(
                                    color: isListening
                                        ? const Color(0xFF10B981).withValues(alpha: 0.5)
                                        : const Color(0xFFEF4444).withValues(alpha: 0.5),
                                    width: 1.0,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        color: isListening
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFFEF4444),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      isListening ? 'SLEEP GUARDIAN ACTIVE' : 'MONITORING PAUSED',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: isListening
                                            ? const Color(0xFF34D399)
                                            : const Color(0xFFF87171),
                                        letterSpacing: 1.2,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (!isListening) ...[
                                const SizedBox(height: 10),
                                TextButton.icon(
                                  onPressed: () {
                                    ref.read(isListeningProvider.notifier).toggle();
                                  },
                                  icon: const Icon(Icons.mic_rounded, color: Color(0xFF34D399), size: 18),
                                  label: const Text(
                                    'Resume Listening',
                                    style: TextStyle(color: Color(0xFF34D399), fontWeight: FontWeight.w600),
                                  ),
                                  style: TextButton.styleFrom(
                                    backgroundColor: const Color(0xFF065F46).withValues(alpha: 0.2),
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                  ),
                                ),
                              ],
                            ],
                          ),
                        ),

                        // ── MONITORING PROFILE DETAILS CARD ─────────────────────────
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFF131D31),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
                          ),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.shield_rounded, color: Colors.amberAccent, size: 20),
                                  const SizedBox(width: 8),
                                  const Text(
                                    'Monitored Life-Safety Alarms',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const Spacer(),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.06),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: const Text(
                                      '3 Active',
                                      style: TextStyle(color: Colors.white70, fontSize: 11),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceAround,
                                children: [
                                  _buildAlarmItem(
                                    iconKey: 'fireAlarm',
                                    label: 'Fire Alarm',
                                    color: Colors.redAccent,
                                  ),
                                  _buildAlarmItem(
                                    iconKey: 'emergencySiren',
                                    label: 'Siren',
                                    color: Colors.redAccent,
                                  ),
                                  _buildAlarmItem(
                                    iconKey: 'babyCrying',
                                    label: 'Baby Crying',
                                    color: Colors.amberAccent,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 16),
                              const Divider(color: Colors.white12, height: 1),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.vibration_rounded, size: 16, color: Colors.amberAccent),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'Amplified vibration alert enabled for bedside tables',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.white.withValues(alpha: 0.7),
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // ── EXIT BUTTON ─────────────────────────────────────────────
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: OutlinedButton.icon(
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.amber.shade200,
                              side: BorderSide(color: Colors.amber.shade300, width: 1.5),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(27)),
                              backgroundColor: Colors.amber.shade400.withValues(alpha: 0.05),
                            ),
                            onPressed: _exitSleepMode,
                            icon: const Icon(Icons.exit_to_app_rounded, size: 20),
                            label: const Text(
                              'Exit Sleep Mode',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 0.5),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildAlarmItem({
    required String iconKey,
    required String label,
    required Color color,
  }) {
    return Column(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.12),
            border: Border.all(color: color.withValues(alpha: 0.3), width: 1.2),
          ),
          child: Center(
            child: AppSvgIcon(iconKey: iconKey, size: 22, color: color),
          ),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
