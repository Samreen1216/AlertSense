import 'package:flutter_test/flutter_test.dart';
import 'package:alertsense/core/constants/sound_categories.dart';
import 'package:alertsense/services/temporal_smoothing_service.dart';

void main() {
  group('TemporalSmoothingService Tests', () {
    late TemporalSmoothingService service;

    setUp(() {
      service = TemporalSmoothingService(
        config: const TemporalSmoothingConfig(
          historyWindow: 3,
          minimumConfirmations: 2,
          predictionExpiry: Duration(seconds: 3),
          aggregationMethod: ConfidenceAggregationMethod.weightedAverage,
        ),
      );
    });

    test('Single prediction does not trigger confirmation', () {
      final confirmed = service.processPrediction(
        category: SoundCategory.fireAlarm,
        confidence: 0.90,
      );

      expect(confirmed, isNull);
      expect(service.currentBuffer.length, equals(1));
    });

    test('Two consecutive matching predictions trigger confirmation', () {
      final t0 = DateTime.now();

      final first = service.processPrediction(
        category: SoundCategory.fireAlarm,
        confidence: 0.80,
        timestamp: t0,
      );
      expect(first, isNull);

      final second = service.processPrediction(
        category: SoundCategory.fireAlarm,
        confidence: 0.90,
        timestamp: t0.add(const Duration(milliseconds: 500)),
      );

      expect(second, isNotNull);
      expect(second!.category, equals(SoundCategory.fireAlarm));
      expect(second.confirmationCount, equals(2));
      expect(second.windowSize, equals(2));
      // Weighted average: (0.80 * 1 + 0.90 * 2) / 3 = 2.60 / 3 ≈ 0.8667
      expect(second.aggregatedConfidence, closeTo(0.8667, 0.001));
    });

    test('Buffer enforces historyWindow maximum limit', () {
      final t0 = DateTime.now();
      service.processPrediction(category: SoundCategory.babyCrying, confidence: 0.70, timestamp: t0);
      service.processPrediction(category: SoundCategory.babyCrying, confidence: 0.75, timestamp: t0.add(const Duration(milliseconds: 200)));
      service.processPrediction(category: SoundCategory.babyCrying, confidence: 0.80, timestamp: t0.add(const Duration(milliseconds: 400)));
      service.processPrediction(category: SoundCategory.babyCrying, confidence: 0.85, timestamp: t0.add(const Duration(milliseconds: 600)));

      expect(service.currentBuffer.length, equals(3));
      expect(service.currentBuffer.first.confidence, equals(0.75));
      expect(service.currentBuffer.last.confidence, equals(0.85));
    });

    test('Alternating categories do not confirm without reaching minimum threshold', () {
      final t0 = DateTime.now();

      final r1 = service.processPrediction(category: SoundCategory.doorbell, confidence: 0.85, timestamp: t0);
      final r2 = service.processPrediction(category: SoundCategory.knocking, confidence: 0.80, timestamp: t0.add(const Duration(milliseconds: 200)));
      final r3 = service.processPrediction(category: SoundCategory.dogBarking, confidence: 0.80, timestamp: t0.add(const Duration(milliseconds: 400)));

      expect(r1, isNull);
      expect(r2, isNull);
      expect(r3, isNull);
    });

    test('Window allows non-consecutive matching predictions within window size', () {
      final t0 = DateTime.now();

      service.processPrediction(category: SoundCategory.doorbell, confidence: 0.80, timestamp: t0);
      service.processPrediction(category: SoundCategory.babyCrying, confidence: 0.70, timestamp: t0.add(const Duration(milliseconds: 200)));
      final r3 = service.processPrediction(category: SoundCategory.doorbell, confidence: 0.85, timestamp: t0.add(const Duration(milliseconds: 400)));

      // Doorbell has 2 matching predictions in window of 3
      expect(r3, isNotNull);
      expect(r3!.category, equals(SoundCategory.doorbell));
      expect(r3.confirmationCount, equals(2));
      expect(r3.windowSize, equals(3));
    });

    test('Stale predictions past expiry duration are evicted', () {
      final t0 = DateTime(2026, 1, 1, 12, 0, 0);

      service.processPrediction(category: SoundCategory.smokeAlarm, confidence: 0.90, timestamp: t0);

      // Advance by 4 seconds (expiry is 3 seconds)
      final t1 = t0.add(const Duration(seconds: 4));
      final confirmed = service.processPrediction(
        category: SoundCategory.smokeAlarm,
        confidence: 0.90,
        timestamp: t1,
      );

      // Since the first prediction expired, only 1 prediction exists in active window
      expect(confirmed, isNull);
      expect(service.currentBuffer.length, equals(1));
    });

    test('Average aggregation method calculates arithmetic mean', () {
      final avgService = TemporalSmoothingService(
        config: const TemporalSmoothingConfig(
          historyWindow: 2,
          minimumConfirmations: 2,
          aggregationMethod: ConfidenceAggregationMethod.average,
        ),
      );

      avgService.processPrediction(category: SoundCategory.emergencySiren, confidence: 0.70);
      final confirmed = avgService.processPrediction(category: SoundCategory.emergencySiren, confidence: 0.90);

      expect(confirmed, isNotNull);
      expect(confirmed!.aggregatedConfidence, closeTo(0.80, 0.001));
    });

    test('Maximum aggregation method selects highest confidence', () {
      final maxService = TemporalSmoothingService(
        config: const TemporalSmoothingConfig(
          historyWindow: 2,
          minimumConfirmations: 2,
          aggregationMethod: ConfidenceAggregationMethod.maximum,
        ),
      );

      maxService.processPrediction(category: SoundCategory.emergencySiren, confidence: 0.70);
      final confirmed = maxService.processPrediction(category: SoundCategory.emergencySiren, confidence: 0.92);

      expect(confirmed, isNotNull);
      expect(confirmed!.aggregatedConfidence, closeTo(0.92, 0.001));
    });

    test('Reset completely clears prediction buffer', () {
      service.processPrediction(category: SoundCategory.vehicleHorn, confidence: 0.85);
      expect(service.currentBuffer.length, equals(1));

      service.reset();
      expect(service.currentBuffer, isEmpty);

      // Adding one more prediction still doesn't confirm
      final confirmed = service.processPrediction(category: SoundCategory.vehicleHorn, confidence: 0.85);
      expect(confirmed, isNull);
    });
  });
}
