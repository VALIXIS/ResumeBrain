import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/custom_card.dart';
import 'analysis_accessibility_helper.dart';

/// Card widget displaying the score and status for a specific resume category.
/// Hardened for WCAG AAA contrast, text scaling up to 200%, and comprehensive Semantics.
class SectionGradeBadge extends StatelessWidget {
  final String categoryKey;
  final int score; // 0 to 100

  const SectionGradeBadge({
    super.key,
    required this.categoryKey,
    required this.score,
  });

  String _formatCategoryTitle(String key) {
    switch (key) {
      case 'contactInfo':
        return 'Contact Information';
      case 'professionalSummary':
        return 'Professional Summary';
      case 'workExperience':
        return 'Work Experience';
      case 'skills':
        return 'Skills';
      case 'education':
        return 'Education';
      case 'additional':
        return 'Additional Sections';
      default:
        // Convert camelCase or lowercase to Title Case
        return key
            .replaceAllMapped(
              RegExp(r'([A-Z])'),
              (match) => ' ${match.group(1)}',
            )
            .trim()
            .split(' ')
            .map((w) => w.isNotEmpty ? '${w[0].toUpperCase()}${w.substring(1)}' : '')
            .join(' ');
    }
  }

  IconData _getCategoryIcon(String key) {
    final lower = key.toLowerCase();
    if (lower.contains('contact') || lower.contains('personal')) {
      return Icons.person_outline_rounded;
    }
    if (lower.contains('summary') || lower.contains('profile')) {
      return Icons.description_outlined;
    }
    if (lower.contains('experience') || lower.contains('work')) {
      return Icons.work_outline_rounded;
    }
    if (lower.contains('education')) {
      return Icons.school_outlined;
    }
    if (lower.contains('skill')) {
      return Icons.psychology_outlined;
    }
    if (lower.contains('cert')) {
      return Icons.verified_outlined;
    }
    if (lower.contains('lang')) {
      return Icons.language_outlined;
    }
    return Icons.dashboard_customize_outlined;
  }

  @override
  Widget build(BuildContext context) {
    final title = _formatCategoryTitle(categoryKey);
    final categoryIcon = _getCategoryIcon(categoryKey);
    final status = AnalysisA11y.getScoreStatus(context, score);

    return Semantics(
      label: '$title section score: $score%, grade: ${status.gradeLabel} (${status.statusLabel})',
      value: '$score%',
      child: AppCard(
        color: AppColors.surfaceLight,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              alignment: WrapAlignment.spaceBetween,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.xs,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AnalysisA11y.primaryBg(context),
                        borderRadius: AppRadius.borderSm,
                        border: Border.all(
                          color: AnalysisA11y.primaryBorder(context).withValues(alpha: 0.3),
                        ),
                      ),
                      child: Icon(
                        categoryIcon,
                        size: 18,
                        color: AnalysisA11y.primaryText(context),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Flexible(
                      child: Text(
                        title,
                        style: AppTypography.titleMedium.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
                // Status Badge with AAA high-contrast icon + text
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: status.bgColor,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: status.borderColor,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(status.icon, size: 13, color: status.textColor),
                      const SizedBox(width: 4),
                      Text(
                        '$score% (${status.gradeLabel})',
                        style: AppTypography.labelSmall.copyWith(
                          color: status.textColor,
                          fontWeight: FontWeight.w800,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Decorative progress bar excluded from screen reader redundancy
            ExcludeSemantics(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (score / 100).clamp(0.0, 1.0),
                  backgroundColor: AppColors.surfaceBorder,
                  valueColor: AlwaysStoppedAnimation<Color>(status.borderColor),
                  minHeight: 4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

