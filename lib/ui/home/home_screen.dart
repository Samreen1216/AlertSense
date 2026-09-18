import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/sound_categories.dart';
import '../../core/router/app_router.dart';
import '../../providers/audio_providers.dart';
import 'widgets/sound_radar_widget.dart';
import 'widgets/listening_indicator.dart';
import 'widgets/db_meter_widget.dart';
import 'widgets/sound_toggle_grid.dart';
import 'widgets/profile_selector.dart';
import 'widgets/last_alert_card.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isListening = ref.watch(isListeningProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
                ),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.hearing, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 10),
            Text('AlertSense',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => context.push(AppRoutes.sleepMode),
            icon: const Icon(Icons.bedtime_outlined),
            tooltip: 'Sleep Mode',
            style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
          ),
          IconButton(
            onPressed: () => context.push(AppRoutes.settings),
            icon: const Icon(Icons.settings_outlined),
            tooltip: 'Settings',
            style: IconButton.styleFrom(minimumSize: const Size(48, 48)),
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Sound Radar
              const SoundRadarWidget(),
              const SizedBox(height: 20),

              // Listening Status + dB Meter
              const ListeningIndicator(),
              const SizedBox(height: 12),
              const DbMeterWidget(),
              const SizedBox(height: 24),

              // Profile Selector
              Text('Active Profile',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const ProfileSelector(),
              const SizedBox(height: 24),

              // Sound Categories Toggle
              Text('Sound Categories',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              const SoundToggleGrid(),
              const SizedBox(height: 24),

              // ── Sound Test Panel ─────────────────────────────────────────
              _SoundTestPanel(),
              const SizedBox(height: 24),

              // Last Alert Card
              const LastAlertCard(),
              const SizedBox(height: 100), // Space for FAB
            ],
          ),
        ),
      ),

      // Big Listening Toggle FAB
      floatingActionButton: SizedBox(
        width: 72,
        height: 72,
        child: FloatingActionButton.large(
          onPressed: () => ref.read(isListeningProvider.notifier).toggle(),
          backgroundColor: isListening ? theme.colorScheme.error : theme.colorScheme.primary,
          foregroundColor: Colors.white,
          tooltip: isListening ? 'Stop Listening' : 'Start Listening',
          elevation: 6,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: Icon(
              isListening ? Icons.stop_rounded : Icons.mic_rounded,
              key: ValueKey(isListening),
              size: 36,
            ),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
    );
  }
}

/// Quick-tap demo panel: sends a synthetic alert for any sound category.
class _SoundTestPanel extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Card(
      elevation: 0,
      color: theme.colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.science_outlined, color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Sound Test',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '— tap to simulate an alert',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: SoundCategory.values.map((cat) {
                return ActionChip(
                  avatar: Text(cat.emoji, style: const TextStyle(fontSize: 16)),
                  label: Text(cat.label, style: const TextStyle(fontSize: 12)),
                  onPressed: () {
                    ref.read(isListeningProvider.notifier).fireTestAlert(cat);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${cat.emoji} Testing ${cat.label}…'),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  backgroundColor: cat.color.withOpacity(0.15),
                  side: BorderSide(color: cat.color.withOpacity(0.4)),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}
