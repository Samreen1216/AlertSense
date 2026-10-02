import 'package:flutter/material.dart';

enum AlertChannel { whatsapp, sms }

/// A reusable modal dialog that lets users choose between WhatsApp and SMS
/// for emergency family notifications with live GPS location support.
class AlertFamilyChoiceDialog extends StatefulWidget {
  final List<String> savedContacts;
  final String soundName;
  final AlertChannel initialChannel;

  const AlertFamilyChoiceDialog({
    super.key,
    required this.savedContacts,
    required this.soundName,
    this.initialChannel = AlertChannel.sms,
  });

  /// Displays the AlertFamilyChoiceDialog and returns the selected [AlertChannel] (or null on dismiss).
  static Future<AlertChannel?> show(
    BuildContext context, {
    required List<String> savedContacts,
    required String soundName,
    AlertChannel initialChannel = AlertChannel.sms,
  }) {
    return showDialog<AlertChannel>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertFamilyChoiceDialog(
        savedContacts: savedContacts,
        soundName: soundName,
        initialChannel: initialChannel,
      ),
    );
  }

  @override
  State<AlertFamilyChoiceDialog> createState() => _AlertFamilyChoiceDialogState();
}

class _AlertFamilyChoiceDialogState extends State<AlertFamilyChoiceDialog> {
  late AlertChannel _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.initialChannel;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final primaryContact =
        widget.savedContacts.isNotEmpty ? widget.savedContacts.first : null;

    const whatsappColor = Color(0xFF25D366);
    const smsColor = Color(0xFFE65100);
    final activeColor = _selected == AlertChannel.whatsapp ? whatsappColor : smsColor;

    return AlertDialog(
      backgroundColor: isDark ? const Color(0xFF1E222D) : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isDark ? Colors.white12 : Colors.black12,
          width: 1.0,
        ),
      ),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 16),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFFE65100).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.family_restroom_rounded,
              color: Color(0xFFE65100),
              size: 26,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Alert Family',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    fontSize: 19,
                  ),
                ),
                if (primaryContact != null)
                  Text(
                    widget.savedContacts.length > 1
                        ? 'To: $primaryContact (+${widget.savedContacts.length - 1} more)'
                        : 'To: $primaryContact',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Choose which messaging app to send the alert with:',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            const SizedBox(height: 16),

            // ── Messages (SMS) Card ──
            _ChannelOptionTile(
              channel: AlertChannel.sms,
              isSelected: _selected == AlertChannel.sms,
              title: 'Messages (SMS)',
              subtitle: 'Send via native cellular SMS Inbox',
              accentColor: smsColor,
              icon: Icons.sms_rounded,
              isDark: isDark,
              onTap: () => setState(() => _selected = AlertChannel.sms),
            ),

            const SizedBox(height: 12),

            // ── WhatsApp Card ──
            _ChannelOptionTile(
              channel: AlertChannel.whatsapp,
              isSelected: _selected == AlertChannel.whatsapp,
              title: 'WhatsApp',
              subtitle: 'Send via WhatsApp chat',
              accentColor: whatsappColor,
              icon: Icons.chat_rounded,
              isDark: isDark,
              onTap: () => setState(() => _selected = AlertChannel.whatsapp),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(null),
          style: TextButton.styleFrom(
            foregroundColor: isDark ? Colors.white60 : Colors.black54,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          ),
          child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
        ),
        FilledButton(
          style: FilledButton.styleFrom(
            backgroundColor: activeColor,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: 2,
          ),
          onPressed: () {
            Navigator.of(context).pop(_selected);
          },
          child: const Text(
            'JUST ONCE',
            style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.8),
          ),
        ),
      ],
    );
  }
}

class _ChannelOptionTile extends StatelessWidget {
  final AlertChannel channel;
  final bool isSelected;
  final String title;
  final String subtitle;
  final Color accentColor;
  final IconData icon;
  final bool isDark;
  final VoidCallback onTap;

  const _ChannelOptionTile({
    required this.channel,
    required this.isSelected,
    required this.title,
    required this.subtitle,
    required this.accentColor,
    required this.icon,
    required this.isDark,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected
              ? accentColor.withValues(alpha: isDark ? 0.18 : 0.12)
              : (isDark ? const Color(0xFF272B37) : const Color(0xFFF3F4F6)),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isSelected ? accentColor : (isDark ? Colors.white12 : Colors.black12),
            width: isSelected ? 2.0 : 1.0,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: accentColor.withValues(alpha: 0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: accentColor, size: 22),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white60 : Colors.black54,
                    ),
                  ),
                ],
              ),
            ),
            Radio<AlertChannel>(
              value: channel,
              // ignore: deprecated_member_use
              groupValue: isSelected ? channel : null,
              activeColor: accentColor,
              // ignore: deprecated_member_use
              onChanged: (_) => onTap(),
            ),
          ],
        ),
      ),
    );
  }
}
