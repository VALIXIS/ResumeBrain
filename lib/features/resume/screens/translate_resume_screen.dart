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
import '../../../core/widgets/responsive_layout.dart';
import '../../../data/models/resume_models.dart';
import '../../ai/services/resume_translator_service.dart';

class TranslateResumeScreen extends ConsumerStatefulWidget {
  final Resume? initialResume;

  const TranslateResumeScreen({super.key, this.initialResume});

  @override
  ConsumerState<TranslateResumeScreen> createState() => _TranslateResumeScreenState();
}

class _TranslateResumeScreenState extends ConsumerState<TranslateResumeScreen>
    with SingleTickerProviderStateMixin {
  ResumeLanguage _selectedLanguage = ResumeLanguage.spanish;
  bool _isTranslating = false;
  bool _isExporting = false;
  Resume? _translatedResume;
  Duration? _lastTranslationDuration;
  Resume? _selectedResume;

  late TabController _mobileTabController;

  @override
  void initState() {
    super.initState();
    _mobileTabController = TabController(length: 2, vsync: this);
    _selectedResume = widget.initialResume;
  }

  @override
  void dispose() {
    _mobileTabController.dispose();
    super.dispose();
  }

  Resume? _getEffectiveResume(Resume? currentActive) {
    if (_selectedResume != null) return _selectedResume;
    return currentActive;
  }

  Future<void> _performTranslation(Resume resume) async {
    setState(() {
      _isTranslating = true;
      _translatedResume = null;
    });

    try {
      final translator = ref.read(resumeTranslatorServiceProvider);
      final result = await translator.translateResume(
        resume: resume,
        targetLanguage: _selectedLanguage,
      );

      if (mounted) {
        setState(() {
          _isTranslating = false;
          _translatedResume = result.translatedResume;
          _lastTranslationDuration = result.duration;
        });

        if (result.isSuccess && result.translatedResume != null) {
          HapticFeedback.mediumImpact();
          AppSnackBar.showSuccess(
            context,
            'Translated to ${_selectedLanguage.displayName} (${result.duration?.inMilliseconds ?? 0}ms)!',
          );
        } else {
          AppSnackBar.showError(
            context,
            result.errorMessage ?? 'Translation failed.',
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isTranslating = false);
        AppSnackBar.showError(context, 'Error during translation: $e');
      }
    }
  }

  Future<void> _exportPdf(Resume translatedResume) async {
    setState(() => _isExporting = true);
    try {
      final translator = ref.read(resumeTranslatorServiceProvider);
      await translator.exportTranslatedPdf(translatedResume);
      HapticFeedback.lightImpact();
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'PDF Export failed: $e');
      }
    } finally {
      if (mounted) {
        setState(() => _isExporting = false);
      }
    }
  }

  Future<void> _saveAsNewResume(Resume translatedResume) async {
    try {
      final newResume = Resume(
        title: '${translatedResume.title} (${_selectedLanguage.displayName})',
        templateId: translatedResume.templateId,
        personalInfo: translatedResume.personalInfo,
        summary: translatedResume.summary,
        experiences: translatedResume.experiences,
        educationList: translatedResume.educationList,
        projects: translatedResume.projects,
        skills: translatedResume.skills,
        certifications: translatedResume.certifications,
        languages: translatedResume.languages,
        customSections: translatedResume.customSections,
        socialLinks: translatedResume.socialLinks,
      );
      await ref.read(resumesListProvider.notifier).saveResume(newResume);
      HapticFeedback.lightImpact();
      if (mounted) {
        AppSnackBar.showSuccess(
          context,
          'Saved "${newResume.title}" to your resumes library!',
        );
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Failed to save translated resume: $e');
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
                gradient: AppColors.primaryGradient,
                borderRadius: AppRadius.borderSm,
              ),
              child: const Icon(Icons.g_translate_rounded, size: 18, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Text(
                'Multi-Language Translation',
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        actions: [
          if (_translatedResume != null)
            IconButton(
              icon: const Icon(Icons.bookmark_add_outlined, color: AppColors.accentTeal),
              tooltip: 'Save as New Resume',
              onPressed: () => _saveAsNewResume(_translatedResume!),
            ),
        ],
      ),
      body: targetResume == null
          ? _buildNoResumeView()
          : LayoutBuilder(
              builder: (context, constraints) {
                final isWide = constraints.maxWidth >= ResponsiveLayout.kTabletBreakpoint;

                return Column(
                  children: [
                    // Header & Language Selector Controls
                    _buildLanguagePickerSection(targetResume, resumesList),
                    const Divider(height: 1),

                    // Main Content: Side-by-Side or Mobile Tabs
                    Expanded(
                      child: isWide
                          ? _buildWideSideBySideView(targetResume, _translatedResume)
                          : _buildMobileTabView(targetResume, _translatedResume),
                    ),

                    // Bottom Floating Action Bar
                    if (_translatedResume != null)
                      _buildBottomActionBar(_translatedResume!),
                  ],
                );
              },
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
              child: const Icon(Icons.description_outlined, size: 48, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('No Resume Selected', style: AppTypography.titleLarge),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Please select or create a resume first to translate it into international formats.',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              text: 'Back to Dashboard',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLanguagePickerSection(Resume resume, List<Resume> allResumes) {
    return Container(
      color: AppColors.surface,
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Active Profile row
          Row(
            children: [
              Expanded(
                child: Row(
                  children: [
                    const Icon(Icons.badge_outlined, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        resume.personalInfo.fullName.isNotEmpty
                            ? '${resume.personalInfo.fullName} • ${resume.title}'
                            : resume.title,
                        style: AppTypography.labelLarge.copyWith(fontSize: 13),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 1,
                      ),
                    ),
                  ],
                ),
              ),
              if (allResumes.length > 1)
                PopupMenuButton<Resume>(
                  icon: const Icon(Icons.swap_horiz_rounded, size: 20, color: AppColors.textSecondary),
                  tooltip: 'Switch Resume',
                  onSelected: (selected) {
                    setState(() {
                      _selectedResume = selected;
                      _translatedResume = null;
                    });
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
          const SizedBox(height: AppSpacing.sm),

          // Target Language Selector Chips
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: ResumeLanguage.values.map((lang) {
                final isSelected = _selectedLanguage == lang;
                return Padding(
                  padding: const EdgeInsets.only(right: 8.0),
                  child: InkWell(
                    onTap: _isTranslating
                        ? null
                        : () {
                            setState(() {
                              _selectedLanguage = lang;
                            });
                          },
                    borderRadius: AppRadius.borderMd,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.primary.withValues(alpha: 0.15)
                            : AppColors.surfaceLight,
                        border: Border.all(
                          color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
                          width: isSelected ? 1.5 : 1,
                        ),
                        borderRadius: AppRadius.borderMd,
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(lang.flagEmoji, style: const TextStyle(fontSize: 16)),
                          const SizedBox(width: 6),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                lang.displayName,
                                style: AppTypography.labelLarge.copyWith(
                                   fontSize: 12,
                                   color: isSelected ? AppColors.primary : AppColors.textPrimary,
                                   fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                                ),
                              ),
                              Text(
                                lang.nativeName,
                                style: AppTypography.labelSmall.copyWith(
                                  fontSize: 9,
                                  color: isSelected ? AppColors.primary : AppColors.textMuted,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),

          // Translate Button
          AppButton(
            text: _isTranslating
                ? 'Translating to ${_selectedLanguage.displayName}...'
                : 'Translate to ${_selectedLanguage.displayName} (${_selectedLanguage.flagEmoji})',
            icon: Icons.auto_awesome_rounded,
            isLoading: _isTranslating,
            variant: AppButtonVariant.ai,
            onPressed: _isTranslating ? null : () => _performTranslation(resume),
          ),
        ],
      ),
    );
  }

  // ==========================================
  // WIDE / DESKTOP SIDE-BY-SIDE VIEW
  // ==========================================
  Widget _buildWideSideBySideView(Resume original, Resume? translated) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Original Resume Panel (Left)
        Expanded(
          child: Container(
            color: AppColors.background,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPaneHeader('Original (English)', Icons.description_outlined, Colors.blueGrey),
                Expanded(
                  child: SingleChildScrollView(
                    padding: AppSpacing.screenPadding,
                    child: _buildResumePreviewCard(original, isOriginal: true),
                  ),
                ),
              ],
            ),
          ),
        ),
        const VerticalDivider(width: 1),

        // Translated Resume Panel (Right)
        Expanded(
          child: Container(
            color: AppColors.background,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildPaneHeader(
                  'Translated (${_selectedLanguage.displayName} ${_selectedLanguage.flagEmoji})',
                  Icons.g_translate,
                  AppColors.primary,
                  duration: _lastTranslationDuration,
                ),
                Expanded(
                  child: translated == null
                      ? _buildEmptyTranslationPlaceholder()
                      : SingleChildScrollView(
                          padding: AppSpacing.screenPadding,
                          child: _buildResumePreviewCard(translated, isOriginal: false),
                        ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ==========================================
  // MOBILE TABBED VIEW
  // ==========================================
  Widget _buildMobileTabView(Resume original, Resume? translated) {
    return Column(
      children: [
        TabBar(
          controller: _mobileTabController,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          labelStyle: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
          tabs: [
            const Tab(icon: Icon(Icons.description_outlined, size: 18), text: 'Original (EN)'),
            Tab(
              icon: const Icon(Icons.g_translate_rounded, size: 18),
              text: 'Translated (${_selectedLanguage.code.toUpperCase()})',
            ),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _mobileTabController,
            children: [
              SingleChildScrollView(
                padding: AppSpacing.screenPadding,
                child: _buildResumePreviewCard(original, isOriginal: true),
              ),
              translated == null
                  ? _buildEmptyTranslationPlaceholder()
                  : SingleChildScrollView(
                      padding: AppSpacing.screenPadding,
                      child: _buildResumePreviewCard(translated, isOriginal: false),
                    ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaneHeader(String title, IconData icon, Color color, {Duration? duration}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Icon(icon, size: 16, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: AppTypography.titleMedium.copyWith(fontSize: 14),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ),
          ),
          if (duration != null) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.accentGreen.withValues(alpha: 0.15),
                borderRadius: AppRadius.borderSm,
              ),
              child: Text(
                '${duration.inMilliseconds} ms',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.accentGreen,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyTranslationPlaceholder() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.translate_rounded, size: 36, color: AppColors.primary),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Ready to Translate', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Tap "Translate to ${_selectedLanguage.displayName}" above to convert entire resume with formatting and token preservation.',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  String _getSectionTitle(String key, bool isOriginal, {int? count}) {
    if (isOriginal) {
      return count != null ? '$key ($count)' : key;
    }
    final localized = switch (key) {
      'Professional Summary' => switch (_selectedLanguage) {
        ResumeLanguage.spanish => 'Resumen Profesional',
        ResumeLanguage.german => 'Berufliches Profil',
        ResumeLanguage.french => 'Résumé Professionnel',
        ResumeLanguage.japanese => '職務要約 (サマリー)',
      },
      'Work Experience' => switch (_selectedLanguage) {
        ResumeLanguage.spanish => 'Experiencia Laboral',
        ResumeLanguage.german => 'Berufserfahrung',
        ResumeLanguage.french => 'Expérience Professionnelle',
        ResumeLanguage.japanese => '職務経歴',
      },
      'Education' => switch (_selectedLanguage) {
        ResumeLanguage.spanish => 'Educación y Formación',
        ResumeLanguage.german => 'Ausbildung & Studium',
        ResumeLanguage.french => 'Formation & Éducation',
        ResumeLanguage.japanese => '学歴',
      },
      'Skills & Competencies' => switch (_selectedLanguage) {
        ResumeLanguage.spanish => 'Habilidades y Competencias',
        ResumeLanguage.german => 'Kenntnisse & Kompetenzen',
        ResumeLanguage.french => 'Compétences & Savoir-faire',
        ResumeLanguage.japanese => 'スキル・専門分野',
      },
      _ => key,
    };
    return count != null ? '$localized ($count)' : localized;
  }

  Widget _buildResumePreviewCard(Resume r, {required bool isOriginal}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Personal Information Banner
        AppCard(
          color: isOriginal ? AppColors.surface : AppColors.surfaceLight,
          border: Border.all(
            color: isOriginal ? AppColors.surfaceBorder : AppColors.primary.withValues(alpha: 0.3),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                r.personalInfo.fullName.isNotEmpty ? r.personalInfo.fullName : 'Full Name',
                style: AppTypography.titleLarge.copyWith(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 2),
              Text(
                r.personalInfo.jobTitle.isNotEmpty ? r.personalInfo.jobTitle : 'Job Title',
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.primary,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 6,
                children: [
                  if (r.personalInfo.email.isNotEmpty)
                    _buildContactChip(Icons.email_outlined, r.personalInfo.email),
                  if (r.personalInfo.phone.isNotEmpty)
                    _buildContactChip(Icons.phone_outlined, r.personalInfo.phone),
                  if (r.personalInfo.location.isNotEmpty)
                    _buildContactChip(Icons.location_on_outlined, r.personalInfo.location),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),

        // Summary Section
        if (r.summary.summaryText.isNotEmpty) ...[
          _buildSectionHeader(_getSectionTitle('Professional Summary', isOriginal), Icons.summarize_outlined),
          const SizedBox(height: AppSpacing.xs),
          AppCard(
            child: Text(r.summary.summaryText, style: AppTypography.bodyMedium.copyWith(height: 1.5)),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Work Experience Section
        if (r.experiences.isNotEmpty) ...[
          _buildSectionHeader(
            _getSectionTitle('Work Experience', isOriginal, count: r.experiences.length),
            Icons.work_outline_rounded,
          ),
          const SizedBox(height: AppSpacing.xs),
          ...r.experiences.map((exp) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              exp.position,
                              style: AppTypography.titleMedium.copyWith(fontSize: 14, fontWeight: FontWeight.bold),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${exp.startDate} - ${exp.isCurrent ? (isOriginal ? "Present" : switch (_selectedLanguage) {
                                  ResumeLanguage.spanish => "Presente",
                                  ResumeLanguage.german => "Heute",
                                  ResumeLanguage.french => "Présent",
                                  ResumeLanguage.japanese => "現在",
                                }) : exp.endDate}',
                            style: AppTypography.labelSmall,
                          ),
                        ],
                      ),
                      Text(exp.company, style: AppTypography.labelLarge.copyWith(fontSize: 12, color: AppColors.primary)),
                      if (exp.description.isNotEmpty) ...[
                        const SizedBox(height: 6),
                        Text(exp.description, style: AppTypography.bodySmall.copyWith(height: 1.4)),
                      ],
                    ],
                  ),
                ),
              )),
          const SizedBox(height: AppSpacing.md),
        ],

        // Education Section
        if (r.educationList.isNotEmpty) ...[
          _buildSectionHeader(
            _getSectionTitle('Education', isOriginal, count: r.educationList.length),
            Icons.school_outlined,
          ),
          const SizedBox(height: AppSpacing.xs),
          ...r.educationList.map((edu) => Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                child: AppCard(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${edu.degree} in ${edu.fieldOfStudy}',
                        style: AppTypography.titleMedium.copyWith(fontSize: 13, fontWeight: FontWeight.bold),
                      ),
                      Text(edu.institution, style: AppTypography.bodySmall),
                    ],
                  ),
                ),
              )),
          const SizedBox(height: AppSpacing.md),
        ],

        // Skills Section
        if (r.skills.isNotEmpty) ...[
          _buildSectionHeader(_getSectionTitle('Skills & Competencies', isOriginal), Icons.bolt_rounded),
          const SizedBox(height: AppSpacing.xs),
          AppCard(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: r.skills.map((s) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.12),
                    borderRadius: AppRadius.borderSm,
                  ),
                  child: Text(s.name, style: AppTypography.labelSmall.copyWith(color: AppColors.primary)),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
        ],

        // Custom Sections
        if (r.customSections.isNotEmpty) ...[
          ...r.customSections.map((sec) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionHeader(sec.title, Icons.stars_outlined),
                  const SizedBox(height: AppSpacing.xs),
                  AppCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: sec.items.map((item) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('• ', style: TextStyle(color: AppColors.primary)),
                              Expanded(child: Text(item, style: AppTypography.bodySmall)),
                            ],
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  const SizedBox(height: AppSpacing.md),
                ],
              )),
        ],
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.primary),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            title,
            style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.bold, fontSize: 13),
            overflow: TextOverflow.ellipsis,
            maxLines: 1,
          ),
        ),
      ],
    );
  }

  Widget _buildContactChip(IconData icon, String text) {
    return Container(
      constraints: const BoxConstraints(maxWidth: 300),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              text,
              style: AppTypography.bodySmall.copyWith(fontSize: 11),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar(Resume translatedResume) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isNarrow = constraints.maxWidth < 360;
            if (isNarrow) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      text: 'Save As Resume',
                      icon: Icons.bookmark_add_outlined,
                      variant: AppButtonVariant.outline,
                      onPressed: () => _saveAsNewResume(translatedResume),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: AppButton(
                      text: 'Export Translated PDF',
                      icon: Icons.picture_as_pdf_outlined,
                      isLoading: _isExporting,
                      variant: AppButtonVariant.primary,
                      onPressed: _isExporting ? null : () => _exportPdf(translatedResume),
                    ),
                  ),
                ],
              );
            }
            return Row(
              children: [
                Expanded(
                  child: AppButton(
                    text: 'Save As Resume',
                    icon: Icons.bookmark_add_outlined,
                    variant: AppButtonVariant.outline,
                    onPressed: () => _saveAsNewResume(translatedResume),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    text: 'Export Translated PDF',
                    icon: Icons.picture_as_pdf_outlined,
                    isLoading: _isExporting,
                    variant: AppButtonVariant.primary,
                    onPressed: _isExporting ? null : () => _exportPdf(translatedResume),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}
