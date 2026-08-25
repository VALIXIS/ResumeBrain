import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../services/template_registry.dart';

class TemplateSelectorScreen extends ConsumerWidget {
  const TemplateSelectorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resume = ref.watch(currentResumeProvider);
    final templates = TemplateRegistry.allTemplates;
    final selectedId = resume?.templateId ?? 'modern_classic';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Template'),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Professional ATS Templates', style: AppTypography.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Select a clean, recruiter-approved format for your resume.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.lg),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: templates.length,
              separatorBuilder: (c, i) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final template = templates[index];
                final isSelected = template.id == selectedId;

                return AppCard(
                  color: isSelected ? AppColors.primary.withValues(alpha: 0.1) : AppColors.surface,
                  border: Border.all(
                    color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
                    width: isSelected ? 2 : 1,
                  ),
                  onTap: () {
                    ref.read(currentResumeProvider.notifier).setTemplate(template.id);
                  },
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 60,
                        height: 80,
                        decoration: BoxDecoration(
                          color: AppColors.surfaceLight,
                          borderRadius: AppRadius.borderSm,
                          border: Border.all(color: AppColors.surfaceBorder),
                        ),
                        child: Icon(
                          Icons.description_outlined,
                          size: 32,
                          color: isSelected ? AppColors.primary : AppColors.textMuted,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(template.name, style: AppTypography.titleMedium),
                                ),
                                if (template.isAtsFriendly)
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.accentGreen.withValues(alpha: 0.2),
                                      borderRadius: AppRadius.borderSm,
                                    ),
                                    child: Text(
                                      'ATS OK',
                                      style: AppTypography.labelSmall.copyWith(
                                        color: AppColors.accentGreen,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(template.description, style: AppTypography.bodySmall),
                            const SizedBox(height: 12),
                            if (isSelected)
                              Row(
                                children: [
                                  const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Active Template',
                                    style: AppTypography.labelLarge.copyWith(color: AppColors.primary),
                                  ),
                                ],
                              )
                            else
                              AppButton(
                                text: 'Apply Template',
                                variant: AppButtonVariant.outline,
                                isFullWidth: false,
                                onPressed: () {
                                  ref.read(currentResumeProvider.notifier).setTemplate(template.id);
                                },
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
