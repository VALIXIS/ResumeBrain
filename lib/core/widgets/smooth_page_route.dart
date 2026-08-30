import 'package:flutter/material.dart';

/// A custom page route that provides a subtle, premium fade and slight
/// slide-up transition, respecting user reduced-motion preferences.
class SmoothPageRoute<T> extends PageRouteBuilder<T> {
  final Widget page;

  SmoothPageRoute({required this.page})
      : super(
          pageBuilder: (context, animation, secondaryAnimation) => page,
          transitionDuration: const Duration(milliseconds: 250),
          reverseTransitionDuration: const Duration(milliseconds: 200),
          transitionsBuilder: (context, animation, secondaryAnimation, child) {
            // Respect accessibility settings for reduced motion
            if (MediaQuery.disableAnimationsOf(context)) {
              return child;
            }

            final slideTween = Tween<Offset>(
              begin: const Offset(0.0, 0.04),
              end: Offset.zero,
            ).chain(CurveTween(curve: Curves.easeOutQuad));

            return FadeTransition(
              opacity: animation,
              child: SlideTransition(
                position: animation.drive(slideTween),
                child: child,
              ),
            );
          },
        );
}
