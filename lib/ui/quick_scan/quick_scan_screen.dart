import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:permission_handler/permission_handler.dart';
import '../../core/constants/app_svg_icons.dart';
import '../../core/constants/sound_categories.dart';
import '../../core/router/app_router.dart';
import '../../providers/quick_scan_provider.dart';

class QuickScanScreen extends ConsumerStatefulWidget {
  const QuickScanScreen({super.key});

  @override
  ConsumerState<QuickScanScreen> createState() => _QuickScanScreenState();
}

class _QuickScanScreenState extends ConsumerState<QuickScanScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _waveController;

  @override
  void initState() {
    super.initState();
    _waveController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _waveController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(quickScanProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Scan'),
        elevation: 0,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 300),
            child: switch (scanState.status) {
              QuickScanStatus.idle => _buildIdleState(context, ref),
              QuickScanStatus.scanning =>
                _buildScanningState(context, scanState),
              QuickScanStatus.result =>
                _buildResultState(context, ref, scanState),
              QuickScanStatus.noResult =>
                _buildNoResultState(context, ref),
              QuickScanStatus.error =>
                _buildErrorState(context, ref, scanState),
              QuickScanStatus.permissionDenied =>
                _buildPermissionDeniedState(context, ref),
            },
          ),
        ),
      ),
    );
  }

  // ── 1. IDLE STATE ──────────────────────────────────────────────────────────
  Widget _buildIdleState(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFF0055D4), Color(0xFF00E5FF)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF0055D4).withValues(alpha: 0.35),
                  blurRadius: 24,
                  spreadRadius: 4,
                ),
              ],
            ),
            child: const Icon(Icons.graphic_eq_rounded,
                size: 60, color: Colors.white),
          ),
          const SizedBox(height: 32),
          Text(
            'Quick Environmental Scan',
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 12),
          Text(
            'Check your surroundings for critical safety sounds (alarms, sirens, glass breaking, crying). AlertSense will analyze audio for 4 seconds.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 48),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                ref.read(quickScanProvider.notifier).startScan();
              },
              icon: const Icon(Icons.mic_rounded, size: 26),
              label: const Text(
                'Start Quick Scan',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── 2. SCANNING STATE ──────────────────────────────────────────────────────
  Widget _buildScanningState(BuildContext context, QuickScanState state) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Animated pulsating radar ring
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              final wave = _waveController.value;
              return Container(
                width: 140 + (wave * 20),
                height: 140 + (wave * 20),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFF00E5FF).withValues(alpha: 0.12),
                  border: Border.all(
                    color: const Color(0xFF00E5FF).withValues(alpha: 0.4),
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Container(
                    width: 110,
                    height: 110,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [Color(0xFF0055D4), Color(0xFF00E5FF)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: Center(
                      child: Text(
                        '${state.remainingSeconds}s',
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 36),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Color(0xFF10B981),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Listening & Analyzing...',
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Ambient volume: ${state.currentDb.toStringAsFixed(1)} dB',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: const Color(0xFF00E5FF),
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 24),
          // Live equalizer visualizer
          AnimatedBuilder(
            animation: _waveController,
            builder: (context, child) {
              return Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(16, (i) {
                  final h = 12.0 +
                      (sin((i * 0.5) + (_waveController.value * 4)).abs() *
                          36.0);
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 2.5),
                    width: 5,
                    height: h,
                    decoration: BoxDecoration(
                      color: const Color(0xFF00E5FF),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  );
                }),
              );
            },
          ),
        ],
      ),
    );
  }

  // ── 3. RESULT STATE ────────────────────────────────────────────────────────
  Widget _buildResultState(
      BuildContext context, WidgetRef ref, QuickScanState state) {
    final theme = Theme.of(context);
    final alert = state.createdAlert!;
    final result = state.bestResult!;

    SoundCategory? category;
    try {
      category = SoundCategory.values
          .firstWhere((c) => c.name == result.soundCategory);
    } catch (_) {}

    final label = category?.label ?? result.soundCategory;
    final priority = alert.priorityLevel.toUpperCase();
    final isHigh = priority == 'HIGH';
    final priorityColor = isHigh
        ? const Color(0xFFEF4444)
        : (priority == 'MEDIUM' ? const Color(0xFFF59E0B) : const Color(0xFF10B981));

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          AppSvgIcon(
            iconKey: category?.name ?? 'alert',
            size: 84,
            color: priorityColor,
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: priorityColor, width: 1.0),
            ),
            child: Text(
              '$priority PRIORITY DETECTED',
              style: TextStyle(
                color: priorityColor,
                fontWeight: FontWeight.w900,
                fontSize: 12,
                letterSpacing: 1.2,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(result.confidence * 100).toStringAsFixed(0)}% Confidence • Detected Just Now',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: priorityColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                context.push(AppRoutes.alertDetails, extra: alert);
              },
              icon: const Icon(Icons.info_outline_rounded),
              label: const Text('View Alert Details',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                ref.read(quickScanProvider.notifier).startScan();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Scan Again'),
            ),
          ),
        ],
      ),
    );
  }

  // ── 4. NO RESULT STATE ─────────────────────────────────────────────────────
  Widget _buildNoResultState(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_circle_outline_rounded,
              size: 72,
              color: Color(0xFF10B981),
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'No Critical Sound Detected',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'The environment appears quiet and clear of recognizable alarm sounds.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 36),
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton.icon(
              style: FilledButton.styleFrom(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              onPressed: () {
                ref.read(quickScanProvider.notifier).startScan();
              },
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Scan Again',
                  style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
    );
  }

  // ── 5. ERROR STATE ─────────────────────────────────────────────────────────
  Widget _buildErrorState(
      BuildContext context, WidgetRef ref, QuickScanState state) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline_rounded, size: 64, color: Colors.red),
          const SizedBox(height: 20),
          Text(
            'Unable to Analyze Sound',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            state.errorMessage ?? 'An error occurred while accessing the audio hardware.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () {
              ref.read(quickScanProvider.notifier).startScan();
            },
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Try Again'),
          ),
        ],
      ),
    );
  }

  // ── 6. PERMISSION DENIED STATE ─────────────────────────────────────────────
  Widget _buildPermissionDeniedState(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.mic_off_rounded, size: 64, color: Colors.orange),
          const SizedBox(height: 20),
          Text(
            'Microphone Permission Required',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'AlertSense needs microphone access to sample your environment and detect critical sounds.',
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
          const SizedBox(height: 32),
          FilledButton.icon(
            onPressed: () async {
              await openAppSettings();
            },
            icon: const Icon(Icons.settings_rounded),
            label: const Text('Open App Settings'),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: () {
              ref.read(quickScanProvider.notifier).startScan();
            },
            child: const Text('I Granted Permission, Retry'),
          ),
        ],
      ),
    );
  }
}
