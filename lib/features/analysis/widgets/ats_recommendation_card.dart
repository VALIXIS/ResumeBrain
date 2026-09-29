import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/custom_card.dart';
import '../services/ats_engine.dart';

/// An expandable recommendation card widget displaying actionable ATS feedback,
/// priority indicators, score context, and a "Fix with AI" action button.
class AtsRecommendationCard extends StatefulWidget {
  final AtsRecommendation recommendation;
  final bool initialExpanded;
  final ValueChanged<AtsRecommendation>? onFixWithAi;

  const AtsRecommendationCard({
    super.key,
    required this.recommendation,
    this.initialExpanded = false,
    this.onFixWithAi,
  });

  @override
  State<AtsRecommendationCard> createState() => _AtsRecommendationCardState();
}

class _AtsRecommendationCardState extends State<AtsRecommendationCard> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded;
  }

  IconData _getDimensionIcon(AtsDimension dimension) {
    switch (dimension) {
      case AtsDimension.impactVerbs:
        return Icons.bolt_rounded;
      case AtsDimension.formatting:
        return Icons.view_headline_rounded;
      case AtsDimension.contactCompleteness:
        return Icons.contact_mail_rounded;
      case AtsDimension.keywordDensity:
        return Icons.key_rounded;
    }
  }

  Color _getPriorityColor(AtsPriority priority) {
    switch (priority) {
      case AtsPriority.high:
        return AppColors.accentRed;
      case AtsPriority.medium:
        return AppColors.accentOrange;
      case AtsPriority.low:
        return AppColors.accentPurple;
    }
  }

  @override
  Widget build(BuildContext context) {
    final rec = widget.recommendation;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final priorityColor = _getPriorityColor(rec.priority);
    final dimensionIcon = _getDimensionIcon(rec.dimension);

    return Semantics(
      label: 'Recommendation card: ${rec.title}. Priority: ${rec.priority.label}. Category: ${rec.dimension.displayName}. Double tap to ${_isExpanded ? "collapse" : "expand"}.',
      button: true,
      child: AppCard(
        color: isDark ? AppColors.surface : Colors.white,
        border: Border.all(
          color: _isExpanded
              ? AppColors.primary.withValues(alpha: 0.5)
              : AppColors.surfaceBorder,
          width: _isExpanded ? 1.5 : 1.0,
        ),
        padding: EdgeInsets.zero,
        child: Column(
          children: [
            // Card Header (Always Visible)
            InkWell(
              onTap: () {
                setState(() {
                  _isExpanded = !_isExpanded;
                });
              },
              borderRadius: AppRadius.borderMd,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Dimension Icon Container
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.15),
                        borderRadius: AppRadius.borderSm,
                        border: Border.all(
                          color: priorityColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(
                        dimensionIcon,
                        color: priorityColor,
                        size: 20,
                      ),
                    ),

                    const SizedBox(width: AppSpacing.md),

                    // Title & Category/Priority Badges
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              // Priority Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 6,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: priorityColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(999),
                                ),
                                child: Text(
                                  rec.priority.label.toUpperCase(),
                                  style: AppTypography.labelSmall.copyWith(
                                    color: priorityColor,
                                    fontSize: 9.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.5,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 6),
                              // Dimension Name Tag
                              Text(
                                rec.dimension.displayName,
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.textSecondary,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(
                            rec.title,
                            style: AppTypography.titleMedium.copyWith(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Expand / Collapse Chevron
                    IconButton(
                      icon: AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 200),
                        child: const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      onPressed: () {
                        setState(() {
                          _isExpanded = !_isExpanded;
                        });
                      },
                      tooltip: _isExpanded ? 'Collapse' : 'Expand details',
                    ),
                  ],
                ),
              ),
            ),

            // Expanded Details & Fix with AI Action
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity, height: 0),
              secondChild: Container(
                width: double.infinity,
                padding: const EdgeInsets.only(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: AppSpacing.md,
                  top: 0,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(color: AppColors.surfaceBorder, height: 1),
                    const SizedBox(height: AppSpacing.sm),

                    // Context info if present
                    if (rec.contextInfo != null && rec.contextInfo!.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppSpacing.sm,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.surfaceLight : const Color(0xFFF1F5F9),
                          borderRadius: AppRadius.borderSm,
                        ),
                        child: Text(
                          'Context: ${rec.contextInfo}',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondary,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                    ],

                    // Detailed Description
                    Text(
                      rec.description,
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                        height: 1.45,
                      ),
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Fix with AI Button (if AI fixable)
                    if (rec.isAiFixable)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: AppColors.aiGradient,
                            borderRadius: AppRadius.borderMd,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withValues(alpha: 0.3),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(
                                horizontal: AppSpacing.md,
                                vertical: AppSpacing.sm,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: AppRadius.borderMd,
                              ),
                            ),
                            onPressed: () {
                              if (widget.onFixWithAi != null) {
                                widget.onFixWithAi!(rec);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('AI Fix initiated for "${rec.title}"'),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              }
                            },
                            icon: const Icon(
                              Icons.auto_awesome_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            label: const Text(
                              'Fix with AI',
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.3,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              crossFadeState: _isExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 250),
            ),
          ],
        ),
      ),
    );
  }
}
