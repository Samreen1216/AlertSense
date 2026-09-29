import 'package:flutter_test/flutter_test.dart';
import 'package:alertsense/data/models/sound_profile.dart';

void main() {
  group('Factory presets', () {
    /// Verifies Home profile has exactly 8 categories
    test('Home profile has 8 categories', () {
      final profile = SoundProfile.home();
      expect(profile.enabledCategories.length, 8);
      expect(
        profile.enabledCategories,
        containsAll([
          'fireAlarm',
          'smokeAlarm',
          'babyCrying',
          'emergencySiren',
          'doorbell',
          'dogBarking',
          'vehicleHorn',
          'glassBreaking'
        ]),
      );
    });

    /// Verifies Sleep profile has exactly 4 critical categories
    test('Sleep profile has 4 critical categories', () {
      final profile = SoundProfile.sleep();
      expect(profile.enabledCategories.length, 4);
    });

    /// Verifies Outdoor profile has exactly 4 categories
    test('Outdoor profile has 4 categories', () {
      final profile = SoundProfile.outdoor();
      expect(profile.enabledCategories.length, 4);
      expect(
        profile.enabledCategories,
        containsAll([
          'emergencySiren',
          'vehicleHorn',
          'glassBreaking',
          'dogBarking'
        ]),
      );
    });
  });

  group('Sleep profile specific rules', () {
    /// Verifies sleep profile ONLY includes life-safety categories
    test('ONLY includes life-safety categories', () {
      final profile = SoundProfile.sleep();
      expect(profile.enabledCategories, [
        'fireAlarm',
        'smokeAlarm',
        'babyCrying',
        'emergencySiren'
      ]);
    });
  });

  group('Default flag on presets', () {
    /// Verifies all factory presets have isDefault = true
    test('isDefault is true for all factory presets', () {
      expect(SoundProfile.home().isDefault, isTrue);
      expect(SoundProfile.sleep().isDefault, isTrue);
      expect(SoundProfile.outdoor().isDefault, isTrue);
    });
  });

  group('copyWith functionality', () {
    /// Verifies copyWith correctly copies and overwrites fields
    test('changes specified fields', () {
      final original = SoundProfile.home();
      final copied = original.copyWith(
        name: 'Custom Home',
        emoji: '🏰',
        isDefault: false,
      );

      expect(copied.id, original.id);
      expect(copied.name, 'Custom Home');
      expect(copied.emoji, '🏰');
      expect(copied.isDefault, isFalse);
      expect(copied.enabledCategories, original.enabledCategories);
    });
  });

  group('toMap / fromMap round-trip', () {
    /// Verifies round-trip serialization with Map
    test('serializes and deserializes correctly', () {
      const original = SoundProfile(
        id: 'custom_1',
        name: 'Office',
        emoji: '🏢',
        enabledCategories: ['fireAlarm', 'doorbell'],
        isDefault: false,
        sensitivityOverrides: {'fireAlarm': 0.8},
      );

      final map = original.toMap();
      final decoded = SoundProfile.fromMap(map);

      expect(decoded.id, original.id);
      expect(decoded.name, original.name);
      expect(decoded.emoji, original.emoji);
      expect(decoded.enabledCategories, original.enabledCategories);
      expect(decoded.isDefault, original.isDefault);
      expect(decoded.sensitivityOverrides, original.sensitivityOverrides);
    });
  });

  group('toJson / fromJson round-trip', () {
    /// Verifies round-trip serialization with JSON String
    test('serializes and deserializes correctly', () {
      const original = SoundProfile(
        id: 'custom_2',
        name: 'Gym',
        emoji: '🏋️',
        enabledCategories: ['emergencySiren'],
      );

      final jsonString = original.toJson();
      final decoded = SoundProfile.fromJson(jsonString);

      expect(decoded.id, original.id);
      expect(decoded.name, original.name);
      expect(decoded.emoji, original.emoji);
      expect(decoded.enabledCategories, original.enabledCategories);
      expect(decoded.isDefault, original.isDefault);
      expect(decoded.sensitivityOverrides, original.sensitivityOverrides);
    });
  });

  group('fromMap edge cases', () {
    /// Verifies defaults are used for missing fields in map
    test('handles missing fields with defaults', () {
      final map = <String, dynamic>{};
      final profile = SoundProfile.fromMap(map);

      expect(profile.id, '');
      expect(profile.name, '');
      expect(profile.emoji, '');
      expect(profile.enabledCategories, isEmpty);
      expect(profile.isDefault, isFalse);
      expect(profile.sensitivityOverrides, isEmpty);
    });
  });

  group('sensitivityOverrides serialization', () {
    /// Verifies sensitivity overrides map is correctly serialized and deserialized
    test('serializes and deserializes overrides', () {
      const original = SoundProfile(
        id: 'custom_3',
        name: 'Theater',
        emoji: '🎬',
        enabledCategories: ['fireAlarm'],
        sensitivityOverrides: {
          'fireAlarm': 0.95,
          'babyCrying': 0.5,
        },
      );

      final map = original.toMap();
      final decoded = SoundProfile.fromMap(map);

      expect(decoded.sensitivityOverrides['fireAlarm'], 0.95);
      expect(decoded.sensitivityOverrides['babyCrying'], 0.5);
    });
  });
}
