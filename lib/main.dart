import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'app.dart';
import 'core/theme/theme_provider.dart';
import 'data/datasources/local_storage.dart';
import 'data/repositories/alert_repository.dart';
import 'data/repositories/settings_repository.dart';
import 'providers/service_providers.dart';
import 'services/home_widget_service.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  final prefs = await SharedPreferences.getInstance();
  final localStorage = LocalStorage(prefs);

  final alertRepository = AlertRepository(localStorage);
  await alertRepository.init();
  final settingsRepository = SettingsRepository(localStorage);
  await settingsRepository.init();

  final notificationService = NotificationService();
  await notificationService.init();

  final homeWidgetService = HomeWidgetService();
  await homeWidgetService.init();

  // Populate initial home widget state from repositories
  final initialAlerts = alertRepository.getAll();
  final now = DateTime.now();
  final todayAlerts = initialAlerts.where((a) =>
    a.timestamp.year == now.year &&
    a.timestamp.month == now.month &&
    a.timestamp.day == now.day).length;
  final highPriority = initialAlerts.where((a) => a.priorityLevel.toLowerCase() == 'high').length;

  await homeWidgetService.syncData(
    isListening: false,
    activeProfile: 'home',
    ambientDb: 38.0,
    lastAlert: initialAlerts.isNotEmpty ? initialAlerts.first : null,
    alertsTodayCount: todayAlerts,
    highPriorityCount: highPriority,
    monitoredCount: 9,
  );

  // Request POST_NOTIFICATIONS permission (Android 13+)
  await Permission.notification.request();

  runApp(
    ProviderScope(
      overrides: [
        // theme_provider.dart defines sharedPreferencesProvider as Provider<SharedPreferences?>
        sharedPreferencesProvider.overrideWithValue(prefs),
        localStorageProvider.overrideWithValue(localStorage),
        alertRepositoryProvider.overrideWithValue(alertRepository),
        settingsRepositoryProvider.overrideWithValue(settingsRepository),
        notificationServiceProvider.overrideWithValue(notificationService),
        homeWidgetServiceProvider.overrideWithValue(homeWidgetService),
      ],
      child: const AlertSenseApp(),
    ),
  );
}

// These providers are used by repositories and services
final localStorageProvider = Provider<LocalStorage>((ref) {
  throw UnimplementedError('Must be overridden in ProviderScope');
});

final alertRepositoryProvider = Provider<AlertRepository>((ref) {
  throw UnimplementedError('Must be overridden in ProviderScope');
});

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  throw UnimplementedError('Must be overridden in ProviderScope');
});
