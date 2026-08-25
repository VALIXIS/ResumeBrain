import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../../data/models/resume_models.dart';
import '../../ai/presentation/coming_soon_screen.dart';
import '../../pdf/presentation/resume_preview_screen.dart';
import '../../resume/presentation/resume_editor_screen.dart';

class HomeDashboardScreen extends ConsumerWidget {
  const HomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resumesAsync = ref.watch(resumesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: AppRadius.borderSm,
              ),
              child: const Icon(Icons.psychology, size: 20, color: Colors.white),
            ),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(AppConstants.appName, style: AppTypography.titleLarge),
                Text(
                  'BY ${AppConstants.companyName}',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.primary, letterSpacing: 1.2),
                ),
              ],
            ),
          ],
        ),
      ),
      body: resumesAsync.when(
        loading: () => const LoadingStateWidget(message: 'Loading your career workspace...'),
        error: (err, stack) => ErrorStateWidget(
          errorMessage: err.toString(),
          onRetry: () => ref.read(resumesListProvider.notifier).loadResumes(),
        ),
        data: (resumes) => SingleChildScrollView(
          padding: AppSpacing.screenPadding,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Hero Banner / Create CTA Card
              AppCard(
                color: AppColors.surface,
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.3), width: 1.5),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.auto_awesome, color: AppColors.accentPurple, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'VALIXIS CAREER ENGINE',
                          style: AppTypography.labelSmall.copyWith(color: AppColors.accentPurple),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Build ATS-Ready Resumes in Minutes',
                      style: AppTypography.displayMedium.copyWith(fontSize: 20),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Create, format, and export high-impact professional resumes optimized for recruiters.',
                      style: AppTypography.bodyMedium,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      text: 'Create New Resume',
                      icon: Icons.add_rounded,
                      variant: AppButtonVariant.primary,
                      onPressed: () => _createNewResume(context, ref),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppSpacing.xl),

              // Recent / Saved Resumes Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('My Resumes', style: AppTypography.titleLarge),
                  Text('${resumes.length} saved', style: AppTypography.bodySmall),
                ],
              ),
              const SizedBox(height: AppSpacing.md),

              if (resumes.isEmpty)
                EmptyStateWidget(
                  title: 'No Resumes Yet',
                  description: 'Create your first resume to kickstart your career journey with Resume Brain.',
                  actionText: 'Create Resume Now',
                  onAction: () => _createNewResume(context, ref),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: resumes.length,
                  separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
                  itemBuilder: (context, index) {
                    final resume = resumes[index];
                    return _buildResumeCard(context, ref, resume);
                  },
                ),

              const SizedBox(height: AppSpacing.xl),

              // Future AI Expansion Modules (Disabled / Coming Soon)
              Text('Resume Intelligence Suite', style: AppTypography.titleLarge),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'Next-generation career tools powered by AI.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: AppSpacing.md),

              _buildComingSoonFeatureCard(
                context,
                title: 'AI Resume Analysis & ATS Score',
                description: 'Get deep feedback, keyword checks, and structural score.',
                icon: Icons.analytics_outlined,
                accentColor: AppColors.accentTeal,
              ),
              const SizedBox(height: AppSpacing.md),
              _buildComingSoonFeatureCard(
                context,
                title: 'Job Match & Resume Tailoring',
                description: 'Match your resume against job postings and auto-tailor bullet points.',
                icon: Icons.work_outline_rounded,
                accentColor: AppColors.accentPurple,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResumeCard(BuildContext context, WidgetRef ref, Resume resume) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return AppCard(
      onTap: () {
        ref.read(currentResumeProvider.notifier).setResume(resume);
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => const ResumeEditorScreen()),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resume.title.isNotEmpty ? resume.title : 'Untitled Resume',
                      style: AppTypography.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (resume.personalInfo.fullName.isNotEmpty)
                      Text(
                        '${resume.personalInfo.fullName} • ${resume.personalInfo.jobTitle}',
                        style: AppTypography.bodySmall,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted),
                color: AppColors.surfaceLight,
                onSelected: (value) async {
                  if (value == 'edit') {
                    ref.read(currentResumeProvider.notifier).setResume(resume);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ResumeEditorScreen()),
                    );
                  } else if (value == 'preview') {
                    ref.read(currentResumeProvider.notifier).setResume(resume);
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => const ResumePreviewScreen()),
                    );
                  } else if (value == 'delete') {
                    _confirmDelete(context, ref, resume);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(children: [Icon(Icons.edit_outlined, size: 18), SizedBox(width: 8), Text('Edit')]),
                  ),
                  const PopupMenuItem(
                    value: 'preview',
                    child: Row(children: [Icon(Icons.visibility_outlined, size: 18), SizedBox(width: 8), Text('Preview PDF')]),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(children: [Icon(Icons.delete_outline, size: 18, color: AppColors.accentRed), SizedBox(width: 8), Text('Delete', style: TextStyle(color: AppColors.accentRed))]),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.15),
                  borderRadius: AppRadius.borderSm,
                ),
                child: Text(
                  resume.templateId == 'modern_classic' ? 'Modern Classic' : 'Executive Minimal',
                  style: AppTypography.labelSmall.copyWith(color: AppColors.primary),
                ),
              ),
              const Spacer(),
              Text(
                'Updated ${dateFormat.format(resume.updatedAt)}',
                style: AppTypography.bodySmall,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildComingSoonFeatureCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color accentColor,
  }) {
    return AppCard(
      color: AppColors.surface.withValues(alpha: 0.6),
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ComingSoonScreen(featureTitle: title),
          ),
        );
      },
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: accentColor.withValues(alpha: 0.15),
              borderRadius: AppRadius.borderMd,
            ),
            child: Icon(icon, color: accentColor, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(title, style: AppTypography.titleMedium.copyWith(fontSize: 14)),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.surfaceBorder,
                        borderRadius: AppRadius.borderSm,
                      ),
                      child: Text(
                        'COMING SOON',
                        style: AppTypography.labelSmall.copyWith(fontSize: 9),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(description, style: AppTypography.bodySmall),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _createNewResume(BuildContext context, WidgetRef ref) {
    final newResume = Resume(
      title: 'New Resume ${DateFormat('MMM d').format(DateTime.now())}',
    );
    ref.read(currentResumeProvider.notifier).setResume(newResume);
    ref.read(resumesListProvider.notifier).saveResume(newResume);

    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ResumeEditorScreen()),
    );
  }

  void _confirmDelete(BuildContext context, WidgetRef ref, Resume resume) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Delete Resume'),
        content: Text('Are you sure you want to delete "${resume.title}"? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(resumesListProvider.notifier).deleteResume(resume.id);
              Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: AppColors.accentRed)),
          ),
        ],
      ),
    );
  }
}
