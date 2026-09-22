import 'dart:io';
import 'package:flutter/foundation.dart';
import '../core/constants/sound_categories.dart';
import '../core/constants/sound_detection_thresholds.dart';
import '../data/models/classification_result.dart';
import '../services/temporal_smoothing_service.dart';
import '../services/tflite_classifier_service.dart';
import 'evaluation_models.dart';

/// Offline evaluation engine for the AlertSense sound recognition system.
///
/// Computes real-world performance metrics:
/// - Accuracy
/// - Precision
/// - Recall
/// - F1 Score
/// - False Alert Rate (FAR)
/// Across 9 sound categories and 8 acoustic test conditions.
/// Fully zero-division safe for empty categories and edge cases.
class EvaluationEngine {
  final TFLiteClassifierService? classifier;
  final SoundDetectionThresholds thresholds;
  final TemporalSmoothingService? temporalSmoother;

  EvaluationEngine({
    this.classifier,
    SoundDetectionThresholds? thresholds,
    this.temporalSmoother,
  }) : thresholds = thresholds ?? SoundDetectionThresholds();

  /// Calculate all performance metrics from a collection of evaluation result items.
  ///
  /// Guaranteed to be safe against division by zero (returns 0.0 when denominators are zero).
  static EvaluationReport calculateMetrics(List<EvaluationResultItem> results) {
    if (results.isEmpty) {
      final emptyMetrics = <SoundCategory, CategoryMetrics>{};
      for (final cat in SoundCategory.values) {
        emptyMetrics[cat] = CategoryMetrics(
          category: cat,
          truePositives: 0,
          falsePositives: 0,
          falseNegatives: 0,
          trueNegatives: 0,
          precision: 0.0,
          recall: 0.0,
          f1Score: 0.0,
          falseAlertRate: 0.0,
        );
      }
      return EvaluationReport(
        results: const [],
        overallAccuracy: 0.0,
        macroPrecision: 0.0,
        macroRecall: 0.0,
        macroF1Score: 0.0,
        overallFalseAlertRate: 0.0,
        categoryMetrics: emptyMetrics,
        accuracyByCondition: {for (final c in SoundTestCondition.values) c: 0.0},
      );
    }

    final totalSamples = results.length;
    final correctCount = results.where((r) => r.isCorrect).length;
    final overallAccuracy = totalSamples > 0 ? (correctCount / totalSamples) : 0.0;

    final categoryMetrics = <SoundCategory, CategoryMetrics>{};

    for (final category in SoundCategory.values) {
      int tp = 0;
      int fp = 0;
      int fn = 0;
      int tn = 0;

      for (final item in results) {
        final isExpected = item.expectedCategory == category;
        final isPredicted = item.predictedCategory == category;

        if (isExpected && isPredicted) {
          tp++;
        } else if (!isExpected && isPredicted) {
          fp++;
        } else if (isExpected && !isPredicted) {
          fn++;
        } else {
          tn++;
        }
      }

      // Precision: TP / (TP + FP)
      final precisionDenom = tp + fp;
      final precision = precisionDenom > 0 ? (tp / precisionDenom) : 0.0;

      // Recall: TP / (TP + FN)
      final recallDenom = tp + fn;
      final recall = recallDenom > 0 ? (tp / recallDenom) : 0.0;

      // F1 Score: 2 * Precision * Recall / (Precision + Recall)
      final f1Denom = precision + recall;
      final f1Score = f1Denom > 0 ? (2 * precision * recall / f1Denom) : 0.0;

      // False Alert Rate (Fall-out / False Positive Rate): FP / (FP + TN)
      final farDenom = fp + tn;
      final falseAlertRate = farDenom > 0 ? (fp / farDenom) : 0.0;

      categoryMetrics[category] = CategoryMetrics(
        category: category,
        truePositives: tp,
        falsePositives: fp,
        falseNegatives: fn,
        trueNegatives: tn,
        precision: precision,
        recall: recall,
        f1Score: f1Score,
        falseAlertRate: falseAlertRate,
      );
    }

    // Macro-averages across all 9 monitored categories
    final numCategories = categoryMetrics.length;
    final macroPrecision = numCategories > 0
        ? categoryMetrics.values.fold(0.0, (acc, m) => acc + m.precision) / numCategories
        : 0.0;
    final macroRecall = numCategories > 0
        ? categoryMetrics.values.fold(0.0, (acc, m) => acc + m.recall) / numCategories
        : 0.0;
    final macroF1Score = numCategories > 0
        ? categoryMetrics.values.fold(0.0, (acc, m) => acc + m.f1Score) / numCategories
        : 0.0;
    final overallFalseAlertRate = numCategories > 0
        ? categoryMetrics.values.fold(0.0, (acc, m) => acc + m.falseAlertRate) / numCategories
        : 0.0;

    // Accuracy by acoustic test condition
    final accuracyByCondition = <SoundTestCondition, double>{};
    for (final condition in SoundTestCondition.values) {
      final conditionItems = results.where((r) => r.condition == condition).toList();
      if (conditionItems.isEmpty) {
        accuracyByCondition[condition] = 0.0;
      } else {
        final conditionCorrect = conditionItems.where((r) => r.isCorrect).length;
        accuracyByCondition[condition] = conditionCorrect / conditionItems.length;
      }
    }

    return EvaluationReport(
      results: results,
      overallAccuracy: overallAccuracy,
      macroPrecision: macroPrecision,
      macroRecall: macroRecall,
      macroF1Score: macroF1Score,
      overallFalseAlertRate: overallFalseAlertRate,
      categoryMetrics: categoryMetrics,
      accuracyByCondition: accuracyByCondition,
    );
  }

  /// Run evaluation on a batch of [EvaluationSample]s through the sound recognition pipeline.
  ///
  /// Supports custom classifier overrides for fast and isolated unit/integration tests.
  EvaluationReport evaluateSamples(
    List<EvaluationSample> samples, {
    ClassificationResult? Function(List<double> audioData)? classifyOverride,
    bool useTemporalSmoothing = false,
    bool resetSmootherPerSample = true,
  }) {
    final results = <EvaluationResultItem>[];

    for (final sample in samples) {
      if (resetSmootherPerSample && temporalSmoother != null) {
        temporalSmoother!.reset();
      }

      // 1. Run classifier
      ClassificationResult? classification;
      if (classifyOverride != null) {
        classification = classifyOverride(sample.audioData);
      } else if (classifier != null) {
        classification = classifier!.classify(sample.audioData);
      }

      SoundCategory? predictedCategory;
      double confidence = 0.0;

      if (classification != null) {
        final cat = SoundCategoryExtension.fromName(classification.soundCategory);
        if (cat != null) {
          // 2. Sound-specific threshold gate
          final meets = thresholds.meetsThreshold(cat, classification.confidence);
          if (meets) {
            // 3. Temporal smoothing gate (optional)
            if (useTemporalSmoothing && temporalSmoother != null) {
              final confirmed = temporalSmoother!.processPrediction(
                category: cat,
                confidence: classification.confidence,
              );
              if (confirmed != null) {
                predictedCategory = confirmed.category;
                confidence = confirmed.aggregatedConfidence;
              }
            } else {
              predictedCategory = cat;
              confidence = classification.confidence;
            }
          }
        }
      }

      // Check correctness
      final bool isCorrect;
      if (sample.expectedCategory == null) {
        // Ambient / negative sample: correct if NO alert / sound triggered
        isCorrect = (predictedCategory == null);
      } else {
        // Target sound: correct only if predicted matches expected
        isCorrect = (predictedCategory == sample.expectedCategory);
      }

      results.add(
        EvaluationResultItem(
          sampleId: sample.id,
          expectedCategory: sample.expectedCategory,
          predictedCategory: predictedCategory,
          confidence: confidence,
          isCorrect: isCorrect,
          condition: sample.condition,
          metadata: sample.metadata,
        ),
      );
    }

    return calculateMetrics(results);
  }

  /// Load audio evaluation samples from a local directory layout.
  ///
  /// Expected directory formats:
  /// - `evaluation_audio/<category_name>/<audio_file>`
  /// - `evaluation_audio/<condition_name>/<category_name>/<audio_file>`
  ///
  /// Negative / ambient audio can be placed in directories named `ambient`, `background`,
  /// `negative`, or `noise`.
  static Future<List<EvaluationSample>> loadDatasetFromDirectory(Directory dir) async {
    if (!dir.existsSync()) {
      debugPrint('[EvaluationEngine] Directory does not exist: ${dir.path}');
      return const [];
    }

    final samples = <EvaluationSample>[];
    final entities = dir.listSync(recursive: true);

    for (final entity in entities) {
      if (entity is! File) continue;

      final pathLower = entity.path.toLowerCase();
      if (!pathLower.endsWith('.wav') &&
          !pathLower.endsWith('.pcm') &&
          !pathLower.endsWith('.raw')) {
        continue;
      }

      // Determine expected category from path segments
      final segments = entity.uri.pathSegments.where((s) => s.isNotEmpty).toList();
      SoundCategory? expectedCategory;
      bool isNegative = false;

      for (final segment in segments) {
        final segLower = segment.toLowerCase();
        if (segLower == 'ambient' ||
            segLower == 'background' ||
            segLower == 'negative' ||
            segLower == 'noise') {
          isNegative = true;
          expectedCategory = null;
          break;
        }

        final parsedCat = SoundCategoryExtension.fromName(segment);
        if (parsedCat != null) {
          expectedCategory = parsedCat;
        }
      }

      if (!isNegative && expectedCategory == null) {
        // Check filename without extension
        final fileNameWithoutExt = entity.uri.pathSegments.last.split('.').first;
        expectedCategory = SoundCategoryExtension.fromName(fileNameWithoutExt);
      }

      // Determine acoustic condition from path segments or filename
      SoundTestCondition condition = SoundTestCondition.quietEnvironment;
      final fullPathStr = entity.path.toLowerCase();

      for (final cond in SoundTestCondition.values) {
        if (fullPathStr.contains(cond.name.toLowerCase()) ||
            fullPathStr.contains(cond.label.toLowerCase())) {
          condition = cond;
          break;
        }
      }
      if (condition == SoundTestCondition.quietEnvironment) {
        if (fullPathStr.contains('noisy') || fullPathStr.contains('noise')) {
          condition = SoundTestCondition.noisyEnvironment;
        } else if (fullPathStr.contains('near')) {
          condition = SoundTestCondition.nearSoundSource;
        } else if (fullPathStr.contains('far')) {
          condition = SoundTestCondition.farFromSoundSource;
        } else if (fullPathStr.contains('low') || fullPathStr.contains('quiet_vol')) {
          condition = SoundTestCondition.lowVolumeSound;
        } else if (fullPathStr.contains('speech') || fullPathStr.contains('talking')) {
          condition = SoundTestCondition.backgroundSpeech;
        } else if (fullPathStr.contains('music')) {
          condition = SoundTestCondition.musicBackgroundNoise;
        } else if (fullPathStr.contains('simultaneous')) {
          condition = SoundTestCondition.multipleSimultaneousSounds;
        }
      }

      // Read audio data
      List<double> audioData = const [];
      try {
        if (pathLower.endsWith('.wav')) {
          audioData = _parseWavFile(entity);
        } else {
          audioData = _parsePcmFile(entity);
        }
      } catch (e) {
        debugPrint('[EvaluationEngine] Error reading audio ${entity.path}: $e');
        continue;
      }

      if (audioData.isNotEmpty) {
        samples.add(
          EvaluationSample(
            id: entity.path,
            expectedCategory: expectedCategory,
            audioData: audioData,
            condition: condition,
            sourcePath: entity.path,
          ),
        );
      }
    }

    return samples;
  }

  /// Parse a 16-bit linear PCM WAV file into normalized float samples [-1.0, 1.0].
  static List<double> _parseWavFile(File file) {
    final bytes = file.readAsBytesSync();
    if (bytes.length < 44) return const [];

    final byteData = ByteData.sublistView(bytes);

    // Validate RIFF header
    final riff = String.fromCharCodes(bytes.sublist(0, 4));
    final wave = String.fromCharCodes(bytes.sublist(8, 12));
    if (riff != 'RIFF' || wave != 'WAVE') return const [];

    int offset = 12;
    int numChannels = 1;
    int bitsPerSample = 16;
    int dataOffset = -1;
    int dataLength = 0;

    while (offset + 8 <= bytes.length) {
      final chunkId = String.fromCharCodes(bytes.sublist(offset, offset + 4));
      final chunkSize = byteData.getUint32(offset + 4, Endian.little);
      offset += 8;

      if (chunkId == 'fmt ' && chunkSize >= 16) {
        numChannels = byteData.getUint16(offset + 2, Endian.little);
        bitsPerSample = byteData.getUint16(offset + 14, Endian.little);
        offset += chunkSize;
      } else if (chunkId == 'data') {
        dataOffset = offset;
        dataLength = chunkSize;
        break;
      } else {
        offset += chunkSize;
      }
    }

    if (dataOffset == -1 || bitsPerSample != 16) return const [];

    final total16BitSamples = (dataLength ~/ 2);
    final monoSamples = <double>[];

    if (numChannels == 1) {
      for (int i = 0; i < total16BitSamples; i++) {
        final samplePos = dataOffset + (i * 2);
        if (samplePos + 2 > bytes.length) break;
        final raw = byteData.getInt16(samplePos, Endian.little);
        monoSamples.add(raw / 32768.0);
      }
    } else if (numChannels == 2) {
      // Stereo: average left and right
      final frameCount = total16BitSamples ~/ 2;
      for (int i = 0; i < frameCount; i++) {
        final samplePos = dataOffset + (i * 4);
        if (samplePos + 4 > bytes.length) break;
        final left = byteData.getInt16(samplePos, Endian.little) / 32768.0;
        final right = byteData.getInt16(samplePos + 2, Endian.little) / 32768.0;
        monoSamples.add((left + right) / 2.0);
      }
    }

    return monoSamples;
  }

  /// Parse raw 16-bit signed PCM mono audio bytes into [-1.0, 1.0] floats.
  static List<double> _parsePcmFile(File file) {
    final bytes = file.readAsBytesSync();
    if (bytes.length < 2) return const [];

    final byteData = ByteData.sublistView(bytes);
    final numSamples = bytes.length ~/ 2;
    final samples = <double>[];

    for (int i = 0; i < numSamples; i++) {
      final raw = byteData.getInt16(i * 2, Endian.little);
      samples.add(raw / 32768.0);
    }

    return samples;
  }
}
