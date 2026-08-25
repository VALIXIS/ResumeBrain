import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../data/models/resume_models.dart';
import '../../pdf/presentation/resume_preview_screen.dart';
import '../../templates/presentation/template_selector_screen.dart';

class ResumeEditorScreen extends ConsumerStatefulWidget {
  const ResumeEditorScreen({super.key});

  @override
  ConsumerState<ResumeEditorScreen> createState() => _ResumeEditorScreenState();
}

class _ResumeEditorScreenState extends ConsumerState<ResumeEditorScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final _fullNameCtrl = TextEditingController();
  final _jobTitleCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _summaryCtrl = TextEditingController();
  final _titleCtrl = TextEditingController();

  bool _isAiEnhancing = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 6, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadCurrentResumeData();
    });
  }

  void _loadCurrentResumeData() {
    final resume = ref.read(currentResumeProvider);
    if (resume != null) {
      _titleCtrl.text = resume.title;
      _fullNameCtrl.text = resume.personalInfo.fullName;
      _jobTitleCtrl.text = resume.personalInfo.jobTitle;
      _emailCtrl.text = resume.personalInfo.email;
      _phoneCtrl.text = resume.personalInfo.phone;
      _locationCtrl.text = resume.personalInfo.location;
      _websiteCtrl.text = resume.personalInfo.website;
      _summaryCtrl.text = resume.summary.summaryText;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fullNameCtrl.dispose();
    _jobTitleCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _websiteCtrl.dispose();
    _summaryCtrl.dispose();
    _titleCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resume = ref.watch(currentResumeProvider);

    if (resume == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Edit Resume')),
        body: const Center(child: Text('No resume selected')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          controller: _titleCtrl,
          style: AppTypography.titleLarge,
          decoration: const InputDecoration(
            border: InputBorder.none,
            enabledBorder: InputBorder.none,
            focusedBorder: InputBorder.none,
            hintText: 'Resume Title',
            isDense: true,
          ),
          onChanged: (val) {
            ref.read(currentResumeProvider.notifier).updateResume((r) => r.copyWith(title: val));
          },
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.style_outlined, color: AppColors.accentPurple),
            tooltip: 'Templates',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TemplateSelectorScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf_outlined, color: AppColors.primary),
            tooltip: 'Preview PDF',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ResumePreviewScreen()),
              );
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          indicatorColor: AppColors.primary,
          labelColor: AppColors.primary,
          unselectedLabelColor: AppColors.textMuted,
          tabs: const [
            Tab(text: 'Personal'),
            Tab(text: 'Summary'),
            Tab(text: 'Experience'),
            Tab(text: 'Education'),
            Tab(text: 'Skills'),
            Tab(text: 'Projects'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildPersonalInfoTab(resume),
          _buildSummaryTab(resume),
          _buildExperienceTab(resume),
          _buildEducationTab(resume),
          _buildSkillsTab(resume),
          _buildProjectsTab(resume),
        ],
      ),
      bottomNavigationBar: Container(
        padding: AppSpacing.paddingMd,
        decoration: const BoxDecoration(
          color: AppColors.surface,
          border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
        ),
        child: Row(
          children: [
            Expanded(
              child: AppButton(
                text: 'Select Template',
                icon: Icons.palette_outlined,
                variant: AppButtonVariant.secondary,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const TemplateSelectorScreen()),
                  );
                },
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: AppButton(
                text: 'Preview PDF',
                icon: Icons.visibility_outlined,
                variant: AppButtonVariant.primary,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ResumePreviewScreen()),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPersonalInfoTab(Resume resume) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        children: [
          AppTextField(
            label: 'Full Name',
            hint: 'e.g. Alex Morgan',
            controller: _fullNameCtrl,
            onChanged: (val) => _savePersonalInfo(),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Job Title / Target Role',
            hint: 'e.g. Senior Software Engineer',
            controller: _jobTitleCtrl,
            onChanged: (val) => _savePersonalInfo(),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Email Address',
            hint: 'e.g. alex.morgan@valixis.com',
            keyboardType: TextInputType.emailAddress,
            controller: _emailCtrl,
            onChanged: (val) => _savePersonalInfo(),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Phone Number',
            hint: 'e.g. +1 (555) 234-5678',
            keyboardType: TextInputType.phone,
            controller: _phoneCtrl,
            onChanged: (val) => _savePersonalInfo(),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Location (City, Country)',
            hint: 'e.g. San Francisco, CA',
            controller: _locationCtrl,
            onChanged: (val) => _savePersonalInfo(),
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Website / Portfolio Link',
            hint: 'e.g. https://alexmorgan.dev',
            controller: _websiteCtrl,
            onChanged: (val) => _savePersonalInfo(),
          ),
        ],
      ),
    );
  }

  void _savePersonalInfo() {
    ref.read(currentResumeProvider.notifier).updatePersonalInfo(
          PersonalInformation(
            fullName: _fullNameCtrl.text,
            jobTitle: _jobTitleCtrl.text,
            email: _emailCtrl.text,
            phone: _phoneCtrl.text,
            location: _locationCtrl.text,
            website: _websiteCtrl.text,
          ),
        );
  }

  Widget _buildSummaryTab(Resume resume) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AppTextField(
            label: 'Professional Summary',
            hint: 'Write a brief, impactful overview of your career accomplishments and strengths...',
            maxLines: 6,
            controller: _summaryCtrl,
            onChanged: (val) {
              ref.read(currentResumeProvider.notifier).updateSummary(ProfessionalSummary(summaryText: val));
            },
            onAiEnhance: () async {
              setState(() => _isAiEnhancing = true);
              final aiService = ref.read(aiServiceProvider);
              final res = await aiService.improveText(_summaryCtrl.text, 'summary');
              setState(() {
                _isAiEnhancing = false;
                if (res.isSuccess && res.outputText.isNotEmpty) {
                  _summaryCtrl.text = res.outputText;
                  ref.read(currentResumeProvider.notifier).updateSummary(ProfessionalSummary(summaryText: res.outputText));
                }
              });
              if (mounted && res.suggestions.isNotEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('AI Enhanced: ${res.suggestions.first}'),
                    backgroundColor: AppColors.accentPurple,
                  ),
                );
              }
            },
          ),
          if (_isAiEnhancing) ...[
            const SizedBox(height: AppSpacing.md),
            const LinearProgressIndicator(color: AppColors.accentPurple),
          ],
        ],
      ),
    );
  }

  Widget _buildExperienceTab(Resume resume) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Work Experience', style: AppTypography.titleLarge),
              AppButton(
                text: 'Add Experience',
                icon: Icons.add,
                isFullWidth: false,
                onPressed: () => _showExperienceDialog(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (resume.experiences.isEmpty)
            Text('No experience added yet.', style: AppTypography.bodyMedium)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: resume.experiences.length,
              separatorBuilder: (c, i) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (c, i) {
                final exp = resume.experiences[i];
                return AppCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(exp.position, style: AppTypography.titleMedium),
                            Text('${exp.company} • ${exp.startDate} - ${exp.isCurrent ? "Present" : exp.endDate}',
                                style: AppTypography.bodySmall),
                            if (exp.description.isNotEmpty) ...[
                              const SizedBox(height: 4),
                              Text(exp.description, style: AppTypography.bodyMedium, maxLines: 2, overflow: TextOverflow.ellipsis),
                            ],
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_outlined, color: AppColors.textMuted),
                        onPressed: () => _showExperienceDialog(context, experience: exp),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.accentRed),
                        onPressed: () => ref.read(currentResumeProvider.notifier).deleteExperience(exp.id),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showExperienceDialog(BuildContext context, {Experience? experience}) {
    final companyCtrl = TextEditingController(text: experience?.company ?? '');
    final positionCtrl = TextEditingController(text: experience?.position ?? '');
    final locationCtrl = TextEditingController(text: experience?.location ?? '');
    final startDateCtrl = TextEditingController(text: experience?.startDate ?? '');
    final endDateCtrl = TextEditingController(text: experience?.endDate ?? '');
    final descCtrl = TextEditingController(text: experience?.description ?? '');
    bool isCurrent = experience?.isCurrent ?? false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDlgState) => AlertDialog(
          backgroundColor: AppColors.surface,
          title: Text(experience == null ? 'Add Experience' : 'Edit Experience'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                AppTextField(label: 'Company', controller: companyCtrl),
                const SizedBox(height: 12),
                AppTextField(label: 'Position / Title', controller: positionCtrl),
                const SizedBox(height: 12),
                AppTextField(label: 'Location', controller: locationCtrl),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: AppTextField(label: 'Start Date', hint: 'e.g. 2022', controller: startDateCtrl)),
                    const SizedBox(width: 8),
                    Expanded(child: AppTextField(label: 'End Date', hint: 'e.g. Present', controller: endDateCtrl)),
                  ],
                ),
                const SizedBox(height: 8),
                CheckboxListTile(
                  title: const Text('I currently work here', style: TextStyle(color: Colors.white)),
                  value: isCurrent,
                  onChanged: (val) => setDlgState(() => isCurrent = val ?? false),
                ),
                const SizedBox(height: 8),
                AppTextField(
                  label: 'Description / Bullet points',
                  maxLines: 4,
                  controller: descCtrl,
                  onAiEnhance: () async {
                    final aiService = ref.read(aiServiceProvider);
                    final res = await aiService.improveText(descCtrl.text, 'experience');
                    if (res.isSuccess && res.outputText.isNotEmpty) {
                      setDlgState(() => descCtrl.text = res.outputText);
                    }
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            AppButton(
              text: 'Save',
              isFullWidth: false,
              onPressed: () {
                final exp = Experience(
                  id: experience?.id,
                  company: companyCtrl.text,
                  position: positionCtrl.text,
                  location: locationCtrl.text,
                  startDate: startDateCtrl.text,
                  endDate: endDateCtrl.text,
                  isCurrent: isCurrent,
                  description: descCtrl.text,
                );
                ref.read(currentResumeProvider.notifier).addExperience(exp);
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEducationTab(Resume resume) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Education', style: AppTypography.titleLarge),
              AppButton(
                text: 'Add Education',
                icon: Icons.add,
                isFullWidth: false,
                onPressed: () => _showEducationDialog(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (resume.educationList.isEmpty)
            Text('No education added yet.', style: AppTypography.bodyMedium)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: resume.educationList.length,
              separatorBuilder: (c, i) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (c, i) {
                final edu = resume.educationList[i];
                return AppCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${edu.degree} in ${edu.fieldOfStudy}', style: AppTypography.titleMedium),
                            Text('${edu.institution} • ${edu.startDate} - ${edu.endDate}', style: AppTypography.bodySmall),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.accentRed),
                        onPressed: () => ref.read(currentResumeProvider.notifier).deleteEducation(edu.id),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showEducationDialog(BuildContext context, {Education? education}) {
    final instCtrl = TextEditingController(text: education?.institution ?? '');
    final degreeCtrl = TextEditingController(text: education?.degree ?? '');
    final fieldCtrl = TextEditingController(text: education?.fieldOfStudy ?? '');
    final startCtrl = TextEditingController(text: education?.startDate ?? '');
    final endCtrl = TextEditingController(text: education?.endDate ?? '');

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Add Education'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(label: 'Institution', controller: instCtrl),
              const SizedBox(height: 12),
              AppTextField(label: 'Degree', controller: degreeCtrl),
              const SizedBox(height: 12),
              AppTextField(label: 'Field of Study', controller: fieldCtrl),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: AppTextField(label: 'Start Year', controller: startCtrl)),
                  const SizedBox(width: 8),
                  Expanded(child: AppTextField(label: 'End Year', controller: endCtrl)),
                ],
              ),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          AppButton(
            text: 'Save',
            isFullWidth: false,
            onPressed: () {
              final edu = Education(
                id: education?.id,
                institution: instCtrl.text,
                degree: degreeCtrl.text,
                fieldOfStudy: fieldCtrl.text,
                startDate: startCtrl.text,
                endDate: endCtrl.text,
              );
              ref.read(currentResumeProvider.notifier).addEducation(edu);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }

  Widget _buildSkillsTab(Resume resume) {
    final skillCtrl = TextEditingController();
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Skills', style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: AppTextField(label: 'Skill Name', hint: 'e.g. Flutter, Dart, Python', controller: skillCtrl),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: AppButton(
                  text: 'Add',
                  isFullWidth: false,
                  onPressed: () {
                    if (skillCtrl.text.isNotEmpty) {
                      ref.read(currentResumeProvider.notifier).addSkill(Skill(name: skillCtrl.text));
                      skillCtrl.clear();
                    }
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: resume.skills.map((skill) {
              return Chip(
                backgroundColor: AppColors.surfaceLight,
                label: Text(skill.name, style: const TextStyle(color: Colors.white)),
                deleteIcon: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
                onDeleted: () => ref.read(currentResumeProvider.notifier).deleteSkill(skill.id),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildProjectsTab(Resume resume) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Projects', style: AppTypography.titleLarge),
              AppButton(
                text: 'Add Project',
                icon: Icons.add,
                isFullWidth: false,
                onPressed: () => _showProjectDialog(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (resume.projects.isEmpty)
            Text('No projects added yet.', style: AppTypography.bodyMedium)
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: resume.projects.length,
              separatorBuilder: (c, i) => const SizedBox(height: AppSpacing.md),
              itemBuilder: (c, i) {
                final proj = resume.projects[i];
                return AppCard(
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(proj.name, style: AppTypography.titleMedium),
                            if (proj.role.isNotEmpty) Text(proj.role, style: AppTypography.bodySmall),
                            if (proj.description.isNotEmpty) Text(proj.description, style: AppTypography.bodyMedium),
                          ],
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.accentRed),
                        onPressed: () => ref.read(currentResumeProvider.notifier).deleteProject(proj.id),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  void _showProjectDialog(BuildContext context) {
    final nameCtrl = TextEditingController();
    final roleCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    final techCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppColors.surface,
        title: const Text('Add Project'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppTextField(label: 'Project Name', controller: nameCtrl),
              const SizedBox(height: 12),
              AppTextField(label: 'Your Role', controller: roleCtrl),
              const SizedBox(height: 12),
              AppTextField(label: 'Technologies Used', hint: 'e.g. Flutter, Firebase', controller: techCtrl),
              const SizedBox(height: 12),
              AppTextField(label: 'Description', maxLines: 3, controller: descCtrl),
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          AppButton(
            text: 'Save',
            isFullWidth: false,
            onPressed: () {
              final proj = Project(
                name: nameCtrl.text,
                role: roleCtrl.text,
                technologies: techCtrl.text,
                description: descCtrl.text,
              );
              ref.read(currentResumeProvider.notifier).addProject(proj);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    );
  }
}
