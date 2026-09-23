import 'package:flutter_test/flutter_test.dart';
import 'package:alertsense/core/constants/sound_categories.dart';
import 'package:alertsense/core/constants/sound_detection_thresholds.dart';

void main() {
  group('SoundDetectionThresholds Tests', () {
    late SoundDetectionThresholds thresholds;

    setUp(() {
      thresholds = SoundDetectionThresholds();
    });

    test('Baseline thresholds match specifications for all 9 categories', () {
      expect(SoundDetectionThresholds.getThreshold(SoundCategory.fireAlarm), equals(0.70));
      expect(SoundDetectionThresholds.getThreshold(SoundCategory.smokeAlarm), equals(0.70));
      expect(SoundDetectionThresholds.getThreshold(SoundCategory.emergencySiren), equals(0.75));
      expect(SoundDetectionThresholds.getThreshold(SoundCategory.glassBreaking), equals(0.80));
      expect(SoundDetectionThresholds.getThreshold(SoundCategory.doorbell), equals(0.75));
      expect(SoundDetectionThresholds.getThreshold(SoundCategory.knocking), equals(0.75));
      expect(SoundDetectionThresholds.getThreshold(SoundCategory.babyCrying), equals(0.70));
      expect(SoundDetectionThresholds.getThreshold(SoundCategory.dogBarking), equals(0.80));
      expect(SoundDetectionThresholds.getThreshold(SoundCategory.vehicleHorn), equals(0.80));
    });

    test('meetsThreshold correctly rejects below-threshold confidence', () {
      // Dog Barking threshold is 0.80
      expect(thresholds.meetsThreshold(SoundCategory.dogBarking, 0.79), isFalse);
      expect(thresholds.meetsThreshold(SoundCategory.dogBarking, 0.50), isFalse);
      expect(thresholds.meetsThreshold(SoundCategory.dogBarking, 0.0), isFalse);
    });

    test('meetsThreshold correctly accepts equal or above-threshold confidence', () {
      // Dog Barking threshold is 0.80
      expect(thresholds.meetsThreshold(SoundCategory.dogBarking, 0.80), isTrue);
      expect(thresholds.meetsThreshold(SoundCategory.dogBarking, 0.85), isTrue);
      expect(thresholds.meetsThreshold(SoundCategory.dogBarking, 1.0), isTrue);
    });

    test('Category-specific differentiation: 0.72 satisfies Baby Crying but rejects Dog Barking', () {
      const score = 0.72;
      expect(thresholds.meetsThreshold(SoundCategory.babyCrying, score), isTrue); // req: 0.70
      expect(thresholds.meetsThreshold(SoundCategory.dogBarking, score), isFalse); // req: 0.80
      expect(thresholds.meetsThreshold(SoundCategory.doorbell, score), isFalse); // req: 0.75
    });

    test('Custom threshold overrides modify specific categories while retaining others', () {
      final custom = SoundDetectionThresholds({
        SoundCategory.dogBarking: 0.60,
      });

      expect(custom.thresholdFor(SoundCategory.dogBarking), equals(0.60));
      expect(custom.meetsThreshold(SoundCategory.dogBarking, 0.62), isTrue);
      // Fire alarm remains default 0.70
      expect(custom.thresholdFor(SoundCategory.fireAlarm), equals(0.70));
      expect(custom.meetsThreshold(SoundCategory.fireAlarm, 0.62), isFalse);
    });

    test('SoundCategory defaultThreshold references centralized thresholds', () {
      for (final cat in SoundCategory.values) {
        expect(cat.defaultThreshold, equals(SoundDetectionThresholds.getThreshold(cat)));
      }
    });

    test('toMap returns all 9 category thresholds and is unmodifiable', () {
      final map = thresholds.toMap();
      expect(map.length, equals(9));
      expect(map[SoundCategory.emergencySiren], equals(0.75));
      expect(() => map[SoundCategory.fireAlarm] = 0.99, throwsUnsupportedError);
    });
  });
}
