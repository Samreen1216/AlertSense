import 'dart:math';
import 'package:flutter/foundation.dart';
import '../core/constants/sound_categories.dart';

/// Aggregation strategy for computing confidence across multiple confirmed windows.
enum ConfidenceAggregationMethod {
  /// Simple arithmetic mean of matching predictions.
  average,

  /// Recency-weighted average placing greater weight on latest audio windows.
  weightedAverage,

  /// Maximum confidence observed within the confirmation window.
  maximum,
}

/// Configuration model for temporal prediction buffering and confirmation.
class TemporalSmoothingConfig {
  /// Number of recent predictions maintained in the rolling buffer.
  final int historyWindow;

  /// Number of matching category predictions required within the window to confirm detection.
  final int minimumConfirmations;

  /// Duration after which a buffered prediction is considered stale and evicted.
  final Duration predictionExpiry;

  /// Calculation strategy for aggregated confidence score.
  final ConfidenceAggregationMethod aggregationMethod;

  const TemporalSmoothingConfig({
    this.historyWindow = 3,
    this.minimumConfirmations = 2,
    this.predictionExpiry = const Duration(seconds: 3),
    this.aggregationMethod = ConfidenceAggregationMethod.weightedAverage,
  })  : assert(historyWindow >= 1, 'historyWindow must be at least 1'),
        assert(minimumConfirmations >= 1, 'minimumConfirmations must be at least 1'),
        assert(minimumConfirmations <= historyWindow, 'minimumConfirmations cannot exceed historyWindow');
}

/// Represents a single time-stamped prediction candidate.
class TemporalPrediction {
  final SoundCategory category;
  final double confidence;
  final DateTime timestamp;
  final Map<String, dynamic>? metadata;

  const TemporalPrediction({
    required this.category,
    required this.confidence,
    required this.timestamp,
    this.metadata,
  });
}

/// Result emitted when a sound category achieves multi-window confirmation.
class ConfirmedSoundDetection {
  final SoundCategory category;
  final double aggregatedConfidence;
  final int confirmationCount;
  final int windowSize;
  final DateTime timestamp;
  final List<TemporalPrediction> contributingPredictions;

  const ConfirmedSoundDetection({
    required this.category,
    required this.aggregatedConfidence,
    required this.confirmationCount,
    required this.windowSize,
    required this.timestamp,
    required this.contributingPredictions,
  });
}

/// Temporal prediction buffer service that confirms sounds across multiple time windows.
///
/// Prevents isolated, transient false-positive spikes from triggering alerts by
/// requiring multiple detections within a rolling time window before confirming.
class TemporalSmoothingService {
  final TemporalSmoothingConfig config;
  final List<TemporalPrediction> _predictionBuffer = [];

  TemporalSmoothingService({TemporalSmoothingConfig? config})
      : config = config ?? const TemporalSmoothingConfig();

  /// Feed a new prediction into the temporal smoother.
  ///
  /// Returns a [ConfirmedSoundDetection] if the category achieves the required
  /// confirmation count within the rolling window, or `null` if not yet confirmed.
  ConfirmedSoundDetection? processPrediction({
    required SoundCategory category,
    required double confidence,
    DateTime? timestamp,
  }) {
    final now = timestamp ?? DateTime.now();

    // 1. Purge stale predictions exceeding expiration window
    _purgeExpired(now);

    // 2. Add current candidate prediction
    final prediction = TemporalPrediction(
      category: category,
      confidence: confidence.clamp(0.0, 1.0),
      timestamp: now,
    );
    _predictionBuffer.add(prediction);

    // 3. Keep buffer strictly within rolling history window limit
    while (_predictionBuffer.length > config.historyWindow) {
      _predictionBuffer.removeAt(0);
    }

    // 4. Count matching predictions for this category
    final matching = _predictionBuffer.where((p) => p.category == category).toList();
    final count = matching.length;

    debugPrint('[Temporal] ${category.name} confirmations: $count/${config.historyWindow}');

    // 5. Check if confirmation threshold is achieved
    if (count >= config.minimumConfirmations) {
      final aggregatedConfidence = _computeAggregatedConfidence(matching);

      return ConfirmedSoundDetection(
        category: category,
        aggregatedConfidence: aggregatedConfidence,
        confirmationCount: count,
        windowSize: _predictionBuffer.length,
        timestamp: now,
        contributingPredictions: List.unmodifiable(matching),
      );
    }

    return null;
  }

  /// Remove predictions older than the configured expiry threshold.
  void _purgeExpired(DateTime now) {
    _predictionBuffer.removeWhere((p) => now.difference(p.timestamp) > config.predictionExpiry);
  }

  /// Explicitly purge expired predictions (can be called by timers or tests).
  void purgeExpired([DateTime? now]) {
    _purgeExpired(now ?? DateTime.now());
  }

  /// Reset and empty the rolling buffer (e.g. when pausing audio monitoring).
  void reset() {
    _predictionBuffer.clear();
  }

  /// Unmodifiable view of current predictions in buffer.
  List<TemporalPrediction> get currentBuffer => List.unmodifiable(_predictionBuffer);

  /// Compute aggregated confidence score across matching window predictions.
  double _computeAggregatedConfidence(List<TemporalPrediction> predictions) {
    if (predictions.isEmpty) return 0.0;

    switch (config.aggregationMethod) {
      case ConfidenceAggregationMethod.average:
        final sum = predictions.fold(0.0, (acc, p) => acc + p.confidence);
        return (sum / predictions.length).clamp(0.0, 1.0);

      case ConfidenceAggregationMethod.maximum:
        return predictions.map((p) => p.confidence).reduce(max).clamp(0.0, 1.0);

      case ConfidenceAggregationMethod.weightedAverage:
        // Recent predictions receive proportionally higher weights
        double weightedSum = 0.0;
        double totalWeight = 0.0;
        for (int i = 0; i < predictions.length; i++) {
          final weight = (i + 1).toDouble(); // 1, 2, 3...
          weightedSum += predictions[i].confidence * weight;
          totalWeight += weight;
        }
        return totalWeight > 0 ? (weightedSum / totalWeight).clamp(0.0, 1.0) : 0.0;
    }
  }
}
