import 'dart:math';
import 'dart:typed_data';

/// High-fidelity audio preprocessing utilities for YAMNet audio recognition.
///
/// Ensures audio fed into neural network inference strictly matches:
/// - Sample rate: 16,000 Hz
/// - Channels: Mono (1 channel)
/// - Format: Float32 in range [-1.0, 1.0]
/// - Window size: Exactly 15,600 samples (0.975 seconds)
class AudioPreprocessor {
  static const int targetSampleRate = 16000;
  static const int targetWindowSamples = 15600;

  /// Converts signed 16-bit linear PCM bytes (little-endian) into normalized float32 samples.
  ///
  /// Output samples are guaranteed to be clamped within `[-1.0, 1.0]`.
  static List<double> pcm16ToFloat32(Uint8List pcmBytes) {
    if (pcmBytes.length < 2) return const [];

    final byteData = ByteData.sublistView(pcmBytes);
    final numSamples = pcmBytes.length ~/ 2;
    final samples = List<double>.filled(numSamples, 0.0);

    for (int i = 0; i < numSamples; i++) {
      final rawInt16 = byteData.getInt16(i * 2, Endian.little);
      samples[i] = (rawInt16 / 32768.0).clamp(-1.0, 1.0);
    }

    return samples;
  }

  /// Converts interleaved stereo or multi-channel audio to mono by averaging channels.
  static List<double> stereoToMono(List<double> interleavedSamples, {int numChannels = 2}) {
    if (numChannels <= 1) return interleavedSamples;
    if (interleavedSamples.isEmpty) return const [];

    final monoLength = interleavedSamples.length ~/ numChannels;
    final monoSamples = List<double>.filled(monoLength, 0.0);

    for (int i = 0; i < monoLength; i++) {
      double sum = 0.0;
      final offset = i * numChannels;
      for (int ch = 0; ch < numChannels; ch++) {
        sum += interleavedSamples[offset + ch];
      }
      monoSamples[i] = (sum / numChannels).clamp(-1.0, 1.0);
    }

    return monoSamples;
  }

  /// Resample audio from [inputSampleRate] to [targetSampleRate] (16,000 Hz).
  ///
  /// Uses decimation with anti-aliasing boxcar averaging for integer ratios (e.g. 48 kHz -> 16 kHz),
  /// and linear interpolation for non-integer ratios (e.g. 44.1 kHz -> 16 kHz).
  static List<double> resample(
    List<double> input, {
    required int inputSampleRate,
    int outputSampleRate = targetSampleRate,
  }) {
    if (input.isEmpty) return const [];
    if (inputSampleRate == outputSampleRate) return List<double>.from(input);

    // Exact integer decimation (e.g. 48,000 Hz -> 16,000 Hz = 3:1)
    if (inputSampleRate > outputSampleRate && inputSampleRate % outputSampleRate == 0) {
      final ratio = inputSampleRate ~/ outputSampleRate;
      final outLength = input.length ~/ ratio;
      final output = List<double>.filled(outLength, 0.0);

      for (int i = 0; i < outLength; i++) {
        double sum = 0.0;
        final startIdx = i * ratio;
        for (int r = 0; r < ratio; r++) {
          sum += input[startIdx + r];
        }
        output[i] = (sum / ratio).clamp(-1.0, 1.0);
      }
      return output;
    }

    // General linear interpolation resampling (e.g. 44,100 Hz -> 16,000 Hz)
    final ratio = inputSampleRate / outputSampleRate;
    final outLength = (input.length / ratio).floor();
    if (outLength <= 0) return const [];

    final output = List<double>.filled(outLength, 0.0);

    for (int i = 0; i < outLength; i++) {
      final srcPos = i * ratio;
      final srcIdx = srcPos.floor();
      final frac = srcPos - srcIdx;

      if (srcIdx + 1 < input.length) {
        output[i] = (input[srcIdx] * (1.0 - frac) + input[srcIdx + 1] * frac).clamp(-1.0, 1.0);
      } else if (srcIdx < input.length) {
        output[i] = input[srcIdx].clamp(-1.0, 1.0);
      }
    }

    return output;
  }

  /// Complete end-to-end preprocessing pipeline from raw incoming microphone PCM data.
  static List<double> processIncomingPcm({
    required Uint8List pcmBytes,
    required int inputSampleRate,
    required int numChannels,
  }) {
    // 1. Convert PCM16 to float32 [-1.0, 1.0]
    var samples = pcm16ToFloat32(pcmBytes);

    // 2. Mix multi-channel to mono
    if (numChannels > 1) {
      samples = stereoToMono(samples, numChannels: numChannels);
    }

    // 3. Resample to 16,000 Hz if needed
    if (inputSampleRate != targetSampleRate) {
      samples = resample(samples, inputSampleRate: inputSampleRate, outputSampleRate: targetSampleRate);
    }

    return samples;
  }
}

/// Streaming FIFO audio buffer that assembles continuous samples into 15,600-sample windows.
class AudioWindowBuffer {
  final int windowSize;
  final List<double> _buffer = [];

  AudioWindowBuffer({this.windowSize = AudioPreprocessor.targetWindowSamples});

  int get availableSamples => _buffer.length;

  /// Ingest newly processed 16 kHz mono float32 audio samples.
  void addSamples(List<double> samples) {
    _buffer.addAll(samples);
  }

  /// Whether at least one full window is available for classification.
  bool get hasWindow => _buffer.length >= windowSize;

  /// Extract the next non-overlapping 15,600-sample window, or `null` if buffer has insufficient data.
  List<double>? nextWindow() {
    if (!hasWindow) return null;
    final window = _buffer.sublist(0, windowSize);
    _buffer.removeRange(0, windowSize);
    return window;
  }

  /// Reset and empty the buffer.
  void clear() {
    _buffer.clear();
  }
}
