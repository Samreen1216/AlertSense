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
    final isLightColor = color.computeLuminance() > 0.4;
    final resolvedIconColor = iconColor ??
        (isLightColor ? const Color(0xFF0F172A) : Colors.white);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: borderColor != null
            ? Border.all(color: borderColor!, width: 1.0)
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
