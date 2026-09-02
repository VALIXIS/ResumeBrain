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

/// Card widget displaying the score evolution, trend comparison, and historical timeline
/// for a resume document.
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

    return Semantics(
      label: 'Score evolution: Current score ${evolution.currentScore}, '
          '${evolution.hasPrevious ? "Previous score ${evolution.previousScore}, change ${evolution.scoreDifference! > 0 ? "+${evolution.scoreDifference}" : "${evolution.scoreDifference}"}" : "Initial analysis"}',
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
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: AppRadius.borderSm,
                  ),
                  child: const Icon(
                    Icons.timeline_rounded,
                    color: AppColors.primary,
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
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        '${history.length} snapshot${history.length == 1 ? "" : "s"} recorded',
                        style: AppTypography.bodySmall
                            .copyWith(color: AppColors.textMuted),
                      ),
                    ],
                  ),
                ),
                _buildTrendBadge(evolution),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildScoreColumn(
                      label: 'CURRENT',
                      score: '${evolution.currentScore}',
                      subtext: dateFormat.format(evolution.currentDate),
                      color: AppColors.primary,
                    ),
                    Container(
                      height: 36,
                      width: 1,
                      color: AppColors.surfaceBorder,
                    ),
                    _buildScoreColumn(
                      label: 'PREVIOUS',
                      score: '${evolution.previousScore}',
                      subtext: evolution.previousDate != null
                          ? dateFormat.format(evolution.previousDate!)
                          : '-',
                      color: AppColors.textSecondary,
                    ),
                    Container(
                      height: 36,
                      width: 1,
                      color: AppColors.surfaceBorder,
                    ),
                    _buildDiffColumn(evolution),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),

              // Section-level evolution badges
              if (evolution.sectionDiffs.any((s) => s.difference != null && s.difference != 0)) ...[
                Text(
                  'Section Improvements',
                  style: AppTypography.labelSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: evolution.sectionDiffs
                      .where((s) => s.difference != null && s.difference != 0)
                      .map((s) => _buildSectionDiffChip(s))
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
                    const Icon(
                      Icons.info_outline_rounded,
                      color: AppColors.primary,
                      size: 22,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Initial analysis snapshot saved. Re-analyze your resume after making edits to track score evolution over time.',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
            ],

            // Toggleable Timeline List
            if (history.length > 1) ...[
              InkWell(
                onTap: () {
                  setState(() {
                    _showFullHistory = !_showFullHistory;
                  });
                },
                borderRadius: AppRadius.borderSm,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        _showFullHistory
                            ? 'Hide Timeline History'
                            : 'View Full Timeline History',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        _showFullHistory
                            ? Icons.keyboard_arrow_up_rounded
                            : Icons.keyboard_arrow_down_rounded,
                        size: 18,
                        color: AppColors.primary,
                      ),
                    ],
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
                    return Padding(
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
                            size: 14,
                            color: isCurrent
                                ? AppColors.primary
                                : AppColors.textMuted,
                          ),
                          const SizedBox(width: 8),
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
                                        : AppColors.textSecondary,
                                  ),
                                ),
                                if (isCurrent)
                                  Text(
                                    'Latest Snapshot',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: AppColors.primary,
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
                              color: AppColors.surface,
                              borderRadius: BorderRadius.circular(10),
                              border:
                                  Border.all(color: AppColors.surfaceBorder),
                            ),
                            child: Text(
                              '${entry.overallScore}%',
                              style: AppTypography.labelSmall.copyWith(
                                fontWeight: FontWeight.bold,
                                color: entry.overallScore >= 80
                                    ? AppColors.accentGreen
                                    : entry.overallScore >= 60
                                        ? AppColors.accentOrange
                                        : AppColors.accentRed,
                              ),
                            ),
                          ),
                        ],
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

  Widget _buildTrendBadge(ScoreEvolution evolution) {
    Color color;
    IconData icon;
    String label;

    switch (evolution.trend) {
      case ScoreTrend.improved:
        color = AppColors.accentGreen;
        icon = Icons.trending_up_rounded;
        label = 'Improved';
        break;
      case ScoreTrend.declined:
        color = AppColors.accentRed;
        icon = Icons.trending_down_rounded;
        label = 'Declined';
        break;
      case ScoreTrend.unchanged:
        color = AppColors.accentOrange;
        icon = Icons.trending_flat_rounded;
        label = 'Unchanged';
        break;
      case ScoreTrend.initial:
        color = AppColors.primary;
        icon = Icons.star_outline_rounded;
        label = 'Initial Baseline';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTypography.labelSmall.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreColumn({
    required String label,
    required String score,
    required String subtext,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
            fontSize: 10,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          score,
          style: AppTypography.titleLarge.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          subtext,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
            fontSize: 10,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildDiffColumn(ScoreEvolution evolution) {
    final diff = evolution.scoreDifference ?? 0;
    final isPos = diff > 0;
    final isNeg = diff < 0;
    final color = isPos
        ? AppColors.accentGreen
        : isNeg
            ? AppColors.accentRed
            : AppColors.accentOrange;

    final diffText = isPos ? '+$diff' : '$diff';

    return Column(
      children: [
        Text(
          'CHANGE',
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.textMuted,
            fontSize: 10,
            letterSpacing: 0.8,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          diffText,
          style: AppTypography.titleLarge.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        Text(
          isPos ? 'Points gained' : isNeg ? 'Points lost' : 'No change',
          style: AppTypography.labelSmall.copyWith(
            color: color,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildSectionDiffChip(SectionScoreDiff diff) {
    final isPos = diff.isImprovement;
    final color = isPos ? AppColors.accentGreen : AppColors.accentRed;
    final title = _formatCategoryTitle(diff.categoryKey);
    final sign = isPos ? '+' : '';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        '$title $sign${diff.difference}%',
        style: AppTypography.labelSmall.copyWith(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
