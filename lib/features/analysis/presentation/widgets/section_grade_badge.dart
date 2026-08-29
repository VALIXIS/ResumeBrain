import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../models/analysis_models.dart';

/// Card widget displaying the evaluation score and letter grade for a specific resume section.
class SectionGradeBadge extends StatelessWidget {
  final SectionGrade grade;

  const SectionGradeBadge({
    super.key,
    required this.grade,
  });

  IconData _getSectionIcon(String sectionName) {
    final lower = sectionName.toLowerCase();
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

  Color _getGradeColor(double score) {
    if (score >= 80) return AppColors.accentGreen;
    if (score >= 65) return AppColors.accentOrange;
    return AppColors.accentRed;
  }

  IconData _getStatusIcon(double score) {
    if (score >= 80) return Icons.check_circle_outline_rounded;
    if (score >= 65) return Icons.info_outline_rounded;
    return Icons.warning_amber_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final gradeColor = _getGradeColor(grade.score);
    final statusIcon = _getStatusIcon(grade.score);
    final sectionIcon = _getSectionIcon(grade.sectionName);

    return AppCard(
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
                  sectionIcon,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  grade.sectionName,
                  style: AppTypography.titleMedium.copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: AppSpacing.xs),
              // Status Badge with icon + text for accessibility
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: gradeColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: gradeColor.withValues(alpha: 0.4),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(statusIcon, size: 12, color: gradeColor),
                    const SizedBox(width: 4),
                    Text(
                      grade.grade,
                      style: AppTypography.labelSmall.copyWith(
                        color: gradeColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (grade.feedback.isNotEmpty) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              grade.feedback,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: AppSpacing.xs),
          // Visual progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (grade.score / 100).clamp(0.0, 1.0),
              backgroundColor: AppColors.surfaceBorder,
              valueColor: AlwaysStoppedAnimation<Color>(gradeColor),
              minHeight: 4,
            ),
          ),
        ],
      ),
    );
  }
}
