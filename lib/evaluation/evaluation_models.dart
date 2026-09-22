import '../core/constants/sound_categories.dart';

/// Real-world acoustic test environments and acoustic conditions.
enum SoundTestCondition {
  quietEnvironment('Quiet environment'),
  noisyEnvironment('Noisy environment'),
  nearSoundSource('Near sound source'),
  farFromSoundSource('Far from sound source'),
  lowVolumeSound('Low-volume sound'),
  multipleSimultaneousSounds('Multiple simultaneous sounds'),
  backgroundSpeech('Background speech'),
  musicBackgroundNoise('Music/background noise');

  final String label;
  const SoundTestCondition(this.label);

  static SoundTestCondition fromString(String str) {
    final lower = str.toLowerCase();
    for (final val in SoundTestCondition.values) {
      if (val.name.toLowerCase() == lower || val.label.toLowerCase() == lower) {
        return val;
      }
    }
    return SoundTestCondition.quietEnvironment;
  }
}

/// An audio evaluation sample fed into the recognition evaluation framework.
class EvaluationSample {
  final String id;
  final SoundCategory? expectedCategory; // null indicates negative / background / ambient audio
  final List<double> audioData;
  final SoundTestCondition condition;
  final String? sourcePath;
  final Map<String, dynamic> metadata;

  const EvaluationSample({
    required this.id,
    this.expectedCategory,
    required this.audioData,
    this.condition = SoundTestCondition.quietEnvironment,
    this.sourcePath,
    this.metadata = const {},
  });
}

/// Individual inference result outcome for an evaluation sample.
class EvaluationResultItem {
  final String sampleId;
  final SoundCategory? expectedCategory;
  final SoundCategory? predictedCategory;
  final double confidence;
  final bool isCorrect;
  final SoundTestCondition condition;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  EvaluationResultItem({
    required this.sampleId,
    this.expectedCategory,
    this.predictedCategory,
    required this.confidence,
    required this.isCorrect,
    this.condition = SoundTestCondition.quietEnvironment,
    DateTime? timestamp,
    this.metadata = const {},
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toJson() => {
        'sampleId': sampleId,
        'expectedCategory': expectedCategory?.name,
        'predictedCategory': predictedCategory?.name,
        'confidence': confidence,
        'isCorrect': isCorrect,
        'condition': condition.label,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
      };
}

/// Performance metrics computed for an individual [SoundCategory].
class CategoryMetrics {
  final SoundCategory category;
  final int truePositives;
  final int falsePositives;
  final int falseNegatives;
  final int trueNegatives;
  final double precision;
  final double recall;
  final double f1Score;
  final double falseAlertRate;

  const CategoryMetrics({
    required this.category,
    required this.truePositives,
    required this.falsePositives,
    required this.falseNegatives,
    required this.trueNegatives,
    required this.precision,
    required this.recall,
    required this.f1Score,
    required this.falseAlertRate,
  });

  Map<String, dynamic> toJson() => {
        'category': category.name,
        'label': category.label,
        'truePositives': truePositives,
        'falsePositives': falsePositives,
        'falseNegatives': falseNegatives,
        'trueNegatives': trueNegatives,
        'precision': precision,
        'recall': recall,
        'f1Score': f1Score,
        'falseAlertRate': falseAlertRate,
      };
}

/// Aggregated real-world evaluation report across all categories and conditions.
class EvaluationReport {
  final List<EvaluationResultItem> results;
  final double overallAccuracy;
  final double macroPrecision;
  final double macroRecall;
  final double macroF1Score;
  final double overallFalseAlertRate;
  final Map<SoundCategory, CategoryMetrics> categoryMetrics;
  final Map<SoundTestCondition, double> accuracyByCondition;
  final DateTime generatedAt;

  EvaluationReport({
    required this.results,
    required this.overallAccuracy,
    required this.macroPrecision,
    required this.macroRecall,
    required this.macroF1Score,
    required this.overallFalseAlertRate,
    required this.categoryMetrics,
    required this.accuracyByCondition,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  int get totalSamples => results.length;
  int get correctCount => results.where((r) => r.isCorrect).length;

  /// Returns a clean human-readable evaluation summary table.
  String toFormattedSummary() {
    final buffer = StringBuffer();
    buffer.writeln('===============================================================');
    buffer.writeln('          AlertSense YAMNet Real-World Evaluation Report        ');
    buffer.writeln('===============================================================');
    buffer.writeln('Generated: ${generatedAt.toIso8601String()}');
    buffer.writeln('Total Samples: $totalSamples | Correct: $correctCount (${(overallAccuracy * 100).toStringAsFixed(1)}%)');
    buffer.writeln('Macro Precision: ${(macroPrecision * 100).toStringAsFixed(1)}% | Macro Recall: ${(macroRecall * 100).toStringAsFixed(1)}%');
    buffer.writeln('Macro F1 Score: ${(macroF1Score * 100).toStringAsFixed(1)}% | False Alert Rate: ${(overallFalseAlertRate * 100).toStringAsFixed(1)}%');
    buffer.writeln('---------------------------------------------------------------');
    buffer.writeln('CATEGORY PERFORMANCE:');
    buffer.writeln('Category         | Prec  | Rec   | F1    | FAR   | TP/FP/FN');
    buffer.writeln('-----------------+-------+-------+-------+-------+-------------');

    for (final entry in categoryMetrics.entries) {
      final m = entry.value;
      final catName = m.category.label.padRight(16).substring(0, 16);
      final pStr = (m.precision * 100).toStringAsFixed(0).padLeft(3) + '%';
      final rStr = (m.recall * 100).toStringAsFixed(0).padLeft(3) + '%';
      final fStr = (m.f1Score * 100).toStringAsFixed(0).padLeft(3) + '%';
      final farStr = (m.falseAlertRate * 100).toStringAsFixed(0).padLeft(3) + '%';
      final counts = '${m.truePositives}/${m.falsePositives}/${m.falseNegatives}';
      buffer.writeln('$catName | $pStr  | $rStr  | $fStr  | $farStr  | $counts');
    }

    buffer.writeln('---------------------------------------------------------------');
    buffer.writeln('PERFORMANCE BY ACOUSTIC CONDITION:');
    for (final entry in accuracyByCondition.entries) {
      final condName = entry.key.label.padRight(32);
      final acc = (entry.value * 100).toStringAsFixed(1) + '%';
      buffer.writeln(' - $condName: $acc');
    }
    buffer.writeln('===============================================================');
    return buffer.toString();
  }

  Map<String, dynamic> toJson() => {
        'totalSamples': totalSamples,
        'overallAccuracy': overallAccuracy,
        'macroPrecision': macroPrecision,
        'macroRecall': macroRecall,
        'macroF1Score': macroF1Score,
        'overallFalseAlertRate': overallFalseAlertRate,
        'generatedAt': generatedAt.toIso8601String(),
        'categoryMetrics': categoryMetrics.map((k, v) => MapEntry(k.name, v.toJson())),
        'accuracyByCondition': accuracyByCondition.map((k, v) => MapEntry(k.name, v)),
        'results': results.map((r) => r.toJson()).toList(),
      };
}
