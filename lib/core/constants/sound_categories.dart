import 'package:flutter/material.dart';
import 'priority_levels.dart';
import 'app_colors.dart';

enum SoundCategory {
  fireAlarm(
    label: 'Fire Alarm',
    emoji: '🔥',
    description: 'Loud alarm indicating fire',
    defaultPriority: PriorityLevel.high,
    color: AppColors.fireAlarm,
    icon: Icons.local_fire_department,
    yamnetLabels: [
      'Fire alarm',
      'Smoke detector, smoke alarm',
      'Alarm',
      'Buzzer',
    ],
    defaultThreshold: 0.70,
  ),
  smokeAlarm(
    label: 'Smoke Alarm',
    emoji: '💨',
    description: 'High-pitched smoke detector beep',
    defaultPriority: PriorityLevel.high,
    color: AppColors.smokeAlarm,
    icon: Icons.smoke_free,
    yamnetLabels: [
      'Smoke detector, smoke alarm',
      'Fire alarm',
      'Alarm',
    ],
    defaultThreshold: 0.70,
  ),
  emergencySiren(
    label: 'Emergency Siren',
    emoji: '🚓',
    description: 'Police, ambulance, or fire truck siren',
    defaultPriority: PriorityLevel.high,
    color: AppColors.emergencySiren,
    icon: Icons.local_police,
    yamnetLabels: [
      'Siren',
      'Civil defense siren',
      'Ambulance (siren)',
      'Police car (siren)',
      'Fire engine, fire truck (siren)',
      'Car alarm',
    ],
    defaultThreshold: 0.75,
  ),
  glassBreaking(
    label: 'Glass Breaking',
    emoji: '🪟',
    description: 'Sound of shattering glass',
    defaultPriority: PriorityLevel.high,
    color: AppColors.glassBreaking,
    icon: Icons.window,
    yamnetLabels: [
      'Shatter',
      'Glass',
    ],
    defaultThreshold: 0.80,
  ),
  doorbell(
    label: 'Doorbell',
    emoji: '🔔',
    description: 'Someone may be at the door',
    defaultPriority: PriorityLevel.medium,
    color: AppColors.doorbell,
    icon: Icons.doorbell,
    yamnetLabels: [
      'Doorbell',
      'Ding-dong',
      'Bell ring',
      'Chime',
      'Bell',
    ],
    defaultThreshold: 0.75,
  ),
  knocking(
    label: 'Knocking',
    emoji: '🚪',
    description: 'Someone knocking on a door',
    defaultPriority: PriorityLevel.medium,
    color: AppColors.knocking,
    icon: Icons.back_hand,
    yamnetLabels: [
      'Knock',
      'Door',
      'Tap',
    ],
    defaultThreshold: 0.75,
  ),
  babyCrying(
    label: 'Baby Crying',
    emoji: '👶',
    description: 'Infant or baby crying',
    defaultPriority: PriorityLevel.medium,
    color: AppColors.babyCrying,
    icon: Icons.child_care,
    yamnetLabels: [
      'Baby cry, infant cry',
      'Crying, sobbing',
    ],
    defaultThreshold: 0.70,
  ),
  dogBarking(
    label: 'Dog Barking',
    emoji: '🐕',
    description: 'Dog barking or howling',
    defaultPriority: PriorityLevel.low,
    color: AppColors.dogBarking,
    icon: Icons.pets,
    yamnetLabels: [
      'Bark',
      'Bow-wow',
      'Yip',
      'Howl',
      'Dog',
    ],
    defaultThreshold: 0.80,
  ),
  vehicleHorn(
    label: 'Vehicle Horn',
    emoji: '🚗',
    description: 'Car or truck horn honking',
    defaultPriority: PriorityLevel.low,
    color: AppColors.vehicleHorn,
    icon: Icons.directions_car,
    yamnetLabels: [
      'Vehicle horn, car horn, honking',
      'Air horn, truck horn',
      'Train horn',
      'Foghorn',
    ],
    defaultThreshold: 0.80,
  );

  final String label;
  final String emoji;
  final String description;
  final PriorityLevel defaultPriority;
  final Color color;
  final IconData icon;
  final List<String> yamnetLabels;
  final double defaultThreshold;

  const SoundCategory({
    required this.label,
    required this.emoji,
    required this.description,
    required this.defaultPriority,
    required this.color,
    required this.icon,
    required this.yamnetLabels,
    required this.defaultThreshold,
  });
}

extension SoundCategoryExtension on SoundCategory {
  /// Conservative, exact case-insensitive matching between YAMNet AudioSet label and SoundCategory.
  /// Eliminates broad substring false positives.
  static SoundCategory? fromYamnetLabel(String label) {
    final lower = label.toLowerCase().trim();
    for (final category in SoundCategory.values) {
      if (category.yamnetLabels.any((yLabel) => yLabel.toLowerCase().trim() == lower)) {
        return category;
      }
    }
    return null;
  }

  static SoundCategory? fromName(String name) {
    final lower = name.toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '');
    for (final category in SoundCategory.values) {
      if (category.name.toLowerCase() == lower ||
          category.label.toLowerCase().replaceAll(RegExp(r'[\s_\-]'), '') == lower) {
        return category;
      }
    }
    return null;
  }
}
