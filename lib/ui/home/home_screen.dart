import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/sound_categories.dart';
import '../../providers/audio_providers.dart';
import 'widgets/alertsense_header.dart';
import 'widgets/hero_sound_radar.dart';
import 'widgets/hero_listening_card.dart';
import 'widgets/hero_profile_card.dart';
import 'widgets/hero_battery_card.dart';
import 'widgets/segmented_profile_selector.dart';
import 'widgets/sound_category_cards.dart';
import 'widgets/reference_last_alert_card.dart';
import 'widgets/quick_stats_grid.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: const Color(0xFF070F26),
      body: SafeArea(
        bottom: false,
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. TOP HEADER
              const AlertSenseHeader(),
              const SizedBox(height: 4),

              // 2. HERO SECTION: 2-Column Responsive Hero (Radar + 3 Cards)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final isNarrow = constraints.maxWidth < 340;

                    if (isNarrow) {
                      return const Column(
                        children: [
                          SizedBox(
                            height: 200,
                            child: HeroSoundRadar(),
                          ),
                          SizedBox(height: 12),
                          HeroListeningCard(),
                          SizedBox(height: 8),
                          HeroProfileCard(),
                          SizedBox(height: 8),
                          HeroBatteryCard(),
                        ],
                      );
                    }

                    return const Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        // Left: Live Sound Radar
                        Expanded(
                          flex: 11,
                          child: SizedBox(
                            height: 205,
                            child: HeroSoundRadar(),
                          ),
                        ),
                        SizedBox(width: 10),

                        // Right: 3 Stacked Status Cards
                        Expanded(
                          flex: 11,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              HeroListeningCard(),
                              SizedBox(height: 6),
                              HeroProfileCard(),
                              SizedBox(height: 6),
                              HeroBatteryCard(),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              const SizedBox(height: 14),

              // 3. WHITE / LIGHT CONTENT CONTAINER (Radius 28)
              Container(
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                      blurRadius: 16,
                      offset: const Offset(0, -4),
                    ),
                  ],
                ),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 36),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    // Segmented Profile Selector (Home / Sleep / Outdoor)
                    SegmentedProfileSelector(),
                    SizedBox(height: 22),

                    // Sound Categories Section (Horizontal cards with toggles)
                    SoundCategoryCardsSection(),
                    SizedBox(height: 22),

                    // Last Alert Card
                    ReferenceLastAlertCard(),
                    SizedBox(height: 22),

                    // Quick Stats (2x2 Grid)
                    QuickStatsGrid(),
                    SizedBox(height: 24),

                    // Modern Sound Simulation / Hardware Demo
                    _ModernSoundTestPanel(),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Sound Test & Simulator Panel for Instant Accessibility Demos
class _ModernSoundTestPanel extends ConsumerWidget {
  const _ModernSoundTestPanel();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1E2638).withValues(alpha: 0.6)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : const Color(0xFF64748B).withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.science_rounded,
                  color: Color(0xFF8B5CF6),
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Sound Simulator & Hardware Demo',
                      style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      'Tap any sound to test live vibration, flash & radar response',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? Colors.white60 : const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: SoundCategory.values.map((cat) {
              return Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    ref.read(isListeningProvider.notifier).fireTestAlert(cat);
                    ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Row(
                          children: [
                            Text(cat.emoji, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 8),
                            Text('Simulating: ${cat.label} (Flash & Vibration)'),
                          ],
                        ),
                        duration: const Duration(seconds: 2),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  },
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: cat.color.withValues(alpha: isDark ? 0.2 : 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: cat.color.withValues(alpha: 0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(cat.emoji, style: const TextStyle(fontSize: 14)),
                        const SizedBox(width: 6),
                        Text(
                          cat.label,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: isDark ? Colors.white : const Color(0xFF1E293B),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
