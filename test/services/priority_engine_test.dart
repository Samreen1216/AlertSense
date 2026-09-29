import 'package:flutter_test/flutter_test.dart';
import 'package:alertsense/services/priority_engine.dart';
import 'package:alertsense/data/models/classification_result.dart';
import 'package:alertsense/core/constants/priority_levels.dart';
import 'package:alertsense/core/constants/sound_categories.dart';

void main() {
  late PriorityEngine priorityEngine;

  setUp(() {
    priorityEngine = PriorityEngine();
  });

  /// Helper function to create ClassificationResult
  ClassificationResult makeResult(String category, double confidence) {
    return ClassificationResult(
      soundCategory: category,
      confidence: confidence,
      timestamp: DateTime(2024, 1, 1),
      topPredictions: [MapEntry(category, confidence)],
      ambientDbLevel: 50.0,
    );
  }

  group('Group 1: Default Threshold Evaluation', () {
    /// Verifies the default threshold evaluation behavior for a known category
    test('fireAlarm at 0.85 confidence (above 0.70) returns PriorityLevel.high', () {
      final result = makeResult('fireAlarm', 0.85);
      final priority = priorityEngine.evaluateAlert(result);
      expect(priority, PriorityLevel.high);
    });

    test('fireAlarm at 0.50 confidence (below 0.70) returns null', () {
      final result = makeResult('fireAlarm', 0.50);
      final priority = priorityEngine.evaluateAlert(result);
      expect(priority, isNull);
    });

    test('fireAlarm at exactly 0.70 confidence (boundary) returns PriorityLevel.high', () {
      final result = makeResult('fireAlarm', 0.70);
      final priority = priorityEngine.evaluateAlert(result);
      expect(priority, PriorityLevel.high);
    });

    test('fireAlarm at 0.69 confidence (just below) returns null', () {
      final result = makeResult('fireAlarm', 0.69);
      final priority = priorityEngine.evaluateAlert(result);
      expect(priority, isNull);
    });
  });

  group('Group 2: Priority Level Mapping', () {
    /// Verifies mapping of sound categories to their default priority levels
    test('Returns correct priority for all known categories', () {
      expect(priorityEngine.evaluateAlert(makeResult('fireAlarm', 0.9)), PriorityLevel.high);
      expect(priorityEngine.evaluateAlert(makeResult('smokeAlarm', 0.9)), PriorityLevel.high);
      expect(priorityEngine.evaluateAlert(makeResult('emergencySiren', 0.9)), PriorityLevel.high);
      expect(priorityEngine.evaluateAlert(makeResult('glassBreaking', 0.9)), PriorityLevel.high);

      expect(priorityEngine.evaluateAlert(makeResult('doorbell', 0.9)), PriorityLevel.medium);
      expect(priorityEngine.evaluateAlert(makeResult('knocking', 0.9)), PriorityLevel.medium);
      expect(priorityEngine.evaluateAlert(makeResult('babyCrying', 0.9)), PriorityLevel.medium);

      expect(priorityEngine.evaluateAlert(makeResult('dogBarking', 0.9)), PriorityLevel.low);
      expect(priorityEngine.evaluateAlert(makeResult('vehicleHorn', 0.9)), PriorityLevel.low);
    });
  });

  group('Group 3: Custom Threshold Override', () {
    /// Verifies setting individual custom thresholds and clamping logic
    test('setThreshold lowers threshold and triggers', () {
      priorityEngine.setThreshold('fireAlarm', 0.50);
      final result = makeResult('fireAlarm', 0.55);
      final priority = priorityEngine.evaluateAlert(result);
      expect(priority, PriorityLevel.high);
    });

    test('setThreshold raises threshold and does NOT trigger', () {
      priorityEngine.setThreshold('fireAlarm', 0.90);
      final result = makeResult('fireAlarm', 0.85);
      final priority = priorityEngine.evaluateAlert(result);
      expect(priority, isNull);
    });

    test('setThreshold clamps values: setting 0.1 clamps to 0.30', () {
      priorityEngine.setThreshold('fireAlarm', 0.1);
      final category = SoundCategory.values.firstWhere((c) => c.name == 'fireAlarm');
      expect(priorityEngine.getThresholdForCategory(category), 0.30);
    });

    test('setThreshold clamps values: setting 1.0 clamps to 0.95', () {
      priorityEngine.setThreshold('fireAlarm', 1.0);
      final category = SoundCategory.values.firstWhere((c) => c.name == 'fireAlarm');
      expect(priorityEngine.getThresholdForCategory(category), 0.95);
    });
  });

  group('Group 4: loadThresholds()', () {
    /// Verifies bulk loading of custom thresholds and replacing existing ones
    test('Loading multiple thresholds overrides defaults for those categories', () {
      priorityEngine.loadThresholds({
        'fireAlarm': 0.8,
        'doorbell': 0.8,
      });
      final fireAlarm = SoundCategory.values.firstWhere((c) => c.name == 'fireAlarm');
      final doorbell = SoundCategory.values.firstWhere((c) => c.name == 'doorbell');
      expect(priorityEngine.getThresholdForCategory(fireAlarm), 0.8);
      expect(priorityEngine.getThresholdForCategory(doorbell), 0.8);
      
      final result = makeResult('fireAlarm', 0.75);
      expect(priorityEngine.evaluateAlert(result), isNull);
    });

    test('loadThresholds replaces previous custom thresholds', () {
      priorityEngine.setThreshold('fireAlarm', 0.5);
      priorityEngine.loadThresholds({'doorbell': 0.8});
      
      final fireAlarm = SoundCategory.values.firstWhere((c) => c.name == 'fireAlarm');
      final doorbell = SoundCategory.values.firstWhere((c) => c.name == 'doorbell');
      
      expect(priorityEngine.getThresholdForCategory(doorbell), 0.8);
      // 'fireAlarm' should be back to default 0.70 because old custom thresholds are cleared
      expect(priorityEngine.getThresholdForCategory(fireAlarm), 0.70);
    });
  });

  group('Group 5: Unknown Category', () {
    /// Verifies behavior when an unknown category is passed
    test('evaluateAlert with unknown category returns null', () {
      final result = makeResult('unknownSound', 0.9);
      expect(priorityEngine.evaluateAlert(result), isNull);
    });

    test('getPriorityForCategory with unknown category returns low priority', () {
      expect(priorityEngine.getPriorityForCategory('unknownSound'), PriorityLevel.low);
    });
  });

  group('Group 6: getPriorityForCategory()', () {
    /// Verifies getting priority for category name directly
    test('Returns correct priority for all known categories', () {
      expect(priorityEngine.getPriorityForCategory('fireAlarm'), PriorityLevel.high);
      expect(priorityEngine.getPriorityForCategory('smokeAlarm'), PriorityLevel.high);
      expect(priorityEngine.getPriorityForCategory('emergencySiren'), PriorityLevel.high);
      expect(priorityEngine.getPriorityForCategory('glassBreaking'), PriorityLevel.high);
      
      expect(priorityEngine.getPriorityForCategory('doorbell'), PriorityLevel.medium);
      expect(priorityEngine.getPriorityForCategory('knocking'), PriorityLevel.medium);
      expect(priorityEngine.getPriorityForCategory('babyCrying'), PriorityLevel.medium);
      
      expect(priorityEngine.getPriorityForCategory('dogBarking'), PriorityLevel.low);
      expect(priorityEngine.getPriorityForCategory('vehicleHorn'), PriorityLevel.low);
    });

    test('Returns PriorityLevel.low for unknown categories', () {
      expect(priorityEngine.getPriorityForCategory('random_noise'), PriorityLevel.low);
    });
  });

  group('Group 7: Each category at its exact threshold boundary', () {
    /// Verifies exact threshold behaviors (hit and miss) for every default category threshold
    final thresholds = {
      'fireAlarm': 0.70,
      'smokeAlarm': 0.70,
      'emergencySiren': 0.75,
      'glassBreaking': 0.80,
      'doorbell': 0.75,
      'knocking': 0.75,
      'babyCrying': 0.70,
      'dogBarking': 0.80,
      'vehicleHorn': 0.80,
    };

    test('Test every category at exactly its default threshold should trigger', () {
      for (final entry in thresholds.entries) {
        final category = entry.key;
        final threshold = entry.value;
        final result = makeResult(category, threshold);
        expect(priorityEngine.evaluateAlert(result), isNotNull, reason: 'Failed for $category at threshold $threshold');
      }
    });

    test('Test every category at threshold - 0.01 should NOT trigger', () {
      for (final entry in thresholds.entries) {
        final category = entry.key;
        final threshold = entry.value;
        // Subtract 0.01 carefully avoiding double precision floating point issues
        final loweredThreshold = (threshold * 100 - 1) / 100;
        final result = makeResult(category, loweredThreshold);
        expect(priorityEngine.evaluateAlert(result), isNull, reason: 'Failed for $category at threshold $loweredThreshold');
      }
    });
  });
}
