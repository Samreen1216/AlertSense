import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:geolocator/geolocator.dart';
import 'package:permission_handler/permission_handler.dart';

/// Represents geographical coordinates and accuracy obtained during emergency detection.
class LocationResult {
  final double latitude;
  final double longitude;
  final double accuracy;
  final DateTime timestamp;

  const LocationResult({
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.timestamp,
  });

  /// Formats the coordinates into a standard Google Maps pin link.
  /// Example: https://maps.google.com/?q=33.6844,73.0479
  String toGoogleMapsUrl() => 'https://maps.google.com/?q=$latitude,$longitude';

  /// Formatted accuracy string, e.g., "±12m".
  String get formattedAccuracy => '±${accuracy.round()}m';

  /// Combined location URL and accuracy snippet for inclusion in alerts.
  String toLocationSnippet() => '${toGoogleMapsUrl()} ($formattedAccuracy)';

  /// Safely creates a [LocationResult] from a raw map, returning null if coordinates
  /// are missing, corrupt, or resolve to (0.0, 0.0) Null Island without explicit flag.
  static LocationResult? tryFromMap(dynamic map) {
    if (map is! Map) return null;
    final latNum = map['latitude'] as num?;
    final lngNum = map['longitude'] as num?;
    if (latNum == null || lngNum == null) return null;

    final lat = latNum.toDouble();
    final lng = lngNum.toDouble();

    // Guard against 0.0, 0.0 "Null Island" artifacts unless explicitly permitted
    if (lat == 0.0 && lng == 0.0 && !map.containsKey('allowZeroZero')) {
      return null;
    }

    final acc = (map['accuracy'] as num?)?.toDouble() ?? 0.0;
    final tsVal = map['timestamp'];

    DateTime ts = DateTime.now();
    if (tsVal is int) {
      ts = DateTime.fromMillisecondsSinceEpoch(tsVal);
    } else if (tsVal is String) {
      ts = DateTime.tryParse(tsVal) ?? DateTime.now();
    } else if (tsVal is DateTime) {
      ts = tsVal;
    }

    return LocationResult(
      latitude: lat,
      longitude: lng,
      accuracy: acc,
      timestamp: ts,
    );
  }

  /// Creates a [LocationResult] from a native platform channel map with safe fallbacks.
  factory LocationResult.fromMap(Map<dynamic, dynamic> map) {
    final parsed = tryFromMap(map);
    if (parsed != null) return parsed;

    return LocationResult(
      latitude: (map['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (map['longitude'] as num?)?.toDouble() ?? 0.0,
      accuracy: (map['accuracy'] as num?)?.toDouble() ?? 0.0,
      timestamp: DateTime.now(),
    );
  }

  /// Serializes to a key-value map.
  Map<String, dynamic> toMap() => {
        'latitude': latitude,
        'longitude': longitude,
        'accuracy': accuracy,
        'timestamp': timestamp.toIso8601String(),
      };

  @override
  String toString() =>
      'LocationResult(lat: $latitude, lng: $longitude, acc: $accuracy, timestamp: $timestamp)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is LocationResult &&
          runtimeType == other.runtimeType &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          accuracy == other.accuracy;

  @override
  int get hashCode => Object.hash(latitude, longitude, accuracy);
}

/// Service managing GPS geolocation acquisition for emergency SOS and family alerts.
///
/// Designed with strict fast timeouts and multi-layered fallbacks so emergency
/// dispatches are never blocked or delayed even if GPS signal is weak, searching,
/// or permissions are disabled.
class LocationService {
  final MethodChannel _deviceChannel;
  final MethodChannel _geolocatorChannel;
  final MethodChannel _geolocatorAndroidChannel;
  final Duration cacheValidDuration;
  final Future<bool> Function()? permissionStatusChecker;
  final Future<bool> Function()? serviceStatusChecker;

  LocationResult? _cachedLocation;
  DateTime? _cacheTimestamp;
  Future<LocationResult?>? _inflightFetch;

  LocationService({
    MethodChannel? deviceChannel,
    MethodChannel? geolocatorChannel,
    MethodChannel? geolocatorAndroidChannel,
    this.cacheValidDuration = const Duration(seconds: 60),
    this.permissionStatusChecker,
    this.serviceStatusChecker,
  })  : _deviceChannel = deviceChannel ?? const MethodChannel('com.alertsense/device'),
        _geolocatorChannel =
            geolocatorChannel ?? const MethodChannel('flutter.baseflow.com/geolocator'),
        _geolocatorAndroidChannel = geolocatorAndroidChannel ??
            const MethodChannel('flutter.baseflow.com/geolocator_android');

  /// Indicates whether a recently cached location is available and fresh.
  bool get isCacheValid {
    if (_cachedLocation == null || _cacheTimestamp == null) return false;
    return DateTime.now().difference(_cacheTimestamp!) < cacheValidDuration;
  }

  /// Returns the cached location if still valid, or null.
  LocationResult? get cachedLocation => isCacheValid ? _cachedLocation : null;

  /// Updates the in-memory location cache.
  void updateCache(LocationResult location) {
    _cachedLocation = location;
    _cacheTimestamp = DateTime.now();
  }

  /// Clears the in-memory location cache.
  void clearCache() {
    _cachedLocation = null;
    _cacheTimestamp = null;
  }

  /// Verifies whether device location services (GPS/Network) are active.
  Future<bool> isLocationServiceEnabled() async {
    if (serviceStatusChecker != null) {
      try {
        return await serviceStatusChecker!();
      } catch (_) {}
    }

    // 1. Try AlertSense native device channel
    try {
      final enabled = await _deviceChannel.invokeMethod<bool>('isLocationServiceEnabled');
      if (enabled != null) return enabled;
    } catch (_) {}

    // 2. Try permission_handler
    try {
      final status = await Permission.location.serviceStatus;
      if (status.isEnabled) return true;
      if (status.isDisabled) return false;
    } catch (_) {}

    // 3. Try geolocator channels
    for (final channel in [_geolocatorAndroidChannel, _geolocatorChannel]) {
      try {
        final enabled = await channel.invokeMethod<bool>('isLocationServiceEnabled');
        if (enabled != null) return enabled;
      } catch (_) {}
    }

    // 4. Try Geolocator directly
    try {
      return await Geolocator.isLocationServiceEnabled();
    } catch (_) {}

    // Default to true to allow fetch attempt if status check is inconclusive
    return true;
  }

  /// Checks if location permission has already been granted.
  Future<bool> checkPermission() async {
    if (permissionStatusChecker != null) {
      try {
        return await permissionStatusChecker!();
      } catch (_) {}
    }

    // 1. Try AlertSense native device channel
    try {
      final granted = await _deviceChannel.invokeMethod<bool>('checkPermission');
      if (granted != null) return granted;
    } catch (_) {}

    // 2. Try permission_handler
    try {
      final status = await Permission.location.status;
      if (status.isGranted || status.isLimited) return true;
      if (status.isPermanentlyDenied || status.isRestricted) return false;
    } catch (_) {}

    // 3. Try geolocator channels (where 2=whileInUse, 3=always)
    for (final channel in [_geolocatorAndroidChannel, _geolocatorChannel]) {
      try {
        final perm = await channel.invokeMethod<int>('checkPermission');
        if (perm != null && perm > 1) return true;
      } catch (_) {}
    }

    try {
      final perm = await Geolocator.checkPermission();
      return perm == LocationPermission.always || perm == LocationPermission.whileInUse;
    } catch (_) {}

    return true;
  }

  /// Explicitly requests location permission from the user.
  Future<PermissionStatus> requestPermission() async {
    try {
      final status = await Permission.location.request();
      if (status.isGranted || status.isLimited) {
        return status;
      }
      if (status.isPermanentlyDenied || status.isRestricted) {
        return status;
      }
    } catch (_) {}

    try {
      final geoPerm = await Geolocator.requestPermission();
      if (geoPerm == LocationPermission.always || geoPerm == LocationPermission.whileInUse) {
        return PermissionStatus.granted;
      } else if (geoPerm == LocationPermission.deniedForever) {
        return PermissionStatus.permanentlyDenied;
      }
    } catch (_) {}

    try {
      final granted = await _deviceChannel.invokeMethod<bool>('checkPermission');
      if (granted == true) return PermissionStatus.granted;
    } catch (_) {}
    return PermissionStatus.denied;
  }

  /// Checks and automatically requests permission if not granted.
  /// Returns `true` if granted, `false` otherwise.
  Future<bool> checkAndRequestPermission() async {
    if (permissionStatusChecker != null) {
      try {
        return await permissionStatusChecker!();
      } catch (_) {}
    }

    // 1. Check if permission is already granted via AlertSense device channel
    try {
      final granted = await _deviceChannel.invokeMethod<bool>('checkPermission');
      if (granted == true) return true;
    } catch (_) {}

    // 2. Check if already granted via permission_handler
    try {
      final status = await Permission.location.status;
      if (status.isGranted || status.isLimited) {
        return true;
      }
      if (status.isPermanentlyDenied || status.isRestricted) {
        debugPrint('[LocationService] Location permission permanently denied or restricted.');
        return false;
      }
    } catch (_) {}

    // 3. Check if already granted via geolocator channels
    for (final channel in [_geolocatorAndroidChannel, _geolocatorChannel]) {
      try {
        final perm = await channel.invokeMethod<int>('checkPermission');
        if (perm != null && perm > 1) return true;
      } catch (_) {}
    }

    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.always || perm == LocationPermission.whileInUse) {
        return true;
      }
      if (perm == LocationPermission.deniedForever) {
        debugPrint('[LocationService] Geolocator reports permission permanently denied.');
        return false;
      }
    } catch (_) {}

    // 4. Permission is NOT granted yet! Explicitly request permission at runtime
    try {
      final requested = await Permission.location.request();
      if (requested.isGranted || requested.isLimited) {
        return true;
      }
    } catch (_) {}

    try {
      final geoPerm = await Geolocator.requestPermission();
      if (geoPerm == LocationPermission.always || geoPerm == LocationPermission.whileInUse) {
        return true;
      }
    } catch (_) {}

    // 5. Final check via device channel in case system dialog resolved it
    try {
      final granted = await _deviceChannel.invokeMethod<bool>('checkPermission');
      if (granted == true) return true;
    } catch (_) {}

    return false;
  }

  /// Instantly retrieves the last known location without waiting for fresh GPS fix.
  Future<LocationResult?> getLastKnownLocation() async {
    if (isCacheValid && _cachedLocation != null) return _cachedLocation;

    try {
      final raw = await _deviceChannel.invokeMethod<dynamic>('getLastKnownLocation');
      final parsed = LocationResult.tryFromMap(raw);
      if (parsed != null) {
        updateCache(parsed);
        return parsed;
      }
    } catch (_) {}

    for (final channel in [_geolocatorAndroidChannel, _geolocatorChannel]) {
      try {
        final raw = await channel.invokeMethod<dynamic>('getLastKnownPosition');
        final parsed = LocationResult.tryFromMap(raw);
        if (parsed != null) {
          updateCache(parsed);
          return parsed;
        }
      } catch (_) {}
    }

    // Direct geolocator plugin fallback
    try {
      final pos = await Geolocator.getLastKnownPosition();
      if (pos != null) {
        final res = LocationResult(
          latitude: pos.latitude,
          longitude: pos.longitude,
          accuracy: pos.accuracy,
          timestamp: pos.timestamp,
        );
        updateCache(res);
        return res;
      }
    } catch (_) {}

    return null;
  }

  /// Acquires current location asynchronously with a strict timeout.
  ///
  /// Features an instant cache fast-path: if a valid location was pre-warmed within
  /// [cacheValidDuration], it returns immediately without delaying emergency dispatch.
  /// Enforces a default 3-second timeout so emergency dispatch is never delayed.
  /// Handles all edge cases gracefully:
  /// - Location services disabled
  /// - Permission denied or permanently denied
  /// - Weak GPS / timeout (falls back to last known location or null)
  /// - Platform channel failure
  ///
  /// Never throws an exception; always fails gracefully.
  Future<LocationResult?> getCurrentLocation({
    Duration timeout = const Duration(seconds: 4),
    bool useCache = true,
  }) async {
    // 0. Instant Cache Fast-Path: if cache is valid and fresh, return immediately!
    if (useCache && isCacheValid && _cachedLocation != null) {
      return _cachedLocation;
    }

    // 0b. Inflight request deduplication: reuse active fetch if one is already running
    if (_inflightFetch != null) {
      return await _inflightFetch!;
    }

    final future = _executeLocationFetch(timeout);
    _inflightFetch = future;
    try {
      return await future;
    } finally {
      if (identical(_inflightFetch, future)) {
        _inflightFetch = null;
      }
    }
  }

  Future<LocationResult?> _executeLocationFetch(Duration timeout) async {
    try {
      // 1. Verify location hardware/service is enabled
      final isEnabled = await isLocationServiceEnabled();
      if (!isEnabled) {
        debugPrint('[LocationService] Location services disabled on device.');
        return null;
      }

      // 2. Verify or request permission
      final hasPermission = await checkAndRequestPermission();
      if (!hasPermission) {
        debugPrint('[LocationService] Location permission not granted.');
        return null;
      }

      // 3. Acquire location with strict timeout
      return await _fetchLocationWithTimeout(timeout);
    } catch (e) {
      debugPrint('[LocationService] Unexpected error in getCurrentLocation: $e');
      return getLastKnownLocation();
    }
  }

  Future<LocationResult?> _fetchLocationWithTimeout(Duration timeout) async {
    try {
      final result = await _fetchFromChannels().timeout(
        timeout,
        onTimeout: () {
          debugPrint(
              '[LocationService] Location fetch reached fast timeout (${timeout.inSeconds}s). Falling back.');
          return getLastKnownLocation();
        },
      );
      if (result != null) {
        updateCache(result);
      }
      return result;
    } catch (e) {
      debugPrint('[LocationService] Platform location fetch failed: $e. Falling back.');
      return getLastKnownLocation();
    }
  }

  Future<LocationResult?> _fetchFromChannels() async {
    // 1. Try AlertSense native device channel with fast 2.5s budget
    try {
      final raw = await _deviceChannel
          .invokeMethod<dynamic>('getCurrentLocation')
          .timeout(const Duration(milliseconds: 2500));
      final parsed = LocationResult.tryFromMap(raw);
      if (parsed != null) return parsed;
    } catch (_) {}

    // 2. Try geolocator Android channel
    try {
      final raw = await _geolocatorAndroidChannel
          .invokeMethod<dynamic>('getCurrentPosition')
          .timeout(const Duration(milliseconds: 2000));
      final parsed = LocationResult.tryFromMap(raw);
      if (parsed != null) return parsed;
    } catch (_) {}

    // 3. Try standard geolocator channel
    try {
      final raw = await _geolocatorChannel
          .invokeMethod<dynamic>('getCurrentPosition')
          .timeout(const Duration(milliseconds: 2000));
      final parsed = LocationResult.tryFromMap(raw);
      if (parsed != null) return parsed;
    } catch (_) {}

    // 4. Try geolocator plugin directly as hardware fallback
    try {
      final pos = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 3),
        ),
      );
      return LocationResult(
        latitude: pos.latitude,
        longitude: pos.longitude,
        accuracy: pos.accuracy,
        timestamp: pos.timestamp,
      );
    } catch (_) {}

    // 5. Fallback to last known location
    return getLastKnownLocation();
  }

  /// Formats a Google Maps pin link given latitude and longitude.
  static String formatGoogleMapsPin(double lat, double lng) =>
      'https://maps.google.com/?q=$lat,$lng';

  /// Formats the accuracy string.
  static String formatAccuracy(double accuracy) => '±${accuracy.round()}m';

  /// Formats a full snippet containing the Google Maps pin and accuracy.
  static String formatSnippet(double lat, double lng, double accuracy) =>
      '${formatGoogleMapsPin(lat, lng)} (${formatAccuracy(accuracy)})';
}
