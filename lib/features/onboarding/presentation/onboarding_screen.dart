import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/smooth_page_route.dart';
import '../../../data/models/resume_models.dart';
import '../../home/presentation/home_dashboard_screen.dart';
import 'resume_setup_wizard_screen.dart';

import '../../../core/storage/storage_bootstrap.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  final List<Map<String, dynamic>> _pages = [
    {
      'title': 'AI-Powered ATS Analysis',
      'description': 'Scan your resume against real applicant tracking system criteria and boost your score.',
      'icon': Icons.analytics_rounded,
      'color': AppColors.accentTeal,
    },
    {
      'title': 'Tailored Job Matching',
      'description': 'Paste target job descriptions to automatically rewrite and optimize your experience bullet points.',
      'icon': Icons.work_history_rounded,
      'color': AppColors.accentPurple,
    },
    {
      'title': 'Encrypted Cloud Backup',
      'description': 'Keep your data safe with hardware-backed AES-256 encryption and multi-device cloud synchronization.',
      'icon': Icons.security_rounded,
      'color': AppColors.primary,
    },
  ];

  Future<void> _startGuidedWizard() async {
    await StorageBootstrapService().setOnboardingCompleted(true);
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      SmoothPageRoute(page: const ResumeSetupWizardScreen()),
    );
  }

  Future<void> _finishOnboarding() async {
    await StorageBootstrapService().setOnboardingCompleted(true);
    // Seed a sample resume if resumes list is empty
    final resumes = ref.read(resumesListProvider).value ?? [];
    if (resumes.isEmpty) {
      final sampleResume = Resume(
        title: 'Software Engineer Resume (Sample)',
        personalInfo: PersonalInformation(
          fullName: 'Alex Morgan',
          email: 'alex.morgan@example.com',
          phone: '+1 (555) 234-5678',
          location: 'San Francisco, CA',
          jobTitle: 'Senior Full Stack Engineer',
        ),
        summary: ProfessionalSummary(
          summaryText: 'Results-driven Senior Full Stack Engineer with 6+ years of experience designing and scaling web and mobile systems.',
        ),
        skills: [
          Skill(name: 'Flutter / Dart', level: 'Expert'),
          Skill(name: 'TypeScript & Node.js', level: 'Advanced'),
          Skill(name: 'Supabase & PostgreSQL', level: 'Intermediate'),
          Skill(name: 'Docker & Kubernetes', level: 'Intermediate'),
        ],
      );
      await ref.read(resumesListProvider.notifier).saveResume(sampleResume);
      ref.read(currentResumeProvider.notifier).setResume(sampleResume);
    }

    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      SmoothPageRoute(page: const HomeDashboardScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: AppSpacing.screenPadding,
          child: Column(
            children: [
              Align(
                alignment: Alignment.topRight,
                child: TextButton(
                  onPressed: _finishOnboarding,
                  child: Text('Skip to Dashboard', style: AppTypography.bodyMedium.copyWith(color: AppColors.textMuted)),
                ),
              ),
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: (idx) => setState(() => _currentPage = idx),
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(32),
                          decoration: BoxDecoration(
                            color: (page['color'] as Color).withValues(alpha: 0.15),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(page['icon'] as IconData, size: 72, color: page['color'] as Color),
                        ),
                        const SizedBox(height: AppSpacing.xl),
                        Text(
                          page['title'] as String,
                          style: AppTypography.displayMedium,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppSpacing.md),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Text(
                            page['description'] as String,
                            style: AppTypography.bodyLarge,
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(
                  _pages.length,
                  (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 250),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    width: _currentPage == index ? 24 : 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: _currentPage == index ? AppColors.primary : AppColors.surfaceBorder,
                      borderRadius: AppRadius.borderSm,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                text: _currentPage == _pages.length - 1 ? '🚀 Start Guided Resume Setup' : 'Next',
                isFullWidth: true,
                onPressed: () {
                  if (_currentPage < _pages.length - 1) {
                    _pageController.nextPage(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeInOut,
                    );
                  } else {
                    _startGuidedWizard();
                  }
                },
              ),
              const SizedBox(height: AppSpacing.md),
            ],
          ),
        ),
      ),
    );
  }
}
