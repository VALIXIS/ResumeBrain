import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../../data/models/resume_models.dart';
import '../models/analysis_models.dart';
import '../providers/analysis_providers.dart';
import 'widgets/score_meter.dart';
import 'widgets/section_grade_badge.dart';
import 'widgets/suggestion_chip.dart';

/// AnalysisResultsScreen displays complete ATS and structural analysis for a resume,
/// including a circular score gauge, section grade badges, and actionable suggestion chips.
class AnalysisResultsScreen extends ConsumerStatefulWidget {
  final Resume? targetResume;

  const AnalysisResultsScreen({
    super.key,
    this.targetResume,
  });

  @override
  ConsumerState<AnalysisResultsScreen> createState() => _AnalysisResultsScreenState();
}

class _AnalysisResultsScreenState extends ConsumerState<AnalysisResultsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _triggerAnalysis();
    });
  }

  void _triggerAnalysis() {
    final resume = widget.targetResume ?? ref.read(currentResumeProvider);
    if (resume != null) {
      ref.read(resumeAnalysisProvider.notifier).analyzeResume(resume);
    }
  }

  @override
  Widget build(BuildContext context) {
    final resume = widget.targetResume ?? ref.watch(currentResumeProvider);
    final analysisAsync = ref.watch(resumeAnalysisProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Analysis Results'),
        actions: [
          if (resume != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Re-analyze Resume',
              onPressed: () => _triggerAnalysis(),
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
      return EmptyStateWidget(
        title: 'No Resume Selected',
        description: 'Select or create a resume to perform ATS and structural analysis.',
        icon: Icons.description_outlined,
        actionText: 'Go Back',
        onAction: () => Navigator.of(context).maybePop(),
      );
    }

    return analysisAsync.when(
      loading: () => const LoadingStateWidget(
        message: 'Analyzing resume structure and ATS compliance...',
      ),
      error: (error, stack) => ErrorStateWidget(
        errorMessage: 'Analysis failed: ${error.toString()}',
        onRetry: () => _triggerAnalysis(),
      ),
      data: (report) {
        if (report == null) {
          return EmptyStateWidget(
            title: 'No Analysis Available',
            description: 'Run analysis on "${resume.title}" to generate ATS score and insights.',
            icon: Icons.analytics_outlined,
            actionText: 'Run Analysis',
            onAction: () => _triggerAnalysis(),
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
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Resume Info Header Card
          _buildResumeOverviewCard(resume),
          const SizedBox(height: AppSpacing.md),

          // Overall ATS Score Meter Card
          _buildScoreOverviewCard(report),
          const SizedBox(height: AppSpacing.xl),

          // Section Breakdown
          Row(
            children: [
              const Icon(
                Icons.fact_check_outlined,
                color: AppColors.primary,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Section Breakdown',
                style: AppTypography.titleLarge,
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (report.sectionGrades.isEmpty)
            Text(
              'No section grades available.',
              style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: report.sectionGrades.length,
              separatorBuilder: (c, i) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                return SectionGradeBadge(grade: report.sectionGrades[index]);
              },
            ),

          const SizedBox(height: AppSpacing.xl),

          // Actionable Suggestions
          Row(
            children: [
              const Icon(
                Icons.lightbulb_outline_rounded,
                color: AppColors.accentPurple,
                size: 22,
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Actionable Suggestions',
                style: AppTypography.titleLarge,
              ),
              const Spacer(),
              Text(
                '${report.suggestions.length} items',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (report.suggestions.isEmpty)
            AppCard(
              color: AppColors.surfaceLight,
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle_outline_rounded,
                    color: AppColors.accentGreen,
                    size: 28,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      'Great job! No critical improvements needed for this resume.',
                      style: AppTypography.bodyMedium,
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
              separatorBuilder: (c, i) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                return SuggestionChipWidget(
                  suggestion: report.suggestions[index],
                );
              },
            ),

          const SizedBox(height: AppSpacing.xxl),

          // Re-Analyze Action Button
          AppButton(
            text: 'Re-Analyze Resume',
            icon: Icons.refresh_rounded,
            variant: AppButtonVariant.primary,
            onPressed: () => _triggerAnalysis(),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildResumeOverviewCard(Resume resume) {
    return AppCard(
      color: AppColors.surfaceLight,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: AppRadius.borderSm,
            ),
            child: const Icon(Icons.description_outlined, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  resume.title.isNotEmpty ? resume.title : 'Untitled Resume',
                  style: AppTypography.titleMedium.copyWith(fontSize: 15),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (resume.personalInfo.fullName.isNotEmpty)
                  Text(
                    '${resume.personalInfo.fullName} • ${resume.personalInfo.jobTitle.isNotEmpty ? resume.personalInfo.jobTitle : "Resume Target"}',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreOverviewCard(ResumeAnalysisReport report) {
    return AppCard(
      color: AppColors.surface,
      border: Border.all(color: AppColors.surfaceBorder),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          Text(
            'OVERALL ATS SCORE',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.primary,
              letterSpacing: 1.2,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          CircularScoreMeter(score: report.overallScore, size: 190),
          const SizedBox(height: AppSpacing.lg),
          if (report.summary.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: AppRadius.borderMd,
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: Text(
                report.summary,
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
