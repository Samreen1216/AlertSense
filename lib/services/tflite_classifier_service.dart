import 'dart:io';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:tflite_flutter/tflite_flutter.dart';
import '../core/constants/sound_categories.dart';
import '../data/models/classification_result.dart';
import 'acoustic_dsp_analyzer.dart';

/// Production-grade audio classifier powered by Google's pretrained YAMNet model.
///
/// Features:
/// - Executes the 521-class AudioSet YAMNet neural network on-device via TensorFlow Lite.
/// - Ingests 15,600 samples (0.975s window at 16 kHz) of audio.
/// - Translates 521 AudioSet class probabilities to AlertSense monitored [SoundCategory].
/// - Includes pure-Dart [AcousticDspAnalyzer] as a seamless fallback if native TFLite
///   is unavailable in the runtime environment.
class TFLiteClassifierService {
  static const String _modelAssetPath = 'assets/models/yamnet.tflite';
  static const String _labelAssetPath = 'assets/labels/yamnet_class_map.csv';
  static const int _requiredSamples = 15600;

  Interpreter? _interpreter;
  final Map<int, String> _labels = {};
  final AcousticDspAnalyzer _analyzer = AcousticDspAnalyzer();

  bool _isLoaded = false;
  bool _isTfLiteReady = false;

  bool get isLoaded => _isLoaded;
  bool get isTfLiteReady => _isTfLiteReady;

  /// Load YAMNet model weights and label dictionary into memory.
  Future<void> loadModel() async {
    if (_isLoaded) return;

    // 1. Load AudioSet class mapping dictionary
    await _loadClassLabels();

    // 2. Load YAMNet TFLite model
    try {
      final options = InterpreterOptions()..threads = 2;
      _interpreter = await Interpreter.fromAsset(_modelAssetPath, options: options);
      _isTfLiteReady = true;
      debugPrint('[Classifier] Pretrained YAMNet model loaded successfully (${_labels.length} classes)');
    } catch (e) {
      debugPrint('[Classifier] YAMNet TFLite initialization note: $e');
      debugPrint('[Classifier] Using verified AcousticDspAnalyzer active engine');
      _isTfLiteReady = false;
    }

    _isLoaded = true;
  }

  /// Parse the 521-class YAMNet CSV map
  Future<void> _loadClassLabels() async {
    String csvContent;
    try {
      csvContent = await rootBundle.loadString(_labelAssetPath);
    } catch (_) {
      final file = File(_labelAssetPath);
      if (file.existsSync()) {
        csvContent = await file.readAsString();
      } else {
        debugPrint('[Classifier] Could not locate $_labelAssetPath');
        return;
      }
    }

    _labels.clear();
    final lines = csvContent.split('\n');
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final firstComma = line.indexOf(',');
      if (firstComma == -1) continue;
      final secondComma = line.indexOf(',', firstComma + 1);
      if (secondComma == -1) continue;

      final idxStr = line.substring(0, firstComma).trim();
      String displayName = line.substring(secondComma + 1).trim();
      if (displayName.startsWith('"') && displayName.endsWith('"')) {
        displayName = displayName.substring(1, displayName.length - 1);
      }

      final index = int.tryParse(idxStr);
      if (index != null) {
        _labels[index] = displayName;
      }
    }
  }

  /// Classify a 16 kHz mono audio buffer.
  ClassificationResult? classify(List<double> audioData) {
    if (!_isLoaded) {
      debugPrint('[Classifier] Model not loaded!');
      return null;
    }

    final rms = _calculateRms(audioData);
    final dbLevel = _rmsToDb(rms);
    if (rms < 0.003) return null; // Silence / ambient baseline

    // 1. Run inference via pretrained YAMNet TFLite model when ready
    if (_isTfLiteReady && _interpreter != null) {
      try {
        final result = _classifyWithYamnet(audioData, dbLevel);
        // Authoritative YAMNet result: if null, no alert sound is present.
        // Do NOT fall back to DSP analyzer when YAMNet is successfully loaded and running!
        return result;
      } catch (e) {
        debugPrint('[Classifier] YAMNet inference exception: $e');
        debugPrint('[Classifier] Falling back to AcousticDspAnalyzer');
      }
    }

    // 2. Pure-Dart acoustic feature analyzer fallback (used ONLY when native TFLite is unavailable)
    return _analyzer.classify(audioData);
  }

  /// Run inference on the YAMNet neural network.
  ClassificationResult? _classifyWithYamnet(List<double> audioData, double dbLevel) {
    // Prepare 15,600 float32 samples clamped to [-1.0, 1.0]
    final inputBuffer = Float32List(_requiredSamples);
    final count = min(audioData.length, _requiredSamples);
    for (int i = 0; i < count; i++) {
      inputBuffer[i] = audioData[i].clamp(-1.0, 1.0);
    }

    // Determine input tensor shape
    final inputShape = _interpreter!.getInputTensors()[0].shape;
    Object input;
    if (inputShape.length == 1) {
      input = inputBuffer;
    } else {
      input = [inputBuffer];
    }

    // Determine output tensor shape (usually [1, 521] or [N, 521])
    final outputShape = _interpreter!.getOutputTensors()[0].shape;
    final numFrames = outputShape.isNotEmpty && outputShape[0] > 0 ? outputShape[0] : 1;
    final numClasses = outputShape.length > 1 ? outputShape[1] : 521;
    final output = List.generate(numFrames, (_) => List<double>.filled(numClasses, 0.0));

    // Execute neural network
    _interpreter!.run(input, output);

    // Pool predictions across frames
    final scores = List<double>.filled(numClasses, 0.0);
    for (int c = 0; c < numClasses; c++) {
      double maxScore = 0.0;
      for (int f = 0; f < numFrames; f++) {
        if (output[f][c] > maxScore) maxScore = output[f][c];
      }
      scores[c] = maxScore;
    }

    // Sort predictions descending
    final List<MapEntry<String, double>> sortedPredictions = [];
    for (int i = 0; i < scores.length; i++) {
      final label = _labels[i] ?? 'Class $i';
      sortedPredictions.add(MapEntry(label, scores[i]));
    }
    sortedPredictions.sort((a, b) => b.value.compareTo(a.value));

    // Expose top 5 raw predictions
    final top5 = sortedPredictions.take(5).toList();

    // Log raw YAMNet debug output
    final logBuf = StringBuffer();
    logBuf.writeln('[YAMNet]');
    for (final pred in top5) {
      logBuf.writeln('Class: ${pred.key}\nScore: ${pred.value.toStringAsFixed(2)}\n');
    }
    debugPrint(logBuf.toString().trim());

    // Inspect top 3-5 predictions for monitored AlertSense categories
    SoundCategory? bestCategory;
    double bestConfidence = 0.0;
    String bestLabel = '';

    for (final pred in top5) {
      final cat = SoundCategoryExtension.fromYamnetLabel(pred.key);
      if (cat != null) {
        // Priority policy: choose higher priority category, or higher score if equal priority
        if (bestCategory == null) {
          bestCategory = cat;
          bestConfidence = pred.value;
          bestLabel = pred.key;
        } else if (cat.defaultPriority.index < bestCategory.defaultPriority.index) {
          // In PriorityLevel enum: high=0, medium=1, low=2 (smaller index is higher priority)
          bestCategory = cat;
          bestConfidence = pred.value;
          bestLabel = pred.key;
        } else if (cat.defaultPriority.index == bestCategory.defaultPriority.index &&
            pred.value > bestConfidence) {
          bestCategory = cat;
          bestConfidence = pred.value;
          bestLabel = pred.key;
        }
      }
    }

    if (bestCategory != null) {
      debugPrint('[Mapping] $bestLabel → ${bestCategory.name} (${bestConfidence.toStringAsFixed(2)})');
      return ClassificationResult(
        soundCategory: bestCategory.name,
        confidence: bestConfidence, // True model probability
        timestamp: DateTime.now(),
        topPredictions: top5,
        ambientDbLevel: dbLevel,
      );
    }

    debugPrint('AlertSense: None\nReason: No monitored category in top predictions');
    return null;
  }

  double _calculateRms(List<double> samples) {
    if (samples.isEmpty) return 0.0;
    double sum = 0.0;
    for (final s in samples) {
      sum += s * s;
    }
    return sqrt(sum / samples.length);
  }

  double _rmsToDb(double rms) {
    if (rms <= 0) return 0.0;
    return (20 * log(rms) / ln10 + 90).clamp(0.0, 120.0);
  }

  double getThreshold(String categoryName) => 0.55;

  void dispose() {
    _interpreter?.close();
    _interpreter = null;
    _isLoaded = false;
    _isTfLiteReady = false;
    debugPrint('[Classifier] YAMNet model disposed');
  }
}
