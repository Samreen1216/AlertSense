import 'dart:math';
import 'package:flutter/foundation.dart';
import '../core/constants/sound_categories.dart';
import '../data/models/classification_result.dart';

/// Pure-Dart acoustic DSP classifier.
///
/// Computes spectral features (FFT + sub-band energy + ZCR + RMS) on each
/// 15,600-sample PCM window and maps them to a [SoundCategory].
/// No native dependencies — works purely in the Dart VM.
class AcousticDspAnalyzer {
  const AcousticDspAnalyzer();

  static const int _sampleRate = 16000;
  static const int _fftSize = 1024;
  static const double _binHz = _sampleRate / _fftSize; // 15.625 Hz/bin

  /// Asynchronously offloads heavy acoustic DSP computation (FFT magnitude spectrum,
  /// Hann windowing, multi-frame active window hop scanning, ZCR) to a background
  /// isolate via [compute] so the main UI thread never suffers frame drops or stutter.
  ///
  /// Gracefully falls back to synchronous [classify] if background isolates are restricted
  /// (e.g., in certain test environments or single-threaded runtimes).
  Future<ClassificationResult?> classifyAsync(List<double> audioData) async {
    try {
      return await compute(_isolateClassifierWorker, audioData);
    } catch (e) {
      debugPrint('[DSP] Background isolate failed or restricted ($e). Falling back to synchronous classification.');
      return classify(audioData);
    }
  }

  /// Static entrypoint executed inside the background isolate.
  static ClassificationResult? _isolateClassifierWorker(List<double> audioData) {
    return const AcousticDspAnalyzer().classify(audioData);
  }

  ClassificationResult? classify(List<double> audioData) {
    if (audioData.length < _fftSize) return null;
    final overallRms = _calculateRms(audioData);
    if (overallRms.isNaN || overallRms.isInfinite || overallRms < 0.003) return null;
    final dbLevel = _rmsToDb(overallRms);

    // 1. Multi-frame active window selection:
    // Scan across audio window to locate the frame containing the peak sound event
    int bestStart = 0;
    double maxFrameRms = 0.0;
    const hopSize = _fftSize ~/ 2; // 512 samples = 32ms hop

    for (int i = 0; i <= audioData.length - _fftSize; i += hopSize) {
      final frame = audioData.sublist(i, i + _fftSize);
      final r = _calculateRms(frame);
      if (r > maxFrameRms) {
        maxFrameRms = r;
        bestStart = i;
      }
    }

    if (maxFrameRms.isNaN || maxFrameRms.isInfinite || maxFrameRms < 0.005) return null;

    final activeSamples = audioData.sublist(bestStart, bestStart + _fftSize);

    // 2. Apply Hann window to eliminate spectral leakage
    final windowed = List<double>.generate(_fftSize, (i) {
      final w = 0.5 * (1.0 - cos(2.0 * pi * i / (_fftSize - 1)));
      return activeSamples[i] * w;
    });

    final zcr = _calculateZcr(activeSamples);
    final magnitude = _fftMagnitude(windowed);
    final totalEnergy = magnitude.fold(0.0, (sum, m) => sum + m * m);
    if (totalEnergy == 0) return null;

    final eLow = _bandEnergy(magnitude, 0, 51) / totalEnergy;
    final eMid = _bandEnergy(magnitude, 51, 128) / totalEnergy;
    final eHigh = _bandEnergy(magnitude, 128, 256) / totalEnergy;
    final eVeryHigh = _bandEnergy(magnitude, 256, 512) / totalEnergy;
    final centroid = _spectralCentroid(magnitude);
    final flatness = _spectralFlatness(magnitude);
    final peakHz = _dominantFrequency(magnitude);

    final avgMag = magnitude.fold(0.0, (s, m) => s + m) / magnitude.length;
    final peakMag = magnitude.fold(0.0, max);
    final peakProminence = avgMag > 0 ? (peakMag / avgMag) : 1.0;

    debugPrint('[DSP] rms=${overallRms.toStringAsFixed(3)} frameRms=${maxFrameRms.toStringAsFixed(3)} db=${dbLevel.toStringAsFixed(1)} '
        'zcr=${zcr.toStringAsFixed(3)} centroid=${centroid.toStringAsFixed(0)} '
        'peak=${peakHz.toStringAsFixed(0)} flat=${flatness.toStringAsFixed(2)} '
        'prom=${peakProminence.toStringAsFixed(1)}');

    return _classify(
      rms: maxFrameRms,
      overallRms: overallRms,
      zcr: zcr,
      eLow: eLow,
      eMid: eMid,
      eHigh: eHigh,
      eVeryHigh: eVeryHigh,
      centroid: centroid,
      flatness: flatness,
      peakHz: peakHz,
      peakProminence: peakProminence,
      dbLevel: dbLevel,
    );
  }

  ClassificationResult? _classify({
    required double rms,
    required double overallRms,
    required double zcr,
    required double eLow,
    required double eMid,
    required double eHigh,
    required double eVeryHigh,
    required double centroid,
    required double flatness,
    required double peakHz,
    required double peakProminence,
    required double dbLevel,
  }) {
    SoundCategory? category;
    double confidence = 0.0;

    // 1. Smoke Alarm: very high-pitched ~3300-4800 Hz pure tone
    if (peakHz >= 3300 && peakHz <= 4800 && eVeryHigh > 0.28 && flatness < 0.35 && zcr < 0.25) {
      category = SoundCategory.smokeAlarm;
      confidence = _mapConfidence(eVeryHigh, 0.28, 0.65, base: 0.75, maxConf: 0.95);
    }
    // 2. Fire Alarm: ~2850-3350 Hz continuous/pulsing loud tonal alarm
    else if (peakHz >= 2850 && peakHz <= 3350 && eHigh > 0.38 && flatness < 0.35 && rms > 0.04) {
      category = SoundCategory.fireAlarm;
      confidence = _mapConfidence(eHigh, 0.38, 0.75, base: 0.76, maxConf: 0.95);
    }
    // 3. Vehicle Horn: low-mid tonal honk (200-750 Hz)
    // Vehicle horns typically have fundamental frequency between 250 Hz and 700 Hz (e.g. dual tone F4/A4 ~350/440 Hz)
    // with strong low/mid energy and harmonic flatness < 0.45.
    // Evaluated BEFORE general bell/doorbell so low-mid vehicle horns are never misclassified as doorbell!
    else if (peakHz >= 200 && peakHz <= 750 && (eLow > 0.24 || (eLow + eMid) > 0.48) && flatness < 0.45 && rms > 0.025 && (overallRms / rms) >= 0.38) {
      category = SoundCategory.vehicleHorn;
      confidence = _mapConfidence(eLow + eMid * 0.4, 0.24, 0.70, base: 0.80, maxConf: 0.96);
    }
    // 4. Bell Ring / Doorbell / Chime:
    // Pure harmonic decaying tone in 600 Hz to 3200 Hz range with low spectral flatness & strong peak prominence
    else if (peakHz >= 600 && peakHz <= 3200 && (flatness < 0.48 || peakProminence > 3.0) && zcr < 0.35) {
      category = SoundCategory.doorbell;
      final promScore = (peakProminence / 8.0).clamp(0.0, 1.0);
      final flatnessScore = (1.0 - (flatness / 0.50)).clamp(0.0, 1.0);
      confidence = (0.76 + 0.12 * promScore + 0.10 * flatnessScore).clamp(0.76, 0.96);
    }
    // 5. Knocking: low-frequency percussive impulse burst
    else if (eLow > 0.25 && peakHz < 950 && centroid < 1200 && zcr < 0.22 && rms > 0.012) {
      category = SoundCategory.knocking;
      confidence = _mapConfidence(eLow + (1.0 - zcr) * 0.1, 0.25, 0.75, base: 0.76, maxConf: 0.95);
    }
    // 6. Siren: sweeping pitch, mid-high energy, sustained
    else if (centroid > 1100 && centroid < 3500 && (eMid + eHigh) > 0.42 && flatness < 0.55 && rms > 0.03) {
      category = SoundCategory.emergencySiren;
      confidence = _mapConfidence(eMid + eHigh, 0.42, 0.80, base: 0.76, maxConf: 0.95);
    }
    // 7. Glass Breaking: high ZCR, very high freq, impulsive noisy
    else if ((centroid > 1800 || peakHz > 2200) && zcr > 0.15 && (eHigh + eVeryHigh > 0.22 || (eMid + eHigh + eVeryHigh) > 0.55) && flatness > 0.22 && rms > 0.015) {
      category = SoundCategory.glassBreaking;
      confidence = _mapConfidence((eHigh + eVeryHigh) * (flatness + 0.3), 0.10, 0.55, base: 0.80, maxConf: 0.96);
    }
    // 8. Baby Crying: mid-high harmonic vocal cries
    else if (centroid > 700 && centroid < 2400 && eMid > 0.28 && zcr > 0.10 && zcr < 0.35 && rms > 0.018) {
      category = SoundCategory.babyCrying;
      confidence = _mapConfidence(eMid, 0.28, 0.60, base: 0.72, maxConf: 0.95);
    }
    // 9. Dog Barking: mid burst pattern with broad harmonic spectrum
    // Dog barks have fundamental around 250-1000 Hz, centroid 350-3200 Hz, burst energy in low-mid
    else if (centroid > 350 && centroid < 3200 && (eMid + eLow) > 0.35 && zcr > 0.04 && zcr < 0.32 && rms > 0.015) {
      category = SoundCategory.dogBarking;
      confidence = _mapConfidence(eMid + eLow, 0.35, 0.80, base: 0.80, maxConf: 0.96);
    }

    if (category == null) return null;

    return ClassificationResult(
      soundCategory: category.name,
      confidence: confidence.clamp(0.50, 0.98),
      timestamp: DateTime.now(),
      topPredictions: [MapEntry(category.yamnetLabels.first, confidence)],
      ambientDbLevel: dbLevel,
    );
  }

  double _calculateRms(List<double> samples) {
    if (samples.isEmpty) return 0.0;
    double sum = 0.0;
    for (final s in samples) { sum += s * s; }
    return sqrt(sum / samples.length);
  }

  double _rmsToDb(double rms) {
    if (rms <= 0) return 0.0;
    return (20 * log(rms) / ln10 + 90).clamp(0.0, 120.0);
  }

  double _calculateZcr(List<double> samples) {
    if (samples.length < 2) return 0.0;
    int crossings = 0;
    for (int i = 1; i < samples.length; i++) {
      if ((samples[i] >= 0) != (samples[i - 1] >= 0)) crossings++;
    }
    return crossings / samples.length;
  }

  List<double> _fftMagnitude(List<double> x) {
    final n = x.length;
    final real = List<double>.from(x);
    final imag = List<double>.filled(n, 0.0);
    // Bit-reversal
    int j = 0;
    for (int i = 1; i < n; i++) {
      int bit = n >> 1;
      while (j & bit != 0) { j ^= bit; bit >>= 1; }
      j ^= bit;
      if (i < j) {
        final tr = real[i]; real[i] = real[j]; real[j] = tr;
        final ti = imag[i]; imag[i] = imag[j]; imag[j] = ti;
      }
    }
    // Butterfly
    for (int len = 2; len <= n; len <<= 1) {
      final ang = -2 * pi / len;
      final wR = cos(ang); final wI = sin(ang);
      for (int i = 0; i < n; i += len) {
        double cR = 1.0, cI = 0.0;
        for (int k = 0; k < len ~/ 2; k++) {
          final uR = real[i + k]; final uI = imag[i + k];
          final half = i + k + len ~/ 2;
          final vR = real[half] * cR - imag[half] * cI;
          final vI = real[half] * cI + imag[half] * cR;
          real[i + k] = uR + vR; imag[i + k] = uI + vI;
          real[half] = uR - vR; imag[half] = uI - vI;
          final newCR = cR * wR - cI * wI;
          cI = cR * wI + cI * wR; cR = newCR;
        }
      }
    }
    return List.generate(n ~/ 2, (k) => sqrt(real[k] * real[k] + imag[k] * imag[k]));
  }

  double _bandEnergy(List<double> mag, int start, int end) {
    double e = 0.0;
    final endIdx = end.clamp(0, mag.length);
    for (int i = start; i < endIdx; i++) { e += mag[i] * mag[i]; }
    return e;
  }

  double _spectralCentroid(List<double> mag) {
    double wSum = 0.0, mSum = 0.0;
    for (int i = 0; i < mag.length; i++) {
      wSum += i * _binHz * mag[i]; mSum += mag[i];
    }
    return mSum > 0 ? wSum / mSum : 0.0;
  }

  double _spectralFlatness(List<double> mag) {
    if (mag.isEmpty) return 0.0;
    double logSum = 0.0, arithSum = 0.0; int nonZero = 0;
    for (final m in mag) {
      if (m > 0) { logSum += log(m); nonZero++; }
      arithSum += m;
    }
    if (nonZero == 0 || arithSum == 0) return 0.0;
    final geo = exp(logSum / nonZero);
    final arith = arithSum / mag.length;
    return (geo / arith).clamp(0.0, 1.0);
  }

  double _dominantFrequency(List<double> mag) {
    if (mag.isEmpty) return 0.0;
    int peak = 0; double peakMag = 0.0;
    for (int i = 1; i < mag.length; i++) {
      if (mag[i] > peakMag) { peakMag = mag[i]; peak = i; }
    }
    return peak * _binHz;
  }

  double _mapConfidence(
    double value,
    double min,
    double max, {
    double base = 0.76,
    double maxConf = 0.96,
  }) {
    final t = ((value - min) / (max - min)).clamp(0.0, 1.0);
    return (base + t * (maxConf - base)).clamp(base, maxConf);
  }
}
