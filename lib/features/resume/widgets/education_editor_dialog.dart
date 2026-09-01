import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../data/models/resume_models.dart';
import '../utils/resume_input_scrubber.dart';
import 'resume_validators.dart';
import 'validated_form_field.dart';

/// EducationEditorDialog provides a modal dialog for creating and editing
/// Education credentials with real-time field validation, focus traversal, and GPA format checks.
class EducationEditorDialog extends StatefulWidget {
  final Education? education;
  final ValueChanged<Education> onSave;

  const EducationEditorDialog({
    super.key,
    this.education,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    Education? education,
    required ValueChanged<Education> onSave,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => EducationEditorDialog(
        education: education,
        onSave: onSave,
      ),
    );
  }

  @override
  State<EducationEditorDialog> createState() => _EducationEditorDialogState();
}

class _EducationEditorDialogState extends State<EducationEditorDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _instCtrl;
  late final TextEditingController _degreeCtrl;
  late final TextEditingController _fieldCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _startDateCtrl;
  late final TextEditingController _endDateCtrl;
  late final TextEditingController _gpaCtrl;

  @override
  void initState() {
    super.initState();
    final edu = widget.education;
    _instCtrl = TextEditingController(text: edu?.institution ?? '');
    _degreeCtrl = TextEditingController(text: edu?.degree ?? '');
    _fieldCtrl = TextEditingController(text: edu?.fieldOfStudy ?? '');
    _locationCtrl = TextEditingController(text: edu?.location ?? '');
    _startDateCtrl = TextEditingController(text: edu?.startDate ?? '');
    _endDateCtrl = TextEditingController(text: edu?.endDate ?? '');
    _gpaCtrl = TextEditingController(text: edu?.gpa ?? '');
  }

  @override
  void dispose() {
    _instCtrl.dispose();
    _degreeCtrl.dispose();
    _fieldCtrl.dispose();
    _locationCtrl.dispose();
    _startDateCtrl.dispose();
    _endDateCtrl.dispose();
    _gpaCtrl.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState?.validate() ?? false) {
      final edu = Education(
        id: widget.education?.id,
        institution: _instCtrl.text.trim(),
        degree: _degreeCtrl.text.trim(),
        fieldOfStudy: _fieldCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        startDate: _startDateCtrl.text.trim(),
        endDate: _endDateCtrl.text.trim(),
        gpa: _gpaCtrl.text.trim(),
      );
      widget.onSave(edu);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.education != null;

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
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(
                          Icons.school_outlined,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          isEditing ? 'Edit Education' : 'Add Education',
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

                  // Institution Name
                  ValidatedFormField(
                    label: 'School / University / Institution',
                    hint: 'e.g. Stanford University, MIT',
                    controller: _instCtrl,
                    maxLength: 100,
                    isRequired: true,
                    inputFormatters: [ResumeInputScrubber.titleFormatter()],
                    validator: (val) => ResumeValidators.validateRequired(val, 'Institution name', maxLength: 100),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Degree & Field of Study
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ValidatedFormField(
                          label: 'Degree',
                          hint: 'e.g. Bachelor of Science, Master of Arts',
                          controller: _degreeCtrl,
                          maxLength: 100,
                          isRequired: true,
                          inputFormatters: [ResumeInputScrubber.titleFormatter()],
                          validator: (val) => ResumeValidators.validateRequired(val, 'Degree', maxLength: 100),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ValidatedFormField(
                          label: 'Field of Study / Major',
                          hint: 'e.g. Computer Science, Economics',
                          controller: _fieldCtrl,
                          maxLength: 100,
                          isRequired: true,
                          inputFormatters: [ResumeInputScrubber.titleFormatter()],
                          validator: (val) => ResumeValidators.validateRequired(val, 'Field of study', maxLength: 100),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Start Date & End Date
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ValidatedFormField(
                          label: 'Start Year / Date',
                          hint: 'e.g. 2019',
                          controller: _startDateCtrl,
                          maxLength: 30,
                          isRequired: true,
                          inputFormatters: [ResumeInputScrubber.dateFormatter()],
                          validator: (val) => ResumeValidators.validateDate(val, 'Start date', isRequired: true),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ValidatedFormField(
                          label: 'End Year / Date (or Expected)',
                          hint: 'e.g. 2023',
                          controller: _endDateCtrl,
                          maxLength: 30,
                          isRequired: true,
                          inputFormatters: [ResumeInputScrubber.dateFormatter()],
                          validator: (val) {
                            final dateErr = ResumeValidators.validateDate(val, 'End date', isRequired: true);
                            if (dateErr != null) return dateErr;
                            return ResumeValidators.validateDateRange(_startDateCtrl.text, val);
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Location & GPA
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ValidatedFormField(
                          label: 'Location (Optional)',
                          hint: 'e.g. Stanford, CA',
                          controller: _locationCtrl,
                          maxLength: 100,
                          inputFormatters: [ResumeInputScrubber.titleFormatter()],
                          validator: (val) => ResumeValidators.validateOptionalLength(val, 'Location', maxLength: 100),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: ValidatedFormField(
                          label: 'GPA / Honors (Optional)',
                          hint: 'e.g. 3.9/4.0 or Magna Cum Laude',
                          controller: _gpaCtrl,
                          maxLength: 40,
                          inputFormatters: [ResumeInputScrubber.gpaFormatter()],
                          validator: (val) => ResumeValidators.validateOptionalLength(val, 'GPA', maxLength: 40),
                        ),
                      ),
                    ],
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
                        text: isEditing ? 'Save Changes' : 'Add Education',
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
