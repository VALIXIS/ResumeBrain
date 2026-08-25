import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_typography.dart';

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
            color: variant == AppButtonVariant.outline
                ? AppColors.textPrimary
                : (variant == AppButtonVariant.text ? AppColors.primary : Colors.white),
          ),
        ),
      ],
    );

    Decoration? decoration;
    Color buttonColor = Colors.transparent;

    switch (variant) {
      case AppButtonVariant.primary:
        decoration = BoxDecoration(
          gradient: AppColors.primaryGradient,
          borderRadius: AppRadius.borderMd,
        );
        break;
      case AppButtonVariant.ai:
        decoration = BoxDecoration(
          gradient: AppColors.aiGradient,
          borderRadius: AppRadius.borderMd,
        );
        break;
      case AppButtonVariant.secondary:
        buttonColor = AppColors.surfaceLight;
        break;
      case AppButtonVariant.outline:
        decoration = BoxDecoration(
          border: Border.all(color: AppColors.surfaceBorder, width: 1.5),
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
        onTap: isLoading ? null : onPressed,
        borderRadius: AppRadius.borderMd,
        child: Container(
          decoration: decoration,
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );

    return isFullWidth ? SizedBox(width: double.infinity, child: buttonWidget) : buttonWidget;
  }
}
