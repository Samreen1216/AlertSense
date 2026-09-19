import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/alert_providers.dart';
import '../../../providers/audio_providers.dart';

class ProfileSelector extends ConsumerWidget {
  const ProfileSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProfile = ref.watch(activeProfileProvider);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final profiles = [
      {
        'id': 'home',
        'label': 'Home',
        'sub': '9 Sounds',
        'icon': Icons.home_rounded,
      },
      {
        'id': 'sleep',
        'label': 'Sleep',
        'sub': 'Life Safety',
        'icon': Icons.nightlight_round,
      },
      {
        'id': 'outdoor',
        'label': 'Outdoor',
        'sub': 'Traffic & Siren',
        'icon': Icons.park_rounded,
      },
    ];

    return Row(
      children: profiles.map((p) {
        final id = p['id'] as String;
        final label = p['label'] as String;
        final sub = p['sub'] as String;
        final icon = p['icon'] as IconData;
        final isSelected = activeProfile == id;

        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: InkWell(
              onTap: () {
                ref.read(activeProfileProvider.notifier).state = id;
                ref.read(enabledSoundsProvider.notifier).setProfile(id);
              },
              borderRadius: BorderRadius.circular(16),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 250),
                curve: Curves.easeOutCubic,
                padding:
                    const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? theme.colorScheme.primary
                      : (isDark
                          ? const Color(0xFF1E2638)
                          : theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.5)),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isSelected
                        ? theme.colorScheme.primary
                        : theme.colorScheme.outlineVariant
                            .withValues(alpha: 0.4),
                    width: isSelected ? 2 : 1,
                  ),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: theme.colorScheme.primary
                                .withValues(alpha: 0.3),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ]
                      : null,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      icon,
                      color: isSelected
                          ? Colors.white
                          : (isDark ? Colors.white70 : Colors.black87),
                      size: 22,
                    ),
                    const SizedBox(height: 6),
                    Text(
                      label,
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                        color: isSelected
                            ? Colors.white
                            : (isDark ? Colors.white : Colors.black87),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      sub,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                        color: isSelected
                            ? Colors.white.withValues(alpha: 0.85)
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
