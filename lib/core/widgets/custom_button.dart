import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';
import 'tap_scale_widget.dart';

enum AppButtonVariant { primary, secondary, outline, text, ai }

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final IconData? icon;
  final bool isLoading;
  final bool isFullWidth;

  const AppButton({
    super.key,
    required this.text,
    this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.icon,
    this.isLoading = false,
    this.isFullWidth = true,
  });

  @override
  Widget build(BuildContext context) {
    final isEnabled = !isLoading && onPressed != null;

    Widget child = Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading) ...[
          const SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
          ),
          const SizedBox(width: 8),
        ] else if (icon != null) ...[
          Icon(icon, size: 18),
          const SizedBox(width: 8),
        ],
        Text(
          text,
          style: AppTypography.labelLarge.copyWith(
            color: !isEnabled
                ? AppColors.textDisabled
                : (variant == AppButtonVariant.outline
                    ? AppColors.textPrimary
                    : (variant == AppButtonVariant.text ? AppColors.primary : Colors.white)),
          ),
        ),
      ],
    );

    Decoration? decoration;
    Color buttonColor = Colors.transparent;

    switch (variant) {
      case AppButtonVariant.primary:
        decoration = BoxDecoration(
          gradient: isEnabled
              ? AppColors.primaryGradient
              : LinearGradient(
                  colors: [
                    AppColors.primary.withValues(alpha: 0.5),
                    AppColors.secondary.withValues(alpha: 0.5),
                  ],
                ),
          borderRadius: AppRadius.borderMd,
        );
        break;
      case AppButtonVariant.ai:
        decoration = BoxDecoration(
          gradient: isEnabled
              ? AppColors.aiGradient
              : LinearGradient(
                  colors: [
                    AppColors.accentPurple.withValues(alpha: 0.5),
                    AppColors.primary.withValues(alpha: 0.5),
                  ],
                ),
          borderRadius: AppRadius.borderMd,
        );
        break;
      case AppButtonVariant.secondary:
        buttonColor = isEnabled ? AppColors.surfaceLight : AppColors.surface;
        break;
      case AppButtonVariant.outline:
        decoration = BoxDecoration(
          border: Border.all(
            color: isEnabled ? AppColors.surfaceBorder : AppColors.surfaceBorder.withValues(alpha: 0.5),
            width: 1.5,
          ),
          borderRadius: AppRadius.borderMd,
        );
        break;
      case AppButtonVariant.text:
        buttonColor = Colors.transparent;
        break;
    }

    Widget buttonWidget = Material(
      color: decoration == null ? buttonColor : Colors.transparent,
      borderRadius: AppRadius.borderMd,
      child: InkWell(
        onTap: isEnabled ? onPressed : null,
        borderRadius: AppRadius.borderMd,
        child: ConstrainedBox(
          constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
          child: Container(
            decoration: decoration,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            alignment: Alignment.center,
            child: child,
          ),
        ),
      ),
    );

    buttonWidget = TapScaleWidget(
      onTap: isEnabled ? onPressed : null,
      child: buttonWidget,
    );

    return Semantics(
      button: true,
      enabled: isEnabled,
      label: text,
      child: isFullWidth ? SizedBox(width: double.infinity, child: buttonWidget) : buttonWidget,
    );
  }
}
