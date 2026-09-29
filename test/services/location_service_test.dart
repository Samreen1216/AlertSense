import 'dart:async';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alertsense/services/location_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LocationResult tests', () {
    test('formats Google Maps URL correctly', () {
      final loc = LocationResult(
        latitude: 33.6844,
        longitude: 73.0479,
        accuracy: 12.4,
        timestamp: DateTime(2026, 9, 29, 12, 0),
      );

      expect(loc.toGoogleMapsUrl(), 'https://maps.google.com/?q=33.6844,73.0479');
      expect(loc.formattedAccuracy, '±12m');
      expect(
        loc.toLocationSnippet(),
        'https://maps.google.com/?q=33.6844,73.0479 (±12m)',
      );
    });

    test('serializes to and from Map correctly', () {
      final original = LocationResult(
        latitude: 24.8607,
        longitude: 67.0011,
        accuracy: 8.7,
        timestamp: DateTime(2026, 9, 29, 10, 30),
      );

      final map = original.toMap();
      expect(map['latitude'], 24.8607);
      expect(map['longitude'], 67.0011);
      expect(map['accuracy'], 8.7);

      final deserialized = LocationResult.fromMap(map);
      expect(deserialized.latitude, original.latitude);
      expect(deserialized.longitude, original.longitude);
      expect(deserialized.accuracy, original.accuracy);
      expect(deserialized.timestamp, original.timestamp);
      expect(deserialized, equals(original));
    });

    test('handles numeric types in fromMap gracefully', () {
      final map = {
        'latitude': 31,
        'longitude': 74,
        'accuracy': 15,
        'timestamp': 1727600000000,
      };

      final loc = LocationResult.fromMap(map);
      expect(loc.latitude, 31.0);
      expect(loc.longitude, 74.0);
      expect(loc.accuracy, 15.0);
      expect(loc.timestamp.millisecondsSinceEpoch, 1727600000000);
    });

    test('tryFromMap safely rejects corrupt maps and Null Island coordinates', () {
      expect(LocationResult.tryFromMap(null), isNull);
      expect(LocationResult.tryFromMap('invalid'), isNull);
      expect(LocationResult.tryFromMap({}), isNull);
      expect(LocationResult.tryFromMap({'latitude': 33.68}), isNull);
      expect(LocationResult.tryFromMap({'longitude': 73.04}), isNull);

      // (0.0, 0.0) is rejected by default to prevent Atlantic Ocean buoy bug
      expect(LocationResult.tryFromMap({'latitude': 0.0, 'longitude': 0.0}), isNull);

      // (0.0, 0.0) accepted if explicitly permitted
      final explicitZero = LocationResult.tryFromMap({
        'latitude': 0.0,
        'longitude': 0.0,
        'allowZeroZero': true,
      });
      expect(explicitZero, isNotNull);
      expect(explicitZero!.latitude, 0.0);
      expect(explicitZero.longitude, 0.0);
    });

    test('implements value equality and hashCode correctly', () {
      final loc1 = LocationResult(
        latitude: 33.6844,
        longitude: 73.0479,
        accuracy: 10.0,
        timestamp: DateTime(2026, 9, 29),
      );

      final loc2 = LocationResult(
        latitude: 33.6844,
        longitude: 73.0479,
        accuracy: 10.0,
        timestamp: DateTime(2026, 9, 29),
      );

      final loc3 = LocationResult(
        latitude: 34.0,
        longitude: 73.0479,
        accuracy: 10.0,
        timestamp: DateTime(2026, 9, 29),
      );

      expect(loc1, equals(loc2));
      expect(loc1.hashCode, equals(loc2.hashCode));
      expect(loc1, isNot(equals(loc3)));
    });
  });

  group('LocationService platform and edge case tests', () {
    const deviceChannelName = 'com.alertsense/device/test';
    const geolocatorChannelName = 'flutter.baseflow.com/geolocator/test';
    const geolocatorAndroidChannelName = 'flutter.baseflow.com/geolocator_android/test';

    const testDeviceChannel = MethodChannel(deviceChannelName);
    const testGeolocatorChannel = MethodChannel(geolocatorChannelName);
    const testGeolocatorAndroidChannel = MethodChannel(geolocatorAndroidChannelName);

    late LocationService service;
    late List<MethodCall> deviceCalls;
    late List<MethodCall> geolocatorCalls;
    late List<MethodCall> geolocatorAndroidCalls;

    setUp(() {
      deviceCalls = [];
      geolocatorCalls = [];
      geolocatorAndroidCalls = [];

      service = LocationService(
        deviceChannel: testDeviceChannel,
        geolocatorChannel: testGeolocatorChannel,
        geolocatorAndroidChannel: testGeolocatorAndroidChannel,
        cacheValidDuration: const Duration(seconds: 10),
      );

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(testDeviceChannel, (MethodCall call) async {
        deviceCalls.add(call);
        switch (call.method) {
          case 'isLocationServiceEnabled':
            return true;
          case 'checkPermission':
            return true;
          case 'getCurrentLocation':
            return {
              'latitude': 33.6844,
              'longitude': 73.0479,
              'accuracy': 12.0,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            };
          case 'getLastKnownLocation':
            return {
              'latitude': 33.6800,
              'longitude': 73.0400,
              'accuracy': 25.0,
              'timestamp': DateTime.now().millisecondsSinceEpoch,
            };
          default:
            return null;
        }
      });

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(testGeolocatorChannel, (MethodCall call) async {
        geolocatorCalls.add(call);
        return null;
      });

      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(testGeolocatorAndroidChannel, (MethodCall call) async {
        geolocatorAndroidCalls.add(call);
        return null;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(testDeviceChannel, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(testGeolocatorChannel, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(testGeolocatorAndroidChannel, null);
    });

    test('acquires current location successfully and caches it', () async {
      final loc = await service.getCurrentLocation(timeout: const Duration(seconds: 2));

      expect(loc, isNotNull);
      expect(loc!.latitude, 33.6844);
      expect(loc.longitude, 73.0479);
      expect(loc.accuracy, 12.0);

      // Verify cached location is available immediately
      expect(service.isCacheValid, isTrue);
      expect(service.cachedLocation, equals(loc));

      // Subsequent getLastKnownLocation returns cached location
      final cached = await service.getLastKnownLocation();
      expect(cached, equals(loc));
    });

    test('instant cache fast-path returns cached location without invoking platform channels', () async {
      final initialLoc = LocationResult(
        latitude: 33.6844,
        longitude: 73.0479,
        accuracy: 10.0,
        timestamp: DateTime.now(),
      );
      service.updateCache(initialLoc);

      deviceCalls.clear();

      // Calling getCurrentLocation with default useCache: true should return immediately
      final loc = await service.getCurrentLocation();
      expect(loc, equals(initialLoc));
      // No channel calls should have been made
      expect(deviceCalls.where((c) => c.method == 'getCurrentLocation'), isEmpty);
    });

    test('useCache false bypasses cache to acquire fresh fix', () async {
      final oldLoc = LocationResult(
        latitude: 33.0,
        longitude: 73.0,
        accuracy: 50.0,
        timestamp: DateTime.now().subtract(const Duration(seconds: 5)),
      );
      service.updateCache(oldLoc);

      final freshLoc = await service.getCurrentLocation(useCache: false);
      expect(freshLoc, isNotNull);
      expect(freshLoc!.latitude, 33.6844);
      expect(freshLoc.accuracy, 12.0);
    });

    test('cache clearing works properly', () async {
      service.updateCache(LocationResult(
        latitude: 33.0,
        longitude: 73.0,
        accuracy: 10.0,
        timestamp: DateTime.now(),
      ));

      expect(service.isCacheValid, isTrue);
      service.clearCache();
      expect(service.isCacheValid, isFalse);
      expect(service.cachedLocation, isNull);
    });

    test('deduplicates simultaneous concurrent getCurrentLocation calls into a single channel invocation', () async {
      service.clearCache();
      deviceCalls.clear();

      // Launch 3 concurrent location fetches simultaneously
      final future1 = service.getCurrentLocation(useCache: false);
      final future2 = service.getCurrentLocation(useCache: false);
      final future3 = service.getCurrentLocation(useCache: false);

      final results = await Future.wait([future1, future2, future3]);

      // All 3 callers must receive the exact same resolved location
      expect(results[0], isNotNull);
      expect(results[1], equals(results[0]));
      expect(results[2], equals(results[0]));

      // Only ONE channel invocation should have occurred
      final getLocCalls = deviceCalls.where((c) => c.method == 'getCurrentLocation').toList();
      expect(getLocCalls.length, equals(1));
    });

    test('falls back to geolocator Android channel if device channel returns null', () async {
      // Mock device channel to return null
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(testDeviceChannel, (MethodCall call) async {
        if (call.method == 'isLocationServiceEnabled') return true;
        if (call.method == 'checkPermission') return true;
        return null;
      });

      // Mock geolocator_android channel to return valid location
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(testGeolocatorAndroidChannel, (MethodCall call) async {
        if (call.method == 'getCurrentPosition') {
          return {
            'latitude': 31.5204,
            'longitude': 74.3587,
            'accuracy': 6.5,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          };
        }
        return null;
      });

      final loc = await service.getCurrentLocation(timeout: const Duration(seconds: 2));
      expect(loc, isNotNull);
      expect(loc!.latitude, 31.5204);
      expect(loc.longitude, 74.3587);
    });

    test('handles location services disabled gracefully without throwing', () async {
      final disabledService = LocationService(
        deviceChannel: testDeviceChannel,
        serviceStatusChecker: () async => false,
      );

      final loc = await disabledService.getCurrentLocation(timeout: const Duration(seconds: 1));
      expect(loc, isNull);
    });

    test('handles permission denied gracefully without throwing', () async {
      final deniedService = LocationService(
        deviceChannel: testDeviceChannel,
        serviceStatusChecker: () async => true,
        permissionStatusChecker: () async => false,
      );

      final loc = await deniedService.getCurrentLocation(timeout: const Duration(seconds: 1));
      expect(loc, isNull);
    });

    test('handles fast timeout gracefully by falling back to last known location', () async {
      // Mock device channel to hang on getCurrentLocation (simulating GPS search delay)
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(testDeviceChannel, (MethodCall call) async {
        if (call.method == 'isLocationServiceEnabled') {
          return true;
        }
        if (call.method == 'checkPermission') {
          return true;
        }
        if (call.method == 'getCurrentLocation') {
          // Delay longer than timeout
          await Future.delayed(const Duration(milliseconds: 600));
          return {'latitude': 33.6844, 'longitude': 73.0479, 'accuracy': 5.0};
        }
        if (call.method == 'getLastKnownLocation') {
          return {
            'latitude': 33.6800,
            'longitude': 73.0400,
            'accuracy': 20.0,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          };
        }
        return null;
      });

      // Strict timeout of 200ms
      final loc = await service.getCurrentLocation(
        timeout: const Duration(milliseconds: 200),
      );

      // Should have fallen back to last known location
      expect(loc, isNotNull);
      expect(loc!.latitude, 33.6800);
      expect(loc.longitude, 73.0400);
      expect(loc.accuracy, 20.0);
    });

    test('handles total failure and timeout with no last-known location without throwing', () async {
      // Both getCurrentLocation and getLastKnownLocation fail
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(testDeviceChannel, (MethodCall call) async {
        if (call.method == 'isLocationServiceEnabled') return true;
        if (call.method == 'checkPermission') return true;
        if (call.method == 'getCurrentLocation') {
          await Future.delayed(const Duration(milliseconds: 500));
          return null;
        }
        if (call.method == 'getLastKnownLocation') return null;
        return null;
      });

      final loc = await service.getCurrentLocation(
        timeout: const Duration(milliseconds: 150),
      );

      // Must complete without throwing and return null
      expect(loc, isNull);
    });

    test('static formatting helpers generate correct strings', () {
      expect(
        LocationService.formatGoogleMapsPin(33.6844, 73.0479),
        'https://maps.google.com/?q=33.6844,73.0479',
      );
      expect(LocationService.formatAccuracy(12.3), '±12m');
      expect(
        LocationService.formatSnippet(33.6844, 73.0479, 12.3),
        'https://maps.google.com/?q=33.6844,73.0479 (±12m)',
      );
    });

    test('checkAndRequestPermission succeeds when permission is granted by checker', () async {
      final permService = LocationService(
        deviceChannel: testDeviceChannel,
        serviceStatusChecker: () async => true,
        permissionStatusChecker: () async => true,
      );

      final hasPerm = await permService.checkAndRequestPermission();
      expect(hasPerm, isTrue);
    });
  });
}
