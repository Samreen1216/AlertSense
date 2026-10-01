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
    if (settings.onboardingCompleted) {
      await _prefs.setBool('onboarding_completed', true);
    }
  }

  UserSettings loadSettings() {
    final jsonStr = _prefs.getString('user_settings');
    UserSettings settings = const UserSettings();
    if (jsonStr != null) {
      try {
        settings = UserSettings.fromJson(jsonStr);
      } catch (_) {}
    }
    final directOnboarding = _prefs.getBool('onboarding_completed');
    if (directOnboarding == true && !settings.onboardingCompleted) {
      settings = settings.copyWith(onboardingCompleted: true);
    }
    return settings;
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
    await _prefs.setBool('onboarding_completed', true);
    final settings = loadSettings().copyWith(onboardingCompleted: true);
    await saveSettings(settings);
  }

  bool isOnboardingComplete() {
    final direct = _prefs.getBool('onboarding_completed');
    if (direct == true) return true;
    return loadSettings().onboardingCompleted;
  }

  Future<void> saveUserAuthDetails({
    required String email,
    String? fullName,
    String? userId,
  }) async {
    await _prefs.setString('auth_user_email', email);
    if (fullName != null && fullName.trim().isNotEmpty) {
      await _prefs.setString('auth_user_full_name', fullName.trim());
    }
    if (userId != null && userId.isNotEmpty) {
      await _prefs.setString('auth_user_id', userId);
    }
  }

  String? getSavedUserFullName() => _prefs.getString('auth_user_full_name');
  String? getSavedUserEmail() => _prefs.getString('auth_user_email');
  String? getSavedUserId() => _prefs.getString('auth_user_id');

  Future<void> clearUserAuthDetails() async {
    await _prefs.remove('auth_user_email');
    await _prefs.remove('auth_user_full_name');
    await _prefs.remove('auth_user_id');
  }
}
