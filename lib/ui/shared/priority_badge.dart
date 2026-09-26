import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_colors.dart';
import '../../core/theme/theme_provider.dart';

class PriorityBadge extends ConsumerWidget {
  final String priority;

  const PriorityBadge({super.key, required this.priority});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeType = ref.watch(themeTypeProvider);
    final normPriority = priority.toUpperCase();

    Color primaryColor;
    Color textColor = Colors.white;
    bool isHighContrast = themeType == ThemeType.highContrast;

    if (themeType == ThemeType.colorBlindSafe) {
      switch (normPriority) {
        case 'HIGH':
          primaryColor = AppColors.cbSafeHigh; // Pink (#D81B60)
          break;
        case 'MEDIUM':
          primaryColor = AppColors.cbSafeMedium; // Orange (#F57C00)
          break;
        case 'LOW':
          primaryColor = AppColors.cbSafeLow; // Blue (#1E88E5)
          break;
        default:
          primaryColor = const Color(0xFF64748B);
      }
    } else if (isHighContrast) {
      switch (normPriority) {
        case 'HIGH':
          primaryColor = const Color(0xFF00FF41); // Matrix Green
          textColor = Colors.black;
          break;
        case 'MEDIUM':
          primaryColor = const Color(0xFFFFD600); // Neon Yellow
          textColor = Colors.black;
          break;
        case 'LOW':
          primaryColor = const Color(0xFF00FFFF); // Cyan
          textColor = Colors.black;
          break;
        default:
          primaryColor = Colors.white;
          textColor = Colors.black;
      }
    } else {
      switch (normPriority) {
        case 'HIGH':
          primaryColor = const Color(0xFFEF4444);
          break;
        case 'MEDIUM':
          primaryColor = const Color(0xFFF59E0B);
          break;
        case 'LOW':
          primaryColor = const Color(0xFF10B981);
          break;
        default:
          primaryColor = const Color(0xFF64748B);
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3.5),
      decoration: BoxDecoration(
        color: isHighContrast
            ? primaryColor
            : primaryColor.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isHighContrast ? Colors.white : primaryColor.withValues(alpha: 0.45),
          width: isHighContrast ? 1.5 : 1.0,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (!isHighContrast) ...[
            Container(
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 5),
          ],
          Text(
            normPriority,
            style: TextStyle(
              color: isHighContrast ? textColor : primaryColor,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
