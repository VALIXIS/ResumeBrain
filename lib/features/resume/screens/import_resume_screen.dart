import 'dart:convert';
import 'dart:typed_data';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/smooth_page_route.dart';
import '../../../data/models/resume_models.dart';
import '../presentation/resume_editor_screen.dart';
import '../services/resume_parser_service.dart';

/// Screen for uploading, parsing, reviewing, and applying PDF resumes into Resume Brain.
class ImportResumeScreen extends ConsumerStatefulWidget {
  const ImportResumeScreen({super.key});

  @override
  ConsumerState<ImportResumeScreen> createState() => _ImportResumeScreenState();
}

enum _ImportStage { upload, parsing, review }

class _ImportResumeScreenState extends ConsumerState<ImportResumeScreen> with SingleTickerProviderStateMixin {
  _ImportStage _currentStage = _ImportStage.upload;
  String? _selectedFileName;
  ParsedResumeResult? _parsedResult;
  bool _isAiAssistedFallback = false;
  String _parsingStatusText = 'Extracting PDF text stream...';

  // Editable Form Controllers for Review Stage
  late TextEditingController _nameController;
  late TextEditingController _titleController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late TextEditingController _locationController;
  late TextEditingController _websiteController;
  late TextEditingController _summaryController;
  late TextEditingController _newSkillController;

  List<Experience> _experiences = [];
  List<Education> _educationList = [];
  List<Skill> _skills = [];
  List<Project> _projects = [];
  List<Certification> _certifications = [];
  List<Language> _languages = [];

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _nameController = TextEditingController();
    _titleController = TextEditingController();
    _emailController = TextEditingController();
    _phoneController = TextEditingController();
    _locationController = TextEditingController();
    _websiteController = TextEditingController();
    _summaryController = TextEditingController();
    _newSkillController = TextEditingController();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _titleController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _locationController.dispose();
    _websiteController.dispose();
    _summaryController.dispose();
    _newSkillController.dispose();
    super.dispose();
  }

  void _populateReviewControllers(Resume resume) {
    _nameController.text = resume.personalInfo.fullName;
    _titleController.text = resume.personalInfo.jobTitle;
    _emailController.text = resume.personalInfo.email;
    _phoneController.text = resume.personalInfo.phone;
    _locationController.text = resume.personalInfo.location;
    _websiteController.text = resume.personalInfo.website;
    _summaryController.text = resume.summary.summaryText;

    _experiences = List.from(resume.experiences);
    _educationList = List.from(resume.educationList);
    _skills = List.from(resume.skills);
    _projects = List.from(resume.projects);
    _certifications = List.from(resume.certifications);
    _languages = List.from(resume.languages);
  }

  Future<void> _pickAndParsePdf() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final file = result.files.first;
      final bytes = file.bytes;

      if (bytes == null || bytes.isEmpty) {
        if (mounted) {
          AppSnackBar.showError(context, 'Could not read PDF bytes from selected file.');
        }
        return;
      }

      setState(() {
        _selectedFileName = file.name;
        _currentStage = _ImportStage.parsing;
        _parsingStatusText = 'Decompressing PDF stream & reading text...';
      });

      final parser = ref.read(resumeParserServiceProvider);

      // Status animation tick
      await Future.delayed(const Duration(milliseconds: 300));
      if (mounted) {
        setState(() => _parsingStatusText = 'Extracting headers & matching section heuristics...');
      }

      final parsed = await parser.parsePdfBytes(
        bytes,
        enableAiFallback: true,
        preferredTitle: file.name.replaceAll(RegExp(r'\.pdf$', caseSensitive: false), ''),
      );

      if (mounted) {
        setState(() {
          _parsedResult = parsed;
          _isAiAssistedFallback = parsed.isAiAssisted;
          _populateReviewControllers(parsed.resume);
          _currentStage = _ImportStage.review;
        });
        AppSnackBar.showSuccess(
          context,
          'Successfully parsed resume in ${parsed.parsingDuration.inMilliseconds}ms!',
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _currentStage = _ImportStage.upload);
        AppSnackBar.showError(context, 'Failed to import PDF: $e');
      }
    }
  }

  void _parseSampleResume() async {
    setState(() {
      _selectedFileName = 'Sample_Resume_Hasitha.pdf';
      _currentStage = _ImportStage.parsing;
      _parsingStatusText = 'Simulating PDF text stream ingestion...';
    });

    await Future.delayed(const Duration(milliseconds: 600));

    const sampleText = '''
HASITHA SENEVIRATNE
Senior Mobile Systems Engineer | Flutter & Cloud Architect
hasitha.dev@example.com | +1 (555) 019-2834 | San Francisco, CA | linkedin.com/in/hasithadev

PROFESSIONAL SUMMARY
Results-driven Lead Mobile Engineer with 7+ years of experience engineering high-throughput Flutter applications, offline-first architectures, and scalable cloud microservices. Proven track record of boosting app performance and delivering resilient mobile products.

WORK EXPERIENCE
Lead Mobile Architect - Valixis Tech Corp
Jan 2022 - Present | San Francisco, CA
• Designed and shipped offline-first state synchronization engine serving 500k+ MAU with 99.98% crash-free sessions.
• Optimized Dart memory allocations and rendering pipeline, reducing frame drop by 42%.
• Mentored cross-functional team of 12 mobile engineers and standardized atomic design systems.

Senior Software Engineer - CloudMatrix Systems
Mar 2019 - Dec 2021 | Austin, TX
• Engineered reactive Flutter client connected to enterprise REST and GraphQL backend services.
• Implemented automated CI/CD deployment pipelines reducing release turnaround from 3 days to 40 minutes.
• Architected AES-256 encrypted local storage layer with biometric authentication support.

EDUCATION
Master of Science in Computer Science
Stanford University | 2017 - 2019 | GPA: 3.92

Bachelor of Science in Software Engineering
University of Texas at Austin | 2013 - 2017 | GPA: 3.85

CORE SKILLS & TECHNOLOGIES
Flutter, Dart, Riverpod, Clean Architecture, SQLite, Hive, REST APIs, GraphQL, Firebase, Docker, CI/CD, TypeScript, Git, Unit Testing, Performance Profiling

KEY PROJECTS
Resume Brain Mobile Engine
• Next-generation AI-powered career assistant with ATS optimization, real-time tailoring, and deterministic PDF export.

CERTIFICATIONS
Google Cloud Certified Professional Cloud Architect - 2023
AWS Certified Solutions Architect Associate - 2021

LANGUAGES
English (Native), Spanish (Conversational), German (Beginner)
''';

    // Simulate parser with sample raw text
    final bytes = Uint8List.fromList(utf8.encode(sampleText));
    final parser = ref.read(resumeParserServiceProvider);
    final parsed = await parser.parsePdfBytes(bytes, preferredTitle: 'Hasitha Seneviratne Resume');

    if (mounted) {
      setState(() {
        _parsedResult = parsed;
        _isAiAssistedFallback = false;
        _populateReviewControllers(parsed.resume);
        _currentStage = _ImportStage.review;
      });
      AppSnackBar.showSuccess(
        context,
        'Parsed sample resume in ${parsed.parsingDuration.inMilliseconds}ms!',
      );
    }
  }

  void _applyToActiveResume() async {
    final assembledResume = Resume(
      id: _parsedResult?.resume.id ?? const Uuid().v4(),
      title: _nameController.text.isNotEmpty
          ? '${_nameController.text.trim()} Resume'
          : 'Imported Resume',
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      templateId: 'modern_classic',
      personalInfo: PersonalInformation(
        fullName: _nameController.text.trim(),
        jobTitle: _titleController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        location: _locationController.text.trim(),
        website: _websiteController.text.trim(),
      ),
      summary: ProfessionalSummary(
        summaryText: _summaryController.text.trim(),
      ),
      experiences: _experiences,
      educationList: _educationList,
      skills: _skills,
      projects: _projects,
      certifications: _certifications,
      languages: _languages,
      socialLinks: _parsedResult?.resume.socialLinks ?? [],
    );

    // Save to repository and update active resume
    ref.read(currentResumeProvider.notifier).setResume(assembledResume);
    await ref.read(resumesListProvider.notifier).saveResume(assembledResume);

    if (mounted) {
      AppSnackBar.showSuccess(context, 'Resume imported & activated successfully!');
      Navigator.pushReplacement(
        context,
        SmoothPageRoute(page: const ResumeEditorScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resume Importer & PDF Parser'),
        actions: [
          if (_currentStage == _ImportStage.review)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              tooltip: 'Import Another PDF',
              onPressed: () => setState(() => _currentStage = _ImportStage.upload),
            ),
        ],
      ),
      body: SafeArea(
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 300),
          child: _buildStageContent(),
        ),
      ),
    );
  }

  Widget _buildStageContent() {
    switch (_currentStage) {
      case _ImportStage.upload:
        return _buildUploadStage();
      case _ImportStage.parsing:
        return _buildParsingStage();
      case _ImportStage.review:
        return _buildReviewStage();
    }
  }

  // ---------------------------------------------------------------------------
  // Stage 1: Upload Dropzone
  // ---------------------------------------------------------------------------

  Widget _buildUploadStage() {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildInfoBanner(),
          const SizedBox(height: AppSpacing.lg),
          _buildDropzoneCard(),
          const SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              const Expanded(child: Divider(color: AppColors.surfaceBorder)),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
                child: Text('OR', style: AppTypography.bodySmall),
              ),
              const Expanded(child: Divider(color: AppColors.surfaceBorder)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          AppButton(
            text: 'Load Sample PDF Resume',
            icon: Icons.auto_awesome,
            variant: AppButtonVariant.secondary,
            onPressed: _parseSampleResume,
          ),
          const SizedBox(height: AppSpacing.xl),
          _buildFeatureHighlights(),
        ],
      ),
    );
  }

  Widget _buildInfoBanner() {
    return AppCard(
      color: AppColors.surfaceLight,
      border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.15),
              borderRadius: AppRadius.borderSm,
            ),
            child: const Icon(Icons.flash_on_rounded, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Fast Sub-5s Extraction Engine', style: AppTypography.titleMedium),
                const SizedBox(height: 2),
                Text(
                  'Instantly map Experience, Education, Skills, and Contact Info into ATS-ready models.',
                  style: AppTypography.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDropzoneCard() {
    return InkWell(
      onTap: _pickAndParsePdf,
      borderRadius: AppRadius.borderLg,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: AppRadius.borderLg,
          border: Border.all(
            color: AppColors.primary.withValues(alpha: 0.6),
            width: 2,
          ),
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.cloud_upload_outlined, color: Colors.white, size: 36),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Select PDF Resume',
              style: AppTypography.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Tap to browse files from device (.pdf format)',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 240),
              child: AppButton(
                text: 'Browse Files',
                icon: Icons.folder_open_rounded,
                onPressed: _pickAndParsePdf,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureHighlights() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Supported Extraction Capabilities', style: AppTypography.titleMedium),
        const SizedBox(height: AppSpacing.sm),
        _buildHighlightItem(Icons.badge_outlined, 'Personal & Contact Information', 'Name, Job Title, Email, Phone, Location, Portfolio/LinkedIn'),
        _buildHighlightItem(Icons.work_history_outlined, 'Professional Experience & Bullets', 'Positions, Companies, Date ranges, and achievements'),
        _buildHighlightItem(Icons.school_outlined, 'Education & Academics', 'Institutions, Degrees, Majors, GPA, and Graduation dates'),
        _buildHighlightItem(Icons.psychology_outlined, 'Skills & Tech Stack', 'Automated tokenization and level classification'),
      ],
    );
  }

  Widget _buildHighlightItem(IconData icon, String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 20, color: AppColors.accentPurple),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppTypography.labelLarge.copyWith(fontSize: 13)),
                Text(subtitle, style: AppTypography.bodySmall.copyWith(fontSize: 11)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Stage 2: Live Progress Spinner
  // ---------------------------------------------------------------------------

  Widget _buildParsingStage() {
    return Center(
      child: Padding(
        padding: AppSpacing.screenPadding,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: AppColors.surface,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surfaceBorder),
              ),
              child: const CircularProgressIndicator(
                strokeWidth: 3.5,
                valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Text(
              'Parsing Resume PDF',
              style: AppTypography.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.xs),
            if (_selectedFileName != null)
              Text(
                _selectedFileName!,
                style: AppTypography.labelLarge.copyWith(color: AppColors.primary),
                textAlign: TextAlign.center,
              ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceLight,
                borderRadius: AppRadius.borderMd,
              ),
              child: Text(
                _parsingStatusText,
                style: AppTypography.bodyMedium,
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // Stage 3: Review & Edit Parsed Fields Screen
  // ---------------------------------------------------------------------------

  Widget _buildReviewStage() {
    return Column(
      children: [
        _buildReviewSummaryHeader(),
        TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textSecondary,
          indicatorColor: AppColors.primary,
          indicatorWeight: 3,
          tabs: [
            const Tab(text: 'Personal'),
            const Tab(text: 'Summary'),
            Tab(text: 'Experience (${_experiences.length})'),
            Tab(text: 'Education (${_educationList.length})'),
            Tab(text: 'Skills (${_skills.length})'),
          ],
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildPersonalTab(),
              _buildSummaryTab(),
              _buildExperienceTab(),
              _buildEducationTab(),
              _buildSkillsTab(),
            ],
          ),
        ),
        _buildBottomActionBar(),
      ],
    );
  }

  Widget _buildReviewSummaryHeader() {
    final conf = ((_parsedResult?.confidenceScore ?? 0.8) * 100).toInt();
    final duration = _parsedResult?.parsingDuration.inMilliseconds ?? 0;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.accentGreen.withValues(alpha: 0.15),
              borderRadius: AppRadius.borderSm,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.check_circle_outline, size: 14, color: AppColors.accentGreen),
                const SizedBox(width: 4),
                Text(
                  'Confidence $conf%',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.accentGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: AppRadius.borderSm,
            ),
            child: Text(
              '${duration}ms',
              style: AppTypography.labelSmall.copyWith(color: AppColors.textSecondary),
            ),
          ),
          if (_isAiAssistedFallback) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.accentPurple.withValues(alpha: 0.15),
                borderRadius: AppRadius.borderSm,
              ),
              child: Text(
                'AI Assisted',
                style: AppTypography.labelSmall.copyWith(color: AppColors.accentPurple),
              ),
            ),
          ],
          const Spacer(),
          Text(
            'Review Parsed Fields',
            style: AppTypography.labelLarge.copyWith(fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildPersonalTab() {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(label: 'Full Name', controller: _nameController, hint: 'e.g. Jane Doe'),
          const SizedBox(height: AppSpacing.md),
          AppTextField(label: 'Job Title', controller: _titleController, hint: 'e.g. Senior Mobile Engineer'),
          const SizedBox(height: AppSpacing.md),
          AppTextField(label: 'Email', controller: _emailController, hint: 'e.g. jane@example.com'),
          const SizedBox(height: AppSpacing.md),
          AppTextField(label: 'Phone', controller: _phoneController, hint: 'e.g. +1 (555) 123-4567'),
          const SizedBox(height: AppSpacing.md),
          AppTextField(label: 'Location', controller: _locationController, hint: 'e.g. San Francisco, CA'),
          const SizedBox(height: AppSpacing.md),
          AppTextField(label: 'Website / LinkedIn', controller: _websiteController, hint: 'e.g. linkedin.com/in/janedoe'),
        ],
      ),
    );
  }

  Widget _buildSummaryTab() {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Professional Summary', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Review and refine the extracted summary statement.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Summary Statement',
            controller: _summaryController,
            maxLines: 6,
            hint: 'Write a compelling career summary...',
          ),
        ],
      ),
    );
  }

  Widget _buildExperienceTab() {
    return ListView.builder(
      padding: AppSpacing.screenPadding,
      itemCount: _experiences.length + 1,
      itemBuilder: (context, index) {
        if (index == _experiences.length) {
          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xl),
            child: AppButton(
              text: 'Add Experience Item',
              icon: Icons.add_rounded,
              variant: AppButtonVariant.outline,
              onPressed: () {
                setState(() {
                  _experiences.add(Experience(
                    company: 'New Company',
                    position: 'Position',
                    startDate: '2023',
                    endDate: 'Present',
                    isCurrent: true,
                  ));
                });
              },
            ),
          );
        }

        final exp = _experiences[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        exp.position.isNotEmpty ? exp.position : 'Untitled Role',
                        style: AppTypography.titleMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.accentRed, size: 20),
                      onPressed: () {
                        setState(() => _experiences.removeAt(index));
                      },
                    ),
                  ],
                ),
                Text(
                  '${exp.company} • ${exp.startDate} - ${exp.isCurrent ? 'Present' : exp.endDate}',
                  style: AppTypography.bodySmall,
                ),
                if (exp.description.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Text(exp.description, style: AppTypography.bodyMedium),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildEducationTab() {
    return ListView.builder(
      padding: AppSpacing.screenPadding,
      itemCount: _educationList.length + 1,
      itemBuilder: (context, index) {
        if (index == _educationList.length) {
          return Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm, bottom: AppSpacing.xl),
            child: AppButton(
              text: 'Add Education Item',
              icon: Icons.add_rounded,
              variant: AppButtonVariant.outline,
              onPressed: () {
                setState(() {
                  _educationList.add(Education(
                    institution: 'University / College',
                    degree: 'Bachelor of Science',
                    fieldOfStudy: 'Computer Science',
                  ));
                });
              },
            ),
          );
        }

        final edu = _educationList[index];
        return Padding(
          padding: const EdgeInsets.only(bottom: AppSpacing.md),
          child: AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        edu.degree.isNotEmpty ? edu.degree : 'Degree',
                        style: AppTypography.titleMedium,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: AppColors.accentRed, size: 20),
                      onPressed: () {
                        setState(() => _educationList.removeAt(index));
                      },
                    ),
                  ],
                ),
                Text(
                  '${edu.institution} ${edu.fieldOfStudy.isNotEmpty ? '• ${edu.fieldOfStudy}' : ''}',
                  style: AppTypography.bodySmall,
                ),
                if (edu.gpa.isNotEmpty)
                  Text('GPA: ${edu.gpa}', style: AppTypography.labelSmall.copyWith(color: AppColors.primary)),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildSkillsTab() {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: AppTextField(
                  label: 'Add Skill',
                  controller: _newSkillController,
                  hint: 'e.g. Flutter, TypeScript',
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: AppButton(
                  text: 'Add',
                  isFullWidth: false,
                  onPressed: () {
                    final skillName = _newSkillController.text.trim();
                    if (skillName.isNotEmpty) {
                      setState(() {
                        _skills.add(Skill(name: skillName));
                        _newSkillController.clear();
                      });
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Text('Extracted Skills (${_skills.length})', style: AppTypography.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _skills.map((skill) {
              return Chip(
                backgroundColor: AppColors.surfaceLight,
                side: BorderSide(color: AppColors.surfaceBorder),
                label: Text(skill.name, style: AppTypography.bodyMedium),
                deleteIcon: const Icon(Icons.close, size: 16),
                onDeleted: () {
                  setState(() => _skills.remove(skill));
                },
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomActionBar() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
      ),
      child: Row(
        children: [
          Expanded(
            child: AppButton(
              text: 'Cancel',
              variant: AppButtonVariant.outline,
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            flex: 2,
            child: AppButton(
              text: 'Apply to Active Resume',
              icon: Icons.check_circle_rounded,
              variant: AppButtonVariant.primary,
              onPressed: _applyToActiveResume,
            ),
          ),
        ],
      ),
    );
  }
}
