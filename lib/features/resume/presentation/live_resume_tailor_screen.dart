import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../data/models/resume_models.dart';
import '../../ai/services/ai_service.dart';

class LiveResumeTailorScreen extends ConsumerStatefulWidget {
  const LiveResumeTailorScreen({super.key});

  @override
  ConsumerState<LiveResumeTailorScreen> createState() => _LiveResumeTailorScreenState();
}

class _LiveResumeTailorScreenState extends ConsumerState<LiveResumeTailorScreen> {
  final _jdController = TextEditingController();
  bool _isAnalyzing = false;
  AIResponse? _aiResult;

  Future<void> _tailorResume(Resume activeResume) async {
    final jdText = _jdController.text.trim();
    if (jdText.isEmpty) {
      AppSnackBar.showError(context, 'Please enter or paste a Target Job Description.');
      return;
    }

    setState(() {
      _isAnalyzing = true;
      _aiResult = null;
    });

    try {
      final aiService = ref.read(aiServiceProvider);
      final result = await aiService.tailorResume(activeResume, jdText);

      if (mounted) {
        setState(() {
          _isAnalyzing = false;
          _aiResult = result;
        });
        if (!result.isSuccess) {
          AppSnackBar.showError(context, result.errorMessage ?? 'Resume tailoring failed.');
        } else {
          AppSnackBar.showSuccess(context, 'Resume tailoring completed!');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAnalyzing = false);
        AppSnackBar.showError(context, 'Tailoring error: $e');
      }
    }
  }

  void _applyTailoredSummary(Resume activeResume, String newSummary) {
    ref.read(currentResumeProvider.notifier).updateSummary(
          ProfessionalSummary(summaryText: newSummary),
        );
    AppSnackBar.showSuccess(context, 'Applied tailored summary to active resume!');
  }

  @override
  void dispose() {
    _jdController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final activeResume = ref.watch(currentResumeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Live AI Resume Tailoring'),
      ),
      body: activeResume == null
          ? Center(
              child: Text(
                'No active resume selected.\nPlease create or select a resume from Dashboard.',
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
            )
          : SingleChildScrollView(
              padding: AppSpacing.screenPadding,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppCard(
                    child: Row(
                      children: [
                        const Icon(Icons.description_outlined, color: AppColors.primary),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Text(
                            'Active Resume: ${activeResume.title}',
                            style: AppTypography.titleMedium,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                  Text('Target Job Description', style: AppTypography.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    'Paste the target job posting below. The AI will align your summary, experience bullet points, and keywords directly with the job requirements.',
                    style: AppTypography.bodySmall,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  AppTextField(
                    controller: _jdController,
                    label: 'Job Description',
                    hint: 'Paste job duties, requirements, and tech stack here...',
                    maxLines: 6,
                  ),
                  const SizedBox(height: AppSpacing.md),
                  AppButton(
                    text: _isAnalyzing ? 'Tailoring Resume...' : 'Generate AI Tailored Resume',
                    isLoading: _isAnalyzing,
                    isFullWidth: true,
                    onPressed: () => _tailorResume(activeResume),
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  if (_aiResult != null && _aiResult!.isSuccess) ...[
                    Text('Tailored AI Output & Recommendations', style: AppTypography.titleMedium),
                    const SizedBox(height: AppSpacing.sm),
                    AppCard(
                      color: AppColors.primary.withValues(alpha: 0.08),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('AI Suggested Content', style: AppTypography.titleMedium),
                              IconButton(
                                icon: const Icon(Icons.copy, size: 18, color: AppColors.primary),
                                tooltip: 'Apply to Resume',
                                onPressed: () => _applyTailoredSummary(activeResume, _aiResult!.outputText),
                              ),
                            ],
                          ),
                          const SizedBox(height: AppSpacing.xs),
                          SelectableText(
                            _aiResult!.outputText,
                            style: AppTypography.bodyMedium,
                          ),
                          const SizedBox(height: AppSpacing.md),
                          AppButton(
                            text: '1-Click Apply to Resume Summary',
                            isFullWidth: true,
                            onPressed: () => _applyTailoredSummary(activeResume, _aiResult!.outputText),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    if (_aiResult!.suggestions.isNotEmpty) ...[
                      Text('Optimization Bullet Points', style: AppTypography.titleMedium),
                      const SizedBox(height: AppSpacing.xs),
                      ..._aiResult!.suggestions.map(
                        (sug) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle_outline, size: 18, color: AppColors.accentTeal),
                              const SizedBox(width: 8),
                              Expanded(child: Text(sug, style: AppTypography.bodySmall)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                  const SizedBox(height: AppSpacing.xxl),
                ],
              ),
            ),
    );
  }
}
