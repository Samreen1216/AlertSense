import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:record/record.dart';

/// Service that manages real-time microphone audio streaming.
/// Uses the `record` package for live PCM capture at 16 kHz.
class AudioStreamService {
  static const int sampleRate = 16000;
  static const double windowDuration = 0.975;
  static const int samplesPerWindow = 15600;
  static const double silenceThreshold = 0.01;

  bool _isListening = false;
  final _audioBufferController = StreamController<List<double>>.broadcast();
  final _dbLevelController = StreamController<double>.broadcast();

  final AudioRecorder _recorder = AudioRecorder();
  StreamSubscription<Uint8List>? _recorderSub;
  final List<double> _sampleBuffer = [];

  Timer? _simulationTimer; // fallback only

  Stream<List<double>> get audioStream => _audioBufferController.stream;
  Stream<double> get dbLevelStream => _dbLevelController.stream;
  bool get isListening => _isListening;

  Future<void> startListening() async {
    if (_isListening) return;
    _isListening = true;
    _sampleBuffer.clear();

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
            _fallbackSimulation();
          },
        );
        micStarted = true;
        debugPrint('[AudioStream] Real mic started');
      }
    } catch (e) {
      debugPrint('[AudioStream] Could not start mic: $e');
    }

    if (!micStarted) {
      _fallbackSimulation();
    }
  }

  void _onAudioData(Uint8List data) {
    final samples = convertPcmToFloat32(data);
    _sampleBuffer.addAll(samples);

    while (_sampleBuffer.length >= samplesPerWindow) {
      final window = _sampleBuffer.sublist(0, samplesPerWindow);
      _sampleBuffer.removeRange(0, samplesPerWindow);

      final rms = calculateRms(window);
      final db = rmsToDb(rms);
      if (!_dbLevelController.isClosed) _dbLevelController.add(db);

      if (rms > silenceThreshold) {
        if (!_audioBufferController.isClosed) _audioBufferController.add(window);
      }
    }
  }

  void _fallbackSimulation() {
    debugPrint('[AudioStream] Using simulation fallback');
    final random = Random();
    _simulationTimer = Timer.periodic(const Duration(milliseconds: 975), (_) {
      if (!_isListening) return;
      final db = 35.0 + random.nextDouble() * 40.0;
      if (!_dbLevelController.isClosed) _dbLevelController.add(db);
      if (random.nextDouble() > 0.65) {
        final buffer = List.generate(
          samplesPerWindow,
          (_) => (random.nextDouble() * 2.0 - 1.0) * 0.3,
        );
        if (!_audioBufferController.isClosed) _audioBufferController.add(buffer);
      }
    });
  }

  Future<void> stopListening() async {
    _isListening = false;
    _simulationTimer?.cancel();
    _simulationTimer = null;
    await _recorderSub?.cancel();
    _recorderSub = null;
    try { await _recorder.stop(); } catch (_) {}
    _sampleBuffer.clear();
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
