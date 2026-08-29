import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/custom_card.dart';
import '../../models/analysis_models.dart';

/// Card widget displaying an actionable resume improvement suggestion.
class SuggestionChipWidget extends StatelessWidget {
  final AnalysisSuggestion suggestion;
  final VoidCallback? onTap;

  const SuggestionChipWidget({
    super.key,
    required this.suggestion,
    this.onTap,
  });

  Color _getPriorityColor(SuggestionPriority priority) {
    switch (priority) {
      case SuggestionPriority.high:
        return AppColors.accentRed;
      case SuggestionPriority.medium:
        return AppColors.accentOrange;
      case SuggestionPriority.low:
        return AppColors.accentTeal;
    }
  }

  String _getPriorityLabel(SuggestionPriority priority) {
    switch (priority) {
      case SuggestionPriority.high:
        return 'HIGH PRIORITY';
      case SuggestionPriority.medium:
        return 'RECOMMENDED';
      case SuggestionPriority.low:
        return 'OPTIONAL';
    }
  }

  IconData _getPriorityIcon(SuggestionPriority priority) {
    switch (priority) {
      case SuggestionPriority.high:
        return Icons.priority_high_rounded;
      case SuggestionPriority.medium:
        return Icons.lightbulb_outline_rounded;
      case SuggestionPriority.low:
        return Icons.tips_and_updates_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final priorityColor = _getPriorityColor(suggestion.priority);
    final priorityLabel = _getPriorityLabel(suggestion.priority);
    final priorityIcon = _getPriorityIcon(suggestion.priority);

    return AppCard(
      color: AppColors.surfaceLight,
      padding: const EdgeInsets.all(AppSpacing.md),
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: priorityColor.withValues(alpha: 0.15),
              borderRadius: AppRadius.borderSm,
            ),
            child: Icon(
              priorityIcon,
              size: 18,
              color: priorityColor,
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (suggestion.section != null) ...[
                      Text(
                        suggestion.section!.toUpperCase(),
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                          fontSize: 10,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '•',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 10),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 1.5,
                      ),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        priorityLabel,
                        style: AppTypography.labelSmall.copyWith(
                          color: priorityColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 9,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  suggestion.text,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
