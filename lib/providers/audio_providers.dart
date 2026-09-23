import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/constants/sound_categories.dart';
import '../data/models/alert_event.dart';
import '../data/models/classification_result.dart';
import 'alert_providers.dart';
import 'service_providers.dart';
import 'settings_providers.dart';
import 'stats_providers.dart';

import '../core/constants/priority_levels.dart';

class DetectedSound {
  final SoundCategory category;
  final double confidence;
  final double angle;
  final double distance;
  final PriorityLevel priority;
  final DateTime timestamp;

  DetectedSound({
    required this.category,
    required this.confidence,
    required this.angle,
    this.distance = 0.65,
    PriorityLevel? priority,
    DateTime? timestamp,
  })  : priority = priority ?? category.defaultPriority,
        timestamp = timestamp ?? DateTime.now();

  String get categoryName => category.label;
}

class ListeningNotifier extends StateNotifier<bool> {
  final Ref _ref;
  StreamSubscription<List<double>>? _audioSub;
  StreamSubscription<double>? _dbSub;
  Timer? _clearRadarTimer;

  ListeningNotifier(this._ref) : super(false);

  Future<void> toggle() async {
    if (state) { await _stop(); } else { await _start(); }
  }

  Future<void> start() async { if (!state) await _start(); }
  Future<void> stop() async { if (state) await _stop(); }

  Future<void> _start() async {
    final status = await Permission.microphone.request();
    if (!status.isGranted) return;

    // Ensure notification permission is requested so background alerts can show
    await Permission.notification.request();

    // Start Android Foreground Service with microphone type & wake lock
    // This allows continuous background audio capture whether app is open, minimized, or screen locked.
    final foregroundService = _ref.read(foregroundServiceProvider);
    await foregroundService.startMonitoring(
      title: 'AlertSense Active',
      text: 'Actively monitoring surrounding sounds in real time...',
    );

    state = true;
    _syncWidget();

    final classifier = _ref.read(classifierServiceProvider);
    await classifier.loadModel();

    final audioStream = _ref.read(audioStreamServiceProvider);
    await audioStream.startListening();

    DateTime lastWidgetDbSync = DateTime.now();
    _dbSub = audioStream.dbLevelStream.listen((db) {
      if (mounted) {
        _ref.read(ambientDbProvider.notifier).state = db;
        final now = DateTime.now();
        if (now.difference(lastWidgetDbSync).inMilliseconds >= 2500) {
          lastWidgetDbSync = now;
          _syncWidget();
        }
      }
    });

    _audioSub = audioStream.audioStream.listen((buffer) async {
      if (!state) return;

      // 1. Signal / Energy Validation
      final validator = _ref.read(signalEnergyValidatorProvider);
      final validation = validator.validate(buffer);
      final smoother = _ref.read(temporalSmoothingServiceProvider);

      if (!validation.isSufficient) {
        smoother.purgeExpired();
        return;
      }

      // 2. YAMNet Inference & Top-5 Candidate Search
      final result = classifier.classify(buffer);
      if (result == null) {
        return;
      }

      SoundCategory? category;
      try {
        category = SoundCategory.values.firstWhere((c) => c.name == result.soundCategory);
      } catch (_) {}
      if (category == null) return;

      // 3. Category-Specific Threshold Gating & Hysteresis
      final thresholds = _ref.read(soundDetectionThresholdsProvider);
      final baselineThreshold = thresholds.thresholdFor(category);
      final effectiveThreshold = smoother.getEffectiveThreshold(category, baselineThreshold);

      if (result.confidence < effectiveThreshold) {
        debugPrint('[Threshold] ${result.confidence.toStringAsFixed(2)} < ${effectiveThreshold.toStringAsFixed(2)} → REJECT');
        debugPrint('[Alert] NOT TRIGGERED');
        return;
      }
      debugPrint('[Threshold] ${result.confidence.toStringAsFixed(2)} >= ${effectiveThreshold.toStringAsFixed(2)} → PASS');

      // 4. Temporal Smoothing / Multi-Window Confirmation
      final confirmed = smoother.processPrediction(
        category: category,
        confidence: result.confidence,
        timestamp: result.timestamp,
      );

      if (confirmed == null) {
        debugPrint('[Alert] NOT TRIGGERED');
        return;
      }

      debugPrint('[Detection] ${category.label} CONFIRMED');

      // 5. Confirmed Detection Passed to Alert Dispatcher
      final confirmedResult = ClassificationResult(
        soundCategory: confirmed.category.name,
        confidence: confirmed.aggregatedConfidence,
        timestamp: confirmed.timestamp,
        topPredictions: result.topPredictions,
        ambientDbLevel: result.ambientDbLevel,
      );

      await _dispatch(confirmedResult);
    });
  }

  Future<void> _dispatch(ClassificationResult result) async {
    // Use currentProfileProvider as the single source of truth for enabled sounds.
    // enabledSoundsProvider was never synced from the profile and always returned all
    // categories — so profile filtering was silently bypassed.
    final currentProfile = _ref.read(currentProfileProvider);
    final enabledCategories = currentProfile.enabledCategories.toSet();
    // Fix: profile id is 'default_sleep', not 'sleep'. Use name for reliable check.
    final isSleep = currentProfile.name.toLowerCase() == 'sleep';

    final settings = _ref.read(userSettingsProvider);

    final dispatcher = _ref.read(alertDispatcherServiceProvider);
    final alertEvent = await dispatcher.dispatchClassification(
      result: result,
      isSleepMode: isSleep,
      flashEnabled: settings.flashEnabled,
      vibrationEnabled: settings.vibrationEnabled,
      enabledCategories: enabledCategories,
    );

    if (alertEvent != null) {
      final cat = SoundCategory.values.firstWhere(
        (c) => c.name == alertEvent.soundCategory,
        orElse: () => SoundCategory.dogBarking,
      );

      // Update the persistent status bar notification with the latest sound event
      final foregroundService = _ref.read(foregroundServiceProvider);
      await foregroundService.updateStatus(
        title: '${cat.label} Detected!',
        text: 'Confidence: ${(alertEvent.confidence * 100).toStringAsFixed(0)}% • AlertSense Active',
      );

      if (mounted) {
        final random = Random();
        final dist = (0.75 - (alertEvent.confidence * 0.2)).clamp(0.42, 0.82);
        final newSound = DetectedSound(
          category: cat,
          confidence: alertEvent.confidence * 100,
          angle: random.nextDouble() * 2 * pi,
          distance: dist,
          priority: cat.defaultPriority,
        );

        final currentSounds = _ref.read(detectedSoundsProvider)
            .where((s) => DateTime.now().difference(s.timestamp).inSeconds < 18 && s.category != cat)
            .toList();

        _ref.read(detectedSoundsProvider.notifier).state = [newSound, ...currentSounds].take(4).toList();
        _ref.read(alertListProvider.notifier).syncFromRepo();

        _clearRadarTimer?.cancel();
        _clearRadarTimer = Timer(const Duration(seconds: 18), () {
          if (mounted) {
            final valid = _ref.read(detectedSoundsProvider)
                .where((s) => DateTime.now().difference(s.timestamp).inSeconds < 18)
                .toList();
            _ref.read(detectedSoundsProvider.notifier).state = valid;
          }
        });
      }

      _syncWidget(event: alertEvent);
    }
  }

  Future<void> _stop() async {
    state = false;
    await _audioSub?.cancel(); _audioSub = null;
    await _dbSub?.cancel(); _dbSub = null;
    _clearRadarTimer?.cancel(); _clearRadarTimer = null;
    await _ref.read(audioStreamServiceProvider).stopListening();
    await _ref.read(foregroundServiceProvider).stopMonitoring();
    _ref.read(temporalSmoothingServiceProvider).reset();
    if (mounted) _ref.read(detectedSoundsProvider.notifier).state = [];
    _syncWidget();
  }

  /// Clear the radar display immediately (e.g. on profile switch so stale
  /// cross-profile sounds disappear at once).
  void clearRadar() {
    _clearRadarTimer?.cancel();
    if (mounted) _ref.read(detectedSoundsProvider.notifier).state = [];
  }

  void _syncWidget({AlertEvent? event}) {
    try {
      final widgetService = _ref.read(homeWidgetServiceProvider);
      final profile = _ref.read(activeProfileProvider);
      final db = _ref.read(ambientDbProvider);
      final todayCount = _ref.read(alertsTodayCountProvider);
      final highCount = _ref.read(highPriorityCountProvider);
      final lastAlert = event ?? _ref.read(lastAlertProvider);
      final enabledCount = _ref.read(enabledSoundsProvider).length;

      widgetService.syncData(
        isListening: state,
        activeProfile: profile,
        ambientDb: db,
        lastAlert: lastAlert,
        alertsTodayCount: todayCount,
        highPriorityCount: highCount,
        monitoredCount: enabledCount,
      );
    } catch (_) {}
  }

  /// Fire a synthetic test alert for demonstration.
  Future<void> fireTestAlert(SoundCategory category) async {
    final classifier = _ref.read(classifierServiceProvider);
    if (!classifier.isLoaded) await classifier.loadModel();

    final result = ClassificationResult(
      soundCategory: category.name,
      confidence: 0.88,
      timestamp: DateTime.now(),
      topPredictions: [MapEntry(category.yamnetLabels.first, 0.88)],
      ambientDbLevel: 65.0,
    );
    await _dispatch(result);
  }

  @override
  void dispose() {
    _stop();
    super.dispose();
  }
}

final isListeningProvider = StateNotifierProvider<ListeningNotifier, bool>((ref) {
  return ListeningNotifier(ref);
});

final detectedSoundsProvider = StateProvider<List<DetectedSound>>((ref) => []);
final ambientDbProvider = StateProvider<double>((ref) => 38.0);

class EnabledSoundsNotifier extends StateNotifier<Set<String>> {
  EnabledSoundsNotifier() : super(SoundCategory.values.map((c) => c.name).toSet());

  void toggle(String cat) {
    if (state.contains(cat)) { state = {...state}..remove(cat); }
    else { state = {...state, cat}; }
  }

  void setProfile(String profileIdOrName) {
    // Match by id suffix or name, e.g. 'default_sleep' or 'sleep', 'Sleep', etc.
    final key = profileIdOrName.toLowerCase();
    if (key.contains('sleep')) {
      state = { SoundCategory.fireAlarm.name, SoundCategory.smokeAlarm.name,
                SoundCategory.emergencySiren.name, SoundCategory.babyCrying.name };
    } else if (key.contains('outdoor') || key.contains('away')) {
      state = { SoundCategory.emergencySiren.name, SoundCategory.vehicleHorn.name,
                SoundCategory.glassBreaking.name, SoundCategory.dogBarking.name };
    } else {
      // Home or any other profile — all categories enabled
      state = SoundCategory.values.map((c) => c.name).toSet();
    }
  }

  void enableAll(Set<String> all) { state = all; }
  void disableAll() { state = {}; }
}

final enabledSoundsProvider = StateNotifierProvider<EnabledSoundsNotifier, Set<String>>((ref) {
  return EnabledSoundsNotifier();
});
