import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../data/models/resume_models.dart';
import '../utils/resume_input_scrubber.dart';
import 'validated_form_field.dart';

/// CertificationEditorDialog provides a modal dialog for creating and editing
/// professional certifications and licenses with real-time validation and focus traversal.
class CertificationEditorDialog extends StatefulWidget {
  final Certification? certification;
  final ValueChanged<Certification> onSave;

  const CertificationEditorDialog({
    super.key,
    this.certification,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    Certification? certification,
    required ValueChanged<Certification> onSave,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CertificationEditorDialog(
        certification: certification,
        onSave: onSave,
      ),
    );
  }

  @override
  State<CertificationEditorDialog> createState() =>
      _CertificationEditorDialogState();
}

class _CertificationEditorDialogState extends State<CertificationEditorDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameCtrl;
  late final TextEditingController _orgCtrl;
  late final TextEditingController _issueDateCtrl;
  late final TextEditingController _expiryDateCtrl;
  late final TextEditingController _credIdCtrl;
  late final TextEditingController _credUrlCtrl;

  @override
  void initState() {
    super.initState();
    final cert = widget.certification;
    _nameCtrl = TextEditingController(text: cert?.name ?? '');
    _orgCtrl = TextEditingController(text: cert?.issuingOrganization ?? '');
    _issueDateCtrl = TextEditingController(text: cert?.issueDate ?? '');
    _expiryDateCtrl = TextEditingController(text: cert?.expiryDate ?? '');
    _credIdCtrl = TextEditingController(text: cert?.credentialId ?? '');
    _credUrlCtrl = TextEditingController(text: cert?.credentialUrl ?? '');
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _orgCtrl.dispose();
    _issueDateCtrl.dispose();
    _expiryDateCtrl.dispose();
    _credIdCtrl.dispose();
    _credUrlCtrl.dispose();
    super.dispose();
  }

  DateTime? _parseDate(String dateStr) {
    if (dateStr.trim().isEmpty) return null;
    final trimmed = dateStr.trim();

    // Check MM/YYYY format
    final mmYyyy = RegExp(r'^(\d{1,2})/(\d{4})$');
    final match = mmYyyy.firstMatch(trimmed);
    if (match != null) {
      final month = int.tryParse(match.group(1)!);
      final year = int.tryParse(match.group(2)!);
      if (month != null && year != null && month >= 1 && month <= 12) {
        return DateTime(year, month, 1);
      }
    }

    // Check YYYY format
    final yyyy = RegExp(r'^(\d{4})$');
    if (yyyy.hasMatch(trimmed)) {
      final year = int.tryParse(trimmed);
      if (year != null) return DateTime(year, 1, 1);
    }

    // Check Month YYYY text format
    const months = {
      'jan': 1, 'january': 1,
      'feb': 2, 'february': 2,
      'mar': 3, 'march': 3,
      'apr': 4, 'april': 4,
      'may': 5,
      'jun': 6, 'june': 6,
      'jul': 7, 'july': 7,
      'aug': 8, 'august': 8,
      'sep': 9, 'september': 9, 'sept': 9,
      'oct': 10, 'october': 10,
      'nov': 11, 'november': 11,
      'dec': 12, 'december': 12,
    };

    final monthNameRegex = RegExp(r'^([a-zA-Z]+)[\s,]+(\d{4})$');
    final monthNameMatch = monthNameRegex.firstMatch(trimmed);
    if (monthNameMatch != null) {
      final monthStr = monthNameMatch.group(1)!.toLowerCase();
      final year = int.tryParse(monthNameMatch.group(2)!);
      if (months.containsKey(monthStr) && year != null) {
        return DateTime(year, months[monthStr]!, 1);
      }
    }

    return DateTime.tryParse(trimmed);
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Certification name is required';
    }
    if (value.trim().length > 100) {
      return 'Certification name cannot exceed 100 characters';
    }
    return null;
  }

  String? _validateOrg(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Issuing organization is required';
    }
    if (value.trim().length > 100) {
      return 'Issuing organization cannot exceed 100 characters';
    }
    return null;
  }

  String? _validateIssueDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Issue date is required';
    }
    return null;
  }

  String? _validateExpiryDate(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Expiry date is optional
    }
    final issueDate = _parseDate(_issueDateCtrl.text);
    final expiryDate = _parseDate(value);

    if (issueDate != null && expiryDate != null) {
      if (expiryDate.isBefore(issueDate)) {
        return 'Expiry date cannot be before issue date';
      }
    }
    return null;
  }

  String? _validateUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Optional
    }
    final trimmed = value.trim();
    if (trimmed.length > 200) {
      return 'URL cannot exceed 200 characters';
    }
    final uri = Uri.tryParse(trimmed);
    final isHttpOrHttps = uri != null &&
        uri.hasScheme &&
        (uri.isScheme('http') || uri.isScheme('https')) &&
        uri.host.isNotEmpty;

    if (!isHttpOrHttps) {
      return 'Enter a valid web address (e.g. https://...)';
    }
    return null;
  }

  void _handleSave() {
    if (_formKey.currentState?.validate() ?? false) {
      final cert = Certification(
        id: widget.certification?.id,
        name: _nameCtrl.text.trim(),
        issuingOrganization: _orgCtrl.text.trim(),
        issueDate: _issueDateCtrl.text.trim(),
        expiryDate: _expiryDateCtrl.text.trim(),
        credentialId: _credIdCtrl.text.trim(),
        credentialUrl: _credUrlCtrl.text.trim(),
      );
      widget.onSave(cert);
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.certification != null;

    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
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
                          Icons.verified_outlined,
                          color: AppColors.primary,
                          size: 22,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          isEditing ? 'Edit Certification' : 'Add Certification',
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
                    label: 'Certification Name',
                    hint: 'e.g. AWS Certified Solutions Architect',
                    controller: _nameCtrl,
                    maxLength: 100,
                    isRequired: true,
                    inputFormatters: [ResumeInputScrubber.titleFormatter()],
                    validator: _validateName,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  ValidatedFormField(
                    label: 'Issuing Organization',
                    hint: 'e.g. Amazon Web Services, Coursera, Cisco',
                    controller: _orgCtrl,
                    maxLength: 100,
                    isRequired: true,
                    inputFormatters: [ResumeInputScrubber.titleFormatter()],
                    validator: _validateOrg,
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: ValidatedFormField(
                          label: 'Issue Date',
                          hint: 'e.g. 01/2023 or Jan 2023',
                          controller: _issueDateCtrl,
                          maxLength: 20,
                          isRequired: true,
                          inputFormatters: [ResumeInputScrubber.dateFormatter()],
                          validator: _validateIssueDate,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: ValidatedFormField(
                          label: 'Expiry Date',
                          hint: 'e.g. 01/2026 or No Expiry',
                          controller: _expiryDateCtrl,
                          maxLength: 20,
                          inputFormatters: [ResumeInputScrubber.dateFormatter()],
                          validator: _validateExpiryDate,
                          textInputAction: TextInputAction.next,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.md),

                  ValidatedFormField(
                    label: 'Credential ID',
                    hint: 'e.g. AWS-PSA-12345 (Optional)',
                    controller: _credIdCtrl,
                    maxLength: 50,
                    inputFormatters: [ResumeInputScrubber.titleFormatter()],
                    textInputAction: TextInputAction.next,
                  ),
                  const SizedBox(height: AppSpacing.md),

                  ValidatedFormField(
                    label: 'Credential URL',
                    hint: 'e.g. https://www.credly.com/badges/... (Optional)',
                    controller: _credUrlCtrl,
                    maxLength: 200,
                    keyboardType: TextInputType.url,
                    inputFormatters: [ResumeInputScrubber.urlFormatter()],
                    validator: _validateUrl,
                    textInputAction: TextInputAction.done,
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
                        text: isEditing ? 'Save Changes' : 'Add Certification',
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
