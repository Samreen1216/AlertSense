import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_assets.dart';
import '../../core/constants/app_colors.dart';
import '../../core/router/app_router.dart';
import '../../core/theme/theme_provider.dart';
import '../../providers/alert_providers.dart';
import '../../providers/audio_providers.dart';
import '../../providers/service_providers.dart';
import '../../providers/stats_providers.dart';

class WidgetThemeColors {
  final Color background;
  final Color cardBackground;
  final Color cardBorder;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  final Color primaryButtonBg;
  final Color primaryButtonText;
  final Color secondaryButtonBg;
  final Color secondaryButtonBorder;
  final Color secondaryButtonText;

  const WidgetThemeColors({
    required this.background,
    required this.cardBackground,
    required this.cardBorder,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
    required this.primaryButtonBg,
    required this.primaryButtonText,
    required this.secondaryButtonBg,
    required this.secondaryButtonBorder,
    required this.secondaryButtonText,
  });

  factory WidgetThemeColors.fromThemeType(ThemeType type) {
    switch (type) {
      case ThemeType.light:
        return const WidgetThemeColors(
          background: Color(0xFFF8FAFC),
          cardBackground: Color(0xFFFFFFFF),
          cardBorder: Color(0xFFE2E8F0),
          textPrimary: Color(0xFF0F172A),
          textSecondary: Color(0xFF64748B),
          accent: Color(0xFF0062FF),
          primaryButtonBg: Color(0xFF0062FF),
          primaryButtonText: Color(0xFFFFFFFF),
          secondaryButtonBg: Color(0xFFF1F5F9),
          secondaryButtonBorder: Color(0xFFCBD5E1),
          secondaryButtonText: Color(0xFF0F172A),
        );
      case ThemeType.highContrast:
        return const WidgetThemeColors(
          background: Color(0xFF000000),
          cardBackground: Color(0xFF000000),
          cardBorder: Color(0xFF38BDF8),
          textPrimary: Color(0xFFFFFFFF),
          textSecondary: Color(0xFFE2E8F0),
          accent: Color(0xFF38BDF8),
          primaryButtonBg: Color(0xFF38BDF8),
          primaryButtonText: Color(0xFF000000),
          secondaryButtonBg: Color(0xFF000000),
          secondaryButtonBorder: Color(0xFF38BDF8),
          secondaryButtonText: Color(0xFFFFFFFF),
        );
      case ThemeType.colorBlindSafe:
        return const WidgetThemeColors(
          background: Color(0xFFF8FAFC),
          cardBackground: Color(0xFFFFFFFF),
          cardBorder: Color(0xFFD0D7DE),
          textPrimary: Color(0xFF0F172A),
          textSecondary: Color(0xFF57606A),
          accent: Color(0xFF0077BB),
          primaryButtonBg: Color(0xFF0077BB),
          primaryButtonText: Color(0xFFFFFFFF),
          secondaryButtonBg: Color(0xFFF6F8FA),
          secondaryButtonBorder: Color(0xFFD0D7DE),
          secondaryButtonText: Color(0xFF0F172A),
        );
      case ThemeType.dark:
        return const WidgetThemeColors(
          background: Color(0xFF070F26),
          cardBackground: Color(0xFF0F172A),
          cardBorder: Color(0xFF1E293B),
          textPrimary: Color(0xFFFFFFFF),
          textSecondary: Color(0xFF94A3B8),
          accent: Color(0xFF00E5FF),
          primaryButtonBg: Color(0xFF1A73E8),
          primaryButtonText: Color(0xFFFFFFFF),
          secondaryButtonBg: Color(0xFF0F172A),
          secondaryButtonBorder: Color(0xFF334155),
          secondaryButtonText: Color(0xFFFFFFFF),
        );
    }
  }
}

class HomeWidgetShowcaseScreen extends ConsumerStatefulWidget {
  const HomeWidgetShowcaseScreen({super.key});

  @override
  ConsumerState<HomeWidgetShowcaseScreen> createState() => _HomeWidgetShowcaseScreenState();
}

class _HomeWidgetShowcaseScreenState extends ConsumerState<HomeWidgetShowcaseScreen> {
  int _currentSlide = 0;
  bool _isSyncing = false;

  void _nextSlide() {
    setState(() {
      _currentSlide = (_currentSlide + 1) % 3;
    });
  }

  void _prevSlide() {
    setState(() {
      _currentSlide = (_currentSlide - 1 + 3) % 3;
    });
  }

  Future<void> _syncWidgetData() async {
    setState(() => _isSyncing = true);
    final widgetService = ref.read(homeWidgetServiceProvider);
    final isListening = ref.read(isListeningProvider);
    final profile = ref.read(activeProfileProvider);
    final db = ref.read(ambientDbProvider);
    final lastAlert = ref.read(lastAlertProvider);
    final todayCount = ref.read(alertsTodayCountProvider);
    final highCount = ref.read(highPriorityCountProvider);
    final enabledCount = ref.read(enabledSoundsProvider).length;
    final themeType = ref.read(themeTypeProvider);

    await widgetService.syncData(
      isListening: isListening,
      activeProfile: profile,
      ambientDb: db,
      lastAlert: lastAlert,
      alertsTodayCount: todayCount,
      highPriorityCount: highCount,
      monitoredCount: enabledCount,
      themeType: themeType.name,
    );

    if (mounted) {
      setState(() => _isSyncing = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Home Widget updated with live app state!'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pinWidget() async {
    final widgetService = ref.read(homeWidgetServiceProvider);
    final success = await widgetService.pinWidgetToHomeScreen();
    if (mounted) {
      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📌 Widget pin request sent to launcher!'),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('ℹ️ To add: Long press your home screen, tap "Widgets", and select AlertSense.'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isListening = ref.watch(isListeningProvider);
    final profile = ref.watch(activeProfileProvider);
    final db = ref.watch(ambientDbProvider);
    final lastAlert = ref.watch(lastAlertProvider);
    final todayCount = ref.watch(alertsTodayCountProvider);
    final enabledCount = ref.watch(enabledSoundsProvider).length;
    final themeType = ref.watch(themeTypeProvider);
    final widgetColors = WidgetThemeColors.fromThemeType(themeType);

    return Scaffold(
      backgroundColor: const Color(0xFF070F26),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white, size: 20),
          onPressed: () => context.pop(),
        ),
        title: const Text(
          'Home Screen Widget',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          IconButton(
            tooltip: 'Sync Widget',
            icon: _isSyncing
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Color(0xFF00E5FF)),
                  )
                : const Icon(Icons.sync, color: Color(0xFF00E5FF)),
            onPressed: _isSyncing ? null : _syncWidgetData,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        physics: const BouncingScrollPhysics(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Section Header
            const Text(
              'LIVE WIDGET PREVIEW',
              style: TextStyle(
                color: Color(0xFF00E5FF),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 6),
            const Text(
              'Interactive 3-slider home widget. Switch slides below or interact with quick actions.',
              style: TextStyle(
                color: Color(0xFF94A3B8),
                fontSize: 13,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 16),

            // INTERACTIVE WIDGET SIMULATOR CONTAINER
            _buildInteractiveWidgetSimulator(
              isListening: isListening,
              profile: profile,
              db: db,
              lastAlert: lastAlert,
              todayCount: todayCount,
              enabledCount: enabledCount,
              theme: widgetColors,
            ),
            const SizedBox(height: 14),

            // Slide Navigation Tabs
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  _buildSlidePill(0, '1. Live Monitor', widgetColors),
                  const SizedBox(width: 8),
                  _buildSlidePill(1, '2. Alerts Feed', widgetColors),
                  const SizedBox(width: 8),
                  _buildSlidePill(2, '3. Emergency', widgetColors),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // ACTION BUTTONS
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
              ),
              onPressed: _pinWidget,
              icon: const Icon(Icons.add_to_home_screen_rounded, size: 20),
              label: const Text(
                'Pin Widget to Home Screen',
                style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 10),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFF00E5FF),
                side: const BorderSide(color: Color(0xFF1E293B), width: 1.5),
                padding: const EdgeInsets.symmetric(vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                backgroundColor: const Color(0xFF0F172A),
              ),
              onPressed: _syncWidgetData,
              icon: const Icon(Icons.sync_rounded, size: 18),
              label: const Text(
                'Force Sync Current App State',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 28),

            // HOW TO ADD TUTORIAL
            _buildHowToAddGuide(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildSlidePill(int index, String label, WidgetThemeColors theme) {
    final isSelected = _currentSlide == index;
    return GestureDetector(
      onTap: () => setState(() => _currentSlide = index),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isSelected ? theme.primaryButtonBg : theme.secondaryButtonBg,
          borderRadius: BorderRadius.circular(100),
          border: Border.all(
            color: isSelected ? theme.accent : theme.secondaryButtonBorder,
            width: 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? theme.primaryButtonText : theme.textSecondary,
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
          ),
        ),
      ),
    );
  }

  Widget _buildInteractiveWidgetSimulator({
    required bool isListening,
    required String profile,
    required double db,
    required dynamic lastAlert,
    required int todayCount,
    required int enabledCount,
    required WidgetThemeColors theme,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: theme.background,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: theme.cardBorder,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.accent.withValues(alpha: 0.12),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. WIDGET TOP HEADER
          Row(
            children: [
              // Brand & Live Pill
              Flexible(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: Image.asset(
                          AppAssets.appIcon,
                          width: 16,
                          height: 16,
                          fit: BoxFit.contain,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'AlertSense',
                        style: TextStyle(
                          color: theme.textPrimary,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2.5),
                        decoration: BoxDecoration(
                          color: isListening ? const Color(0xFF0D2818) : theme.secondaryButtonBg,
                          borderRadius: BorderRadius.circular(100),
                          border: Border.all(
                            color: isListening ? const Color(0xFF10B981) : theme.cardBorder,
                            width: 1,
                          ),
                        ),
                        child: Text(
                          isListening ? '● LIVE' : '○ PAUSED',
                          style: TextStyle(
                            color: isListening ? const Color(0xFF10B981) : theme.textSecondary,
                            fontSize: 9.5,
                            fontWeight: FontWeight.bold,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),

              // Right: Open App Action Button
              GestureDetector(
                onTap: () => context.go(AppRoutes.home),
                child: Container(
                  height: 28,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: theme.secondaryButtonBg,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: theme.secondaryButtonBorder),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    '⚡ Open App',
                    style: TextStyle(
                      color: theme.accent,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: theme.cardBorder, height: 1),
          ),

          // 2. SLIDE CONTENT
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 250),
            child: _buildCurrentSlide(
              isListening: isListening,
              profile: profile,
              db: db,
              lastAlert: lastAlert,
              todayCount: todayCount,
              enabledCount: enabledCount,
              theme: theme,
            ),
          ),

          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Divider(color: theme.cardBorder, height: 1),
          ),

          // 3. BOTTOM MIDDLE SLIDER CONTROLS ROW (< dots >)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Prev Slide Button (<)
              GestureDetector(
                onTap: _prevSlide,
                child: Container(
                  width: 54,
                  height: 38,
                  decoration: BoxDecoration(
                    color: theme.secondaryButtonBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.secondaryButtonBorder),
                  ),
                  alignment: Alignment.center,
                  child: Text('◀', style: TextStyle(color: theme.accent, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 14),
              // Slide indicator dots
              GestureDetector(
                onTap: _nextSlide,
                child: Container(
                  height: 38,
                  padding: const EdgeInsets.symmetric(horizontal: 18),
                  decoration: BoxDecoration(
                    color: theme.secondaryButtonBg,
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(color: theme.secondaryButtonBorder),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    _currentSlide == 0
                        ? '● ○ ○'
                        : _currentSlide == 1
                            ? '○ ● ○'
                            : '○ ○ ●',
                    style: TextStyle(
                      color: theme.accent,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 14),
              // Next Slide Button (>)
              GestureDetector(
                onTap: _nextSlide,
                child: Container(
                  width: 54,
                  height: 38,
                  decoration: BoxDecoration(
                    color: theme.secondaryButtonBg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: theme.secondaryButtonBorder),
                  ),
                  alignment: Alignment.center,
                  child: Text('▶', style: TextStyle(color: theme.accent, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentSlide({
    required bool isListening,
    required String profile,
    required double db,
    required dynamic lastAlert,
    required int todayCount,
    required int enabledCount,
    required WidgetThemeColors theme,
  }) {
    switch (_currentSlide) {
      case 0:
        return _buildSlide1(isListening, profile, db, enabledCount, theme);
      case 1:
        return _buildSlide2(lastAlert, todayCount, theme);
      case 2:
      default:
        return _buildSlide3(theme);
    }
  }

  // SLIDE 1: AWARENESS & LIVE RADAR
  Widget _buildSlide1(bool isListening, String profile, double db, int enabledCount, WidgetThemeColors theme) {
    return Column(
      key: const ValueKey(0),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Decibel & Profile Card
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: theme.cardBorder),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    '${db.toStringAsFixed(0)} dB',
                    style: TextStyle(
                      color: theme.accent,
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      db < 45 ? 'Quiet Environment' : (db < 65 ? 'Normal Ambient Noise' : 'Moderate Activity'),
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '🏠 ${_capitalize(profile)} Profile Active',
                    style: TextStyle(color: theme.textSecondary, fontSize: 11),
                  ),
                  Text(
                    '$enabledCount Sounds Monitored',
                    style: TextStyle(color: theme.textSecondary, fontSize: 11),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Quick Functionality Access Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryButtonBg,
                  foregroundColor: theme.primaryButtonText,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => context.push(AppRoutes.quickScan),
                icon: const Icon(Icons.flash_on_rounded, size: 15),
                label: const Text('Quick Scan', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.secondaryButtonText,
                  backgroundColor: theme.secondaryButtonBg,
                  side: BorderSide(color: theme.secondaryButtonBorder),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => ref.read(isListeningProvider.notifier).toggle(),
                icon: Icon(
                  isListening ? Icons.mic_off_rounded : Icons.mic_rounded,
                  size: 15,
                  color: isListening ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                ),
                label: Text(
                  isListening ? 'Pause Mic' : 'Start Mic',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // SLIDE 2: RECENT ALERTS & THREAT FEED
  Widget _buildSlide2(dynamic lastAlert, int todayCount, WidgetThemeColors theme) {
    final alertTitle = lastAlert != null ? lastAlert.soundCategory : 'No Recent Alerts';
    final alertPriority = lastAlert != null ? lastAlert.priorityLevel.toUpperCase() : 'LOW';
    final isHigh = alertPriority == 'HIGH';

    return Column(
      key: const ValueKey(1),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Alert Card
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isHigh ? const Color(0xFFEF4444).withValues(alpha: 0.4) : theme.cardBorder,
            ),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      '🚨 $alertTitle',
                      style: TextStyle(
                        color: theme.textPrimary,
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: isHigh ? const Color(0xFF450A0A) : const Color(0xFF064E3B),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: isHigh ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                      ),
                    ),
                    child: Text(
                      alertPriority,
                      style: TextStyle(
                        color: isHigh ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        fontSize: 9.5,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '94% Confidence • Recently Active',
                    style: TextStyle(color: theme.textSecondary, fontSize: 11),
                  ),
                  Text(
                    '$todayCount Alerts Today',
                    style: TextStyle(
                      color: theme.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // Quick Functionality Access Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: theme.primaryButtonBg,
                  foregroundColor: theme.primaryButtonText,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => context.push(AppRoutes.history),
                icon: const Icon(Icons.history_rounded, size: 15),
                label: const Text('Full History', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.secondaryButtonText,
                  backgroundColor: theme.secondaryButtonBg,
                  side: BorderSide(color: theme.secondaryButtonBorder),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => context.push(AppRoutes.stats),
                icon: Icon(Icons.bar_chart_rounded, size: 15, color: theme.accent),
                label: const Text('Sound Insights', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // SLIDE 3: RAPID EMERGENCY & SAFETY ACTIONS
  Widget _buildSlide3(WidgetThemeColors theme) {
    return Column(
      key: const ValueKey(2),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Emergency Card
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: theme.cardBackground,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '🚨 Life-Safety Quick Response',
                style: TextStyle(
                  color: theme.textPrimary,
                  fontSize: 13.5,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                'Instant SOS alert dispatch & Bedside sleep mode ready',
                style: TextStyle(color: theme.textSecondary, fontSize: 11),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // 3 Action Buttons
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFEF4444),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => context.push(AppRoutes.emergencyContacts),
                icon: const Icon(Icons.sos_rounded, size: 14),
                label: const Text('SOS Contacts', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.secondaryButtonText,
                  backgroundColor: theme.secondaryButtonBg,
                  side: BorderSide(color: theme.secondaryButtonBorder),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => context.push(AppRoutes.sleepMode),
                icon: Icon(Icons.bedtime_rounded, size: 14, color: theme.accent),
                label: const Text('Sleep Mode', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 6),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: theme.secondaryButtonText,
                  backgroundColor: theme.secondaryButtonBg,
                  side: BorderSide(color: theme.secondaryButtonBorder),
                  padding: const EdgeInsets.symmetric(vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: () => context.push(AppRoutes.settings),
                icon: const Icon(Icons.settings_rounded, size: 14),
                label: const Text('Settings', style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildHowToAddGuide() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E293B)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.help_outline_rounded, color: Color(0xFF00E5FF), size: 18),
              SizedBox(width: 8),
              Text(
                'HOW TO ADD TO ANDROID HOME SCREEN',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildStep(1, 'Go to your device Home Screen.'),
          _buildStep(2, 'Touch and hold an empty space until the home menu appears.'),
          _buildStep(3, 'Tap "Widgets" and find "AlertSense".'),
          _buildStep(4, 'Select "AlertSense Radar (4x2)" and drag it onto your screen.'),
          _buildStep(5, 'Use the ◀ and ▶ buttons on the widget to slide through all 3 views anytime!'),
        ],
      ),
    );
  }

  Widget _buildStep(int number, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: const Color(0xFF1E293B),
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF00E5FF), width: 1),
            ),
            alignment: Alignment.center,
            child: Text(
              '$number',
              style: const TextStyle(
                color: Color(0xFF00E5FF),
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                color: Color(0xFFCBD5E1),
                fontSize: 13,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _capitalize(String s) {
    if (s.isEmpty) return s;
    return s[0].toUpperCase() + s.substring(1);
  }
}
