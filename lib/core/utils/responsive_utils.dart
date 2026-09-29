import 'package:flutter/material.dart';

/// Centralized responsive breakpoint utility class for AlertSense.
class ResponsiveBreakpoints {
  ResponsiveBreakpoints._();

  static const double maxTabletWidth = 680.0;
  static const double maxDesktopWidth = 840.0;

  /// Width < 360 (compact phones like iPhone SE 1st gen, small Androids)
  static bool isCompact(BuildContext context) =>
      MediaQuery.sizeOf(context).width < 360;

  /// Width >= 600 (tablets, foldables unfolded, small desktops)
  static bool isTablet(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 600;

  /// Width >= 900 (large tablets landscape, desktops)
  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= 900;

  /// Orientation is landscape OR viewport height is <= 480 (landscape phones)
  static bool isLandscape(BuildContext context) =>
      MediaQuery.orientationOf(context) == Orientation.landscape ||
      MediaQuery.sizeOf(context).height <= 480;

  /// Viewport height is <= 480
  static bool isShortViewport(BuildContext context) =>
      MediaQuery.sizeOf(context).height <= 480;

  /// Helper to return responsive values based on device category
  static T value<T>(
    BuildContext context, {
    required T compact,
    T? regular,
    T? tablet,
    T? desktop,
  }) {
    if (isDesktop(context) && desktop != null) return desktop;
    if (isTablet(context) && tablet != null) return tablet;
    if (isCompact(context)) return compact;
    return regular ?? compact;
  }
}

/// Convenience extension on BuildContext
extension ResponsiveContext on BuildContext {
  bool get isCompact => ResponsiveBreakpoints.isCompact(this);
  bool get isTablet => ResponsiveBreakpoints.isTablet(this);
  bool get isDesktop => ResponsiveBreakpoints.isDesktop(this);
  bool get isLandscape => ResponsiveBreakpoints.isLandscape(this);
  bool get isShortViewport => ResponsiveBreakpoints.isShortViewport(this);
}
