import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../providers/device_providers.dart';

class HeroBatteryCard extends ConsumerWidget {
  const HeroBatteryCard({super.key});

  void _showBatteryInfo(BuildContext context, WidgetRef ref, BatteryStatus status) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Row(
          children: [
            Icon(
              status.isOptimized
                  ? Icons.verified_user_rounded
                  : Icons.battery_alert_rounded,
              color: status.isOptimized
                  ? const Color(0xFF10B981)
                  : const Color(0xFFF59E0B),
            ),
            const SizedBox(width: 10),
            Text(status.title),
          ],
        ),
        content: Text(
          status.isOptimized
              ? 'AlertSense is fully whitelisted from battery restrictions. Continuous sound awareness and instant vibrations run uninterrupted in the background.'
              : 'AlertSense needs battery optimization disabled to guarantee reliable acoustic detection when the screen is locked or in the background.',
          style: const TextStyle(fontSize: 14, height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Dismiss'),
          ),
          if (status.requiresAction)
            FilledButton(
              onPressed: () async {
                Navigator.pop(ctx);
                final service = ref.read(deviceServiceProvider);
                await service.requestIgnoreBatteryOptimizations();
                ref.invalidate(batteryStatusProvider);
              },
              child: const Text('Optimize Now'),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusAsync = ref.watch(batteryStatusProvider);

    final status = statusAsync.value ??
        const BatteryStatus(
          title: 'Battery Optimized',
          subtitle: 'Running in background',
          isOptimized: true,
        );

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showBatteryInfo(context, ref, status),
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: const Color(0xFF0F1A3A).withValues(alpha: 0.7),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.1),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              // Shield / Battery Icon
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (status.isOptimized
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B))
                      .withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: (status.isOptimized
                            ? const Color(0xFF10B981)
                            : const Color(0xFFF59E0B))
                        .withValues(alpha: 0.4),
                    width: 1,
                  ),
                ),
                child: Icon(
                  status.isOptimized
                      ? Icons.verified_user_rounded
                      : Icons.battery_alert_rounded,
                  color: status.isOptimized
                      ? const Color(0xFF10B981)
                      : const Color(0xFFF59E0B),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),

              // Status Title & Subtitle
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      status.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    Text(
                      status.subtitle,
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.6),
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),

              // Chevron
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.white.withValues(alpha: 0.4),
                size: 14,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
