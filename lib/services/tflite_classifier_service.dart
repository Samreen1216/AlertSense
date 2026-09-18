import 'package:flutter/foundation.dart';
import '../data/models/classification_result.dart';
import 'acoustic_dsp_analyzer.dart';

/// Audio classifier that uses the [AcousticDspAnalyzer] (pure-Dart FFT).
/// Drop-in replacement for the YAMNet TFLite classifier.
class TFLiteClassifierService {
  final AcousticDspAnalyzer _analyzer = AcousticDspAnalyzer();
  bool _isLoaded = false;

  bool get isLoaded => _isLoaded;

  Future<void> loadModel() async {
    if (_isLoaded) return;
    // DSP analyzer needs no model file — just mark ready
    _isLoaded = true;
    debugPrint('[Classifier] Acoustic DSP analyzer ready');
  }

  ClassificationResult? classify(List<double> audioData) {
    if (!_isLoaded) {
      debugPrint('[Classifier] Not loaded!');
      return null;
    }
    return _analyzer.classify(audioData);
  }

  double getThreshold(String categoryName) => 0.60;

  void dispose() {
    _isLoaded = false;
    debugPrint('[Classifier] Disposed');
  }
}
