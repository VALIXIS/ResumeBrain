import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// ReorderableSectionCard provides a polished section card UI with touch elevation,
/// subtle active shadow glow, fluid accordion expand/collapse transitions, and a prominent drag handle.
class ReorderableSectionCard extends StatefulWidget {
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
  final bool isExpanded;
  final VoidCallback? onToggleExpand;

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
    this.isExpanded = false,
    this.onToggleExpand,
  });

  @override
  State<ReorderableSectionCard> createState() => _ReorderableSectionCardState();
}

class _ReorderableSectionCardState extends State<ReorderableSectionCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final bool active = _isHovered || _isPressed;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.fastOutSlowIn,
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderMd,
        border: Border.all(
          color: active ? AppColors.primary.withValues(alpha: 0.6) : AppColors.surfaceBorder,
          width: active ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: active
                ? AppColors.primary.withValues(alpha: 0.2)
                : Colors.black.withValues(alpha: 0.04),
            blurRadius: active ? 12 : 4,
            offset: active ? const Offset(0, 4) : const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: AppRadius.borderMd,
        child: InkWell(
          borderRadius: AppRadius.borderMd,
          onHighlightChanged: (highlighted) {
            setState(() => _isPressed = highlighted);
          },
          onHover: (hovered) {
            setState(() => _isHovered = hovered);
          },
          onTap: widget.onToggleExpand ?? widget.onEdit,
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: AppSpacing.sm + 4,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Reorder Drag Handle
                    ReorderableDragStartListener(
                      index: widget.index,
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
                    if (widget.leading != null) ...[
                      widget.leading!,
                      const SizedBox(width: AppSpacing.md),
                    ],

                    // Card Content Header
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title.isNotEmpty ? widget.title : 'Untitled Item',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (widget.subtitle != null && widget.subtitle!.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              widget.subtitle!,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                          if (widget.tags != null && widget.tags!.isNotEmpty) ...[
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              runSpacing: 4,
                              children: widget.tags!,
                            ),
                          ],
                          if (widget.description != null && widget.description!.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Text(
                              widget.description!,
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textMuted,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ],
                      ),
                    ),

                    // Trailing Actions (Edit / Delete / Accordion Expand)
                    if (widget.trailing != null)
                      widget.trailing!
                    else
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (widget.onToggleExpand != null)
                            AnimatedRotation(
                              turns: widget.isExpanded ? 0.5 : 0.0,
                              duration: const Duration(milliseconds: 250),
                              child: IconButton(
                                icon: const Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: AppColors.textMuted,
                                  size: 22,
                                ),
                                tooltip: widget.isExpanded ? 'Collapse' : 'Expand',
                                onPressed: widget.onToggleExpand,
                              ),
                            ),
                          if (widget.onEdit != null)
                            IconButton(
                              icon: const Icon(
                                Icons.edit_outlined,
                                color: AppColors.textMuted,
                                size: 19,
                              ),
                              tooltip: 'Edit',
                              visualDensity: VisualDensity.compact,
                              onPressed: widget.onEdit,
                            ),
                          if (widget.onDelete != null)
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: AppColors.accentRed,
                                size: 19,
                              ),
                              tooltip: 'Delete',
                              visualDensity: VisualDensity.compact,
                              onPressed: widget.onDelete,
                            ),
                        ],
                      ),
                  ],
                ),

                // Fluid Accordion Expand / Collapse Content Transition
                if (widget.extraContent != null)
                  AnimatedCrossFade(
                    firstChild: const SizedBox(width: double.infinity, height: 0),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: widget.extraContent!,
                    ),
                    crossFadeState: widget.isExpanded
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 250),
                    firstCurve: Curves.fastOutSlowIn,
                    secondCurve: Curves.fastOutSlowIn,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
