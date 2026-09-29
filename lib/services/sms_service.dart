import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';
import 'location_service.dart';

/// Service for quick emergency responses, phone dialing, SMS messaging, and WhatsApp alerts.
class SmsService {
  static const MethodChannel _deviceChannel = MethodChannel('com.alertsense/device');

  /// Open the phone dialer with a specific emergency number (e.g., 1122, 911, etc.).
  static Future<bool> dialEmergencyNumber(String number) async {
    final cleanNumber = number.trim().replaceAll(' ', '');
    final uri = Uri(scheme: 'tel', path: cleanNumber);
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[SmsService] Dial error: $e');
      try {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (innerErr) {
        debugPrint('[SmsService] Direct dial fallback error: $innerErr');
        return false;
      }
    }
  }

  /// Send an SMS message to contact(s) with pre-composed text directly via native SMS inbox.
  static Future<bool> sendEmergencySms({
    required List<String> recipients,
    required String message,
  }) async {
    if (recipients.isEmpty) {
      debugPrint('[SmsService] No recipients specified');
      return false;
    }

    final cleanRecipients = recipients
        .map((r) => r.trim().replaceAll(' ', ''))
        .where((r) => r.isNotEmpty)
        .toList();

    if (cleanRecipients.isEmpty) return false;

    final primaryRecipient = cleanRecipients.first;
    final allRecipients = cleanRecipients.join(',');
    final encodedMsg = Uri.encodeComponent(message);

    // 0. On Android, use native Intent with default SMS package to bypass the "Open with WhatsApp" chooser
    if (defaultTargetPlatform == TargetPlatform.android) {
      try {
        final targetRecipient =
            cleanRecipients.length == 1 ? primaryRecipient : cleanRecipients.join(';');
        final success = await _deviceChannel.invokeMethod<bool>('sendDirectSms', {
          'recipient': targetRecipient,
          'message': message,
        });
        if (success == true) {
          debugPrint('[SmsService] Native direct SMS successfully launched for $targetRecipient');
          return true;
        }
      } catch (e) {
        debugPrint('[SmsService] Native direct SMS failed: $e, falling back to url_launcher');
      }
    }

    // 1. Prioritize smsto: and sms: schemes with proper body encoding (targets native SMS Inbox)
    final rawSmstoSingleUri = Uri.parse('smsto:$primaryRecipient?body=$encodedMsg');
    final querySmstoSingleUri = Uri(
      scheme: 'smsto',
      path: primaryRecipient,
      queryParameters: <String, String>{'body': message},
    );
    final rawSmsSingleUri = Uri.parse('sms:$primaryRecipient?body=$encodedMsg');
    final querySmsSingleUri = Uri(
      scheme: 'sms',
      path: primaryRecipient,
      queryParameters: <String, String>{'body': message},
    );
    final rawIosSmsUri = Uri.parse('sms:$primaryRecipient&body=$encodedMsg');

    final smstoAllUri = Uri(
      scheme: 'smsto',
      path: allRecipients,
      queryParameters: <String, String>{'body': message},
    );
    final rawSmstoAllUri = Uri.parse('smsto:$allRecipients?body=$encodedMsg');
    final smsUri = Uri(
      scheme: 'sms',
      path: allRecipients,
      queryParameters: <String, String>{'body': message},
    );
    final rawSmsAllUri = Uri.parse('sms:$allRecipients?body=$encodedMsg');

    final candidates = [
      rawSmstoSingleUri,
      querySmstoSingleUri,
      rawSmsSingleUri,
      querySmsSingleUri,
      smstoAllUri,
      rawSmstoAllUri,
      rawIosSmsUri,
      smsUri,
      rawSmsAllUri,
    ];

    for (final candidate in candidates) {
      try {
        if (await canLaunchUrl(candidate)) {
          return await launchUrl(candidate, mode: LaunchMode.externalApplication);
        }
      } catch (_) {}
    }

    // Direct launches without pre-flight check in case canLaunchUrl was restricted by OS
    for (final fallback in [rawSmstoSingleUri, querySmsSingleUri, rawSmsSingleUri, smsUri]) {
      try {
        return await launchUrl(fallback, mode: LaunchMode.externalApplication);
      } catch (_) {}
    }
    return false;
  }

  /// Format phone numbers into clean international format suitable for WhatsApp.
  /// Handles local formats (e.g. 03001234567 -> 923001234567), +92..., 0092..., etc.
  static String formatForWhatsApp(String phone, {String defaultCountryCode = '92'}) {
    final raw = phone.trim();
    if (raw.isEmpty) return '';

    // Remove punctuation, spaces, dashes, parentheses
    String cleaned = raw.replaceAll(RegExp(r'[\s\-\(\)\.]'), '');

    if (cleaned.startsWith('+')) {
      cleaned = cleaned.substring(1);
    } else if (cleaned.startsWith('00')) {
      cleaned = cleaned.substring(2);
    } else if (cleaned.startsWith('0') && cleaned.length >= 10) {
      // Convert local leading 0 (e.g., 03001234567) to country code (e.g., 923001234567)
      cleaned = '$defaultCountryCode${cleaned.substring(1)}';
    }

    // Retain only digits
    cleaned = cleaned.replaceAll(RegExp(r'\D'), '');
    return cleaned;
  }

  /// Send an alert via WhatsApp.
  /// If [phoneNumber] is provided, formats it accurately to avoid invite/joining screens.
  /// If [phoneNumber] is empty or fails, opens WhatsApp chat picker directly.
  static Future<bool> sendEmergencyWhatsApp({
    String? phoneNumber,
    required String message,
  }) async {
    final cleanPhone = phoneNumber != null ? formatForWhatsApp(phoneNumber) : '';

    // 1. If phone number is available, attempt direct WhatsApp chat URL
    if (cleanPhone.isNotEmpty) {
      final whatsappDirectUri = Uri.parse(
        'whatsapp://send?phone=$cleanPhone&text=${Uri.encodeComponent(message)}',
      );
      final apiDirectUri = Uri.parse(
        'https://api.whatsapp.com/send?phone=$cleanPhone&text=${Uri.encodeComponent(message)}',
      );
      final waMeUri = Uri.parse(
        'https://wa.me/$cleanPhone?text=${Uri.encodeComponent(message)}',
      );

      for (final candidate in [whatsappDirectUri, apiDirectUri, waMeUri]) {
        try {
          if (await canLaunchUrl(candidate)) {
            return await launchUrl(candidate, mode: LaunchMode.externalApplication);
          }
        } catch (_) {}
      }

      // Direct fallback attempt without pre-flight check in case OS queries were inconclusive
      for (final candidate in [whatsappDirectUri, waMeUri, apiDirectUri]) {
        try {
          return await launchUrl(candidate, mode: LaunchMode.externalApplication);
        } catch (_) {}
      }
    }

    // 2. Open WhatsApp Contact/Group Chooser with pre-filled message (No phone needed, zero invite errors)
    final whatsappShareUri = Uri.parse(
      'whatsapp://send?text=${Uri.encodeComponent(message)}',
    );
    final apiShareUri = Uri.parse(
      'https://api.whatsapp.com/send?text=${Uri.encodeComponent(message)}',
    );

    for (final candidate in [whatsappShareUri, apiShareUri]) {
      try {
        if (await canLaunchUrl(candidate)) {
          return await launchUrl(candidate, mode: LaunchMode.externalApplication);
        }
      } catch (_) {}
    }
    try {
      return await launchUrl(whatsappShareUri, mode: LaunchMode.externalApplication);
    } catch (_) {}

    // 3. Fallback: System Share sheet so user can send via WhatsApp or any installed messenger
    try {
      await Share.share(message, subject: 'AlertSense Emergency Alert');
      return true;
    } catch (e) {
      debugPrint('[SmsService] Share fallback error: $e');
      return false;
    }
  }

  /// Preset message for "I'm Safe" notification.
  static String safeMessage(String soundName) {
    return 'AlertSense notice: A $soundName was detected earlier, but I have verified that I am safe. No action is required.';
  }

  /// Preset message for "Emergency Alert" to family via SMS or WhatsApp.
  /// If [location] or [locationUrl] is provided, formats with clickable Google Maps pin and optional accuracy.
  static String emergencyMessage(
    String soundName, {
    String? locationUrl,
    double? accuracy,
    LocationResult? location,
  }) {
    final url = location?.toGoogleMapsUrl() ?? locationUrl;
    final acc = location?.accuracy ?? accuracy;

    if (url != null && url.trim().isNotEmpty) {
      final accStr = acc != null ? ' (±${acc.round()}m)' : '';
      return 'EMERGENCY ALERT via AlertSense: A $soundName has been detected at my location!\n\n'
          '📍 Pin: $url$accStr\n\n'
          'Please check on me or call for assistance!';
    }
    return 'EMERGENCY ALERT via AlertSense: A $soundName has been detected at my location. Please check on me or call for assistance!';
  }

  /// Preset message for auto-dispatched critical alerts when 45-second countdown expires unacknowledged.
  static String autoDispatchEmergencyMessage(
    String soundName, {
    String? locationUrl,
    double? accuracy,
    LocationResult? location,
  }) {
    final url = location?.toGoogleMapsUrl() ?? locationUrl;
    final acc = location?.accuracy ?? accuracy;

    if (url != null && url.trim().isNotEmpty) {
      final accStr = acc != null ? ' (±${acc.round()}m)' : '';
      return 'CRITICAL ALERT via AlertSense: $soundName detected at user location. '
          'User is currently unacknowledged.\n\n'
          '📍 Pin: $url$accStr\n\n'
          'Sent automatically by AlertSense.';
    }
    return 'CRITICAL ALERT: $soundName detected at user location. User is currently unacknowledged. Sent automatically by AlertSense.';
  }

  /// Preset message for WhatsApp emergency alert.
  static String whatsAppEmergencyMessage(
    String soundName, {
    String? locationUrl,
    double? accuracy,
    LocationResult? location,
  }) {
    return emergencyMessage(
      soundName,
      locationUrl: locationUrl,
      accuracy: accuracy,
      location: location,
    );
  }
}

