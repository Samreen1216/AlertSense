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
  static const int _sampleRate = 16000;
  static const int _fftSize = 1024;
  static const double _binHz = _sampleRate / _fftSize; // 15.625 Hz/bin

  ClassificationResult? classify(List<double> audioData) {
    if (audioData.length < _fftSize) return null;
    final rms = _calculateRms(audioData);
    final dbLevel = _rmsToDb(rms);
    if (rms < 0.01) return null;
    final zcr = _calculateZcr(audioData);
    final magnitude = _fftMagnitude(audioData.sublist(0, _fftSize));
    final totalEnergy = magnitude.fold(0.0, (sum, m) => sum + m * m);
    if (totalEnergy == 0) return null;
    final eLow = _bandEnergy(magnitude, 0, 51) / totalEnergy;
    final eMid = _bandEnergy(magnitude, 51, 128) / totalEnergy;
    final eHigh = _bandEnergy(magnitude, 128, 256) / totalEnergy;
    final eVeryHigh = _bandEnergy(magnitude, 256, 512) / totalEnergy;
    final centroid = _spectralCentroid(magnitude);
    final flatness = _spectralFlatness(magnitude);
    final peakHz = _dominantFrequency(magnitude);
    debugPrint('[DSP] rms=${rms.toStringAsFixed(3)} db=${dbLevel.toStringAsFixed(1)} '
        'zcr=${zcr.toStringAsFixed(3)} centroid=${centroid.toStringAsFixed(0)} '
        'peak=${peakHz.toStringAsFixed(0)} flat=${flatness.toStringAsFixed(2)}');
    return _classify(rms: rms, zcr: zcr, eLow: eLow, eMid: eMid,
        eHigh: eHigh, eVeryHigh: eVeryHigh, centroid: centroid,
        flatness: flatness, peakHz: peakHz, dbLevel: dbLevel);
  }

  ClassificationResult _classify({
    required double rms, required double zcr,
    required double eLow, required double eMid,
    required double eHigh, required double eVeryHigh,
    required double centroid, required double flatness,
    required double peakHz, required double dbLevel,
  }) {
    SoundCategory category;
    double confidence;

    // Fire Alarm: ~3150 Hz tonal peak, high eHigh, periodic
    if (peakHz >= 2800 && peakHz <= 3400 && eHigh > 0.35 && flatness < 0.4 && zcr < 0.25) {
      category = SoundCategory.fireAlarm;
      confidence = _mapConfidence(eHigh, 0.35, 0.70);
    }
    // Smoke Alarm: very high-pitched ~3400-4500 Hz pure tone
    else if (peakHz >= 3300 && peakHz <= 4500 && eVeryHigh > 0.30 && flatness < 0.3 && zcr < 0.20) {
      category = SoundCategory.smokeAlarm;
      confidence = _mapConfidence(eVeryHigh, 0.30, 0.65);
    }
    // Siren: sweeping pitch, mid-high energy, sustained
    else if (centroid > 1200 && centroid < 3500 && eMid + eHigh > 0.45 && flatness < 0.55 && rms > 0.08) {
      category = SoundCategory.emergencySiren;
      confidence = _mapConfidence(eMid + eHigh, 0.45, 0.80);
    }
    // Glass Breaking: high ZCR, very high freq, impulsive noisy
    else if (zcr > 0.30 && eVeryHigh > 0.35 && flatness > 0.55 && rms > 0.05) {
      category = SoundCategory.glassBreaking;
      confidence = _mapConfidence(eVeryHigh * flatness, 0.18, 0.50);
    }
    // Dog Barking: broad spectrum, mid dominant
    else if (eMid > 0.35 && eLow > 0.15 && zcr > 0.08 && zcr < 0.22 && flatness > 0.40) {
      category = SoundCategory.dogBarking;
      confidence = _mapConfidence(eMid, 0.35, 0.65);
    }
    // Baby Crying: mid-high sustained
    else if (centroid > 800 && centroid < 2000 && eMid > 0.30 && zcr > 0.15 && zcr < 0.35 && rms > 0.03) {
      category = SoundCategory.babyCrying;
      confidence = _mapConfidence(eMid, 0.30, 0.60);
    }
    // Vehicle Horn: low-mid tonal
    else if (peakHz >= 200 && peakHz <= 700 && eLow > 0.30 && flatness < 0.45 && rms > 0.06) {
      category = SoundCategory.vehicleHorn;
      confidence = _mapConfidence(eLow, 0.30, 0.65);
    }
    // Knocking: percussive low-freq burst
    else if (eLow > 0.40 && eMid > 0.20 && zcr < 0.12 && rms > 0.04) {
      category = SoundCategory.knocking;
      confidence = _mapConfidence(eLow, 0.40, 0.75);
    }
    // Doorbell: tonal ~500-800 Hz
    else if (peakHz >= 400 && peakHz <= 900 && eLow + eMid > 0.45 && flatness < 0.40 && zcr < 0.18) {
      category = SoundCategory.doorbell;
      confidence = _mapConfidence(eLow + eMid, 0.45, 0.80);
    }
    // Fallback
    else {
      if (eHigh + eVeryHigh > 0.50) {
        category = rms > 0.10 ? SoundCategory.glassBreaking : SoundCategory.fireAlarm;
        confidence = 0.55;
      } else if (eLow > 0.45) {
        category = SoundCategory.knocking;
        confidence = 0.52;
      } else {
        category = SoundCategory.dogBarking;
        confidence = 0.50;
      }
    }

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

  double _mapConfidence(double value, double min, double max) {
    final t = ((value - min) / (max - min)).clamp(0.0, 1.0);
    return 0.50 + t * 0.48;
  }
}
