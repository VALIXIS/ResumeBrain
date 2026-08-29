import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// ReorderableSectionCard provides a standardized card UI with a prominent drag handle
/// for use inside Flutter's `ReorderableListView`.
class ReorderableSectionCard extends StatelessWidget {
  final int index;
  final Widget? leading;
  final String title;
  final String? subtitle;
  final String? description;
  final List<Widget>? tags;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final Widget? trailing;
  final Widget? extraContent;

  const ReorderableSectionCard({
    super.key,
    required this.index,
    required this.title,
    this.leading,
    this.subtitle,
    this.description,
    this.tags,
    this.onEdit,
    this.onDelete,
    this.trailing,
    this.extraContent,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderMd,
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.borderMd,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 4,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Reorder Drag Handle
              ReorderableDragStartListener(
                index: index,
                child: Container(
                  padding: const EdgeInsets.only(top: 2, right: 10, bottom: 2),
                  child: const MouseRegion(
                    cursor: SystemMouseCursors.grab,
                    child: Icon(
                      Icons.drag_indicator,
                      color: AppColors.textMuted,
                      size: 22,
                    ),
                  ),
                ),
              ),

              // Optional Leading Widget
              if (leading != null) ...[
                leading!,
                const SizedBox(width: AppSpacing.md),
              ],

              // Card Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title.isNotEmpty ? title : 'Untitled Item',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    if (subtitle != null && subtitle!.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        subtitle!,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                    if (tags != null && tags!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Wrap(
                        spacing: 6,
                        runSpacing: 4,
                        children: tags!,
                      ),
                    ],
                    if (description != null && description!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        description!,
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.textMuted,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (extraContent != null) ...[
                      const SizedBox(height: 6),
                      extraContent!,
                    ],
                  ],
                ),
              ),

              // Trailing Actions (Edit / Delete)
              if (trailing != null)
                trailing!
              else
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (onEdit != null)
                      IconButton(
                        icon: const Icon(
                          Icons.edit_outlined,
                          color: AppColors.textMuted,
                          size: 19,
                        ),
                        tooltip: 'Edit',
                        visualDensity: VisualDensity.compact,
                        onPressed: onEdit,
                      ),
                    if (onDelete != null)
                      IconButton(
                        icon: const Icon(
                          Icons.delete_outline,
                          color: AppColors.accentRed,
                          size: 19,
                        ),
                        tooltip: 'Delete',
                        visualDensity: VisualDensity.compact,
                        onPressed: onDelete,
                      ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
