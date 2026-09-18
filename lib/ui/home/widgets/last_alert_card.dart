import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/sound_categories.dart';
import '../../../providers/alert_providers.dart';

class LastAlertCard extends ConsumerWidget {
  const LastAlertCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastAlert = ref.watch(lastAlertProvider);
    final theme = Theme.of(context);

    if (lastAlert == null) {
      return Card(
        elevation: 0,
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.4),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(
            color: theme.colorScheme.outlineVariant.withOpacity(0.5),
          ),
        ),
        child: const Padding(
          padding: EdgeInsets.all(16.0),
          child: Row(
            children: [
              Icon(Icons.check_circle_outline_rounded, color: Colors.green, size: 28),
              SizedBox(width: 14),
              Expanded(
                child: Text(
                  'No recent alerts — environment is safe and clear',
                  style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14),
                ),
              ),
            ],
          ),
        ),
      );
    }

    SoundCategory? category;
    try {
      category = SoundCategory.values.firstWhere(
        (c) => c.name.toLowerCase() == lastAlert.soundCategory.toLowerCase(),
      );
    } catch (_) {}

    final priority = lastAlert.priorityLevel.toLowerCase();
    final color = priority == 'high'
        ? const Color(0xFFD32F2F)
        : (priority == 'medium' ? const Color(0xFFF57C00) : const Color(0xFF388E3C));

    final timeAgo = _formatTimeAgo(lastAlert.timestamp);

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withOpacity(0.5), width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(
          border: Border(left: BorderSide(color: color, width: 6)),
        ),
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: Text(
                category?.emoji ?? '🚨',
                style: const TextStyle(fontSize: 24),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    category?.label ?? lastAlert.soundCategory,
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$timeAgo • ${(lastAlert.confidence * 100).toStringAsFixed(0)}% confidence',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                priority.toUpperCase(),
                style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTimeAgo(DateTime timestamp) {
    final diff = DateTime.now().difference(timestamp);
    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return DateFormat.MMMd().format(timestamp);
  }
}
