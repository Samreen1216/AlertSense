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
    yamnetLabels: ['Fire alarm', 'Alarm'],
    defaultThreshold: 0.70,
  ),
  smokeAlarm(
    label: 'Smoke Alarm',
    emoji: '💨',
    description: 'High-pitched smoke detector beep',
    defaultPriority: PriorityLevel.high,
    color: AppColors.smokeAlarm,
    icon: Icons.smoke_free,
    yamnetLabels: ['Smoke detector, smoke alarm'],
    defaultThreshold: 0.65,
  ),
  emergencySiren(
    label: 'Emergency Siren',
    emoji: '🚓',
    description: 'Police, ambulance, or fire truck siren',
    defaultPriority: PriorityLevel.high,
    color: AppColors.emergencySiren,
    icon: Icons.local_police,
    yamnetLabels: ['Siren', 'Ambulance (siren)', 'Police car (siren)', 'Fire engine, fire truck (siren)'],
    defaultThreshold: 0.65,
  ),
  glassBreaking(
    label: 'Glass Breaking',
    emoji: '🪟',
    description: 'Sound of shattering glass',
    defaultPriority: PriorityLevel.high,
    color: AppColors.glassBreaking,
    icon: Icons.window,
    yamnetLabels: ['Glass', 'Chink, clink', 'Shatter'],
    defaultThreshold: 0.60,
  ),
  doorbell(
    label: 'Bell Ring',
    emoji: '🔔',
    description: 'Doorbell, bell ring, or chime',
    defaultPriority: PriorityLevel.medium,
    color: AppColors.doorbell,
    icon: Icons.doorbell,
    yamnetLabels: [
      'Bell ring',
      'Doorbell',
      'Ding-dong',
      'Chime',
      'Bell',
      'Bicycle bell',
      'Jingle bell',
      'Doorbell chime',
      'Alarm clock',
    ],
    defaultThreshold: 0.50,
  ),
  knocking(
    label: 'Knocking',
    emoji: '🚪',
    description: 'Someone knocking on a door',
    defaultPriority: PriorityLevel.medium,
    color: AppColors.knocking,
    icon: Icons.back_hand,
    yamnetLabels: ['Knock', 'Door', 'Wood'],
    defaultThreshold: 0.55,
  ),
  babyCrying(
    label: 'Baby Crying',
    emoji: '👶',
    description: 'Infant or baby crying',
    defaultPriority: PriorityLevel.medium,
    color: AppColors.babyCrying,
    icon: Icons.child_care,
    yamnetLabels: ['Crying, sobbing', 'Baby cry, infant cry'],
    defaultThreshold: 0.60,
  ),
  dogBarking(
    label: 'Dog Barking',
    emoji: '🐕',
    description: 'Dog barking or howling',
    defaultPriority: PriorityLevel.low,
    color: AppColors.dogBarking,
    icon: Icons.pets,
    yamnetLabels: ['Dog', 'Bark', 'Howl'],
    defaultThreshold: 0.60,
  ),
  vehicleHorn(
    label: 'Vehicle Horn',
    emoji: '🚗',
    description: 'Car or truck horn honking',
    defaultPriority: PriorityLevel.medium,
    color: AppColors.vehicleHorn,
    icon: Icons.directions_car,
    yamnetLabels: ['Vehicle horn, car horn, honking'],
    defaultThreshold: 0.65,
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
  static SoundCategory? fromYamnetLabel(String label) {
    final lower = label.toLowerCase().trim();
    for (final category in SoundCategory.values) {
      if (category.yamnetLabels.any((yLabel) => yLabel.toLowerCase() == lower)) {
        return category;
      }
    }
    // Substring match
    for (final category in SoundCategory.values) {
      if (category.yamnetLabels.any((yLabel) => lower.contains(yLabel.toLowerCase()))) {
        return category;
      }
    }
    return null;
  }
}
