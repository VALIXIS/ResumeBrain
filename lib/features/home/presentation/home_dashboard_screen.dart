import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/storage/storage_bootstrap.dart';
import '../../../core/storage/storage_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../../data/models/resume_models.dart';
import '../../ai/presentation/coming_soon_screen.dart';
import '../../analysis/presentation/analysis_results_screen.dart';
import '../../job_matching/presentation/job_description_input_screen.dart';
import '../../pdf/presentation/resume_preview_screen.dart';
import '../../resume/presentation/resume_editor_screen.dart';
import '../../templates/presentation/template_selector_screen.dart';

import '../../../core/widgets/theme_toggle_widget.dart';
import '../../../core/widgets/smooth_page_route.dart';
import '../../../core/widgets/app_shimmer.dart';
import '../../../core/widgets/shimmer_placeholders.dart';
import '../../../core/widgets/responsive_layout.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/app_bottom_sheet.dart';
import '../../../core/widgets/app_navigation_drawer.dart';

class HomeDashboardScreen extends ConsumerStatefulWidget {
  const HomeDashboardScreen({super.key});

  @override
  ConsumerState<HomeDashboardScreen> createState() => _HomeDashboardScreenState();
}

class _HomeDashboardScreenState extends ConsumerState<HomeDashboardScreen> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    StartupStages.logStage('HOME_BUILD_ENTER', 'HomeDashboardScreen build entered');
    final widget = LayoutBuilder(
      builder: (context, constraints) {
        final isDesktopOrTablet = constraints.maxWidth >= ResponsiveLayout.kMobileBreakpoint;

        if (isDesktopOrTablet) {
          return Scaffold(
            body: Row(
              children: [
                AppNavigationDrawer(
                  selectedIndex: _selectedIndex,
                  onDestinationSelected: (index) {
                    setState(() => _selectedIndex = index);
                  },
                  isPermanent: true,
                ),
                Expanded(
                  child: _buildCurrentTabContent(context),
                ),
              ],
            ),
          );
        }

        // Mobile Layout: Top AppBar, Bottom Navigation Bar, and Drawer
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
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.primary,
                        letterSpacing: 1.2,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            actions: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                child: IconButton(
                  icon: const Icon(Icons.info_outline_rounded),
                  tooltip: 'Quick Help & Info',
                  onPressed: () => _showQuickHelpBottomSheet(context),
                ),
              ),
              const ThemeToggleWidget(),
              const SizedBox(width: 8),
            ],
          ),
          drawer: AppNavigationDrawer(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            isPermanent: false,
          ),
          body: _buildCurrentTabContent(context),
          bottomNavigationBar: NavigationBar(
            selectedIndex: _selectedIndex,
            onDestinationSelected: (index) {
              setState(() => _selectedIndex = index);
            },
            destinations: AppNavigationDrawer.destinations.map((item) {
              return NavigationDestination(
                icon: Icon(item.icon),
                selectedIcon: Icon(item.selectedIcon, color: AppColors.primary),
                label: item.label,
                tooltip: item.tooltip,
              );
            }).toList(),
          ),
        );
      },
    );
    StartupStages.logStage('HOME_BUILD_EXIT', 'HomeDashboardScreen build exited');
    return widget;
  }

  Widget _buildCurrentTabContent(BuildContext context) {
    switch (_selectedIndex) {
      case 1:
        return const AnalysisResultsScreen();
      case 2:
        return const JobDescriptionInputScreen();
      case 3:
        return const TemplateSelectorScreen();
      case 0:
      default:
        return _buildDashboardView(context);
    }
  }

  Widget _buildDashboardView(BuildContext context) {
    StartupStages.logStage(StartupStages.stage7HomeRender, 'Rendering HomeDashboardScreen view');
    final storageStatus = ref.watch(storageBootstrapProvider);

    if (storageStatus == StorageStatus.initializing || storageStatus == StorageStatus.uninitialized) {
      return _buildLoadingShimmer();
    }

    if (storageStatus == StorageStatus.error) {
      return SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeroCard(context, ref),
            const SizedBox(height: AppSpacing.xl),
            ErrorStateWidget(
              errorMessage: 'Storage initialized with fallback. Tap Retry to reconnect storage.',
              onRetry: () => ref.read(storageBootstrapProvider.notifier).retry(),
            ),
            const SizedBox(height: AppSpacing.xl),
            _buildAiSuiteSection(context),
          ],
        ),
      );
    }

    final resumesAsync = ref.watch(resumesListProvider);

    return resumesAsync.when(
      loading: () => _buildLoadingShimmer(),
      error: (err, stack) => ErrorStateWidget(
        errorMessage: err.toString(),
        onRetry: () => ref.read(resumesListProvider.notifier).loadResumes(),
      ),
      data: (resumes) => ResponsiveLayout(
        mobile: _buildMobileLayout(context, ref, resumes),
        tablet: _buildTabletDesktopLayout(context, ref, resumes, gap: AppSpacing.lg),
        desktop: _buildTabletDesktopLayout(context, ref, resumes, gap: AppSpacing.xl),
      ),
    );
  }

  // Layout Builders
  Widget _buildMobileLayout(BuildContext context, WidgetRef ref, List<Resume> resumes) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroCard(context, ref),
          const SizedBox(height: AppSpacing.xl),
          _buildResumesSection(context, ref, resumes),
          const SizedBox(height: AppSpacing.xl),
          _buildAiSuiteSection(context),
        ],
      ),
    );
  }

  Widget _buildTabletDesktopLayout(
    BuildContext context,
    WidgetRef ref,
    List<Resume> resumes, {
    required double gap,
  }) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Primary Pane (Left)
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroCard(context, ref),
                const SizedBox(height: AppSpacing.xl),
                _buildResumesSection(context, ref, resumes),
              ],
            ),
          ),
          SizedBox(width: gap),
          // Secondary Pane (Right)
          Expanded(
            flex: 2,
            child: _buildAiSuiteSection(context),
          ),
        ],
      ),
    );
  }

  // Component Helpers
  Widget _buildHeroCard(BuildContext context, WidgetRef ref) {
    return AppCard(
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
    );
  }

  Widget _buildResumesSection(BuildContext context, WidgetRef ref, List<Resume> resumes) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
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
      ],
    );
  }

  Widget _buildAiSuiteSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Resume Intelligence Suite', style: AppTypography.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Next-generation career tools powered by AI.',
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        _buildAiFeatureCard(
          context,
          title: 'AI Resume Analysis & ATS Score',
          description: 'Get deep feedback, keyword checks, and structural score.',
          icon: Icons.analytics_outlined,
          accentColor: AppColors.accentTeal,
          onTap: () => setState(() => _selectedIndex = 1),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildAiFeatureCard(
          context,
          title: 'Job Match & Resume Tailoring',
          description: 'Match your resume against job postings and auto-tailor bullet points.',
          icon: Icons.work_outline_rounded,
          accentColor: AppColors.accentPurple,
          onTap: () => setState(() => _selectedIndex = 2),
        ),
      ],
    );
  }

  Widget _buildResumeCard(BuildContext context, WidgetRef ref, Resume resume) {
    final dateFormat = DateFormat('MMM d, yyyy');

    return AppCard(
      onTap: () {
        ref.read(currentResumeProvider.notifier).setResume(resume);
        Navigator.push(
          context,
          SmoothPageRoute(page: const ResumeEditorScreen()),
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
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                child: PopupMenuButton<String>(
                  tooltip: 'Options for ${resume.title}',
                  icon: const Icon(Icons.more_vert_rounded, color: AppColors.textMuted),
                  color: AppColors.surfaceLight,
                  onSelected: (value) async {
                    if (value == 'edit') {
                      ref.read(currentResumeProvider.notifier).setResume(resume);
                      Navigator.push(
                        context,
                        SmoothPageRoute(page: const ResumeEditorScreen()),
                      );
                    } else if (value == 'preview') {
                      ref.read(currentResumeProvider.notifier).setResume(resume);
                      Navigator.push(
                        context,
                        SmoothPageRoute(page: const ResumePreviewScreen()),
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

  Widget _buildAiFeatureCard(
    BuildContext context, {
    required String title,
    required String description,
    required IconData icon,
    required Color accentColor,
    VoidCallback? onTap,
  }) {
    return AppCard(
      color: AppColors.surface.withValues(alpha: 0.6),
      onTap: onTap ??
          () {
            Navigator.push(
              context,
              SmoothPageRoute(
                page: ComingSoonScreen(featureTitle: title),
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
                        color: accentColor.withValues(alpha: 0.2),
                        borderRadius: AppRadius.borderSm,
                      ),
                      child: Text(
                        'AI LIVE',
                        style: AppTypography.labelSmall.copyWith(
                          fontSize: 9,
                          color: accentColor,
                          fontWeight: FontWeight.bold,
                        ),
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

  // Shimmer loading helper
  Widget _buildLoadingShimmer() {
    return ResponsiveLayout(
      mobile: _buildMobileShimmer(),
      tablet: _buildTabletDesktopShimmer(gap: AppSpacing.lg),
      desktop: _buildTabletDesktopShimmer(gap: AppSpacing.xl),
    );
  }

  Widget _buildMobileShimmer() {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeroShimmer(),
          const SizedBox(height: AppSpacing.xl),
          _buildResumesShimmer(),
          const SizedBox(height: AppSpacing.xl),
          _buildAiSuiteShimmer(),
        ],
      ),
    );
  }

  Widget _buildTabletDesktopShimmer({required double gap}) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroShimmer(),
                const SizedBox(height: AppSpacing.xl),
                _buildResumesShimmer(),
              ],
            ),
          ),
          SizedBox(width: gap),
          Expanded(
            flex: 2,
            child: _buildAiSuiteShimmer(),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroShimmer() {
    return AppCard(
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
          const AppButton(
            text: 'Create New Resume',
            icon: Icons.add_rounded,
            variant: AppButtonVariant.primary,
            onPressed: null,
          ),
        ],
      ),
    );
  }

  Widget _buildResumesShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('My Resumes', style: AppTypography.titleLarge),
            const AppShimmer(width: 50, height: 14),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        const ListRowShimmer(),
        const SizedBox(height: AppSpacing.md),
        const ListRowShimmer(),
      ],
    );
  }

  Widget _buildAiSuiteShimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Resume Intelligence Suite', style: AppTypography.titleLarge),
        const SizedBox(height: AppSpacing.xs),
        Text(
          'Next-generation career tools powered by AI.',
          style: AppTypography.bodySmall,
        ),
        const SizedBox(height: AppSpacing.md),
        const DashboardCardShimmer(),
        const SizedBox(height: AppSpacing.md),
        const DashboardCardShimmer(),
      ],
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
      SmoothPageRoute(page: const ResumeEditorScreen()),
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
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            child: TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ),
          ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
            child: TextButton(
              onPressed: () {
                ref.read(resumesListProvider.notifier).deleteResume(resume.id);
                Navigator.pop(context);
                AppSnackBar.show(
                  context,
                  message: 'Deleted "${resume.title}"',
                  variant: AppSnackBarVariant.info,
                  actionLabel: 'Undo',
                  onAction: () {
                    ref.read(resumesListProvider.notifier).saveResume(resume);
                  },
                );
              },
              child: const Text('Delete', style: TextStyle(color: AppColors.accentRed)),
            ),
          ),
        ],
      ),
    );
  }

  void _showQuickHelpBottomSheet(BuildContext context) {
    AppBottomSheet.show(
      context: context,
      title: 'Resume Brain Guide',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'How to get started',
            style: AppTypography.titleMedium,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            '1. Tap "Create New Resume" to start building with structured sections.\n'
            '2. Tailor your resume against target job descriptions in the Job Match tab.\n'
            '3. Run ATS Analysis to check your score and get actionable feedback.\n'
            '4. Choose from professional ATS templates and export to PDF.',
            style: AppTypography.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            text: 'Got it',
            variant: AppButtonVariant.primary,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}
