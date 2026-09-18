import '../datasources/local_storage.dart';
import '../models/alert_event.dart';

class AlertRepository {
  final LocalStorage _storage;
  List<AlertEvent> _alerts = [];

  AlertRepository(this._storage);

  Future<void> init() async {
    _alerts = _storage.loadAlerts();
    _alerts.sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> addAlert(AlertEvent alert) async {
    _alerts.insert(0, alert);
    await _storage.saveAlerts(_alerts);
  }

  List<AlertEvent> getAll() {
    return List.unmodifiable(_alerts);
  }

  List<AlertEvent> getFiltered({String? priority, DateTime? from, DateTime? to}) {
    return _alerts.where((alert) {
      bool matches = true;
      if (priority != null) {
        matches = matches && alert.priorityLevel == priority;
      }
      if (from != null) {
        matches = matches && alert.timestamp.isAfter(from);
      }
      if (to != null) {
        matches = matches && alert.timestamp.isBefore(to);
      }
      return matches;
    }).toList();
  }

  Future<void> deleteAlert(String id) async {
    _alerts.removeWhere((alert) => alert.id == id);
    await _storage.saveAlerts(_alerts);
  }

  Future<void> clearAll() async {
    _alerts.clear();
    await _storage.saveAlerts(_alerts);
  }

  Future<void> acknowledgeAlert(String id) async {
    final index = _alerts.indexWhere((alert) => alert.id == id);
    if (index != -1) {
      _alerts[index] = _alerts[index].copyWith(acknowledged: true);
      await _storage.saveAlerts(_alerts);
    }
  }

  int countByCategory(String category, {DateTime? since}) {
    return _alerts.where((a) {
      return a.soundCategory == category && (since == null || a.timestamp.isAfter(since));
    }).length;
  }

  Map<String, int> frequencyMap({DateTime? since}) {
    final map = <String, int>{};
    for (final alert in _alerts) {
      if (since != null && alert.timestamp.isBefore(since)) continue;
      map[alert.soundCategory] = (map[alert.soundCategory] ?? 0) + 1;
    }
    return map;
  }

  Map<int, int> hourlyDistribution({DateTime? since}) {
    final map = <int, int>{};
    for (final alert in _alerts) {
      if (since != null && alert.timestamp.isBefore(since)) continue;
      final hour = alert.timestamp.hour;
      map[hour] = (map[hour] ?? 0) + 1;
    }
    return map;
  }

  List<MapEntry<DateTime, int>> dailyTrend({int days = 7}) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final map = <DateTime, int>{};

    for (int i = 0; i < days; i++) {
      map[today.subtract(Duration(days: i))] = 0;
    }

    for (final alert in _alerts) {
      final day = DateTime(alert.timestamp.year, alert.timestamp.month, alert.timestamp.day);
      if (map.containsKey(day)) {
        map[day] = map[day]! + 1;
      }
    }

    final sortedEntries = map.entries.toList()..sort((a, b) => a.key.compareTo(b.key));
    return sortedEntries;
  }
}
