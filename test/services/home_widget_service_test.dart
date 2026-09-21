import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:alertsense/services/home_widget_service.dart';
import 'package:alertsense/data/models/alert_event.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late HomeWidgetService service;
  final List<MethodCall> channelCalls = [];

  setUp(() {
    service = HomeWidgetService();
    channelCalls.clear();

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('home_widget'), (MethodCall call) async {
      channelCalls.add(call);
      if (call.method == 'saveWidgetData' || call.method == 'updateWidget') {
        return true;
      }
      if (call.method == 'initiallyLaunchedFromHomeWidget') {
        return null;
      }
      if (call.method == 'isRequestPinWidgetSupported') {
        return true;
      }
      if (call.method == 'requestPinWidget') {
        return null;
      }
      return null;
    });
  });

  tearDown(() {
    service.dispose();
  });

  test('HomeWidgetService initializes and syncs data to native channel', () async {
    await service.init();

    final testAlert = AlertEvent(
      id: 'test-1',
      soundCategory: 'fireAlarm',
      priorityLevel: 'High',
      confidence: 0.95,
      timestamp: DateTime.now().subtract(const Duration(minutes: 2)),
    );

    await service.syncData(
      isListening: true,
      activeProfile: 'home',
      ambientDb: 42.0,
      lastAlert: testAlert,
      alertsTodayCount: 3,
      highPriorityCount: 1,
      monitoredCount: 9,
    );

    // Verify channel received saveWidgetData and updateWidget calls
    expect(channelCalls.any((call) => call.method == 'saveWidgetData' && call.arguments['id'] == 'is_listening'), isTrue);
    expect(channelCalls.any((call) => call.method == 'saveWidgetData' && call.arguments['id'] == 'active_profile'), isTrue);
    expect(channelCalls.any((call) => call.method == 'saveWidgetData' && call.arguments['id'] == 'ambient_db'), isTrue);
    expect(channelCalls.any((call) => call.method == 'saveWidgetData' && call.arguments['id'] == 'last_alert_title'), isTrue);
    expect(channelCalls.any((call) => call.method == 'updateWidget'), isTrue);
  });

  test('HomeWidgetService handles null lastAlert gracefully (All Clear)', () async {
    await service.syncData(
      isListening: false,
      activeProfile: 'sleep',
      ambientDb: 32.0,
      lastAlert: null,
      alertsTodayCount: 0,
      highPriorityCount: 0,
    );

    final titleCall = channelCalls.firstWhere(
      (c) => c.method == 'saveWidgetData' && c.arguments['id'] == 'last_alert_title',
    );
    expect(titleCall.arguments['data'], equals('All Clear'));
  });

  test('HomeWidgetService pinWidgetToHomeScreen calls requestPinWidget', () async {
    final success = await service.pinWidgetToHomeScreen();
    expect(success, isTrue);
    expect(channelCalls.any((call) => call.method == 'requestPinWidget'), isTrue);
  });
}
