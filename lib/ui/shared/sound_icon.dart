import 'package:flutter/material.dart';
import '../../core/constants/app_svg_icons.dart';

class SoundIcon extends StatelessWidget {
  final String? emoji;
  final String? iconName;
  final Color color;
  final double size;
  final double iconSize;

  const SoundIcon({
    super.key,
    this.emoji,
    this.iconName,
    required this.color,
    this.size = 40,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    final key = iconName ?? emoji ?? 'alert';
    final isLightColor = color.computeLuminance() > 0.4;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: AppSvgIcon(
        iconKey: key,
        size: iconSize,
        color: isLightColor ? const Color(0xFF0F172A) : Colors.white,
      ),
    );
  }
}
