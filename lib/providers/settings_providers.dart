import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/user_settings.dart';
import '../data/models/sound_profile.dart';
import '../main.dart';

class SettingsNotifier extends StateNotifier<UserSettings> {
  final Ref _ref;

  SettingsNotifier(this._ref) : super(const UserSettings()) {
    _load();
  }

  void _load() {
    final repo = _ref.read(settingsRepositoryProvider);
    state = repo.settings;
  }

  Future<void> updateSettings(UserSettings settings) async {
    state = settings;
    final repo = _ref.read(settingsRepositoryProvider);
    await repo.updateSettings(settings);
  }

  Future<void> setFlashEnabled(bool enabled) async {
    await updateSettings(state.copyWith(flashEnabled: enabled));
  }

  Future<void> setVibrationEnabled(bool enabled) async {
    await updateSettings(state.copyWith(vibrationEnabled: enabled));
  }

  Future<void> setActiveProfileId(String profileId) async {
    await updateSettings(state.copyWith(activeProfileId: profileId));
  }

  Future<void> setEmergencyContacts(List<String> contacts) async {
    await updateSettings(state.copyWith(emergencyContacts: contacts));
  }

  Future<void> setCooldownSeconds(String category, int seconds) async {
    final updated = Map<String, int>.from(state.cooldownSeconds);
    updated[category] = seconds;
    await updateSettings(state.copyWith(cooldownSeconds: updated));
  }

  Future<void> setCustomVibration(String category, List<int> pattern) async {
    final updated = Map<String, List<int>>.from(state.customVibrationPatterns);
    updated[category] = pattern;
    await updateSettings(state.copyWith(customVibrationPatterns: updated));
  }
}

final userSettingsProvider = StateNotifierProvider<SettingsNotifier, UserSettings>((ref) {
  return SettingsNotifier(ref);
});

class SoundProfilesNotifier extends StateNotifier<List<SoundProfile>> {
  final Ref _ref;

  SoundProfilesNotifier(this._ref) : super([]) {
    _load();
  }

  void _load() {
    final repo = _ref.read(settingsRepositoryProvider);
    state = repo.profiles;
  }

  Future<void> saveProfile(SoundProfile profile) async {
    final repo = _ref.read(settingsRepositoryProvider);
    await repo.saveProfile(profile);
    state = repo.profiles;
  }

  Future<void> deleteProfile(String id) async {
    final repo = _ref.read(settingsRepositoryProvider);
    await repo.deleteProfile(id);
    state = repo.profiles;
  }
}

final soundProfilesProvider = StateNotifierProvider<SoundProfilesNotifier, List<SoundProfile>>((ref) {
  return SoundProfilesNotifier(ref);
});

final currentProfileProvider = Provider<SoundProfile>((ref) {
  final settings = ref.watch(userSettingsProvider);
  final profiles = ref.watch(soundProfilesProvider);
  return profiles.firstWhere(
    (p) => p.id == settings.activeProfileId,
    orElse: () => SoundProfile.home(),
  );
});
