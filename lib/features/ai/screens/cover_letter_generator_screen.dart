import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../../../data/models/resume_models.dart';
import '../services/ai_cover_letter_service.dart';

class CoverLetterGeneratorScreen extends ConsumerStatefulWidget {
  final Resume? initialResume;

  const CoverLetterGeneratorScreen({super.key, this.initialResume});

  @override
  ConsumerState<CoverLetterGeneratorScreen> createState() =>
      _CoverLetterGeneratorScreenState();
}

class _CoverLetterGeneratorScreenState
    extends ConsumerState<CoverLetterGeneratorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Cover Letter Tab State
  final TextEditingController _jdController = TextEditingController();
  final TextEditingController _companyController = TextEditingController();
  final TextEditingController _jobTitleController = TextEditingController();
  CoverLetterTone _selectedTone = CoverLetterTone.professional;

  bool _isGeneratingCoverLetter = false;
  String _generatedCoverLetter = '';
  StreamSubscription<String>? _coverLetterSub;

  // LinkedIn Outreach Tab State
  final TextEditingController _linkedInJdController = TextEditingController();
  final TextEditingController _recruiterNameController = TextEditingController();
  final TextEditingController _linkedInCompanyController = TextEditingController();
  final TextEditingController _linkedInRoleController = TextEditingController();

  bool _isGeneratingLinkedIn = false;
  String _generatedLinkedInNote = '';
  StreamSubscription<String>? _linkedInSub;

  Resume? _selectedResume;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _selectedResume = widget.initialResume;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _jdController.dispose();
    _companyController.dispose();
    _jobTitleController.dispose();
    _linkedInJdController.dispose();
    _recruiterNameController.dispose();
    _linkedInCompanyController.dispose();
    _linkedInRoleController.dispose();
    _coverLetterSub?.cancel();
    _linkedInSub?.cancel();
    super.dispose();
  }

  Resume? _getEffectiveResume(Resume? currentActive) {
    if (_selectedResume != null) return _selectedResume;
    return currentActive;
  }

  Future<void> _generateCoverLetter(Resume resume) async {
    final jd = _jdController.text.trim();
    if (jd.isEmpty) {
      AppSnackBar.showError(context, 'Please paste or enter the target Job Description.');
      return;
    }

    // Cancel existing stream if active
    await _coverLetterSub?.cancel();

    setState(() {
      _isGeneratingCoverLetter = true;
      _generatedCoverLetter = '';
    });

    final aiService = ref.read(aiCoverLetterServiceProvider);
    final company = _companyController.text.trim();
    final role = _jobTitleController.text.trim();

    try {
      final stream = aiService.generateCoverLetterStream(
        resume: resume,
        jobDescription: jd,
        tone: _selectedTone,
        companyName: company.isNotEmpty ? company : null,
        jobTitle: role.isNotEmpty ? role : null,
      );

      _coverLetterSub = stream.listen(
        (chunk) {
          if (mounted) {
            setState(() {
              _generatedCoverLetter += chunk;
            });
          }
        },
        onDone: () {
          if (mounted) {
            setState(() => _isGeneratingCoverLetter = false);
            HapticFeedback.mediumImpact();
            AppSnackBar.showSuccess(context, 'Cover letter generated successfully!');
          }
        },
        onError: (err) {
          if (mounted) {
            setState(() => _isGeneratingCoverLetter = false);
            AppSnackBar.showError(context, 'Generation error: $err');
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingCoverLetter = false);
        AppSnackBar.showError(context, 'Failed to start AI generation: $e');
      }
    }
  }

  Future<void> _generateLinkedInNote(Resume resume) async {
    final jd = _linkedInJdController.text.trim().isNotEmpty
        ? _linkedInJdController.text.trim()
        : _jdController.text.trim();

    if (jd.isEmpty) {
      AppSnackBar.showError(
          context, 'Please provide the Job Description or key job context.');
      return;
    }

    await _linkedInSub?.cancel();

    setState(() {
      _isGeneratingLinkedIn = true;
      _generatedLinkedInNote = '';
    });

    final aiService = ref.read(aiCoverLetterServiceProvider);
    final recruiter = _recruiterNameController.text.trim();
    final company = _linkedInCompanyController.text.trim().isNotEmpty
        ? _linkedInCompanyController.text.trim()
        : _companyController.text.trim();
    final role = _linkedInRoleController.text.trim().isNotEmpty
        ? _linkedInRoleController.text.trim()
        : _jobTitleController.text.trim();

    try {
      final stream = aiService.generateLinkedInOutreachStream(
        resume: resume,
        jobDescription: jd,
        recruiterName: recruiter.isNotEmpty ? recruiter : null,
        companyName: company.isNotEmpty ? company : null,
        jobTitle: role.isNotEmpty ? role : null,
      );

      _linkedInSub = stream.listen(
        (chunk) {
          if (mounted) {
            setState(() {
              _generatedLinkedInNote += chunk;
            });
          }
        },
        onDone: () {
          if (mounted) {
            setState(() => _isGeneratingLinkedIn = false);
            HapticFeedback.mediumImpact();
            AppSnackBar.showSuccess(context, 'LinkedIn note tailored under 300 chars!');
          }
        },
        onError: (err) {
          if (mounted) {
            setState(() => _isGeneratingLinkedIn = false);
            AppSnackBar.showError(context, 'Generation error: $err');
          }
        },
      );
    } catch (e) {
      if (mounted) {
        setState(() => _isGeneratingLinkedIn = false);
        AppSnackBar.showError(context, 'Failed to generate note: $e');
      }
    }
  }

  Future<void> _copyToClipboard(String text, {String message = 'Copied to clipboard!'}) async {
    if (text.isEmpty) return;
    await Clipboard.setData(ClipboardData(text: text));
    HapticFeedback.lightImpact();
    if (mounted) {
      AppSnackBar.showSuccess(context, message);
    }
  }

  Future<void> _exportPdf(Resume resume) async {
    if (_generatedCoverLetter.trim().isEmpty) {
      AppSnackBar.showError(context, 'Generate a cover letter before exporting PDF.');
      return;
    }

    try {
      final aiService = ref.read(aiCoverLetterServiceProvider);
      await aiService.exportCoverLetterPdf(
        resume: resume,
        coverLetterText: _generatedCoverLetter,
        companyName: _companyController.text.trim(),
        jobTitle: _jobTitleController.text.trim(),
        tone: _selectedTone,
      );
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Error exporting PDF: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final activeResume = _getEffectiveResume(ref.watch(currentResumeProvider));
    final resumesList = ref.watch(resumesListProvider).value ?? [];

    final targetResume = activeResume ?? (resumesList.isNotEmpty ? resumesList.first : null);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.aiGradient,
                borderRadius: AppRadius.borderSm,
              ),
              child: const Icon(Icons.mail_outline_rounded, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Text('AI Cover Letter & Outreach'),
          ],
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold),
          tabs: const [
            Tab(
              icon: Icon(Icons.description_outlined, size: 20),
              text: 'Cover Letter',
            ),
            Tab(
              icon: Icon(Icons.send_rounded, size: 20),
              text: 'LinkedIn Outreach',
            ),
          ],
        ),
      ),
      body: targetResume == null
          ? _buildNoResumeView()
          : TabBarView(
              controller: _tabController,
              children: [
                _buildCoverLetterTab(context, targetResume, resumesList),
                _buildLinkedInTab(context, targetResume, resumesList),
              ],
            ),
    );
  }

  Widget _buildNoResumeView() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline_rounded, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('No Resume Selected', style: AppTypography.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Please create or import a resume in Resume Brain to generate personalized, achievement-backed cover letters.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              text: 'Back to Dashboard',
              variant: AppButtonVariant.primary,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  // ==========================================
  // TAB 1: COVER LETTER GENERATOR
  // ==========================================
  Widget _buildCoverLetterTab(BuildContext context, Resume resume, List<Resume> allResumes) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResumeSelectorCard(resume, allResumes),
          const SizedBox(height: AppSpacing.md),
          _buildJobContextCard(),
          const SizedBox(height: AppSpacing.md),
          _buildToneSelectorCard(),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            text: _isGeneratingCoverLetter ? 'Crafting Cover Letter...' : 'Generate AI Cover Letter',
            icon: Icons.auto_awesome,
            isLoading: _isGeneratingCoverLetter,
            variant: AppButtonVariant.ai,
            onPressed: _isGeneratingCoverLetter ? null : () => _generateCoverLetter(resume),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_generatedCoverLetter.isNotEmpty || _isGeneratingCoverLetter)
            _buildCoverLetterResultSection(resume),
        ],
      ),
    );
  }

  // ==========================================
  // TAB 2: LINKEDIN OUTREACH GENERATOR
  // ==========================================
  Widget _buildLinkedInTab(BuildContext context, Resume resume, List<Resume> allResumes) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppCard(
            color: AppColors.surface,
            border: Border.all(color: const Color(0xFF0077B5).withValues(alpha: 0.3)),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF0077B5).withValues(alpha: 0.15),
                    borderRadius: AppRadius.borderSm,
                  ),
                  child: const Icon(Icons.share_outlined, color: Color(0xFF0077B5), size: 22),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('LinkedIn Recruiter DM (Max 300 Chars)',
                          style: AppTypography.titleMedium.copyWith(fontSize: 15)),
                      const SizedBox(height: 2),
                      Text(
                        'Generates ultra-tailored connection request notes guaranteed to fit LinkedIn limits.',
                        style: AppTypography.bodySmall,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildLinkedInInputsCard(),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            text: _isGeneratingLinkedIn ? 'Generating Note...' : 'Generate Tailored Outreach Note',
            icon: Icons.send_rounded,
            isLoading: _isGeneratingLinkedIn,
            variant: AppButtonVariant.primary,
            onPressed: _isGeneratingLinkedIn ? null : () => _generateLinkedInNote(resume),
          ),
          const SizedBox(height: AppSpacing.xl),
          if (_generatedLinkedInNote.isNotEmpty || _isGeneratingLinkedIn)
            _buildLinkedInResultSection(),
        ],
      ),
    );
  }

  Widget _buildResumeSelectorCard(Resume activeResume, List<Resume> allResumes) {
    return AppCard(
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.12),
              borderRadius: AppRadius.borderSm,
            ),
            child: const Icon(Icons.badge_outlined, color: AppColors.primary, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Active Profile / Resume', style: AppTypography.labelSmall),
                Text(
                  activeResume.personalInfo.fullName.isNotEmpty
                      ? '${activeResume.personalInfo.fullName} (${activeResume.title})'
                      : activeResume.title,
                  style: AppTypography.titleMedium.copyWith(fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (allResumes.length > 1)
            PopupMenuButton<Resume>(
              icon: const Icon(Icons.swap_horiz_rounded, color: AppColors.textSecondary),
              tooltip: 'Switch Resume',
              onSelected: (selected) {
                setState(() => _selectedResume = selected);
              },
              itemBuilder: (context) {
                return allResumes.map((r) {
                  return PopupMenuItem<Resume>(
                    value: r,
                    child: Text(r.title, style: AppTypography.bodyMedium),
                  );
                }).toList();
              },
            ),
        ],
      ),
    );
  }

  Widget _buildJobContextCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.work_outline_rounded, color: AppColors.primary, size: 18),
              const SizedBox(width: 8),
              Text('Target Job & Company', style: AppTypography.titleMedium.copyWith(fontSize: 15)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Target Company',
                  hint: 'e.g. Google, Stripe, Meta',
                  controller: _companyController,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppTextField(
                  label: 'Role / Position',
                  hint: 'e.g. Senior Mobile Engineer',
                  controller: _jobTitleController,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Target Job Description *', style: AppTypography.labelLarge),
              Row(
                children: [
                  InkWell(
                    onTap: () async {
                      final data = await Clipboard.getData(Clipboard.kTextPlain);
                      if (data != null && data.text != null) {
                        _jdController.text = data.text!;
                        setState(() {});
                      }
                    },
                    borderRadius: AppRadius.borderSm,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      child: Row(
                        children: [
                          const Icon(Icons.paste_rounded, size: 14, color: AppColors.primary),
                          const SizedBox(width: 4),
                          Text('Paste',
                              style: AppTypography.labelSmall.copyWith(color: AppColors.primary)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  if (_jdController.text.isNotEmpty)
                    InkWell(
                      onTap: () {
                        _jdController.clear();
                        setState(() {});
                      },
                      borderRadius: AppRadius.borderSm,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        child: Text('Clear',
                            style: AppTypography.labelSmall.copyWith(color: AppColors.accentRed)),
                      ),
                    ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(
            controller: _jdController,
            maxLines: 6,
            onChanged: (_) => setState(() {}),
            style: AppTypography.bodyMedium,
            decoration: InputDecoration(
              hintText: 'Paste the requirements, responsibilities, and qualifications from the job posting...',
              hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textDisabled),
              filled: true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: AppRadius.borderMd,
                borderSide: BorderSide(color: AppColors.surfaceBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.borderMd,
                borderSide: BorderSide(color: AppColors.surfaceBorder),
              ),
              focusedBorder: const OutlineInputBorder(
                borderRadius: AppRadius.borderMd,
                borderSide: BorderSide(color: AppColors.primary, width: 1.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildToneSelectorCard() {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, color: AppColors.accentPurple, size: 18),
              const SizedBox(width: 8),
              Text('Cover Letter Tone', style: AppTypography.titleMedium.copyWith(fontSize: 15)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Select how you want Gemini to position your accomplishments and voice.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: CoverLetterTone.values.map((tone) {
              final isSelected = _selectedTone == tone;
              IconData icon;
              Color activeColor;
              switch (tone) {
                case CoverLetterTone.confident:
                  icon = Icons.bolt_rounded;
                  activeColor = Colors.amber.shade700;
                  break;
                case CoverLetterTone.professional:
                  icon = Icons.verified_user_outlined;
                  activeColor = AppColors.primary;
                  break;
                case CoverLetterTone.creative:
                  icon = Icons.lightbulb_outline_rounded;
                  activeColor = AppColors.accentTeal;
                  break;
              }

              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: InkWell(
                    onTap: () => setState(() => _selectedTone = tone),
                    borderRadius: AppRadius.borderMd,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? activeColor.withValues(alpha: 0.15)
                            : AppColors.surfaceLight,
                        border: Border.all(
                          color: isSelected ? activeColor : AppColors.surfaceBorder,
                          width: isSelected ? 2 : 1,
                        ),
                        borderRadius: AppRadius.borderMd,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, color: isSelected ? activeColor : AppColors.textSecondary, size: 22),
                          const SizedBox(height: 6),
                          Text(
                            tone.displayName,
                            style: AppTypography.labelLarge.copyWith(
                              fontSize: 12,
                              color: isSelected ? activeColor : AppColors.textPrimary,
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: AppSpacing.sm),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: AppRadius.borderSm,
            ),
            child: Text(
              _selectedTone.subtitle,
              style: AppTypography.bodySmall.copyWith(
                fontStyle: FontStyle.italic,
                color: AppColors.textSecondary,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCoverLetterResultSection(Resume resume) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.accentPurple, size: 18),
                const SizedBox(width: 8),
                Text('Personalized Cover Letter', style: AppTypography.titleLarge.copyWith(fontSize: 17)),
              ],
            ),
            if (_isGeneratingCoverLetter)
              Row(
                children: [
                  const SizedBox(
                    width: 14,
                    height: 14,
                    child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primary),
                  ),
                  const SizedBox(width: 6),
                  Text('Streaming...',
                      style: AppTypography.labelSmall.copyWith(color: AppColors.primary)),
                ],
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        // Action Bar (Copy & PDF Export)
        Row(
          children: [
            Expanded(
              child: AppButton(
                text: 'Copy to Clipboard',
                icon: Icons.copy_rounded,
                variant: AppButtonVariant.outline,
                onPressed: () => _copyToClipboard(
                  _generatedCoverLetter,
                  message: 'Cover letter copied to clipboard!',
                ),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppButton(
                text: 'Export PDF',
                icon: Icons.picture_as_pdf_outlined,
                variant: AppButtonVariant.primary,
                onPressed: () => _exportPdf(resume),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          color: AppColors.surface,
          border: Border.all(color: AppColors.surfaceBorder),
          child: SelectableText.rich(
            _buildMarkdownSpan(_generatedCoverLetter),
            style: AppTypography.bodyMedium.copyWith(height: 1.6),
          ),
        ),
      ],
    );
  }

  Widget _buildLinkedInInputsCard() {
    final hasJdContext = _linkedInJdController.text.isNotEmpty || _jdController.text.isNotEmpty;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.person_search_rounded, color: Color(0xFF0077B5), size: 18),
              const SizedBox(width: 8),
              Text('Target Recruiter & Role', style: AppTypography.titleMedium.copyWith(fontSize: 15)),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Recruiter or Hiring Manager Name',
            hint: 'e.g. Sarah Jenkins (or leave blank for "Hiring Leader")',
            controller: _recruiterNameController,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Company',
                  hint: _companyController.text.isNotEmpty ? _companyController.text : 'e.g. Microsoft',
                  controller: _linkedInCompanyController,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: AppTextField(
                  label: 'Role',
                  hint: _jobTitleController.text.isNotEmpty ? _jobTitleController.text : 'e.g. Flutter Engineer',
                  controller: _linkedInRoleController,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Text('Job Keywords or Context (Optional if entered in Cover Letter Tab)',
              style: AppTypography.labelLarge),
          const SizedBox(height: AppSpacing.xs),
          TextFormField(
            controller: _linkedInJdController,
            maxLines: 3,
            onChanged: (_) => setState(() {}),
            style: AppTypography.bodyMedium,
            decoration: InputDecoration(
              hintText: hasJdContext
                  ? 'Using context from Cover Letter tab, or add custom context here...'
                  : 'Enter key skills/requirements for this role...',
              hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textDisabled),
              filled: true,
              fillColor: AppColors.surfaceLight,
              border: OutlineInputBorder(
                borderRadius: AppRadius.borderMd,
                borderSide: BorderSide(color: AppColors.surfaceBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: AppRadius.borderMd,
                borderSide: BorderSide(color: AppColors.surfaceBorder),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLinkedInResultSection() {
    final charCount = _generatedLinkedInNote.length;
    final isWithinLimit = charCount <= 300;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.mark_email_read_outlined, color: Color(0xFF0077B5), size: 18),
                const SizedBox(width: 8),
                Text('Tailored LinkedIn Note', style: AppTypography.titleLarge.copyWith(fontSize: 17)),
              ],
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: isWithinLimit
                    ? AppColors.accentGreen.withValues(alpha: 0.15)
                    : AppColors.accentRed.withValues(alpha: 0.15),
                borderRadius: AppRadius.borderSm,
                border: Border.all(
                  color: isWithinLimit ? AppColors.accentGreen : AppColors.accentRed,
                  width: 1,
                ),
              ),
              child: Text(
                '$charCount / 300 chars',
                style: AppTypography.labelSmall.copyWith(
                  color: isWithinLimit ? AppColors.accentGreen : AppColors.accentRed,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        AppCard(
          color: AppColors.surface,
          border: Border.all(color: isWithinLimit ? const Color(0xFF0077B5).withValues(alpha: 0.5) : AppColors.accentRed),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(
                _generatedLinkedInNote,
                style: AppTypography.bodyLarge.copyWith(height: 1.5),
              ),
              const SizedBox(height: AppSpacing.md),
              const Divider(),
              const SizedBox(height: AppSpacing.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isWithinLimit ? Icons.check_circle_outline_rounded : Icons.warning_amber_rounded,
                        size: 16,
                        color: isWithinLimit ? AppColors.accentGreen : AppColors.accentOrange,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        isWithinLimit
                            ? 'Ready for LinkedIn Connection Request'
                            : 'Exceeds 300 character limit',
                        style: AppTypography.labelSmall.copyWith(
                          color: isWithinLimit ? AppColors.accentGreen : AppColors.accentOrange,
                        ),
                      ),
                    ],
                  ),
                  AppButton(
                    text: 'Copy Note',
                    icon: Icons.copy_rounded,
                    variant: AppButtonVariant.primary,
                    isFullWidth: false,
                    onPressed: () => _copyToClipboard(
                      _generatedLinkedInNote,
                      message: 'LinkedIn outreach note copied!',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Parses markdown headings, boldings, lists, and links into rich TextSpans
  TextSpan _buildMarkdownSpan(String text) {
    final spans = <TextSpan>[];
    final lines = text.split('\n');

    for (int i = 0; i < lines.length; i++) {
      final line = lines[i];

      if (line.startsWith('# ')) {
        spans.add(TextSpan(
          text: '${line.substring(2)}\n',
          style: AppTypography.titleLarge.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
            fontSize: 20,
          ),
        ));
      } else if (line.startsWith('## ')) {
        spans.add(TextSpan(
          text: '${line.substring(3)}\n',
          style: AppTypography.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ));
      } else if (line.startsWith('### ')) {
        spans.add(TextSpan(
          text: '${line.substring(4)}\n',
          style: AppTypography.titleMedium.copyWith(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ));
      } else if (line.trim().startsWith('- ') || line.trim().startsWith('* ')) {
        spans.add(TextSpan(
          text: '  • ${line.trim().substring(2)}\n',
          style: AppTypography.bodyMedium,
        ));
      } else {
        // Parse bold inline **text**
        final parts = line.split('**');
        for (int j = 0; j < parts.length; j++) {
          final isBold = j % 2 == 1;
          spans.add(TextSpan(
            text: parts[j],
            style: isBold
                ? AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.bold)
                : AppTypography.bodyMedium,
          ));
        }
        spans.add(const TextSpan(text: '\n'));
      }
    }

    return TextSpan(children: spans);
  }
}
