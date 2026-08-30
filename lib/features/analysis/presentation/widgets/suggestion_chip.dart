import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/custom_card.dart';

/// Card widget displaying an actionable resume improvement suggestion.
class SuggestionChipWidget extends StatelessWidget {
  final String suggestion;
  final VoidCallback? onTap;

  const SuggestionChipWidget({
    super.key,
    required this.suggestion,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Suggestion: $suggestion',
      child: AppCard(
        color: AppColors.surfaceLight,
        padding: const EdgeInsets.all(AppSpacing.md),
        onTap: onTap,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.accentPurple.withValues(alpha: 0.15),
                borderRadius: AppRadius.borderSm,
              ),
              child: const Icon(
                Icons.lightbulb_outline_rounded,
                size: 18,
                color: AppColors.accentPurple,
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Text(
                suggestion,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.textPrimary,
                  height: 1.35,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
