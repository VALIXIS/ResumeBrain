import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/smooth_page_route.dart';
import '../../../data/models/resume_models.dart';
import '../../ai/presentation/ai_mock_interview_screen.dart';
import '../models/resume_template.dart';
import '../services/template_registry.dart';

class TemplateSelectorScreen extends ConsumerStatefulWidget {
  const TemplateSelectorScreen({super.key});

  @override
  ConsumerState<TemplateSelectorScreen> createState() => _TemplateSelectorScreenState();
}

class _TemplateSelectorScreenState extends ConsumerState<TemplateSelectorScreen> {
  late final PageController _carouselController;
  int _currentCarouselIndex = 0;

  @override
  void initState() {
    super.initState();
    _carouselController = PageController(viewportFraction: 0.86);
  }

  @override
  void dispose() {
    _carouselController.dispose();
    super.dispose();
  }

  Future<void> _handleTemplateTap(
    BuildContext context,
    ResumeTemplate template,
    bool isLocked,
    bool isSelected,
  ) async {
    if (isLocked) {
      final shouldWatchAd = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Row(
            children: [
              const Icon(Icons.lock_outline_rounded, color: Colors.amber),
              const SizedBox(width: 8),
              Expanded(
                child: Text('Unlock ${template.name}', style: AppTypography.titleMedium),
              ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Executive templates feature high-density serif typography and leadership section formatting optimized for Fortune 500 ATS scanners.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.12),
                  borderRadius: AppRadius.borderSm,
                  border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.card_giftcard_rounded, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Watch a short 5-second video ad to permanently unlock this template for your current session and earn +1 Free AI Interview Session Token!',
                        style: AppTypography.labelSmall.copyWith(color: Colors.amber),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
              label: const Text('Watch Video Ad'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () => Navigator.of(ctx).pop(true),
            ),
          ],
        ),
      );

      if (shouldWatchAd == true && context.mounted) {
        final adService = ref.read(adServiceProvider);
        final success = await adService.showRewardedAd(
          context: context,
          unlockTemplateId: template.id,
          customTitle: 'Executive Template & AI Token Sponsor',
          rewardType: 'ai_interview_token',
          rewardAmount: 1,
          onUserEarnedReward: (reward) {
            // Apply template immediately
            ref.read(currentResumeProvider.notifier).setTemplate(template.id);
            if (context.mounted) {
              AppSnackBar.showSuccess(
                context,
                '🎉 ${template.name} unlocked for this session! +1 Free AI Interview Token granted.',
              );
            }
          },
        );

        if (!success && context.mounted) {
          AppSnackBar.showInfo(
            context,
            'Video ad was closed before completion. Watch the full ad to unlock the template.',
          );
        }
      }
    } else {
      // Free or unlocked template: apply directly
      ref.read(currentResumeProvider.notifier).setTemplate(template.id);
      AppSnackBar.showSuccess(context, '${template.name} applied to your resume.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final resume = ref.watch(currentResumeProvider);
    final resumesList = ref.watch(resumesListProvider).value ?? [];
    final templates = TemplateRegistry.allTemplates;
    final unlockedTemplates = ref.watch(sessionUnlockedTemplatesProvider);
    final interviewTokens = ref.watch(aiInterviewTokensProvider);

    // Auto-select first resume if none active
    if (resume == null && resumesList.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(currentResumeProvider.notifier).setResume(resumesList.first);
      });
    }

    final selectedId = resume?.templateId ?? 'modern_classic';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Select Template'),
        actions: [
          // AI Interview Tokens Chip
          Padding(
            padding: const EdgeInsets.only(right: 12.0),
            child: ActionChip(
              avatar: const Icon(Icons.token_rounded, color: Colors.amber, size: 16),
              label: Text(
                '$interviewTokens Tokens',
                style: AppTypography.labelSmall.copyWith(
                  color: Colors.amber,
                  fontWeight: FontWeight.bold,
                ),
              ),
              backgroundColor: Colors.amber.withValues(alpha: 0.15),
              side: const BorderSide(color: Colors.amber),
              tooltip: 'AI Mock Interview Tokens. Tap to open coach.',
              onPressed: () {
                Navigator.push(
                  context,
                  SmoothPageRoute(page: const AIMockInterviewScreen()),
                );
              },
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (resume != null) ...[
              AppCard(
                color: AppColors.surfaceLight,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  children: [
                    const Icon(Icons.description_outlined, color: AppColors.primary, size: 20),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('ACTIVE RESUME',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.primary,
                                fontSize: 10,
                              )),
                          Text(resume.title, style: AppTypography.titleMedium.copyWith(fontSize: 14)),
                        ],
                      ),
                    ),
                    if (resumesList.length > 1)
                      PopupMenuButton<Resume>(
                        icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.primary),
                        tooltip: 'Switch Resume',
                        onSelected: (selected) {
                          ref.read(currentResumeProvider.notifier).setResume(selected);
                        },
                        itemBuilder: (context) => resumesList.map((r) {
                          return PopupMenuItem<Resume>(
                            value: r,
                            child: Text(r.title),
                          );
                        }).toList(),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.md),
            ],

            Text('Template Showcase', style: AppTypography.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Swipe to preview designs. Executive templates can be unlocked for your active session by viewing a sponsored ad.',
              style: AppTypography.bodySmall,
            ),
            const SizedBox(height: AppSpacing.md),

            // 1. Template Selection Carousel
            SizedBox(
              height: 270,
              child: PageView.builder(
                controller: _carouselController,
                itemCount: templates.length,
                onPageChanged: (index) {
                  setState(() => _currentCarouselIndex = index);
                },
                itemBuilder: (context, index) {
                  final template = templates[index];
                  final isSelected = template.id == selectedId;
                  final isExecutive = template.isExecutive;
                  final isUnlocked = !isExecutive || unlockedTemplates.contains(template.id);
                  final isLocked = isExecutive && !isUnlocked;

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                    child: _buildCarouselCard(
                      template: template,
                      isSelected: isSelected,
                      isExecutive: isExecutive,
                      isLocked: isLocked,
                      isUnlocked: isUnlocked,
                      onTap: () => _handleTemplateTap(context, template, isLocked, isSelected),
                    ),
                  );
                },
              ),
            ),

            const SizedBox(height: 12),

            // Carousel Dots Indicator
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(templates.length, (index) {
                  final isActive = index == _currentCarouselIndex;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: isActive ? 20 : 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isActive ? AppColors.primary : AppColors.surfaceBorder,
                      borderRadius: AppRadius.borderPill,
                    ),
                  );
                }),
              ),
            ),

            const SizedBox(height: AppSpacing.xl),

            // 2. All Templates List View
            Text('All Resume Formats', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.sm),

            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: templates.length,
              separatorBuilder: (c, i) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (context, index) {
                final template = templates[index];
                final isSelected = template.id == selectedId;
                final isExecutive = template.isExecutive;
                final isUnlocked = !isExecutive || unlockedTemplates.contains(template.id);
                final isLocked = isExecutive && !isUnlocked;

                return AppCard(
                  color: isSelected
                      ? AppColors.primary.withValues(alpha: 0.1)
                      : (isLocked ? Colors.amber.withValues(alpha: 0.05) : AppColors.surface),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.primary
                        : (isLocked ? Colors.amber.withValues(alpha: 0.5) : AppColors.surfaceBorder),
                    width: isSelected || isLocked ? 1.5 : 1,
                  ),
                  onTap: () => _handleTemplateTap(context, template, isLocked, isSelected),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Thumbnail Icon / Lock Badge
                      Stack(
                        children: [
                          Container(
                            width: 60,
                            height: 80,
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: AppRadius.borderSm,
                              border: Border.all(
                                color: isLocked ? Colors.amber.withValues(alpha: 0.4) : AppColors.surfaceBorder,
                              ),
                            ),
                            child: Icon(
                              isLocked
                                  ? Icons.lock_rounded
                                  : Icons.description_outlined,
                              size: 32,
                              color: isLocked
                                  ? Colors.amber
                                  : (isSelected ? AppColors.primary : AppColors.textMuted),
                            ),
                          ),
                          if (isLocked)
                            Positioned(
                              top: 2,
                              right: 2,
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: const BoxDecoration(
                                  color: Colors.amber,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.lock, size: 10, color: Colors.black87),
                              ),
                            ),
                        ],
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
                                if (isExecutive) ...[
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: isLocked
                                          ? Colors.amber.withValues(alpha: 0.2)
                                          : AppColors.accentGreen.withValues(alpha: 0.2),
                                      borderRadius: AppRadius.borderSm,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(
                                          isLocked ? Icons.lock : Icons.lock_open_rounded,
                                          size: 11,
                                          color: isLocked ? Colors.amber : AppColors.accentGreen,
                                        ),
                                        const SizedBox(width: 4),
                                        Text(
                                          isLocked ? 'EXECUTIVE' : 'UNLOCKED',
                                          style: AppTypography.labelSmall.copyWith(
                                            color: isLocked ? Colors.amber : AppColors.accentGreen,
                                            fontWeight: FontWeight.bold,
                                            fontSize: 9,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                ],
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
                                        fontSize: 9,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(template.description, style: AppTypography.bodySmall),
                            const SizedBox(height: 12),

                            // Bottom Item Button
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
                            else if (isLocked)
                              AppButton(
                                text: 'Watch Ad to Unlock',
                                icon: Icons.play_circle_fill_rounded,
                                variant: AppButtonVariant.primary,
                                isFullWidth: false,
                                onPressed: () =>
                                    _handleTemplateTap(context, template, isLocked, isSelected),
                              )
                            else
                              AppButton(
                                text: 'Apply Template',
                                variant: AppButtonVariant.outline,
                                isFullWidth: false,
                                onPressed: () =>
                                    _handleTemplateTap(context, template, isLocked, isSelected),
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

  Widget _buildCarouselCard({
    required ResumeTemplate template,
    required bool isSelected,
    required bool isExecutive,
    required bool isLocked,
    required bool isUnlocked,
    required VoidCallback onTap,
  }) {
    return AppCard(
      color: isSelected
          ? AppColors.primary.withValues(alpha: 0.12)
          : (isLocked ? const Color(0xFF261D10) : AppColors.surface),
      border: Border.all(
        color: isSelected
            ? AppColors.primary
            : (isLocked ? Colors.amber.withValues(alpha: 0.6) : AppColors.surfaceBorder),
        width: isSelected || isLocked ? 2 : 1,
      ),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Badges & Lock State
          Row(
            children: [
              if (isExecutive)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: isLocked
                        ? Colors.amber.withValues(alpha: 0.25)
                        : AppColors.accentGreen.withValues(alpha: 0.25),
                    borderRadius: AppRadius.borderSm,
                    border: Border.all(
                      color: isLocked ? Colors.amber : AppColors.accentGreen,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isLocked ? Icons.lock_rounded : Icons.lock_open_rounded,
                        size: 13,
                        color: isLocked ? Colors.amber : AppColors.accentGreen,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        isLocked ? 'EXECUTIVE • LOCKED' : 'EXECUTIVE • UNLOCKED',
                        style: AppTypography.labelSmall.copyWith(
                          color: isLocked ? Colors.amber : AppColors.accentGreen,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.accentTeal.withValues(alpha: 0.15),
                    borderRadius: AppRadius.borderSm,
                  ),
                  child: Text(
                    'FREE ATS TEMPLATE',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.accentTeal,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              const Spacer(),
              if (template.isAtsFriendly)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.accentGreen.withValues(alpha: 0.2),
                    borderRadius: AppRadius.borderSm,
                  ),
                  child: Text(
                    'ATS 100%',
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.accentGreen,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: 12),

          // Central Icon Mockup Canvas
          Expanded(
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: isLocked
                        ? Colors.black.withValues(alpha: 0.3)
                        : AppColors.surfaceLight,
                    borderRadius: AppRadius.borderMd,
                    border: Border.all(
                      color: isLocked ? Colors.amber.withValues(alpha: 0.25) : AppColors.surfaceBorder,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isLocked ? Icons.lock_outline_rounded : Icons.description_outlined,
                        size: 44,
                        color: isLocked
                            ? Colors.amber
                            : (isSelected ? AppColors.primary : AppColors.textMuted),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        template.name,
                        style: AppTypography.titleMedium.copyWith(
                          color: isLocked ? Colors.amber.shade200 : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isLocked)
                  Positioned(
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.75),
                        borderRadius: AppRadius.borderSm,
                      ),
                      child: Text(
                        'Tap to Watch Ad & Unlock',
                        style: AppTypography.labelSmall.copyWith(
                          color: Colors.amber,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          Text(
            template.description,
            style: AppTypography.bodySmall,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),

          const SizedBox(height: 12),

          // Action Button
          if (isSelected)
            Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 18),
                const SizedBox(width: 6),
                Text('Active Template', style: AppTypography.labelLarge.copyWith(color: AppColors.primary)),
              ],
            )
          else if (isLocked)
            AppButton(
              text: 'Watch Video Ad to Unlock (+1 Token)',
              icon: Icons.play_circle_fill_rounded,
              variant: AppButtonVariant.primary,
              isFullWidth: true,
              onPressed: onTap,
            )
          else
            AppButton(
              text: 'Apply Template',
              variant: AppButtonVariant.outline,
              isFullWidth: true,
              onPressed: onTap,
            ),
        ],
      ),
    );
  }
}
