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
import '../controllers/job_matching_controller.dart';
import '../models/keyword_extraction_result.dart';
import '../services/keyword_extractor_service.dart';
import '../widgets/keyword_heatmap.dart';
import '../presentation/widgets/resume_vs_jd_comparison_widget.dart';

/// RSM-04 Job Description Matcher & Keyword Gap Heatmap Screen.
/// Computes match percentage between candidate skills/bullet points and target job description,
/// displaying matching skills in green and missing keywords in amber with one-tap 'Add to Resume' action.
class JobMatchScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSuccess;

  const JobMatchScreen({
    super.key,
    this.onSuccess,
  });

  @override
  ConsumerState<JobMatchScreen> createState() => _JobMatchScreenState();
}

class _JobMatchScreenState extends ConsumerState<JobMatchScreen> {
  late final TextEditingController _textController;
  late final TextEditingController _urlController;
  int _inputModeIndex = 0; // 0: Text Area, 1: Job URL
  bool _isFetchingUrl = false;

  static const List<Map<String, String>> _sampleJds = [
    {
      'title': 'Senior Flutter Developer',
      'text':
          'We are seeking a Senior Flutter Developer with 4+ years experience. Required skills: Flutter, Dart, Riverpod, REST API, Git, CI/CD, Unit Testing, Clean Architecture, State Management, Firebase, and Kotlin.',
    },
    {
      'title': 'Full-Stack Software Engineer',
      'text':
          'Looking for a Full-Stack Engineer proficient in TypeScript, React, Node.js, Express.js, PostgreSQL, Docker, Kubernetes, AWS, GraphQL, Microservices, and Jest testing.',
    },
    {
      'title': 'AI / ML Engineer',
      'text':
          'Seeking AI/ML Engineer with expertise in Python, TensorFlow, PyTorch, Scikit-learn, Pandas, NumPy, NLP, Large Language Models (LLMs), RAG, LangChain, Vector Databases, and MLOps.',
    },
  ];

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
    _urlController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    _urlController.dispose();
    super.dispose();
  }

  Future<void> _fetchFromUrl() async {
    final url = _urlController.text.trim();
    if (url.isEmpty) {
      AppSnackBar.show(
        context,
        message: 'Please enter a valid job URL',
        variant: AppSnackBarVariant.error,
      );
      return;
    }

    setState(() => _isFetchingUrl = true);
    await Future.delayed(const Duration(milliseconds: 600));

    // Simulated URL job description extraction
    const extractedText = '''
Target Position: Senior Mobile Systems Engineer
Location: Remote / Hybrid
Role Requirements:
We are looking for an experienced Senior Mobile Engineer to build high-performance mobile applications.
Key Requirements & Skills:
- 3+ years of Flutter & Dart application development
- Strong proficiency in Riverpod state management and Clean Architecture
- Experience with REST API, WebSockets, gRPC, and GraphQL integration
- Knowledge of SQLite, PostgreSQL, Firebase, and Supabase database solutions
- Expertise in CI/CD pipelines, GitHub Actions, Docker, and Automated Unit Testing
- Proficiency in Agile, Git, and UI/UX responsive design
- Experience with Python, Node.js, or AI/ML integrations is a plus.
''';

    _textController.text = extractedText;
    if (!mounted) return;

    setState(() {
      _isFetchingUrl = false;
      _inputModeIndex = 0;
    });

    AppSnackBar.show(
      context,
      message: 'Job description extracted from URL successfully!',
      variant: AppSnackBarVariant.success,
    );
  }

  void _submit() async {
    final textToSubmit = _textController.text.trim();
    if (textToSubmit.isEmpty) {
      AppSnackBar.show(
        context,
        message: 'Please paste or enter a job description.',
        variant: AppSnackBarVariant.error,
      );
      return;
    }

    final activeResume = ref.read(currentResumeProvider);

    await ref.read(jobMatchingControllerProvider.notifier).submitJobDescriptionWithResume(
          textToSubmit,
          title: 'Target Job Description',
          url: _urlController.text.isNotEmpty ? _urlController.text.trim() : null,
          resume: activeResume,
        );

    if (mounted) {
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final controllerState = ref.watch(jobMatchingControllerProvider);
    final activeResume = ref.watch(currentResumeProvider);
    final resumesList = ref.watch(resumesListProvider).value ?? [];

    if (activeResume == null && resumesList.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(currentResumeProvider.notifier).setResume(resumesList.first);
      });
    }

    final KeywordExtractionResult? result;
    if (controllerState.extractionResult != null) {
      result = controllerState.extractionResult;
    } else if (controllerState.currentJob != null &&
        controllerState.currentJob!.descriptionText.trim().isNotEmpty) {
      final extractor = ref.watch(keywordExtractorServiceProvider);
      result = extractor.extractAndCompare(
        jobDescriptionText: controllerState.currentJob!.descriptionText,
        resume: activeResume,
      );
    } else {
      result = null;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Description Matcher'),
        actions: [
          if (controllerState.currentJob != null)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Reset Matcher',
              onPressed: () {
                ref.read(jobMatchingControllerProvider.notifier).clearCurrentJob();
                _textController.clear();
                _urlController.clear();
                setState(() {});
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Target Resume Banner
            if (activeResume != null) ...[
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.description_outlined, color: AppColors.primary, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TARGET RESUME FOR MATCHING',
                            style: AppTypography.labelSmall.copyWith(
                              color: AppColors.primary,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            activeResume.title,
                            style: AppTypography.titleMedium.copyWith(fontSize: 14),
                          ),
                        ],
                      ),
                    ),
                    if (resumesList.length > 1)
                      PopupMenuButton<Resume>(
                        icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.primary),
                        tooltip: 'Switch Target Resume',
                        onSelected: (selected) {
                          ref.read(currentResumeProvider.notifier).setResume(selected);
                          if (_textController.text.trim().isNotEmpty) {
                            _submit();
                          }
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

            // Input Mode Toggle & Card
            AppCard(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Target Job Description',
                      style: AppTypography.titleMedium.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Paste the job description text or enter a job posting URL to analyze keyword gaps.',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: AppSpacing.md),

                    // Segmented Button / Tabs for Text vs URL
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _inputModeIndex = 0),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _inputModeIndex == 0
                                    ? AppColors.primary
                                    : AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.paste_rounded,
                                    size: 16,
                                    color: _inputModeIndex == 0
                                        ? Colors.white
                                        : AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Paste Description',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: _inputModeIndex == 0
                                          ? Colors.white
                                          : AppColors.textMuted,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _inputModeIndex = 1),
                            borderRadius: BorderRadius.circular(8),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _inputModeIndex == 1
                                    ? AppColors.primary
                                    : AppColors.surfaceLight,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    Icons.link_rounded,
                                    size: 16,
                                    color: _inputModeIndex == 1
                                        ? Colors.white
                                        : AppColors.textMuted,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'Job Posting URL',
                                    style: AppTypography.labelSmall.copyWith(
                                      color: _inputModeIndex == 1
                                          ? Colors.white
                                          : AppColors.textMuted,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: AppSpacing.md),

                    if (_inputModeIndex == 1) ...[
                      // URL Input Field
                      AppTextField(
                        label: 'Job Posting URL',
                        hint: 'https://linkedin.com/jobs/view/12345678',
                        controller: _urlController,
                        suffixIcon: const Icon(Icons.language_rounded, size: 20, color: AppColors.primary),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      AppButton(
                        text: 'Extract Job Text from URL',
                        icon: Icons.download_rounded,
                        isLoading: _isFetchingUrl,
                        onPressed: _isFetchingUrl ? null : _fetchFromUrl,
                      ),
                      const SizedBox(height: AppSpacing.md),
                    ],

                    // Text Field for Job Description
                    AppTextField(
                      label: 'Job Description Text',
                      hint: 'Paste requirements, responsibilities, or skills list here...',
                      controller: _textController,
                      maxLines: 7,
                    ),

                    const SizedBox(height: AppSpacing.md),

                    // Quick Sample Selection Chips
                    Text(
                      'Or load a sample job description:',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: _sampleJds.map((sample) {
                        return ActionChip(
                          avatar: const Icon(Icons.work_outline, size: 14, color: AppColors.primary),
                          label: Text(
                            sample['title']!,
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                          side: const BorderSide(color: AppColors.primary, width: 0.8),
                          onPressed: () {
                            _textController.text = sample['text']!;
                            _submit();
                          },
                        );
                      }).toList(),
                    ),

                    const SizedBox(height: AppSpacing.lg),

                    AppButton(
                      text: 'Compute Keyword Match',
                      icon: Icons.analytics_rounded,
                      isLoading: controllerState.isLoading,
                      onPressed: controllerState.isLoading ? null : _submit,
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: AppSpacing.lg),

            // Keyword Gap Heatmap Results Section
            if (result != null) ...[
              KeywordHeatmap(
                result: result,
                onSkillAdded: () {
                  if (_textController.text.trim().isNotEmpty) {
                    _submit();
                  }
                },
              ),
              const SizedBox(height: AppSpacing.lg),

              // Side by side Comparison Section
              if (controllerState.currentJob != null && activeResume != null)
                ResumeVsJdComparisonWidget(
                  resume: activeResume,
                  jobDescription: controllerState.currentJob!,
                  result: result,
                  onSkillAdded: () {
                    if (_textController.text.trim().isNotEmpty) {
                      _submit();
                    }
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }
}
