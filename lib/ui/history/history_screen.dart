import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/sound_categories.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/theme_provider.dart';
import '../../data/models/alert_event.dart';
import '../../providers/alert_providers.dart';
import '../../services/pdf_export_service.dart';
import '../shared/priority_badge.dart';
import '../shared/sound_icon.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  final List<String> _filters = ['All', 'High', 'Medium', 'Low'];
  bool _isExporting = false;
  ScaffoldFeatureController<SnackBar, SnackBarClosedReason>? _snackBarController;
  Timer? _snackBarTimer;

  @override
  void dispose() {
    _snackBarTimer?.cancel();
    try {
      _snackBarController?.close();
    } catch (_) {}
    super.dispose();
  }

  void _showDeleteSnackBar(AlertEvent alert, SoundCategory? category) {
    _snackBarTimer?.cancel();
    try {
      _snackBarController?.close();
    } catch (_) {}
    if (!mounted) return;

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();

    final label = category?.label ?? alert.soundCategory;
    final controller = messenger.showSnackBar(
      SnackBar(
        content: Text('Removed $label alert'),
        duration: const Duration(seconds: 4),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        action: SnackBarAction(
          label: 'Undo',
          textColor: const Color(0xFF00C6FF),
          onPressed: () {
            _snackBarTimer?.cancel();
            ref.read(alertListProvider.notifier).addAlert(alert);
          },
        ),
      ),
    );
    _snackBarController = controller;

    // Guaranteed auto-dismissal after 4.0s even if system accessibleNavigation disables internal timer
    _snackBarTimer = Timer(const Duration(milliseconds: 4000), () {
      try {
        controller.close();
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final selectedFilter = ref.watch(alertFilterPriorityProvider) ?? 'All';
    final alerts = ref.watch(filteredAlertsProvider);
    final themeType = ref.watch(themeTypeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Group alerts by Today, Yesterday, Earlier
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final Map<String, List<AlertEvent>> grouped = {
      'Today': [],
      'Yesterday': [],
      'Earlier': [],
    };

    for (final a in alerts) {
      final aDate = DateTime(a.timestamp.year, a.timestamp.month, a.timestamp.day);
      if (aDate == today) {
        grouped['Today']!.add(a);
      } else if (aDate == yesterday) {
        grouped['Yesterday']!.add(a);
      } else {
        grouped['Earlier']!.add(a);
      }
    }

    // Remove empty groups
    grouped.removeWhere((key, list) => list.isEmpty);

    final canPop = ModalRoute.of(context)?.canPop ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alert History'),
        automaticallyImplyLeading: false,
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
        actions: [
          IconButton(
            icon: _isExporting
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.share_outlined),
            tooltip: 'Export / Share History',
            onPressed: alerts.isEmpty || _isExporting
                ? null
                : () => _showExportOptionsSheet(context, alerts),
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
                final isSelected =
                    selectedFilter.toLowerCase() == filter.toLowerCase();
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: FilterChip(
                    label: Text(
                        filter == 'All' ? 'All Alerts' : '$filter Priority'),
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
                              color: isDark
                                  ? const Color(0xFF1E2638)
                                  : theme.colorScheme.surfaceContainerHighest
                                      .withValues(alpha: 0.5),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              Icons.notifications_off_outlined,
                              size: 64,
                              color: theme.colorScheme.primary
                                  .withValues(alpha: 0.7),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'No alerts yet',
                            style: theme.textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            selectedFilter == 'All'
                                ? 'No sounds have been detected yet. When an environmental sound or alarm occurs, it will be logged here.'
                                : 'No $selectedFilter priority alerts found.',
                            textAlign: TextAlign.center,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          if (selectedFilter == 'All') ...[
                            const SizedBox(height: 20),
                            FilledButton.icon(
                              onPressed: () => context.push(AppRoutes.quickScan),
                              icon: const Icon(Icons.graphic_eq_rounded, size: 18),
                              label: const Text('Start Quick Scan'),
                              style: FilledButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 16),
                            OutlinedButton(
                              onPressed: () {
                                ref.read(alertFilterPriorityProvider.notifier).state = null;
                              },
                              child: const Text('Show All Alerts'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.only(top: 8, bottom: 24),
                    itemCount: grouped.keys.length,
                    itemBuilder: (context, groupIndex) {
                      final groupTitle = grouped.keys.elementAt(groupIndex);
                      final groupAlerts = grouped[groupTitle]!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
                            child: Text(
                              groupTitle.toUpperCase(),
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.0,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                          ),
                          ...groupAlerts.map((alert) {
                            final category = _getCategory(alert.soundCategory);
                            final borderColor =
                                _getPriorityColor(alert.priorityLevel, themeType);

                            return Dismissible(
                              key: Key(alert.id),
                              direction: DismissDirection.endToStart,
                              background: Container(
                                color: theme.colorScheme.error,
                                alignment: Alignment.centerRight,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 24),
                                child: const Row(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  children: [
                                    Icon(Icons.delete_outline_rounded,
                                        color: Colors.white),
                                    SizedBox(width: 8),
                                    Text('Delete',
                                        style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.bold)),
                                  ],
                                ),
                              ),
                              onDismissed: (_) {
                                ref
                                    .read(alertListProvider.notifier)
                                    .removeAlert(alert.id);
                                _showDeleteSnackBar(alert, category);
                              },
                              child: Card(
                                margin: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 5),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                  side: BorderSide(
                                    color: borderColor.withValues(alpha: 0.4),
                                    width: 1.0,
                                  ),
                                ),
                                child: InkWell(
                                  onTap: () {
                                    context.push(AppRoutes.alertDetails,
                                        extra: alert);
                                  },
                                  borderRadius: BorderRadius.circular(16),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(16),
                                      border: Border(
                                        left: BorderSide(
                                            color: borderColor, width: 5),
                                      ),
                                    ),
                                    child: ListTile(
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                              horizontal: 16, vertical: 6),
                                      leading: SoundIcon(
                                        iconName: alert.soundCategory,
                                        color:
                                            borderColor.withValues(alpha: 0.15),
                                      ),
                                      title: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              category?.label ??
                                                  alert.soundCategory,
                                              style: theme.textTheme.titleMedium
                                                  ?.copyWith(
                                                fontWeight: FontWeight.w700,
                                              ),
                                            ),
                                          ),
                                          PriorityBadge(
                                              priority: alert.priorityLevel
                                                  .toUpperCase()),
                                        ],
                                      ),
                                      subtitle: Padding(
                                        padding: const EdgeInsets.only(top: 4.0),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              '${(alert.confidence * 100).toStringAsFixed(0)}% • ${DateFormat.jm().format(alert.timestamp)} • ${alert.source}',
                                              style: theme.textTheme.bodySmall
                                                  ?.copyWith(
                                                color: theme.colorScheme
                                                    .onSurfaceVariant,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                            if (alert.acknowledged)
                                              Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 4.0),
                                                child: Row(
                                                  children: [
                                                    const Icon(
                                                        Icons.check_circle,
                                                        size: 13,
                                                        color: Colors.green),
                                                    const SizedBox(width: 4),
                                                    Text(
                                                      'Acknowledged (${alert.responseAction ?? "checked"})',
                                                      style: const TextStyle(
                                                          fontSize: 11,
                                                          color: Colors.green,
                                                          fontWeight:
                                                              FontWeight.w500),
                                                    ),
                                                  ],
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                      trailing: const Icon(
                                          Icons.chevron_right_rounded,
                                          size: 18),
                                    ),
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
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
      return SoundCategory.values
          .firstWhere((c) => c.name.toLowerCase() == name.toLowerCase());
    } catch (_) {
      return null;
    }
  }

  Color _getPriorityColor(String priority, ThemeType themeType) {
    final p = priority.toLowerCase();
    if (themeType == ThemeType.colorBlindSafe) {
      switch (p) {
        case 'high':
          return AppColors.cbSafeHigh; // #D81B60
        case 'medium':
          return AppColors.cbSafeMedium; // #F57C00
        case 'low':
        default:
          return AppColors.cbSafeLow; // #1E88E5
      }
    } else if (themeType == ThemeType.highContrast) {
      switch (p) {
        case 'high':
          return const Color(0xFF00FF41);
        case 'medium':
          return const Color(0xFFFFD600);
        case 'low':
        default:
          return const Color(0xFF00FFFF);
      }
    }

    switch (p) {
      case 'high':
        return const Color(0xFFEF4444);
      case 'medium':
        return const Color(0xFFF59E0B);
      case 'low':
      default:
        return const Color(0xFF10B981);
    }
  }

  void _showExportOptionsSheet(BuildContext context, List<AlertEvent> alerts) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: isDark ? Colors.white24 : Colors.black12,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Export Alert History',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Choose how you want to export your ${alerts.length} logged event(s):',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 16),

                // 1. PDF Report Card
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: const Color(0xFF0072FF).withValues(alpha: 0.3),
                    ),
                  ),
                  tileColor: const Color(0xFF0072FF).withValues(alpha: 0.08),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0072FF).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.picture_as_pdf_rounded, color: Color(0xFF0072FF)),
                  ),
                  title: const Text(
                    'Export Formatted PDF Report',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  subtitle: const Text(
                    'Audit-ready PDF with summary KPIs, tables, and timestamps for records or caregivers.',
                    style: TextStyle(fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _exportPdf(alerts);
                  },
                ),
                const SizedBox(height: 12),

                // 2. Text Summary Card
                ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(
                      color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                    ),
                  ),
                  leading: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(Icons.text_snippet_rounded, color: theme.colorScheme.primary),
                  ),
                  title: const Text(
                    'Share Text Summary',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  subtitle: const Text(
                    'Lightweight plain text summary for quick messaging or clipboard.',
                    style: TextStyle(fontSize: 12),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _shareTextSummary(alerts);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _exportPdf(List<AlertEvent> alerts) async {
    setState(() => _isExporting = true);
    try {
      await PdfExportService.exportAndSharePdf(alerts);
    } catch (e) {
      if (mounted) {
        _snackBarTimer?.cancel();
        try {
          _snackBarController?.close();
        } catch (_) {}
        final messenger = ScaffoldMessenger.of(context);
        messenger.clearSnackBars();
        final controller = messenger.showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            duration: const Duration(seconds: 4),
            behavior: SnackBarBehavior.floating,
            margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            backgroundColor: Colors.red.shade900,
          ),
        );
        _snackBarController = controller;
        _snackBarTimer = Timer(const Duration(milliseconds: 4000), () {
          try {
            controller.close();
          } catch (_) {}
        });
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _shareTextSummary(List<AlertEvent> alerts) async {
    final buffer = StringBuffer();
    buffer.writeln('=== AlertSense Event Log ===');
    buffer.writeln(
        'Generated: ${DateFormat.yMd().add_jm().format(DateTime.now())}');
    buffer.writeln('Total Events: ${alerts.length}\n');

    for (final a in alerts) {
      final cat = _getCategory(a.soundCategory)?.label ?? a.soundCategory;
      buffer.writeln(
          '[${DateFormat.yMd().add_jm().format(a.timestamp)}] ${a.priorityLevel.toUpperCase()}: $cat (${(a.confidence * 100).toStringAsFixed(0)}%) [Source: ${a.source}]');
    }

    await Share.share(buffer.toString(), subject: 'AlertSense Event Log');
  }

  void _confirmClear(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Alert History?'),
        content: const Text(
            'This will permanently delete all recorded alert events from local storage.'),
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
              _snackBarTimer?.cancel();
              try {
                _snackBarController?.close();
              } catch (_) {}
              final messenger = ScaffoldMessenger.of(context);
              messenger.clearSnackBars();
              final controller = messenger.showSnackBar(
                SnackBar(
                  content: const Text('Alert history cleared'),
                  duration: const Duration(seconds: 3),
                  behavior: SnackBarBehavior.floating,
                  margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              );
              _snackBarController = controller;
              _snackBarTimer = Timer(const Duration(milliseconds: 3000), () {
                try {
                  controller.close();
                } catch (_) {}
              });
            },
            child: const Text('Clear All'),
          ),
        ],
      ),
    );
  }
}
