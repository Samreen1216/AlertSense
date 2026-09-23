import 'package:flutter_test/flutter_test.dart';
import 'package:alertsense/core/constants/sound_categories.dart';
import 'package:alertsense/services/temporal_smoothing_service.dart';

void main() {
  group('Detection Hysteresis Tests', () {
    late TemporalSmoothingService service;

    setUp(() {
      service = TemporalSmoothingService(
        config: const TemporalSmoothingConfig(
          historyWindow: 3,
          minimumConfirmations: 2,
          predictionExpiry: Duration(seconds: 3),
          continuationDelta: 0.15,
          activeContinuationExpiry: Duration(seconds: 4),
        ),
      );
    });

    test('Inactive category requires full activation threshold', () {
      const activationThreshold = 0.80;

      expect(service.isCategoryActive(SoundCategory.dogBarking), isFalse);
      expect(
        service.getEffectiveThreshold(SoundCategory.dogBarking, activationThreshold),
        equals(0.80),
      );
    });

    test('Confirmed category transitions to active state (START) and enables continuation threshold', () {
      const activationThreshold = 0.80;
      final t0 = DateTime.now();

      // Window 1: candidate
      service.processPrediction(
        category: SoundCategory.dogBarking,
        confidence: 0.85,
        timestamp: t0,
      );
      expect(service.isCategoryActive(SoundCategory.dogBarking), isFalse);

      // Window 2: confirmed (START)
      final confirmed = service.processPrediction(
        category: SoundCategory.dogBarking,
        confidence: 0.82,
        timestamp: t0.add(const Duration(milliseconds: 500)),
      );

      expect(confirmed, isNotNull);
      expect(confirmed!.isContinuation, isFalse); // First activation (START)
      expect(service.isCategoryActive(SoundCategory.dogBarking), isTrue);

      // Now active: effective threshold drops to continuation threshold (0.80 - 0.15 = 0.65)
      final continuationThreshold = service.getEffectiveThreshold(
        SoundCategory.dogBarking,
        activationThreshold,
      );
      expect(continuationThreshold, equals(0.65));
    });

    test('Active category remains confirmed at continuation threshold (KEEP ACTIVE)', () {
      final t0 = DateTime.now();

      // Confirm category
      service.processPrediction(category: SoundCategory.emergencySiren, confidence: 0.85, timestamp: t0);
      service.processPrediction(category: SoundCategory.emergencySiren, confidence: 0.85, timestamp: t0.add(const Duration(milliseconds: 500)));
      expect(service.isCategoryActive(SoundCategory.emergencySiren), isTrue);

      // Third window at 0.70 (below activation 0.75, but above continuation 0.60)
      final keepActive = service.processPrediction(
        category: SoundCategory.emergencySiren,
        confidence: 0.70,
        timestamp: t0.add(const Duration(milliseconds: 1000)),
      );

      expect(keepActive, isNotNull);
      expect(keepActive!.isContinuation, isTrue); // Maintained active
    });

    test('Category stops after continuation timeout and requires activation threshold again', () {
      const activationThreshold = 0.80;
      final t0 = DateTime(2026, 1, 1, 12, 0, 0);

      service.processPrediction(category: SoundCategory.doorbell, confidence: 0.85, timestamp: t0);
      service.processPrediction(category: SoundCategory.doorbell, confidence: 0.85, timestamp: t0.add(const Duration(milliseconds: 500)));
      expect(service.isCategoryActive(SoundCategory.doorbell, t0.add(const Duration(milliseconds: 500))), isTrue);

      // Advance past activeContinuationExpiry (4 seconds)
      final tLater = t0.add(const Duration(seconds: 5));

      expect(service.isCategoryActive(SoundCategory.doorbell, tLater), isFalse);
      expect(
        service.getEffectiveThreshold(SoundCategory.doorbell, activationThreshold, tLater),
        equals(0.80),
      );
    });

    test('stopCategory immediately transitions active category to STOP', () {
      final t0 = DateTime.now();
      service.processPrediction(category: SoundCategory.vehicleHorn, confidence: 0.85, timestamp: t0);
      service.processPrediction(category: SoundCategory.vehicleHorn, confidence: 0.85, timestamp: t0.add(const Duration(milliseconds: 500)));
      expect(service.isCategoryActive(SoundCategory.vehicleHorn), isTrue);

      service.stopCategory(SoundCategory.vehicleHorn);
      expect(service.isCategoryActive(SoundCategory.vehicleHorn), isFalse);
    });
  });
}
