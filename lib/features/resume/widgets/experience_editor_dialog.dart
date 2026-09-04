import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../data/models/resume_models.dart';
import '../utils/resume_input_scrubber.dart';
import 'bullet_point_enhancer.dart';
import 'resume_validators.dart';
import 'validated_form_field.dart';

/// ExperienceEditorDialog provides a modal dialog for adding and editing
/// Work Experience entries with real-time field validation, focus traversal, and Riverpod AI integration.
class ExperienceEditorDialog extends ConsumerStatefulWidget {
  final Experience? experience;
  final ValueChanged<Experience> onSave;

  const ExperienceEditorDialog({
    super.key,
    this.experience,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    Experience? experience,
    required ValueChanged<Experience> onSave,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => ExperienceEditorDialog(
        experience: experience,
        onSave: onSave,
      ),
    );
  }

  @override
  ConsumerState<ExperienceEditorDialog> createState() => _ExperienceEditorDialogState();
}

class _ExperienceEditorDialogState extends ConsumerState<ExperienceEditorDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _companyCtrl;
  late final TextEditingController _positionCtrl;
  late final TextEditingController _locationCtrl;
  late final TextEditingController _startDateCtrl;
  late final TextEditingController _endDateCtrl;
  late final TextEditingController _descCtrl;

  late bool _isCurrent;

  @override
  void initState() {
    super.initState();
    final exp = widget.experience;
    _companyCtrl = TextEditingController(text: exp?.company ?? '');
    _positionCtrl = TextEditingController(text: exp?.position ?? '');
    _locationCtrl = TextEditingController(text: exp?.location ?? '');
    _startDateCtrl = TextEditingController(text: exp?.startDate ?? '');
    _endDateCtrl = TextEditingController(text: exp?.endDate ?? '');
    _descCtrl = TextEditingController(text: exp?.description ?? '');
    _isCurrent = exp?.isCurrent ?? false;
  }

  @override
  void dispose() {
    _companyCtrl.dispose();
    _positionCtrl.dispose();
    _locationCtrl.dispose();
    _startDateCtrl.dispose();
    _endDateCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  void _handleSave() {
    if (_formKey.currentState?.validate() ?? false) {
      final exp = Experience(
        id: widget.experience?.id,
        company: _companyCtrl.text.trim(),
        position: _positionCtrl.text.trim(),
        location: _locationCtrl.text.trim(),
        startDate: _startDateCtrl.text.trim(),
        endDate: _isCurrent ? 'Present' : _endDateCtrl.text.trim(),
        isCurrent: _isCurrent,
        description: _descCtrl.text.trim(),
      );
      widget.onSave(exp);
      Navigator.of(context).pop();
    }
  }

  void _enhanceDescription() {
    final text = _descCtrl.text.trim();
    final roleCtx = '${_positionCtrl.text.trim()} ${_companyCtrl.text.trim()}'.trim();
    BulletPointEnhancerDialog.show(
      context: context,
      initialBullet: text,
      roleContext: roleCtx.isEmpty ? null : roleCtx,
      onApply: (enhanced) {
        setState(() {
          _descCtrl.text = enhanced;
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.experience != null;

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
                          Icons.work_outline,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          isEditing ? 'Edit Work Experience' : 'Add Work Experience',
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

                  // Company & Position
                  ValidatedFormField(
                    label: 'Company / Organization',
                    hint: 'e.g. Google, Valixis, Stripe',
                    controller: _companyCtrl,
                    maxLength: 100,
                    isRequired: true,
                    inputFormatters: [ResumeInputScrubber.titleFormatter()],
                    validator: (val) => ResumeValidators.validateRequired(val, 'Company name', maxLength: 100),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  ValidatedFormField(
                    label: 'Job Title / Position',
                    hint: 'e.g. Senior Software Engineer',
                    controller: _positionCtrl,
                    maxLength: 100,
                    isRequired: true,
                    inputFormatters: [ResumeInputScrubber.titleFormatter()],
                    validator: (val) => ResumeValidators.validateRequired(val, 'Job title', maxLength: 100),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  ValidatedFormField(
                    label: 'Location (Optional)',
                    hint: 'e.g. San Francisco, CA / Remote',
                    controller: _locationCtrl,
                    maxLength: 100,
                    inputFormatters: [ResumeInputScrubber.titleFormatter()],
                    validator: (val) => ResumeValidators.validateOptionalLength(val, 'Location', maxLength: 100),
                  ),
                  const SizedBox(height: AppSpacing.md),

                  // Start Date & End Date
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ValidatedFormField(
                          label: 'Start Date',
                          hint: 'e.g. 2021 or 06/2021',
                          controller: _startDateCtrl,
                          maxLength: 30,
                          isRequired: true,
                          inputFormatters: [ResumeInputScrubber.dateFormatter()],
                          validator: (val) => ResumeValidators.validateDate(val, 'Start date', isRequired: true),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: _isCurrent
                            ? Container(
                                margin: const EdgeInsets.only(top: 24),
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                decoration: BoxDecoration(
                                  color: AppColors.surfaceLight,
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: AppColors.surfaceBorder),
                                ),
                                child: Text(
                                  'Present (Current)',
                                  style: AppTypography.bodyMedium.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600),
                                ),
                              )
                            : ValidatedFormField(
                                label: 'End Date',
                                hint: 'e.g. 2023 or 08/2023',
                                controller: _endDateCtrl,
                                maxLength: 30,
                                isRequired: true,
                                inputFormatters: [ResumeInputScrubber.dateFormatter()],
                                validator: (val) {
                                  final dateErr = ResumeValidators.validateDate(val, 'End date', isRequired: true);
                                  if (dateErr != null) return dateErr;
                                  return ResumeValidators.validateDateRange(
                                    _startDateCtrl.text,
                                    val,
                                    isCurrent: _isCurrent,
                                  );
                                },
                              ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),

                  // Current Job Checkbox
                  CheckboxListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(
                      'I currently work in this role',
                      style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                    ),
                    value: _isCurrent,
                    activeColor: AppColors.primary,
                    onChanged: (val) {
                      setState(() {
                        _isCurrent = val ?? false;
                        if (_isCurrent) {
                          _endDateCtrl.text = 'Present';
                        } else if (_endDateCtrl.text == 'Present') {
                          _endDateCtrl.text = '';
                        }
                      });
                    },
                  ),
                  const SizedBox(height: AppSpacing.sm),

                  // Description with AI Button
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Responsibilities & Accomplishments',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Semantics(
                        button: true,
                        label: 'AI Enhance Responsibilities and Accomplishments',
                        child: TextButton.icon(
                          style: TextButton.styleFrom(
                            minimumSize: const Size(48, 48),
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                          ),
                          onPressed: _enhanceDescription,
                          icon: const Icon(Icons.auto_awesome, size: 16, color: AppColors.accentPurple),
                          label: Text(
                            'AI Enhance',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.accentPurple,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  ValidatedFormField(
                    label: '',
                    hint: '• Led development of scalable microservices...\n• Improved query latency by 40%...',
                    controller: _descCtrl,
                    maxLines: 5,
                    maxLength: 2000,
                    inputFormatters: [ResumeInputScrubber.textBlockFormatter()],
                    validator: (val) => ResumeValidators.validateOptionalLength(val, 'Description', maxLength: 2000),
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
                        text: isEditing ? 'Save Changes' : 'Add Experience',
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
