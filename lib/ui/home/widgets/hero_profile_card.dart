import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/app_router.dart';
import '../../../providers/alert_providers.dart';

class HeroProfileCard extends ConsumerWidget {
  const HeroProfileCard({super.key});

  IconData _getProfileIcon(String profile) {
    switch (profile.toLowerCase()) {
      case 'sleep':
        return Icons.nightlight_round;
      case 'outdoor':
        return Icons.park_rounded;
      default:
        return Icons.home_rounded;
    }
  }

  String _getProfileTitle(String profile) {
    switch (profile.toLowerCase()) {
      case 'sleep':
        return 'Sleep';
      case 'outdoor':
        return 'Outdoor';
      default:
        return 'Home';
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProfile = ref.watch(activeProfileProvider);
    final icon = _getProfileIcon(activeProfile);
    final title = _getProfileTitle(activeProfile);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push(AppRoutes.profileEditor),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1A3A).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Profile Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: const Color(0xFF0072FF).withValues(alpha: 0.25),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: const Color(0xFF0072FF).withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF00C6FF),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Title & Name
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Current Profile',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),

              // Chevron
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withValues(alpha: 0.4),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
