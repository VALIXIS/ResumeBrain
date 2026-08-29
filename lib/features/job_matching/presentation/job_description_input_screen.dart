import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../controllers/job_matching_controller.dart';

import 'job_match_results_screen.dart';

class JobDescriptionInputScreen extends ConsumerStatefulWidget {
  final VoidCallback? onSuccess;

  const JobDescriptionInputScreen({
    super.key,
    this.onSuccess,
  });

  @override
  ConsumerState<JobDescriptionInputScreen> createState() =>
      _JobDescriptionInputScreenState();
}

class _JobDescriptionInputScreenState extends ConsumerState<JobDescriptionInputScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _textController;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController();
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState?.validate() ?? false) {
      await ref
          .read(jobMatchingControllerProvider.notifier)
          .submitJobDescription(_textController.text);
      
      final state = ref.read(jobMatchingControllerProvider);
      if (state.error == null && mounted) {
        if (widget.onSuccess != null) {
          widget.onSuccess!.call();
        } else {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const JobMatchResultsScreen(),
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(jobMatchingControllerProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Job Description Match'),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Enter Job Details',
                style: AppTypography.titleLarge.copyWith(color: AppColors.textPrimary),
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Paste the target job description to match and tailor your resume.',
                style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted),
              ),
              const SizedBox(height: AppSpacing.lg),
              AppTextField(
                label: 'Job Description',
                hint: 'Paste the job description here...',
                controller: _textController,
                maxLines: 8,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Job description cannot be empty';
                  }
                  return null;
                },
              ),
              const SizedBox(height: AppSpacing.xl),
              if (state.error != null) ...[
                Text(
                  state.error!,
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.accentRed),
                ),
                const SizedBox(height: AppSpacing.md),
              ],
              if (state.currentJob != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    border: Border.all(color: AppColors.primary),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: AppColors.primary),
                      const SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Text(
                          'Successfully matched with: ${state.currentJob!.title}',
                          style: AppTypography.bodyMedium.copyWith(color: AppColors.textPrimary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.xl),
              ],
              AppButton(
                text: 'Submit Description',
                isLoading: state.isLoading,
                onPressed: state.isLoading ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
