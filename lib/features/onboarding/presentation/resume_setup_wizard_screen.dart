import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/smooth_page_route.dart';
import '../../../data/models/resume_models.dart';
import '../../home/presentation/home_dashboard_screen.dart';
import '../../pdf/presentation/resume_preview_screen.dart';

class ResumeSetupWizardScreen extends ConsumerStatefulWidget {
  const ResumeSetupWizardScreen({super.key});

  @override
  ConsumerState<ResumeSetupWizardScreen> createState() => _ResumeSetupWizardScreenState();
}

class _ResumeSetupWizardScreenState extends ConsumerState<ResumeSetupWizardScreen> {
  final PageController _pageController = PageController();
  int _currentStep = 0;

  // Form Controllers - Personal Info
  final _fullNameController = TextEditingController();
  final _jobTitleController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _locationController = TextEditingController();

  // Form Controllers - Summary
  final _summaryController = TextEditingController();

  // Form Controllers - Work Experience
  final _companyController = TextEditingController();
  final _positionController = TextEditingController();
  final _expDescController = TextEditingController();

  // Form Controllers - Education & Skills
  final _schoolController = TextEditingController();
  final _degreeController = TextEditingController();
  final _skillsController = TextEditingController(text: 'Flutter, Dart, Mobile Development, REST APIs');

  bool _isAiEnhancing = false;

  void _nextStep() {
    if (_currentStep < 4) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finishWizard();
    }
  }

  void _previousStep() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _aiEnhanceSummary() async {
    final title = _jobTitleController.text.trim();
    if (title.isEmpty) {
      AppSnackBar.showError(context, 'Please enter a Target Job Title first.');
      return;
    }

    setState(() => _isAiEnhancing = true);

    try {
      final aiService = ref.read(aiServiceProvider);
      final response = await aiService.improveText(
        _summaryController.text.isNotEmpty ? _summaryController.text : 'Seeking a position as $title.',
        'Summary',
      );

      if (mounted) {
        setState(() {
          _isAiEnhancing = false;
          if (response.isSuccess && response.outputText.isNotEmpty) {
            _summaryController.text = response.outputText;
            AppSnackBar.showSuccess(context, 'AI enhanced your professional summary!');
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isAiEnhancing = false);
        AppSnackBar.showError(context, 'AI enhancement error: $e');
      }
    }
  }

  void _finishWizard() {
    final rawSkills = _skillsController.text
        .split(',')
        .map((s) => s.trim())
        .where((s) => s.isNotEmpty)
        .toList();

    final newResume = Resume(
      title: '${_fullNameController.text.isNotEmpty ? _fullNameController.text : "My"} Resume',
      personalInfo: PersonalInformation(
        fullName: _fullNameController.text.trim(),
        jobTitle: _jobTitleController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        location: _locationController.text.trim(),
      ),
      summary: ProfessionalSummary(
        summaryText: _summaryController.text.trim(),
      ),
      experiences: [
        if (_companyController.text.isNotEmpty || _positionController.text.isNotEmpty)
          Experience(
            company: _companyController.text.trim(),
            position: _positionController.text.trim(),
            description: _expDescController.text.trim(),
          ),
      ],
      educationList: [
        if (_schoolController.text.isNotEmpty || _degreeController.text.isNotEmpty)
          Education(
            institution: _schoolController.text.trim(),
            degree: _degreeController.text.trim(),
          ),
      ],
      skills: rawSkills.map((name) => Skill(name: name, level: 'Intermediate')).toList(),
    );

    ref.read(currentResumeProvider.notifier).setResume(newResume);
    ref.read(resumesListProvider.notifier).saveResume(newResume);

    AppSnackBar.showSuccess(context, 'Resume created successfully! Opening preview.');

    Navigator.of(context).pushAndRemoveUntil(
      SmoothPageRoute(page: const HomeDashboardScreen()),
      (route) => false,
    );
    Navigator.of(context).push(
      SmoothPageRoute(page: const ResumePreviewScreen()),
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    _fullNameController.dispose();
    _jobTitleController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _summaryController.dispose();
    _companyController.dispose();
    _positionController.dispose();
    _expDescController.dispose();
    _schoolController.dispose();
    _degreeController.dispose();
    _skillsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Exit to Dashboard',
          onPressed: () {
            Navigator.of(context).pushAndRemoveUntil(
              SmoothPageRoute(page: const HomeDashboardScreen()),
              (route) => false,
            );
          },
        ),
        title: const Text('Guided Resume Setup Wizard'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(6),
          child: LinearProgressIndicator(
            value: (_currentStep + 1) / 5,
            backgroundColor: AppColors.surfaceBorder,
            valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (idx) => setState(() => _currentStep = idx),
              physics: const NeverScrollableScrollPhysics(), // Wizard driven via buttons
              children: [
                _buildStep1PersonalInfo(),
                _buildStep2Summary(),
                _buildStep3Experience(),
                _buildStep4EducationSkills(),
                _buildStep5Review(),
              ],
            ),
          ),
          _buildBottomNavigation(),
        ],
      ),
    );
  }

  Widget _buildStep1PersonalInfo() {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 1: Contact Information', style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Recruiters and ATS systems need your basic contact details to reach you.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _fullNameController,
            label: 'Full Name *',
            hint: 'e.g., Alex Morgan',
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _jobTitleController,
            label: 'Target Job Title *',
            hint: 'e.g., Senior Full Stack Developer',
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _emailController,
            label: 'Email Address *',
            hint: 'alex.morgan@example.com',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _phoneController,
            label: 'Phone Number',
            hint: '+1 (555) 019-2834',
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _locationController,
            label: 'Location (City, Country)',
            hint: 'San Francisco, CA',
          ),
        ],
      ),
    );
  }

  Widget _buildStep2Summary() {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 2: Professional Summary', style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'A 2-3 sentence elevator pitch summarizing your key skills and achievements.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _summaryController,
            label: 'Professional Summary',
            hint: 'Write a short overview or tap AI Enhance to auto-generate...',
            maxLines: 5,
            onAiEnhance: _aiEnhanceSummary,
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            text: _isAiEnhancing ? 'Generating with AI...' : '✨ Generate AI Professional Summary',
            isLoading: _isAiEnhancing,
            variant: AppButtonVariant.ai,
            isFullWidth: true,
            onPressed: _aiEnhanceSummary,
          ),
        ],
      ),
    );
  }

  Widget _buildStep3Experience() {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 3: Recent Work Experience', style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Add your most recent role. You can add additional history in the full editor.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _companyController,
            label: 'Company Name',
            hint: 'e.g., Google Inc.',
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _positionController,
            label: 'Job Title / Position',
            hint: 'e.g., Software Engineer',
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _expDescController,
            label: 'Key Responsibilities & Impact',
            hint: 'Achieved 35% reduction in latency by refactoring backend services...',
            maxLines: 4,
          ),
        ],
      ),
    );
  }

  Widget _buildStep4EducationSkills() {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Step 4: Education & Skills', style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Highlight your educational background and primary technical skills.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.lg),
          AppTextField(
            controller: _schoolController,
            label: 'University / Institution',
            hint: 'e.g., Stanford University',
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _degreeController,
            label: 'Degree & Major',
            hint: 'e.g., B.S. in Computer Science',
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            controller: _skillsController,
            label: 'Skills (Comma separated)',
            hint: 'Flutter, Python, PostgreSQL, AWS',
            maxLines: 3,
          ),
        ],
      ),
    );
  }

  Widget _buildStep5Review() {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.accentTeal.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded, size: 56, color: AppColors.accentTeal),
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Center(
            child: Text(
              'Your Resume is Ready!',
              style: AppTypography.displayMedium,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Center(
            child: Text(
              'We will assemble your data into an ATS-optimized PDF template instantly.',
              style: AppTypography.bodySmall,
              textAlign: TextAlign.center,
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _fullNameController.text.isNotEmpty ? _fullNameController.text : 'Alex Morgan',
                  style: AppTypography.titleMedium,
                ),
                Text(
                  _jobTitleController.text.isNotEmpty ? _jobTitleController.text : 'Software Engineer',
                  style: AppTypography.bodySmall,
                ),
                const Divider(),
                Text(
                  'Email: ${_emailController.text.isNotEmpty ? _emailController.text : "Not provided"}',
                  style: AppTypography.bodySmall,
                ),
                Text(
                  'Skills: ${_skillsController.text}',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation() {
    return Container(
      padding: AppSpacing.screenPadding,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: Row(
        children: [
          if (_currentStep > 0)
            Expanded(
              child: AppButton(
                text: 'Back',
                variant: AppButtonVariant.outline,
                onPressed: _previousStep,
              ),
            ),
          if (_currentStep > 0) const SizedBox(width: AppSpacing.md),
          Expanded(
            child: AppButton(
              text: _currentStep == 4 ? 'Build PDF Resume' : 'Continue',
              onPressed: _nextStep,
            ),
          ),
        ],
      ),
    );
  }
}
