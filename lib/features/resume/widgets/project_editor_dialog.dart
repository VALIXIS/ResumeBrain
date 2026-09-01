import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../data/models/resume_models.dart';
import '../utils/resume_input_scrubber.dart';
import 'resume_validators.dart';
import 'validated_form_field.dart';

/// ProjectEditorDialog provides a modal dialog for creating and editing
/// Showcase Projects with real-time field validation, focus traversal, and URL checks.
class ProjectEditorDialog extends StatefulWidget {
  final Project? project;
  final ValueChanged<Project> onSave;

  const ProjectEditorDialog({
    super.key,
    this.project,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    Project? project,
    required ValueChanged<Project> onSave,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ProjectEditorDialog(
        project: project,
        onSave: onSave,
      ),
    );
  }

  @override
  State<ProjectEditorDialog> createState() => _ProjectEditorDialogState();
}

class _ProjectEditorDialogState extends State<ProjectEditorDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _roleCtrl;
  late final TextEditingController _technologiesCtrl;
  late final TextEditingController _linkCtrl;
  late final TextEditingController _descriptionCtrl;

  @override
  void initState() {
    super.initState();
    final p = widget.project;
    _nameCtrl = TextEditingController(text: p?.name ?? '');
    _roleCtrl = TextEditingController(text: p?.role ?? '');
    _technologiesCtrl = TextEditingController(text: p?.technologies ?? '');
    _linkCtrl = TextEditingController(text: p?.link ?? '');
    _descriptionCtrl = TextEditingController(text: p?.description ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _roleCtrl.dispose();
    _technologiesCtrl.dispose();
    _linkCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState?.validate() ?? false) {
      final proj = Project(
        id: widget.project?.id,
        name: _nameCtrl.text.trim(),
        role: _roleCtrl.text.trim(),
        technologies: _technologiesCtrl.text.trim(),
        link: _linkCtrl.text.trim(),
        description: _descriptionCtrl.text.trim(),
      );
      widget.onSave(proj);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.project != null;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 580),
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
                          Icons.rocket_launch_outlined,
                          color: AppColors.secondary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          isEditing ? 'Edit Project' : 'Add Project',
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

                  // Project Name & Role
                  ValidatedFormField(
                    label: 'Project Name',
                    hint: 'e.g. ResumeBrain AI, E-Commerce Platform',
                    controller: _nameCtrl,
                    maxLength: 100,
                    isRequired: true,
                    inputFormatters: [ResumeInputScrubber.titleFormatter()],
                    validator: (val) => ResumeValidators.validateRequired(val, 'Project name', maxLength: 100),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ValidatedFormField(
                          label: 'Your Role / Title (Optional)',
                          hint: 'e.g. Lead Architect, Full Stack Dev',
                          controller: _roleCtrl,
                          maxLength: 80,
                          inputFormatters: [ResumeInputScrubber.titleFormatter()],
                          validator: (val) => ResumeValidators.validateOptionalLength(val, 'Role', maxLength: 80),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ValidatedFormField(
                          label: 'Technologies Used',
                          hint: 'e.g. Flutter, Dart, Riverpod, Firebase',
                          controller: _technologiesCtrl,
                          maxLength: 150,
                          inputFormatters: [ResumeInputScrubber.titleFormatter()],
                          validator: (val) => ResumeValidators.validateOptionalLength(val, 'Technologies', maxLength: 150),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Link / URL
                  ValidatedFormField(
                    label: 'Project Link / Demo / GitHub (Optional)',
                    hint: 'e.g. https://github.com/username/project',
                    controller: _linkCtrl,
                    maxLength: 200,
                    keyboardType: TextInputType.url,
                    inputFormatters: [ResumeInputScrubber.urlFormatter()],
                    validator: (val) => ResumeValidators.validateUrl(val),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Description
                  ValidatedFormField(
                    label: 'Project Overview & Key Accomplishments',
                    hint: '• Architected state management using Riverpod...\n• Achieved 60fps across mobile and web targets...',
                    controller: _descriptionCtrl,
                    maxLines: 4,
                    maxLength: 1000,
                    inputFormatters: [ResumeInputScrubber.textBlockFormatter()],
                    validator: (val) => ResumeValidators.validateOptionalLength(val, 'Description', maxLength: 1000),
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
                        text: isEditing ? 'Save Changes' : 'Add Project',
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
