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

/// SectionEditorTab provides the editor UI skeleton for supplementary resume sections:
/// - Certifications & Licenses
/// - Languages & Proficiency
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
  // Certifications Section
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
                const Icon(
                  Icons.verified_outlined,
                  color: AppColors.primary,
                  size: 22,
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
              onPressed: () => _showCertificationDialog(context, ref),
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
                  onPressed: () => _showCertificationDialog(context, ref),
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
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(cert.name, style: AppTypography.titleMedium),
                          const SizedBox(height: 2),
                          Text(
                            cert.issuingOrganization.isNotEmpty
                                ? '${cert.issuingOrganization}${cert.issueDate.isNotEmpty ? " • ${cert.issueDate}" : ""}'
                                : (cert.issueDate.isNotEmpty ? cert.issueDate : 'No organization specified'),
                            style: AppTypography.bodySmall,
                          ),
                          if (cert.credentialId.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              'ID: ${cert.credentialId}',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.textMuted,
                              ),
                            ),
                          ],
                          if (cert.credentialUrl.isNotEmpty) ...[
                            const SizedBox(height: 2),
                            Text(
                              cert.credentialUrl,
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.secondary,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
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
                      tooltip: 'Edit',
                      onPressed: () => _showCertificationDialog(
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
                      tooltip: 'Delete',
                      onPressed: () => _deleteCertification(ref, cert.id),
                    ),
                  ],
                ),
              );
            },
          ),
      ],
    );
  }

  void _showCertificationDialog(
    BuildContext context,
    WidgetRef ref, {
    Certification? certification,
  }) {
    final nameCtrl = TextEditingController(text: certification?.name ?? '');
    final orgCtrl = TextEditingController(
      text: certification?.issuingOrganization ?? '',
    );
    final issueDateCtrl = TextEditingController(
      text: certification?.issueDate ?? '',
    );
    final expiryDateCtrl = TextEditingController(
      text: certification?.expiryDate ?? '',
    );
    final credIdCtrl = TextEditingController(
      text: certification?.credentialId ?? '',
    );
    final credUrlCtrl = TextEditingController(
      text: certification?.credentialUrl ?? '',
    );

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: Text(
          certification == null ? 'Add Certification' : 'Edit Certification',
          style: AppTypography.titleLarge,
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(
                label: 'Certification Name',
                hint: 'e.g. AWS Certified Solutions Architect',
                controller: nameCtrl,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Issuing Organization',
                hint: 'e.g. Amazon Web Services',
                controller: orgCtrl,
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Issue Date',
                      hint: 'e.g. Jan 2023',
                      controller: issueDateCtrl,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: AppTextField(
                      label: 'Expiry Date',
                      hint: 'e.g. Jan 2026',
                      controller: expiryDateCtrl,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Credential ID (Optional)',
                hint: 'e.g. ABC-1234567',
                controller: credIdCtrl,
              ),
              const SizedBox(height: AppSpacing.md),
              AppTextField(
                label: 'Credential URL (Optional)',
                hint: 'e.g. https://aws.amazon.com/verify/...',
                controller: credUrlCtrl,
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
              if (nameCtrl.text.trim().isNotEmpty) {
                final cert = Certification(
                  id: certification?.id,
                  name: nameCtrl.text.trim(),
                  issuingOrganization: orgCtrl.text.trim(),
                  issueDate: issueDateCtrl.text.trim(),
                  expiryDate: expiryDateCtrl.text.trim(),
                  credentialId: credIdCtrl.text.trim(),
                  credentialUrl: credUrlCtrl.text.trim(),
                );
                _saveCertification(ref, cert);
              }
              Navigator.pop(context);
            },
          ),
        ],
      ),
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

  void _deleteCertification(WidgetRef ref, String id) {
    ref.read(currentResumeProvider.notifier).updateResume((resume) {
      return resume.copyWith(
        certifications: resume.certifications.where((c) => c.id != id).toList(),
      );
    });
  }

  // ---------------------------------------------------------------------------
  // Languages Section
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
                const Icon(
                  Icons.language_outlined,
                  color: AppColors.secondary,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.sm),
                Text('Languages', style: AppTypography.titleLarge),
              ],
            ),
            AppButton(
              text: 'Add Language',
              icon: Icons.add,
              isFullWidth: false,
              onPressed: () => _showLanguageDialog(context, ref),
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
                  onPressed: () => _showLanguageDialog(context, ref),
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
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.secondary.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        lang.proficiency,
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.secondary,
                          fontSize: 11,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    GestureDetector(
                      onTap: () => _showLanguageDialog(
                        context,
                        ref,
                        language: lang,
                      ),
                      child: const Icon(
                        Icons.edit_outlined,
                        size: 15,
                        color: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => _deleteLanguage(ref, lang.id),
                      child: const Icon(
                        Icons.close,
                        size: 15,
                        color: AppColors.accentRed,
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

  void _showLanguageDialog(
    BuildContext context,
    WidgetRef ref, {
    Language? language,
  }) {
    final nameCtrl = TextEditingController(text: language?.name ?? '');
    String proficiency = language?.proficiency ?? 'Fluent';
    final proficiencies = ['Native', 'Fluent', 'Conversational', 'Beginner'];

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(
            language == null ? 'Add Language' : 'Edit Language',
            style: AppTypography.titleLarge,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AppTextField(
                label: 'Language Name',
                hint: 'e.g. Spanish, French, Japanese',
                controller: nameCtrl,
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                'Proficiency Level',
                style: AppTypography.labelLarge.copyWith(color: AppColors.textSecondary),
              ),
              const SizedBox(height: AppSpacing.sm),
              DropdownButtonFormField<String>(
                initialValue: proficiencies.contains(proficiency) ? proficiency : proficiencies.first,
                dropdownColor: AppColors.surfaceLight,
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: AppColors.surfaceLight,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.surfaceBorder),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.surfaceBorder),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: AppColors.primary, width: 2),
                  ),
                ),
                items: proficiencies
                    .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                    .toList(),
                onChanged: (val) {
                  if (val != null) {
                    setDialogState(() => proficiency = val);
                  }
                },
              ),
            ],
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
                if (nameCtrl.text.trim().isNotEmpty) {
                  final lang = Language(
                    id: language?.id,
                    name: nameCtrl.text.trim(),
                    proficiency: proficiency,
                  );
                  _saveLanguage(ref, lang);
                }
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
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
                const Icon(
                  Icons.dashboard_customize_outlined,
                  color: AppColors.accentPurple,
                  size: 22,
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
