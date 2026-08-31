import 'package:flutter/material.dart';

/// A reusable responsive layout builder that switches views
/// based on available width constraints, using standard breakpoints.
class ResponsiveLayout extends StatelessWidget {
  final Widget mobile;
  final Widget? tablet;
  final Widget? desktop;

  const ResponsiveLayout({
    super.key,
    required this.mobile,
    this.tablet,
    this.desktop,
  });

  /// Breakpoint thresholds
  static const double kMobileBreakpoint = 640.0;
  static const double kTabletBreakpoint = 1024.0;
  static const double kMaxContentWidth = 1200.0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth >= kTabletBreakpoint && desktop != null) {
          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: kMaxContentWidth),
              child: desktop!,
            ),
          );
        } else if (constraints.maxWidth >= kMobileBreakpoint && (tablet != null || desktop != null)) {
          return tablet ?? desktop!;
        } else {
          return mobile;
        }
      },
    );
  }
}
