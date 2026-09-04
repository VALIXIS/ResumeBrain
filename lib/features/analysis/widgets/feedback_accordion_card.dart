import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/custom_card.dart';
import '../models/category_feedback.dart';
import '../presentation/widgets/analysis_accessibility_helper.dart';
import '../presentation/widgets/suggestion_chip.dart';

/// Reusable accordion component displaying categorized resume feedback
/// (Formatting, Content Quality, Keywords) with strengths, weaknesses, and recommendations.
/// Hardened for WCAG AAA contrast, 48x48 dp minimum touch targets, 200% text scaling,
/// and comprehensive Flutter Semantics.
class FeedbackAccordionCard extends StatefulWidget {
  final CategoryFeedback feedback;
  final IconData? icon;
  final bool initialExpanded;

  const FeedbackAccordionCard({
    super.key,
    required this.feedback,
    this.icon,
    this.initialExpanded = false,
  });

  @override
  State<FeedbackAccordionCard> createState() => _FeedbackAccordionCardState();
}

class _FeedbackAccordionCardState extends State<FeedbackAccordionCard>
    with SingleTickerProviderStateMixin {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = widget.initialExpanded;
  }

  IconData _getDefaultCategoryIcon(String title) {
    final lower = title.toLowerCase();
    if (lower.contains('format')) {
      return Icons.format_shapes_rounded;
    }
    if (lower.contains('content')) {
      return Icons.article_outlined;
    }
    if (lower.contains('keyword')) {
      return Icons.key_rounded;
    }
    return Icons.category_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final feedback = widget.feedback;
    final categoryIcon = widget.icon ?? _getDefaultCategoryIcon(feedback.title);

    final status = feedback.score != null
        ? AnalysisA11y.getScoreStatus(context, feedback.score!)
        : null;

    final hasContent = feedback.strengths.isNotEmpty ||
        feedback.weaknesses.isNotEmpty ||
        feedback.recommendations.isNotEmpty;

    final statusText = feedback.status ?? (status != null ? status.statusLabel : 'Available');

    return AppCard(
      color: AppColors.surfaceLight,
      padding: EdgeInsets.zero,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Clickable Accordion Header with 48x48 min touch target & Semantics
          Semantics(
            label: '${feedback.title} feedback category. '
                '${feedback.score != null ? "Score: ${feedback.score}%, " : ""}'
                'Status: $statusText.',
            value: _isExpanded ? 'Expanded' : 'Collapsed',
            button: true,
            hint: _isExpanded
                ? 'Double tap to collapse category details'
                : 'Double tap to expand category details',
            child: ConstrainedBox(
              constraints: AnalysisA11y.minTouchTargetConstraints,
              child: InkWell(
                onTap: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
                borderRadius: AppRadius.borderMd,
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Row(
                    children: [
                      // Category Icon with high-contrast background
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AnalysisA11y.primaryBg(context),
                          borderRadius: AppRadius.borderSm,
                          border: Border.all(
                            color: AnalysisA11y.primaryBorder(context).withValues(alpha: 0.3),
                          ),
                        ),
                        child: Icon(
                          categoryIcon,
                          size: 20,
                          color: AnalysisA11y.primaryText(context),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),

                      // Title & Status
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              feedback.title,
                              style: AppTypography.titleMedium.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textPrimary,
                              ),
                            ),
                            if (feedback.status != null || feedback.score != null) ...[
                              const SizedBox(height: 3),
                              Wrap(
                                crossAxisAlignment: WrapCrossAlignment.center,
                                spacing: 6,
                                children: [
                                  if (feedback.score != null && status != null) ...[
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(status.icon, size: 12, color: status.textColor),
                                        const SizedBox(width: 3),
                                        Text(
                                          '${feedback.score!}% (${status.gradeLabel})',
                                          style: AppTypography.labelSmall.copyWith(
                                            color: status.textColor,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Text(
                                      '•',
                                      style: TextStyle(
                                        color: AnalysisA11y.textMuted(context),
                                        fontSize: 10,
                                      ),
                                    ),
                                  ],
                                  if (feedback.status != null)
                                    Text(
                                      feedback.status!,
                                      style: AppTypography.labelSmall.copyWith(
                                        color: status?.textColor ?? AnalysisA11y.textSecondary(context),
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ],
                        ),
                      ),

                      // Expansion Chevron Indicator
                      AnimatedRotation(
                        turns: _isExpanded ? 0.5 : 0.0,
                        duration: const Duration(milliseconds: 250),
                        curve: Curves.easeInOut,
                        child: Icon(
                          Icons.expand_more_rounded,
                          color: AnalysisA11y.textSecondary(context),
                          size: 24,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Expandable Content Body
          AnimatedCrossFade(
            firstChild: const SizedBox.shrink(),
            secondChild: Padding(
              padding: const EdgeInsets.only(
                left: AppSpacing.md,
                right: AppSpacing.md,
                bottom: AppSpacing.md,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(color: AppColors.surfaceBorder, height: 1),
                  const SizedBox(height: AppSpacing.md),

                  if (!hasContent)
                    Padding(
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            color: AnalysisA11y.textMuted(context),
                            size: 18,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'No feedback items available for this category.',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AnalysisA11y.textMuted(context),
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else ...[
                    // 1. Strengths Subsection
                    if (feedback.strengths.isNotEmpty) ...[
                      _buildSectionHeader(
                        context: context,
                        icon: Icons.check_circle_outline_rounded,
                        title: 'Strengths',
                        iconColor: AnalysisA11y.successText(context),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      ...feedback.strengths.map(
                        (item) => _buildBulletItem(
                          context: context,
                          prefix: 'Strength: ',
                          text: item,
                          bulletColor: AnalysisA11y.successText(context),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // 2. Weaknesses Subsection
                    if (feedback.weaknesses.isNotEmpty) ...[
                      _buildSectionHeader(
                        context: context,
                        icon: Icons.warning_amber_rounded,
                        title: 'Areas for Improvement',
                        iconColor: AnalysisA11y.warningText(context),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      ...feedback.weaknesses.map(
                        (item) => _buildBulletItem(
                          context: context,
                          prefix: 'Area for improvement: ',
                          text: item,
                          bulletColor: AnalysisA11y.warningText(context),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // 3. Actionable Recommendations Subsection
                    if (feedback.recommendations.isNotEmpty) ...[
                      _buildSectionHeader(
                        context: context,
                        icon: Icons.lightbulb_outline_rounded,
                        title: 'Recommendations',
                        iconColor: AnalysisA11y.purpleText(context),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      ...feedback.recommendations.map(
                        (rec) => Padding(
                          padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                          child: SuggestionChipWidget(suggestion: rec),
                        ),
                      ),
                    ],
                  ],
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
    );
  }

  Widget _buildSectionHeader({
    required BuildContext context,
    required IconData icon,
    required String title,
    required Color iconColor,
  }) {
    return Semantics(
      header: true,
      label: '$title subsection',
      child: Row(
        children: [
          Icon(icon, size: 16, color: iconColor),
          const SizedBox(width: 6),
          Text(
            title,
            style: AppTypography.titleMedium.copyWith(
              fontWeight: FontWeight.w700,
              fontSize: 13,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBulletItem({
    required BuildContext context,
    required String prefix,
    required String text,
    required Color bulletColor,
  }) {
    return Semantics(
      label: '$prefix$text',
      child: Padding(
        padding: const EdgeInsets.only(left: 6, top: 4, bottom: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              margin: const EdgeInsets.only(top: 6),
              width: 6,
              height: 6,
              decoration: BoxDecoration(
                color: bulletColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                text,
                style: AppTypography.bodyMedium.copyWith(
                  fontSize: 13,
                  color: AnalysisA11y.textSecondary(context),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

