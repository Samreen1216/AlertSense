import 'package:flutter_test/flutter_test.dart';
import 'package:alertsense/core/constants/sound_categories.dart';
import 'package:alertsense/evaluation/evaluation_models.dart';
import 'package:alertsense/evaluation/evaluation_engine.dart';

void main() {
  group('Evaluation Metrics Calculations & Zero-Division Safety', () {
    test('Empty results handle zero division gracefully without throwing or NaN', () {
      final report = EvaluationEngine.calculateMetrics([]);

      expect(report.totalSamples, equals(0));
      expect(report.overallAccuracy, equals(0.0));
      expect(report.macroPrecision, equals(0.0));
      expect(report.macroRecall, equals(0.0));
      expect(report.macroF1Score, equals(0.0));
      expect(report.overallFalseAlertRate, equals(0.0));
      expect(report.categoryMetrics.length, equals(SoundCategory.values.length));

      for (final metric in report.categoryMetrics.values) {
        expect(metric.precision, equals(0.0));
        expect(metric.recall, equals(0.0));
        expect(metric.f1Score, equals(0.0));
        expect(metric.falseAlertRate, equals(0.0));
        expect(metric.truePositives, equals(0));
        expect(metric.falsePositives, equals(0));
      }
    });

    test('100% correct dataset calculates perfect 1.0 metrics and 0.0 FAR', () {
      final results = SoundCategory.values.map((cat) {
        return EvaluationResultItem(
          sampleId: 'sample_${cat.name}',
          expectedCategory: cat,
          predictedCategory: cat,
          confidence: 0.95,
          isCorrect: true,
          condition: SoundTestCondition.quietEnvironment,
        );
      }).toList();

      final report = EvaluationEngine.calculateMetrics(results);

      expect(report.totalSamples, equals(9));
      expect(report.correctCount, equals(9));
      expect(report.overallAccuracy, equals(1.0));
      expect(report.macroPrecision, equals(1.0));
      expect(report.macroRecall, equals(1.0));
      expect(report.macroF1Score, equals(1.0));
      expect(report.overallFalseAlertRate, equals(0.0));

      for (final metric in report.categoryMetrics.values) {
        expect(metric.truePositives, equals(1));
        expect(metric.falsePositives, equals(0));
        expect(metric.falseNegatives, equals(0));
        expect(metric.trueNegatives, equals(8));
        expect(metric.precision, equals(1.0));
        expect(metric.recall, equals(1.0));
        expect(metric.f1Score, equals(1.0));
        expect(metric.falseAlertRate, equals(0.0));
      }
    });

    test('Precision, Recall, F1 and FAR computed accurately on mixed outcomes', () {
      // 2 TP for fireAlarm, 1 FP for fireAlarm, 1 FN for fireAlarm
      final results = <EvaluationResultItem>[
        // TP 1
        EvaluationResultItem(
          sampleId: 's1',
          expectedCategory: SoundCategory.fireAlarm,
          predictedCategory: SoundCategory.fireAlarm,
          confidence: 0.90,
          isCorrect: true,
        ),
        // TP 2
        EvaluationResultItem(
          sampleId: 's2',
          expectedCategory: SoundCategory.fireAlarm,
          predictedCategory: SoundCategory.fireAlarm,
          confidence: 0.85,
          isCorrect: true,
        ),
        // FP: Ambient noise misclassified as fireAlarm
        EvaluationResultItem(
          sampleId: 's3',
          expectedCategory: null,
          predictedCategory: SoundCategory.fireAlarm,
          confidence: 0.70,
          isCorrect: false,
        ),
        // FN: fireAlarm missed (predicted as knocking)
        EvaluationResultItem(
          sampleId: 's4',
          expectedCategory: SoundCategory.fireAlarm,
          predictedCategory: SoundCategory.knocking,
          confidence: 0.60,
          isCorrect: false,
        ),
        // TN: Ambient audio correctly rejected
        EvaluationResultItem(
          sampleId: 's5',
          expectedCategory: null,
          predictedCategory: null,
          confidence: 0.0,
          isCorrect: true,
        ),
      ];

      final report = EvaluationEngine.calculateMetrics(results);

      expect(report.totalSamples, equals(5));
      expect(report.correctCount, equals(3));
      expect(report.overallAccuracy, equals(3 / 5)); // 0.60

      final fireMetric = report.categoryMetrics[SoundCategory.fireAlarm]!;
      expect(fireMetric.truePositives, equals(2));
      expect(fireMetric.falsePositives, equals(1));
      expect(fireMetric.falseNegatives, equals(1));
      expect(fireMetric.trueNegatives, equals(1)); // s5 is not expected fireAlarm and not predicted fireAlarm

      // Precision = 2 / (2 + 1) = 2/3
      expect(fireMetric.precision, closeTo(2 / 3, 0.0001));
      // Recall = 2 / (2 + 1) = 2/3
      expect(fireMetric.recall, closeTo(2 / 3, 0.0001));
      // F1 = 2 * (2/3) * (2/3) / (4/3) = 2/3
      expect(fireMetric.f1Score, closeTo(2 / 3, 0.0001));
      // FAR = FP / (FP + TN) = 1 / (1 + 1) = 0.5
      expect(fireMetric.falseAlertRate, equals(0.5));
    });

    test('Division by zero on 0 true positives, 0 false positives returns 0.0', () {
      // Results contain only dogBarking, no glassBreaking ever predicted or expected
      final results = [
        EvaluationResultItem(
          sampleId: 's1',
          expectedCategory: SoundCategory.dogBarking,
          predictedCategory: SoundCategory.dogBarking,
          confidence: 0.88,
          isCorrect: true,
        ),
      ];

      final report = EvaluationEngine.calculateMetrics(results);
      final glassMetric = report.categoryMetrics[SoundCategory.glassBreaking]!;

      expect(glassMetric.truePositives, equals(0));
      expect(glassMetric.falsePositives, equals(0));
      expect(glassMetric.falseNegatives, equals(0));
      expect(glassMetric.trueNegatives, equals(1));

      expect(glassMetric.precision.isNaN, isFalse);
      expect(glassMetric.precision, equals(0.0));
      expect(glassMetric.recall.isNaN, isFalse);
      expect(glassMetric.recall, equals(0.0));
      expect(glassMetric.f1Score.isNaN, isFalse);
      expect(glassMetric.f1Score, equals(0.0));
      expect(glassMetric.falseAlertRate, equals(0.0));
    });

    test('Accuracy by condition correctly segments test performance', () {
      final results = [
        EvaluationResultItem(
          sampleId: 'q1',
          expectedCategory: SoundCategory.doorbell,
          predictedCategory: SoundCategory.doorbell,
          confidence: 0.90,
          isCorrect: true,
          condition: SoundTestCondition.quietEnvironment,
        ),
        EvaluationResultItem(
          sampleId: 'n1',
          expectedCategory: SoundCategory.doorbell,
          predictedCategory: null,
          confidence: 0.0,
          isCorrect: false,
          condition: SoundTestCondition.noisyEnvironment,
        ),
      ];

      final report = EvaluationEngine.calculateMetrics(results);

      expect(report.accuracyByCondition[SoundTestCondition.quietEnvironment], equals(1.0));
      expect(report.accuracyByCondition[SoundTestCondition.noisyEnvironment], equals(0.0));
      // Untested condition reports 0.0
      expect(report.accuracyByCondition[SoundTestCondition.backgroundSpeech], equals(0.0));
    });

    test('toFormattedSummary generates readable report string and toJson serializes completely', () {
      final results = [
        EvaluationResultItem(
          sampleId: 'test1',
          expectedCategory: SoundCategory.babyCrying,
          predictedCategory: SoundCategory.babyCrying,
          confidence: 0.85,
          isCorrect: true,
        ),
      ];

      final report = EvaluationEngine.calculateMetrics(results);
      final summary = report.toFormattedSummary();

      expect(summary, contains('AlertSense YAMNet Real-World Evaluation Report'));
      expect(summary, contains('Baby Crying'));
      expect(summary, contains('Total Samples: 1'));

      final json = report.toJson();
      expect(json['totalSamples'], equals(1));
      expect(json['categoryMetrics'], isA<Map>());
      expect(json['results'], isA<List>());
    });
  });
}
