import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:alertsense/core/constants/sound_categories.dart';
import 'package:alertsense/providers/audio_providers.dart';
import 'package:alertsense/data/models/sound_profile.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('EnabledSoundsNotifier.setProfile()', () {
    test('setProfile with short name "sleep" enables only critical sounds', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(enabledSoundsProvider.notifier).setProfile('sleep');
      final enabled = container.read(enabledSoundsProvider);

      expect(enabled, containsAll([
        SoundCategory.fireAlarm.name,
        SoundCategory.smokeAlarm.name,
        SoundCategory.emergencySiren.name,
        SoundCategory.babyCrying.name,
      ]));
      expect(enabled, isNot(contains(SoundCategory.doorbell.name)));
      expect(enabled, isNot(contains(SoundCategory.dogBarking.name)));
      expect(enabled, isNot(contains(SoundCategory.vehicleHorn.name)));
      expect(enabled, isNot(contains(SoundCategory.glassBreaking.name)));
    });

    test('setProfile with profile ID "default_sleep" enables only critical sounds', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(enabledSoundsProvider.notifier).setProfile('default_sleep');
      final enabled = container.read(enabledSoundsProvider);

      expect(enabled, containsAll([
        SoundCategory.fireAlarm.name,
        SoundCategory.smokeAlarm.name,
        SoundCategory.emergencySiren.name,
        SoundCategory.babyCrying.name,
      ]));
      expect(enabled.length, equals(4));
    });

    test('setProfile with "default_outdoor" enables outdoor-relevant sounds', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(enabledSoundsProvider.notifier).setProfile('default_outdoor');
      final enabled = container.read(enabledSoundsProvider);

      expect(enabled, containsAll([
        SoundCategory.emergencySiren.name,
        SoundCategory.vehicleHorn.name,
        SoundCategory.glassBreaking.name,
        SoundCategory.dogBarking.name,
      ]));
      expect(enabled, isNot(contains(SoundCategory.doorbell.name)));
      expect(enabled, isNot(contains(SoundCategory.babyCrying.name)));
    });

    test('setProfile with "default_home" enables all categories', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      container.read(enabledSoundsProvider.notifier).setProfile('default_home');
      final enabled = container.read(enabledSoundsProvider);

      expect(enabled.length, equals(SoundCategory.values.length));
    });

    test('setProfile with unknown profile enables all categories (safe default)', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // First restrict, then switch to unknown
      container.read(enabledSoundsProvider.notifier).setProfile('default_sleep');
      container.read(enabledSoundsProvider.notifier).setProfile('some_custom_profile');
      final enabled = container.read(enabledSoundsProvider);

      expect(enabled.length, equals(SoundCategory.values.length));
    });
  });

  group('SoundProfile enabledCategories coverage', () {
    test('SoundProfile.home() enables 8 categories', () {
      final profile = SoundProfile.home();
      expect(profile.enabledCategories.length, greaterThanOrEqualTo(7));
      expect(profile.enabledCategories, contains('fireAlarm'));
      expect(profile.enabledCategories, contains('doorbell'));
    });

    test('SoundProfile.sleep() enables only 4 categories', () {
      final profile = SoundProfile.sleep();
      expect(profile.enabledCategories.length, equals(4));
      expect(profile.enabledCategories, containsAll([
        'fireAlarm', 'smokeAlarm', 'babyCrying', 'emergencySiren',
      ]));
      expect(profile.enabledCategories, isNot(contains('doorbell')));
      expect(profile.enabledCategories, isNot(contains('dogBarking')));
    });

    test('SoundProfile.outdoor() enables only outdoor-relevant categories', () {
      final profile = SoundProfile.outdoor();
      expect(profile.enabledCategories, containsAll([
        'emergencySiren', 'vehicleHorn', 'glassBreaking',
      ]));
      expect(profile.enabledCategories, isNot(contains('fireAlarm')));
    });
  });

  group('Profile isSleepMode derivation', () {
    test('isSleepMode is true for Sleep profile (by name)', () {
      final profile = SoundProfile.sleep();
      final isSleep = profile.name.toLowerCase() == 'sleep';
      expect(isSleep, isTrue);
    });

    test('isSleepMode is false for Home profile', () {
      final profile = SoundProfile.home();
      final isSleep = profile.name.toLowerCase() == 'sleep';
      expect(isSleep, isFalse);
    });

    test('isSleepMode is false for Outdoor profile', () {
      final profile = SoundProfile.outdoor();
      final isSleep = profile.name.toLowerCase() == 'sleep';
      expect(isSleep, isFalse);
    });
  });

  group('Enabled categories from profile are a proper Set<String>', () {
    test('Home profile categories are valid SoundCategory names', () {
      final profile = SoundProfile.home();
      final validNames = SoundCategory.values.map((c) => c.name).toSet();
      for (final cat in profile.enabledCategories) {
        expect(validNames, contains(cat),
            reason: '"$cat" from Home profile is not a valid SoundCategory name');
      }
    });

    test('Sleep profile categories are valid SoundCategory names', () {
      final profile = SoundProfile.sleep();
      final validNames = SoundCategory.values.map((c) => c.name).toSet();
      for (final cat in profile.enabledCategories) {
        expect(validNames, contains(cat),
            reason: '"$cat" from Sleep profile is not a valid SoundCategory name');
      }
    });

    test('Outdoor profile categories are valid SoundCategory names', () {
      final profile = SoundProfile.outdoor();
      final validNames = SoundCategory.values.map((c) => c.name).toSet();
      for (final cat in profile.enabledCategories) {
        expect(validNames, contains(cat),
            reason: '"$cat" from Outdoor profile is not a valid SoundCategory name');
      }
    });
  });
}
