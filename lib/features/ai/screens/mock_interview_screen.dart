import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../app/providers.dart';
import '../../../data/models/resume_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../services/mock_interview_service.dart';

/// Screen for AI Behavioral Mock Interview Coach powered by Google Gemini and STAR Method.
class MockInterviewScreen extends ConsumerStatefulWidget {
  const MockInterviewScreen({super.key});

  @override
  ConsumerState<MockInterviewScreen> createState() => _MockInterviewScreenState();
}

class _MockInterviewScreenState extends ConsumerState<MockInterviewScreen> {
  final MockInterviewService _interviewService = MockInterviewService();

  String _selectedTrack = 'Behavioral & Leadership (STAR)';
  String _selectedSeniority = 'Senior / Staff (5-10 YOE)';

  bool _isSessionActive = false;
  bool _isGeneratingQuestions = false;
  bool _isEvaluating = false;
  bool _isCompleted = false;

  int _currentQuestionIndex = 0;
  List<InterviewQuestion> _questions = [];
  final List<QuestionEvaluation> _evaluations = [];

  final TextEditingController _answerController = TextEditingController();
  QuestionEvaluation? _currentEvaluation;
  InterviewSessionResult? _finalResult;

  final List<String> _tracks = [
    'Behavioral & Leadership (STAR)',
    'Technical & System Architecture',
    'Executive & Strategic Impact',
  ];

  final List<String> _seniorityLevels = [
    'Mid-Level (2-5 YOE)',
    'Senior / Staff (5-10 YOE)',
    'Executive / Director (10+ YOE)',
  ];

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
      onUserEarnedReward: (_) {
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
      if (mounted) _showNoTokensDialog();
      return;
    }

    setState(() {
      _isGeneratingQuestions = true;
      _isSessionActive = false;
      _isCompleted = false;
      _currentQuestionIndex = 0;
      _evaluations.clear();
      _questions.clear();
      _currentEvaluation = null;
      _finalResult = null;
      _answerController.clear();
    });

    final activeResume = ref.read(currentResumeProvider);
    final keyStorage = ref.read(aiKeyStorageServiceProvider);
    final apiKey = await keyStorage.getGeminiKey();

    final generatedQuestions = await _interviewService.generate5Questions(
      resume: activeResume,
      track: _selectedTrack,
      seniority: _selectedSeniority,
      apiKey: apiKey,
    );

    if (mounted) {
      setState(() {
        _questions = generatedQuestions;
        _isGeneratingQuestions = false;
        _isSessionActive = true;
      });

      AppSnackBar.showSuccess(
        context,
        '1 Token used. 5 Tailored STAR interview questions generated!',
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
          'You need 1 AI Interview Token to start a 5-question behavioral mock interview session tailored to your resume.',
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

  Future<void> _evaluateCurrentAnswer() async {
    final answer = _answerController.text.trim();
    if (answer.isEmpty) {
      AppSnackBar.showError(context, 'Please type or insert an answer before submitting for scoring.');
      return;
    }

    if (_questions.isEmpty || _currentQuestionIndex >= _questions.length) return;

    setState(() => _isEvaluating = true);

    final currentQuestion = _questions[_currentQuestionIndex];
    final activeResume = ref.read(currentResumeProvider);
    final keyStorage = ref.read(aiKeyStorageServiceProvider);
    final apiKey = await keyStorage.getGeminiKey();

    final eval = await _interviewService.evaluateAnswer(
      question: currentQuestion,
      candidateAnswer: answer,
      resume: activeResume,
      seniority: _selectedSeniority,
      apiKey: apiKey,
    );

    if (mounted) {
      setState(() {
        _isEvaluating = false;
        _currentEvaluation = eval;
      });
    }
  }

  void _nextQuestion() {
    if (_currentEvaluation != null) {
      _evaluations.add(_currentEvaluation!);
    }

    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _currentEvaluation = null;
        _answerController.clear();
      });
    } else {
      _finishInterview();
    }
  }

  void _finishInterview() {
    final result = _interviewService.computeFinalScorecard(_evaluations);
    setState(() {
      _finalResult = result;
      _isSessionActive = false;
      _isCompleted = true;
    });

    AppSnackBar.showSuccess(
      context,
      '🎉 Interview complete! Your STAR Readiness Scorecard is ready.',
    );
  }

  void _restartSession() {
    setState(() {
      _isSessionActive = false;
      _isCompleted = false;
      _isGeneratingQuestions = false;
      _currentQuestionIndex = 0;
      _questions.clear();
      _evaluations.clear();
      _currentEvaluation = null;
      _finalResult = null;
      _answerController.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    final tokenBalance = ref.watch(aiInterviewTokensProvider);
    final activeResume = ref.watch(currentResumeProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Behavioral Interview Coach'),
        actions: [
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
            // Banner Card
            _buildHeaderBanner(tokenBalance),
            const SizedBox(height: AppSpacing.lg),

            if (_isGeneratingQuestions) ...[
              _buildLoadingState(),
            ] else if (!_isSessionActive && !_isCompleted) ...[
              _buildSetupView(activeResume),
            ] else if (_isSessionActive) ...[
              _buildQuestionSessionView(),
            ] else if (_isCompleted && _finalResult != null) ...[
              _buildScorecardView(),
            ],

            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderBanner(int tokenBalance) {
    return AppCard(
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
                Text('STAR Behavioral Coach', style: AppTypography.titleMedium),
                const SizedBox(height: 2),
                Text(
                  '1 Token = 5 Tailored Gemini Behavioral Questions',
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
    );
  }

  Widget _buildLoadingState() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(color: AppColors.primary),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Gemini AI is analyzing your resume...',
              style: AppTypography.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              'Generating 5 custom STAR behavioral interview questions tailored to your experience.',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSetupView(Resume? activeResume) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Interview Track & Configuration', style: AppTypography.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Tailor question complexity according to active profile: ${activeResume?.personalInfo.jobTitle.isNotEmpty == true ? activeResume!.personalInfo.jobTitle : (activeResume?.title ?? "Standard Software Profile")}',
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),

        // Active Resume Info Card
        if (activeResume != null) ...[
          AppCard(
            color: AppColors.surface,
            child: Row(
              children: [
                const Icon(Icons.description_outlined, color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(activeResume.title, style: AppTypography.titleMedium.copyWith(fontSize: 14)),
                      Text(
                        '${activeResume.experiences.length} Experiences • ${activeResume.skills.length} Skills • ${activeResume.projects.length} Projects',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.check_circle, color: AppColors.accentGreen, size: 20),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        Text('Target Track', style: AppTypography.labelLarge),
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
          text: 'Start AI Behavioral Session (5 Questions)',
          icon: Icons.play_arrow_rounded,
          variant: AppButtonVariant.primary,
          isFullWidth: true,
          onPressed: _startInterviewSession,
        ),
      ],
    );
  }

  Widget _buildQuestionSessionView() {
    if (_questions.isEmpty || _currentQuestionIndex >= _questions.length) {
      return const SizedBox.shrink();
    }

    final question = _questions[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Progress Header
        Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.15),
                borderRadius: AppRadius.borderSm,
              ),
              child: Text(
                'QUESTION ${_currentQuestionIndex + 1} OF ${_questions.length}',
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
        const SizedBox(height: 8),

        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppColors.surfaceBorder,
          color: AppColors.primary,
          minHeight: 6,
          borderRadius: AppRadius.borderSm,
        ),

        const SizedBox(height: AppSpacing.md),

        // Question Card
        AppCard(
          color: AppColors.surface,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.accentPurple.withValues(alpha: 0.15),
                      borderRadius: AppRadius.borderSm,
                    ),
                    child: Text(
                      question.competency,
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.accentPurple,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.help_outline_rounded, color: AppColors.primary, size: 24),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      question.question,
                      style: AppTypography.titleMedium.copyWith(height: 1.4, fontSize: 16),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: AppRadius.borderSm,
                ),
                child: Row(
                  children: [
                    const Icon(Icons.bookmark_outline, size: 14, color: AppColors.textMuted),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        question.resumeContext,
                        style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.md),

        // Input Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('Your STAR Response', style: AppTypography.labelLarge),
            TextButton.icon(
              icon: const Icon(Icons.lightbulb_outline, size: 16),
              label: const Text('Insert Sample Answer'),
              onPressed: () {
                _answerController.text = question.sampleAnswer;
              },
            ),
          ],
        ),
        const SizedBox(height: 4),

        AppTextField(
          label: 'Candidate Response',
          controller: _answerController,
          hint: 'Structure your answer: Situation context -> Task goal -> Action steps taken -> Quantified Result...',
          maxLines: 5,
        ),

        const SizedBox(height: AppSpacing.md),

        AppButton(
          text: _isEvaluating ? 'Evaluating STAR Scores with Gemini...' : 'Evaluate Answer with STAR Framework',
          icon: Icons.auto_awesome_rounded,
          isLoading: _isEvaluating,
          isFullWidth: true,
          variant: AppButtonVariant.ai,
          onPressed: _evaluateCurrentAnswer,
        ),

        // Display STAR Evaluation Result
        if (_currentEvaluation != null) ...[
          const SizedBox(height: AppSpacing.lg),
          _buildQuestionEvaluationCard(_currentEvaluation!),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            text: _currentQuestionIndex < _questions.length - 1
                ? 'Next Question (${_currentQuestionIndex + 2}/5)'
                : 'View Final Interview Readiness Scorecard',
            icon: Icons.arrow_forward_rounded,
            variant: AppButtonVariant.primary,
            isFullWidth: true,
            onPressed: _nextQuestion,
          ),
        ],
      ],
    );
  }

  Widget _buildQuestionEvaluationCard(QuestionEvaluation eval) {
    final star = eval.starScore;

    return AppCard(
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
                    Text('STAR Score Evaluation', style: AppTypography.labelSmall),
                    Text(
                      '${star.overallScore} / 100',
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

          Text('STAR Framework Breakdown:', style: AppTypography.labelLarge),
          const SizedBox(height: 8),

          // 2x2 STAR Grid
          Row(
            children: [
              Expanded(child: _buildStarChip('Situation', star.situationScore, star.situationFeedback)),
              const SizedBox(width: 8),
              Expanded(child: _buildStarChip('Task', star.taskScore, star.taskFeedback)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildStarChip('Action', star.actionScore, star.actionFeedback)),
              const SizedBox(width: 8),
              Expanded(child: _buildStarChip('Result', star.resultScore, star.resultFeedback)),
            ],
          ),

          const SizedBox(height: 14),

          Text('Strengths Observed:', style: AppTypography.labelLarge),
          const SizedBox(height: 4),
          ...eval.strengths.map(
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

          const SizedBox(height: 10),

          Text('Areas to Refine:', style: AppTypography.labelLarge),
          const SizedBox(height: 4),
          ...eval.improvements.map(
            (imp) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.build_circle_outlined, color: Colors.orange, size: 16),
                  const SizedBox(width: 8),
                  Expanded(child: Text(imp, style: AppTypography.bodySmall)),
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
                    eval.actionableTip,
                    style: AppTypography.bodySmall.copyWith(color: AppColors.primary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStarChip(String title, int score, String feedback) {
    final color = score >= 80 ? AppColors.accentGreen : (score >= 65 ? Colors.orange : Colors.red);
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderSm,
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(title, style: AppTypography.labelSmall.copyWith(fontWeight: FontWeight.bold)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: AppRadius.borderSm,
                ),
                child: Text(
                  '$score%',
                  style: AppTypography.labelSmall.copyWith(color: color, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            feedback,
            style: AppTypography.bodySmall.copyWith(fontSize: 11, color: AppColors.textMuted),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildScorecardView() {
    final res = _finalResult!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Readiness Hero Card
        AppCard(
          color: AppColors.surfaceLight,
          border: Border.all(color: AppColors.primary, width: 2),
          child: Column(
            children: [
              const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 48),
              const SizedBox(height: 8),
              Text(
                'Interview Readiness Score',
                style: AppTypography.labelLarge,
              ),
              const SizedBox(height: 4),
              Text(
                '${res.overallReadinessScore} / 100',
                style: AppTypography.displayLarge.copyWith(
                  color: AppColors.primary,
                  fontWeight: FontWeight.bold,
                  fontSize: 42,
                ),
              ),
              const SizedBox(height: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: AppRadius.borderMd,
                ),
                child: Text(
                  res.readinessTier,
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: AppSpacing.lg),

        Text('Average STAR Framework Performance', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.sm),

        // STAR Averages Row
        Row(
          children: [
            Expanded(child: _buildMetricTile('Situation', '${res.averageSituation.round()}%')),
            const SizedBox(width: 8),
            Expanded(child: _buildMetricTile('Task', '${res.averageTask.round()}%')),
            const SizedBox(width: 8),
            Expanded(child: _buildMetricTile('Action', '${res.averageAction.round()}%')),
            const SizedBox(width: 8),
            Expanded(child: _buildMetricTile('Result', '${res.averageResult.round()}%')),
          ],
        ),

        const SizedBox(height: AppSpacing.lg),

        // Top Strengths
        if (res.topStrengths.isNotEmpty) ...[
          AppCard(
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 20),
                    const SizedBox(width: 8),
                    Text('Top Interview Strengths', style: AppTypography.titleMedium),
                  ],
                ),
                const SizedBox(height: 8),
                ...res.topStrengths.map(
                  (s) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.check_circle_outline, color: AppColors.accentGreen, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(s, style: AppTypography.bodyMedium)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Priority Improvements
        if (res.priorityImprovements.isNotEmpty) ...[
          AppCard(
            color: AppColors.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.center_focus_strong_rounded, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text('Priority Focus Areas for Real Interview', style: AppTypography.titleMedium),
                  ],
                ),
                const SizedBox(height: 8),
                ...res.priorityImprovements.map(
                  (imp) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.trending_up_rounded, color: AppColors.primary, size: 16),
                        const SizedBox(width: 8),
                        Expanded(child: Text(imp, style: AppTypography.bodyMedium)),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
        ],

        // One-tap Retry Button
        AppButton(
          text: 'Practice Again (Start New Mock Session)',
          icon: Icons.refresh_rounded,
          variant: AppButtonVariant.primary,
          isFullWidth: true,
          onPressed: _restartSession,
        ),
      ],
    );
  }

  Widget _buildMetricTile(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.borderSm,
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        children: [
          Text(label, style: AppTypography.labelSmall),
          const SizedBox(height: 4),
          Text(value, style: AppTypography.titleMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
