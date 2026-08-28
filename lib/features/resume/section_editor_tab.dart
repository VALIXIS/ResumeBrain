import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../app/providers.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/custom_button.dart';
import '../../core/widgets/custom_card.dart';
import '../../core/widgets/custom_text_field.dart';
import '../../data/models/resume_models.dart';
import 'widgets/certification_editor_dialog.dart';
import 'widgets/language_editor_dialog.dart';

/// SectionEditorTab provides the editor UI for supplementary resume sections:
/// - Certifications & Licenses (Full CRUD with validation)
/// - Languages & Proficiency (Full CRUD with validation)
/// - Custom User-Defined Sections
class SectionEditorTab extends ConsumerWidget {
  const SectionEditorTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resume = ref.watch(currentResumeProvider);

    if (resume == null) {
      return const Center(
        child: Text(
          'No resume selected',
          style: TextStyle(color: AppColors.textMuted),
        ),
      );
    }

    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCertificationsSection(context, ref, resume),
          const SizedBox(height: AppSpacing.xxl),
          _buildLanguagesSection(context, ref, resume),
          const SizedBox(height: AppSpacing.xxl),
          _buildCustomSections(context, ref, resume),
          const SizedBox(height: AppSpacing.xxl),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Certifications Section CRUD
  // ---------------------------------------------------------------------------
  Widget _buildCertificationsSection(
    BuildContext context,
    WidgetRef ref,
    Resume resume,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.verified_outlined,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  'Certifications & Licenses',
                  style: AppTypography.titleLarge,
                ),
              ],
            ),
            AppButton(
              text: 'Add Certification',
              icon: Icons.add,
              isFullWidth: false,
              onPressed: () => _openCertificationDialog(context, ref),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (resume.certifications.isEmpty)
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
                      Text(
                        'No certifications added yet',
                        style: AppTypography.titleMedium,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Add your professional certifications, licenses, or credentials to showcase verified expertise.',
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
                  onPressed: () => _openCertificationDialog(context, ref),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: resume.certifications.length,
            separatorBuilder: (c, i) => const SizedBox(height: AppSpacing.sm),
            itemBuilder: (context, index) {
              final cert = resume.certifications[index];
              return AppCard(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      margin: const EdgeInsets.only(top: 2),
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.workspace_premium_outlined,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cert.name, style: AppTypography.titleMedium),
                          const SizedBox(height: 2),
                          Text(
                            cert.issuingOrganization.isNotEmpty
                                ? '${cert.issuingOrganization}${cert.issueDate.isNotEmpty ? " • ${cert.issueDate}" : ""}${cert.expiryDate.isNotEmpty ? " (Expires: ${cert.expiryDate})" : ""}'
                                : (cert.issueDate.isNotEmpty ? cert.issueDate : 'No organization specified'),
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                          if (cert.credentialId.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.tag,
                                  size: 13,
                                  color: AppColors.textMuted,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  'ID: ${cert.credentialId}',
                                  style: AppTypography.bodySmall.copyWith(
                                    color: AppColors.textMuted,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          if (cert.credentialUrl.isNotEmpty) ...[
                            const SizedBox(height: 4),
                            Row(
                              children: [
                                const Icon(
                                  Icons.link,
                                  size: 13,
                                  color: AppColors.secondary,
                                ),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    cert.credentialUrl,
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
                          ],
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: AppColors.textMuted,
                        size: 20,
                      ),
                      tooltip: 'Edit Certification',
                      onPressed: () => _openCertificationDialog(
                        context,
                        ref,
                        certification: cert,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.delete_outline,
                        color: AppColors.accentRed,
                        size: 20,
                      ),
                      tooltip: 'Delete Certification',
                      onPressed: () => _confirmDeleteCertification(
                        context,
                        ref,
                        cert,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  void _openCertificationDialog(
    BuildContext context,
    WidgetRef ref, {
    Certification? certification,
  }) {
    CertificationEditorDialog.show(
      context: context,
      certification: certification,
      onSave: (cert) => _saveCertification(ref, cert),
    );
  }

  void _saveCertification(WidgetRef ref, Certification cert) {
    ref.read(currentResumeProvider.notifier).updateResume((resume) {
      final list = List<Certification>.from(resume.certifications);
      final index = list.indexWhere((c) => c.id == cert.id);
      if (index != -1) {
        list[index] = cert;
      } else {
        list.add(cert);
      }
      return resume.copyWith(certifications: list);
    });
  }

  void _confirmDeleteCertification(
    BuildContext context,
    WidgetRef ref,
    Certification cert,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Certification'),
        content: Text(
          'Are you sure you want to delete "${cert.name}"? This action cannot be undone.',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          AppButton(
            text: 'Delete',
            isFullWidth: false,
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteCertification(ref, cert.id);
            },
          ),
        ],
      ),
    );
  }

  void _deleteCertification(WidgetRef ref, String id) {
    ref.read(currentResumeProvider.notifier).updateResume((resume) {
      return resume.copyWith(
        certifications: resume.certifications.where((c) => c.id != id).toList(),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Languages Section CRUD
  // ---------------------------------------------------------------------------
  Widget _buildLanguagesSection(
    BuildContext context,
    WidgetRef ref,
    Resume resume,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.language_outlined,
                    color: AppColors.secondary,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('Languages', style: AppTypography.titleLarge),
              ],
            ),
            AppButton(
              text: 'Add Language',
              icon: Icons.add,
              isFullWidth: false,
              onPressed: () => _openLanguageDialog(context, ref, resume),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (resume.languages.isEmpty)
          AppCard(
            color: AppColors.surfaceLight.withValues(alpha: 0.5),
            child: Row(
              children: [
                const Icon(
                  Icons.translate_outlined,
                  color: AppColors.textMuted,
                  size: 32,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('No languages added yet', style: AppTypography.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        'List the languages you speak and your proficiency level (e.g. Native, Fluent, Conversational).',
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
                  onPressed: () => _openLanguageDialog(context, ref, resume),
                ),
              ],
            ),
          )
        else
          Wrap(
            spacing: AppSpacing.sm,
            runSpacing: AppSpacing.sm,
            children: resume.languages.map((lang) {
              return Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.md,
                  vertical: AppSpacing.sm,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surfaceLight,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.surfaceBorder),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      lang.name,
                      style: AppTypography.labelLarge.copyWith(
                        color: AppColors.textPrimary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        lang.proficiency,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.secondary,
                          fontWeight: FontWeight.w600,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    InkWell(
                      onTap: () => _openLanguageDialog(
                        context,
                        ref,
                        resume,
                        language: lang,
                      ),
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(
                          Icons.edit_outlined,
                          size: 15,
                          color: AppColors.textMuted,
                        ),
                      ),
                    ),
                    const SizedBox(width: 4),
                    InkWell(
                      onTap: () => _confirmDeleteLanguage(context, ref, lang),
                      borderRadius: BorderRadius.circular(12),
                      child: const Padding(
                        padding: EdgeInsets.all(2),
                        child: Icon(
                          Icons.close,
                          size: 15,
                          color: AppColors.accentRed,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
      ],
    );
  }

  void _openLanguageDialog(
    BuildContext context,
    WidgetRef ref,
    Resume resume, {
    Language? language,
  }) {
    LanguageEditorDialog.show(
      context: context,
      language: language,
      existingLanguages: resume.languages,
      onSave: (lang) => _saveLanguage(ref, lang),
    );
  }

  void _saveLanguage(WidgetRef ref, Language lang) {
    ref.read(currentResumeProvider.notifier).updateResume((resume) {
      final list = List<Language>.from(resume.languages);
      final index = list.indexWhere((l) => l.id == lang.id);
      if (index != -1) {
        list[index] = lang;
      } else {
        list.add(lang);
      }
      return resume.copyWith(languages: list);
    });
  }

  void _confirmDeleteLanguage(
    BuildContext context,
    WidgetRef ref,
    Language lang,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Language'),
        content: Text(
          'Are you sure you want to delete "${lang.name}"?',
          style: AppTypography.bodyMedium,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          AppButton(
            text: 'Delete',
            isFullWidth: false,
            onPressed: () {
              Navigator.of(ctx).pop();
              _deleteLanguage(ref, lang.id);
            },
          ),
        ],
      ),
    );
  }

  void _deleteLanguage(WidgetRef ref, String id) {
    ref.read(currentResumeProvider.notifier).updateResume((resume) {
      return resume.copyWith(
        languages: resume.languages.where((l) => l.id != id).toList(),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Custom Sections
  // ---------------------------------------------------------------------------
  Widget _buildCustomSections(
    BuildContext context,
    WidgetRef ref,
    Resume resume,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: AppColors.accentPurple.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.dashboard_customize_outlined,
                    color: AppColors.accentPurple,
                    size: 20,
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('Custom Sections', style: AppTypography.titleLarge),
              ],
            ),
            AppButton(
              text: 'Add Section',
              icon: Icons.add,
              isFullWidth: false,
              onPressed: () => _showCustomSectionDialog(context, ref),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        if (resume.customSections.isEmpty)
          AppCard(
            color: AppColors.surfaceLight.withValues(alpha: 0.5),
            child: Row(
              children: [
                const Icon(
                  Icons.add_box_outlined,
                  color: AppColors.textMuted,
                  size: 32,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('No custom sections added', style: AppTypography.titleMedium),
                      const SizedBox(height: 2),
                      Text(
                        'Add custom sections such as Publications, Awards & Honors, Volunteering, or Interests.',
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
                  onPressed: () => _showCustomSectionDialog(context, ref),
                ),
              ],
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: resume.customSections.length,
            separatorBuilder: (c, i) => const SizedBox(height: AppSpacing.md),
            itemBuilder: (context, index) {
              final section = resume.customSections[index];
              return AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            section.title.isNotEmpty ? section.title : 'Untitled Section',
                            style: AppTypography.titleMedium.copyWith(
                              color: AppColors.accentPurple,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.edit_outlined,
                            color: AppColors.textMuted,
                            size: 20,
                          ),
                          tooltip: 'Edit Section',
                          onPressed: () => _showCustomSectionDialog(
                            context,
                            ref,
                            section: section,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(
                            Icons.delete_outline,
                            color: AppColors.accentRed,
                            size: 20,
                          ),
                          tooltip: 'Delete Section',
                          onPressed: () => _deleteCustomSection(ref, section.id),
                        ),
                      ],
                    ),
                    if (section.items.isNotEmpty) ...[
                      const SizedBox(height: AppSpacing.xs),
                      ...section.items.map(
                        (bullet) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                '• ',
                                style: TextStyle(
                                  color: AppColors.accentPurple,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  bullet,
                                  style: AppTypography.bodyMedium,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Text(
                          'No bullet points added yet.',
                          style: AppTypography.bodySmall.copyWith(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  void _showCustomSectionDialog(
    BuildContext context,
    WidgetRef ref, {
    CustomSection? section,
  }) {
    final titleCtrl = TextEditingController(text: section?.title ?? '');
    final itemsCtrl = TextEditingController(
      text: section != null ? section.items.join('\n') : '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          section == null ? 'Add Custom Section' : 'Edit Custom Section',
          style: AppTypography.titleLarge,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'Section Title',
                hint: 'e.g. Publications, Awards, Volunteering',
                controller: titleCtrl,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Bullet Points / Entries (one per line)',
                hint: 'Enter each bullet point or item on a new line...',
                maxLines: 5,
                controller: itemsCtrl,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: AppColors.textMuted)),
          ),
          AppButton(
            text: 'Save',
            isFullWidth: false,
            onPressed: () {
              if (titleCtrl.text.trim().isNotEmpty) {
                final bulletList = itemsCtrl.text
                    .split('\n')
                    .map((s) => s.trim())
                    .where((s) => s.isNotEmpty)
                    .toList();

                final customSec = CustomSection(
                  id: section?.id,
                  title: titleCtrl.text.trim(),
                  items: bulletList,
                );
                _saveCustomSection(ref, customSec);
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  void _saveCustomSection(WidgetRef ref, CustomSection section) {
    ref.read(currentResumeProvider.notifier).updateResume((resume) {
      final list = List<CustomSection>.from(resume.customSections);
      final index = list.indexWhere((s) => s.id == section.id);
      if (index != -1) {
        list[index] = section;
      } else {
        list.add(section);
      }
      return resume.copyWith(customSections: list);
    });
  }

  void _deleteCustomSection(WidgetRef ref, String id) {
    ref.read(currentResumeProvider.notifier).updateResume((resume) {
      return resume.copyWith(
        customSections: resume.customSections.where((s) => s.id != id).toList(),
      );
    });
  }
}
