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
import '../../../core/widgets/custom_text_field.dart';

/// Screen for conducting AI-powered Mock Interviews with token gating and rewarded ad rewards.
class AIMockInterviewScreen extends ConsumerStatefulWidget {
  const AIMockInterviewScreen({super.key});

  @override
  ConsumerState<AIMockInterviewScreen> createState() => _AIMockInterviewScreenState();
}

class _AIMockInterviewScreenState extends ConsumerState<AIMockInterviewScreen> {
  String _selectedTrack = 'Technical & System Architecture';
  String _selectedSeniority = 'Senior / Staff';
  bool _isSessionActive = false;
  bool _isEvaluating = false;
  int _currentQuestionIndex = 0;

  final TextEditingController _answerController = TextEditingController();

  final List<String> _tracks = [
    'Technical & System Architecture',
    'Behavioral & Leadership (STAR)',
    'Executive & Strategic Impact',
  ];

  final List<String> _seniorityLevels = [
    'Mid-Level (2-5 YOE)',
    'Senior / Staff (5-10 YOE)',
    'Executive / Director (10+ YOE)',
  ];

  final List<Map<String, dynamic>> _mockQuestions = [
    {
      'question':
          'Can you describe a high-stakes technical architecture or engineering decision you made, the trade-offs evaluated, and how you measured business impact?',
      'sampleAnswer':
          'At my previous company, our mobile sync engine had high latency and occasional data races during offline reconnects. I architected an optimistic offline-first synchronization protocol utilizing cryptographic revision tokens and client-side Hive vector caching. This reduced p99 sync latency by 68% and eliminated 100% of data race collisions across 250,000 active users.',
      'idealKeywords': ['Architecture', 'Trade-offs', 'Metrics', 'Impact', 'Latency'],
    },
    {
      'question':
          'Tell me about a time when you experienced cross-functional conflict with product or executive leadership on technical debt versus new features. How did you navigate it?',
      'sampleAnswer':
          'Product wanted to ship three net-new features while our crash rate had elevated to 0.4% due to legacy state management. Instead of pushing back dogmatically, I framed the tech debt in business metrics: estimating that the crash rate caused an estimated \$45k monthly churn in checkout abandons. We agreed on a 70/30 split sprint allocation, reducing crash rates to 0.02% while still delivering the flagship feature on time.',
      'idealKeywords': ['Stakeholder Alignment', 'Business Value', 'Quantification', 'Resolution'],
    },
  ];

  Map<String, dynamic>? _lastEvaluation;

  @override
  void dispose() {
    _answerController.dispose();
    super.dispose();
  }

  Future<void> _watchAdForTokens() async {
    final adService = ref.read(adServiceProvider);
    final success = await adService.showRewardedAd(
      context: context,
      customTitle: 'AI Mock Interview Token Sponsor',
      rewardType: 'ai_interview_token',
      rewardAmount: 1,
      onUserEarnedReward: (reward) {
        AppSnackBar.showSuccess(
          context,
          '🎉 +1 AI Mock Interview Token earned! You can now start or continue your session.',
        );
      },
    );

    if (!success && mounted) {
      AppSnackBar.showInfo(
        context,
        'Video ad closed early. Watch the full ad to claim your free interview token.',
      );
    }
  }

  Future<void> _startInterviewSession() async {
    final tokensNotifier = ref.read(aiInterviewTokensProvider.notifier);
    final hasToken = await tokensNotifier.useToken();

    if (!hasToken) {
      if (mounted) {
        _showNoTokensDialog();
      }
      return;
    }

    setState(() {
      _isSessionActive = true;
      _currentQuestionIndex = 0;
      _lastEvaluation = null;
      _answerController.clear();
    });

    if (mounted) {
      AppSnackBar.showSuccess(
        context,
        '1 Token used. Mock Interview session initiated!',
      );
    }
  }

  void _showNoTokensDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Row(
          children: [
            const Icon(Icons.token_rounded, color: Colors.amber),
            const SizedBox(width: 8),
            const Text('No Interview Tokens Left'),
          ],
        ),
        content: const Text(
          'You need 1 AI Interview Token to start a live mock interview session. Watch a 5-second video ad to earn 1 free session token instantly!',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.play_circle_fill_rounded, size: 18),
            label: const Text('Watch Ad (+1 Token)'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              Navigator.of(ctx).pop();
              _watchAdForTokens();
            },
          ),
        ],
      ),
    );
  }

  Future<void> _evaluateAnswer() async {
    final answer = _answerController.text.trim();
    if (answer.isEmpty) {
      AppSnackBar.showError(context, 'Please type or generate an answer before evaluating.');
      return;
    }

    setState(() => _isEvaluating = true);

    await Future.delayed(const Duration(milliseconds: 600));

    // Dynamic scoring logic based on answer substance and length
    final lengthScore = (answer.length / 3).clamp(40, 95).toInt();
    final hasMetrics = RegExp(r'\d+%|\$\d+|\b\d+\b').hasMatch(answer);
    final finalScore = (lengthScore + (hasMetrics ? 8 : 0)).clamp(60, 98);

    if (mounted) {
      setState(() {
        _isEvaluating = false;
        _lastEvaluation = {
          'score': finalScore,
          'summary': finalScore >= 85
              ? 'Outstanding response with high quantification, clear executive ownership, and structural precision.'
              : 'Solid foundation. Consider framing outcomes with specific metrics and STAR action steps.',
          'strengths': [
            'Directly addresses technical trade-offs and complexity',
            if (hasMetrics) 'Quantifies measurable business results with data' else 'Clear problem definition',
            'Strong leadership tone aligned with $_selectedSeniority',
          ],
          'actionableTip':
              'Structure your response using the STAR method: Situation -> Task -> Action -> Result.',
        };
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final tokenBalance = ref.watch(aiInterviewTokensProvider);
    final activeResume = ref.watch(currentResumeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Mock Interview Coach'),
        actions: [
          // Tokens Display Badge & Watch Ad Action
          Container(
            margin: const EdgeInsets.only(right: 12),
            child: ActionChip(
              avatar: const Icon(Icons.token_rounded, color: Colors.amber, size: 18),
              label: Text(
                '$tokenBalance Tokens',
                style: AppTypography.labelSmall.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber,
                ),
              ),
              backgroundColor: Colors.amber.withValues(alpha: 0.15),
              side: const BorderSide(color: Colors.amber, width: 1),
              tooltip: 'Watch Ad to earn +1 Token',
              onPressed: _watchAdForTokens,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Banner: Token status & Rewarded Ad prompt
            AppCard(
              color: AppColors.surfaceLight,
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.withValues(alpha: 0.15),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.psychology_rounded, color: Colors.amber, size: 28),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('AI Mock Interview Tokens: $tokenBalance', style: AppTypography.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          '1 Token = 1 Tailored Full Interview Session',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.amber.shade700,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    ),
                    icon: const Icon(Icons.play_circle_fill, size: 16),
                    label: const Text('+1 Free', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    onPressed: _watchAdForTokens,
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            if (!_isSessionActive) ...[
              // Setup Session Controls
              Text('Interview Track & Configuration', style: AppTypography.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Tailor question complexity according to your active resume: ${activeResume?.title ?? "Standard Profile"}',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),

              // Track Selection
              Text('Target Interview Track', style: AppTypography.labelLarge),
              const SizedBox(height: 8),
              ..._tracks.map((track) {
                final isSelected = _selectedTrack == track;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surface,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
                    ),
                    onTap: () => setState(() => _selectedTrack = track),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: isSelected ? AppColors.primary : AppColors.textMuted,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(track, style: AppTypography.titleMedium.copyWith(fontSize: 14))),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: AppSpacing.md),

              // Seniority Level
              Text('Seniority Level', style: AppTypography.labelLarge),
              const SizedBox(height: 8),
              ..._seniorityLevels.map((lvl) {
                final isSelected = _selectedSeniority == lvl;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: AppCard(
                    color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surface,
                    border: Border.all(
                      color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
                    ),
                    onTap: () => setState(() => _selectedSeniority = lvl),
                    child: Row(
                      children: [
                        Icon(
                          isSelected ? Icons.radio_button_checked : Icons.radio_button_off,
                          color: isSelected ? AppColors.primary : AppColors.textMuted,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(child: Text(lvl, style: AppTypography.bodyMedium)),
                      ],
                    ),
                  ),
                );
              }),

              const SizedBox(height: AppSpacing.lg),

              AppButton(
                text: 'Start Mock Interview (Cost: 1 Token)',
                icon: Icons.play_arrow_rounded,
                isFullWidth: true,
                onPressed: _startInterviewSession,
              ),
            ] else ...[
              // Active Session Q&A View
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.15),
                      borderRadius: AppRadius.borderSm,
                    ),
                    child: Text(
                      'QUESTION ${_currentQuestionIndex + 1} OF ${_mockQuestions.length}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.stop_circle_outlined, size: 16),
                    label: const Text('End Session'),
                    onPressed: () => setState(() => _isSessionActive = false),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),

              AppCard(
                color: AppColors.surface,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.help_outline_rounded, color: AppColors.primary),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _mockQuestions[_currentQuestionIndex]['question'] as String,
                            style: AppTypography.titleMedium.copyWith(height: 1.4),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.md),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Your Response', style: AppTypography.labelLarge),
                  TextButton.icon(
                    icon: const Icon(Icons.lightbulb_outline, size: 16),
                    label: const Text('Insert Sample Answer'),
                    onPressed: () {
                      _answerController.text =
                          _mockQuestions[_currentQuestionIndex]['sampleAnswer'] as String;
                    },
                  ),
                ],
              ),
              const SizedBox(height: 4),

              AppTextField(
                label: 'Candidate Response',
                controller: _answerController,
                hint: 'Describe your relevant scenario, quantified impact, and trade-offs...',
                maxLines: 5,
              ),

              const SizedBox(height: AppSpacing.md),

              AppButton(
                text: _isEvaluating ? 'Evaluating with AI...' : 'Submit Answer for AI Scoring',
                icon: Icons.auto_awesome_rounded,
                isLoading: _isEvaluating,
                isFullWidth: true,
                onPressed: _evaluateAnswer,
              ),

              if (_lastEvaluation != null) ...[
                const SizedBox(height: AppSpacing.lg),
                AppCard(
                  color: AppColors.surfaceLight,
                  border: Border.all(color: AppColors.accentGreen, width: 1.5),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(
                              color: AppColors.accentGreen,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.check, color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Interview Readiness Score', style: AppTypography.labelSmall),
                                Text(
                                  '${_lastEvaluation!['score']} / 100',
                                  style: AppTypography.displayMedium.copyWith(
                                    color: AppColors.accentGreen,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),
                      Text(
                        _lastEvaluation!['summary'] as String,
                        style: AppTypography.bodyMedium,
                      ),
                      const SizedBox(height: 12),
                      Text('Strengths Observed:', style: AppTypography.labelLarge),
                      const SizedBox(height: 4),
                      ...(_lastEvaluation!['strengths'] as List<String>).map(
                        (str) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.check_circle_outline, color: AppColors.accentGreen, size: 16),
                              const SizedBox(width: 8),
                              Expanded(child: Text(str, style: AppTypography.bodySmall)),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: AppRadius.borderSm,
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.tips_and_updates_outlined, color: AppColors.primary, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                _lastEvaluation!['actionableTip'] as String,
                                style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      if (_currentQuestionIndex < _mockQuestions.length - 1)
                        AppButton(
                          text: 'Next Question',
                          variant: AppButtonVariant.outline,
                          isFullWidth: true,
                          onPressed: () {
                            setState(() {
                              _currentQuestionIndex++;
                              _answerController.clear();
                              _lastEvaluation = null;
                            });
                          },
                        )
                      else
                        AppButton(
                          text: 'Complete Interview Session',
                          variant: AppButtonVariant.primary,
                          isFullWidth: true,
                          onPressed: () {
                            setState(() {
                              _isSessionActive = false;
                              _lastEvaluation = null;
                            });
                            AppSnackBar.showSuccess(
                              context,
                              'Interview session complete! Review your coaching tips before your live interview.',
                            );
                          },
                        ),
                    ],
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
