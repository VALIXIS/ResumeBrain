import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/custom_button.dart';

/// Lightweight error boundary widget for resume editor UI sections and tabs.
///
/// Catches unexpected rendering or runtime exceptions within a child subtree,
/// prevents the entire [ResumeEditorScreen] from crashing, and renders a safe,
/// accessible fallback card with retry capabilities without exposing stack traces
/// or sensitive resume data.
class ResumeErrorBoundary extends StatefulWidget {
  final Widget? child;
  final Widget Function(BuildContext context)? builder;
  final String sectionName;
  final VoidCallback? onRetry;
  final Widget Function(BuildContext context, VoidCallback onRetry)? customFallbackBuilder;

  const ResumeErrorBoundary({
    super.key,
    this.child,
    this.builder,
    this.sectionName = 'Resume Section',
    this.onRetry,
    this.customFallbackBuilder,
  }) : assert(child != null || builder != null, 'Either child or builder must be provided');

  @override
  State<ResumeErrorBoundary> createState() => _ResumeErrorBoundaryState();
}

class _ResumeErrorBoundaryState extends State<ResumeErrorBoundary> {
  Object? _error;

  @override
  void didUpdateWidget(covariant ResumeErrorBoundary oldWidget) {
    super.didUpdateWidget(oldWidget);
    if ((widget.child != oldWidget.child || widget.builder != oldWidget.builder) && _error != null) {
      setState(() => _error = null);
    }
  }

  void _handleRetry() {
    setState(() => _error = null);
    widget.onRetry?.call();
  }

  void _catchError(Object error) {
    // Log lightweight diagnostic info without sensitive resume text or stack traces
    final timestamp = DateTime.now().toIso8601String();
    debugPrint('[$timestamp] [RESUME_ERROR_BOUNDARY] Error in ${widget.sectionName}: ${error.runtimeType}');
    if (mounted) {
      setState(() => _error = error);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_error != null) {
      if (widget.customFallbackBuilder != null) {
        return widget.customFallbackBuilder!(context, _handleRetry);
      }
      return _buildDefaultFallback(context);
    }

    if (widget.builder != null) {
      try {
        return widget.builder!(context);
      } catch (e) {
        _catchError(e);
        return _buildDefaultFallback(context);
      }
    }

    return widget.child!;
  }

  Widget _buildDefaultFallback(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.accentOrange.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.warning_amber_rounded,
              size: 32,
              color: AppColors.accentOrange,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Unable to display ${widget.sectionName}',
            style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'A temporary display issue occurred in this section. Your resume data remains safely saved.',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            text: 'Retry Section',
            icon: Icons.refresh_rounded,
            isFullWidth: false,
            variant: AppButtonVariant.secondary,
            onPressed: _handleRetry,
          ),
        ],
      ),
    );
  }
}
