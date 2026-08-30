import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../data/models/resume_models.dart';
import '../controllers/job_matching_controller.dart';
import '../models/job_description.dart';
import '../models/keyword_extraction_result.dart';
import '../services/keyword_extractor_service.dart';

/// Screen displaying the overall match score, matched technical skill chips,
/// and missing keyword gaps for a target Job Description compared against a Resume.
class JobMatchResultsScreen extends ConsumerWidget {
  final JobDescription? jobDescription;
  final Resume? resume;
  final KeywordExtractionResult? initialResult;

  const JobMatchResultsScreen({
    super.key,
    this.jobDescription,
    this.resume,
    this.initialResult,
  });

  Color _getScoreColor(double percentage) {
    if (percentage >= 75.0) {
      return AppColors.accentGreen;
    } else if (percentage >= 50.0) {
      return AppColors.accentOrange;
    } else {
      return AppColors.accentRed;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controllerState = ref.watch(jobMatchingControllerProvider);
    final activeJob = jobDescription ?? controllerState.currentJob;
    final activeResume = resume ?? ref.watch(currentResumeProvider);

    final KeywordExtractionResult result;
    if (initialResult != null) {
      result = initialResult!;
    } else if (controllerState.extractionResult != null && jobDescription == null) {
      result = controllerState.extractionResult!;
    } else if (activeJob != null && activeJob.descriptionText.trim().isNotEmpty) {
      final extractor = ref.watch(keywordExtractorServiceProvider);
      result = extractor.extractAndCompare(
        jobDescriptionText: activeJob.descriptionText,
        resume: activeResume,
      );
    } else {
      result = KeywordExtractionResult.empty();
    }

    final bool hasJob = activeJob != null && activeJob.descriptionText.trim().isNotEmpty;
    final double score = result.overlapPercentage;
    final Color scoreColor = _getScoreColor(score);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Match Results'),
      ),
      body: !hasJob
          ? _buildEmptyJdState(context)
          : SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Job Description Title Banner
                  Text(
                    activeJob.title.isNotEmpty ? activeJob.title : 'Target Job Description',
                    style: AppTypography.titleLarge.copyWith(color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Technical skill overlap and keyword gap analysis against your resume.',
                    style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Overall Match Score Card
                  AppCard(
                    child: Padding(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Overall Skill Match',
                                    style: AppTypography.titleMedium.copyWith(
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    '${result.matchedSkills.length} of ${result.extractedJdSkills.length} JD skills matched',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                              // Percentage Badge
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.md,
                                  vertical: AppSpacing.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: scoreColor.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(20),
                                  border: Border.all(color: scoreColor),
                                ),
                                child: Text(
                                  '${score.toStringAsFixed(0)}%',
                                  style: AppTypography.titleLarge.copyWith(
                                    color: scoreColor,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.md),

                          // Linear Progress Indicator
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: result.extractedJdSkills.isEmpty
                                  ? 0.0
                                  : (score / 100.0).clamp(0.0, 1.0),
                              minHeight: 10,
                              backgroundColor: AppColors.surfaceLight,
                              valueColor: AlwaysStoppedAnimation<Color>(scoreColor),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: AppSpacing.xl),

                  // Matched Skills Section
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: AppColors.accentGreen, size: 22),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Matched Skills (${result.matchedSkills.length})',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Technical skills present in both the target job description and your resume.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  if (result.matchedSkills.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceLight.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.surfaceBorder),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: AppColors.textMuted, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'No matching technical skills detected in your resume.',
                              style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: result.matchedSkills.map((skill) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentGreen.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.check, size: 14, color: AppColors.accentGreen),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  skill,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.accentGreen,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: AppSpacing.xl),

                  // Missing Skills / Gap Section
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.accentOrange, size: 22),
                      const SizedBox(width: AppSpacing.xs),
                      Text(
                        'Missing Keywords Gap (${result.missingSkills.length})',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Key technical skills mentioned in the job description that were not detected in your resume.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  if (result.missingSkills.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.accentGreen.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: AppColors.accentGreen),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.stars_rounded, color: AppColors.accentGreen, size: 22),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'No missing technical keywords detected! Your resume covers all extracted skills.',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.textPrimary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: result.missingSkills.map((skill) {
                        return Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: AppSpacing.sm,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.accentOrange.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(color: AppColors.accentOrange.withValues(alpha: 0.5)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.add_circle_outline, size: 14, color: AppColors.accentOrange),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text(
                                  skill,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.accentOrange,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        );
                      }).toList(),
                    ),

                  const SizedBox(height: AppSpacing.xl),
                ],
              ),
            ),
    );
  }

  Widget _buildEmptyJdState(BuildContext context) {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.work_off_outlined,
              size: 64,
              color: AppColors.textMuted,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No Job Description Loaded',
              style: AppTypography.titleMedium.copyWith(color: AppColors.textPrimary),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Please submit a job description to view match score and skill gap analysis.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
