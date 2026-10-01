import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';

/// ValidatedFormField provides a standardized text input field for resume CRUD forms.
/// Supports real-time character counters, required field indicators, custom validators,
/// input scrubbing formatters, logical focus traversal, and automated keyboard auto-scrolling.
class ValidatedFormField extends StatefulWidget {
  final String label;
  final String? hint;
  final TextEditingController controller;
  final FocusNode? focusNode;
  final String? Function(String?)? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onFieldSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final TextInputType keyboardType;
  final TextInputAction textInputAction;
  final int maxLines;
  final int? maxLength;
  final bool isRequired;
  final bool autoScrollOnFocus;
  final Widget? prefixIcon;
  final Widget? suffixIcon;

  const ValidatedFormField({
    super.key,
    required this.label,
    required this.controller,
    this.focusNode,
    this.hint,
    this.validator,
    this.onChanged,
    this.onFieldSubmitted,
    this.inputFormatters,
    this.keyboardType = TextInputType.text,
    this.textInputAction = TextInputAction.next,
    this.maxLines = 1,
    this.maxLength,
    this.isRequired = false,
    this.autoScrollOnFocus = true,
    this.prefixIcon,
    this.suffixIcon,
  });

  @override
  State<ValidatedFormField> createState() => _ValidatedFormFieldState();
}

class _ValidatedFormFieldState extends State<ValidatedFormField> {
  late int _charCount;
  FocusNode? _internalFocusNode;
  Timer? _scrollTimer;

  FocusNode get _effectiveFocusNode => widget.focusNode ?? (_internalFocusNode ??= FocusNode());

  @override
  void initState() {
    super.initState();
    _charCount = widget.controller.text.length;
    widget.controller.addListener(_updateCount);
    _effectiveFocusNode.addListener(_handleFocusChange);
  }

  @override
  void didUpdateWidget(covariant ValidatedFormField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.controller != oldWidget.controller) {
      oldWidget.controller.removeListener(_updateCount);
      _charCount = widget.controller.text.length;
      widget.controller.addListener(_updateCount);
    }
    if (widget.focusNode != oldWidget.focusNode) {
      (oldWidget.focusNode ?? _internalFocusNode)?.removeListener(_handleFocusChange);
      _effectiveFocusNode.addListener(_handleFocusChange);
    }
  }

  @override
  void dispose() {
    _scrollTimer?.cancel();
    widget.controller.removeListener(_updateCount);
    _effectiveFocusNode.removeListener(_handleFocusChange);
    _internalFocusNode?.dispose();
    super.dispose();
  }

  void _updateCount() {
    if (mounted && widget.maxLength != null) {
      setState(() {
        _charCount = widget.controller.text.length;
      });
    }
  }

  void _handleFocusChange() {
    if (widget.autoScrollOnFocus && _effectiveFocusNode.hasFocus && mounted) {
      _scrollTimer?.cancel();
      // Delay slightly to coordinate with mobile keyboard appearance
      _scrollTimer = Timer(const Duration(milliseconds: 100), () {
        if (mounted && _effectiveFocusNode.hasFocus) {
          Scrollable.ensureVisible(
            context,
            alignment: 0.35,
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
          );
        }
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentText = widget.controller.text;
    final String? rawErrorText = widget.validator != null ? widget.validator!(currentText) : null;
    final bool hasText = currentText.trim().isNotEmpty;
    final bool isValid = hasText && rawErrorText == null;
    final bool hasError = rawErrorText != null && (hasText || _effectiveFocusNode.hasFocus);

    // Build humanized validation icon for suffix slot
    Widget? validationIcon = widget.suffixIcon;
    if (validationIcon == null) {
      if (isValid) {
        validationIcon = const Padding(
          padding: EdgeInsets.only(right: 12),
          child: Icon(Icons.check_circle_rounded, color: AppColors.accentTeal, size: 20),
        );
      } else if (hasError) {
        validationIcon = const Padding(
          padding: EdgeInsets.only(right: 12),
          child: Icon(Icons.error_outline_rounded, color: AppColors.accentRed, size: 20),
        );
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.label.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Row(
                  children: [
                    Flexible(
                      child: Text(
                        widget.label,
                        style: AppTypography.labelLarge.copyWith(
                          color: _effectiveFocusNode.hasFocus ? AppColors.primary : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (widget.isRequired) ...[
                      const SizedBox(width: 4),
                      const Text(
                        '*',
                        style: TextStyle(
                          color: AppColors.accentRed,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 8),
              // Real-time Character Counter Pill Badge
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: widget.maxLength != null && _charCount > widget.maxLength!
                      ? AppColors.accentRed.withValues(alpha: 0.15)
                      : _effectiveFocusNode.hasFocus
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : AppColors.surfaceBorder.withValues(alpha: 0.5),
                  borderRadius: AppRadius.borderSm,
                  border: Border.all(
                    color: _effectiveFocusNode.hasFocus
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : Colors.transparent,
                  ),
                ),
                child: Text(
                  widget.maxLength != null
                      ? '$_charCount / ${widget.maxLength}'
                      : '$_charCount chars',
                  style: AppTypography.bodySmall.copyWith(
                    color: widget.maxLength != null && _charCount > widget.maxLength!
                        ? AppColors.accentRed
                        : _effectiveFocusNode.hasFocus
                            ? AppColors.primary
                            : AppColors.textMuted,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
        ],
        TextFormField(
          controller: widget.controller,
          focusNode: _effectiveFocusNode,
          inputFormatters: widget.inputFormatters,
          maxLines: widget.maxLines,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          validator: widget.validator,
          onChanged: widget.onChanged,
          onFieldSubmitted: (value) {
            if (widget.onFieldSubmitted != null) {
              widget.onFieldSubmitted!(value);
            } else if (widget.textInputAction == TextInputAction.next) {
              FocusScope.of(context).nextFocus();
            }
          },
          style: AppTypography.bodyLarge.copyWith(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: widget.hint,
            hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
            prefixIcon: widget.prefixIcon,
            suffixIcon: validationIcon,
            suffixIconConstraints: const BoxConstraints(minWidth: 40, minHeight: 40),
            filled: true,
            fillColor: _effectiveFocusNode.hasFocus
                ? AppColors.surfaceLight
                : AppColors.surfaceLight.withValues(alpha: 0.7),
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
              borderSide: BorderSide(
                color: isValid
                    ? AppColors.accentTeal.withValues(alpha: 0.5)
                    : AppColors.surfaceBorder,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: AppRadius.borderMd,
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: AppRadius.borderMd,
              borderSide: const BorderSide(color: AppColors.accentRed),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: AppRadius.borderMd,
              borderSide: const BorderSide(color: AppColors.accentRed, width: 2),
            ),
            errorStyle: AppTypography.bodySmall.copyWith(
              color: AppColors.accentRed,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
            counterText: '', // Custom header counter rendered above
          ),
        ),
      ],
    );
  }
}
