import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_provider.dart';
import '../../core/utils/responsive_utils.dart';
import 'widgets/alertsense_header.dart';
import 'widgets/hero_sound_radar.dart';
import 'widgets/hero_listening_card.dart';
import 'widgets/hero_profile_card.dart';
import 'widgets/hero_battery_card.dart';
import 'widgets/segmented_profile_selector.dart';
import 'widgets/sound_category_cards.dart';
import 'widgets/recent_alerts_section.dart';
import 'widgets/profile_side_navigation.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final themeType = ref.watch(themeTypeProvider);
    final isHighContrast = themeType == ThemeType.highContrast;
    final isDark = theme.brightness == Brightness.dark;

    final scaffoldBg = isHighContrast ? Colors.black : AppColors.darkBackground;

    final bodyContent = SingleChildScrollView(
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

              // 3. WHITE / LIGHT / HIGH CONTRAST CONTENT CONTAINER (Radius 28)
              Container(
                decoration: BoxDecoration(
                  color: isHighContrast
                      ? Colors.black
                      : (isDark ? AppColors.darkSurface : AppColors.backgroundLight),
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                  border: isHighContrast
                      ? const Border(
                          top: BorderSide(color: AppColors.hcPrimary, width: 2.0),
                          left: BorderSide(color: AppColors.hcPrimary, width: 1.0),
                          right: BorderSide(color: AppColors.hcPrimary, width: 1.0),
                        )
                      : null,
                  boxShadow: isHighContrast
                      ? null
                      : [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: isDark ? 0.4 : 0.08),
                            blurRadius: 16,
                            offset: const Offset(0, -4),
                          ),
                        ],
                ),
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 36),
                child: const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Segmented Profile Selector (Home / Sleep / Outdoor)
                    SegmentedProfileSelector(),
                    SizedBox(height: 22),

                    // Sound Categories Section (Horizontal cards with toggles)
                    SoundCategoryCardsSection(),
                    SizedBox(height: 22),

                    // Recent Alerts Section (Dynamic alerts from original data)
                    RecentAlertsSection(),
                  ],
                ),
              ),
            ],
          ),
        );

    return Scaffold(
      backgroundColor: scaffoldBg,
      endDrawer: const ProfileSideNavigation(),
      body: SafeArea(
        bottom: false,
        child: context.isTablet
            ? Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: ResponsiveBreakpoints.maxDesktopWidth,
                  ),
                  child: bodyContent,
                ),
              )
            : bodyContent,
      ),
    );
  }
}
