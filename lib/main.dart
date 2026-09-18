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
