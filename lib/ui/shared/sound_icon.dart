import 'package:flutter/material.dart';
import '../../core/constants/app_svg_icons.dart';

class SoundIcon extends StatelessWidget {
  final String? emoji;
  final String? iconName;
  final Color color;
  final Color? iconColor;
  final Color? borderColor;
  final double size;
  final double iconSize;

  const SoundIcon({
    super.key,
    this.emoji,
    this.iconName,
    required this.color,
    this.iconColor,
    this.borderColor,
    this.size = 40,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final key = iconName ?? emoji ?? 'alert';
    // If explicit iconColor is provided, use it.
    // If container color is translucent (alpha < 0.85), use full opaque color for rich vibrancy and contrast.
    // Otherwise calculate luminance: dark container -> white icon, light container -> dark icon.
    final resolvedIconColor = iconColor ??
        (color.a < 0.85
            ? color.withValues(alpha: 1.0)
            : (color.computeLuminance() > 0.4 ? const Color(0xFF0F172A) : Colors.white));

    final resolvedBorderColor = borderColor ??
        (color.a < 0.85 ? color.withValues(alpha: 0.35) : null);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: resolvedBorderColor != null
            ? Border.all(color: resolvedBorderColor, width: 1.0)
            : null,
      ),
      alignment: Alignment.center,
      child: AppSvgIcon(
        iconKey: key,
        size: iconSize,
        color: resolvedIconColor,
      ),
    );
  }
}
