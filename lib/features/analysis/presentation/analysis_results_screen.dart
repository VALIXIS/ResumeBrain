import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../../data/models/resume_models.dart';
import '../models/resume_analysis_report.dart';
import '../providers/analysis_provider.dart';
import '../services/feedback_categorizer.dart';
import '../widgets/feedback_accordion_card.dart';
import 'widgets/analysis_accessibility_helper.dart';
import 'widgets/score_evolution_card.dart';
import 'widgets/score_meter.dart';
import 'widgets/section_grade_badge.dart';
import 'widgets/suggestion_chip.dart';

/// AnalysisResultsScreen displays complete ATS and structural analysis for a resume,
/// including a circular score gauge, score evolution/history tracking, section grade badges,
/// categorized feedback accordions, and actionable suggestion chips.
/// Hardened for WCAG AAA contrast, 48x48 dp touch targets, 200% text scaling, and comprehensive Semantics.
class AnalysisResultsScreen extends ConsumerStatefulWidget {
  final Resume? targetResume;

  const AnalysisResultsScreen({
    super.key,
    this.targetResume,
  });

  @override
  ConsumerState<AnalysisResultsScreen> createState() =>
      _AnalysisResultsScreenState();
}

class _AnalysisResultsScreenState extends ConsumerState<AnalysisResultsScreen> {
  Resume? _getResume() {
    return widget.targetResume ?? ref.watch(currentResumeProvider);
  }

  void _refreshAnalysis() {
    final resume = widget.targetResume ?? ref.read(currentResumeProvider);
    if (resume != null) {
      if (widget.targetResume != null) {
        ref.invalidate(singleResumeAnalysisProvider(resume));
      } else {
        ref.invalidate(currentResumeAnalysisProvider);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final resume = _getResume();

    AsyncValue<ResumeAnalysisReport?> analysisAsync;
    if (resume == null) {
      analysisAsync = const AsyncValue.data(null);
    } else if (widget.targetResume != null) {
      analysisAsync = ref.watch(singleResumeAnalysisProvider(resume));
    } else {
      analysisAsync = ref.watch(currentResumeAnalysisProvider);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Results'),
        actions: [
          if (resume != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Re-analyze Resume',
              constraints: AnalysisA11y.minTouchTargetConstraints,
              onPressed: _refreshAnalysis,
            ),
        ],
      ),
      body: _buildBody(context, resume, analysisAsync),
    );
  }

  Widget _buildBody(
    BuildContext context,
    Resume? resume,
    AsyncValue<ResumeAnalysisReport?> analysisAsync,
  ) {
    if (resume == null) {
      return _buildResumeSelectionView(context);
    }

    return analysisAsync.when(
      loading: () => const LoadingStateWidget(
        message: 'Analyzing resume structure and ATS compliance...',
      ),
      error: (error, stack) => Semantics(
        label: 'Analysis error occurred. Select retry to analyze again.',
        child: ErrorStateWidget(
          errorMessage: 'Analysis failed. Please check your resume and try again.',
          onRetry: _refreshAnalysis,
        ),
      ),
      data: (report) {
        if (report == null) {
          return Semantics(
            label: 'No analysis available for ${resume.title}. Activate Run Analysis button to generate insights.',
            child: EmptyStateWidget(
              title: 'No Analysis Available',
              description:
                  'Run analysis on "${resume.title}" to generate ATS score and insights.',
              icon: Icons.analytics_outlined,
              actionText: 'Run Analysis',
              onAction: _refreshAnalysis,
            ),
          );
        }

        return _buildReportContent(context, resume, report);
      },
    );
  }

  Widget _buildReportContent(
    BuildContext context,
    Resume resume,
    ResumeAnalysisReport report,
  ) {
    final categories = report.categoryScores.entries.toList();
    final categorizedFeedback = FeedbackCategorizer.categorize(report);

    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Resume Info Header Card
          _buildResumeOverviewCard(resume),
          const SizedBox(height: AppSpacing.md),

          // 2. Overall ATS Score Meter Card
          _buildScoreOverviewCard(report),
          const SizedBox(height: AppSpacing.lg),

          // 3. Historical Score Evolution & Trend Card
          ScoreEvolutionCard(report: report),
          const SizedBox(height: AppSpacing.xl),

          // 4. Section Breakdown
          Semantics(
            header: true,
            label: 'Section Breakdown Header. ${categories.length} sections analyzed.',
            child: Row(
              children: [
                Icon(
                  Icons.fact_check_outlined,
                  color: AnalysisA11y.primaryText(context),
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Section Breakdown',
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (categories.isEmpty)
            Text(
              'No section scores available.',
              style: AppTypography.bodyMedium.copyWith(
                color: AnalysisA11y.textMuted(context),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              separatorBuilder: (c, i) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final category = categories[index];
                return SectionGradeBadge(
                  categoryKey: category.key,
                  score: category.value,
                );
              },
            ),

          const SizedBox(height: AppSpacing.xl),

          // 5. Categorized Feedback Accordions (Formatting, Content Quality, Keywords)
          Semantics(
            header: true,
            label: 'Categorized Feedback Header. ${categorizedFeedback.length} categories available.',
            child: Row(
              children: [
                Icon(
                  Icons.tune_rounded,
                  color: AnalysisA11y.primaryText(context),
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Categorized Feedback',
                  style: AppTypography.titleLarge.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: categorizedFeedback.length,
            separatorBuilder: (c, i) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final category = categorizedFeedback[index];
              return FeedbackAccordionCard(
                feedback: category,
                initialExpanded: false,
              );
            },
          ),

          const SizedBox(height: AppSpacing.xl),

          // 6. Actionable Suggestions
          Semantics(
            header: true,
            label: 'Actionable Suggestions Header. ${report.suggestions.length} items available.',
            child: Row(
              children: [
                Icon(
                  Icons.lightbulb_outline_rounded,
                  color: AnalysisA11y.purpleText(context),
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    'Actionable Suggestions',
                    style: AppTypography.titleLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                Text(
                  '${report.suggestions.length} items',
                  style: AppTypography.bodySmall.copyWith(
                    color: AnalysisA11y.textSecondary(context),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (report.suggestions.isEmpty)
            AppCard(
              color: AppColors.surfaceLight,
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_outline_rounded,
                    color: AnalysisA11y.successText(context),
                    size: 28,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Great job! No critical improvements needed for this resume.',
                      style: AppTypography.bodyMedium.copyWith(
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ],
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: report.suggestions.length,
              separatorBuilder: (c, i) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                return SuggestionChipWidget(
                  suggestion: report.suggestions[index],
                );
              },
            ),

          const SizedBox(height: AppSpacing.xxl),

          // Re-Analyze Action Button with 48x48 min touch target
          ConstrainedBox(
            constraints: AnalysisA11y.minTouchTargetConstraints,
            child: AppButton(
              text: 'Re-Analyze Resume',
              icon: Icons.refresh_rounded,
              variant: AppButtonVariant.primary,
              onPressed: _refreshAnalysis,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildResumeSelectionView(BuildContext context) {
    final resumesAsync = ref.watch(resumesListProvider);

    return resumesAsync.when(
      loading: () => const LoadingStateWidget(message: 'Loading saved resumes...'),
      error: (err, stack) => ErrorStateWidget(
        errorMessage: 'Failed to load resumes. Please retry.',
        onRetry: () => ref.read(resumesListProvider.notifier).loadResumes(),
      ),
      data: (resumes) {
        if (resumes.isEmpty) {
          return EmptyStateWidget(
            title: 'No Saved Resumes Found',
            description: 'Create your first resume to generate detailed ATS analysis & recommendations.',
            icon: Icons.description_outlined,
            actionText: 'Create Resume Now',
            onAction: () {
              final newResume = Resume(
                title: 'New Resume ${DateFormat('MMM d').format(DateTime.now())}',
              );
              ref.read(currentResumeProvider.notifier).setResume(newResume);
              ref.read(resumesListProvider.notifier).saveResume(newResume);
            },
          );
        }

        return SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Select Resume for ATS Analysis',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Choose a resume from your library to evaluate its overall score and structural compliance.',
                style: AppTypography.bodySmall.copyWith(
                  color: AnalysisA11y.textSecondary(context),
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: resumes.length,
                separatorBuilder: (c, i) => const SizedBox(height: AppSpacing.md),
                itemBuilder: (context, index) {
                  final resume = resumes[index];
                  return Semantics(
                    label: 'Resume: ${resume.title}. ${resume.personalInfo.fullName.isNotEmpty ? "Candidate: ${resume.personalInfo.fullName}, Role: ${resume.personalInfo.jobTitle}" : ""}. Double tap to analyze.',
                    button: true,
                    child: ConstrainedBox(
                      constraints: AnalysisA11y.minTouchTargetConstraints,
                      child: AppCard(
                        onTap: () {
                          ref.read(currentResumeProvider.notifier).setResume(resume);
                        },
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),
                              decoration: BoxDecoration(
                                color: AnalysisA11y.primaryBg(context),
                                borderRadius: AppRadius.borderSm,
                                border: Border.all(
                                  color: AnalysisA11y.primaryBorder(context).withValues(alpha: 0.3),
                                ),
                              ),
                              child: Icon(
                                Icons.analytics_outlined,
                                color: AnalysisA11y.primaryText(context),
                                size: 24,
                              ),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    resume.title,
                                    style: AppTypography.titleMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  if (resume.personalInfo.fullName.isNotEmpty)
                                    Text(
                                      '${resume.personalInfo.fullName} • ${resume.personalInfo.jobTitle}',
                                      style: AppTypography.bodySmall.copyWith(
                                        color: AnalysisA11y.textSecondary(context),
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: AnalysisA11y.textSecondary(context),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildResumeOverviewCard(Resume resume) {
    return AppCard(
      color: AppColors.surfaceLight,
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      child: Row(
        children: [
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
              Icons.description_outlined,
              color: AnalysisA11y.primaryText(context),
              size: 20,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resume.title.isNotEmpty ? resume.title : 'Untitled Resume',
                  style: AppTypography.titleMedium.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                if (resume.personalInfo.fullName.isNotEmpty)
                  Text(
                    '${resume.personalInfo.fullName} • ${resume.personalInfo.jobTitle.isNotEmpty ? resume.personalInfo.jobTitle : "Resume Target"}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AnalysisA11y.textSecondary(context),
                    ),
                  ),
              ],
            ),
          ),
          Semantics(
            label: 'Switch selected resume. Currently analyzing ${resume.title}.',
            button: true,
            hint: 'Double tap to open resume selection list',
            child: TextButton.icon(
              style: TextButton.styleFrom(
                minimumSize: const Size(48, 48),
                foregroundColor: AnalysisA11y.primaryText(context),
              ),
              onPressed: () {
                ref.read(currentResumeProvider.notifier).setResume(resume);
                _showResumePickerModal(context);
              },
              icon: const Icon(Icons.swap_horiz_rounded, size: 18),
              label: const Text('Switch'),
            ),
          ),
        ],
      ),
    );
  }

  void _showResumePickerModal(BuildContext context) {
    final resumes = ref.read(resumesListProvider).value ?? [];
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: AppSpacing.paddingMd,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Resume to Analyze',
                  style: AppTypography.titleMedium.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                Flexible(
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: resumes.length,
                    separatorBuilder: (c, i) => const SizedBox(height: AppSpacing.sm),
                    itemBuilder: (context, index) {
                      final item = resumes[index];
                      return Semantics(
                        label: 'Resume option: ${item.title}, ${item.personalInfo.fullName}',
                        button: true,
                        child: ListTile(
                          minVerticalPadding: 12,
                          title: Text(
                            item.title,
                            style: AppTypography.bodyMedium.copyWith(
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          subtitle: Text(
                            item.personalInfo.fullName,
                            style: AppTypography.bodySmall.copyWith(
                              color: AnalysisA11y.textSecondary(context),
                            ),
                          ),
                          trailing: Icon(
                            Icons.chevron_right,
                            color: AnalysisA11y.textSecondary(context),
                          ),
                          onTap: () {
                            ref.read(currentResumeProvider.notifier).setResume(item);
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildScoreOverviewCard(ResumeAnalysisReport report) {
    final score = report.overallScore;
    String summary;
    if (score >= 85) {
      summary =
          'Outstanding resume structure with high ATS readability and solid section depth.';
    } else if (score >= 70) {
      summary =
          'Good foundational resume. Adding measurable metrics and expanding skill keywords will maximize recruiter impact.';
    } else if (score >= 50) {
      summary =
          'Moderate ATS compliance. Fill in missing details in experience and summary to boost your score.';
    } else {
      summary =
          'Resume needs significant detail additions in experience, skills, and contact info to pass ATS filters.';
    }

    return AppCard(
      color: AppColors.surface,
      border: Border.all(color: AppColors.surfaceBorder),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Text(
            'OVERALL ATS SCORE',
            style: AppTypography.labelSmall.copyWith(
              color: AnalysisA11y.primaryText(context),
              letterSpacing: 1.2,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          CircularScoreMeter(score: report.overallScore, size: 190),
          const SizedBox(height: AppSpacing.lg),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: AppRadius.borderMd,
              border: Border.all(color: AppColors.surfaceBorder),
            ),
            child: Text(
              summary,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.textPrimary,
                height: 1.4,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

