import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../data/models/resume_models.dart';
import '../../pdf/presentation/resume_preview_screen.dart';
import '../../templates/presentation/template_selector_screen.dart';
import '../providers/resume_history_provider.dart';
import '../utils/resume_input_scrubber.dart';
import '../widgets/education_editor_dialog.dart';
import '../widgets/experience_editor_dialog.dart';
import '../widgets/project_editor_dialog.dart';
import '../widgets/reorderable_section_card.dart';
import '../widgets/resume_error_boundary.dart';
import '../widgets/resume_validators.dart';
import '../widgets/validated_form_field.dart';
import 'section_editor_tab.dart';
import '../screens/translate_resume_screen.dart';
import '../../ai/presentation/ai_settings_screen.dart';
import '../../ai/services/ai_service.dart';
import '../../ai/services/smart_summary_enhancer.dart';

class ResumeEditorScreen extends ConsumerStatefulWidget {
  const ResumeEditorScreen({super.key});

  @override
  ConsumerState<ResumeEditorScreen> createState() => _ResumeEditorScreenState();
}

class _ResumeEditorScreenState extends ConsumerState<ResumeEditorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _personalFormKey = GlobalKey<FormState>();
  final _fullNameCtrl = TextEditingController();
  final _jobTitleCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _summaryCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();
  final _skillInputCtrl = TextEditingController();

  String? _skillError;
  bool _isAiEnhancing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    _tabController.addListener(() {
      if (mounted) setState(() {});
    });
    final resume = ref.read(currentResumeProvider);
    ref.read(resumeHistoryProvider.notifier).initializeWithResume(resume);
    _loadCurrentResumeData();
  }

  void _nextSection() {
    if (_tabController.index < _tabController.length - 1) {
      _tabController.animateTo(_tabController.index + 1);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => const ResumePreviewScreen(),
        ),
      );
    }
  }

  void _loadCurrentResumeData() {
    final resume = ref.read(currentResumeProvider);
    if (resume != null) {
      _titleCtrl.text = resume.title;
      _fullNameCtrl.text = resume.personalInfo.fullName;
      _jobTitleCtrl.text = resume.personalInfo.jobTitle;
      _emailCtrl.text = resume.personalInfo.email;
      _phoneCtrl.text = resume.personalInfo.phone;
      _locationCtrl.text = resume.personalInfo.location;
      _websiteCtrl.text = resume.personalInfo.website;
      _summaryCtrl.text = resume.summary.summaryText;
    }
  }

  void _updateResumeWithHistory(
    Resume Function(Resume current) updateFn, {
    bool immediate = false,
  }) {
    try {
      final current = ref.read(currentResumeProvider);
      if (current != null) {
        ref.read(currentResumeProvider.notifier).updateResume(updateFn, immediate: immediate);
        final updated = ref.read(currentResumeProvider);
        if (updated != null) {
          ref.read(resumeHistoryProvider.notifier).recordSnapshot(updated);
        }
      }
    } catch (e) {
      debugPrint('[RESUME_ERROR_BOUNDARY] Error updating resume history: ${e.runtimeType}');
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fullNameCtrl.dispose();
    _jobTitleCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _websiteCtrl.dispose();
    _summaryCtrl.dispose();
    _titleCtrl.dispose();
    _skillInputCtrl.dispose();
    super.dispose();
  }

  void _syncControllerIfChanged(TextEditingController controller, String newText) {
    if (controller.text != newText && controller.text.trim() != newText.trim()) {
      final oldSelection = controller.selection;
      final int newOffset;
      if (oldSelection.isValid && oldSelection.end <= newText.length) {
        newOffset = oldSelection.end;
      } else {
        newOffset = newText.length;
      }
      controller.value = TextEditingValue(
        text: newText,
        selection: TextSelection.collapsed(offset: newOffset),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final resume = ref.watch(currentResumeProvider);

    // Sync text controllers when undo/redo or external mutations update the resume
    ref.listen<Resume?>(currentResumeProvider, (previous, next) {
      if (next != null) {
        _syncControllerIfChanged(_titleCtrl, next.title);
        _syncControllerIfChanged(_fullNameCtrl, next.personalInfo.fullName);
        _syncControllerIfChanged(_jobTitleCtrl, next.personalInfo.jobTitle);
        _syncControllerIfChanged(_emailCtrl, next.personalInfo.email);
        _syncControllerIfChanged(_phoneCtrl, next.personalInfo.phone);
        _syncControllerIfChanged(_locationCtrl, next.personalInfo.location);
        _syncControllerIfChanged(_websiteCtrl, next.personalInfo.website);
        _syncControllerIfChanged(_summaryCtrl, next.summary.summaryText);
      }
    });

    if (resume == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Resume')),
        body: const Center(child: Text('No resume selected')),
      );
    }

    return CallbackShortcuts(
      bindings: <ShortcutActivator, VoidCallback>{
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true): () {
          ref.read(resumeHistoryProvider.notifier).undo(ref);
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true): () {
          ref.read(resumeHistoryProvider.notifier).undo(ref);
        },
        const SingleActivator(LogicalKeyboardKey.keyY, control: true): () {
          ref.read(resumeHistoryProvider.notifier).redo(ref);
        },
        const SingleActivator(LogicalKeyboardKey.keyY, meta: true): () {
          ref.read(resumeHistoryProvider.notifier).redo(ref);
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, control: true, shift: true): () {
          ref.read(resumeHistoryProvider.notifier).redo(ref);
        },
        const SingleActivator(LogicalKeyboardKey.keyZ, meta: true, shift: true): () {
          ref.read(resumeHistoryProvider.notifier).redo(ref);
        },
      },
      child: Scaffold(
        appBar: AppBar(
          title: TextField(
            key: ObjectKey(_titleCtrl),
            controller: _titleCtrl,
            style: AppTypography.titleLarge,
            inputFormatters: [ResumeInputScrubber.titleFormatter()],
            decoration: const InputDecoration(
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintText: 'Resume Title',
              isDense: true,
            ),
            onChanged: (val) {
              _updateResumeWithHistory((r) => r.copyWith(title: val));
            },
          ),
          actions: [
            Consumer(
              builder: (context, ref, _) {
                final canUndo = ref.watch(resumeHistoryProvider.select((s) => s.canUndo));
                return IconButton(
                  icon: const Icon(Icons.undo),
                  tooltip: 'Undo (Ctrl+Z)',
                  color: canUndo
                      ? AppColors.textPrimary
                      : AppColors.textMuted.withValues(alpha: 0.35),
                  onPressed: canUndo
                      ? () => ref.read(resumeHistoryProvider.notifier).undo(ref)
                      : null,
                );
              },
            ),
            Consumer(
              builder: (context, ref, _) {
                final canRedo = ref.watch(resumeHistoryProvider.select((s) => s.canRedo));
                return IconButton(
                  icon: const Icon(Icons.redo),
                  tooltip: 'Redo (Ctrl+Y)',
                  color: canRedo
                      ? AppColors.textPrimary
                      : AppColors.textMuted.withValues(alpha: 0.35),
                  onPressed: canRedo
                      ? () => ref.read(resumeHistoryProvider.notifier).redo(ref)
                      : null,
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.g_translate_rounded, color: AppColors.accentTeal),
              tooltip: 'Translate Resume',
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const TranslateResumeScreen(),
                  ),
                );
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            isScrollable: true,
            tabAlignment: TabAlignment.start,
            indicatorColor: AppColors.primary,
            labelColor: AppColors.primary,
            unselectedLabelColor: AppColors.textMuted,
            tabs: const [
              Tab(text: 'Personal'),
              Tab(text: 'Summary'),
              Tab(text: 'Experience'),
              Tab(text: 'Education'),
              Tab(text: 'Skills'),
              Tab(text: 'Projects'),
              Tab(text: 'Sections'),
            ],
          ),
        ),
        body: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _KeepAliveWrapper(
                    key: const PageStorageKey('tab_personal'),
                    child: ResumeErrorBoundary(
                      sectionName: 'Personal Information',
                      child: RepaintBoundary(child: _buildPersonalInfoTab(resume)),
                    ),
                  ),
                  _KeepAliveWrapper(
                    key: const PageStorageKey('tab_summary'),
                    child: ResumeErrorBoundary(
                      sectionName: 'Professional Summary',
                      child: RepaintBoundary(child: _buildSummaryTab(resume)),
                    ),
                  ),
                  _KeepAliveWrapper(
                    key: const PageStorageKey('tab_experience'),
                    child: ResumeErrorBoundary(
                      sectionName: 'Work Experience',
                      child: RepaintBoundary(child: _buildExperienceTab(resume)),
                    ),
                  ),
                  _KeepAliveWrapper(
                    key: const PageStorageKey('tab_education'),
                    child: ResumeErrorBoundary(
                      sectionName: 'Education',
                      child: RepaintBoundary(child: _buildEducationTab(resume)),
                    ),
                  ),
                  _KeepAliveWrapper(
                    key: const PageStorageKey('tab_skills'),
                    child: ResumeErrorBoundary(
                      sectionName: 'Skills Inventory',
                      child: RepaintBoundary(child: _buildSkillsTab(resume)),
                    ),
                  ),
                  _KeepAliveWrapper(
                    key: const PageStorageKey('tab_projects'),
                    child: ResumeErrorBoundary(
                      sectionName: 'Showcase Projects',
                      child: RepaintBoundary(child: _buildProjectsTab(resume)),
                    ),
                  ),
                  const _KeepAliveWrapper(
                    key: PageStorageKey('tab_sections'),
                    child: ResumeErrorBoundary(
                      sectionName: 'Supplementary Sections',
                      child: RepaintBoundary(child: SectionEditorTab()),
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              top: false,
              child: SizedBox(
                height: 64,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                    border: Border(top: BorderSide(color: Theme.of(context).dividerColor)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: AppButton(
                          text: 'Preview',
                          icon: Icons.visibility_outlined,
                          variant: AppButtonVariant.secondary,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const ResumePreviewScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppButton(
                          text: 'Template',
                          icon: Icons.palette_outlined,
                          variant: AppButtonVariant.secondary,
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const TemplateSelectorScreen(),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: AppButton(
                          text: 'Next',
                          icon: Icons.arrow_forward_rounded,
                          variant: AppButtonVariant.primary,
                          onPressed: _nextSection,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 1. Personal Information Tab (Real-Time Validated & Focus Traversed)
  // ---------------------------------------------------------------------------
  Widget _buildPersonalInfoTab(Resume resume) {
    return FocusTraversalGroup(
      policy: ReadingOrderTraversalPolicy(),
      child: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Form(
          key: _personalFormKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ValidatedFormField(
                key: ObjectKey(_fullNameCtrl),
                label: 'Full Name',
                hint: 'e.g. Alex Morgan',
                controller: _fullNameCtrl,
                maxLength: 80,
                isRequired: true,
                inputFormatters: [ResumeInputScrubber.nameFormatter()],
                prefixIcon: const Icon(Icons.person_outline, size: 20),
                validator: (val) => ResumeValidators.validateRequired(
                  val,
                  'Full name',
                  minLength: 2,
                  maxLength: 80,
                ),
                onChanged: (_) => _savePersonalInfo(),
              ),
              const SizedBox(height: AppSpacing.md),
              ValidatedFormField(
                key: ObjectKey(_jobTitleCtrl),
                label: 'Job Title / Target Role',
                hint: 'e.g. Senior Software Engineer',
                controller: _jobTitleCtrl,
                maxLength: 100,
                inputFormatters: [ResumeInputScrubber.titleFormatter()],
                prefixIcon: const Icon(Icons.badge_outlined, size: 20),
                validator: (val) => ResumeValidators.validateOptionalLength(
                  val,
                  'Job title',
                  maxLength: 100,
                ),
                onChanged: (_) => _savePersonalInfo(),
              ),
              const SizedBox(height: AppSpacing.md),
              ValidatedFormField(
                key: ObjectKey(_emailCtrl),
                label: 'Email Address',
                hint: 'e.g. alex.morgan@example.com',
                keyboardType: TextInputType.emailAddress,
                controller: _emailCtrl,
                maxLength: 100,
                isRequired: true,
                inputFormatters: [ResumeInputScrubber.emailFormatter()],
                prefixIcon: const Icon(Icons.email_outlined, size: 20),
                validator: (val) => ResumeValidators.validateEmail(val, isRequired: true),
                onChanged: (_) => _savePersonalInfo(),
              ),
              const SizedBox(height: AppSpacing.md),
              ValidatedFormField(
                key: ObjectKey(_phoneCtrl),
                label: 'Phone Number',
                hint: 'e.g. +1 (555) 234-5678',
                keyboardType: TextInputType.phone,
                controller: _phoneCtrl,
                maxLength: 30,
                inputFormatters: [ResumeInputScrubber.phoneFormatter()],
                prefixIcon: const Icon(Icons.phone_outlined, size: 20),
                validator: (val) => ResumeValidators.validatePhone(val),
                onChanged: (_) => _savePersonalInfo(),
              ),
              const SizedBox(height: AppSpacing.md),
              ValidatedFormField(
                key: ObjectKey(_locationCtrl),
                label: 'Location (City, Country)',
                hint: 'e.g. San Francisco, CA',
                controller: _locationCtrl,
                maxLength: 100,
                inputFormatters: [ResumeInputScrubber.titleFormatter()],
                prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
                validator: (val) => ResumeValidators.validateOptionalLength(
                  val,
                  'Location',
                  maxLength: 100,
                ),
                onChanged: (_) => _savePersonalInfo(),
              ),
              const SizedBox(height: AppSpacing.md),
              ValidatedFormField(
                key: ObjectKey(_websiteCtrl),
                label: 'Website / Portfolio Link',
                hint: 'e.g. https://alexmorgan.dev',
                keyboardType: TextInputType.url,
                textInputAction: TextInputAction.done,
                controller: _websiteCtrl,
                maxLength: 200,
                inputFormatters: [ResumeInputScrubber.urlFormatter()],
                prefixIcon: const Icon(Icons.link_outlined, size: 20),
                validator: (val) => ResumeValidators.validateUrl(val),
                onChanged: (_) => _savePersonalInfo(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _savePersonalInfo() {
    _updateResumeWithHistory((r) => r.copyWith(
          personalInfo: PersonalInformation(
            fullName: _fullNameCtrl.text,
            jobTitle: _jobTitleCtrl.text,
            email: _emailCtrl.text,
            phone: _phoneCtrl.text,
            location: _locationCtrl.text,
            website: _websiteCtrl.text,
          ),
        ));
  }

  // ---------------------------------------------------------------------------
  // 2. Professional Summary Tab (Real-Time Validated)
  // ---------------------------------------------------------------------------
  Widget _buildSummaryTab(Resume resume) {
    return FocusTraversalGroup(
      policy: ReadingOrderTraversalPolicy(),
      child: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Professional Summary',
                  style: AppTypography.titleLarge,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    IconButton(
                      tooltip: 'AI Model Settings',
                      icon: const Icon(Icons.tune, size: 18, color: AppColors.textMuted),
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const AISettingsScreen()),
                        );
                      },
                    ),
                    TextButton.icon(
                      onPressed: _isAiEnhancing ? null : _enhanceSummary,
                      icon: _isAiEnhancing
                          ? const SizedBox(
                              width: 14,
                              height: 14,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: AppColors.accentPurple,
                              ),
                            )
                          : const Icon(Icons.auto_awesome, size: 14, color: AppColors.accentPurple),
                      label: Text(
                        'AI Enhance',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.accentPurple,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            ValidatedFormField(
              key: ObjectKey(_summaryCtrl),
              label: '',
              hint: 'Write a brief, impactful overview of your career accomplishments and strengths...',
              maxLines: 7,
              maxLength: 2000,
              controller: _summaryCtrl,
              inputFormatters: [ResumeInputScrubber.textBlockFormatter()],
              validator: (val) => ResumeValidators.validateOptionalLength(
                val,
                'Summary',
                maxLength: 2000,
              ),
              onChanged: (val) {
                _updateResumeWithHistory((r) => r.copyWith(
                      summary: ProfessionalSummary(summaryText: val),
                    ));
              },
            ),
            if (_isAiEnhancing) ...[
              const SizedBox(height: AppSpacing.md),
              const LinearProgressIndicator(color: AppColors.accentPurple),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _enhanceSummary() async {
    final rawText = _summaryCtrl.text.trim();
    if (rawText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter some summary text first to enhance.'),
          backgroundColor: AppColors.accentRed,
        ),
      );
      return;
    }

    setState(() => _isAiEnhancing = true);
    try {
      final aiService = ref.read(aiServiceProvider);
      // Attempt live AI improvement with a strict 5-second timeout
      AIResponse? res;
      try {
        res = await aiService.improveText(rawText, 'summary').timeout(const Duration(seconds: 5));
      } catch (_) {
        res = null;
      }

      String enhancedText = '';
      String statusMessage = '';

      if (res != null && res.isSuccess && res.outputText.trim().isNotEmpty) {
        enhancedText = res.outputText.trim();
        statusMessage = res.suggestions.isNotEmpty
            ? res.suggestions.first
            : 'Enhanced with AI executive formatting';
      } else {
        // Fallback to intelligent local ATS enhancement engine
        final fallback = SmartSummaryEnhancer.enhance(
          rawText,
          targetRole: _jobTitleCtrl.text.trim().isNotEmpty ? _jobTitleCtrl.text.trim() : null,
        );
        enhancedText = fallback.text;
        statusMessage = fallback.suggestions.isNotEmpty
            ? fallback.suggestions.first
            : 'Enhanced with local ATS executive phrasing';
      }

      if (mounted && enhancedText.isNotEmpty) {
        _summaryCtrl.text = enhancedText;
        _updateResumeWithHistory((r) => r.copyWith(
              summary: ProfessionalSummary(summaryText: enhancedText),
            ));

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_outline, color: Colors.white, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    statusMessage,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.accentPurple,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (_) {
      if (mounted) {
        final fallback = SmartSummaryEnhancer.enhance(rawText);
        _summaryCtrl.text = fallback.text;
        _updateResumeWithHistory((r) => r.copyWith(
              summary: ProfessionalSummary(summaryText: fallback.text),
            ));
      }
    } finally {
      if (mounted) {
        setState(() => _isAiEnhancing = false);
      }
    }
  }

  // ---------------------------------------------------------------------------
  // 3. Work Experience Tab (Reorderable with ReorderableListView)
  // ---------------------------------------------------------------------------
  Widget _buildExperienceTab(Resume resume) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('Work Experience', style: AppTypography.titleLarge),
                  if (resume.experiences.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${resume.experiences.length}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              AppButton(
                text: 'Add Experience',
                icon: Icons.add,
                isFullWidth: false,
                onPressed: () => _openExperienceDialog(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (resume.experiences.isEmpty)
            AppCard(
              color: AppColors.surfaceLight.withValues(alpha: 0.5),
              child: Row(
                children: [
                  const Icon(
                    Icons.work_history_outlined,
                    color: AppColors.textMuted,
                    size: 32,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('No experience added yet', style: AppTypography.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          'Add your work history, internships, or freelancing roles.',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppButton(
                    text: 'Add',
                    icon: Icons.add,
                    isFullWidth: false,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => _openExperienceDialog(context),
                  ),
                ],
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: resume.experiences.length,
              onReorder: (oldIndex, newIndex) {
                _updateResumeWithHistory(
                  (r) => r.copyWith(
                    experiences: ReorderableSectionCard.reorderList(
                      list: r.experiences,
                      oldIndex: oldIndex,
                      newIndex: newIndex,
                    ),
                  ),
                  immediate: true,
                );
              },
              itemBuilder: (context, index) {
                final exp = resume.experiences[index];
                return ReorderableSectionCard(
                  key: ValueKey('exp_${exp.id}'),
                  index: index,
                  leading: Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.work_outline,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: exp.position,
                  subtitle: '${exp.company} • ${exp.startDate} - ${exp.isCurrent ? "Present" : exp.endDate}${exp.location.isNotEmpty ? " • ${exp.location}" : ""}',
                  description: exp.description,
                  onEdit: () => _openExperienceDialog(context, experience: exp),
                  onDelete: () => _deleteExperienceWithHistory(exp.id),
                );
              },
            ),
        ],
      ),
    );
  }

  void _openExperienceDialog(BuildContext context, {Experience? experience}) {
    ExperienceEditorDialog.show(
      context: context,
      experience: experience,
      onSave: (exp) {
        _updateResumeWithHistory((r) {
          final list = List<Experience>.from(r.experiences);
          final index = list.indexWhere((item) => item.id == exp.id);
          if (index != -1) {
            list[index] = exp;
          } else {
            list.add(exp);
          }
          return r.copyWith(experiences: list);
        });
      },
    );
  }

  void _deleteExperienceWithHistory(String id) {
    _updateResumeWithHistory((r) => r.copyWith(
          experiences: r.experiences.where((e) => e.id != id).toList(),
        ));
  }

  // ---------------------------------------------------------------------------
  // 4. Education Tab (Reorderable with ReorderableListView)
  // ---------------------------------------------------------------------------
  Widget _buildEducationTab(Resume resume) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('Education', style: AppTypography.titleLarge),
                  if (resume.educationList.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${resume.educationList.length}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              AppButton(
                text: 'Add Education',
                icon: Icons.add,
                isFullWidth: false,
                onPressed: () => _openEducationDialog(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (resume.educationList.isEmpty)
            AppCard(
              color: AppColors.surfaceLight.withValues(alpha: 0.5),
              child: Row(
                children: [
                  const Icon(
                    Icons.school_outlined,
                    color: AppColors.textMuted,
                    size: 32,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('No education added yet', style: AppTypography.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          'Add your degrees, diplomas, or academic institutions.',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppButton(
                    text: 'Add',
                    icon: Icons.add,
                    isFullWidth: false,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => _openEducationDialog(context),
                  ),
                ],
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: resume.educationList.length,
              onReorder: (oldIndex, newIndex) {
                _updateResumeWithHistory(
                  (r) => r.copyWith(
                    educationList: ReorderableSectionCard.reorderList(
                      list: r.educationList,
                      oldIndex: oldIndex,
                      newIndex: newIndex,
                    ),
                  ),
                  immediate: true,
                );
              },
              itemBuilder: (context, index) {
                final edu = resume.educationList[index];
                return ReorderableSectionCard(
                  key: ValueKey('edu_${edu.id}'),
                  index: index,
                  leading: Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.school_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                  ),
                  title: '${edu.degree} in ${edu.fieldOfStudy}',
                  subtitle: '${edu.institution} • ${edu.startDate} - ${edu.endDate}${edu.location.isNotEmpty ? " • ${edu.location}" : ""}${edu.gpa.isNotEmpty ? " (GPA: ${edu.gpa})" : ""}',
                  onEdit: () => _openEducationDialog(context, education: edu),
                  onDelete: () => _deleteEducationWithHistory(edu.id),
                );
              },
            ),
        ],
      ),
    );
  }

  void _openEducationDialog(BuildContext context, {Education? education}) {
    EducationEditorDialog.show(
      context: context,
      education: education,
      onSave: (edu) {
        _updateResumeWithHistory((r) {
          final list = List<Education>.from(r.educationList);
          final index = list.indexWhere((item) => item.id == edu.id);
          if (index != -1) {
            list[index] = edu;
          } else {
            list.add(edu);
          }
          return r.copyWith(educationList: list);
        });
      },
    );
  }

  void _deleteEducationWithHistory(String id) {
    _updateResumeWithHistory((r) => r.copyWith(
          educationList: r.educationList.where((e) => e.id != id).toList(),
        ));
  }

  // ---------------------------------------------------------------------------
  // 5. Skills Tab (Reorderable with Real-time Duplicate Validation)
  // ---------------------------------------------------------------------------
  Widget _buildSkillsTab(Resume resume) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Skills', style: AppTypography.titleLarge),
              if (resume.skills.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${resume.skills.length}',
                    style: AppTypography.bodySmall.copyWith(
                      color: AppColors.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 11,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ValidatedFormField(
                      key: ObjectKey(_skillInputCtrl),
                      label: 'Add Skill',
                      hint: 'e.g. Flutter, Dart, TypeScript, Docker',
                      controller: _skillInputCtrl,
                      maxLength: 50,
                      inputFormatters: [ResumeInputScrubber.titleFormatter()],
                      textInputAction: TextInputAction.done,
                      onFieldSubmitted: (_) => _addSkill(resume),
                      validator: (val) {
                        if (_skillError != null) return _skillError;
                        return null;
                      },
                      onChanged: (val) {
                        if (_skillError != null) {
                          setState(() => _skillError = null);
                        }
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: AppButton(
                  text: 'Add',
                  icon: Icons.add,
                  isFullWidth: false,
                  onPressed: () => _addSkill(resume),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          if (resume.skills.isEmpty)
            AppCard(
              color: AppColors.surfaceLight.withValues(alpha: 0.5),
              child: Row(
                children: [
                  const Icon(Icons.star_outline, color: AppColors.textMuted, size: 32),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('No skills added yet', style: AppTypography.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          'Type a skill above and press Add to populate your skills inventory.',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: resume.skills.length,
              onReorder: (oldIndex, newIndex) {
                _updateResumeWithHistory(
                  (r) => r.copyWith(
                    skills: ReorderableSectionCard.reorderList(
                      list: r.skills,
                      oldIndex: oldIndex,
                      newIndex: newIndex,
                    ),
                  ),
                  immediate: true,
                );
              },
              itemBuilder: (context, index) {
                final skill = resume.skills[index];
                return ReorderableSectionCard(
                  key: ValueKey('skill_${skill.id}'),
                  index: index,
                  leading: Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.code,
                      color: AppColors.primary,
                      size: 16,
                    ),
                  ),
                  title: skill.name,
                  onDelete: () => _deleteSkillWithHistory(skill.id),
                );
              },
            ),
        ],
      ),
    );
  }

  void _addSkill(Resume resume) {
    final text = _skillInputCtrl.text.trim();
    if (text.isEmpty) {
      setState(() => _skillError = 'Skill name cannot be empty');
      return;
    }
    if (text.length > 50) {
      setState(() => _skillError = 'Skill name cannot exceed 50 characters');
      return;
    }
    final isDuplicate = resume.skills.any(
      (s) => s.name.trim().toLowerCase() == text.toLowerCase(),
    );
    if (isDuplicate) {
      setState(() => _skillError = '"$text" is already in your skills list');
      return;
    }

    setState(() => _skillError = null);
    _updateResumeWithHistory((r) {
      final list = List<Skill>.from(r.skills);
      list.add(Skill(name: text));
      return r.copyWith(skills: list);
    });
    _skillInputCtrl.clear();
  }

  void _deleteSkillWithHistory(String id) {
    _updateResumeWithHistory((r) => r.copyWith(
          skills: r.skills.where((s) => s.id != id).toList(),
        ));
  }

  // ---------------------------------------------------------------------------
  // 6. Projects Tab (Reorderable with ReorderableListView)
  // ---------------------------------------------------------------------------
  Widget _buildProjectsTab(Resume resume) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text('Projects', style: AppTypography.titleLarge),
                  if (resume.projects.isNotEmpty) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${resume.projects.length}',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              AppButton(
                text: 'Add Project',
                icon: Icons.add,
                isFullWidth: false,
                onPressed: () => _openProjectDialog(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (resume.projects.isEmpty)
            AppCard(
              color: AppColors.surfaceLight.withValues(alpha: 0.5),
              child: Row(
                children: [
                  const Icon(
                    Icons.rocket_launch_outlined,
                    color: AppColors.textMuted,
                    size: 32,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('No projects added yet', style: AppTypography.titleMedium),
                        const SizedBox(height: 2),
                        Text(
                          'Showcase your portfolio, open-source contributions, or key initiatives.',
                          style: AppTypography.bodySmall,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  AppButton(
                    text: 'Add',
                    icon: Icons.add,
                    isFullWidth: false,
                    variant: AppButtonVariant.secondary,
                    onPressed: () => _openProjectDialog(context),
                  ),
                ],
              ),
            )
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: resume.projects.length,
              onReorder: (oldIndex, newIndex) {
                _updateResumeWithHistory(
                  (r) => r.copyWith(
                    projects: ReorderableSectionCard.reorderList(
                      list: r.projects,
                      oldIndex: oldIndex,
                      newIndex: newIndex,
                    ),
                  ),
                  immediate: true,
                );
              },
              itemBuilder: (context, index) {
                final proj = resume.projects[index];
                return ReorderableSectionCard(
                  key: ValueKey('proj_${proj.id}'),
                  index: index,
                  leading: Container(
                    margin: const EdgeInsets.only(top: 2),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.rocket_launch_outlined,
                      color: AppColors.secondary,
                      size: 20,
                    ),
                  ),
                  title: proj.name,
                  subtitle: proj.role.isNotEmpty ? proj.role : null,
                  tags: proj.technologies.isNotEmpty
                      ? proj.technologies.split(',').map((tech) {
                          return Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              tech.trim(),
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.secondary,
                                fontSize: 11,
                              ),
                            ),
                          );
                        }).toList()
                      : null,
                  description: proj.description,
                  extraContent: proj.link.isNotEmpty
                      ? Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Row(
                            children: [
                              const Icon(Icons.link, size: 13, color: AppColors.secondary),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  proj.link,
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.secondary,
                                    fontSize: 12,
                                    decoration: TextDecoration.underline,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        )
                      : null,
                  onEdit: () => _openProjectDialog(context, project: proj),
                  onDelete: () => _deleteProjectWithHistory(proj.id),
                );
              },
            ),
        ],
      ),
    );
  }

  void _openProjectDialog(BuildContext context, {Project? project}) {
    ProjectEditorDialog.show(
      context: context,
      project: project,
      onSave: (proj) {
        _updateResumeWithHistory((r) {
          final list = List<Project>.from(r.projects);
          final index = list.indexWhere((item) => item.id == proj.id);
          if (index != -1) {
            list[index] = proj;
          } else {
            list.add(proj);
          }
          return r.copyWith(projects: list);
        });
      },
    );
  }

  void _deleteProjectWithHistory(String id) {
    _updateResumeWithHistory((r) => r.copyWith(
          projects: r.projects.where((p) => p.id != id).toList(),
        ));
  }
}

class _KeepAliveWrapper extends StatefulWidget {
  final Widget child;
  const _KeepAliveWrapper({super.key, required this.child});

  @override
  State<_KeepAliveWrapper> createState() => _KeepAliveWrapperState();
}

class _KeepAliveWrapperState extends State<_KeepAliveWrapper>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);
    return widget.child;
  }
}
