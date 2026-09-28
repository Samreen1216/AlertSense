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

    test('Vehicle Horn (~420-500 Hz honk) is accurately identified as vehicleHorn, not doorbell', () {
      const sampleRate = 16000;
      const totalSamples = 15600;
      final audioData = List<double>.filled(totalSamples, 0.0);

      // Dual-tone vehicle horn around 420 Hz and 500 Hz
      for (int i = 1000; i < 14000; i++) {
        final t = (i - 1000) / sampleRate;
        audioData[i] = 0.20 * sin(2 * pi * 420 * t) + 0.15 * sin(2 * pi * 500 * t);
      }

      final result = analyzer.classify(audioData);

      expect(result, isNotNull);
      expect(result!.soundCategory, equals(SoundCategory.vehicleHorn.name));
      expect(result.confidence, greaterThanOrEqualTo(0.80));
    });

    test('Dog Barking burst is accurately identified as dogBarking', () {
      const sampleRate = 16000;
      const totalSamples = 15600;
      final audioData = List<double>.filled(totalSamples, 0.0);

      // Bark burst with rich harmonics (fundamental ~380Hz, harmonics 760Hz, 1140Hz)
      final rng = Random(42);
      for (int i = 3000; i < 8000; i++) {
        final t = (i - 3000) / sampleRate;
        final envelope = sin(pi * (i - 3000) / 5000);
        final harmonics = 0.18 * sin(2 * pi * 380 * t) +
            0.12 * sin(2 * pi * 760 * t) +
            0.08 * sin(2 * pi * 1140 * t) +
            0.05 * (rng.nextDouble() * 2 - 1);
        audioData[i] = envelope * harmonics;
      }

      final result = analyzer.classify(audioData);

      expect(result, isNotNull);
      expect(result!.soundCategory, equals(SoundCategory.dogBarking.name));
      expect(result.confidence, greaterThanOrEqualTo(0.80));
    });

    test('SoundCategory.doorbell has Doorbell label and YAMNet mappings', () {
      final category = SoundCategory.doorbell;
      expect(category.label, equals('Doorbell'));
      expect(category.yamnetLabels, contains('Bell ring'));
      expect(category.yamnetLabels, contains('Doorbell'));
      expect(category.yamnetLabels, contains('Chime'));
      expect(category.yamnetLabels, contains('Jingle bell'));
    });

    test('SoundCategory mappings include expanded AudioSet classes', () {
      expect(SoundCategoryExtension.fromYamnetLabel('Honk'), equals(SoundCategory.vehicleHorn));
      expect(SoundCategoryExtension.fromYamnetLabel('Vehicle horn, car horn, honking'), equals(SoundCategory.vehicleHorn));
      expect(SoundCategoryExtension.fromYamnetLabel('Reversing beeps'), equals(SoundCategory.vehicleHorn));
      expect(SoundCategoryExtension.fromYamnetLabel('Bark'), equals(SoundCategory.dogBarking));
      expect(SoundCategoryExtension.fromYamnetLabel('Canidae, dogs, wolves'), equals(SoundCategory.dogBarking));
      expect(SoundCategoryExtension.fromYamnetLabel('Whimper (dog)'), equals(SoundCategory.dogBarking));
      expect(SoundCategoryExtension.fromYamnetLabel('Growling'), equals(SoundCategory.dogBarking));
      expect(SoundCategoryExtension.fromYamnetLabel('Breaking'), equals(SoundCategory.glassBreaking));
      expect(SoundCategoryExtension.fromYamnetLabel('Bicycle bell'), equals(SoundCategory.doorbell));
    });
  });
}
