import '../main.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/constants/priority_levels.dart';
import '../core/constants/sound_categories.dart';
import '../data/models/alert_event.dart';
import '../data/models/classification_result.dart';
import 'alert_providers.dart';
import 'audio_providers.dart';
import 'service_providers.dart';
import 'settings_providers.dart';

enum QuickScanStatus {
  idle,
  scanning,
  result,
  noResult,
  error,
  permissionDenied,
}

class QuickScanState {
  final QuickScanStatus status;
  final double currentDb;
  final int remainingSeconds;
  final ClassificationResult? bestResult;
  final AlertEvent? createdAlert;
  final String? errorMessage;

  const QuickScanState({
    required this.status,
    this.currentDb = 0.0,
    this.remainingSeconds = 4,
    this.bestResult,
    this.createdAlert,
    this.errorMessage,
  });

  QuickScanState copyWith({
    QuickScanStatus? status,
    double? currentDb,
    int? remainingSeconds,
    ClassificationResult? bestResult,
    AlertEvent? createdAlert,
    String? errorMessage,
  }) {
    return QuickScanState(
      status: status ?? this.status,
      currentDb: currentDb ?? this.currentDb,
      remainingSeconds: remainingSeconds ?? this.remainingSeconds,
      bestResult: bestResult ?? this.bestResult,
      createdAlert: createdAlert ?? this.createdAlert,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }
}

class QuickScanNotifier extends StateNotifier<QuickScanState> {
  final Ref _ref;
  StreamSubscription? _audioSub;
  StreamSubscription? _dbSub;
  Timer? _countdownTimer;
  bool _wasContinuousListening = false;
  static const int _scanDurationSeconds = 4;

  QuickScanNotifier(this._ref)
      : super(const QuickScanState(status: QuickScanStatus.idle));

  /// Start a real 4-second environmental audio scan.
  Future<void> startScan() async {
    // 1. Check microphone permission
    final perm = await Permission.microphone.status;
    if (perm.isPermanentlyDenied) {
      state = state.copyWith(status: QuickScanStatus.permissionDenied);
      return;
    }
    if (!perm.isGranted) {
      final requested = await Permission.microphone.request();
      if (!requested.isGranted) {
        state = state.copyWith(status: QuickScanStatus.permissionDenied);
        return;
      }
    }

    // 2. Safely pause continuous monitoring if active, avoiding dual mic conflict
    _wasContinuousListening = _ref.read(isListeningProvider);
    if (_wasContinuousListening) {
      await _ref.read(isListeningProvider.notifier).stop();
    }

    // 3. Reset state to scanning
    state = const QuickScanState(
      status: QuickScanStatus.scanning,
      currentDb: 35.0,
      remainingSeconds: _scanDurationSeconds,
    );

    try {
      final classifier = _ref.read(classifierServiceProvider);
      await classifier.loadModel();

      final audioStream = _ref.read(audioStreamServiceProvider);
      await audioStream.startListening();

      ClassificationResult? topResult;

      // Listen to live dB
      _dbSub = audioStream.dbLevelStream.listen((db) {
        if (mounted && state.status == QuickScanStatus.scanning) {
          state = state.copyWith(currentDb: db);
        }
      });

      // Listen to audio chunks and classify
      _audioSub = audioStream.audioStream.listen((buffer) {
        if (state.status != QuickScanStatus.scanning) return;
        final result = classifier.classify(buffer);
        if (result != null) {
          if (topResult == null || result.confidence > topResult!.confidence) {
            topResult = result;
          }
        }
      });

      // 4-second countdown timer
      int secondsLeft = _scanDurationSeconds;
      _countdownTimer?.cancel();
      _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) async {
        secondsLeft--;
        if (secondsLeft > 0) {
          if (mounted) {
            state = state.copyWith(remainingSeconds: secondsLeft);
          }
        } else {
          timer.cancel();
          await _finishScan(topResult);
        }
      });
    } catch (e) {
      debugPrint('[QuickScan] Error during scan: $e');
      await _cleanupAudio();
      state = state.copyWith(
        status: QuickScanStatus.error,
        errorMessage: 'Unable to analyze audio: ${e.toString()}',
      );
      _restoreContinuousListeningIfNeeded();
    }
  }

  Future<void> _finishScan(ClassificationResult? result) async {
    await _cleanupAudio();

    if (result == null || result.confidence < 0.50) {
      if (mounted) {
        state = state.copyWith(status: QuickScanStatus.noResult);
      }
      _restoreContinuousListeningIfNeeded();
      return;
    }

    // Process valid detected sound
    final priorityEngine = _ref.read(priorityEngineProvider);
    final priority = priorityEngine.evaluateAlert(result) ??
        priorityEngine.getPriorityForCategory(result.soundCategory);

    SoundCategory? category;
    try {
      category = SoundCategory.values
          .firstWhere((c) => c.name == result.soundCategory);
    } catch (_) {}

    final alertEvent = AlertEvent(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      soundCategory: result.soundCategory,
      priorityLevel: priority.name,
      confidence: result.confidence,
      timestamp: result.timestamp,
      acknowledged: false,
      source: 'Quick Scan',
    );

    // Save to alert repository
    final repo = _ref.read(alertRepositoryProvider);
    await repo.addAlert(alertEvent);
    _ref.read(alertListProvider.notifier).syncFromRepo();

    // Trigger haptics and flash
    final settings = _ref.read(userSettingsProvider);
    if (settings.vibrationEnabled && category != null) {
      final vibService = _ref.read(vibrationServiceProvider);
      vibService.vibrateForAlert(category: category, priority: priority);
    }
    if (settings.flashEnabled && priority == PriorityLevel.high) {
      final flash = _ref.read(flashServiceProvider);
      flash.triggerStrobe(
        frequencyHz: priority.flashFrequencyHz,
        duration: const Duration(seconds: 2),
      );
    }

    if (mounted) {
      state = state.copyWith(
        status: QuickScanStatus.result,
        bestResult: result,
        createdAlert: alertEvent,
      );
    }

    _restoreContinuousListeningIfNeeded();
  }

  Future<void> _cleanupAudio() async {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    await _audioSub?.cancel();
    _audioSub = null;
    await _dbSub?.cancel();
    _dbSub = null;
    await _ref.read(audioStreamServiceProvider).stopListening();
  }

  void _restoreContinuousListeningIfNeeded() {
    if (_wasContinuousListening) {
      _wasContinuousListening = false;
      // Re-start continuous monitoring cleanly
      Future.microtask(() {
        _ref.read(isListeningProvider.notifier).start();
      });
    }
  }

  void reset() {
    _cleanupAudio();
    state = const QuickScanState(status: QuickScanStatus.idle);
  }

  @override
  void dispose() {
    _cleanupAudio();
    super.dispose();
  }
}

final quickScanProvider =
    StateNotifierProvider.autoDispose<QuickScanNotifier, QuickScanState>((ref) {
  return QuickScanNotifier(ref);
});

