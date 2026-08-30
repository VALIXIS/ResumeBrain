import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
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
    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: color ?? AppColors.surface,
        borderRadius: AppRadius.borderLg,
        border: border ?? Border.all(color: AppColors.surfaceBorder, width: 1),
      ),
      child: child,
    );

    if (onTap != null) {
      return TapScaleWidget(
        onTap: onTap,
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
