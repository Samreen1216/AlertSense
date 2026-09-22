import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:alertsense/core/constants/sound_categories.dart';
import 'package:alertsense/core/constants/sound_detection_thresholds.dart';
import 'package:alertsense/data/models/classification_result.dart';
import 'package:alertsense/evaluation/evaluation_engine.dart';
import 'package:alertsense/evaluation/evaluation_models.dart';
import 'package:alertsense/services/temporal_smoothing_service.dart';

Uint8List _createWavBytes(List<int> int16Samples, {int sampleRate = 16000, int channels = 1}) {
  final byteData = ByteData(44 + int16Samples.length * 2);
  // "RIFF"
  byteData.setUint8(0, 0x52); byteData.setUint8(1, 0x49); byteData.setUint8(2, 0x46); byteData.setUint8(3, 0x46);
  byteData.setUint32(4, 36 + int16Samples.length * 2, Endian.little);
  // "WAVE"
  byteData.setUint8(8, 0x57); byteData.setUint8(9, 0x41); byteData.setUint8(10, 0x56); byteData.setUint8(11, 0x45);
  // "fmt "
  byteData.setUint8(12, 0x66); byteData.setUint8(13, 0x6D); byteData.setUint8(14, 0x74); byteData.setUint8(15, 0x20);
  byteData.setUint32(16, 16, Endian.little);
  byteData.setUint16(20, 1, Endian.little); // PCM = 1
  byteData.setUint16(22, channels, Endian.little);
  byteData.setUint32(24, sampleRate, Endian.little);
  byteData.setUint32(28, sampleRate * channels * 2, Endian.little);
  byteData.setUint16(32, channels * 2, Endian.little);
  byteData.setUint16(34, 16, Endian.little);
  // "data"
  byteData.setUint8(36, 0x64); byteData.setUint8(37, 0x61); byteData.setUint8(38, 0x74); byteData.setUint8(39, 0x61);
  byteData.setUint32(40, int16Samples.length * 2, Endian.little);
  for (int i = 0; i < int16Samples.length; i++) {
    byteData.setInt16(44 + i * 2, int16Samples[i], Endian.little);
  }
  return byteData.buffer.asUint8List();
}

void main() {
  group('EvaluationEngine Batch & Dataset Tests', () {
    late SoundDetectionThresholds thresholds;
    late EvaluationEngine engine;

    setUp(() {
      thresholds = SoundDetectionThresholds();
      engine = EvaluationEngine(
        thresholds: thresholds,
        temporalSmoother: TemporalSmoothingService(),
      );
    });

    test('evaluateSamples with custom classifyOverride checks category thresholds', () {
      final samples = [
        // Sample 1: Doorbell, passes threshold (0.70)
        const EvaluationSample(
          id: 's1',
          expectedCategory: SoundCategory.doorbell,
          audioData: [0.1, 0.2],
          condition: SoundTestCondition.quietEnvironment,
        ),
        // Sample 2: Dog barking, fails threshold (0.75) because confidence is 0.70
        const EvaluationSample(
          id: 's2',
          expectedCategory: SoundCategory.dogBarking,
          audioData: [0.3, 0.4],
          condition: SoundTestCondition.noisyEnvironment,
        ),
        // Sample 3: Ambient noise, correctly classified as null
        const EvaluationSample(
          id: 's3',
          expectedCategory: null,
          audioData: [0.01, 0.02],
          condition: SoundTestCondition.backgroundSpeech,
        ),
      ];

      final report = engine.evaluateSamples(
        samples,
        classifyOverride: (data) {
          if (data[0] == 0.1) {
            return ClassificationResult(
              soundCategory: 'doorbell',
              confidence: 0.85,
              timestamp: DateTime.now(),
              topPredictions: const [MapEntry('Doorbell', 0.85)],
              ambientDbLevel: 60.0,
            );
          } else if (data[0] == 0.3) {
            return ClassificationResult(
              soundCategory: 'dogBarking',
              confidence: 0.70, // Below dogBarking threshold of 0.75 -> will be rejected
              timestamp: DateTime.now(),
              topPredictions: const [MapEntry('Dog', 0.70)],
              ambientDbLevel: 55.0,
            );
          }
          return null; // Silent / ambient
        },
      );

      expect(report.totalSamples, equals(3));
      // s1 is correct (doorbell detected >= 0.70)
      // s2 is incorrect (dog barking rejected because 0.70 < 0.75 threshold)
      // s3 is correct (null predicted for expected null)
      expect(report.correctCount, equals(2));
      expect(report.overallAccuracy, closeTo(2 / 3, 0.001));

      // Condition breakdowns
      expect(report.accuracyByCondition[SoundTestCondition.quietEnvironment], equals(1.0));
      expect(report.accuracyByCondition[SoundTestCondition.noisyEnvironment], equals(0.0));
      expect(report.accuracyByCondition[SoundTestCondition.backgroundSpeech], equals(1.0));
    });

    test('evaluateSamples with temporal smoothing requires multi-window confirmation', () {
      final smoother = TemporalSmoothingService(
        config: const TemporalSmoothingConfig(historyWindow: 3, minimumConfirmations: 2),
      );
      final smoothingEngine = EvaluationEngine(
        thresholds: thresholds,
        temporalSmoother: smoother,
      );

      // Single window of fire alarm
      final singleSample = [
        const EvaluationSample(
          id: 'w1',
          expectedCategory: SoundCategory.fireAlarm,
          audioData: [0.5],
        ),
      ];

      // Single sample without prior window -> smoother returns null -> incorrect
      final reportSingle = smoothingEngine.evaluateSamples(
        singleSample,
        useTemporalSmoothing: true,
        resetSmootherPerSample: false,
        classifyOverride: (_) => ClassificationResult(
          soundCategory: 'fireAlarm',
          confidence: 0.90,
          timestamp: DateTime.now(),
          topPredictions: const [MapEntry('Fire alarm', 0.90)],
          ambientDbLevel: 80.0,
        ),
      );

      expect(reportSingle.results.first.predictedCategory, isNull);
      expect(reportSingle.results.first.isCorrect, isFalse);

      // Second window of fire alarm into same smoother stream -> confirmed!
      final secondSample = [
        const EvaluationSample(
          id: 'w2',
          expectedCategory: SoundCategory.fireAlarm,
          audioData: [0.5],
        ),
      ];

      final reportSecond = smoothingEngine.evaluateSamples(
        secondSample,
        useTemporalSmoothing: true,
        resetSmootherPerSample: false,
        classifyOverride: (_) => ClassificationResult(
          soundCategory: 'fireAlarm',
          confidence: 0.92,
          timestamp: DateTime.now(),
          topPredictions: const [MapEntry('Fire alarm', 0.92)],
          ambientDbLevel: 82.0,
        ),
      );

      expect(reportSecond.results.first.predictedCategory, equals(SoundCategory.fireAlarm));
      expect(reportSecond.results.first.isCorrect, isTrue);
    });

    test('loadDatasetFromDirectory correctly loads and decodes WAV files and directory hierarchies', () async {
      final tempDir = Directory.systemTemp.createTempSync('alertsense_eval_test_');

      try {
        // Create subdirectories
        final fireDir = Directory('${tempDir.path}/fireAlarm')..createSync(recursive: true);
        final ambientDir = Directory('${tempDir.path}/ambient')..createSync(recursive: true);

        // Create sample audio WAV files
        final samplePcm = [1000, 2000, -1000, -2000];
        final wavBytes = _createWavBytes(samplePcm);

        final fireFile = File('${fireDir.path}/siren_quiet_01.wav')..writeAsBytesSync(wavBytes);
        final ambientFile = File('${ambientDir.path}/talking_speech_02.wav')..writeAsBytesSync(wavBytes);

        expect(fireFile.existsSync(), isTrue);
        expect(ambientFile.existsSync(), isTrue);

        final loadedSamples = await EvaluationEngine.loadDatasetFromDirectory(tempDir);

        expect(loadedSamples.length, equals(2));

        final fireSample = loadedSamples.firstWhere((s) => s.id.contains('siren_quiet_01'));
        expect(fireSample.expectedCategory, equals(SoundCategory.fireAlarm));
        expect(fireSample.condition, equals(SoundTestCondition.quietEnvironment));
        expect(fireSample.audioData.length, equals(4));
        expect(fireSample.audioData[0], closeTo(1000 / 32768.0, 0.001));

        final ambientSample = loadedSamples.firstWhere((s) => s.id.contains('talking_speech_02'));
        expect(ambientSample.expectedCategory, isNull);
        expect(ambientSample.condition, equals(SoundTestCondition.backgroundSpeech));
        expect(ambientSample.audioData.length, equals(4));
      } finally {
        tempDir.deleteSync(recursive: true);
      }
    });
  });
}
