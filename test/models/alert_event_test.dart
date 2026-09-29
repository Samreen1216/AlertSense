import 'package:flutter_test/flutter_test.dart';
import 'package:alertsense/data/models/alert_event.dart';

void main() {
  final testDate = DateTime(2023, 1, 1, 12, 0, 0);

  group('Construction', () {
    /// Verifies construction with minimum required fields and default values
    test('default values are set correctly', () {
      final event = AlertEvent(
        id: '123',
        soundCategory: 'Fire Alarm',
        priorityLevel: 'High',
        confidence: 0.95,
        timestamp: testDate,
      );

      expect(event.id, '123');
      expect(event.soundCategory, 'Fire Alarm');
      expect(event.priorityLevel, 'High');
      expect(event.confidence, 0.95);
      expect(event.timestamp, testDate);
      expect(event.acknowledged, isFalse);
      expect(event.durationSeconds, isNull);
      expect(event.responseAction, isNull);
      expect(event.source, 'Continuous Monitoring');
    });

    /// Verifies construction with all fields provided
    test('all fields can be set', () {
      final event = AlertEvent(
        id: '123',
        soundCategory: 'Doorbell',
        priorityLevel: 'Low',
        confidence: 0.8,
        timestamp: testDate,
        acknowledged: true,
        durationSeconds: 5,
        responseAction: 'Notified user',
        source: 'Microphone',
      );

      expect(event.acknowledged, isTrue);
      expect(event.durationSeconds, 5);
      expect(event.responseAction, 'Notified user');
      expect(event.source, 'Microphone');
    });
  });

  group('copyWith', () {
    /// Verifies copyWith changes specified individual fields and leaves others unchanged
    test('changes individual fields and leaves others unchanged', () {
      final event = AlertEvent(
        id: '123',
        soundCategory: 'Fire Alarm',
        priorityLevel: 'High',
        confidence: 0.95,
        timestamp: testDate,
      );

      final newDate = DateTime(2023, 1, 2);
      final copied = event.copyWith(
        id: '456',
        acknowledged: true,
        timestamp: newDate,
      );

      expect(copied.id, '456');
      expect(copied.soundCategory, 'Fire Alarm');
      expect(copied.priorityLevel, 'High');
      expect(copied.confidence, 0.95);
      expect(copied.timestamp, newDate);
      expect(copied.acknowledged, isTrue);
      expect(copied.source, 'Continuous Monitoring');
    });
  });

  group('toMap / fromMap serialization', () {
    /// Verifies round-trip serialization using Maps
    test('serializes and deserializes correctly', () {
      final event = AlertEvent(
        id: '123',
        soundCategory: 'Siren',
        priorityLevel: 'High',
        confidence: 0.99,
        timestamp: testDate,
        acknowledged: true,
        durationSeconds: 10,
        responseAction: 'Flashed lights',
        source: 'Wearable',
      );

      final map = event.toMap();
      final decoded = AlertEvent.fromMap(map);

      expect(decoded.id, event.id);
      expect(decoded.soundCategory, event.soundCategory);
      expect(decoded.priorityLevel, event.priorityLevel);
      expect(decoded.confidence, event.confidence);
      expect(decoded.timestamp, event.timestamp);
      expect(decoded.acknowledged, event.acknowledged);
      expect(decoded.durationSeconds, event.durationSeconds);
      expect(decoded.responseAction, event.responseAction);
      expect(decoded.source, event.source);
    });
  });

  group('toJson / fromJson serialization', () {
    /// Verifies round-trip serialization using JSON strings
    test('serializes and deserializes correctly', () {
      final event = AlertEvent(
        id: '456',
        soundCategory: 'Dog Barking',
        priorityLevel: 'Medium',
        confidence: 0.85,
        timestamp: testDate,
      );

      final jsonString = event.toJson();
      final decoded = AlertEvent.fromJson(jsonString);

      expect(decoded.id, event.id);
      expect(decoded.soundCategory, event.soundCategory);
      expect(decoded.priorityLevel, event.priorityLevel);
      expect(decoded.confidence, event.confidence);
      expect(decoded.timestamp, event.timestamp);
    });
  });

  group('fromMap edge cases', () {
    /// Verifies missing or null fields use default values
    test('handles missing or null fields with defaults', () {
      final map = <String, dynamic>{
        // Intentionally empty
      };

      final event = AlertEvent.fromMap(map);

      expect(event.id, '');
      expect(event.soundCategory, '');
      expect(event.priorityLevel, '');
      expect(event.confidence, 0.0);
      expect(event.acknowledged, isFalse);
      expect(event.durationSeconds, isNull);
      expect(event.responseAction, isNull);
      expect(event.source, 'Continuous Monitoring');
      expect(event.timestamp, isNotNull);
    });

    /// Verifies invalid timestamps fall back to current time
    test('handles invalid timestamp falling back to now', () {
      final before = DateTime.now();
      final map = <String, dynamic>{
        'timestamp': 'invalid-date-format',
      };

      final event = AlertEvent.fromMap(map);
      final after = DateTime.now();

      expect(event.timestamp.isAfter(before) || event.timestamp.isAtSameMomentAs(before), isTrue);
      expect(event.timestamp.isBefore(after) || event.timestamp.isAtSameMomentAs(after), isTrue);
    });
  });
}
