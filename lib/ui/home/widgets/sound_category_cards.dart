import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/constants/sound_categories.dart';
import '../../../core/router/app_router.dart';
import '../../../providers/audio_providers.dart';

class SoundCategoryCardsSection extends ConsumerWidget {
  const SoundCategoryCardsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final enabledSounds = ref.watch(enabledSoundsProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final categories = SoundCategory.values;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Section Header Row
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Sound Categories',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              InkWell(
                onTap: () => context.push(AppRoutes.soundManagement),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF0055D4),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        Icons.tune_rounded,
                        size: 16,
                        color: const Color(0xFF0055D4),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Horizontal Scrollable Cards
        SizedBox(
          height: 146,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: categories.length,
            separatorBuilder: (context, index) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final cat = categories[index];
              final isEnabled = enabledSounds.contains(cat.name);

              return _VerticalSoundCard(
                category: cat,
                isEnabled: isEnabled,
                isDark: isDark,
                onToggle: () {
                  ref.read(enabledSoundsProvider.notifier).toggle(cat.name);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _VerticalSoundCard extends StatelessWidget {
  final SoundCategory category;
  final bool isEnabled;
  final bool isDark;
  final VoidCallback onToggle;

  const _VerticalSoundCard({
    required this.category,
    required this.isEnabled,
    required this.isDark,
    required this.onToggle,
  });

  Color _getCardBg(SoundCategory cat, bool dark) {
    if (dark) {
      return const Color(0xFF1E2638);
    }
    switch (cat) {
      case SoundCategory.fireAlarm:
      case SoundCategory.smokeAlarm:
        return const Color(0xFFFFF0F0);
      case SoundCategory.doorbell:
        return const Color(0xFFFFFDF0);
      case SoundCategory.babyCrying:
        return const Color(0xFFF8F0FF);
      case SoundCategory.vehicleHorn:
        return const Color(0xFFF0FFF4);
      case SoundCategory.knocking:
        return const Color(0xFFFFF5ED);
      case SoundCategory.dogBarking:
        return const Color(0xFFF0FDFA);
      case SoundCategory.emergencySiren:
        return const Color(0xFFF0F4FF);
      case SoundCategory.glassBreaking:
        return const Color(0xFFF0F9FF);
    }
  }

  String _formatLabel(SoundCategory cat) {
    if (cat == SoundCategory.fireAlarm) return 'Fire / Smoke';
    return cat.label;
  }

  @override
  Widget build(BuildContext context) {
    final bgColor = _getCardBg(category, isDark);

    return Container(
      width: 98,
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : category.color.withValues(alpha: 0.2),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withValues(alpha: 0.2)
                : category.color.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Icon Avatar
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: category.color.withValues(alpha: 0.15),
              border: Border.all(
                color: category.color.withValues(alpha: 0.3),
                width: 1,
              ),
            ),
            child: Center(
              child: Text(
                category.emoji,
                style: const TextStyle(fontSize: 20),
              ),
            ),
          ),

          // Label
          Text(
            _formatLabel(category),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF1E293B),
              height: 1.15,
            ),
          ),

          // Switch
          GestureDetector(
            onTap: onToggle,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 38,
              height: 22,
              padding: const EdgeInsets.all(2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: isEnabled
                    ? const Color(0xFF0055D4)
                    : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1)),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 200),
                alignment: isEnabled ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 18,
                  height: 18,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
