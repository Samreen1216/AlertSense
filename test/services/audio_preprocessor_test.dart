import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:alertsense/services/audio_preprocessor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('AudioPreprocessor.pcm16ToFloat32', () {
    /// Verifies PCM16 byte arrays are converted to Float32 [-1.0, 1.0]
    test('Empty bytes (<2 bytes) returns empty list', () {
      expect(AudioPreprocessor.pcm16ToFloat32(Uint8List(0)), isEmpty);
      expect(AudioPreprocessor.pcm16ToFloat32(Uint8List(1)), isEmpty);
    });

    test('Silence (0x0000) converts to 0.0', () {
      final bytes = Uint8List.fromList([0x00, 0x00]);
      final floats = AudioPreprocessor.pcm16ToFloat32(bytes);
      expect(floats, [0.0]);
    });

    test('Max positive (0x7FFF = 32767) converts to ~1.0 (32767/32768)', () {
      // Little endian 0x7FFF -> [0xFF, 0x7F]
      final bytes = Uint8List.fromList([0xFF, 0x7F]);
      final floats = AudioPreprocessor.pcm16ToFloat32(bytes);
      expect(floats[0], closeTo(32767 / 32768.0, 1e-6));
    });

    test('Max negative (0x8000 = -32768) converts to -1.0', () {
      // Little endian 0x8000 -> [0x00, 0x80]
      final bytes = Uint8List.fromList([0x00, 0x80]);
      final floats = AudioPreprocessor.pcm16ToFloat32(bytes);
      expect(floats[0], -1.0);
    });

    test('Mid-range values convert correctly', () {
      // 16384 -> [0x00, 0x40]
      final bytes = Uint8List.fromList([0x00, 0x40]);
      final floats = AudioPreprocessor.pcm16ToFloat32(bytes);
      expect(floats[0], 0.5);
    });

    test('Odd byte count truncates last incomplete sample', () {
      // 3 bytes, should only process the first 2 bytes
      final bytes = Uint8List.fromList([0x00, 0x40, 0xFF]);
      final floats = AudioPreprocessor.pcm16ToFloat32(bytes);
      expect(floats.length, 1);
      expect(floats[0], 0.5);
    });
  });

  group('AudioPreprocessor.stereoToMono', () {
    /// Verifies stereo or multi-channel floats are averaged to mono
    test('Single channel input returned as-is', () {
      final input = [0.1, 0.2, 0.3];
      expect(AudioPreprocessor.stereoToMono(input, numChannels: 1), input);
    });

    test('Stereo [L, R, L, R] averages to [(L+R)/2, (L+R)/2]', () {
      final input = [0.2, 0.4, 0.6, 0.8];
      final result = AudioPreprocessor.stereoToMono(input, numChannels: 2);
      expect(result[0], closeTo(0.3, 1e-6));
      expect(result[1], closeTo(0.7, 1e-6));
    });

    test('Empty input returns empty', () {
      expect(AudioPreprocessor.stereoToMono([], numChannels: 2), isEmpty);
    });

    test('Identical channels: [0.5, 0.5, 0.8, 0.8] → [0.5, 0.8]', () {
      final input = [0.5, 0.5, 0.8, 0.8];
      final expected = [0.5, 0.8];
      expect(AudioPreprocessor.stereoToMono(input, numChannels: 2), expected);
    });

    test('Opposite channels: [1.0, -1.0, 1.0, -1.0] → [0.0, 0.0]', () {
      final input = [1.0, -1.0, 1.0, -1.0];
      final expected = [0.0, 0.0];
      expect(AudioPreprocessor.stereoToMono(input, numChannels: 2), expected);
    });
  });

  group('AudioPreprocessor.resample - Same Rate', () {
    /// Verifies resampling with same rate returns identical output
    test('Same rate returns copy of input', () {
      final input = [0.1, 0.2, 0.3];
      final output = AudioPreprocessor.resample(
        input,
        inputSampleRate: 16000,
        outputSampleRate: 16000,
      );
      expect(output, input);
      expect(identical(output, input), false, reason: 'Should return a new list copy');
    });
  });

  group('AudioPreprocessor.resample - Integer Decimation', () {
    /// Verifies decimation by integer ratios (e.g. 48kHz -> 16kHz)
    test('6 samples at 48kHz → 2 samples at 16kHz (averaged in groups of 3)', () {
      final input = [0.3, 0.6, 0.9, 0.1, 0.2, 0.3];
      final output = AudioPreprocessor.resample(
        input,
        inputSampleRate: 48000,
        outputSampleRate: 16000,
      );
      expect(output.length, 2);
      expect(output[0], closeTo(0.6, 1e-6)); // (0.3+0.6+0.9)/3
      expect(output[1], closeTo(0.2, 1e-6)); // (0.1+0.2+0.3)/3
    });
  });

  group('AudioPreprocessor.resample - Linear Interpolation', () {
    /// Verifies non-integer resampling ratios (e.g. 44.1kHz -> 16kHz)
    test('Verify output length and interpolated values (44.1kHz → 16kHz)', () {
      final input = List<double>.generate(441, (i) => i / 441.0);
      final output = AudioPreprocessor.resample(
        input,
        inputSampleRate: 44100,
        outputSampleRate: 16000,
      );
      
      final expectedLength = (441 * 16000 / 44100).floor(); // 160
      expect(output.length, expectedLength);
      
      // Check a few points
      expect(output.first, 0.0);
      expect(output.last, closeTo(output.length / 160.0, 0.1));
    });
  });

  group('AudioPreprocessor.resample - Edge Cases', () {
    /// Verifies resampling edge cases
    test('Empty input returns empty', () {
      expect(
        AudioPreprocessor.resample([], inputSampleRate: 48000, outputSampleRate: 16000),
        isEmpty,
      );
    });

    test('Single sample input', () {
      final input = [0.5];
      final output = AudioPreprocessor.resample(
        input,
        inputSampleRate: 48000,
        outputSampleRate: 16000,
      );
      // Since it's integer decimation 3:1, but length is 1, length/3 = 0.
      expect(output, isEmpty);
      
      final outputLinear = AudioPreprocessor.resample(
        input,
        inputSampleRate: 44100,
        outputSampleRate: 16000,
      );
      expect(outputLinear, isEmpty);
    });

    test('Zero or negative sample rate returns empty list without error', () {
      final input = [0.1, 0.2, 0.3];
      expect(AudioPreprocessor.resample(input, inputSampleRate: 0, outputSampleRate: 16000), isEmpty);
      expect(AudioPreprocessor.resample(input, inputSampleRate: 16000, outputSampleRate: 0), isEmpty);
      expect(AudioPreprocessor.resample(input, inputSampleRate: -1, outputSampleRate: 16000), isEmpty);
    });
  });

  group('AudioPreprocessor.processIncomingPcm Full Pipeline', () {
    /// Verifies the full PCM processing pipeline (bytes -> float -> mono -> resample)
    test('Mono 16kHz input: just converts PCM16 to float32', () {
      final bytes = Uint8List.fromList([0x00, 0x40, 0x00, 0x80]); // 0.5, -1.0
      final result = AudioPreprocessor.processIncomingPcm(
        pcmBytes: bytes,
        inputSampleRate: 16000,
        numChannels: 1,
      );
      expect(result, [0.5, -1.0]);
    });

    test('Stereo 48kHz input: converts, mixes to mono, resamples', () {
      // 6 stereo samples = 12 floats = 24 bytes
      // Values: [0.3, 0.3, 0.6, 0.6, 0.9, 0.9, 0.1, 0.1, 0.2, 0.2, 0.3, 0.3]
      // Float to Int16:
      // 0.3 -> 9830
      // 0.6 -> 19661
      // 0.9 -> 29491
      // 0.1 -> 3277
      // 0.2 -> 6554
      
      final byteData = ByteData(24);
      final floats = [0.3, 0.3, 0.6, 0.6, 0.9, 0.9, 0.1, 0.1, 0.2, 0.2, 0.3, 0.3];
      for (int i = 0; i < 12; i++) {
        byteData.setInt16(i * 2, (floats[i] * 32768.0).round(), Endian.little);
      }
      
      final result = AudioPreprocessor.processIncomingPcm(
        pcmBytes: byteData.buffer.asUint8List(),
        inputSampleRate: 48000,
        numChannels: 2,
      );
      
      // 6 stereo -> 6 mono -> 3:1 decimation -> 2 samples
      // First mono group: [0.3, 0.6, 0.9] -> avg: 0.6
      // Second mono group: [0.1, 0.2, 0.3] -> avg: 0.2
      expect(result.length, 2);
      expect(result[0], closeTo(0.6, 1e-3));
      expect(result[1], closeTo(0.2, 1e-3));
    });
  });

  group('AudioWindowBuffer', () {
    /// Verifies buffering and windowing of audio samples
    late AudioWindowBuffer buffer;

    setUp(() {
      buffer = AudioWindowBuffer(windowSize: 4, hopSize: 4);
    });

    test('New buffer has 0 availableSamples and hasWindow=false', () {
      expect(buffer.availableSamples, 0);
      expect(buffer.hasWindow, isFalse);
    });

    test('Adding < windowSize samples: hasWindow still false', () {
      buffer.addSamples([0.1, 0.2]);
      expect(buffer.availableSamples, 2);
      expect(buffer.hasWindow, isFalse);
    });

    test('Adding exactly windowSize samples: hasWindow=true', () {
      buffer.addSamples([0.1, 0.2, 0.3, 0.4]);
      expect(buffer.availableSamples, 4);
      expect(buffer.hasWindow, isTrue);
    });

    test('nextWindow() returns correct window and advances buffer', () {
      buffer.addSamples([0.1, 0.2, 0.3, 0.4, 0.5, 0.6]);
      final window = buffer.nextWindow();
      expect(window, [0.1, 0.2, 0.3, 0.4]);
      expect(buffer.availableSamples, 2); // 6 - 4 = 2 remaining
    });

    test('nextWindow() on empty buffer returns null', () {
      expect(buffer.nextWindow(), isNull);
    });

    test('clear() empties the buffer', () {
      buffer.addSamples([0.1, 0.2]);
      buffer.clear();
      expect(buffer.availableSamples, 0);
    });

    test('hopSize < windowSize creates overlapping windows', () {
      final overlapBuffer = AudioWindowBuffer(windowSize: 4, hopSize: 2);
      overlapBuffer.addSamples([0.1, 0.2, 0.3, 0.4, 0.5, 0.6]);
      
      final window1 = overlapBuffer.nextWindow();
      expect(window1, [0.1, 0.2, 0.3, 0.4]);
      expect(overlapBuffer.availableSamples, 4); // 6 - 2 = 4 remaining
      
      final window2 = overlapBuffer.nextWindow();
      expect(window2, [0.3, 0.4, 0.5, 0.6]); // Overlaps by 2 samples
      expect(overlapBuffer.availableSamples, 2); // 4 - 2 = 2 remaining
    });
  });

  group('AudioPreprocessor.processIncomingPcmAsync (Background Isolate)', () {
    test('Processes PCM16 mono bytes to normalized Float32 on isolate', () async {
      // 16 kHz mono, 4 samples: [0, 16384, -16384, 32767]
      final bytes = Uint8List.fromList([
        0x00, 0x00, // 0
        0x00, 0x40, // 16384 -> 0.5
        0x00, 0xC0, // -16384 -> -0.5
        0xFF, 0x7F, // 32767 -> ~1.0
      ]);

      final result = await AudioPreprocessor.processIncomingPcmAsync(
        pcmBytes: bytes,
        inputSampleRate: 16000,
        numChannels: 1,
      );

      expect(result.length, 4);
      expect(result[0], 0.0);
      expect(result[1], 0.5);
      expect(result[2], -0.5);
      expect(result[3], closeTo(1.0, 1e-4));
    });

    test('Downmixes stereo and resamples 48 kHz to 16 kHz on isolate', () async {
      // 48 kHz stereo (3:1 decimation, 2 channels)
      // 6 frames (12 samples) at 48kHz -> should produce 2 mono samples at 16kHz
      final bytes = Uint8List(24); // 12 samples * 2 bytes
      final view = ByteData.sublistView(bytes);
      for (int i = 0; i < 12; i++) {
        view.setInt16(i * 2, 16384, Endian.little); // all 0.5
      }

      final result = await AudioPreprocessor.processIncomingPcmAsync(
        pcmBytes: bytes,
        inputSampleRate: 48000,
        numChannels: 2,
      );

      expect(result.length, 2);
      expect(result[0], closeTo(0.5, 1e-4));
      expect(result[1], closeTo(0.5, 1e-4));
    });
  });
}
