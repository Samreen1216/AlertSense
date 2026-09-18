import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/audio_providers.dart';

class ListeningIndicator extends ConsumerStatefulWidget {
  const ListeningIndicator({super.key});

  @override
  ConsumerState<ListeningIndicator> createState() => _ListeningIndicatorState();
}

class _ListeningIndicatorState extends ConsumerState<ListeningIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isListening = ref.watch(isListeningProvider);
    final ambientDb = ref.watch(ambientDbProvider);

    if (isListening) {
      _pulseController.repeat(reverse: true);
    } else {
      _pulseController.stop();
      _pulseController.value = 0.0;
    }

    return Container(
      height: 48,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: isListening ? _scaleAnimation.value : 1.0,
                child: Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: isListening ? Colors.green : Colors.red,
                    shape: BoxShape.circle,
                  ),
                ),
              );
            }
          ),
          const SizedBox(width: 12),
          Text(
            isListening ? 'Listening...' : 'Not Listening',
            style: const TextStyle(fontWeight: FontWeight.w600),
          ),
          const Spacer(),
          Text(
            '${ambientDb.toStringAsFixed(1)} dB',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
