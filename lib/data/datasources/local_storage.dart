import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_settings.dart';
import '../models/sound_profile.dart';
import '../models/alert_event.dart';

class LocalStorage {
  final SharedPreferences _prefs;

  LocalStorage(this._prefs);

  static Future<LocalStorage> create() async {
    final prefs = await SharedPreferences.getInstance();
    return LocalStorage(prefs);
  }

  Future<void> saveSettings(UserSettings settings) async {
    await _prefs.setString('user_settings', settings.toJson());
  }

  UserSettings loadSettings() {
    final jsonStr = _prefs.getString('user_settings');
    if (jsonStr != null) {
      try {
        return UserSettings.fromJson(jsonStr);
      } catch (_) {}
    }
    return const UserSettings();
  }

  Future<void> saveProfiles(List<SoundProfile> profiles) async {
    final jsonList = profiles.map((p) => p.toMap()).toList();
    await _prefs.setString('sound_profiles', json.encode(jsonList));
  }

  List<SoundProfile> loadProfiles() {
    final jsonStr = _prefs.getString('sound_profiles');
    if (jsonStr != null) {
      try {
        final List<dynamic> jsonList = json.decode(jsonStr);
        return jsonList.map((m) => SoundProfile.fromMap(m)).toList();
      } catch (_) {}
    }
    return [
      SoundProfile.home(),
      SoundProfile.sleep(),
      SoundProfile.outdoor(),
    ];
  }

  Future<void> saveAlerts(List<AlertEvent> alerts) async {
    final jsonList = alerts.map((a) => a.toMap()).toList();
    await _prefs.setString('alerts', json.encode(jsonList));
  }

  List<AlertEvent> loadAlerts() {
    final jsonStr = _prefs.getString('alerts');
    if (jsonStr != null) {
      try {
        final List<dynamic> jsonList = json.decode(jsonStr);
        return jsonList.map((m) => AlertEvent.fromMap(m)).toList();
      } catch (_) {}
    }
    return [];
  }

  Future<void> setOnboardingComplete() async {
    final settings = loadSettings().copyWith(onboardingCompleted: true);
    await saveSettings(settings);
  }

  bool isOnboardingComplete() {
    return loadSettings().onboardingCompleted;
  }
}
