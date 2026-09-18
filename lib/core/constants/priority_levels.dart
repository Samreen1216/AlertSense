import 'package:flutter/material.dart';
import 'app_colors.dart';

enum PriorityLevel {
  high(
    label: 'High',
    color: AppColors.highRed,
    backgroundColor: Color(0xFFFFEBEE),
    defaultVibrationPattern: [0, 500, 200, 500, 200, 500],
    requiresAcknowledgment: true,
    autoDismiss: Duration.zero,
    enableFlash: true,
    flashFrequencyHz: 5,
  ),
  medium(
    label: 'Medium',
    color: AppColors.mediumOrange,
    backgroundColor: Color(0xFFFFF3E0),
    defaultVibrationPattern: [0, 300, 100, 300],
    requiresAcknowledgment: false,
    autoDismiss: Duration(seconds: 15),
    enableFlash: true,
    flashFrequencyHz: 2,
  ),
  low(
    label: 'Low',
    color: AppColors.lowGreen,
    backgroundColor: Color(0xFFE8F5E9),
    defaultVibrationPattern: [0, 200],
    requiresAcknowledgment: false,
    autoDismiss: Duration(seconds: 5),
    enableFlash: false,
    flashFrequencyHz: 0,
  );

  final String label;
  final Color color;
  final Color backgroundColor;
  final List<int> defaultVibrationPattern;
  final bool requiresAcknowledgment;
  final Duration autoDismiss;
  final bool enableFlash;
  final int flashFrequencyHz;

  const PriorityLevel({
    required this.label,
    required this.color,
    required this.backgroundColor,
    required this.defaultVibrationPattern,
    required this.requiresAcknowledgment,
    required this.autoDismiss,
    required this.enableFlash,
    required this.flashFrequencyHz,
  });
}
