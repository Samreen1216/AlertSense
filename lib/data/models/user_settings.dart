import 'dart:convert';

class UserSettings {
  final String activeProfileId;
  final String themeType; // 'light', 'dark', 'highContrast', 'colorBlindSafe'
  final double textScaleFactor;
  final bool flashEnabled;
  final bool vibrationEnabled;
  final bool onboardingCompleted;
  final bool autoStartOnBoot;
  final Map<String, int> cooldownSeconds; // category -> cooldown duration
  final List<String> emergencyContacts; // phone numbers
  final Map<String, List<int>> customVibrationPatterns; // category -> pattern
  
  const UserSettings({
    this.activeProfileId = 'default_home',
    this.themeType = 'light',
    this.textScaleFactor = 1.0,
    this.flashEnabled = true,
    this.vibrationEnabled = true,
    this.onboardingCompleted = false,
    this.autoStartOnBoot = false,
    this.cooldownSeconds = const {},
    this.emergencyContacts = const [],
    this.customVibrationPatterns = const {},
  });

  UserSettings copyWith({
    String? activeProfileId,
    String? themeType,
    double? textScaleFactor,
    bool? flashEnabled,
    bool? vibrationEnabled,
    bool? onboardingCompleted,
    bool? autoStartOnBoot,
    Map<String, int>? cooldownSeconds,
    List<String>? emergencyContacts,
    Map<String, List<int>>? customVibrationPatterns,
  }) {
    return UserSettings(
      activeProfileId: activeProfileId ?? this.activeProfileId,
      themeType: themeType ?? this.themeType,
      textScaleFactor: textScaleFactor ?? this.textScaleFactor,
      flashEnabled: flashEnabled ?? this.flashEnabled,
      vibrationEnabled: vibrationEnabled ?? this.vibrationEnabled,
      onboardingCompleted: onboardingCompleted ?? this.onboardingCompleted,
      autoStartOnBoot: autoStartOnBoot ?? this.autoStartOnBoot,
      cooldownSeconds: cooldownSeconds ?? this.cooldownSeconds,
      emergencyContacts: emergencyContacts ?? this.emergencyContacts,
      customVibrationPatterns: customVibrationPatterns ?? this.customVibrationPatterns,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'activeProfileId': activeProfileId,
      'themeType': themeType,
      'textScaleFactor': textScaleFactor,
      'flashEnabled': flashEnabled,
      'vibrationEnabled': vibrationEnabled,
      'onboardingCompleted': onboardingCompleted,
      'autoStartOnBoot': autoStartOnBoot,
      'cooldownSeconds': cooldownSeconds,
      'emergencyContacts': emergencyContacts,
      'customVibrationPatterns': customVibrationPatterns,
    };
  }

  factory UserSettings.fromMap(Map<String, dynamic> map) {
    return UserSettings(
      activeProfileId: map['activeProfileId'] ?? 'default_home',
      themeType: map['themeType'] ?? 'light',
      textScaleFactor: map['textScaleFactor']?.toDouble() ?? 1.0,
      flashEnabled: map['flashEnabled'] ?? true,
      vibrationEnabled: map['vibrationEnabled'] ?? true,
      onboardingCompleted: map['onboardingCompleted'] ?? false,
      autoStartOnBoot: map['autoStartOnBoot'] ?? false,
      cooldownSeconds: Map<String, int>.from(map['cooldownSeconds'] ?? {}),
      emergencyContacts: List<String>.from(map['emergencyContacts'] ?? []),
      customVibrationPatterns: (map['customVibrationPatterns'] as Map<String, dynamic>?)?.map(
            (k, v) => MapEntry(k, List<int>.from(v)),
          ) ?? {},
    );
  }

  String toJson() => json.encode(toMap());

  factory UserSettings.fromJson(String source) => UserSettings.fromMap(json.decode(source));
}
