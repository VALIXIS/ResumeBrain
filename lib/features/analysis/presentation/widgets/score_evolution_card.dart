import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../models/analysis_history_entry.dart';
import '../../models/resume_analysis_report.dart';
import '../../models/score_evolution.dart';
import '../../providers/analysis_provider.dart';
import 'analysis_accessibility_helper.dart';

/// Card widget displaying the score evolution, trend comparison, and historical timeline
/// for a resume document.
/// Hardened for WCAG AAA contrast, flexible text scaling up to 200%, 48x48 touch targets,
/// and comprehensive accessibility Semantics.
class ScoreEvolutionCard extends ConsumerStatefulWidget {
  final ResumeAnalysisReport report;

  const ScoreEvolutionCard({
    super.key,
    required this.report,
  });

  @override
  ConsumerState<ScoreEvolutionCard> createState() => _ScoreEvolutionCardState();
}

class _ScoreEvolutionCardState extends ConsumerState<ScoreEvolutionCard> {
  bool _showFullHistory = false;

  String _formatCategoryTitle(String key) {
    switch (key) {
      case 'contactInfo':
        return 'Contact';
      case 'professionalSummary':
        return 'Summary';
      case 'workExperience':
        return 'Experience';
      case 'skills':
        return 'Skills';
      case 'education':
        return 'Education';
      case 'additional':
        return 'Additional';
      default:
        return key;
    }
  }

  @override
  Widget build(BuildContext context) {
    final evolutionAsync = ref.watch(scoreEvolutionProvider(widget.report));
    final historyAsync =
        ref.watch(resumeAnalysisHistoryProvider(widget.report.resumeId));

    return evolutionAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (error, stack) => const SizedBox.shrink(),
      data: (evolution) {
        return historyAsync.when(
          loading: () => const SizedBox.shrink(),
          error: (error, stack) => const SizedBox.shrink(),
          data: (history) => _buildContent(context, evolution, history),
        );
      },
    );
  }

  Widget _buildContent(
    BuildContext context,
    ScoreEvolution evolution,
    List<AnalysisHistoryEntry> history,
  ) {
    final dateFormat = DateFormat('MMM d, h:mm a');

    final trendSemantic = evolution.hasPrevious
        ? 'Trend: ${evolution.trend.name}, change of ${evolution.scoreDifference! >= 0 ? "+${evolution.scoreDifference}" : "${evolution.scoreDifference}"} points.'
        : 'Initial baseline snapshot.';

    return Semantics(
      label: 'Score evolution: Current score ${evolution.currentScore} out of 100. '
          '${evolution.hasPrevious ? "Previous score ${evolution.previousScore}, recorded on ${evolution.previousDate != null ? dateFormat.format(evolution.previousDate!) : 'unknown'}. " : ""}'
          '$trendSemantic ${history.length} historical snapshot${history.length == 1 ? "" : "s"} recorded.',
      child: AppCard(
        color: AppColors.surfaceLight,
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
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
                    Icons.timeline_rounded,
                    color: AnalysisA11y.primaryText(context),
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Score Evolution & History',
                        style: AppTypography.titleMedium.copyWith(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        '${history.length} snapshot${history.length == 1 ? "" : "s"} recorded',
                        style: AppTypography.bodySmall.copyWith(
                          color: AnalysisA11y.textSecondary(context),
                        ),
                      ),
                    ],
                  ),
                ),
                _buildTrendBadge(context, evolution),
              ],
            ),
            const SizedBox(height: AppSpacing.md),

            // Comparison Row (Current vs Previous)
            if (evolution.hasPrevious) ...[
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.borderMd,
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: IntrinsicHeight(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      Expanded(
                        child: _buildScoreColumn(
                          context: context,
                          label: 'CURRENT',
                          score: '${evolution.currentScore}',
                          subtext: dateFormat.format(evolution.currentDate),
                          color: AnalysisA11y.primaryText(context),
                        ),
                      ),
                      VerticalDivider(
                        color: AppColors.surfaceBorder,
                        thickness: 1,
                        indent: 4,
                        endIndent: 4,
                      ),
                      Expanded(
                        child: _buildScoreColumn(
                          context: context,
                          label: 'PREVIOUS',
                          score: '${evolution.previousScore}',
                          subtext: evolution.previousDate != null
                              ? dateFormat.format(evolution.previousDate!)
                              : '-',
                          color: AnalysisA11y.textSecondary(context),
                        ),
                      ),
                      VerticalDivider(
                        color: AppColors.surfaceBorder,
                        thickness: 1,
                        indent: 4,
                        endIndent: 4,
                      ),
                      Expanded(
                        child: _buildDiffColumn(context, evolution),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Section-level evolution badges
              if (evolution.sectionDiffs.any((s) => s.difference != null && s.difference != 0)) ...[
                Text(
                  'Section Improvements',
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AnalysisA11y.textSecondary(context),
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: evolution.sectionDiffs
                      .where((s) => s.difference != null && s.difference != 0)
                      .map((s) => _buildSectionDiffChip(context, s))
                      .toList(),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
            ] else ...[
              // Single entry / Initial snapshot message
              Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: AppColors.surface,
                  borderRadius: AppRadius.borderMd,
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.info_outline_rounded,
                      color: AnalysisA11y.primaryText(context),
                      size: 22,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Initial analysis snapshot saved. Re-analyze your resume after making edits to track score evolution over time.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AnalysisA11y.textSecondary(context),
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            // Toggleable Timeline List with 48x48 min touch target
            if (history.length > 1) ...[
              Semantics(
                label: _showFullHistory
                    ? 'Hide Timeline History (${history.length} snapshots)'
                    : 'View Full Timeline History (${history.length} snapshots)',
                button: true,
                hint: 'Double tap to ${_showFullHistory ? "collapse" : "expand"} snapshot timeline',
                child: ConstrainedBox(
                  constraints: AnalysisA11y.minTouchTargetConstraints,
                  child: InkWell(
                    onTap: () {
                      setState(() {
                        _showFullHistory = !_showFullHistory;
                      });
                    },
                    borderRadius: AppRadius.borderSm,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            _showFullHistory
                                ? 'Hide Timeline History'
                                : 'View Full Timeline History',
                            style: AppTypography.labelSmall.copyWith(
                              color: AnalysisA11y.primaryText(context),
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Icon(
                            _showFullHistory
                                ? Icons.keyboard_arrow_up_rounded
                                : Icons.keyboard_arrow_down_rounded,
                            size: 20,
                            color: AnalysisA11y.primaryText(context),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              if (_showFullHistory) ...[
                const Divider(color: AppColors.surfaceBorder, height: 1),
                const SizedBox(height: AppSpacing.sm),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: history.length,
                  separatorBuilder: (c, i) =>
                      const Divider(color: AppColors.surfaceBorder, height: 1),
                  itemBuilder: (context, index) {
                    final entry = history[index];
                    final isCurrent = index == 0;
                    final entryStatus =
                        AnalysisA11y.getScoreStatus(context, entry.overallScore);

                    return Semantics(
                      label: 'Historical Snapshot ${index + 1} of ${history.length}: '
                          'Date ${dateFormat.format(entry.timestamp)}, Score ${entry.overallScore}%, Grade ${entryStatus.gradeLabel} (${entryStatus.statusLabel})'
                          '${isCurrent ? ", Latest Snapshot" : ""}',
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 8,
                          horizontal: 4,
                        ),
                        child: Row(
                          children: [
                            Icon(
                              isCurrent
                                  ? Icons.radio_button_checked_rounded
                                  : Icons.radio_button_unchecked_rounded,
                              size: 16,
                              color: isCurrent
                                  ? AnalysisA11y.primaryText(context)
                                  : AnalysisA11y.textMuted(context),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    dateFormat.format(entry.timestamp),
                                    style: AppTypography.bodySmall.copyWith(
                                      fontWeight: isCurrent
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isCurrent
                                          ? AppColors.textPrimary
                                          : AnalysisA11y.textSecondary(context),
                                    ),
                                  ),
                                  if (isCurrent)
                                    Text(
                                      'Latest Snapshot',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AnalysisA11y.primaryText(context),
                                        fontWeight: FontWeight.w700,
                                        fontSize: 10,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: entryStatus.bgColor,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(
                                  color: entryStatus.borderColor,
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    entryStatus.icon,
                                    size: 11,
                                    color: entryStatus.textColor,
                                  ),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${entry.overallScore}% (${entryStatus.gradeLabel})',
                                    style: AppTypography.labelSmall.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: entryStatus.textColor,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTrendBadge(BuildContext context, ScoreEvolution evolution) {
    Color textColor;
    Color bgColor;
    Color borderColor;
    IconData icon;
    String label;

    switch (evolution.trend) {
      case ScoreTrend.improved:
        textColor = AnalysisA11y.successText(context);
        bgColor = AnalysisA11y.successBg(context);
        borderColor = AnalysisA11y.successBorder(context);
        icon = Icons.trending_up_rounded;
        label = 'Improved';
        break;
      case ScoreTrend.declined:
        textColor = AnalysisA11y.errorText(context);
        bgColor = AnalysisA11y.errorBg(context);
        borderColor = AnalysisA11y.errorBorder(context);
        icon = Icons.trending_down_rounded;
        label = 'Declined';
        break;
      case ScoreTrend.unchanged:
        textColor = AnalysisA11y.warningText(context);
        bgColor = AnalysisA11y.warningBg(context);
        borderColor = AnalysisA11y.warningBorder(context);
        icon = Icons.trending_flat_rounded;
        label = 'Unchanged';
        break;
      case ScoreTrend.initial:
        textColor = AnalysisA11y.primaryText(context);
        bgColor = AnalysisA11y.primaryBg(context);
        borderColor = AnalysisA11y.primaryBorder(context);
        icon = Icons.star_outline_rounded;
        label = 'Initial Baseline';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: textColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreColumn({
    required BuildContext context,
    required String label,
    required String score,
    required String subtext,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AnalysisA11y.textMuted(context),
            fontSize: 10,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          score,
          style: AppTypography.titleLarge.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          subtext,
          style: AppTypography.labelSmall.copyWith(
            color: AnalysisA11y.textSecondary(context),
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildDiffColumn(BuildContext context, ScoreEvolution evolution) {
    final diff = evolution.scoreDifference ?? 0;
    final isPos = diff > 0;
    final isNeg = diff < 0;
    final color = isPos
        ? AnalysisA11y.successText(context)
        : isNeg
            ? AnalysisA11y.errorText(context)
            : AnalysisA11y.warningText(context);

    final diffText = isPos ? '+$diff' : '$diff';
    final subText = isPos ? 'Points gained' : isNeg ? 'Points lost' : 'No change';

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          'CHANGE',
          style: AppTypography.labelSmall.copyWith(
            color: AnalysisA11y.textMuted(context),
            fontSize: 10,
            letterSpacing: 0.8,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          diffText,
          style: AppTypography.titleLarge.copyWith(
            color: color,
            fontWeight: FontWeight.w800,
          ),
        ),
        Text(
          subText,
          style: AppTypography.labelSmall.copyWith(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: 10,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSectionDiffChip(BuildContext context, SectionScoreDiff diff) {
    final isPos = diff.isImprovement;
    final textColor = isPos
        ? AnalysisA11y.successText(context)
        : AnalysisA11y.errorText(context);
    final bgColor = isPos
        ? AnalysisA11y.successBg(context)
        : AnalysisA11y.errorBg(context);
    final borderColor = isPos
        ? AnalysisA11y.successBorder(context)
        : AnalysisA11y.errorBorder(context);

    final title = _formatCategoryTitle(diff.categoryKey);
    final sign = isPos ? '+' : '';
    final icon = isPos ? Icons.arrow_upward_rounded : Icons.arrow_downward_rounded;

    return Semantics(
      label: '$title score difference: $sign${diff.difference}% (${isPos ? "Improved" : "Declined"})',
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: borderColor, width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 12, color: textColor),
            const SizedBox(width: 4),
            Text(
              '$title $sign${diff.difference}%',
              style: AppTypography.labelSmall.copyWith(
                color: textColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

