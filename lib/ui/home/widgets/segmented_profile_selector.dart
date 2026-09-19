import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/alert_providers.dart';
import '../../../providers/audio_providers.dart';

class SegmentedProfileSelector extends ConsumerWidget {
  const SegmentedProfileSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProfile = ref.watch(activeProfileProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final profiles = [
      (
        id: 'home',
        title: 'Home',
        subtitle: 'All sounds active',
        icon: Icons.home_rounded,
      ),
      (
        id: 'sleep',
        title: 'Sleep',
        subtitle: 'Critical sounds only',
        icon: Icons.nightlight_round,
      ),
      (
        id: 'outdoor',
        title: 'Outdoor',
        subtitle: 'Siren + Horns',
        icon: Icons.park_rounded,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF161F33) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : const Color(0xFFE2E8F0),
          width: 1,
        ),
      ),
      child: Row(
        children: profiles.map((p) {
          final isSelected = activeProfile.toLowerCase() == p.id;

          return Expanded(
            child: GestureDetector(
              onTap: () {
                ref.read(activeProfileProvider.notifier).state = p.id;
                ref.read(enabledSoundsProvider.notifier).setProfile(p.id);
              },
              behavior: HitTestBehavior.opaque,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeInOut,
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (isDark ? const Color(0xFF1E2D52) : const Color(0xFFE8F1FD))
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: isSelected && !isDark
                      ? [
                          BoxShadow(
                            color: const Color(0xFF0055D4).withValues(alpha: 0.08),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          p.icon,
                          size: 18,
                          color: isSelected
                              ? const Color(0xFF0055D4)
                              : (isDark ? Colors.white70 : const Color(0xFF475569)),
                        ),
                        const SizedBox(width: 6),
                        Flexible(
                          child: Text(
                            p.title,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                              color: isSelected
                                  ? const Color(0xFF0055D4)
                                  : (isDark ? Colors.white : const Color(0xFF1E293B)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      p.subtitle,
                      textAlign: TextAlign.center,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 1,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? const Color(0xFF0055D4).withValues(alpha: 0.85)
                            : (isDark ? Colors.white54 : const Color(0xFF64748B)),
                      ),
                    ),
                    if (isSelected) ...[
                      const SizedBox(height: 4),
                      Container(
                        width: 24,
                        height: 2.5,
                        decoration: BoxDecoration(
                          color: const Color(0xFF0055D4),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
