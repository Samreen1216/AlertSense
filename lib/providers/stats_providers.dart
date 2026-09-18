import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/constants/sound_categories.dart';
import 'alert_providers.dart';

final statsTimeRangeProvider = StateProvider<String>((ref) => 'week');

/// Returns total alerts grouped by sound category name for the bar chart.
final categoryFrequencyProvider = Provider<Map<String, int>>((ref) {
  final alerts = ref.watch(alertListProvider);
  final range = ref.watch(statsTimeRangeProvider);

  final now = DateTime.now();
  final cutoff = switch (range) {
    'today' => DateTime(now.year, now.month, now.day),
    'week' => now.subtract(const Duration(days: 7)),
    'month' => now.subtract(const Duration(days: 30)),
    _ => now.subtract(const Duration(days: 7)),
  };

  final filtered = alerts.where((a) => a.timestamp.isAfter(cutoff)).toList();

  // Group by short label (category group)
  final Map<String, int> freq = {};
  for (final alert in filtered) {
    try {
      final cat = SoundCategory.values.firstWhere((c) => c.name == alert.soundCategory);
      final group = _groupLabel(cat);
      freq[group] = (freq[group] ?? 0) + 1;
    } catch (_) {
      freq['Other'] = (freq['Other'] ?? 0) + 1;
    }
  }

  if (freq.isEmpty) {
    return {'No Data': 0};
  }
  return freq;
});

String _groupLabel(SoundCategory cat) {
  switch (cat) {
    case SoundCategory.fireAlarm:
    case SoundCategory.smokeAlarm:
      return 'Alarm';
    case SoundCategory.emergencySiren:
      return 'Siren';
    case SoundCategory.glassBreaking:
      return 'Glass';
    case SoundCategory.doorbell:
    case SoundCategory.knocking:
      return 'Door';
    case SoundCategory.babyCrying:
      return 'Baby';
    case SoundCategory.dogBarking:
      return 'Dog';
    case SoundCategory.vehicleHorn:
      return 'Vehicle';
  }
}

/// Top sound: the category with the most alerts.
final topSoundProvider = Provider<Map<String, dynamic>>((ref) {
  final alerts = ref.watch(alertListProvider);
  if (alerts.isEmpty) return {'emoji': '🎧', 'name': 'None yet', 'count': 0};

  final Map<String, int> counts = {};
  for (final alert in alerts) {
    counts[alert.soundCategory] = (counts[alert.soundCategory] ?? 0) + 1;
  }
  final top = counts.entries.reduce((a, b) => a.value >= b.value ? a : b);
  try {
    final cat = SoundCategory.values.firstWhere((c) => c.name == top.key);
    return {'emoji': cat.emoji, 'name': cat.label, 'count': top.value};
  } catch (_) {
    return {'emoji': '🔊', 'name': top.key, 'count': top.value};
  }
});

/// Hourly distribution: Morning / Afternoon / Evening / Night.
final hourlyDistributionProvider = Provider<Map<String, int>>((ref) {
  final alerts = ref.watch(alertListProvider);
  final dist = {'Morning': 0, 'Afternoon': 0, 'Evening': 0, 'Night': 0};
  for (final alert in alerts) {
    final h = alert.timestamp.hour;
    if (h >= 6 && h < 12) dist['Morning'] = dist['Morning']! + 1;
    else if (h >= 12 && h < 17) dist['Afternoon'] = dist['Afternoon']! + 1;
    else if (h >= 17 && h < 21) dist['Evening'] = dist['Evening']! + 1;
    else dist['Night'] = dist['Night']! + 1;
  }
  return dist;
});

/// Daily trend: last 7 days with counts.
final dailyTrendProvider = Provider<List<MapEntry<String, int>>>((ref) {
  final alerts = ref.watch(alertListProvider);
  final now = DateTime.now();
  final days = List.generate(7, (i) => now.subtract(Duration(days: 6 - i)));

  return days.map((day) {
    final count = alerts.where((a) =>
      a.timestamp.year == day.year &&
      a.timestamp.month == day.month &&
      a.timestamp.day == day.day).length;
    final label = ['Mon','Tue','Wed','Thu','Fri','Sat','Sun'][day.weekday - 1];
    return MapEntry(label, count);
  }).toList();
});
