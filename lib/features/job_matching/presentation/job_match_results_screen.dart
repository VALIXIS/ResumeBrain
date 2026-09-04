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
import 'widgets/resume_vs_jd_comparison_widget.dart';

/// Screen displaying overall match score, TF-IDF keyword weights, salary/seniority analysis,
/// missing skill insertion badges, and responsive side-by-side Resume vs JD comparison UI.
class JobMatchResultsScreen extends ConsumerStatefulWidget {
  final JobDescription? jobDescription;
  final Resume? resume;
  final KeywordExtractionResult? initialResult;

  const JobMatchResultsScreen({
    super.key,
    this.jobDescription,
    this.resume,
    this.initialResult,
  });

  @override
  ConsumerState<JobMatchResultsScreen> createState() => _JobMatchResultsScreenState();
}

class _JobMatchResultsScreenState extends ConsumerState<JobMatchResultsScreen> {
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
  Widget build(BuildContext context) {
    final controllerState = ref.watch(jobMatchingControllerProvider);
    final activeJob = widget.jobDescription ?? controllerState.currentJob;
    final activeResume = widget.resume ?? ref.watch(currentResumeProvider);

    final KeywordExtractionResult result;
    if (widget.initialResult != null) {
      result = widget.initialResult!;
    } else if (controllerState.extractionResult != null && widget.jobDescription == null) {
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
                    'Technical skill overlap, TF-IDF relevance, salary/seniority analysis, and comparison view.',
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
                              Expanded(
                                child: Column(
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
                              ),
                              const SizedBox(width: AppSpacing.sm),
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

                  const SizedBox(height: AppSpacing.lg),

                  // TF-IDF Relevance Key Highlights Section
                  if (result.tfidfScores.isNotEmpty) ...[
                    Text(
                      'Top TF-IDF Keyword Scores',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Ranked by statistical frequency and technical relevance weight.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Wrap(
                      spacing: AppSpacing.xs,
                      runSpacing: AppSpacing.xs,
                      children: result.tfidfScores.entries.take(8).map((entry) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.surfaceBorder),
                          ),
                          child: Text(
                            '${entry.key}: ${entry.value.toStringAsFixed(2)}',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: AppSpacing.xl),
                  ],

                  // Responsive Side-by-Side Comparison UI
                  Text(
                    'Resume vs Job Description Comparison',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Interactive breakdown of matched skills, missing skill badges (+ Add to resume), seniority, and salary range.',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  ResumeVsJdComparisonWidget(
                    resume: activeResume,
                    jobDescription: activeJob,
                    result: result,
                    onSkillAdded: () {
                      setState(() {});
                    },
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
              'Please submit a job description to view match score, TF-IDF ranking, and gap comparison.',
              textAlign: TextAlign.center,
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
            ),
          ],
        ),
      ),
    );
  }
}
