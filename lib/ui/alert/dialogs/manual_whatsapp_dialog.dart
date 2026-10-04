import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/app_colors.dart';

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
  late final FocusNode _phoneFocusNode;
  late final FocusNode _messageFocusNode;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController(text: widget.initialPhone);
    _messageController = TextEditingController(text: widget.defaultMessage);
    _phoneFocusNode = FocusNode();
    _messageFocusNode = FocusNode();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _messageController.dispose();
    _phoneFocusNode.dispose();
    _messageFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isHighContrast = theme.scaffoldBackgroundColor == Colors.black;

    final Color dialogBg;
    final Color dialogBorder;
    final Color titleColor;
    final Color labelColor;
    final Color inputFill;
    final Color inputTextColor;
    final Color inputBorder;
    final Color tipColor;
    final Color cancelColor;

    if (isHighContrast) {
      dialogBg = AppColors.hcSurface;
      dialogBorder = AppColors.hcPrimary;
      titleColor = Colors.white;
      labelColor = const Color(0xFFE2E8F0);
      inputFill = Colors.black;
      inputTextColor = Colors.white;
      inputBorder = AppColors.hcPrimary;
      tipColor = const Color(0xFFE2E8F0);
      cancelColor = Colors.white;
    } else if (isDark) {
      dialogBg = const Color(0xFF111C35);
      dialogBorder = const Color(0xFF1E2D4E);
      titleColor = Colors.white;
      labelColor = Colors.white70;
      inputFill = const Color(0xFF182544);
      inputTextColor = Colors.white;
      inputBorder = const Color(0xFF23355E);
      tipColor = Colors.white54;
      cancelColor = Colors.white70;
    } else {
      dialogBg = Colors.white;
      dialogBorder = const Color(0xFFE2E8F0);
      titleColor = const Color(0xFF0F172A);
      labelColor = const Color(0xFF475569);
      inputFill = const Color(0xFFF8FAFC);
      inputTextColor = const Color(0xFF0F172A);
      inputBorder = const Color(0xFFCBD5E1);
      tipColor = const Color(0xFF64748B);
      cancelColor = const Color(0xFF64748B);
    }

    final hasGps = _messageController.text.contains('maps.google.com');
    final gpsBadgeBg = hasGps
        ? (isDark
            ? const Color(0xFF1B5E20).withValues(alpha: 0.6)
            : const Color(0xFFE8F5E9))
        : (isDark
            ? Colors.amber.shade900.withValues(alpha: 0.4)
            : const Color(0xFFFFF3E0));
    final gpsBadgeBorder = hasGps
        ? (isDark ? const Color(0xFF69F0AE) : const Color(0xFF2E7D32))
        : (isDark ? Colors.amberAccent : const Color(0xFFE65100));
    final gpsBadgeText = hasGps
        ? (isDark ? const Color(0xFF69F0AE) : const Color(0xFF1B5E20))
        : (isDark ? Colors.amberAccent : const Color(0xFFE65100));

    return AlertDialog(
      backgroundColor: dialogBg,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: dialogBorder,
          width: isHighContrast ? 1.5 : 1.0,
        ),
      ),
      titlePadding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      contentPadding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF25D366).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.chat_rounded, color: Color(0xFF25D366), size: 24),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Alert via WhatsApp',
              style: TextStyle(
                color: titleColor,
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 440,
          maxHeight: MediaQuery.sizeOf(context).height * 0.72,
        ),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Recipient phone number (Optional):',
                style: TextStyle(
                  color: labelColor,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                focusNode: _phoneFocusNode,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                enableSuggestions: false,
                scrollPadding: const EdgeInsets.all(24.0),
                onSubmitted: (_) => FocusScope.of(context).unfocus(),
                inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\+\-\(\) ]'))],
                style: TextStyle(color: inputTextColor, fontWeight: FontWeight.bold),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.phone, color: Color(0xFF25D366)),
                  hintText: 'e.g. 0300 1234567 or +92 300 1234567',
                  hintStyle: TextStyle(
                    color: isDark ? Colors.white38 : const Color(0xFF94A3B8),
                    fontSize: 13,
                  ),
                  filled: true,
                  fillColor: inputFill,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: inputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: inputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF25D366), width: 2.0),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                alignment: WrapAlignment.spaceBetween,
                crossAxisAlignment: WrapCrossAlignment.center,
                spacing: 8,
                runSpacing: 6,
                children: [
                  Text(
                    'Emergency message preview & edit:',
                    style: TextStyle(
                      color: labelColor,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: gpsBadgeBg,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: gpsBadgeBorder,
                        width: 1.0,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          hasGps
                              ? Icons.location_on_rounded
                              : Icons.location_off_rounded,
                          size: 13,
                          color: gpsBadgeText,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          hasGps ? 'GPS Pin Attached' : 'No GPS Pin',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: gpsBadgeText,
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
                focusNode: _messageFocusNode,
                keyboardType: TextInputType.multiline,
                textInputAction: TextInputAction.newline,
                textCapitalization: TextCapitalization.sentences,
                autocorrect: true,
                enableSuggestions: true,
                maxLines: 4,
                scrollPadding: const EdgeInsets.all(24.0),
                style: TextStyle(color: inputTextColor, fontSize: 13),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: inputFill,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: inputBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: inputBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFF25D366), width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Tip: You can send directly to a number, or choose any contact/group inside WhatsApp.',
                style: TextStyle(color: tipColor, fontSize: 11),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          child: Text('Cancel', style: TextStyle(color: cancelColor, fontWeight: FontWeight.w600)),
        ),
        OutlinedButton(
          style: OutlinedButton.styleFrom(
            foregroundColor: const Color(0xFF25D366),
            side: const BorderSide(color: Color(0xFF25D366)),
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          onPressed: () {
            final msg = _messageController.text.trim();
            Navigator.of(context).pop((phone: null, message: msg));
          },
          child: const Text('Choose in WhatsApp'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: const Color(0xFF25D366),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
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
