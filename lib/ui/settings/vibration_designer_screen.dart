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

  void _onTapDown(TapDownDetails details) {
    final now = DateTime.now();
    Vibration.vibrate(duration: 50); // Feedback while tapping

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

  Future<void> _previewPattern() async {
    if (_recordedPattern.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Record a pattern by tapping the box first!')),
      );
      return;
    }

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
  }

  void _savePattern() {
    if (_recordedPattern.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No pattern recorded')),
      );
      return;
    }

    ref.read(userSettingsProvider.notifier).setCustomVibration(
      _selectedCategory.name,
      _recordedPattern,
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Saved custom vibration for ${_selectedCategory.label}!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

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
                    _recordedPattern.clear();
                    _isRecording = false;
                  });
                }
              },
            ),
            const SizedBox(height: 20),

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
                      width: _isRecording ? 2.0 : 1.0,
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
                          _isRecording ? 'Recording! Keep tapping rhythm...' : 'Tap out your vibration rhythm here',
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
                      Text(
                        'Recorded Pulses: ${_recordedPattern.length ~/ 2}',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      if (_recordedPattern.isNotEmpty)
                        Text(
                          '${_recordedPattern.fold<int>(0, (p, c) => p + c)} ms total',
                          style: const TextStyle(fontSize: 12, color: Colors.grey),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 16,
                    child: _recordedPattern.isEmpty
                        ? const Center(child: Text('No taps recorded yet', style: TextStyle(fontSize: 11, color: Colors.grey)))
                        : Row(
                            children: _recordedPattern.asMap().entries.map((entry) {
                              final isBuzz = entry.key % 2 == 1;
                              final flex = (entry.value / 50).clamp(1, 40).toInt();
                              return Expanded(
                                flex: flex,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(horizontal: 1),
                                  decoration: BoxDecoration(
                                    color: isBuzz ? theme.colorScheme.primary : Colors.transparent,
                                    borderRadius: BorderRadius.circular(4),
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
                    icon: const Icon(Icons.play_arrow_rounded),
                    label: const Text('Preview'),
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
