import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../data/models/resume_models.dart';
import '../models/keyword_extraction_result.dart';

/// Keyword Heatmap widget displaying overall match score percentage (e.g. 82%),
/// matching candidate skills in green, and missing keywords in amber with a one-tap
/// 'Add to Resume' action.
class KeywordHeatmap extends ConsumerStatefulWidget {
  final KeywordExtractionResult result;
  final VoidCallback? onSkillAdded;

  const KeywordHeatmap({
    super.key,
    required this.result,
    this.onSkillAdded,
  });

  @override
  ConsumerState<KeywordHeatmap> createState() => _KeywordHeatmapState();
}

class _KeywordHeatmapState extends ConsumerState<KeywordHeatmap> {
  final Set<String> _addedSkillsInSession = {};

  Color _getScoreColor(double percentage) {
    if (percentage >= 75.0) {
      return AppColors.accentGreen;
    } else if (percentage >= 50.0) {
      return AppColors.accentOrange;
    } else {
      return AppColors.accentRed;
    }
  }

  void _addSkillToResume(String skillName) {
    final activeResume = ref.read(currentResumeProvider);
    if (activeResume != null) {
      final exists = activeResume.skills.any(
        (s) => s.name.trim().toLowerCase() == skillName.trim().toLowerCase(),
      );
      if (!exists) {
        ref.read(currentResumeProvider.notifier).addSkill(Skill(name: skillName));
      }
    }

    setState(() {
      _addedSkillsInSession.add(skillName);
    });

    AppSnackBar.show(
      context,
      message: 'Added "$skillName" to your resume skills!',
      variant: AppSnackBarVariant.success,
    );

    widget.onSkillAdded?.call();
  }

  @override
  Widget build(BuildContext context) {
    final activeResume = ref.watch(currentResumeProvider);
    final double matchPercentage = widget.result.overlapPercentage;
    final Color scoreColor = _getScoreColor(matchPercentage);

    final List<String> matchedSkills = widget.result.matchedSkills;
    final List<String> missingSkills = widget.result.missingSkills;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Match Percentage & Gauge Header Card
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Job Description Match Score',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            '${matchedSkills.length} of ${widget.result.extractedJdSkills.length} required keywords matched from resume bullet points & skills',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textMuted,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    // Match Score Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.md,
                        vertical: AppSpacing.sm,
                      ),
                      decoration: BoxDecoration(
                        color: scoreColor.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: scoreColor, width: 2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            matchPercentage >= 75.0
                                ? Icons.verified_rounded
                                : matchPercentage >= 50.0
                                    ? Icons.bolt_rounded
                                    : Icons.warning_amber_rounded,
                            color: scoreColor,
                            size: 20,
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${matchPercentage.toStringAsFixed(0)}%',
                            style: AppTypography.titleLarge.copyWith(
                              color: scoreColor,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                // Progress Gauge
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: widget.result.extractedJdSkills.isEmpty
                        ? 0.0
                        : (matchPercentage / 100.0).clamp(0.0, 1.0),
                    minHeight: 12,
                    backgroundColor: AppColors.surfaceLight,
                    valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        // Keyword Gap Heatmap Section Header
        AppCard(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Keyword Gap Heatmap',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Row(
                      children: [
                        _buildLegendDot(AppColors.accentGreen, 'Match'),
                        const SizedBox(width: 12),
                        _buildLegendDot(AppColors.accentOrange, 'Missing'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Matching skills in green, missing keywords in amber. Tap any missing keyword to add it to your resume instantly.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                ),
                const SizedBox(height: AppSpacing.md),

                // Matched Skills Subheading & Chips (GREEN)
                if (matchedSkills.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.check_circle_rounded, color: AppColors.accentGreen, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'MATCHING SKILLS (${matchedSkills.length})',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.accentGreen,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: matchedSkills.map((skill) {
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: AppColors.accentGreen.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: AppColors.accentGreen),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(
                              Icons.check_rounded,
                              size: 14,
                              color: AppColors.accentGreen,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              skill,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.accentGreen,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                ],

                // Missing Skills Subheading & Interactive Chips (AMBER)
                if (missingSkills.isNotEmpty) ...[
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.accentOrange, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'MISSING KEYWORDS (${missingSkills.length})',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.accentOrange,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: missingSkills.map((skill) {
                      final bool isAddedInSession = _addedSkillsInSession.contains(skill);
                      final bool isAlreadyInResume = activeResume?.skills.any(
                            (s) => s.name.trim().toLowerCase() == skill.trim().toLowerCase(),
                          ) ??
                          false;
                      final bool isAdded = isAddedInSession || isAlreadyInResume;

                      final Color chipBorderColor = isAdded ? AppColors.accentGreen : AppColors.accentOrange;
                      final Color chipBgColor = isAdded
                          ? AppColors.accentGreen.withValues(alpha: 0.15)
                          : AppColors.accentOrange.withValues(alpha: 0.15);
                      final Color textColor = isAdded ? AppColors.accentGreen : AppColors.accentOrange;

                      return InkWell(
                        onTap: isAdded ? null : () => _addSkillToResume(skill),
                        borderRadius: BorderRadius.circular(20),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: chipBgColor,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: chipBorderColor),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                isAdded ? Icons.check_circle_rounded : Icons.warning_amber_rounded,
                                size: 14,
                                color: textColor,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                skill,
                                style: AppTypography.bodySmall.copyWith(
                                  color: textColor,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: isAdded ? AppColors.accentGreen : AppColors.accentOrange,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      isAdded ? Icons.check : Icons.add,
                                      size: 11,
                                      color: Colors.white,
                                    ),
                                    const SizedBox(width: 2),
                                    Text(
                                      isAdded ? 'Added' : 'Add to Resume',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: Colors.white,
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ] else if (matchedSkills.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.accentGreen.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.accentGreen),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.stars_rounded, color: AppColors.accentGreen, size: 20),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Perfect Match! No missing keywords detected for this job description.',
                            style: AppTypography.bodyMedium.copyWith(color: AppColors.accentGreen),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
        ),
      ],
    );
  }
}
