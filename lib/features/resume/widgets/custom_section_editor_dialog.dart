import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../data/models/resume_models.dart';
import 'resume_validators.dart';
import 'validated_form_field.dart';

/// CustomSectionEditorDialog provides a modal dialog for creating and editing
/// arbitrary custom resume sections (e.g. Publications, Volunteer, Awards, Speaking)
/// with real-time field validation.
class CustomSectionEditorDialog extends StatefulWidget {
  final CustomSection? section;
  final ValueChanged<CustomSection> onSave;

  const CustomSectionEditorDialog({
    super.key,
    this.section,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    CustomSection? section,
    required ValueChanged<CustomSection> onSave,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomSectionEditorDialog(
        section: section,
        onSave: onSave,
      ),
    );
  }

  @override
  State<CustomSectionEditorDialog> createState() => _CustomSectionEditorDialogState();
}

class _CustomSectionEditorDialogState extends State<CustomSectionEditorDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _titleCtrl;
  late final TextEditingController _itemsCtrl;

  @override
  void initState() {
    super.initState();
    final sec = widget.section;
    _titleCtrl = TextEditingController(text: sec?.title ?? '');
    _itemsCtrl = TextEditingController(
      text: sec != null ? sec.items.join('\n') : '',
    );
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _itemsCtrl.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState?.validate() ?? false) {
      final bulletList = _itemsCtrl.text
          .split('\n')
          .map((s) => s.trim())
          .where((s) => s.isNotEmpty)
          .toList();

      final customSec = CustomSection(
        id: widget.section?.id,
        title: _titleCtrl.text.trim(),
        items: bulletList,
      );
      widget.onSave(customSec);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.section != null;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
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
                        color: AppColors.accentPurple.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.dashboard_customize_outlined,
                        color: AppColors.accentPurple,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        isEditing ? 'Edit Custom Section' : 'Add Custom Section',
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

                // Section Title
                ValidatedFormField(
                  label: 'Section Title',
                  hint: 'e.g. Publications, Awards & Honors, Volunteering, Patents',
                  controller: _titleCtrl,
                  maxLength: 80,
                  isRequired: true,
                  validator: (val) => ResumeValidators.validateRequired(
                    val,
                    'Section title',
                    minLength: 2,
                    maxLength: 80,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // Bullet Points
                ValidatedFormField(
                  label: 'Bullet Points / Entries (one per line)',
                  hint: 'Published research on distributed neural transformers (2024)\nReceived Outstanding Contributor Award...',
                  controller: _itemsCtrl,
                  maxLines: 6,
                  maxLength: 1500,
                  validator: (val) => ResumeValidators.validateOptionalLength(
                    val,
                    'Bullet entries',
                    maxLength: 1500,
                  ),
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
                        style: AppTypography.labelLarge.copyWith(color: AppColors.textMuted),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    AppButton(
                      text: isEditing ? 'Save Changes' : 'Add Section',
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
    );
  }
}
