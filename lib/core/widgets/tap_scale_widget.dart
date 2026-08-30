import 'package:flutter/material.dart';

/// A wrapper widget that performs a subtle scale-down micro-animation
/// when pressed/tapped, providing clear tactile visual feedback.
/// Supports accessibility settings and does not block gesture propagation.
class TapScaleWidget extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;

  const TapScaleWidget({
    super.key,
    required this.child,
    this.onTap,
  });

  @override
  State<TapScaleWidget> createState() => _TapScaleWidgetState();
}

class _TapScaleWidgetState extends State<TapScaleWidget> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 100),
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.97).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.disableAnimationsOf(context);

    // If there is no onTap callback, it is not interactive, so return the child as is.
    if (widget.onTap == null) {
      return widget.child;
    }

    Widget animatedChild = widget.child;

    if (!disableAnimations) {
      animatedChild = Listener(
        onPointerDown: (_) => _controller.forward(),
        onPointerUp: (_) => _controller.reverse(),
        onPointerCancel: (_) => _controller.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: animatedChild,
        ),
      );
    }

    return Semantics(
      button: true,
      enabled: widget.onTap != null,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: widget.onTap,
        child: animatedChild,
      ),
    );
  }
}
