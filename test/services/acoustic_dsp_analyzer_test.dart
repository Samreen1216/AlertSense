import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:alertsense/core/constants/sound_categories.dart';
import 'package:alertsense/services/acoustic_dsp_analyzer.dart';

void main() {
  group('AcousticDspAnalyzer Tests', () {
    late AcousticDspAnalyzer analyzer;

    setUp(() {
      analyzer = AcousticDspAnalyzer();
    });

    test('Bell Ring (Doorbell chime ~800 Hz) is accurately identified', () {
      const sampleRate = 16000;
      const totalSamples = 15600;
      final audioData = List<double>.filled(totalSamples, 0.0);

      // Generate an 800 Hz bell chime tone starting at sample 2000 (125ms in)
      const freq = 800.0;
      for (int i = 2000; i < 6000; i++) {
        final t = (i - 2000) / sampleRate;
        final decay = exp(-t * 2.5); // exponential bell decay
        audioData[i] = 0.25 * sin(2 * pi * freq * t) * decay;
      }

      final result = analyzer.classify(audioData);

      expect(result, isNotNull);
      expect(result!.soundCategory, equals(SoundCategory.doorbell.name));
      expect(result.confidence, greaterThanOrEqualTo(0.70));
    });

    test('High-frequency Bell Ring (~2000 Hz) is accurately identified', () {
      const sampleRate = 16000;
      const totalSamples = 15600;
      final audioData = List<double>.filled(totalSamples, 0.0);

      // Generate a 2000 Hz bell tone starting at sample 1000
      const freq = 2000.0;
      for (int i = 1000; i < 5000; i++) {
        final t = (i - 1000) / sampleRate;
        final decay = exp(-t * 3.0);
        audioData[i] = 0.20 * sin(2 * pi * freq * t) * decay;
      }

      final result = analyzer.classify(audioData);

      expect(result, isNotNull);
      expect(result!.soundCategory, equals(SoundCategory.doorbell.name));
      expect(result.confidence, greaterThanOrEqualTo(0.70));
    });

    test('Fire Alarm (~3100 Hz tonal beep) is accurately identified', () {
      const sampleRate = 16000;
      const totalSamples = 15600;
      final audioData = List<double>.filled(totalSamples, 0.0);

      // Fire alarm ~3100 Hz tone
      const freq = 3100.0;
      for (int i = 0; i < totalSamples; i++) {
        final t = i / sampleRate;
        audioData[i] = 0.25 * sin(2 * pi * freq * t);
      }

      final result = analyzer.classify(audioData);

      expect(result, isNotNull);
      expect(result!.soundCategory, equals(SoundCategory.fireAlarm.name));
      expect(result.confidence, greaterThanOrEqualTo(0.75));
    });

    test('Silence or faint ambient noise returns null without false alarm', () {
      const totalSamples = 15600;
      final silence = List<double>.filled(totalSamples, 0.0001);

      final result = analyzer.classify(silence);
      expect(result, isNull);
    });

    test('SoundCategory.doorbell has Bell Ring label and YAMNet mappings', () {
      final category = SoundCategory.doorbell;
      expect(category.label, equals('Bell Ring'));
      expect(category.yamnetLabels, contains('Bell ring'));
      expect(category.yamnetLabels, contains('Doorbell'));
      expect(category.yamnetLabels, contains('Chime'));
    });
  });
}
