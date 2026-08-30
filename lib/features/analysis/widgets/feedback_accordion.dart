import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/custom_card.dart';
import '../models/analysis_models.dart';
import '../presentation/widgets/suggestion_chip.dart';

/// Reusable accordion component displaying categorized resume feedback
/// (Formatting, Content Quality, Keywords) with strengths, weaknesses, and recommendations.
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

  Color _getStatusColor(double? score) {
    if (score == null) return AppColors.textMuted;
    if (score >= 80) return AppColors.accentGreen;
    if (score >= 60) return AppColors.accentOrange;
    return AppColors.accentRed;
  }

  @override
  Widget build(BuildContext context) {
    final feedback = widget.feedback;
    final categoryIcon = widget.icon ?? _getDefaultCategoryIcon(feedback.title);
    final statusColor = _getStatusColor(feedback.score);

    final hasContent = feedback.strengths.isNotEmpty ||
        feedback.weaknesses.isNotEmpty ||
        feedback.recommendations.isNotEmpty;

    return Semantics(
      label: '${feedback.title} feedback category, status: ${feedback.status ?? "Available"}. ${_isExpanded ? "Expanded" : "Collapsed"}',
      button: true,
      child: AppCard(
        color: AppColors.surfaceLight,
        padding: EdgeInsets.zero,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Clickable Accordion Header
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
                  children: [
                    // Category Icon
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: AppRadius.borderSm,
                      ),
                      child: Icon(
                        categoryIcon,
                        size: 20,
                        color: AppColors.primary,
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
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (feedback.status != null || feedback.score != null) ...[
                            const SizedBox(height: 2),
                            Row(
                              children: [
                                if (feedback.score != null) ...[
                                  Text(
                                    '${feedback.score!.toStringAsFixed(0)}%',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    '•',
                                    style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 10,
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
                                if (feedback.status != null)
                                  Text(
                                    feedback.status!,
                                    style: AppTypography.labelSmall.copyWith(
                                      color: statusColor,
                                      fontWeight: FontWeight.w600,
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
                      child: const Icon(
                        Icons.expand_more_rounded,
                        color: AppColors.textMuted,
                        size: 24,
                      ),
                    ),
                  ],
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
                        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                        child: Row(
                          children: [
                            const Icon(
                              Icons.info_outline_rounded,
                              color: AppColors.textMuted,
                              size: 18,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'No feedback available',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textMuted,
                                fontStyle: FontStyle.italic,
                              ),
                            ),
                          ],
                        ),
                      )
                    else ...[
                      // 1. Strengths Subsection
                      if (feedback.strengths.isNotEmpty) ...[
                        _buildSectionHeader(
                          icon: Icons.check_circle_outline_rounded,
                          title: 'Strengths',
                          iconColor: AppColors.accentGreen,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        ...feedback.strengths.map(
                          (item) => _buildBulletItem(
                            text: item,
                            bulletColor: AppColors.accentGreen,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // 2. Weaknesses Subsection
                      if (feedback.weaknesses.isNotEmpty) ...[
                        _buildSectionHeader(
                          icon: Icons.warning_amber_rounded,
                          title: 'Areas for Improvement',
                          iconColor: AppColors.accentOrange,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        ...feedback.weaknesses.map(
                          (item) => _buildBulletItem(
                            text: item,
                            bulletColor: AppColors.accentOrange,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                      ],

                      // 3. Actionable Recommendations Subsection
                      if (feedback.recommendations.isNotEmpty) ...[
                        _buildSectionHeader(
                          icon: Icons.lightbulb_outline_rounded,
                          title: 'Recommendations',
                          iconColor: AppColors.accentPurple,
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
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required Color iconColor,
  }) {
    return Row(
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
    );
  }

  Widget _buildBulletItem({
    required String text,
    required Color bulletColor,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 6, top: 4, bottom: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6),
            width: 5,
            height: 5,
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
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
