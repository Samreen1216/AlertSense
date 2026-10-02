import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:alertsense/data/datasources/local_storage.dart';
import 'package:alertsense/data/models/alert_event.dart';
import 'package:alertsense/data/repositories/alert_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late SharedPreferences prefs;
  late LocalStorage storage;
  late AlertRepository repository;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    storage = LocalStorage(prefs);
    repository = AlertRepository(storage);
    await repository.init();
  });

  AlertEvent createAlert({
    required String id,
    String soundCategory = 'fireAlarm',
    String priorityLevel = 'high',
    double confidence = 0.9,
    DateTime? timestamp,
    bool acknowledged = false,
  }) {
    return AlertEvent(
      id: id,
      soundCategory: soundCategory,
      priorityLevel: priorityLevel,
      confidence: confidence,
      timestamp: timestamp ?? DateTime(2026, 1, 1, 12, 0, 0),
      acknowledged: acknowledged,
    );
  }

  group('AlertRepository - Initialization & Sorting', () {
    test('init() initializes with empty list when storage is empty', () {
      expect(repository.getAll(), isEmpty);
    });

    test('init() loads existing alerts from storage and sorts in descending order (latest first)', () async {
      final t1 = DateTime(2026, 1, 1, 10, 0);
      final t2 = DateTime(2026, 1, 1, 14, 0);
      final t3 = DateTime(2026, 1, 1, 12, 0);

      final alert1 = createAlert(id: 'a1', timestamp: t1);
      final alert2 = createAlert(id: 'a2', timestamp: t2);
      final alert3 = createAlert(id: 'a3', timestamp: t3);

      await storage.saveAlerts([alert1, alert2, alert3]);

      final newRepo = AlertRepository(storage);
      await newRepo.init();

      final all = newRepo.getAll();
      expect(all.length, 3);
      expect(all[0].id, 'a2'); // latest (14:00)
      expect(all[1].id, 'a3'); // middle (12:00)
      expect(all[2].id, 'a1'); // earliest (10:00)
    });

    test('getAll() returns an unmodifiable list', () {
      final all = repository.getAll();
      expect(() => (all as dynamic).add(createAlert(id: 'x')), throwsUnsupportedError);
    });
  });

  group('AlertRepository - CRUD Operations', () {
    test('addAlert() inserts alert at beginning and persists to storage', () async {
      final a1 = createAlert(id: 'a1', timestamp: DateTime(2026, 1, 1, 10, 0));
      final a2 = createAlert(id: 'a2', timestamp: DateTime(2026, 1, 1, 11, 0));

      await repository.addAlert(a1);
      expect(repository.getAll().length, 1);
      expect(repository.getAll().first.id, 'a1');

      await repository.addAlert(a2);
      expect(repository.getAll().length, 2);
      expect(repository.getAll().first.id, 'a2'); // Inserted at 0

      // Verify persistence in LocalStorage
      final loadedAlerts = storage.loadAlerts();
      expect(loadedAlerts.length, 2);
      expect(loadedAlerts.first.id, 'a2');
    });

    test('deleteAlert() removes matching alert and persists change', () async {
      final a1 = createAlert(id: 'a1');
      final a2 = createAlert(id: 'a2');

      await repository.addAlert(a1);
      await repository.addAlert(a2);
      expect(repository.getAll().length, 2);

      await repository.deleteAlert('a1');
      expect(repository.getAll().length, 1);
      expect(repository.getAll().first.id, 'a2');

      // Verify in storage
      final reloaded = storage.loadAlerts();
      expect(reloaded.length, 1);
      expect(reloaded.first.id, 'a2');
    });

    test('deleteAlert() with nonexistent ID does not mutate alerts', () async {
      final a1 = createAlert(id: 'a1');
      await repository.addAlert(a1);

      await repository.deleteAlert('nonexistent');
      expect(repository.getAll().length, 1);
      expect(repository.getAll().first.id, 'a1');
    });

    test('clearAll() removes all alerts and persists empty list', () async {
      await repository.addAlert(createAlert(id: 'a1'));
      await repository.addAlert(createAlert(id: 'a2'));
      expect(repository.getAll().length, 2);

      await repository.clearAll();
      expect(repository.getAll(), isEmpty);

      final reloaded = storage.loadAlerts();
      expect(reloaded, isEmpty);
    });

    test('acknowledgeAlert() marks alert as acknowledged and persists', () async {
      final a1 = createAlert(id: 'a1', acknowledged: false);
      await repository.addAlert(a1);

      expect(repository.getAll().first.acknowledged, isFalse);

      await repository.acknowledgeAlert('a1');
      expect(repository.getAll().first.acknowledged, isTrue);

      // Verify persistence in storage
      final reloaded = storage.loadAlerts();
      expect(reloaded.first.acknowledged, isTrue);
    });

    test('acknowledgeAlert() with nonexistent ID does nothing', () async {
      final a1 = createAlert(id: 'a1', acknowledged: false);
      await repository.addAlert(a1);

      await repository.acknowledgeAlert('unknown_id');
      expect(repository.getAll().first.acknowledged, isFalse);
    });
  });

  group('AlertRepository - Filtering (getFiltered)', () {
    late AlertEvent alertHighOld;
    late AlertEvent alertHighRecent;
    late AlertEvent alertMediumRecent;
    late AlertEvent alertLowRecent;

    setUp(() async {
      alertHighOld = createAlert(
        id: 'h_old',
        priorityLevel: 'high',
        timestamp: DateTime(2026, 1, 10, 8, 0),
      );
      alertHighRecent = createAlert(
        id: 'h_recent',
        priorityLevel: 'high',
        timestamp: DateTime(2026, 1, 10, 12, 0),
      );
      alertMediumRecent = createAlert(
        id: 'm_recent',
        priorityLevel: 'medium',
        timestamp: DateTime(2026, 1, 10, 14, 0),
      );
      alertLowRecent = createAlert(
        id: 'l_recent',
        priorityLevel: 'low',
        timestamp: DateTime(2026, 1, 10, 16, 0),
      );

      await repository.addAlert(alertHighOld);
      await repository.addAlert(alertHighRecent);
      await repository.addAlert(alertMediumRecent);
      await repository.addAlert(alertLowRecent);
    });

    test('getFiltered() with no criteria returns all alerts', () {
      final result = repository.getFiltered();
      expect(result.length, 4);
    });

    test('getFiltered() filters by priority level', () {
      final highAlerts = repository.getFiltered(priority: 'high');
      expect(highAlerts.length, 2);
      expect(highAlerts.every((a) => a.priorityLevel == 'high'), isTrue);

      final mediumAlerts = repository.getFiltered(priority: 'medium');
      expect(mediumAlerts.length, 1);
      expect(mediumAlerts.first.id, 'm_recent');
    });

    test('getFiltered() filters by from timestamp', () {
      final after11am = repository.getFiltered(from: DateTime(2026, 1, 10, 11, 0));
      expect(after11am.length, 3);
      expect(after11am.any((a) => a.id == 'h_old'), isFalse);
    });

    test('getFiltered() filters by to timestamp', () {
      final before13pm = repository.getFiltered(to: DateTime(2026, 1, 10, 13, 0));
      expect(before13pm.length, 2);
      expect(before13pm.map((a) => a.id), containsAll(['h_old', 'h_recent']));
    });

    test('getFiltered() combines priority, from, and to filters', () {
      final result = repository.getFiltered(
        priority: 'high',
        from: DateTime(2026, 1, 10, 10, 0),
        to: DateTime(2026, 1, 10, 13, 0),
      );
      expect(result.length, 1);
      expect(result.first.id, 'h_recent');
    });

    test('getFiltered() returns empty list when no alerts match', () {
      final result = repository.getFiltered(priority: 'critical_emergency');
      expect(result, isEmpty);
    });
  });

  group('AlertRepository - Analytics & Statistics', () {
    test('countByCategory() counts occurrences and respects since filter', () async {
      final t1 = DateTime(2026, 2, 1, 10, 0);
      final t2 = DateTime(2026, 2, 1, 12, 0);
      final t3 = DateTime(2026, 2, 1, 14, 0);

      await repository.addAlert(createAlert(id: '1', soundCategory: 'doorbell', timestamp: t1));
      await repository.addAlert(createAlert(id: '2', soundCategory: 'doorbell', timestamp: t2));
      await repository.addAlert(createAlert(id: '3', soundCategory: 'fireAlarm', timestamp: t3));

      expect(repository.countByCategory('doorbell'), 2);
      expect(repository.countByCategory('fireAlarm'), 1);
      expect(repository.countByCategory('knocking'), 0);

      // With since filter (t1 is at 10:00, filter is 11:00 -> only t2 at 12:00 matches)
      expect(repository.countByCategory('doorbell', since: DateTime(2026, 2, 1, 11, 0)), 1);
    });

    test('frequencyMap() aggregates counts per category with optional since', () async {
      final t1 = DateTime(2026, 2, 1, 10, 0);
      final t2 = DateTime(2026, 2, 1, 12, 0);

      await repository.addAlert(createAlert(id: '1', soundCategory: 'fireAlarm', timestamp: t1));
      await repository.addAlert(createAlert(id: '2', soundCategory: 'fireAlarm', timestamp: t2));
      await repository.addAlert(createAlert(id: '3', soundCategory: 'babyCrying', timestamp: t2));

      final fullMap = repository.frequencyMap();
      expect(fullMap['fireAlarm'], 2);
      expect(fullMap['babyCrying'], 1);
      expect(fullMap.containsKey('doorbell'), isFalse);

      final filteredMap = repository.frequencyMap(since: DateTime(2026, 2, 1, 11, 0));
      expect(filteredMap['fireAlarm'], 1);
      expect(filteredMap['babyCrying'], 1);
    });

    test('hourlyDistribution() maps alerts to their hour (0-23)', () async {
      await repository.addAlert(createAlert(id: '1', timestamp: DateTime(2026, 2, 1, 9, 15)));
      await repository.addAlert(createAlert(id: '2', timestamp: DateTime(2026, 2, 1, 9, 45)));
      await repository.addAlert(createAlert(id: '3', timestamp: DateTime(2026, 2, 1, 14, 0)));

      final dist = repository.hourlyDistribution();
      expect(dist[9], 2);
      expect(dist[14], 1);
      expect(dist.containsKey(10), isFalse);

      final sinceDist = repository.hourlyDistribution(since: DateTime(2026, 2, 1, 12, 0));
      expect(sinceDist[14], 1);
      expect(sinceDist.containsKey(9), isFalse);
    });

    test('dailyTrend() returns sorted list of past N days with accurate counts', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day, 10, 0);
      final yesterday = today.subtract(const Duration(days: 1));

      await repository.addAlert(createAlert(id: '1', timestamp: today));
      await repository.addAlert(createAlert(id: '2', timestamp: today));
      await repository.addAlert(createAlert(id: '3', timestamp: yesterday));

      final trend = repository.dailyTrend(days: 5);
      expect(trend.length, 5);

      // Verify sorted chronologically ascending
      for (int i = 0; i < trend.length - 1; i++) {
        expect(trend[i].key.isBefore(trend[i + 1].key), isTrue);
      }

      // Last item should be today
      final todayEntry = trend.last;
      expect(todayEntry.key, DateTime(now.year, now.month, now.day));
      expect(todayEntry.value, 2);

      // Second to last should be yesterday
      final yesterdayEntry = trend[trend.length - 2];
      expect(yesterdayEntry.value, 1);

      // Third to last should be twoDaysAgo (0 alerts)
      final twoDaysAgoEntry = trend[trend.length - 3];
      expect(twoDaysAgoEntry.value, 0);
    });

    test('dailyTrend() always sets calendar date midnight (00:00:00.000) for all entries', () {
      final trend = repository.dailyTrend(days: 30);
      expect(trend.length, 30);
      for (final entry in trend) {
        expect(entry.key.hour, equals(0));
        expect(entry.key.minute, equals(0));
        expect(entry.key.second, equals(0));
        expect(entry.key.millisecond, equals(0));
      }
    });

    test('getFiltered() and countByCategory() include exact boundary matches', () async {
      final boundaryTime = DateTime(2026, 3, 15, 12, 0, 0);
      await repository.addAlert(createAlert(id: 'exact_b', soundCategory: 'siren', timestamp: boundaryTime));

      final exactFrom = repository.getFiltered(from: boundaryTime);
      expect(exactFrom.any((a) => a.id == 'exact_b'), isTrue);

      final exactTo = repository.getFiltered(to: boundaryTime);
      expect(exactTo.any((a) => a.id == 'exact_b'), isTrue);

      final exactSinceCount = repository.countByCategory('siren', since: boundaryTime);
      expect(exactSinceCount, equals(1));
    });
  });
}
