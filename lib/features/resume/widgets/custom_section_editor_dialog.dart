import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../data/models/resume_models.dart';
import '../utils/resume_input_scrubber.dart';
import 'resume_validators.dart';
import 'validated_form_field.dart';

/// Predefined section preset metadata for fast creation.
class CustomSectionPreset {
  final String label;
  final String defaultTitle;
  final IconData icon;

  const CustomSectionPreset({
    required this.label,
    required this.defaultTitle,
    required this.icon,
  });
}

/// Available predefined custom-section presets.
const List<CustomSectionPreset> kPredefinedSectionPresets = [
  CustomSectionPreset(
    label: 'Publications',
    defaultTitle: 'Publications & Research',
    icon: Icons.menu_book_outlined,
  ),
  CustomSectionPreset(
    label: 'Volunteer',
    defaultTitle: 'Volunteer Experience',
    icon: Icons.volunteer_activism_outlined,
  ),
  CustomSectionPreset(
    label: 'Awards',
    defaultTitle: 'Awards & Honors',
    icon: Icons.emoji_events_outlined,
  ),
  CustomSectionPreset(
    label: 'Custom',
    defaultTitle: '',
    icon: Icons.edit_note_outlined,
  ),
];

/// CustomSectionEditorDialog provides a production-ready modal dialog for creating and editing
/// arbitrary custom resume sections (Publications, Volunteer, Awards, or user-defined titles)
/// with independently editable bullet points, real-time validation, and dynamic item management.
class CustomSectionEditorDialog extends StatefulWidget {
  final CustomSection? section;
  final List<String> existingTitles;
  final String? initialPresetTitle;
  final ValueChanged<CustomSection> onSave;

  const CustomSectionEditorDialog({
    super.key,
    this.section,
    this.existingTitles = const [],
    this.initialPresetTitle,
    required this.onSave,
  });

  static Future<void> show({
    required BuildContext context,
    CustomSection? section,
    List<String> existingTitles = const [],
    String? initialPresetTitle,
    required ValueChanged<CustomSection> onSave,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => CustomSectionEditorDialog(
        section: section,
        existingTitles: existingTitles,
        initialPresetTitle: initialPresetTitle,
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
  final List<TextEditingController> _bulletControllers = [];
  final List<FocusNode> _bulletFocusNodes = [];
  String? _selectedPresetLabel;

  @override
  void initState() {
    super.initState();
    final sec = widget.section;
    final initialTitle = sec?.title ?? widget.initialPresetTitle ?? '';
    _titleCtrl = TextEditingController(text: initialTitle);

    // Identify active preset if title matches a known preset
    _matchActivePreset(initialTitle);

    if (sec != null && sec.items.isNotEmpty) {
      for (final item in sec.items) {
        _bulletControllers.add(TextEditingController(text: item));
        _bulletFocusNodes.add(FocusNode());
      }
    } else {
      // Start with one empty bullet item for convenient entry
      _bulletControllers.add(TextEditingController());
      _bulletFocusNodes.add(FocusNode());
    }
  }

  void _matchActivePreset(String title) {
    final trimmed = title.trim().toLowerCase();
    for (final preset in kPredefinedSectionPresets) {
      if (preset.label != 'Custom' &&
          preset.defaultTitle.trim().toLowerCase() == trimmed) {
        _selectedPresetLabel = preset.label;
        return;
      }
    }
    _selectedPresetLabel = 'Custom';
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    for (final ctrl in _bulletControllers) {
      ctrl.dispose();
    }
    for (final node in _bulletFocusNodes) {
      node.dispose();
    }
    super.dispose();
  }

  void _selectPreset(CustomSectionPreset preset) {
    setState(() {
      _selectedPresetLabel = preset.label;
      if (preset.defaultTitle.isNotEmpty) {
        _titleCtrl.text = preset.defaultTitle;
      }
    });
  }

  void _addBullet([String initialText = '']) {
    setState(() {
      final newNode = FocusNode();
      _bulletControllers.add(TextEditingController(text: initialText));
      _bulletFocusNodes.add(newNode);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (newNode.canRequestFocus) {
          newNode.requestFocus();
        }
      });
    });
  }

  void _removeBullet(int index) {
    if (index >= 0 && index < _bulletControllers.length) {
      setState(() {
        final ctrl = _bulletControllers.removeAt(index);
        final node = _bulletFocusNodes.removeAt(index);
        ctrl.dispose();
        node.dispose();
      });
    }
  }

  void _handleSave() {
    if (_formKey.currentState?.validate() ?? false) {
      final bulletList = _bulletControllers
          .map((ctrl) => ctrl.text.trim())
          .where((text) => text.isNotEmpty)
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
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 720),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(AppSpacing.lg, AppSpacing.lg, AppSpacing.sm, AppSpacing.sm),
              child: Row(
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
            ),
            const Divider(color: AppColors.surfaceBorder, height: 1),

            // Scrollable Content
            Flexible(
              child: FocusTraversalGroup(
                policy: ReadingOrderTraversalPolicy(),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Form(
                    key: _formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Section Type / Preset Chips
                        Text(
                          'Section Template / Preset',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: kPredefinedSectionPresets.map((preset) {
                            final isSelected = _selectedPresetLabel == preset.label;
                            return ChoiceChip(
                              avatar: Icon(
                                preset.icon,
                                size: 16,
                                color: isSelected ? Colors.white : AppColors.accentPurple,
                              ),
                              label: Text(preset.label),
                              selected: isSelected,
                              selectedColor: AppColors.accentPurple,
                              backgroundColor: AppColors.surfaceLight,
                              labelStyle: AppTypography.bodySmall.copyWith(
                                color: isSelected ? Colors.white : AppColors.textPrimary,
                                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              ),
                              onSelected: (_) => _selectPreset(preset),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Section Title Field
                        ValidatedFormField(
                          label: 'Section Title',
                          hint: 'e.g. Publications, Volunteer Experience, Awards & Honors',
                          controller: _titleCtrl,
                          maxLength: 80,
                          isRequired: true,
                          inputFormatters: [ResumeInputScrubber.titleFormatter()],
                          prefixIcon: const Icon(Icons.title, size: 20),
                          validator: (val) => ResumeValidators.validateSectionTitle(
                            val,
                            existingTitles: widget.existingTitles,
                            currentTitle: widget.section?.title,
                          ),
                          onChanged: (val) {
                            // Update active preset marker if title changed manually
                            _matchActivePreset(val);
                            setState(() {});
                          },
                        ),
                        const SizedBox(height: AppSpacing.lg),

                        // Bullet Points Section Header
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Bullet Points / Entries',
                                    style: AppTypography.titleMedium.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  Text(
                                    'Add independent bullet points describing your achievements.',
                                    style: AppTypography.bodySmall.copyWith(
                                      color: AppColors.textMuted,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            AppButton(
                              text: 'Add Bullet',
                              icon: Icons.add,
                              isFullWidth: false,
                              variant: AppButtonVariant.secondary,
                              onPressed: () => _addBullet(),
                            ),
                          ],
                        ),
                        const SizedBox(height: AppSpacing.md),

                        // Bullet Points List
                        if (_bulletControllers.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight.withValues(alpha: 0.5),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: AppColors.surfaceBorder),
                            ),
                            child: Column(
                              children: [
                                const Icon(
                                  Icons.format_list_bulleted,
                                  color: AppColors.textMuted,
                                  size: 28,
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  'No bullet points yet.',
                                  style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                                ),
                                const SizedBox(height: 8),
                                AppButton(
                                  text: 'Add First Bullet Point',
                                  icon: Icons.add,
                                  isFullWidth: false,
                                  variant: AppButtonVariant.primary,
                                  onPressed: () => _addBullet(),
                                ),
                              ],
                            ),
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _bulletControllers.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 10),
                            itemBuilder: (context, index) {
                              final ctrl = _bulletControllers[index];
                              final focusNode = _bulletFocusNodes[index];
                              return Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.only(top: 14, right: 8),
                                    child: Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: AppColors.accentPurple,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: TextFormField(
                                      controller: ctrl,
                                      focusNode: focusNode,
                                      inputFormatters: [ResumeInputScrubber.textBlockFormatter()],
                                      maxLines: null,
                                      minLines: 1,
                                      maxLength: 500,
                                      textInputAction: TextInputAction.next,
                                      onFieldSubmitted: (_) {
                                        if (index == _bulletControllers.length - 1) {
                                          _addBullet();
                                        } else {
                                          FocusScope.of(context).nextFocus();
                                        }
                                      },
                                      style: AppTypography.bodyMedium,
                                      decoration: InputDecoration(
                                        hintText: 'e.g. Published research on transformers in IEEE...',
                                        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
                                        filled: true,
                                        fillColor: AppColors.surfaceLight,
                                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: AppColors.surfaceBorder),
                                        ),
                                        enabledBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: AppColors.surfaceBorder),
                                        ),
                                        focusedBorder: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(8),
                                          borderSide: const BorderSide(color: AppColors.accentPurple, width: 1.5),
                                        ),
                                        counterText: '',
                                      ),
                                      validator: (val) => ResumeValidators.validateBulletPoint(val),
                                    ),
                                  ),
                                  const SizedBox(width: 6),
                                  Padding(
                                    padding: const EdgeInsets.only(top: 2),
                                    child: IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: AppColors.accentRed,
                                        size: 20,
                                      ),
                                      tooltip: 'Remove Bullet Point',
                                      onPressed: () => _removeBullet(index),
                                    ),
                                  ),
                                ],
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            // Footer / Action Buttons
            const Divider(color: AppColors.surfaceBorder, height: 1),
            Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      '${_bulletControllers.where((c) => c.text.trim().isNotEmpty).length} bullet points active',
                      style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Row(
                    mainAxisSize: MainAxisSize.min,
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
                        text: isEditing ? 'Save Changes' : 'Create Section',
                        icon: isEditing ? Icons.check : Icons.add,
                        isFullWidth: false,
                        onPressed: _handleSave,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
