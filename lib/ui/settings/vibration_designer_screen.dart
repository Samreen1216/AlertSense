import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:vibration/vibration.dart';
import '../../core/constants/app_svg_icons.dart';
import '../../core/constants/sound_categories.dart';
import '../../providers/settings_providers.dart';

class VibrationDesignerScreen extends ConsumerStatefulWidget {
  const VibrationDesignerScreen({super.key});

  @override
  ConsumerState<VibrationDesignerScreen> createState() => _VibrationDesignerScreenState();
}

class _VibrationDesignerScreenState extends ConsumerState<VibrationDesignerScreen> {
  SoundCategory _selectedCategory = SoundCategory.fireAlarm;
  final List<int> _recordedPattern = [];
  DateTime? _tapStartTime;
  DateTime? _lastTapEndTime;
  bool _isRecording = false;
  bool _isPlaying = false;
  int _activePlayingIndex = -1;
  Timer? _playbackTimer;
  final List<Timer> _stepTimers = [];

  @override
  void initState() {
    super.initState();
    // Load existing custom vibration if user previously configured one
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _loadPatternForCategory(_selectedCategory);
      }
    });
  }

  @override
  void dispose() {
    _stopPlayback();
    super.dispose();
  }

  void _loadPatternForCategory(SoundCategory cat) {
    _stopPlayback();
    final customVibrations = ref.read(userSettingsProvider).customVibrationPatterns;
    final saved = customVibrations[cat.name];
    setState(() {
      _recordedPattern.clear();
      if (saved != null && saved.isNotEmpty) {
        _recordedPattern.addAll(saved);
      }
      _isRecording = false;
      _lastTapEndTime = null;
      _tapStartTime = null;
    });
  }

  void _onTapDown(TapDownDetails details) {
    if (_isPlaying) _stopPlayback();

    final now = DateTime.now();
    Vibration.vibrate(duration: 50); // Haptic feedback while tapping

    if (_lastTapEndTime != null && _isRecording) {
      final pauseDuration = now.difference(_lastTapEndTime!).inMilliseconds;
      _recordedPattern.add(pauseDuration.clamp(50, 2000));
    } else if (!_isRecording) {
      _recordedPattern.clear();
      _recordedPattern.add(0); // Initial pause is 0
      _isRecording = true;
    }

    _tapStartTime = now;
    setState(() {});
  }

  void _onTapUp(TapUpDetails details) {
    if (_tapStartTime != null) {
      final now = DateTime.now();
      final buzzDuration = now.difference(_tapStartTime!).inMilliseconds;
      _recordedPattern.add(buzzDuration.clamp(50, 2000));
      _lastTapEndTime = now;
      setState(() {});
    }
  }

  void _finishRecording() {
    setState(() {
      _isRecording = false;
      _tapStartTime = null;
      _lastTapEndTime = null;
    });
  }

  void _stopPlayback() {
    _playbackTimer?.cancel();
    _playbackTimer = null;
    for (final t in _stepTimers) {
      t.cancel();
    }
    _stepTimers.clear();
    try {
      Vibration.cancel();
    } catch (_) {}
    if (mounted) {
      setState(() {
        _isPlaying = false;
        _activePlayingIndex = -1;
      });
    }
  }

  Future<void> _previewPattern() async {
    if (_recordedPattern.isEmpty) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      final controller = messenger.showSnackBar(
        SnackBar(
          content: const Text('Record a pattern by tapping the box first!'),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Timer(const Duration(milliseconds: 3000), () {
        try {
          controller.close();
        } catch (_) {}
      });
      return;
    }

    if (_isPlaying) {
      _stopPlayback();
      return;
    }

    setState(() {
      _isRecording = false;
      _isPlaying = true;
      _activePlayingIndex = 0;
    });

    try {
      final hasVibrator = await Vibration.hasVibrator();
      if (hasVibrator == true) {
        await Vibration.vibrate(
          pattern: _recordedPattern,
          intensities: List.filled(_recordedPattern.length, 255),
        );
      }
    } catch (e) {
      debugPrint('Vibration error: $e');
    }

    // Synchronize visual playback highlights with each pattern step
    int accumulatedTime = 0;
    for (int i = 0; i < _recordedPattern.length; i++) {
      final duration = _recordedPattern[i];
      accumulatedTime += duration;
      final stepIndex = i;
      final timer = Timer(Duration(milliseconds: accumulatedTime), () {
        if (mounted && _isPlaying) {
          setState(() {
            _activePlayingIndex = stepIndex + 1;
          });
        }
      });
      _stepTimers.add(timer);
    }

    final totalTime = _recordedPattern.fold<int>(0, (p, c) => p + c);
    _playbackTimer = Timer(Duration(milliseconds: totalTime + 100), () {
      _stopPlayback();
    });
  }

  void _savePattern() {
    _stopPlayback();
    if (_recordedPattern.isEmpty) {
      final messenger = ScaffoldMessenger.of(context);
      messenger.clearSnackBars();
      final controller = messenger.showSnackBar(
        SnackBar(
          content: const Text('No pattern recorded'),
          duration: const Duration(seconds: 3),
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Timer(const Duration(milliseconds: 3000), () {
        try {
          controller.close();
        } catch (_) {}
      });
      return;
    }

    ref.read(userSettingsProvider.notifier).setCustomVibration(
      _selectedCategory.name,
      _recordedPattern,
    );

    final messenger = ScaffoldMessenger.of(context);
    messenger.clearSnackBars();
    final controller = messenger.showSnackBar(
      SnackBar(
        content: Text('Saved custom vibration for ${_selectedCategory.label}!'),
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    Timer(const Duration(milliseconds: 3000), () {
      try {
        controller.close();
      } catch (_) {}
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final hasCustomSaved = ref.watch(userSettingsProvider).customVibrationPatterns.containsKey(_selectedCategory.name);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Vibration Designer'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sound Category Dropdown
            DropdownButtonFormField<SoundCategory>(
              initialValue: _selectedCategory,
              decoration: InputDecoration(
                labelText: 'Sound Category',
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(16)),
              ),
              items: SoundCategory.values.map((cat) {
                return DropdownMenuItem(
                  value: cat,
                  child: Row(
                    children: [
                      AppSvgIcon(iconKey: cat.name, size: 18, color: cat.color),
                      const SizedBox(width: 10),
                      Text(cat.label),
                    ],
                  ),
                );
              }).toList(),
              onChanged: (cat) {
                if (cat != null) {
                  setState(() {
                    _selectedCategory = cat;
                    _loadPatternForCategory(cat);
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // Tap Pad
            Expanded(
              child: GestureDetector(
                onTapDown: _onTapDown,
                onTapUp: _onTapUp,
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isRecording ? theme.colorScheme.primary : theme.colorScheme.outlineVariant,
                      width: _isRecording ? 2.5 : 1.0,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.touch_app_rounded,
                          size: 64,
                          color: _isRecording ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _isRecording ? 'Recording! Tap out your rhythm...' : 'Tap out your vibration rhythm here',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: _isRecording ? theme.colorScheme.primary : theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Hold longer for strong buzzes, quick taps for pulses',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        if (_isRecording) ...[
                          const SizedBox(height: 16),
                          FilledButton.tonalIcon(
                            onPressed: _finishRecording,
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text('Done Recording'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Pattern Visualizer Bar
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Text(
                            'Recorded Pulses: ${_recordedPattern.length ~/ 2}',
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                          if (hasCustomSaved) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF00FF41).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: const Text(
                                'Saved Pattern',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Color(0xFF00FF41),
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (_recordedPattern.isNotEmpty)
                        Text(
                          '${_recordedPattern.fold<int>(0, (p, c) => p + c)} ms total',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    height: 20,
                    child: _recordedPattern.isEmpty
                        ? const Center(
                            child: Text(
                              'No taps recorded yet',
                              style: TextStyle(fontSize: 11, color: Colors.grey),
                            ),
                          )
                        : Row(
                            children: _recordedPattern.asMap().entries.map((entry) {
                              final isBuzz = entry.key % 2 == 1;
                              final flex = (entry.value / 40).clamp(1, 40).toInt();
                              final isCurrentStep = _activePlayingIndex == entry.key;

                              Color blockColor;
                              if (isCurrentStep) {
                                blockColor = const Color(0xFF00FF41); // Active playback highlight
                              } else if (isBuzz) {
                                blockColor = theme.colorScheme.primary;
                              } else {
                                blockColor = theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4);
                              }

                              return Expanded(
                                flex: flex,
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 100),
                                  margin: const EdgeInsets.symmetric(horizontal: 1),
                                  height: isCurrentStep ? 20 : 14,
                                  decoration: BoxDecoration(
                                    color: blockColor,
                                    borderRadius: BorderRadius.circular(4),
                                    boxShadow: isCurrentStep
                                        ? [
                                            BoxShadow(
                                              color: const Color(0xFF00FF41).withValues(alpha: 0.8),
                                              blurRadius: 8,
                                            ),
                                          ]
                                        : null,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      _stopPlayback();
                      setState(() {
                        _recordedPattern.clear();
                        _isRecording = false;
                        _lastTapEndTime = null;
                      });
                    },
                    icon: const Icon(Icons.refresh_rounded),
                    label: const Text('Reset'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton.tonalIcon(
                    onPressed: _previewPattern,
                    icon: Icon(_isPlaying ? Icons.stop_rounded : Icons.play_arrow_rounded),
                    label: Text(_isPlaying ? 'Playing…' : 'Preview'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            FilledButton.icon(
              onPressed: _savePattern,
              icon: const Icon(Icons.save_rounded),
              label: const Text('Save Custom Vibration'),
            ),
          ],
        ),
      ),
    );
  }
}
