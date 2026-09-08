import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

enum AppSnackBarVariant { info, success, error, warning }

/// Helper class to display consistent, theme-aware, accessible snackbars.
class AppSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    AppSnackBarVariant variant = AppSnackBarVariant.info,
    String? actionLabel,
    VoidCallback? onAction,
    Duration duration = const Duration(seconds: 3),
  }) {
    final messenger = ScaffoldMessenger.of(context);
    messenger.hideCurrentSnackBar();

    Color accentColor;
    IconData iconData;

    switch (variant) {
      case AppSnackBarVariant.success:
        accentColor = AppColors.accentTeal;
        iconData = Icons.check_circle_outline_rounded;
        break;
      case AppSnackBarVariant.error:
        accentColor = AppColors.accentRed;
        iconData = Icons.error_outline_rounded;
        break;
      case AppSnackBarVariant.warning:
        accentColor = AppColors.accentPurple;
        iconData = Icons.warning_amber_rounded;
        break;
      case AppSnackBarVariant.info:
        accentColor = AppColors.primary;
        iconData = Icons.info_outline_rounded;
        break;
    }

    messenger.showSnackBar(
      SnackBar(
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(AppSpacing.md),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        elevation: 4,
        backgroundColor: AppColors.surface,
        duration: duration,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadius.borderMd,
          side: BorderSide(color: AppColors.surfaceBorder, width: 1),
        ),
        content: Row(
          children: [
            Icon(iconData, color: accentColor, size: 22),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Text(
                message,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
              ),
            ),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(width: AppSpacing.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                child: TextButton(
                  onPressed: () {
                    messenger.hideCurrentSnackBar();
                    onAction();
                  },
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    foregroundColor: accentColor,
                    textStyle: AppTypography.labelLarge,
                  ),
                  child: Text(actionLabel),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static void showSuccess(BuildContext context, String message) {
    show(context, message: message, variant: AppSnackBarVariant.success);
  }

  static void showError(BuildContext context, String message) {
    show(context, message: message, variant: AppSnackBarVariant.error);
  }
}
