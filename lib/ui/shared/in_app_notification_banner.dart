import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/app_svg_icons.dart';
import '../../core/constants/sound_categories.dart';
import '../../core/router/app_router.dart';
import '../../data/models/alert_event.dart';

class InAppNotificationBanner extends StatefulWidget {
  final AlertEvent alert;
  final VoidCallback onDismiss;

  const InAppNotificationBanner({
    super.key,
    required this.alert,
    required this.onDismiss,
  });

  @override
  State<InAppNotificationBanner> createState() => _InAppNotificationBannerState();
}

class _InAppNotificationBannerState extends State<InAppNotificationBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<Offset> _offsetAnimation;
  late Animation<double> _fadeAnimation;
  Timer? _autoDismissTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );

    _offsetAnimation = Tween<Offset>(
      begin: const Offset(0.0, -1.0),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    _fadeAnimation = CurvedAnimation(parent: _controller, curve: Curves.easeOut);

    _controller.forward();

    // Auto dismiss after 6 seconds
    _autoDismissTimer = Timer(const Duration(seconds: 6), _dismiss);
  }

  void _dismiss() {
    if (!mounted) return;
    _autoDismissTimer?.cancel();
    _controller.reverse().then((_) {
      if (mounted) widget.onDismiss();
    });
  }

  SoundCategory _getCategory(String name) {
    try {
      return SoundCategory.values.firstWhere(
        (c) => c.name.toLowerCase() == name.toLowerCase(),
      );
    } catch (_) {
      return SoundCategory.doorbell;
    }
  }

  @override
  void dispose() {
    _autoDismissTimer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cat = _getCategory(widget.alert.soundCategory);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final priority = widget.alert.priorityLevel.toUpperCase();
    final isHigh = priority == 'HIGH';

    final Color priorityColor = isHigh
        ? const Color(0xFFEF4444)
        : (priority == 'MEDIUM' ? const Color(0xFFF59E0B) : const Color(0xFF10B981));

    return SlideTransition(
      position: _offsetAnimation,
      child: FadeTransition(
        opacity: _fadeAnimation,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  _autoDismissTimer?.cancel();
                  widget.onDismiss();
                  context.push(AppRoutes.alertDetails, extra: widget.alert);
                },
                borderRadius: BorderRadius.circular(18),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: priorityColor.withValues(alpha: 0.6),
                      width: 1.5,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: priorityColor.withValues(alpha: isDark ? 0.35 : 0.20),
                        blurRadius: 18,
                        spreadRadius: 2,
                        offset: const Offset(0, 4),
                      ),
                      BoxShadow(
                        color: Colors.black.withValues(alpha: isDark ? 0.5 : 0.1),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      // Sound Icon with glowing background
                      Container(
                        width: 44,
                        height: 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: priorityColor.withValues(alpha: 0.18),
                          border: Border.all(color: priorityColor, width: 1.2),
                        ),
                        child: Center(
                          child: AppSvgIcon(
                            iconKey: cat.name,
                            size: 24,
                            color: priorityColor,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),

                      // Sound details
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Row(
                              children: [
                                Text(
                                  '${cat.label} Detected!',
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: priorityColor.withValues(alpha: 0.2),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Text(
                                    priority,
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                      color: priorityColor,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${(widget.alert.confidence * 100).toInt()}% Confidence • Tap to view details',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white70 : const Color(0xFF64748B),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Dismiss button
                      IconButton(
                        icon: Icon(
                          Icons.close_rounded,
                          size: 20,
                          color: isDark ? Colors.white60 : const Color(0xFF94A3B8),
                        ),
                        onPressed: _dismiss,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
