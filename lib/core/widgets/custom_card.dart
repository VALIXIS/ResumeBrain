import 'package:flutter/material.dart';
import '../theme/app_radius.dart';

import 'tap_scale_widget.dart';

class AppCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Border? border;

  const AppCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final effectiveColor = color ?? Theme.of(context).cardColor;
    final effectiveBorder = border ??
        Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          width: 1,
        );

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveColor,
        borderRadius: AppRadius.borderLg,
        border: effectiveBorder,
      ),
      child: child,
    );

    if (onTap != null) {
      return TapScaleWidget(
        child: Material(
          color: Colors.transparent,
          borderRadius: AppRadius.borderLg,
          child: InkWell(
            onTap: onTap,
            borderRadius: AppRadius.borderLg,
            child: content,
          ),
        ),
      );
    }

    return content;
  }
}
