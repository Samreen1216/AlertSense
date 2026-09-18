import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/audio_providers.dart';

class DbMeterWidget extends ConsumerWidget {
  const DbMeterWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ambientDb = ref.watch(ambientDbProvider);
    // Range 0 to 120
    final progress = (ambientDb / 120.0).clamp(0.0, 1.0);

    Color getBarColor(double db) {
      if (db <= 40) return Colors.green;
      if (db <= 70) return Colors.yellow;
      if (db <= 90) return Colors.orange;
      return Colors.red;
    }

    return SizedBox(
      height: 24,
      child: Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: progress,
                minHeight: 8,
                backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
                valueColor: AlwaysStoppedAnimation<Color>(getBarColor(ambientDb)),
              ),
            ),
          ),
          const SizedBox(width: 12),
          SizedBox(
            width: 48,
            child: Text(
              '${ambientDb.toInt()} dB',
              textAlign: TextAlign.end,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}
