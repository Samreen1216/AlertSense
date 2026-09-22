import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:alertsense/core/constants/sound_categories.dart';
import 'package:alertsense/services/tflite_classifier_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('TFLiteClassifierService Tests', () {
    late TFLiteClassifierService classifier;

    setUp(() {
      classifier = TFLiteClassifierService();
    });

    tearDown(() {
      classifier.dispose();
    });

    test('Loads model and initializes successfully', () async {
      await classifier.loadModel();
      expect(classifier.isLoaded, isTrue);
    });

    test('Classifies bell ring tone as Bell Ring (doorbell)', () async {
      await classifier.loadModel();
      const sampleRate = 16000;
      const totalSamples = 15600;
      final audioData = List<double>.filled(totalSamples, 0.0);

      // Generate a resonant bell ring at 850 Hz
      const freq = 850.0;
      for (int i = 1500; i < 7000; i++) {
        final t = (i - 1500) / sampleRate;
        audioData[i] = 0.25 * sin(2 * pi * freq * t) * exp(-t * 2.0);
      }

      final result = classifier.classify(audioData);
      expect(result, isNotNull);
      expect(result!.soundCategory, equals(SoundCategory.doorbell.name));
      expect(result.confidence, greaterThanOrEqualTo(0.50));
    });

    test('Classifies fire alarm beep as fireAlarm', () async {
      await classifier.loadModel();
      const sampleRate = 16000;
      const totalSamples = 15600;
      final audioData = List<double>.filled(totalSamples, 0.0);

      // 3100 Hz tonal fire alarm beep
      const freq = 3100.0;
      for (int i = 0; i < totalSamples; i++) {
        final t = i / sampleRate;
        audioData[i] = 0.3 * sin(2 * pi * freq * t);
      }

      final result = classifier.classify(audioData);
      expect(result, isNotNull);
      expect(result!.soundCategory, equals(SoundCategory.fireAlarm.name));
      expect(result.confidence, greaterThanOrEqualTo(0.70));
    });

    test('Silent audio returns null', () async {
      await classifier.loadModel();
      final silence = List<double>.filled(15600, 0.0);
      final result = classifier.classify(silence);
      expect(result, isNull);
    });
  });
}
