import 'package:flutter_test/flutter_test.dart';
import 'package:alertsense/core/constants/sound_categories.dart';
import 'package:alertsense/services/temporal_smoothing_service.dart';

void main() {
  final DateTime baseTime = DateTime(2024, 1, 1, 12, 0, 0);

  group('Group 1: Single Prediction (No Confirmation)', () {
    test('A single fireAlarm prediction does NOT trigger confirmation', () {
      final service = TemporalSmoothingService();
      final result = service.processPrediction(
        category: SoundCategory.fireAlarm,
        confidence: 0.8,
        timestamp: baseTime,
      );

      expect(result, isNull);
    });

    test('Buffer correctly contains the single prediction after processing', () {
      final service = TemporalSmoothingService();
      service.processPrediction(
        category: SoundCategory.fireAlarm,
        confidence: 0.8,
        timestamp: baseTime,
      );

      expect(service.currentBuffer.length, 1);
      expect(service.currentBuffer.first.category, SoundCategory.fireAlarm);
      expect(service.currentBuffer.first.confidence, 0.8);
      expect(service.currentBuffer.first.timestamp, baseTime);
    });
  });

  group('Group 2: Two-of-Three Majority Vote Confirmation', () {
    test('Two consecutive fireAlarm predictions DO confirm', () {
      final service = TemporalSmoothingService();
      service.processPrediction(
        category: SoundCategory.fireAlarm,
        confidence: 0.8,
        timestamp: baseTime,
      );
      final result = service.processPrediction(
        category: SoundCategory.fireAlarm,
        confidence: 0.9,
        timestamp: baseTime.add(const Duration(seconds: 1)),
      );

      expect(result, isNotNull);
      expect(result!.category, SoundCategory.fireAlarm);
      expect(result.confirmationCount, 2);
      expect(result.isContinuation, isFalse);
      
      // Weighted average: (0.8*1 + 0.9*2) / 3 = (0.8 + 1.8) / 3 = 2.6 / 3 = 0.8666...
      expect(result.aggregatedConfidence, closeTo(0.8667, 0.0001));
    });

    test('Three consecutive same-category predictions also confirm with count=3', () {
      final service = TemporalSmoothingService();
      service.processPrediction(
        category: SoundCategory.fireAlarm,
        confidence: 0.7,
        timestamp: baseTime,
      );
      service.processPrediction(
        category: SoundCategory.fireAlarm,
        confidence: 0.8,
        timestamp: baseTime.add(const Duration(seconds: 1)),
      );
      final result = service.processPrediction(
        category: SoundCategory.fireAlarm,
        confidence: 0.9,
        timestamp: baseTime.add(const Duration(seconds: 2)),
      );

      expect(result, isNotNull);
      expect(result!.confirmationCount, 3);
      expect(result.isContinuation, isTrue); // Became active on the second prediction
    });
  });

  group('Group 3: Mixed Category Predictions', () {
    test('fireAlarm then dogBarking then fireAlarm confirms fireAlarm', () {
      final service = TemporalSmoothingService();
      service.processPrediction(
        category: SoundCategory.fireAlarm,
        confidence: 0.8,
        timestamp: baseTime,
      );
      service.processPrediction(
        category: SoundCategory.dogBarking,
        confidence: 0.7,
        timestamp: baseTime.add(const Duration(seconds: 1)),
      );
      final result = service.processPrediction(
        category: SoundCategory.fireAlarm,
        confidence: 0.9,
        timestamp: baseTime.add(const Duration(seconds: 2)),
      );

      // Buffer: [fireAlarm, dogBarking, fireAlarm] -> 2 fireAlarms
      expect(result, isNotNull);
      expect(result!.category, SoundCategory.fireAlarm);
      expect(result.confirmationCount, 2);
    });

    test('fireAlarm then dogBarking then knocking - no confirmation', () {
      final service = TemporalSmoothingService();
      service.processPrediction(
        category: SoundCategory.fireAlarm,
        confidence: 0.8,
        timestamp: baseTime,
      );
      service.processPrediction(
        category: SoundCategory.dogBarking,
        confidence: 0.7,
        timestamp: baseTime.add(const Duration(seconds: 1)),
      );
      final result = service.processPrediction(
        category: SoundCategory.knocking,
        confidence: 0.9,
        timestamp: baseTime.add(const Duration(seconds: 2)),
      );

      expect(result, isNull);
    });
  });

  group('Group 4: Hysteresis State Machine', () {
    test('State machine transitions correctly from START to KEEP ACTIVE to STOP', () {
      final service = TemporalSmoothingService();
      
      // START state: 2 confirmations
      service.processPrediction(
        category: SoundCategory.fireAlarm,
        confidence: 0.8,
        timestamp: baseTime,
      );
      final startResult = service.processPrediction(
        category: SoundCategory.fireAlarm,
        confidence: 0.9,
        timestamp: baseTime.add(const Duration(seconds: 1)),
      );
      
      expect(startResult!.isContinuation, isFalse);
      expect(service.isCategoryActive(SoundCategory.fireAlarm, baseTime.add(const Duration(seconds: 1))), isTrue);

      // KEEP ACTIVE state: subsequent confirmation
      final activeResult = service.processPrediction(
        category: SoundCategory.fireAlarm,
        confidence: 0.9,
        timestamp: baseTime.add(const Duration(seconds: 2)),
      );
      
      expect(activeResult!.isContinuation, isTrue);

      // STOP state: after activeContinuationExpiry (4 seconds)
      final stopTime = baseTime.add(const Duration(seconds: 2)).add(const Duration(seconds: 5));
      expect(service.isCategoryActive(SoundCategory.fireAlarm, stopTime), isFalse);
    });
  });

  group('Group 5: Effective Threshold with Continuation', () {
    test('When category is NOT active, returns baseline', () {
      final service = TemporalSmoothingService();
      expect(service.getEffectiveThreshold(SoundCategory.fireAlarm, 0.8, baseTime), 0.8);
    });

    test('When category IS active, returns baseline - 0.15', () {
      final service = TemporalSmoothingService();
      // Make it active
      service.processPrediction(category: SoundCategory.fireAlarm, confidence: 0.8, timestamp: baseTime);
      service.processPrediction(category: SoundCategory.fireAlarm, confidence: 0.8, timestamp: baseTime.add(const Duration(seconds: 1)));
      
      expect(service.getEffectiveThreshold(SoundCategory.fireAlarm, 0.8, baseTime.add(const Duration(seconds: 1))), 0.65);
    });

    test('Edge case: baseline of 0.60 with active category returns 0.50 (floor)', () {
      final service = TemporalSmoothingService();
      service.processPrediction(category: SoundCategory.fireAlarm, confidence: 0.8, timestamp: baseTime);
      service.processPrediction(category: SoundCategory.fireAlarm, confidence: 0.8, timestamp: baseTime.add(const Duration(seconds: 1)));
      
      expect(service.getEffectiveThreshold(SoundCategory.fireAlarm, 0.60, baseTime.add(const Duration(seconds: 1))), 0.50);
    });
  });

  group('Group 6: Prediction Expiry', () {
    test('Predictions older than 3 seconds are purged and dont confirm', () {
      final service = TemporalSmoothingService();
      service.processPrediction(
        category: SoundCategory.fireAlarm,
        confidence: 0.8,
        timestamp: baseTime,
      );
      final result = service.processPrediction(
        category: SoundCategory.fireAlarm,
        confidence: 0.9,
        timestamp: baseTime.add(const Duration(seconds: 4)),
      );
      
      expect(result, isNull);
      expect(service.currentBuffer.length, 1); // Only the new prediction should be in the buffer
      expect(service.currentBuffer.first.timestamp, baseTime.add(const Duration(seconds: 4)));
    });
  });

  group('Group 7: Buffer Management', () {
    test('Buffer never exceeds historyWindow size (3)', () {
      final service = TemporalSmoothingService();
      service.processPrediction(category: SoundCategory.dogBarking, confidence: 0.8, timestamp: baseTime);
      service.processPrediction(category: SoundCategory.fireAlarm, confidence: 0.8, timestamp: baseTime.add(const Duration(seconds: 1)));
      service.processPrediction(category: SoundCategory.knocking, confidence: 0.8, timestamp: baseTime.add(const Duration(seconds: 2)));
      service.processPrediction(category: SoundCategory.emergencySiren, confidence: 0.8, timestamp: baseTime.add(const Duration(seconds: 3)));
      
      expect(service.currentBuffer.length, 3);
      expect(service.currentBuffer.first.category, SoundCategory.fireAlarm);
      expect(service.currentBuffer.last.category, SoundCategory.emergencySiren);
    });

    test('reset() clears everything', () {
      final service = TemporalSmoothingService();
      service.processPrediction(category: SoundCategory.fireAlarm, confidence: 0.8, timestamp: baseTime);
      service.processPrediction(category: SoundCategory.fireAlarm, confidence: 0.8, timestamp: baseTime.add(const Duration(seconds: 1)));
      
      service.reset();
      expect(service.currentBuffer, isEmpty);
      expect(service.isCategoryActive(SoundCategory.fireAlarm, baseTime.add(const Duration(seconds: 2))), isFalse);
    });
  });

  group('Group 8: stopCategory()', () {
    test('Explicitly stopping a category removes it from active set', () {
      final service = TemporalSmoothingService();
      service.processPrediction(category: SoundCategory.fireAlarm, confidence: 0.8, timestamp: baseTime);
      service.processPrediction(category: SoundCategory.fireAlarm, confidence: 0.8, timestamp: baseTime.add(const Duration(seconds: 1)));
      
      expect(service.isCategoryActive(SoundCategory.fireAlarm, baseTime.add(const Duration(seconds: 1))), isTrue);
      
      service.stopCategory(SoundCategory.fireAlarm);
      expect(service.isCategoryActive(SoundCategory.fireAlarm, baseTime.add(const Duration(seconds: 1))), isFalse);
    });
  });

  group('Group 9: Confidence Aggregation Methods', () {
    test('Average aggregation', () {
      const config = TemporalSmoothingConfig(aggregationMethod: ConfidenceAggregationMethod.average);
      final service = TemporalSmoothingService(config: config);
      
      service.processPrediction(category: SoundCategory.fireAlarm, confidence: 0.8, timestamp: baseTime);
      final result = service.processPrediction(category: SoundCategory.fireAlarm, confidence: 0.9, timestamp: baseTime.add(const Duration(seconds: 1)));
      
      expect(result!.aggregatedConfidence, closeTo(0.85, 0.0001));
    });

    test('Maximum aggregation', () {
      const config = TemporalSmoothingConfig(aggregationMethod: ConfidenceAggregationMethod.maximum);
      final service = TemporalSmoothingService(config: config);
      
      service.processPrediction(category: SoundCategory.fireAlarm, confidence: 0.8, timestamp: baseTime);
      final result = service.processPrediction(category: SoundCategory.fireAlarm, confidence: 0.9, timestamp: baseTime.add(const Duration(seconds: 1)));
      
      expect(result!.aggregatedConfidence, 0.9);
    });

    test('Weighted average aggregation', () {
      const config = TemporalSmoothingConfig(aggregationMethod: ConfidenceAggregationMethod.weightedAverage);
      final service = TemporalSmoothingService(config: config);
      
      service.processPrediction(category: SoundCategory.fireAlarm, confidence: 0.8, timestamp: baseTime);
      final result = service.processPrediction(category: SoundCategory.fireAlarm, confidence: 0.9, timestamp: baseTime.add(const Duration(seconds: 1)));
      
      expect(result!.aggregatedConfidence, closeTo(0.8667, 0.0001));
    });
  });

  group('Group 10: Edge Cases', () {
    test('Processing with confidence > 1.0 clamps to 1.0', () {
      final service = TemporalSmoothingService();
      service.processPrediction(category: SoundCategory.fireAlarm, confidence: 1.5, timestamp: baseTime);
      
      expect(service.currentBuffer.first.confidence, 1.0);
    });

    test('Processing with confidence < 0.0 clamps to 0.0', () {
      final service = TemporalSmoothingService();
      service.processPrediction(category: SoundCategory.fireAlarm, confidence: -0.5, timestamp: baseTime);
      
      expect(service.currentBuffer.first.confidence, 0.0);
    });
  });
}
