import 'package:flutter_test/flutter_test.dart';
import 'package:alertsense/services/deduplication_service.dart';
import 'package:alertsense/core/constants/sound_categories.dart';

void main() {
  late DeduplicationService deduplicationService;

  setUp(() {
    deduplicationService = DeduplicationService();
  });

  /// Group 1: First Alert Always Triggers
  group('Group 1: First Alert Always Triggers', () {
    test('First call for fireAlarm always returns true', () {
      expect(
        deduplicationService.shouldTriggerAlert(category: SoundCategory.fireAlarm),
        isTrue,
      );
    });

    test('First call for doorbell always returns true', () {
      expect(
        deduplicationService.shouldTriggerAlert(category: SoundCategory.doorbell),
        isTrue,
      );
    });

    test('First call for vehicleHorn always returns true', () {
      expect(
        deduplicationService.shouldTriggerAlert(category: SoundCategory.vehicleHorn),
        isTrue,
      );
    });
  });

  /// Group 2: Immediate Repeat is Suppressed
  group('Group 2: Immediate Repeat is Suppressed', () {
    test('Calling shouldTriggerAlert twice in rapid succession returns true then false', () {
      // First call triggers
      expect(
        deduplicationService.shouldTriggerAlert(category: SoundCategory.fireAlarm),
        isTrue,
      );
      // Immediate second call is suppressed due to cooldown
      expect(
        deduplicationService.shouldTriggerAlert(category: SoundCategory.fireAlarm),
        isFalse,
      );
    });
  });

  /// Group 3: Ongoing Event Count Tracking
  group('Group 3: Ongoing Event Count Tracking', () {
    test('After first trigger, getOngoingCount returns 1', () {
      deduplicationService.shouldTriggerAlert(category: SoundCategory.emergencySiren);
      expect(deduplicationService.getOngoingCount(SoundCategory.emergencySiren), 1);
    });

    test('After suppressed second call, getOngoingCount returns 2', () {
      deduplicationService.shouldTriggerAlert(category: SoundCategory.emergencySiren);
      deduplicationService.shouldTriggerAlert(category: SoundCategory.emergencySiren);
      expect(deduplicationService.getOngoingCount(SoundCategory.emergencySiren), 2);
    });

    test('After multiple suppressed calls, count keeps incrementing', () {
      deduplicationService.shouldTriggerAlert(category: SoundCategory.emergencySiren);
      deduplicationService.shouldTriggerAlert(category: SoundCategory.emergencySiren);
      deduplicationService.shouldTriggerAlert(category: SoundCategory.emergencySiren);
      deduplicationService.shouldTriggerAlert(category: SoundCategory.emergencySiren);
      expect(deduplicationService.getOngoingCount(SoundCategory.emergencySiren), 4);
    });
  });

  /// Group 4: Default Cooldown Values
  group('Group 4: Default Cooldown Values', () {
    test('Verify all 9 default cooldown durations are correct', () {
      expect(DeduplicationService.defaultCooldowns['fireAlarm'], 30);
      expect(DeduplicationService.defaultCooldowns['smokeAlarm'], 30);
      expect(DeduplicationService.defaultCooldowns['emergencySiren'], 30);
      expect(DeduplicationService.defaultCooldowns['glassBreaking'], 25);
      expect(DeduplicationService.defaultCooldowns['doorbell'], 15);
      expect(DeduplicationService.defaultCooldowns['knocking'], 12);
      expect(DeduplicationService.defaultCooldowns['babyCrying'], 20);
      expect(DeduplicationService.defaultCooldowns['dogBarking'], 15);
      expect(DeduplicationService.defaultCooldowns['vehicleHorn'], 10);
    });
  });

  /// Group 5: Custom Cooldowns
  group('Group 5: Custom Cooldowns', () {
    test('Passing customCooldowns overrides the default for that call', () {
      expect(
        deduplicationService.shouldTriggerAlert(
          category: SoundCategory.fireAlarm,
          customCooldowns: {'fireAlarm': 5},
        ),
        isTrue,
      );
      
      expect(
        deduplicationService.shouldTriggerAlert(
          category: SoundCategory.fireAlarm,
          customCooldowns: {'fireAlarm': 5},
        ),
        isFalse,
      );
    });
  });

  /// Group 6: Reset Functionality
  group('Group 6: Reset Functionality', () {
    test('reset() clears all categories, next call triggers again', () {
      deduplicationService.shouldTriggerAlert(category: SoundCategory.fireAlarm);
      deduplicationService.shouldTriggerAlert(category: SoundCategory.doorbell);
      
      deduplicationService.reset();
      
      expect(
        deduplicationService.shouldTriggerAlert(category: SoundCategory.fireAlarm),
        isTrue,
      );
      expect(
        deduplicationService.shouldTriggerAlert(category: SoundCategory.doorbell),
        isTrue,
      );
    });

    test('reset("fireAlarm") clears only fireAlarm, leaves others intact', () {
      deduplicationService.shouldTriggerAlert(category: SoundCategory.fireAlarm);
      deduplicationService.shouldTriggerAlert(category: SoundCategory.doorbell);
      
      deduplicationService.reset('fireAlarm');
      
      expect(
        deduplicationService.shouldTriggerAlert(category: SoundCategory.fireAlarm),
        isTrue,
      );
      expect(
        deduplicationService.shouldTriggerAlert(category: SoundCategory.doorbell),
        isFalse,
      );
    });
  });

  /// Group 7: Independent Category Tracking
  group('Group 7: Independent Category Tracking', () {
    test('fireAlarm and doorbell are tracked independently', () {
      expect(
        deduplicationService.shouldTriggerAlert(category: SoundCategory.fireAlarm),
        isTrue,
      );
      
      expect(
        deduplicationService.shouldTriggerAlert(category: SoundCategory.doorbell),
        isTrue,
      );
      
      expect(
        deduplicationService.shouldTriggerAlert(category: SoundCategory.fireAlarm),
        isFalse,
      );
    });
  });

  /// Group 8: getOngoingDurationSeconds
  group('Group 8: getOngoingDurationSeconds', () {
    test('Returns 0 for a category that was never triggered', () {
      expect(deduplicationService.getOngoingDurationSeconds(SoundCategory.fireAlarm), 0);
    });

    test('Returns >= 0 for a category that was triggered', () {
      deduplicationService.shouldTriggerAlert(category: SoundCategory.fireAlarm);
      final duration = deduplicationService.getOngoingDurationSeconds(SoundCategory.fireAlarm);
      expect(duration, greaterThanOrEqualTo(0));
    });
  });

  /// Group 9: getOngoingCount Edge Cases
  group('Group 9: getOngoingCount Edge Cases', () {
    test('Returns 1 for untriggered category (default)', () {
      expect(deduplicationService.getOngoingCount(SoundCategory.babyCrying), 1);
    });

    test('Correctly increments on suppression', () {
      deduplicationService.shouldTriggerAlert(category: SoundCategory.glassBreaking);
      deduplicationService.shouldTriggerAlert(category: SoundCategory.glassBreaking);
      expect(deduplicationService.getOngoingCount(SoundCategory.glassBreaking), 2);
    });
  });
}
