import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_radius.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/custom_card.dart';
import 'analysis_accessibility_helper.dart';

/// Card widget displaying an actionable resume improvement suggestion.
/// Hardened with 48x48 minimum touch targets, WCAG AAA contrast, and comprehensive Semantics.
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
      label: 'Actionable suggestion: $suggestion',
      button: onTap != null,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minHeight: onTap != null ? AnalysisA11y.minTouchTargetSize : 0.0,
        ),
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
                  color: AnalysisA11y.purpleBg(context),
                  borderRadius: AppRadius.borderSm,
                  border: Border.all(
                    color: AnalysisA11y.purpleBorder(context).withValues(alpha: 0.3),
                  ),
                ),
                child: Icon(
                  Icons.lightbulb_outline_rounded,
                  size: 18,
                  color: AnalysisA11y.purpleText(context),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  suggestion,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.textPrimary,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

