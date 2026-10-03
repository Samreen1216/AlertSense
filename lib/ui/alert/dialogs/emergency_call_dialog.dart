import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Modal dialog for dialing emergency numbers with regional pre-sets (1122, 911, 999, 112).
class EmergencyCallDialog extends StatefulWidget {
  final String initialNumber;

  const EmergencyCallDialog({
    super.key,
    this.initialNumber = '1122',
  });

  /// Displays the emergency call dialog and returns the confirmed number, or null if cancelled.
  static Future<String?> show(
    BuildContext context, {
    String initialNumber = '1122',
  }) {
    return showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => EmergencyCallDialog(initialNumber: initialNumber),
    );
  }

  @override
  State<EmergencyCallDialog> createState() => _EmergencyCallDialogState();
}

class _EmergencyCallDialogState extends State<EmergencyCallDialog> {
  late final TextEditingController _controller;

  static const List<({String number, String label})> _regionalNumbers = [
    (number: '1122', label: '1122 (Rescue)'),
    (number: '911', label: '911 (US/CA)'),
    (number: '999', label: '999 (UK)'),
    (number: '112', label: '112 (EU)'),
    (number: '115', label: '115 (Edhi)'),
    (number: '15', label: '15 (Police)'),
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialNumber);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _callNow() {
    final number = _controller.text.trim();
    Navigator.of(context).pop(number.isNotEmpty ? number : null);
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
          Icon(Icons.local_phone_rounded, color: Colors.red, size: 28),
          SizedBox(width: 12),
          Text(
            'Emergency Call',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      content: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Confirm emergency number to dial:',
              style: TextStyle(color: Colors.white70, fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _controller,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              autocorrect: false,
              enableSuggestions: false,
              autofocus: true,
              scrollPadding: const EdgeInsets.all(24.0),
              onSubmitted: (_) => _callNow(),
              inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[\d\+\-\(\) ]'))],
              style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                prefixIcon: const Icon(Icons.phone, color: Colors.red),
                hintText: 'e.g. 1122 / 911 / 999 / 112',
                hintStyle: const TextStyle(color: Colors.white38, fontSize: 14),
                filled: true,
                fillColor: const Color(0xFF2C2C2C),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 1.5),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red, width: 1.5),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.redAccent, width: 2.0),
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Text(
              'Quick Select Regional Numbers:',
              style: TextStyle(color: Colors.white60, fontSize: 11, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: _regionalNumbers.map((reg) {
                final isSelected = _controller.text.trim() == reg.number;
                return ChoiceChip(
                  label: Text(reg.label),
                  selected: isSelected,
                  selectedColor: Colors.red.withValues(alpha: 0.35),
                  backgroundColor: const Color(0xFF2C2C2C),
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.redAccent : Colors.white70,
                    fontSize: 11,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  side: BorderSide(
                    color: isSelected ? Colors.red : Colors.white12,
                  ),
                  onSelected: (_) {
                    setState(() {
                      _controller.text = reg.number;
                      _controller.selection = TextSelection.fromPosition(
                        TextPosition(offset: reg.number.length),
                      );
                    });
                  },
                );
              }).toList(),
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
          style: FilledButton.styleFrom(backgroundColor: Colors.red),
          onPressed: _callNow,
          child: const Text('CALL NOW', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
