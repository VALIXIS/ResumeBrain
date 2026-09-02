import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Standard modal bottom sheet helper ensuring consistent spacing, styling,
/// scrollability, and accessibility support.
class AppBottomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    String? title,
    bool isDismissible = true,
    bool enableDrag = true,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      isScrollControlled: isScrollControlled,
      backgroundColor: AppColors.surface,
      elevation: 8,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppRadius.xl)),
      ),
      builder: (sheetContext) {
        final viewInsets = MediaQuery.viewInsetsOf(sheetContext);
        final maxHeight = MediaQuery.sizeOf(sheetContext).height * 0.85;

        return Padding(
          padding: EdgeInsets.only(bottom: viewInsets.bottom),
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: maxHeight),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Accessible Drag Handle
                  if (enableDrag)
                    Semantics(
                      label: 'Drag handle to dismiss bottom sheet',
                      child: Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          margin: const EdgeInsets.only(top: 10, bottom: 6),
                          decoration: BoxDecoration(
                            color: AppColors.textMuted.withValues(alpha: 0.4),
                            borderRadius: AppRadius.borderSm,
                          ),
                        ),
                      ),
                    ),

                  // Optional Header Title
                  if (title != null) ...[
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: AppTypography.titleLarge,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          ConstrainedBox(
                            constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                            child: IconButton(
                              icon: const Icon(Icons.close_rounded, size: 20),
                              color: AppColors.textMuted,
                              tooltip: 'Close',
                              onPressed: () => Navigator.of(sheetContext).pop(),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Divider(color: AppColors.surfaceBorder, height: 1),
                  ],

                  // Bottom sheet scrollable content
                  Flexible(
                    child: SingleChildScrollView(
                      padding: AppSpacing.screenPadding,
                      child: child,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
