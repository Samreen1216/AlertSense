import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/sound_categories.dart';
import '../../data/models/alert_event.dart';
import '../../providers/alert_providers.dart';
import '../shared/priority_badge.dart';
import '../shared/sound_icon.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final List<String> _filters = ['All', 'High', 'Medium', 'Low'];

  @override
  Widget build(BuildContext context) {
    final selectedFilter = ref.watch(alertFilterPriorityProvider) ?? 'All';
    final alerts = ref.watch(filteredAlertsProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert History'),
        actions: [
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'Export / Share History',
            onPressed: alerts.isEmpty ? null : () => _exportHistory(alerts),
          ),
          if (alerts.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.delete_sweep_outlined),
              tooltip: 'Clear All',
              onPressed: () => _confirmClear(context),
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: Row(
              children: _filters.map((filter) {
                final isSelected = selectedFilter.toLowerCase() == filter.toLowerCase();
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(filter == 'All' ? 'All Alerts' : '$filter Priority'),
                    selected: isSelected,
                    onSelected: (selected) {
                      ref.read(alertFilterPriorityProvider.notifier).state =
                          filter == 'All' ? null : filter.toLowerCase();
                    },
                  ),
                );
              }).toList(),
            ),
          ),
          const Divider(height: 1),

          // Alerts List or Empty State
          Expanded(
            child: alerts.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.verified_outlined,
                              size: 64,
                              color: theme.colorScheme.primary.withOpacity(0.7),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No Alerts Recorded',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            selectedFilter == 'All'
                                ? 'AlertSense hasn\'t detected any critical environmental sounds yet.'
                                : 'No $selectedFilter priority alerts found.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: alerts.length,
                    itemBuilder: (context, index) {
                      final alert = alerts[index];
                      final category = _getCategory(alert.soundCategory);
                      final borderColor = _getPriorityColor(alert.priorityLevel);

                      return Dismissible(
                        key: Key(alert.id),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          color: theme.colorScheme.error,
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              Icon(Icons.delete_outline_rounded, color: Colors.white),
                              SizedBox(width: 8),
                              Text('Delete', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        onDismissed: (_) {
                          ref.read(alertListProvider.notifier).removeAlert(alert.id);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Removed ${category?.label ?? alert.soundCategory} alert'),
                              action: SnackBarAction(
                                label: 'Undo',
                                onPressed: () {
                                  ref.read(alertListProvider.notifier).addAlert(alert);
                                },
                              ),
                            ),
                          );
                        },
                        child: Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: BorderSide(
                              color: borderColor.withOpacity(0.5),
                              width: 1.5,
                            ),
                          ),
                          child: Container(
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(16),
                              border: Border(
                                left: BorderSide(color: borderColor, width: 6),
                              ),
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              leading: SoundIcon(
                                emoji: category?.emoji ?? '🔔',
                                color: borderColor.withOpacity(0.15),
                              ),
                              title: Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      category?.label ?? alert.soundCategory,
                                      style: theme.textTheme.titleMedium?.copyWith(
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  PriorityBadge(priority: alert.priorityLevel.toUpperCase()),
                                ],
                              ),
                              subtitle: Padding(
                                padding: const EdgeInsets.only(top: 6.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      '${(alert.confidence * 100).toStringAsFixed(0)}% Confidence • ${DateFormat.yMMMd().add_jm().format(alert.timestamp)}',
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                    if (alert.acknowledged)
                                      Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Row(
                                          children: [
                                            const Icon(Icons.check_circle, size: 14, color: Colors.green),
                                            const SizedBox(width: 4),
                                            Text(
                                              'Acknowledged (${alert.responseAction ?? "checked"})',
                                              style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  SoundCategory? _getCategory(String name) {
    try {
      return SoundCategory.values.firstWhere((c) => c.name.toLowerCase() == name.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  Color _getPriorityColor(String priority) {
    switch (priority.toLowerCase()) {
      case 'high':
        return const Color(0xFFD32F2F);
      case 'medium':
        return const Color(0xFFF57C00);
      case 'low':
      default:
        return const Color(0xFF388E3C);
    }
  }

  Future<void> _exportHistory(List<AlertEvent> alerts) async {
    final buffer = StringBuffer();
    buffer.writeln('=== AlertSense Event Log ===');
    buffer.writeln('Generated: ${DateFormat.yMd().add_jm().format(DateTime.now())}');
    buffer.writeln('Total Events: ${alerts.length}\n');

    for (final a in alerts) {
      final cat = _getCategory(a.soundCategory)?.label ?? a.soundCategory;
      buffer.writeln('[${DateFormat.yMd().add_jm().format(a.timestamp)}] ${a.priorityLevel.toUpperCase()}: $cat (${(a.confidence * 100).toStringAsFixed(0)}%)');
    }

    await Share.share(buffer.toString(), subject: 'AlertSense Event Log');
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Alert History?'),
        content: const Text('This will permanently delete all recorded alert events.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              ref.read(alertListProvider.notifier).clear();
              Navigator.pop(ctx);
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
