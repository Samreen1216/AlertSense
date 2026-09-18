import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/models/alert_event.dart';
import '../main.dart';

class AlertListNotifier extends StateNotifier<List<AlertEvent>> {
  final Ref _ref;

  AlertListNotifier(this._ref) : super([]) {
    _load();
  }

  void _load() {
    final repo = _ref.read(alertRepositoryProvider);
    state = repo.getAll();
  }

  Future<void> addAlert(AlertEvent event) async {
    state = [event, ...state];
    final repo = _ref.read(alertRepositoryProvider);
    await repo.addAlert(event);
  }

  Future<void> removeAlert(String id) async {
    state = state.where((e) => e.id != id).toList();
    final repo = _ref.read(alertRepositoryProvider);
    await repo.deleteAlert(id);
  }

  Future<void> acknowledgeAlert(String id, {String? action}) async {
    state = state.map((e) {
      if (e.id == id) {
        return e.copyWith(
          acknowledged: true,
          responseAction: action ?? e.responseAction,
        );
      }
      return e;
    }).toList();
    final repo = _ref.read(alertRepositoryProvider);
    await repo.acknowledgeAlert(id);
  }

  void syncFromRepo() {
    final repo = _ref.read(alertRepositoryProvider);
    state = repo.getAll();
  }

  Future<void> clear() async {
    state = [];
    final repo = _ref.read(alertRepositoryProvider);
    await repo.clearAll();
  }
}

final alertListProvider = StateNotifierProvider<AlertListNotifier, List<AlertEvent>>((ref) {
  return AlertListNotifier(ref);
});

final alertFilterPriorityProvider = StateProvider<String?>((ref) => null);

final filteredAlertsProvider = Provider<List<AlertEvent>>((ref) {
  final alerts = ref.watch(alertListProvider);
  final filter = ref.watch(alertFilterPriorityProvider);
  if (filter == null || filter.isEmpty || filter.toLowerCase() == 'all') {
    return alerts;
  }
  return alerts.where((e) => e.priorityLevel.toLowerCase() == filter.toLowerCase()).toList();
});

final lastAlertProvider = Provider<AlertEvent?>((ref) {
  final alerts = ref.watch(alertListProvider);
  return alerts.isNotEmpty ? alerts.first : null;
});

final activeProfileProvider = StateProvider<String>((ref) => 'home');

