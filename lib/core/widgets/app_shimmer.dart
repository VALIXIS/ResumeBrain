import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';

/// A reusable, lightweight shimmer animation widget.
/// Adapts dynamically to light and dark theme colors and respects accessibility settings.
class AppShimmer extends StatefulWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final Widget? child;

  const AppShimmer({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.child,
  });

  @override
  State<AppShimmer> createState() => _AppShimmerState();
}

class _AppShimmerState extends State<AppShimmer> with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Respect system reduced-motion / disable animations preferences
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    final baseColor = AppColors.surface;
    final highlightColor = AppColors.surfaceLight;
    final radius = widget.borderRadius ?? AppRadius.borderMd;

    if (disableAnimations) {
      return Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: radius,
        ),
        child: widget.child,
      );
    }

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          width: widget.width,
          height: widget.height,
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              colors: [
                baseColor,
                highlightColor,
                baseColor,
              ],
              stops: const [0.15, 0.5, 0.85],
              begin: Alignment(-2.0 + _controller.value * 4.0, -0.3),
              end: Alignment(0.0 + _controller.value * 4.0, 0.3),
            ),
          ),
          child: widget.child,
        );
      },
    );
  }
}
