import 'package:flutter_test/flutter_test.dart';
import 'package:alertsense/core/constants/priority_levels.dart';
import 'package:alertsense/data/models/classification_result.dart';
import 'package:alertsense/services/priority_engine.dart';

void main() {
  group('PriorityEngine Tests', () {
    late PriorityEngine engine;

    setUp(() {
      engine = PriorityEngine();
    });

    test('Fire Alarm above threshold triggers HIGH priority', () {
      final result = ClassificationResult(
        soundCategory: 'fireAlarm',
        confidence: 0.92,
        timestamp: DateTime.now(),
        topPredictions: const [MapEntry('Fire alarm', 0.92)],
        ambientDbLevel: 65.0,
      );

      final priority = engine.evaluateAlert(result);
      expect(priority, equals(PriorityLevel.high));
    });

    test('Doorbell above threshold triggers MEDIUM priority', () {
      final result = ClassificationResult(
        soundCategory: 'doorbell',
        confidence: 0.78,
        timestamp: DateTime.now(),
        topPredictions: const [MapEntry('Doorbell', 0.78)],
        ambientDbLevel: 55.0,
      );

      final priority = engine.evaluateAlert(result);
      expect(priority, equals(PriorityLevel.medium));
    });

    test('Dog Barking above threshold triggers LOW priority', () {
      final result = ClassificationResult(
        soundCategory: 'dogBarking',
        confidence: 0.80,
        timestamp: DateTime.now(),
        topPredictions: const [MapEntry('Dog', 0.80)],
        ambientDbLevel: 50.0,
      );

      final priority = engine.evaluateAlert(result);
      expect(priority, equals(PriorityLevel.low));
    });

    test('Confidence below threshold returns null (no alert)', () {
      final result = ClassificationResult(
        soundCategory: 'fireAlarm',
        confidence: 0.20, // well below 0.60 threshold
        timestamp: DateTime.now(),
        topPredictions: const [MapEntry('Fire alarm', 0.20)],
        ambientDbLevel: 40.0,
      );

      final priority = engine.evaluateAlert(result);
      expect(priority, isNull);
    });

    test('Custom threshold override works', () {
      engine.setThreshold('doorbell', 0.90);

      final result = ClassificationResult(
        soundCategory: 'doorbell',
        confidence: 0.85, // below custom 0.90 threshold
        timestamp: DateTime.now(),
        topPredictions: const [MapEntry('Doorbell', 0.85)],
        ambientDbLevel: 55.0,
      );

      final priority = engine.evaluateAlert(result);
      expect(priority, isNull);
    });
  });
}
