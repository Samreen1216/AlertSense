import '../datasources/local_storage.dart';
import '../models/user_settings.dart';
import '../models/sound_profile.dart';

class SettingsRepository {
  final LocalStorage _storage;
  UserSettings _settings = const UserSettings();
  List<SoundProfile> _profiles = [];

  SettingsRepository(this._storage);

  Future<void> init() async {
    _settings = _storage.loadSettings();
    _profiles = _storage.loadProfiles();
  }

  UserSettings get settings => _settings;
  List<SoundProfile> get profiles => List.unmodifiable(_profiles);

  Future<void> updateSettings(UserSettings settings) async {
    _settings = settings;
    await _storage.saveSettings(_settings);
  }

  Future<void> saveProfile(SoundProfile profile) async {
    final index = _profiles.indexWhere((p) => p.id == profile.id);
    if (index != -1) {
      _profiles[index] = profile;
    } else {
      _profiles.add(profile);
    }
    await _storage.saveProfiles(_profiles);
  }

  Future<void> deleteProfile(String id) async {
    _profiles.removeWhere((p) => p.id == id);
    await _storage.saveProfiles(_profiles);
  }

  SoundProfile getActiveProfile() {
    return _profiles.firstWhere(
      (p) => p.id == _settings.activeProfileId,
      orElse: () => SoundProfile.home(),
    );
  }

  Future<void> setActiveProfile(String profileId) async {
    await updateSettings(_settings.copyWith(activeProfileId: profileId));
  }
}
