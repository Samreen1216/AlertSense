import 'dart:convert';

class SoundProfile {
  final String id;
  final String name; // 'Home', 'Sleep', 'Outdoor', 'Custom'
  final String emoji; // '🏠', '🌙', '🌳'
  final List<String> enabledCategories; // list of SoundCategory enum names
  final bool isDefault;
  final Map<String, double> sensitivityOverrides; // category -> threshold

  const SoundProfile({
    required this.id,
    required this.name,
    required this.emoji,
    required this.enabledCategories,
    this.isDefault = false,
    this.sensitivityOverrides = const {},
  });

  SoundProfile copyWith({
    String? id,
    String? name,
    String? emoji,
    List<String>? enabledCategories,
    bool? isDefault,
    Map<String, double>? sensitivityOverrides,
  }) {
    return SoundProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      enabledCategories: enabledCategories ?? this.enabledCategories,
      isDefault: isDefault ?? this.isDefault,
      sensitivityOverrides: sensitivityOverrides ?? this.sensitivityOverrides,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'emoji': emoji,
      'enabledCategories': enabledCategories,
      'isDefault': isDefault,
      'sensitivityOverrides': sensitivityOverrides,
    };
  }

  factory SoundProfile.fromMap(Map<String, dynamic> map) {
    return SoundProfile(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      emoji: map['emoji'] ?? '',
      enabledCategories: List<String>.from(map['enabledCategories'] ?? []),
      isDefault: map['isDefault'] ?? false,
      sensitivityOverrides: Map<String, double>.from(map['sensitivityOverrides'] ?? {}),
    );
  }

  String toJson() => json.encode(toMap());

  factory SoundProfile.fromJson(String source) => SoundProfile.fromMap(json.decode(source));

  factory SoundProfile.home() {
    return const SoundProfile(
      id: 'default_home',
      name: 'Home',
      emoji: '🏠',
      enabledCategories: [
        'fireAlarm', 'smokeAlarm', 'babyCrying', 'emergencySiren',
        'doorbell', 'dogBarking', 'vehicleHorn', 'glassBreaking'
      ],
      isDefault: true,
    );
  }

  factory SoundProfile.sleep() {
    return const SoundProfile(
      id: 'default_sleep',
      name: 'Sleep',
      emoji: '🌙',
      enabledCategories: ['fireAlarm', 'smokeAlarm', 'babyCrying', 'emergencySiren'],
      isDefault: true,
    );
  }

  factory SoundProfile.outdoor() {
    return const SoundProfile(
      id: 'default_outdoor',
      name: 'Outdoor',
      emoji: '🌳',
      enabledCategories: ['emergencySiren', 'vehicleHorn', 'glassBreaking'],
      isDefault: true,
    );
  }
}
