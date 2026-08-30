import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../data/models/resume_models.dart';
import '../widgets/certification_editor_dialog.dart';
import '../widgets/custom_section_editor_dialog.dart';
import '../widgets/language_editor_dialog.dart';
import '../widgets/reorderable_section_card.dart';

/// SectionEditorTab provides the editor UI for supplementary resume sections
/// with drag-and-drop reordering using Flutter's [ReorderableListView]:
/// - Certifications & Licenses (Full CRUD & Reorderable)
/// - Languages & Proficiency (Full CRUD & Reorderable)
/// - Custom User-Defined Sections (Full CRUD & Reorderable)
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
          _buildReorderTipsCard(),
          const SizedBox(height: AppSpacing.lg),
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

  /// Informative banner highlighting drag-and-drop capability.
  Widget _buildReorderTipsCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.swap_vert_circle_outlined,
            color: AppColors.primary,
            size: 24,
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Drag-and-Drop Reordering Active',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Grab the drag handle (⋮⋮) on any item to reorder it upward or downward. Changes save automatically.',
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Certifications Section (Reorderable)
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
                if (resume.certifications.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${resume.certifications.length}',
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
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: resume.certifications.length,
            // ignore: deprecated_member_use
            onReorder: (oldIndex, newIndex) {
              // Flutter ReorderableListView downward index adjustment
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              final list = List<Certification>.from(resume.certifications);
              final item = list.removeAt(oldIndex);
              list.insert(newIndex, item);
              ref.read(currentResumeProvider.notifier).updateResume(
                    (r) => r.copyWith(certifications: list),
                  );
            },
            itemBuilder: (context, index) {
              final cert = resume.certifications[index];
              return ReorderableSectionCard(
                key: ValueKey('cert_${cert.id}'),
                index: index,
                leading: Container(
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
                title: cert.name,
                subtitle: cert.issuingOrganization.isNotEmpty
                    ? '${cert.issuingOrganization}${cert.issueDate.isNotEmpty ? " • ${cert.issueDate}" : ""}${cert.expiryDate.isNotEmpty ? " (Expires: ${cert.expiryDate})" : ""}'
                    : (cert.issueDate.isNotEmpty ? cert.issueDate : 'No organization specified'),
                extraContent: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (cert.credentialId.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.tag, size: 13, color: AppColors.textMuted),
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
                      ),
                    if (cert.credentialUrl.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            const Icon(Icons.link, size: 13, color: AppColors.secondary),
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
                      ),
                  ],
                ),
                onEdit: () => _openCertificationDialog(
                  context,
                  ref,
                  certification: cert,
                ),
                onDelete: () => _confirmDeleteCertification(
                  context,
                  ref,
                  cert,
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
  // Languages Section (Reorderable)
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
                if (resume.languages.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${resume.languages.length}',
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
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: resume.languages.length,
            // ignore: deprecated_member_use
            onReorder: (oldIndex, newIndex) {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              final list = List<Language>.from(resume.languages);
              final item = list.removeAt(oldIndex);
              list.insert(newIndex, item);
              ref.read(currentResumeProvider.notifier).updateResume(
                    (r) => r.copyWith(languages: list),
                  );
            },
            itemBuilder: (context, index) {
              final lang = resume.languages[index];
              return ReorderableSectionCard(
                key: ValueKey('lang_${lang.id}'),
                index: index,
                leading: Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.translate,
                    color: AppColors.secondary,
                    size: 18,
                  ),
                ),
                title: lang.name,
                subtitle: 'Proficiency Level: ${lang.proficiency}',
                tags: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.secondary.withValues(alpha: 0.18),
                      borderRadius: BorderRadius.circular(8),
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
                ],
                onEdit: () => _openLanguageDialog(
                  context,
                  ref,
                  resume,
                  language: lang,
                ),
                onDelete: () => _confirmDeleteLanguage(context, ref, lang),
              );
            },
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
  // Custom Sections (Reorderable)
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
                if (resume.customSections.isNotEmpty) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.accentPurple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${resume.customSections.length}',
                      style: AppTypography.bodySmall.copyWith(
                        color: AppColors.accentPurple,
                        fontWeight: FontWeight.bold,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
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
          ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: resume.customSections.length,
            // ignore: deprecated_member_use
            onReorder: (oldIndex, newIndex) {
              if (oldIndex < newIndex) {
                newIndex -= 1;
              }
              final list = List<CustomSection>.from(resume.customSections);
              final item = list.removeAt(oldIndex);
              list.insert(newIndex, item);
              ref.read(currentResumeProvider.notifier).updateResume(
                    (r) => r.copyWith(customSections: list),
                  );
            },
            itemBuilder: (context, index) {
              final section = resume.customSections[index];
              return ReorderableSectionCard(
                key: ValueKey('custom_${section.id}'),
                index: index,
                leading: Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.accentPurple.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.folder_special_outlined,
                    color: AppColors.accentPurple,
                    size: 20,
                  ),
                ),
                title: section.title.isNotEmpty ? section.title : 'Untitled Section',
                subtitle: '${section.items.length} ${section.items.length == 1 ? "entry" : "entries"}',
                extraContent: section.items.isNotEmpty
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: section.items.map(
                          (bullet) => Padding(
                            padding: const EdgeInsets.only(bottom: 3),
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
                        ).toList(),
                      )
                    : Text(
                        'No bullet points added yet.',
                        style: AppTypography.bodySmall.copyWith(
                          fontStyle: FontStyle.italic,
                          color: AppColors.textMuted,
                        ),
                      ),
                onEdit: () => _showCustomSectionDialog(
                  context,
                  ref,
                  section: section,
                ),
                onDelete: () => _confirmDeleteCustomSection(
                  context,
                  ref,
                  section,
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
    CustomSectionEditorDialog.show(
      context: context,
      section: section,
      onSave: (sec) => _saveCustomSection(ref, sec),
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

  void _confirmDeleteCustomSection(
    BuildContext context,
    WidgetRef ref,
    CustomSection section,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Custom Section'),
        content: Text(
          'Are you sure you want to delete "${section.title}"? This action cannot be undone.',
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
              _deleteCustomSection(ref, section.id);
            },
          ),
        ],
      ),
    );
  }

  void _deleteCustomSection(WidgetRef ref, String id) {
    ref.read(currentResumeProvider.notifier).updateResume((resume) {
      return resume.copyWith(
        customSections: resume.customSections.where((s) => s.id != id).toList(),
      );
    });
  }
}
