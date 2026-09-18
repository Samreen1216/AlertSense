import 'package:flutter_test/flutter_test.dart';
import 'package:alertsense/core/constants/sound_categories.dart';
import 'package:alertsense/services/deduplication_service.dart';

void main() {
  group('DeduplicationService Tests', () {
    late DeduplicationService service;

    setUp(() {
      service = DeduplicationService();
    });

    test('First alert is always allowed', () {
      final allowed = service.shouldTriggerAlert(category: SoundCategory.fireAlarm);
      expect(allowed, isTrue);
    });

    test('Immediate second alert within cooldown is suppressed', () {
      service.shouldTriggerAlert(category: SoundCategory.fireAlarm);
      final allowed = service.shouldTriggerAlert(category: SoundCategory.fireAlarm);
      expect(allowed, isFalse);
    });

    test('Different sound category triggers independently', () {
      service.shouldTriggerAlert(category: SoundCategory.fireAlarm);
      final doorbellAllowed = service.shouldTriggerAlert(category: SoundCategory.doorbell);
      expect(doorbellAllowed, isTrue);
    });

    test('Reset clears cooldown and allows alert immediately', () {
      service.shouldTriggerAlert(category: SoundCategory.fireAlarm);
      service.reset('fireAlarm');
      final allowed = service.shouldTriggerAlert(category: SoundCategory.fireAlarm);
      expect(allowed, isTrue);
    });
  });
}
