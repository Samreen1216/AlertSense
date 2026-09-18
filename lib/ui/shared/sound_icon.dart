import 'package:flutter/material.dart';

class SoundIcon extends StatelessWidget {
  final String emoji;
  final Color color;

  const SoundIcon({super.key, required this.emoji, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 40,
      height: 40,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Text(
        emoji,
        style: const TextStyle(fontSize: 20),
      ),
    );
  }
}
