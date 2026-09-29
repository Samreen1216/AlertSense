import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Modal dialog for dispatching manual emergency alerts via WhatsApp.
///
/// Provides phone input and emergency message preview, with options to either
/// send directly to a specific phone number or select a contact/group in WhatsApp.
class ManualWhatsAppDialog extends StatefulWidget {
  final String initialPhone;
  final String defaultMessage;

  const ManualWhatsAppDialog({
    super.key,
    required this.initialPhone,
    required this.defaultMessage,
  });

  /// Displays the manual WhatsApp dialog and returns the recipient phone (or null) and message.
  static Future<({String? phone, String message})?> show(
    BuildContext context, {
    required String initialPhone,
    required String defaultMessage,
  }) {
    return showDialog<({String? phone, String message})>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ManualWhatsAppDialog(
        initialPhone: initialPhone,
        defaultMessage: defaultMessage,
      ),
    );
  }

  @override
  State<ManualWhatsAppDialog> createState() => _ManualWhatsAppDialogState();
}

class _ManualWhatsAppDialogState extends State<ManualWhatsAppDialog> {
  late final TextEditingController _phoneController;
  late final TextEditingController _messageController;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.initialPhone);
    _messageController = TextEditingController(text: widget.defaultMessage);
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: const Color(0xFF1A1A1A),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: const BorderSide(color: Colors.white24, width: 1.0),
      ),
      title: const Row(
        children: [
          Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 28),
          SizedBox(width: 12),
          Text(
            'Alert via WhatsApp',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Recipient phone number (Optional):',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\+\-\(\) ]'))],
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.phone, color: Color(0xFF25D366)),
                hintText: 'e.g. 0300 1234567 or +92 300 1234567',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                filled: true,
                fillColor: const Color(0xFF2C2C2C),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF25D366)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF25D366)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF25D366), width: 2.0),
                ),
              ),
            ),
            const SizedBox(height: 14),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Emergency message preview & edit:',
                  style: TextStyle(color: Colors.white70, fontSize: 13),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: _messageController.text.contains('maps.google.com')
                        ? const Color(0xFF1B5E20).withValues(alpha: 0.6)
                        : Colors.amber.shade900.withValues(alpha: 0.4),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _messageController.text.contains('maps.google.com')
                          ? const Color(0xFF69F0AE)
                          : Colors.amberAccent,
                      width: 1.0,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _messageController.text.contains('maps.google.com')
                            ? Icons.location_on_rounded
                            : Icons.location_off_rounded,
                        size: 13,
                        color: _messageController.text.contains('maps.google.com')
                            ? const Color(0xFF69F0AE)
                            : Colors.amberAccent,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _messageController.text.contains('maps.google.com')
                            ? 'GPS Pin Attached'
                            : 'No GPS Pin',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: _messageController.text.contains('maps.google.com')
                              ? Colors.white
                              : Colors.amberAccent,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _messageController,
              maxLines: 4,
              style: const TextStyle(color: Colors.white, fontSize: 13),
              decoration: InputDecoration(
                filled: true,
                fillColor: const Color(0xFF2C2C2C),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.white24),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFF25D366), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Tip: You can send directly to a number, or choose any contact/group inside WhatsApp.',
              style: TextStyle(color: Colors.white38, fontSize: 11),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: const Text('Cancel', style: TextStyle(color: Colors.white54)),
        ),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF25D366),
            side: const BorderSide(color: Color(0xFF25D366)),
          ),
          onPressed: () {
            final msg = _messageController.text.trim();
            Navigator.of(context).pop((phone: null, message: msg));
          },
          child: const Text('Choose in WhatsApp'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFF25D366)),
          onPressed: () {
            final phone = _phoneController.text.trim();
            final msg = _messageController.text.trim();
            Navigator.of(context).pop((phone: phone.isNotEmpty ? phone : null, message: msg));
          },
          child: const Text('SEND', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
