import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../services/alert_dispatcher_service.dart';
import '../services/audio_stream_service.dart';
import '../services/deduplication_service.dart';
import '../services/flash_service.dart';
import '../services/notification_service.dart';
import '../services/priority_engine.dart';
import '../services/tflite_classifier_service.dart';
import '../services/vibration_service.dart';
import '../main.dart';

/// Singleton NotificationService — initialized in main().
final notificationServiceProvider = Provider<NotificationService>((ref) {
  throw UnimplementedError('Must be overridden in ProviderScope');
});

final priorityEngineProvider = Provider<PriorityEngine>((ref) {
  return PriorityEngine();
});

final deduplicationServiceProvider = Provider<DeduplicationService>((ref) {
  return DeduplicationService();
});

final vibrationServiceProvider = Provider<VibrationService>((ref) {
  return VibrationService();
});

final flashServiceProvider = Provider<FlashService>((ref) {
  return FlashService();
});

final audioStreamServiceProvider = Provider<AudioStreamService>((ref) {
  final service = AudioStreamService();
  ref.onDispose(service.dispose);
  return service;
});

final classifierServiceProvider = Provider<TFLiteClassifierService>((ref) {
  final service = TFLiteClassifierService();
  ref.onDispose(service.dispose);
  return service;
});

final alertDispatcherServiceProvider = Provider<AlertDispatcherService>((ref) {
  final service = AlertDispatcherService(
    priorityEngine: ref.watch(priorityEngineProvider),
    deduplicationService: ref.watch(deduplicationServiceProvider),
    vibrationService: ref.watch(vibrationServiceProvider),
    flashService: ref.watch(flashServiceProvider),
    notificationService: ref.watch(notificationServiceProvider),
    alertRepository: ref.watch(alertRepositoryProvider),
  );
  ref.onDispose(service.dispose);
  return service;
});
