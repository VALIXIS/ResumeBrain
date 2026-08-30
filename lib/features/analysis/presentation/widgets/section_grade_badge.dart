import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/custom_card.dart';

/// Card widget displaying the score and status for a specific resume category.
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

  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.accentGreen;
    if (score >= 60) return AppColors.accentOrange;
    return AppColors.accentRed;
  }

  IconData _getStatusIcon(int score) {
    if (score >= 80) return Icons.check_circle_outline_rounded;
    if (score >= 60) return Icons.info_outline_rounded;
    return Icons.warning_amber_rounded;
  }

  String _getGradeLabel(int score) {
    if (score >= 90) return 'A+';
    if (score >= 80) return 'A';
    if (score >= 70) return 'B';
    if (score >= 60) return 'C';
    return 'Needs Work';
  }

  @override
  Widget build(BuildContext context) {
    final title = _formatCategoryTitle(categoryKey);
    final scoreColor = _getScoreColor(score);
    final statusIcon = _getStatusIcon(score);
    final categoryIcon = _getCategoryIcon(categoryKey);
    final gradeLabel = _getGradeLabel(score);

    return Semantics(
      label: '$title score: $score%, grade: $gradeLabel',
      child: AppCard(
        color: AppColors.surfaceLight,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: AppRadius.borderSm,
                  ),
                  child: Icon(
                    categoryIcon,
                    size: 18,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(fontSize: 14),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: AppSpacing.xs),
                // Status Badge with icon + text for accessibility
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: scoreColor.withValues(alpha: 0.4),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(statusIcon, size: 12, color: scoreColor),
                      const SizedBox(width: 4),
                      Text(
                        '$score% ($gradeLabel)',
                        style: AppTypography.labelSmall.copyWith(
                          color: scoreColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            // Visual progress bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (score / 100).clamp(0.0, 1.0),
                backgroundColor: AppColors.surfaceBorder,
                valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                minHeight: 4,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
