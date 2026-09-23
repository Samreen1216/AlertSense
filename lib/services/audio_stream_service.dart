import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

import 'audio_preprocessor.dart';

/// Service that manages real-time microphone audio streaming.
/// Uses the `record` package for live PCM capture at 16 kHz.
class AudioStreamService {
  static const int sampleRate = 16000;
  static const double windowDuration = 0.975;
  static const int samplesPerWindow = 15600;
  static const double silenceThreshold = 0.008; // Configurable baseline

  bool _isListening = false;
  final _audioBufferController = StreamController<List<double>>.broadcast();
  final _dbLevelController = StreamController<double>.broadcast();

  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _recorderSub;
  final AudioWindowBuffer _windowBuffer = AudioWindowBuffer();

  Timer? _fallbackDbTimer; // Baseline ambient meter when mic inactive

  Stream<List<double>> get audioStream => _audioBufferController.stream;
  Stream<double> get dbLevelStream => _dbLevelController.stream;
  bool get isListening => _isListening;

  Future<void> startListening() async {
    if (_isListening) return;
    _isListening = true;
    _windowBuffer.clear();

    bool micStarted = false;
    try {
      final hasPermission = await _recorder.hasPermission();
      if (hasPermission) {
        final stream = await _recorder.startStream(
          const RecordConfig(
            encoder: AudioEncoder.pcm16bits,
            sampleRate: sampleRate,
            numChannels: 1,
          ),
        );
        _recorderSub = stream.listen(
          _onAudioData,
          onError: (e) {
            debugPrint('[AudioStream] Mic error: $e');
            _startAmbientDbFallback();
          },
        );
        micStarted = true;
        debugPrint('[AudioStream] Microphone stream active (16 kHz mono)');
      } else {
        debugPrint('[AudioStream] Microphone permission not granted');
      }
    } catch (e) {
      debugPrint('[AudioStream] Could not start mic: $e');
    }

    if (!micStarted) {
      _startAmbientDbFallback();
    }
  }

  void _onAudioData(Uint8List data) {
    // 1. Preprocess incoming PCM data (PCM16 -> Float32, mono, 16 kHz)
    final samples = AudioPreprocessor.processIncomingPcm(
      pcmBytes: data,
      inputSampleRate: sampleRate,
      numChannels: 1,
    );
    _windowBuffer.addSamples(samples);

    // 2. Extract complete 15,600-sample windows
    while (_windowBuffer.hasWindow) {
      final window = _windowBuffer.nextWindow();
      if (window == null) break;

      final rms = calculateRms(window);
      final db = rmsToDb(rms);
      if (!_dbLevelController.isClosed) _dbLevelController.add(db);

      // Buffer emitted only if exceeding minimal noise floor
      if (rms >= silenceThreshold) {
        if (!_audioBufferController.isClosed) _audioBufferController.add(window);
      }
    }
  }

  /// Ambient meter fallback that only updates decibel level without generating fake audio alerts.
  void _startAmbientDbFallback() {
    debugPrint('[AudioStream] Microphone standby — ambient meter only');
    _fallbackDbTimer?.cancel();
    _fallbackDbTimer = Timer.periodic(const Duration(milliseconds: 975), (_) {
      if (!_isListening) return;
      if (!_dbLevelController.isClosed) _dbLevelController.add(30.0);
    });
  }

  Future<void> stopListening() async {
    _isListening = false;
    _fallbackDbTimer?.cancel();
    _fallbackDbTimer = null;
    await _recorderSub?.cancel();
    _recorderSub = null;
    try { await _recorder.stop(); } catch (_) {}
    _windowBuffer.clear();
    debugPrint('[AudioStream] Stopped');
  }

  List<double> convertPcmToFloat32(List<int> pcmBytes) {
    final samples = <double>[];
    for (int i = 0; i < pcmBytes.length - 1; i += 2) {
      int sample = pcmBytes[i] | (pcmBytes[i + 1] << 8);
      if (sample >= 0x8000) sample -= 0x10000;
      samples.add(sample / 32768.0);
    }
    return samples;
  }

  double calculateRms(List<double> samples) {
    if (samples.isEmpty) return 0.0;
    double sum = 0.0;
    for (final s in samples) { sum += s * s; }
    return sqrt(sum / samples.length);
  }

  double rmsToDb(double rms) {
    if (rms <= 0) return 0.0;
    return (20 * log(rms) / ln10 + 90).clamp(0.0, 120.0);
  }

  void dispose() {
    stopListening();
    _audioBufferController.close();
    _dbLevelController.close();
  }
}
