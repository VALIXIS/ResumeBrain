import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../data/models/resume_models.dart';
import '../utils/resume_input_scrubber.dart';
import 'validated_form_field.dart';

/// Predefined language proficiency levels.
const List<String> kLanguageProficiencies = [
  'Native / Bilingual',
  'Fluent',
  'Professional Working',
  'Conversational',
  'Elementary',
];

/// LanguageEditorDialog provides a modal dialog for creating and editing
/// resume languages with real-time validation and focus traversal.
class LanguageEditorDialog extends StatefulWidget {
  final Language? language;
  final List<Language> existingLanguages;
  final ValueChanged<Language> onSave;

  const LanguageEditorDialog({
    super.key,
    this.language,
    this.existingLanguages = const [],
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    Language? language,
    List<Language> existingLanguages = const [],
    required ValueChanged<Language> onSave,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => LanguageEditorDialog(
        language: language,
        existingLanguages: existingLanguages,
        onSave: onSave,
      ),
    );
  }

  @override
  State<LanguageEditorDialog> createState() => _LanguageEditorDialogState();
}

class _LanguageEditorDialogState extends State<LanguageEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameCtrl;
  late String _selectedProficiency;

  @override
  void initState() {
    super.initState();
    final lang = widget.language;
    _nameCtrl = TextEditingController(text: lang?.name ?? '');
    _selectedProficiency =
        lang?.proficiency.isNotEmpty == true ? lang!.proficiency : kLanguageProficiencies.first;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Language name is required';
    }
    if (value.trim().length > 50) {
      return 'Language name cannot exceed 50 characters';
    }
    final trimmedLower = value.trim().toLowerCase();
    final isDuplicate = widget.existingLanguages.any(
      (lang) =>
          lang.id != widget.language?.id &&
          lang.name.trim().toLowerCase() == trimmedLower,
    );
    if (isDuplicate) {
      return 'This language has already been added';
    }
    return null;
  }

  void _handleSave() {
    if (_formKey.currentState?.validate() ?? false) {
      final lang = Language(
        id: widget.language?.id,
        name: _nameCtrl.text.trim(),
        proficiency: _selectedProficiency,
      );
      widget.onSave(lang);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.language != null;
    final proficiencies = kLanguageProficiencies.contains(_selectedProficiency)
        ? kLanguageProficiencies
        : [_selectedProficiency, ...kLanguageProficiencies];

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: FocusTraversalGroup(
          policy: ReadingOrderTraversalPolicy(),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.secondary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.language_outlined,
                          color: AppColors.secondary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          isEditing ? 'Edit Language' : 'Add Language',
                          style: AppTypography.titleLarge,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.textMuted),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),
                  const Divider(color: AppColors.surfaceBorder, height: 1),
                  const SizedBox(height: AppSpacing.md),

                  // Form Fields
                  ValidatedFormField(
                    label: 'Language Name',
                    hint: 'e.g. Spanish, French, German, Japanese',
                    controller: _nameCtrl,
                    maxLength: 50,
                    isRequired: true,
                    inputFormatters: [ResumeInputScrubber.nameFormatter()],
                    validator: _validateName,
                    textInputAction: TextInputAction.done,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  Text(
                    'Proficiency Level',
                    style: AppTypography.labelLarge.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedProficiency,
                    dropdownColor: AppColors.surfaceLight,
                    style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.surfaceLight,
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: AppRadius.borderMd,
                        borderSide: const BorderSide(color: AppColors.surfaceBorder),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: AppRadius.borderMd,
                        borderSide: const BorderSide(color: AppColors.surfaceBorder),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: AppRadius.borderMd,
                        borderSide: const BorderSide(color: AppColors.primary, width: 2),
                      ),
                    ),
                    items: proficiencies
                        .map((p) => DropdownMenuItem(
                              value: p,
                              child: Text(p),
                            ))
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _selectedProficiency = val;
                        });
                      }
                    },
                  ),
                  const SizedBox(height: AppSpacing.lg),

                  // Action Buttons
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: Text(
                          'Cancel',
                          style: AppTypography.labelLarge.copyWith(
                            color: AppColors.textMuted,
                          ),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      AppButton(
                        text: isEditing ? 'Save Changes' : 'Add Language',
                        isFullWidth: false,
                        onPressed: _handleSave,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
