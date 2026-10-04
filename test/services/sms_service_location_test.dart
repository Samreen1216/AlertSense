import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:alertsense/services/location_service.dart';
import 'package:alertsense/services/sms_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SmsService emergency message formatting tests', () {
    test('emergencyMessage formats standard message when locationUrl is null', () {
      final msg = SmsService.emergencyMessage('Smoke Alarm');

      expect(msg, contains('EMERGENCY ALERT via AlertSense: A Smoke Alarm has been detected at my location.'));
      expect(msg, contains('Please check on me or call for assistance!'));
      expect(msg.contains('📍 Pin:'), isFalse);
    });

    test('emergencyMessage formats message with Google Maps pin and accuracy', () {
      const pinUrl = 'https://maps.google.com/?q=33.6844,73.0479';
      final msg = SmsService.emergencyMessage(
        'Fire Alarm',
        locationUrl: pinUrl,
        accuracy: 12.0,
      );

      expect(msg, contains('EMERGENCY ALERT via AlertSense: A Fire Alarm has been detected at my location!'));
      expect(msg, contains('📍 Pin: https://maps.google.com/?q=33.6844,73.0479 (±12m)'));
      expect(msg, contains('Please check on me or call for assistance!'));
    });

    test('emergencyMessage formats message when LocationResult object is passed directly', () {
      final loc = LocationResult(
        latitude: 33.6844,
        longitude: 73.0479,
        accuracy: 14.2,
        timestamp: DateTime(2026, 9, 29),
      );

      final msg = SmsService.emergencyMessage(
        'Smoke Detector',
        location: loc,
      );

      expect(msg, contains('EMERGENCY ALERT via AlertSense: A Smoke Detector has been detected at my location!'));
      expect(msg, contains('📍 Pin: https://maps.google.com/?q=33.6844,73.0479 (±14m)'));
    });

    test('emergencyMessage formats message with Google Maps pin without accuracy', () {
      const pinUrl = 'https://maps.google.com/?q=33.6844,73.0479';
      final msg = SmsService.emergencyMessage(
        'Siren',
        locationUrl: pinUrl,
      );

      expect(msg, contains('📍 Pin: https://maps.google.com/?q=33.6844,73.0479'));
      expect(msg.contains('(±'), isFalse);
    });

    test('emergencyMessage falls back to standard message if locationUrl is empty string or whitespace', () {
      final msgEmpty = SmsService.emergencyMessage('Fire Alarm', locationUrl: '');
      final msgWhitespace = SmsService.emergencyMessage('Fire Alarm', locationUrl: '   ');

      expect(msgEmpty, contains('A Fire Alarm has been detected at my location. Please check on me'));
      expect(msgEmpty.contains('📍 Pin:'), isFalse);

      expect(msgWhitespace, contains('A Fire Alarm has been detected at my location. Please check on me'));
      expect(msgWhitespace.contains('📍 Pin:'), isFalse);
    });
  });

  group('SmsService auto-dispatch emergency message tests', () {
    test('autoDispatchEmergencyMessage formats standard message without location', () {
      final msg = SmsService.autoDispatchEmergencyMessage('Fire Alarm');

      expect(msg, contains('CRITICAL ALERT: Fire Alarm detected at user location.'));
      expect(msg, contains('User is currently unacknowledged. Sent automatically by AlertSense.'));
      expect(msg.contains('📍 Pin:'), isFalse);
    });

    test('autoDispatchEmergencyMessage formats critical message with location pin and accuracy', () {
      const pinUrl = 'https://maps.google.com/?q=33.6844,73.0479';
      final msg = SmsService.autoDispatchEmergencyMessage(
        'Fire Alarm',
        locationUrl: pinUrl,
        accuracy: 8.5,
      );

      expect(msg, contains('CRITICAL ALERT via AlertSense: Fire Alarm detected at user location.'));
      expect(msg, contains('User is currently unacknowledged.'));
      expect(msg, contains('📍 Pin: https://maps.google.com/?q=33.6844,73.0479 (±9m)'));
      expect(msg, contains('Sent automatically by AlertSense.'));
    });

    test('autoDispatchEmergencyMessage formats with LocationResult object directly', () {
      final loc = LocationResult(
        latitude: 24.8607,
        longitude: 67.0011,
        accuracy: 5.2,
        timestamp: DateTime(2026, 9, 29),
      );

      final msg = SmsService.autoDispatchEmergencyMessage(
        'Fire Alarm',
        location: loc,
      );

      expect(msg, contains('📍 Pin: https://maps.google.com/?q=24.8607,67.0011 (±5m)'));
    });

    test('autoDispatchEmergencyMessage falls back when locationUrl is empty or whitespace', () {
      final msg = SmsService.autoDispatchEmergencyMessage('Smoke Detector', locationUrl: '  ');

      expect(msg, equals('CRITICAL ALERT: Smoke Detector detected at user location. User is currently unacknowledged. Sent automatically by AlertSense.'));
    });
  });

  group('SmsService WhatsApp emergency template tests', () {
    test('whatsAppEmergencyMessage formats clickable link template matching emergencyMessage', () {
      const pinUrl = 'https://maps.google.com/?q=31.5204,74.3587';
      final msg = SmsService.whatsAppEmergencyMessage(
        'Baby Cry',
        locationUrl: pinUrl,
        accuracy: 15.0,
      );

      expect(msg, contains('EMERGENCY ALERT via AlertSense: A Baby Cry has been detected at my location!'));
      expect(msg, contains('📍 Pin: https://maps.google.com/?q=31.5204,74.3587 (±15m)'));
    });

    test('whatsAppEmergencyMessage formats with LocationResult directly', () {
      final loc = LocationResult(
        latitude: 31.5204,
        longitude: 74.3587,
        accuracy: 10.0,
        timestamp: DateTime(2026, 9, 29),
      );

      final msg = SmsService.whatsAppEmergencyMessage('Siren', location: loc);
      expect(msg, contains('📍 Pin: https://maps.google.com/?q=31.5204,74.3587 (±10m)'));
    });

    test('safeMessage formats correctly', () {
      final msg = SmsService.safeMessage('Door Knock');
      expect(msg, contains('A Door Knock was detected earlier, but I have verified that I am safe.'));
    });
  });

  group('SmsService phone number normalization for WhatsApp tests', () {
    test('formats local 03xx Pakistani numbers to international format', () {
      expect(SmsService.formatForWhatsApp('03001234567'), '923001234567');
      expect(SmsService.formatForWhatsApp('0321 9876543'), '923219876543');
    });

    test('handles leading plus sign', () {
      expect(SmsService.formatForWhatsApp('+923001234567'), '923001234567');
      expect(SmsService.formatForWhatsApp('+1 (555) 123-4567'), '15551234567');
    });

    test('handles leading 00 international prefix', () {
      expect(SmsService.formatForWhatsApp('00923001234567'), '923001234567');
    });

    test('strips dashes, parentheses, spaces, and punctuation', () {
      expect(SmsService.formatForWhatsApp('+92-300-123.4567'), '923001234567');
    });

    test('handles empty or whitespace strings', () {
      expect(SmsService.formatForWhatsApp(''), '');
      expect(SmsService.formatForWhatsApp('   '), '');
    });
  });

  group('SmsService URI encoding tests', () {
    test('message with Google Maps link, newlines, and pin emoji preserves formatting when encoded', () {
      const pinUrl = 'https://maps.google.com/?q=33.6844,73.0479';
      final msg = SmsService.emergencyMessage('Smoke Alarm', locationUrl: pinUrl, accuracy: 12.0);
      final encoded = Uri.encodeComponent(msg);

      expect(encoded, contains(Uri.encodeComponent('https://maps.google.com/?q=33.6844,73.0479')));
      expect(encoded, contains(Uri.encodeComponent('📍 Pin:')));
      expect(encoded, contains('%0A')); // newlines encoded as %0A
    });
  });

  group('SmsService sendEmergencySms direct dispatch tests', () {
    const channel = MethodChannel('com.alertsense/device');
    const permChannel = MethodChannel('flutter.baseflow.com/permissions/methods');

    setUp(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(permChannel, (MethodCall methodCall) async {
        if (methodCall.method == 'checkPermissionStatus') {
          return 1; // PermissionStatus.granted index
        }
        if (methodCall.method == 'requestPermissions') {
          return {13: 1}; // SMS permission granted
        }
        return 1;
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(permChannel, null);
    });

    test('sendEmergencySms returns false when recipients list is empty', () async {
      final result = await SmsService.sendEmergencySms(
        recipients: [],
        message: 'test',
        directOnly: true,
      );
      expect(result, isFalse);
    });

    test('sendEmergencySms sends via native sendDirectSms with directOnly=true', () async {
      Map<String, dynamic>? receivedArgs;
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'sendDirectSms') {
          receivedArgs = Map<String, dynamic>.from(methodCall.arguments as Map);
          return true;
        }
        return false;
      });

      final result = await SmsService.sendEmergencySms(
        recipients: ['+923001234567', '03009876543'],
        message: 'Critical Fire Alarm detected!',
        directOnly: true,
      );

      expect(result, isTrue);
      expect(receivedArgs, isNotNull);
      expect(receivedArgs!['recipients'], ['+923001234567', '03009876543']);
      expect(receivedArgs!['message'], 'Critical Fire Alarm detected!');
    });

    test('sendEmergencySms with directOnly=true suppresses inbox opening if native dispatch fails', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        if (methodCall.method == 'sendDirectSms') {
          return false;
        }
        return false;
      });

      final result = await SmsService.sendEmergencySms(
        recipients: ['03001234567'],
        message: 'Test alert',
        directOnly: true,
      );

      // Should return false and not launch URL / inbox
      expect(result, isFalse);
    });
  });
}
