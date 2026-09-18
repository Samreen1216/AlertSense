import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service for quick emergency responses, phone dialing, and SMS messaging.
class SmsService {
  /// Open the phone dialer with a specific emergency number (e.g., 1122, 911, etc.).
  static Future<bool> dialEmergencyNumber(String number) async {
    final cleanNumber = number.trim().replaceAll(' ', '');
    final uri = Uri(scheme: 'tel', path: cleanNumber);
    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Direct attempt fallback
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[SmsService] Dial error: $e');
      return false;
    }
  }

  /// Send an SMS message to a contact with pre-composed text.
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

    // Standard Android SMS intent
    final recipientString = cleanRecipients.join(',');
    final uri = Uri(
      scheme: 'sms',
      path: recipientString,
      queryParameters: <String, String>{
        'body': message,
      },
    );

    try {
      if (await canLaunchUrl(uri)) {
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback with smsto:
        final fallbackUri = Uri(
          scheme: 'smsto',
          path: recipientString,
          queryParameters: <String, String>{
            'body': message,
          },
        );
        return await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      debugPrint('[SmsService] SMS launch error: $e');
      try {
        // Direct attempt without canLaunchUrl check
        return await launchUrl(uri, mode: LaunchMode.externalApplication);
      } catch (innerErr) {
        debugPrint('[SmsService] Direct SMS launch fallback error: $innerErr');
        return false;
      }
    }
  }

  /// Preset message for "I'm Safe" notification.
  static String safeMessage(String soundName) {
    return 'AlertSense notice: A $soundName was detected earlier, but I have verified that I am safe. No action is required.';
  }

  /// Preset message for "Emergency Alert" to family.
  static String emergencyMessage(String soundName) {
    return 'EMERGENCY ALERT via AlertSense: A $soundName has been detected at my location. Please check on me or call for assistance!';
  }
}
