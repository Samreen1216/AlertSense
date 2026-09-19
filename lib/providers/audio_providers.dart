import 'dart:async';
import 'dart:math';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import '../core/constants/sound_categories.dart';
import '../data/models/classification_result.dart';
import 'alert_providers.dart';
import 'service_providers.dart';
import 'settings_providers.dart';

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

    state = true;

    final classifier = _ref.read(classifierServiceProvider);
    await classifier.loadModel();

    final audioStream = _ref.read(audioStreamServiceProvider);
    await audioStream.startListening();

    _dbSub = audioStream.dbLevelStream.listen((db) {
      if (mounted) _ref.read(ambientDbProvider.notifier).state = db;
    });

    _audioSub = audioStream.audioStream.listen((buffer) async {
      if (!mounted || !state) return;
      final result = classifier.classify(buffer);
      if (result == null) return;
      await _dispatch(result);
    });
  }

  Future<void> _dispatch(ClassificationResult result) async {
    final enabledSounds = _ref.read(enabledSoundsProvider);
    final settings = _ref.read(userSettingsProvider);
    final profile = _ref.read(activeProfileProvider);
    final isSleep = profile == 'sleep';

    final dispatcher = _ref.read(alertDispatcherServiceProvider);
    final alertEvent = await dispatcher.dispatchClassification(
      result: result,
      isSleepMode: isSleep,
      flashEnabled: settings.flashEnabled,
      vibrationEnabled: settings.vibrationEnabled,
      enabledCategories: enabledSounds,
    );

    if (alertEvent != null && mounted) {
      final random = Random();
      final cat = SoundCategory.values.firstWhere(
        (c) => c.name == alertEvent.soundCategory,
        orElse: () => SoundCategory.dogBarking,
      );
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
  }

  Future<void> _stop() async {
    state = false;
    await _audioSub?.cancel(); _audioSub = null;
    await _dbSub?.cancel(); _dbSub = null;
    _clearRadarTimer?.cancel(); _clearRadarTimer = null;
    await _ref.read(audioStreamServiceProvider).stopListening();
    if (mounted) _ref.read(detectedSoundsProvider.notifier).state = [];
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

  void setProfile(String profile) {
    switch (profile) {
      case 'sleep':
        state = { SoundCategory.fireAlarm.name, SoundCategory.smokeAlarm.name,
                  SoundCategory.emergencySiren.name, SoundCategory.babyCrying.name };
        break;
      case 'outdoor':
        state = { SoundCategory.emergencySiren.name, SoundCategory.vehicleHorn.name,
                  SoundCategory.glassBreaking.name, SoundCategory.dogBarking.name };
        break;
      default:
        state = SoundCategory.values.map((c) => c.name).toSet();
    }
  }

  void enableAll(Set<String> all) { state = all; }
  void disableAll() { state = {}; }
}

final enabledSoundsProvider = StateNotifierProvider<EnabledSoundsNotifier, Set<String>>((ref) {
  return EnabledSoundsNotifier();
});
