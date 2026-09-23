import 'dart:math';
import 'package:flutter/foundation.dart';

/// Configuration for audio signal energy gating.
class SignalValidationConfig {
  /// Minimum Root-Mean-Square (RMS) amplitude required to consider an audio window active.
  /// Rejects mic noise floor and near-silent ambient frames.
  final double minRms;

  /// Minimum estimated decibel sound level (dB SPL) required.
  final double minDbLevel;

  const SignalValidationConfig({
    this.minRms = 0.008,
    this.minDbLevel = 42.0,
  });
}

/// Outcome of evaluating signal energy in an audio frame.
class SignalValidationResult {
  final bool isSufficient;
  final double rms;
  final double dbLevel;
  final String? rejectionReason;

  const SignalValidationResult({
    required this.isSufficient,
    required this.rms,
    required this.dbLevel,
    this.rejectionReason,
  });
}

/// Evaluates incoming audio buffers to ensure sufficient acoustic energy is present
/// before passing to neural network classification.
class SignalEnergyValidator {
  final SignalValidationConfig config;

  const SignalEnergyValidator({this.config = const SignalValidationConfig()});

  /// Check whether an audio buffer contains sufficient acoustic energy.
  SignalValidationResult validate(List<double> audioData) {
    if (audioData.isEmpty) {
      return const SignalValidationResult(
        isSufficient: false,
        rms: 0.0,
        dbLevel: 0.0,
        rejectionReason: 'Empty audio buffer',
      );
    }

    final rms = calculateRms(audioData);
    final db = rmsToDb(rms);

    if (rms < config.minRms || db < config.minDbLevel) {
      final reason = 'RMS ${rms.toStringAsFixed(4)} < ${config.minRms.toStringAsFixed(4)} '
          '(${db.toStringAsFixed(1)} dB < ${config.minDbLevel.toStringAsFixed(1)} dB) → ambient noise floor';
      debugPrint('[Signal] Energy: REJECT ($reason)');
      return SignalValidationResult(
        isSufficient: false,
        rms: rms,
        dbLevel: db,
        rejectionReason: reason,
      );
    }

    debugPrint('[Signal] Energy: PASS (RMS: ${rms.toStringAsFixed(4)}, dB: ${db.toStringAsFixed(1)})');
    return SignalValidationResult(
      isSufficient: true,
      rms: rms,
      dbLevel: db,
    );
  }

  static double calculateRms(List<double> samples) {
    if (samples.isEmpty) return 0.0;
    double sum = 0.0;
    for (final s in samples) {
      sum += s * s;
    }
    return sqrt(sum / samples.length);
  }

  static double rmsToDb(double rms) {
    if (rms <= 0) return 0.0;
    return (20 * log(rms) / ln10 + 90).clamp(0.0, 120.0);
  }
}
