import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/app_svg_icons.dart';
import '../../../providers/alert_providers.dart';
import 'profile_side_navigation.dart';

class HeroProfileCard extends ConsumerWidget {
  const HeroProfileCard({super.key});

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

  void _openProfileSideNav(BuildContext context) {
    final scaffold = Scaffold.maybeOf(context);
    if (scaffold != null && scaffold.hasEndDrawer) {
      scaffold.openEndDrawer();
    } else {
      showGeneralDialog(
        context: context,
        barrierDismissible: true,
        barrierLabel: 'Dismiss',
        barrierColor: Colors.black54,
        transitionDuration: const Duration(milliseconds: 250),
        transitionBuilder: (ctx, anim, secAnim, child) {
          return SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(1, 0),
              end: Offset.zero,
            ).animate(CurvedAnimation(
              parent: anim,
              curve: Curves.easeOutCubic,
            )),
            child: child,
          );
        },
        pageBuilder: (ctx, a1, a2) => const Align(
          alignment: Alignment.centerRight,
          child: SizedBox(
            width: 320,
            child: ProfileSideNavigation(),
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeProfile = ref.watch(activeProfileProvider);
    final title = _getProfileTitle(activeProfile);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _openProfileSideNav(context),
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
                child: Center(
                  child: AppSvgIcon(
                    iconKey: activeProfile,
                    size: 20,
                    color: const Color(0xFF00C6FF),
                  ),
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
