import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/theme_provider.dart';

/// Clean model representing a theme choice in the appearance sheet.
class _ThemeItem {
  final ThemeType type;
  final String title;
  final String subtitle;
  final IconData icon;
  final List<Color> swatches;

  const _ThemeItem({
    required this.type,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.swatches,
  });
}

/// A simple, decent, and elegant bottom sheet for switching appearance themes.
class ThemeAppearanceBottomSheet extends ConsumerWidget {
  const ThemeAppearanceBottomSheet({super.key});

  /// Convenience method to display the theme bottom sheet.
  static Future<void> show(BuildContext context) {
    HapticFeedback.lightImpact();
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => const ThemeAppearanceBottomSheet(),
    );
  }

  static const List<_ThemeItem> _themes = [
    _ThemeItem(
      type: ThemeType.light,
      title: 'Standard Light',
      subtitle: 'Clean light canvas with electric sapphire accents',
      icon: Icons.light_mode_rounded,
      swatches: [
        Color(0xFFF8FAFC),
        Color(0xFF0062FF),
        Color(0xFFEF4444),
        Color(0xFF10B981),
      ],
    ),
    _ThemeItem(
      type: ThemeType.dark,
      title: 'Cyber Dark',
      subtitle: 'Midnight obsidian canvas with luminous cyan accents',
      icon: Icons.dark_mode_rounded,
      swatches: [
        Color(0xFF070F26),
        Color(0xFF38BDF8),
        Color(0xFF0062FF),
        Color(0xFF10B981),
      ],
    ),
    _ThemeItem(
      type: ThemeType.highContrast,
      title: 'High Contrast (AMOLED)',
      subtitle: 'Pure black canvas with matrix neon green (WCAG AAA)',
      icon: Icons.contrast_rounded,
      swatches: [
        Colors.black,
        Color(0xFF00FF41),
        Color(0xFFFFD600),
        Color(0xFF00FFFF),
      ],
    ),
    _ThemeItem(
      type: ThemeType.colorBlindSafe,
      title: 'Color-Blind Accessible (IBM)',
      subtitle: 'High-distinction IBM palette for universal clarity',
      icon: Icons.palette_rounded,
      swatches: [
        Colors.white,
        Color(0xFF0077BB),
        Color(0xFFD81B60),
        Color(0xFFEE7733),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentTheme = ref.watch(themeTypeProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isHighContrast = currentTheme == ThemeType.highContrast;

    final sheetBg = isHighContrast
        ? Colors.black
        : (isDark ? const Color(0xFF0F172A) : Colors.white);

    final sheetBorder = isHighContrast
        ? Border.all(color: const Color(0xFF00FF41), width: 1.5)
        : Border.all(
            color: isDark ? Colors.white12 : const Color(0xFFE2E8F0),
            width: 1,
          );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: sheetBg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        border: sheetBorder,
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drag handle pill
            Center(
              child: Container(
                margin: const EdgeInsets.only(top: 12, bottom: 8),
                width: 36,
                height: 4,
                decoration: BoxDecoration(
                  color: isHighContrast
                      ? const Color(0xFF00FF41)
                      : (isDark ? Colors.white24 : Colors.black12),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),

            // Sheet content
            Flexible(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Appearance & Color Theme',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 18,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Select a theme that works best for your eyesight',
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
                          visualDensity: VisualDensity.compact,
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

                    // Theme options list
                    ..._themes.map((item) {
                      final isSelected = currentTheme == item.type;
                      return _buildThemeTile(
                        context: context,
                        ref: ref,
                        item: item,
                        isSelected: isSelected,
                        isDark: isDark,
                        isHighContrast: isHighContrast,
                      );
                    }),

                    const SizedBox(height: 14),

                    // Done button
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton(
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                            side: isHighContrast
                                ? const BorderSide(color: Color(0xFF00FF41), width: 1.5)
                                : BorderSide.none,
                          ),
                          backgroundColor: isHighContrast
                              ? Colors.black
                              : theme.colorScheme.primary,
                          foregroundColor: isHighContrast
                              ? const Color(0xFF00FF41)
                              : theme.colorScheme.onPrimary,
                        ),
                        onPressed: () {
                          HapticFeedback.lightImpact();
                          Navigator.pop(context);
                        },
                        child: const Text(
                          'Done',
                          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
                        ),
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

  Widget _buildThemeTile({
    required BuildContext context,
    required WidgetRef ref,
    required _ThemeItem item,
    required bool isSelected,
    required bool isDark,
    required bool isHighContrast,
  }) {
    final theme = Theme.of(context);
    final primary = theme.colorScheme.primary;

    final Color tileBg;
    final Border tileBorder;

    if (isHighContrast) {
      tileBg = Colors.black;
      tileBorder = Border.all(
        color: isSelected ? const Color(0xFF00FF41) : Colors.white24,
        width: isSelected ? 2.0 : 1.0,
      );
    } else {
      tileBg = isSelected
          ? primary.withValues(alpha: isDark ? 0.14 : 0.07)
          : (isDark
              ? const Color(0xFF131F38)
              : const Color(0xFFF8FAFC));
      tileBorder = Border.all(
        color: isSelected
            ? primary
            : (isDark ? Colors.white10 : const Color(0xFFE2E8F0)),
        width: isSelected ? 1.6 : 1.0,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            HapticFeedback.selectionClick();
            ref.read(themeTypeProvider.notifier).setTheme(item.type);
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 180),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: tileBg,
              borderRadius: BorderRadius.circular(14),
              border: tileBorder,
            ),
            child: Row(
              children: [
                // Clean leading icon
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: isHighContrast
                        ? Colors.black
                        : (isSelected
                            ? primary.withValues(alpha: isDark ? 0.25 : 0.15)
                            : (isDark
                                ? Colors.white.withValues(alpha: 0.08)
                                : Colors.black.withValues(alpha: 0.05))),
                    borderRadius: BorderRadius.circular(10),
                    border: isHighContrast
                        ? Border.all(
                            color: isSelected ? const Color(0xFF00FF41) : Colors.white30,
                            width: 1.2,
                          )
                        : null,
                  ),
                  child: Icon(
                    item.icon,
                    size: 20,
                    color: isHighContrast
                        ? (isSelected ? const Color(0xFF00FF41) : Colors.white70)
                        : (isSelected ? primary : theme.colorScheme.onSurfaceVariant),
                  ),
                ),
                const SizedBox(width: 12),

                // Title & Subtitle + Swatches
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: isHighContrast
                              ? (isSelected ? const Color(0xFF00FF41) : Colors.white)
                              : (isSelected ? primary : null),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: TextStyle(
                          fontSize: 11.5,
                          color: isHighContrast
                              ? Colors.white70
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // 4 mini swatches
                      Row(
                        children: item.swatches.map((color) {
                          return Container(
                            width: 13,
                            height: 13,
                            margin: const EdgeInsets.only(right: 5),
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark ? Colors.white24 : Colors.black12,
                                width: 0.8,
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // Clean radio checkmark
                Icon(
                  isSelected
                      ? Icons.check_circle_rounded
                      : Icons.radio_button_unchecked_rounded,
                  size: 22,
                  color: isHighContrast
                      ? (isSelected ? const Color(0xFF00FF41) : Colors.white30)
                      : (isSelected
                          ? primary
                          : (isDark ? Colors.white24 : const Color(0xFFCBD5E1))),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
