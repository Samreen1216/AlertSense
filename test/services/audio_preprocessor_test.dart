import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:alertsense/services/audio_preprocessor.dart';

void main() {
  group('AudioPreprocessor Tests', () {
    test('pcm16ToFloat32 accurately normalizes signed 16-bit PCM bytes to [-1.0, 1.0]', () {
      final byteData = ByteData(8);
      // Sample 0: 0
      byteData.setInt16(0, 0, Endian.little);
      // Sample 1: 32767 (max positive)
      byteData.setInt16(2, 32767, Endian.little);
      // Sample 2: -32768 (min negative)
      byteData.setInt16(4, -32768, Endian.little);
      // Sample 3: 16384 (half scale)
      byteData.setInt16(6, 16384, Endian.little);

      final floats = AudioPreprocessor.pcm16ToFloat32(byteData.buffer.asUint8List());

      expect(floats.length, equals(4));
      expect(floats[0], equals(0.0));
      expect(floats[1], closeTo(32767 / 32768.0, 0.0001));
      expect(floats[2], equals(-1.0));
      expect(floats[3], equals(0.5));
    });

    test('stereoToMono averages interleaved channels and preserves mono', () {
      // 1 channel pass-through
      final monoInput = [0.2, -0.4, 0.8];
      expect(AudioPreprocessor.stereoToMono(monoInput, numChannels: 1), equals(monoInput));

      // 2 channels: L0, R0, L1, R1
      final stereoInput = [0.4, 0.6, -0.2, 0.6, 1.0, 1.0];
      final mono = AudioPreprocessor.stereoToMono(stereoInput, numChannels: 2);

      expect(mono.length, equals(3));
      expect(mono[0], closeTo(0.5, 0.0001));
      expect(mono[1], closeTo(0.2, 0.0001));
      expect(mono[2], closeTo(1.0, 0.0001));
    });

    test('resample handles 48 kHz to 16 kHz 3:1 integer decimation correctly', () {
      // 48 kHz input with 6 samples: should become 2 samples at 16 kHz
      final input48k = [0.1, 0.2, 0.3, 0.4, 0.5, 0.6];
      final resampled = AudioPreprocessor.resample(
        input48k,
        inputSampleRate: 48000,
        outputSampleRate: 16000,
      );

      expect(resampled.length, equals(2));
      // First output sample: (0.1 + 0.2 + 0.3) / 3 = 0.2
      expect(resampled[0], closeTo(0.2, 0.0001));
      // Second output sample: (0.4 + 0.5 + 0.6) / 3 = 0.5
      expect(resampled[1], closeTo(0.5, 0.0001));
    });

    test('resample handles 44.1 kHz to 16 kHz non-integer linear interpolation', () {
      // 44,100 samples (1 second) at 44.1 kHz
      final input44k = List<double>.generate(44100, (i) => (i % 100) / 100.0);
      final resampled = AudioPreprocessor.resample(
        input44k,
        inputSampleRate: 44100,
        outputSampleRate: 16000,
      );

      // Should produce exactly 16,000 samples (+/- 1)
      expect(resampled.length, closeTo(16000, 2));
      for (final s in resampled) {
        expect(s >= -1.0 && s <= 1.0, isTrue);
      }
    });

    test('resample passes through identical sample rates without distortion', () {
      final input = [0.1, -0.2, 0.3];
      final output = AudioPreprocessor.resample(input, inputSampleRate: 16000, outputSampleRate: 16000);
      expect(output, equals(input));
    });

    test('AudioWindowBuffer collects incoming samples and dispenses exact 15,600 windows', () {
      final buffer = AudioWindowBuffer(windowSize: 15600);
      expect(buffer.hasWindow, isFalse);
      expect(buffer.nextWindow(), isNull);

      // Add 10,000 samples: not yet ready
      buffer.addSamples(List<double>.filled(10000, 0.1));
      expect(buffer.hasWindow, isFalse);
      expect(buffer.availableSamples, equals(10000));

      // Add 10,000 more samples: total 20,000 (>= 15,600)
      buffer.addSamples(List<double>.filled(10000, 0.2));
      expect(buffer.hasWindow, isTrue);

      // Extract window
      final w1 = buffer.nextWindow();
      expect(w1, isNotNull);
      expect(w1!.length, equals(15600));
      expect(w1.first, equals(0.1));

      // Remainder: 4,400 samples
      expect(buffer.hasWindow, isFalse);
      expect(buffer.availableSamples, equals(4400));

      buffer.clear();
      expect(buffer.availableSamples, equals(0));
    });

    test('processIncomingPcm performs complete pipeline from 48 kHz stereo PCM to 16 kHz mono floats', () {
      const numFrames48k = 6;
      final byteData = ByteData(numFrames48k * 2 * 2); // 6 frames * 2 channels * 2 bytes = 24 bytes

      // Create interleaved stereo PCM16 data
      for (int i = 0; i < numFrames48k; i++) {
        byteData.setInt16(i * 4, 16384, Endian.little); // L = 0.5
        byteData.setInt16(i * 4 + 2, 16384, Endian.little); // R = 0.5
      }

      final processed = AudioPreprocessor.processIncomingPcm(
        pcmBytes: byteData.buffer.asUint8List(),
        inputSampleRate: 48000,
        numChannels: 2,
      );

      // 6 frames at 48 kHz -> 2 frames at 16 kHz
      expect(processed.length, equals(2));
      expect(processed[0], closeTo(0.5, 0.0001));
      expect(processed[1], closeTo(0.5, 0.0001));
    });
  });
}
