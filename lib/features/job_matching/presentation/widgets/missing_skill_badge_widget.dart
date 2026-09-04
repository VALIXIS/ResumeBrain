import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../app/providers.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/widgets/app_snackbar.dart';
import '../../../../data/models/resume_models.dart';

/// Interactive missing-skill badge widget allowing one-click skill insertion
/// into the active resume via [currentResumeProvider].
class MissingSkillBadgeWidget extends ConsumerWidget {
  final String skill;
  final VoidCallback? onInserted;

  const MissingSkillBadgeWidget({
    super.key,
    required this.skill,
    this.onInserted,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.accentOrange.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.accentOrange.withValues(alpha: 0.5)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.warning_amber_rounded,
            size: 14,
            color: AppColors.accentOrange,
          ),
          const SizedBox(width: 4),
          Text(
            skill,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.accentOrange,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(width: 6),
          InkWell(
            onTap: () {
              final activeResume = ref.read(currentResumeProvider);
              if (activeResume != null) {
                final exists = activeResume.skills.any(
                  (s) => s.name.trim().toLowerCase() == skill.trim().toLowerCase(),
                );
                if (!exists) {
                  ref.read(currentResumeProvider.notifier).addSkill(Skill(name: skill));
                }
              }

              AppSnackBar.show(
                context,
                message: 'Added "$skill" to your resume skills!',
                variant: AppSnackBarVariant.success,
              );

              onInserted?.call();
            },
            borderRadius: BorderRadius.circular(12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accentOrange,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.add, size: 12, color: Colors.white),
                  const SizedBox(width: 2),
                  Text(
                    'Add',
                    style: AppTypography.labelSmall.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
