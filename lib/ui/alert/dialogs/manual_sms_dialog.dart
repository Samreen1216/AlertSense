import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Modal dialog for dispatching direct emergency SMS messages with phone input and message preview.
class ManualSmsDialog extends StatefulWidget {
  final String initialPhone;
  final String defaultMessage;

  const ManualSmsDialog({
    super.key,
    required this.initialPhone,
    required this.defaultMessage,
  });

  /// Displays the manual SMS dialog and returns the recipient phone and message, or null if cancelled.
  static Future<({String phone, String message})?> show(
    BuildContext context, {
    required String initialPhone,
    required String defaultMessage,
  }) {
    return showDialog<({String phone, String message})>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => ManualSmsDialog(
        initialPhone: initialPhone,
        defaultMessage: defaultMessage,
      ),
    );
  }

  @override
  State<ManualSmsDialog> createState() => _ManualSmsDialogState();
}

class _ManualSmsDialogState extends State<ManualSmsDialog> {
  late final TextEditingController _phoneController;
  late final TextEditingController _messageController;
  String? _phoneError;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.initialPhone);
    _messageController = TextEditingController(text: widget.defaultMessage);
    _phoneController.addListener(() {
      if (_phoneError != null && _phoneController.text.trim().isNotEmpty) {
        setState(() => _phoneError = null);
      }
    });
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
          Icon(Icons.sms_rounded, color: Color(0xFFE65100), size: 28),
          SizedBox(width: 12),
          Text(
            'Alert Family via SMS',
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
              'Phone number to SMS:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              autofocus: true,
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\+\-\(\) ]'))],
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.phone, color: Color(0xFFE65100)),
                hintText: 'Enter recipient phone number',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 13),
                errorText: _phoneError,
                filled: true,
                fillColor: const Color(0xFF2C2C2C),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE65100)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE65100)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFFF9800), width: 2.0),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Message preview & edit:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
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
                  borderSide: const BorderSide(color: Color(0xFFE65100), width: 1.5),
                ),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tip: Save contacts in Settings → Emergency Contacts for one-tap sending.',
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
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: const Color(0xFFE65100)),
          onPressed: () {
            final phone = _phoneController.text.trim();
            final msg = _messageController.text.trim();
            if (phone.isNotEmpty) {
              Navigator.of(context).pop((phone: phone, message: msg));
            } else {
              setState(() => _phoneError = 'Please enter a recipient phone number');
            }
          },
          child: const Text('SEND SMS', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
