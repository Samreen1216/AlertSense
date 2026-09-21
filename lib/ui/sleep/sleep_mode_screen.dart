import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import 'package:intl/intl.dart';
import '../../core/constants/app_svg_icons.dart';
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

  @override
  void initState() {
    super.initState();
    _previousProfile = ref.read(activeProfileProvider);
    ref.read(activeProfileProvider.notifier).state = 'sleep';

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
    ref.read(activeProfileProvider.notifier).state = _previousProfile;
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final isListening = ref.watch(isListeningProvider);

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              const AppSvgIcon(iconKey: 'sleep', size: 76, color: Colors.amberAccent),
              const SizedBox(height: 24),
              Text(
                DateFormat('hh:mm a').format(_currentTime),
                style: const TextStyle(
                  fontSize: 54,
                  color: Colors.white,
                  fontWeight: FontWeight.w300,
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.white12, width: 1.0),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isListening ? Colors.greenAccent : Colors.redAccent,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      isListening ? 'SLEEP GUARDIAN ACTIVE' : 'MONITORING PAUSED',
                      style: const TextStyle(
                        fontSize: 12,
                        color: Colors.white70,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 36),
              const Text(
                'Only Monitoring Life-Safety Alarms:',
                style: TextStyle(fontSize: 14, color: Colors.white54),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const AppSvgIcon(iconKey: 'fireAlarm', size: 18, color: Colors.redAccent),
                  const SizedBox(width: 4),
                  const Text('Fire Alarm', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 12),
                  const AppSvgIcon(iconKey: 'emergencySiren', size: 18, color: Colors.redAccent),
                  const SizedBox(width: 4),
                  const Text('Siren', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                  const SizedBox(width: 12),
                  const AppSvgIcon(iconKey: 'babyCrying', size: 18, color: Colors.amberAccent),
                  const SizedBox(width: 4),
                  const Text('Baby Crying', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w600)),
                ],
              ),
              const SizedBox(height: 16),
              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.vibration_rounded, size: 16, color: Colors.amberAccent),
                  SizedBox(width: 6),
                  Text(
                    'Amplified Vibration Alert for Bedside Tables',
                    style: TextStyle(fontSize: 13, color: Colors.amberAccent),
                  ),
                ],
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: OutlinedButton(
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.amber.shade200,
                    side: BorderSide(color: Colors.amber.shade200, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                  ),
                  onPressed: _exitSleepMode,
                  child: const Text('Exit Sleep Mode', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
