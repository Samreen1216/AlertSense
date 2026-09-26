import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/constants/app_svg_icons.dart';
import '../../providers/alert_providers.dart';
import '../../providers/stats_providers.dart';

class StatsScreen extends ConsumerWidget {
  const StatsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref.watch(alertListProvider);
    final timeRange = ref.watch(statsTimeRangeProvider);
    final topSound = ref.watch(topSoundProvider);
    final categoryFreq = ref.watch(categoryFrequencyProvider);
    final hourlyDist = ref.watch(hourlyDistributionProvider);
    final dailyTrend = ref.watch(dailyTrendProvider);
    final alertsToday = ref.watch(alertsTodayCountProvider);
    final alertsWeek = ref.watch(alertsWeekCountProvider);
    final highPriority = ref.watch(highPriorityCountProvider);

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final canPop = ModalRoute.of(context)?.canPop ?? false;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Insights & Analytics'),
        automaticallyImplyLeading: false,
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                tooltip: 'Back',
                onPressed: () => Navigator.of(context).pop(),
              )
            : null,
      ),
      body: alerts.isEmpty
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
                        Icons.bar_chart_rounded,
                        size: 64,
                        color: theme.colorScheme.primary.withValues(alpha: 0.7),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      'Not enough data yet',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'AlertSense will analyze your sound patterns and generate frequency trends once alerts are recorded.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── KPI Summary Cards ──
                  Row(
                    children: [
                      Expanded(
                        child: _KpiCard(
                          title: 'Alerts Today',
                          value: '$alertsToday',
                          icon: Icons.today_rounded,
                          color: const Color(0xFF0055D4),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _KpiCard(
                          title: 'This Week',
                          value: '$alertsWeek',
                          icon: Icons.date_range_rounded,
                          color: const Color(0xFF00897B),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _KpiCard(
                          title: 'High Priority',
                          value: '$highPriority',
                          icon: Icons.warning_amber_rounded,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // ── Most Detected Sound Card ──
                  if (topSound != null)
                    Card(
                      elevation: 0,
                      color: isDark
                          ? const Color(0xFF1E2638)
                          : theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.4),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.3),
                          width: 1.0,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20.0),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.12),
                                shape: BoxShape.circle,
                              ),
                              child: AppSvgIcon(
                                iconKey: (topSound['category'] as String?) ?? 'alert',
                                size: 36,
                                color: theme.colorScheme.primary,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'MOST DETECTED SOUND',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.8,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    topSound['name'] as String,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  Text(
                                    '${topSound['count']} incident(s) recorded',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  const SizedBox(height: 20),

                  // ── Category Distribution ──
                  if (categoryFreq.isNotEmpty) ...[
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Alerts by Category',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SegmentedButton<String>(
                          segments: const [
                            ButtonSegment(
                                value: 'week',
                                label: Text('7D',
                                    style: TextStyle(fontSize: 11))),
                            ButtonSegment(
                                value: 'month',
                                label: Text('30D',
                                    style: TextStyle(fontSize: 11))),
                          ],
                          selected: {timeRange},
                          onSelectionChanged: (s) {
                            ref
                                .read(statsTimeRangeProvider.notifier)
                                .state = s.first;
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Card(
                      elevation: 0,
                      color: isDark
                          ? const Color(0xFF1E2638)
                          : theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.35),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: BorderSide(
                          color: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.3),
                          width: 1.0,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(18.0),
                        child: SizedBox(
                          height: 180,
                          child: BarChart(
                            BarChartData(
                              alignment: BarChartAlignment.spaceAround,
                              barTouchData: BarTouchData(enabled: false),
                              titlesData: FlTitlesData(
                                show: true,
                                bottomTitles: AxisTitles(
                                  sideTitles: SideTitles(
                                    showTitles: true,
                                    getTitlesWidget: (value, meta) {
                                      final keys = categoryFreq.keys.toList();
                                      if (value.toInt() < keys.length) {
                                        return Text(
                                          keys[value.toInt()],
                                          style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold),
                                        );
                                      }
                                      return const Text('');
                                    },
                                  ),
                                ),
                                leftTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                topTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                                rightTitles: const AxisTitles(
                                    sideTitles: SideTitles(showTitles: false)),
                              ),
                              borderData: FlBorderData(show: false),
                              gridData: const FlGridData(show: false),
                              barGroups: categoryFreq.entries.map((e) {
                                final index = categoryFreq.keys
                                    .toList()
                                    .indexOf(e.key);
                                return BarChartGroupData(
                                  x: index,
                                  barRods: [
                                    BarChartRodData(
                                      toY: e.value.toDouble(),
                                      color: theme.colorScheme.primary,
                                      width: 18,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                  ],
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // ── Peak Alert Times ──
                  Text(
                    'Peak Alert Times',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    color: isDark
                        ? const Color(0xFF1E2638)
                        : theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.3),
                        width: 1.0,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(18.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: hourlyDist.entries.map((e) {
                          return Column(
                            children: [
                              Text(
                                '${e.value}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  color: e.value > 0
                                      ? const Color(0xFFF59E0B)
                                      : Colors.grey,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                e.key,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),

                  // ── 7-Day Trend ──
                  Text(
                    '7-Day Activity Trend',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    elevation: 0,
                    color: isDark
                        ? const Color(0xFF1E2638)
                        : theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                      side: BorderSide(
                        color: theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.3),
                        width: 1.0,
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 24, 20, 16),
                      child: SizedBox(
                        height: 160,
                        child: LineChart(
                          LineChartData(
                            gridData: const FlGridData(show: false),
                            titlesData: FlTitlesData(
                              show: true,
                              bottomTitles: AxisTitles(
                                sideTitles: SideTitles(
                                  showTitles: true,
                                  getTitlesWidget: (value, meta) {
                                    final i = value.toInt();
                                    if (i >= 0 && i < dailyTrend.length) {
                                      return Text(dailyTrend[i].key,
                                          style: const TextStyle(
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold));
                                    }
                                    return const Text('');
                                  },
                                ),
                              ),
                              leftTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              topTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                              rightTitles: const AxisTitles(
                                  sideTitles: SideTitles(showTitles: false)),
                            ),
                            borderData: FlBorderData(show: false),
                            lineBarsData: [
                              LineChartBarData(
                                spots: dailyTrend.asMap().entries.map((e) {
                                  return FlSpot(e.key.toDouble(),
                                      e.value.value.toDouble());
                                }).toList(),
                                isCurved: true,
                                color: const Color(0xFF10B981),
                                barWidth: 3,
                                isStrokeCapRound: true,
                                dotData: const FlDotData(show: true),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 10),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E2638)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}
