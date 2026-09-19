import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/device_service.dart';
import 'audio_providers.dart';

final deviceServiceProvider = Provider<DeviceService>((ref) {
  return DeviceService();
});

/// Polled physical battery level (percentage 0-100).
final batteryLevelProvider = FutureProvider<int?>((ref) async {
  final service = ref.watch(deviceServiceProvider);
  final level = await service.getBatteryLevel();
  return level;
});

class BatteryStatus {
  final String title;
  final String subtitle;
  final bool isOptimized;
  final bool requiresAction;

  const BatteryStatus({
    required this.title,
    required this.subtitle,
    required this.isOptimized,
    this.requiresAction = false,
  });
}

/// Dynamic battery / background optimization status.
final batteryStatusProvider = FutureProvider<BatteryStatus>((ref) async {
  final service = ref.watch(deviceServiceProvider);
  final isIgnoring = await service.isIgnoringBatteryOptimizations();

  if (isIgnoring) {
    return const BatteryStatus(
      title: 'Battery Optimized',
      subtitle: 'Running in background',
      isOptimized: true,
    );
  } else {
    return const BatteryStatus(
      title: 'Background Active',
      subtitle: 'Tap to optimize battery',
      isOptimized: false,
      requiresAction: true,
    );
  }
});

/// Tracks and formats total listening time for the current calendar day.
class ListeningDurationNotifier extends StateNotifier<int> {
  final Ref _ref;
  Timer? _timer;
  SharedPreferences? _prefs;

  ListeningDurationNotifier(this._ref) : super(0) {
    _init();
  }

  String get _todayKey {
    final now = DateTime.now();
    return 'listening_sec_${now.year}_${now.month}_${now.day}';
  }

  Future<void> _init() async {
    _prefs = await SharedPreferences.getInstance();
    state = _prefs?.getInt(_todayKey) ?? 0;

    _ref.listen<bool>(isListeningProvider, (prev, isListening) {
      if (isListening) {
        _startTimer();
      } else {
        _stopTimer();
      }
    });

    if (_ref.read(isListeningProvider)) {
      _startTimer();
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      state = state + 1;
      if (state % 15 == 0) {
        _prefs?.setInt(_todayKey, state);
      }
    });
  }

  void _stopTimer() {
    _timer?.cancel();
    _timer = null;
    _prefs?.setInt(_todayKey, state);
  }

  @override
  void dispose() {
    _stopTimer();
    super.dispose();
  }
}

final listeningSecondsProvider =
    StateNotifierProvider<ListeningDurationNotifier, int>((ref) {
  return ListeningDurationNotifier(ref);
});

/// Human-readable listening duration string (e.g. "1h 24m", "42m", "< 1m").
final listeningTimeFormattedProvider = Provider<String>((ref) {
  final totalSeconds = ref.watch(listeningSecondsProvider);
  if (totalSeconds < 60) {
    return '${totalSeconds}s';
  }
  final hours = totalSeconds ~/ 3600;
  final minutes = (totalSeconds % 3600) ~/ 60;
  if (hours > 0) {
    return '${hours}h ${minutes}m';
  }
  return '${minutes}m';
});
