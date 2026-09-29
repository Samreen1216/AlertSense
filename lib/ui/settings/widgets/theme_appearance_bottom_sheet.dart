import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_provider.dart';

/// Data model representing a theme option in the appearance bottom sheet.
class ThemeOptionData {
  final ThemeType type;
  final String title;
  final String subtitle;
  final String tag;
  final Color tagColor;
  final IconData icon;
  final List<({Color color, String label})> swatches;

  const ThemeOptionData({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.tag,
    required this.tagColor,
    required this.icon,
    required this.swatches,
  });
}

/// A modern, accessible, and reactive bottom sheet for choosing appearance and color themes.
class ThemeAppearanceBottomSheet extends ConsumerWidget {
  const ThemeAppearanceBottomSheet({super.key});

  /// Convenience static method to show this bottom sheet.
  static Future<void> show(BuildContext context) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ThemeAppearanceBottomSheet(),
    );
  }

  static const List<ThemeOptionData> themeOptions = [
    ThemeOptionData(
      type: ThemeType.light,
      title: 'Standard Light',
      subtitle: 'Crisp slate canvas with electric sapphire accents. Optimal for daytime legibility.',
      tag: 'Daylight',
      tagColor: Color(0xFF0062FF),
      icon: Icons.light_mode_rounded,
      swatches: [
        (color: Color(0xFFF8FAFC), label: 'Canvas'),
        (color: Color(0xFF0062FF), label: 'Primary'),
        (color: Color(0xFFEF4444), label: 'Alert'),
        (color: Color(0xFF10B981), label: 'Safe'),
      ],
    ),
    ThemeOptionData(
      type: ThemeType.dark,
      title: 'Cyber Dark',
      subtitle: 'Midnight obsidian canvas with luminous cyan accents. Reduces glare and saves OLED battery.',
      tag: 'OLED Saver',
      tagColor: Color(0xFF38BDF8),
      icon: Icons.dark_mode_rounded,
      swatches: [
        (color: Color(0xFF070F26), label: 'Obsidian'),
        (color: Color(0xFF38BDF8), label: 'Cyan'),
        (color: Color(0xFF818CF8), label: 'Neural'),
        (color: Color(0xFF10B981), label: 'Safe'),
      ],
    ),
    ThemeOptionData(
      type: ThemeType.highContrast,
      title: 'High Contrast (AMOLED)',
      subtitle: 'Pure #000000 canvas with matrix neon green. Certified WCAG AAA 7:1+ for low vision.',
      tag: 'WCAG AAA',
      tagColor: Color(0xFF00FF41),
      icon: Icons.contrast_rounded,
      swatches: [
        (color: Colors.black, label: 'Pure Black'),
        (color: Color(0xFF00FF41), label: 'Matrix Green'),
        (color: Color(0xFFFFD600), label: 'Yellow'),
        (color: Color(0xFF00FFFF), label: 'Acoustic'),
      ],
    ),
    ThemeOptionData(
      type: ThemeType.colorBlindSafe,
      title: 'Color-Blind Accessible (IBM)',
      subtitle: 'Scientifically tuned IBM research palette ensuring maximum distinction for deuteranopia & protanopia.',
      tag: 'IBM Certified',
      tagColor: Color(0xFFD81B60),
      icon: Icons.remove_red_eye_rounded,
      swatches: [
        (color: Colors.white, label: 'Surface'),
        (color: Color(0xFF0077BB), label: 'Cobalt Blue'),
        (color: Color(0xFFD81B60), label: 'Pink Urgent'),
        (color: Color(0xFFEE7733), label: 'Amber'),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeTypeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isHighContrast = currentTheme == ThemeType.highContrast;

    // Sheet background styling dynamically reflects the active theme
    final sheetBg = isHighContrast
        ? Colors.black
        : isDark
            ? const Color(0xFF0F172A)
            : Colors.white;

    final sheetBorder = isHighContrast
        ? Border.all(color: const Color(0xFF00FF41), width: 2)
        : Border.all(color: isDark ? Colors.white12 : const Color(0xFFE2E8F0), width: 1);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.90,
      ),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
        border: sheetBorder,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.6 : 0.15),
            blurRadius: 24,
            spreadRadius: 4,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Top Drag Handle ──
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: isHighContrast
                      ? const Color(0xFF00FF41)
                      : isDark
                          ? Colors.white24
                          : Colors.black12,
                  borderRadius: BorderRadius.circular(2.5),
                ),
              ),
            ),

            // ── Scrollable Body ──
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Bar
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(alpha: isHighContrast ? 0.2 : 0.12),
                            borderRadius: BorderRadius.circular(12),
                            border: isHighContrast
                                ? Border.all(color: const Color(0xFF00FF41), width: 1.5)
                                : null,
                          ),
                          child: Icon(
                            Icons.palette_rounded,
                            color: theme.colorScheme.primary,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Appearance & Color Theme',
                                style: theme.textTheme.titleLarge?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: -0.3,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Personalize contrast & acoustic visualization for your eyesight',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close_rounded),
                          tooltip: 'Close',
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    // ── Live UI Preview Card ──
                    _buildLiveAlertPreview(context, currentTheme, isDark, isHighContrast),

                    const SizedBox(height: 22),

                    // ── Section Title ──
                    Row(
                      children: [
                        Icon(
                          Icons.tune_rounded,
                          size: 16,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'AVAILABLE THEMES',
                          style: theme.textTheme.labelMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.primary,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // ── Theme Option Cards ──
                    ...themeOptions.map((opt) {
                      final isSelected = currentTheme == opt.type;
                      return _buildThemeCard(
                        context: context,
                        ref: ref,
                        option: opt,
                        isSelected: isSelected,
                        isDark: isDark,
                        isHighContrast: isHighContrast,
                      );
                    }),

                    const SizedBox(height: 16),

                    // ── Bottom Done Button ──
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                            side: isHighContrast
                                ? const BorderSide(color: Color(0xFF00FF41), width: 2)
                                : BorderSide.none,
                          ),
                          backgroundColor: isHighContrast
                              ? Colors.black
                              : theme.colorScheme.primary,
                          foregroundColor: isHighContrast
                              ? const Color(0xFF00FF41)
                              : theme.colorScheme.onPrimary,
                        ),
                        icon: const Icon(Icons.check_rounded, size: 20),
                        label: const Text(
                          'Done',
                          style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Live UI Simulation Card showing an alert card in the current theme.
  Widget _buildLiveAlertPreview(
    BuildContext context,
    ThemeType currentTheme,
    bool isDark,
    bool isHighContrast,
  ) {
    Color cardBg;
    Border border;
    Color titleColor;
    Color subtitleColor;
    Color badgeBg;
    Color badgeText;
    Color primaryAccent;
    Color waveformColor;

    switch (currentTheme) {
      case ThemeType.light:
        cardBg = Colors.white;
        border = Border.all(color: const Color(0xFFE2E8F0), width: 1.2);
        titleColor = const Color(0xFF0F172A);
        subtitleColor = const Color(0xFF64748B);
        badgeBg = const Color(0xFFEF4444).withValues(alpha: 0.12);
        badgeText = const Color(0xFFEF4444);
        primaryAccent = const Color(0xFF0062FF);
        waveformColor = const Color(0xFF0062FF);
        break;
      case ThemeType.dark:
        cardBg = const Color(0xFF111C35);
        border = Border.all(color: const Color(0xFF1E2D4E), width: 1.2);
        titleColor = Colors.white;
        subtitleColor = const Color(0xFF94A3B8);
        badgeBg = const Color(0xFFEF4444).withValues(alpha: 0.2);
        badgeText = const Color(0xFFF87171);
        primaryAccent = const Color(0xFF38BDF8);
        waveformColor = const Color(0xFF38BDF8);
        break;
      case ThemeType.highContrast:
        cardBg = Colors.black;
        border = Border.all(color: const Color(0xFF00FF41), width: 2.0);
        titleColor = Colors.white;
        subtitleColor = const Color(0xFFFFD600);
        badgeBg = Colors.black;
        badgeText = const Color(0xFFFFD600);
        primaryAccent = const Color(0xFF00FF41);
        waveformColor = const Color(0xFF00FF41);
        break;
      case ThemeType.colorBlindSafe:
        cardBg = Colors.white;
        border = Border.all(color: const Color(0xFFD0D7DE), width: 1.2);
        titleColor = const Color(0xFF0A192F);
        subtitleColor = const Color(0xFF57606A);
        badgeBg = const Color(0xFFD81B60).withValues(alpha: 0.15);
        badgeText = const Color(0xFFD81B60);
        primaryAccent = const Color(0xFF0077BB);
        waveformColor = const Color(0xFF0077BB);
        break;
    }

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(18),
        border: border,
        boxShadow: [
          if (!isHighContrast)
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.35 : 0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top live badge & priority label
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: primaryAccent,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'LIVE ALERT PREVIEW',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: primaryAccent,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: badgeBg,
                  borderRadius: BorderRadius.circular(6),
                  border: isHighContrast
                      ? Border.all(color: badgeText, width: 1.5)
                      : null,
                ),
                child: Text(
                  'CRITICAL ALARM',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: badgeText,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Alert content row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: primaryAccent.withValues(alpha: isHighContrast ? 0.2 : 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: isHighContrast
                      ? Border.all(color: primaryAccent, width: 1.5)
                      : null,
                ),
                child: Icon(
                  Icons.local_fire_department_rounded,
                  color: primaryAccent,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Smoke & Fire Alarm',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: titleColor,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Living Room • 98% AI Confidence',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: subtitleColor,
                      ),
                    ),
                  ],
                ),
              ),
              // Mini Acoustic Waveform bars
              Row(
                children: [8, 18, 26, 14, 20].map((height) {
                  return Container(
                    width: 3.5,
                    height: height.toDouble(),
                    margin: const EdgeInsets.symmetric(horizontal: 1.5),
                    decoration: BoxDecoration(
                      color: waveformColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Builds a single rich interactive card for a theme option.
  Widget _buildThemeCard({
    required BuildContext context,
    required WidgetRef ref,
    required ThemeOptionData option,
    required bool isSelected,
    required bool isDark,
    required bool isHighContrast,
  }) {
    // Dynamic borders & card backgrounds
    final Color cardBackground;
    final Border border;

    if (isHighContrast) {
      cardBackground = Colors.black;
      border = Border.all(
        color: isSelected ? const Color(0xFF00FF41) : Colors.white24,
        width: isSelected ? 2.5 : 1.2,
      );
    } else {
      if (isSelected) {
        cardBackground = isDark
            ? option.tagColor.withValues(alpha: 0.12)
            : option.tagColor.withValues(alpha: 0.06);
        border = Border.all(
          color: option.tagColor,
          width: 2.0,
        );
      } else {
        cardBackground = isDark
            ? const Color(0xFF131F38)
            : const Color(0xFFF8FAFC);
        border = Border.all(
          color: isDark ? Colors.white10 : const Color(0xFFE2E8F0),
          width: 1.0,
        );
      }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(18),
          onTap: () {
            HapticFeedback.selectionClick();
            ref.read(themeTypeProvider.notifier).setTheme(option.type);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: cardBackground,
              borderRadius: BorderRadius.circular(18),
              border: border,
              boxShadow: [
                if (isSelected && !isHighContrast)
                  BoxShadow(
                    color: option.tagColor.withValues(alpha: 0.18),
                    blurRadius: 14,
                    offset: const Offset(0, 4),
                  ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Icon, Title, Badge & Radio/Check
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: option.tagColor.withValues(alpha: isHighContrast ? 0.2 : 0.15),
                        borderRadius: BorderRadius.circular(12),
                        border: isHighContrast
                            ? Border.all(color: option.tagColor, width: 1.5)
                            : null,
                      ),
                      child: Icon(
                        option.icon,
                        color: option.tagColor,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  option.title,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: isHighContrast
                                        ? (isSelected ? const Color(0xFF00FF41) : Colors.white)
                                        : null,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: option.tagColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(6),
                                  border: Border.all(
                                    color: option.tagColor.withValues(alpha: 0.4),
                                    width: 0.8,
                                  ),
                                ),
                                child: Text(
                                  option.tag,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: option.tagColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            option.subtitle,
                            style: TextStyle(
                              fontSize: 12,
                              color: isHighContrast
                                  ? (isSelected ? Colors.white : Colors.white70)
                                  : (isDark ? Colors.white60 : const Color(0xFF64748B)),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Selection indicator
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: isSelected
                          ? Container(
                              key: const ValueKey('selected'),
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                color: option.tagColor,
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                Icons.check_rounded,
                                color: option.type == ThemeType.highContrast
                                    ? Colors.black
                                    : Colors.white,
                                size: 17,
                              ),
                            )
                          : Container(
                              key: const ValueKey('unselected'),
                              width: 26,
                              height: 26,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isHighContrast
                                      ? Colors.white38
                                      : (isDark ? Colors.white24 : const Color(0xFFCBD5E1)),
                                  width: 1.5,
                                ),
                              ),
                            ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Bottom Row: Swatches & Current Theme Tag
                Row(
                  children: [
                    ...option.swatches.map((swatch) {
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: Tooltip(
                          message: swatch.label,
                          child: Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: swatch.color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? Colors.white24 : Colors.black12,
                                width: 1.2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }),
                    const Spacer(),
                    if (isSelected)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: option.tagColor.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: option.tagColor.withValues(alpha: 0.5),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: option.tagColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 5),
                            Text(
                              'APPLIED',
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 0.5,
                                color: option.tagColor,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
