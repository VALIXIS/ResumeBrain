import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../../../data/models/resume_models.dart';
import '../../models/job_description.dart';
import '../../models/keyword_extraction_result.dart';
import 'missing_skill_badge_widget.dart';

/// Side-by-side comparison widget contrasting candidate Resume profile
/// against target Job Description requirements. Adapts responsively for narrow mobile screens.
class ResumeVsJdComparisonWidget extends ConsumerStatefulWidget {
  final Resume? resume;
  final JobDescription? jobDescription;
  final KeywordExtractionResult result;
  final VoidCallback? onSkillAdded;

  const ResumeVsJdComparisonWidget({
    super.key,
    required this.resume,
    required this.jobDescription,
    required this.result,
    this.onSkillAdded,
  });

  @override
  ConsumerState<ResumeVsJdComparisonWidget> createState() =>
      _ResumeVsJdComparisonWidgetState();
}

class _ResumeVsJdComparisonWidgetState
    extends ConsumerState<ResumeVsJdComparisonWidget> {
  int _mobileTabIndex = 0;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWideScreen = constraints.maxWidth >= 600;

        if (isWideScreen) {
          return _buildWideSideBySideView(context);
        } else {
          return _buildMobileStackedView(context);
        }
      },
    );
  }

  /// Wide screen (>= 600px): Dual-column side-by-side comparison layout.
  Widget _buildWideSideBySideView(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'RESUME PROFILE',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  width: 1,
                  height: 24,
                  color: AppColors.surfaceBorder,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    'JOB DESCRIPTION',
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.secondary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: AppSpacing.lg),

            // 1. Skills Comparison Row
            _buildComparisonRow(
              title: 'Skills & Keywords',
              resumeContent: _buildResumeSkillsList(),
              jdContent: _buildJdSkillsList(),
            ),
            const Divider(height: AppSpacing.lg),

            // 2. Seniority & Experience Row
            _buildComparisonRow(
              title: 'Seniority & Experience',
              resumeContent: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Level: ${widget.result.seniorityAnalysis.estimatedResumeSeniority}',
                    style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Exp: ~${widget.result.seniorityAnalysis.candidateYearsOfExperience} years',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                  ),
                ],
              ),
              jdContent: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Required Level: ${widget.result.seniorityAnalysis.detectedJdSeniority}',
                    style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    'Req Exp: ${widget.result.seniorityAnalysis.requiredYearsOfExperience != null ? "${widget.result.seniorityAnalysis.requiredYearsOfExperience}+ years" : "Not explicitly specified"}',
                    style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: _getAlignmentColor(widget.result.seniorityAnalysis.alignmentStatus).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      widget.result.seniorityAnalysis.alignmentStatus,
                      style: AppTypography.labelSmall.copyWith(
                        color: _getAlignmentColor(widget.result.seniorityAnalysis.alignmentStatus),
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Divider(height: AppSpacing.lg),

            // 3. Compensation & Salary Row
            _buildComparisonRow(
              title: 'Salary & Compensation',
              resumeContent: Text(
                'Candidate expectations set in profile or open to negotiation.',
                style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
              ),
              jdContent: widget.result.salaryAnalysis.hasSalary
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.result.salaryAnalysis.formattedRange,
                          style: AppTypography.titleMedium.copyWith(
                            color: AppColors.accentGreen,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Raw: ${widget.result.salaryAnalysis.rawText}',
                          style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                        ),
                      ],
                    )
                  : Text(
                      'No explicit salary range detected in JD.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Mobile / Narrow view (< 600px): Responsive stacked view with tab toggle.
  Widget _buildMobileStackedView(BuildContext context) {
    return Column(
      children: [
        // Tab Segment Control
        Container(
          decoration: BoxDecoration(
            color: AppColors.surfaceLight,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _mobileTabIndex = 0),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: _mobileTabIndex == 0 ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Matched & Gaps',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: _mobileTabIndex == 0 ? Colors.white : AppColors.textMuted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () => setState(() => _mobileTabIndex = 1),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: _mobileTabIndex == 1 ? AppColors.primary : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      'Salary & Seniority',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodyMedium.copyWith(
                        color: _mobileTabIndex == 1 ? Colors.white : AppColors.textMuted,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        _mobileTabIndex == 0
            ? AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Matched Skills (${widget.result.matchedSkills.length})',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.accentGreen,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _buildResumeSkillsList(),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        'Missing Keywords Gap (${widget.result.missingSkills.length})',
                        style: AppTypography.titleMedium.copyWith(
                          color: AppColors.accentOrange,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      _buildJdSkillsList(),
                    ],
                  ),
                ),
              )
            : AppCard(
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Seniority Alignment',
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text('JD Target: ${widget.result.seniorityAnalysis.detectedJdSeniority}'),
                      Text('Resume Level: ${widget.result.seniorityAnalysis.estimatedResumeSeniority}'),
                      Text('Status: ${widget.result.seniorityAnalysis.alignmentStatus}'),
                      const Divider(height: AppSpacing.md),
                      Text(
                        'Salary Information',
                        style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        widget.result.salaryAnalysis.hasSalary
                            ? widget.result.salaryAnalysis.formattedRange
                            : 'No salary details in JD',
                        style: AppTypography.bodyMedium.copyWith(
                          color: widget.result.salaryAnalysis.hasSalary
                              ? AppColors.accentGreen
                              : AppColors.textMuted,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ],
    );
  }

  Widget _buildComparisonRow({
    required String title,
    required Widget resumeContent,
    required Widget jdContent,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.labelLarge.copyWith(
            color: AppColors.textMuted,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: AppSpacing.xs),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: resumeContent),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: jdContent),
          ],
        ),
      ],
    );
  }

  Widget _buildResumeSkillsList() {
    if (widget.result.matchedSkills.isEmpty) {
      return Text(
        'No matching skills found.',
        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
      );
    }
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: widget.result.matchedSkills.map((skill) {
        final isSemantic = widget.result.semanticMatches.containsKey(skill);
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.accentGreen.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.accentGreen.withValues(alpha: 0.5)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.check, size: 12, color: AppColors.accentGreen),
              const SizedBox(width: 4),
              Text(
                skill,
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.accentGreen,
                  fontWeight: FontWeight.w600,
                ),
              ),
              if (isSemantic) ...[
                const SizedBox(width: 4),
                Text(
                  '(synonym)',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.accentGreen),
                ),
              ],
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildJdSkillsList() {
    if (widget.result.missingSkills.isEmpty) {
      return Row(
        children: [
          const Icon(Icons.stars, color: AppColors.accentGreen, size: 16),
          const SizedBox(width: 4),
          Text(
            'All JD keywords matched!',
            style: AppTypography.bodySmall.copyWith(color: AppColors.accentGreen),
          ),
        ],
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: widget.result.missingSkills.map((skill) {
        return MissingSkillBadgeWidget(
          skill: skill,
          onInserted: widget.onSkillAdded,
        );
      }).toList(),
    );
  }

  Color _getAlignmentColor(String status) {
    if (status == 'Well Aligned') return AppColors.accentGreen;
    if (status == 'Moderately Aligned') return AppColors.accentOrange;
    if (status == 'Under Qualified') return AppColors.accentRed;
    return AppColors.textMuted;
  }
}
