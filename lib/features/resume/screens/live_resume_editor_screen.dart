import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';

import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../../data/models/resume_models.dart';
import '../../pdf/models/pdf_export_config.dart';
import '../../templates/presentation/template_selector_screen.dart';
import '../providers/resume_history_provider.dart';
import '../utils/resume_input_scrubber.dart';
import '../widgets/certification_editor_dialog.dart';
import '../widgets/custom_section_editor_dialog.dart';
import '../widgets/education_editor_dialog.dart';
import '../widgets/experience_editor_dialog.dart';
import '../widgets/language_editor_dialog.dart';
import '../widgets/project_editor_dialog.dart';
import '../widgets/reorderable_section_card.dart';
import '../widgets/resume_error_boundary.dart';
import '../widgets/resume_validators.dart';
import '../widgets/validated_form_field.dart';

/// RSM-01 3D Live Split-Screen Resume Studio
///
/// Features:
/// - Dual-pane layout: Side-by-side split screen on tablet/desktop, bottom sheet toggle on mobile.
/// - Live vector PDF canvas re-renders immediately as text is typed without blocking the UI thread (debounced).
/// - Floating 3D customization pill with instant font-family switcher, line-height slider, margin adjuster, and primary color picker.
class LiveResumeEditorScreen extends ConsumerStatefulWidget {
  final String? resumeId;
  const LiveResumeEditorScreen({super.key, this.resumeId});

  @override
  ConsumerState<LiveResumeEditorScreen> createState() => _LiveResumeEditorScreenState();
}

class _LiveResumeEditorScreenState extends ConsumerState<LiveResumeEditorScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Controllers for personal info and summary
  final _titleCtrl = TextEditingController();
  final _fullNameCtrl = TextEditingController();
  final _jobTitleCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _locationCtrl = TextEditingController();
  final _websiteCtrl = TextEditingController();
  final _summaryCtrl = TextEditingController();
  final _skillInputCtrl = TextEditingController();
  String? _skillError;

  // Styling Configuration
  PdfExportConfig _exportConfig = const PdfExportConfig();

  // Floating Customization Pill State
  bool _isCustomizerOpen = false;

  // Mobile Bottom Sheet / Preview View Toggle
  bool _showMobilePreview = false;

  // Debounced live PDF refresh counter to trigger rebuild without freezing UI
  Timer? _pdfDebounceTimer;
  int _pdfRenderVersion = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 7, vsync: this);
    if (widget.resumeId != null) {
      final current = ref.read(currentResumeProvider);
      if (current?.id != widget.resumeId) {
        Future.microtask(() async {
          final repo = ref.read(resumeRepositoryProvider);
          final loaded = await repo.getResumeById(widget.resumeId!);
          if (loaded != null && mounted) {
            ref.read(currentResumeProvider.notifier).setResume(loaded);
            ref.read(resumeHistoryProvider.notifier).initializeWithResume(loaded);
            _loadCurrentResumeData();
            setState(() {});
          }
        });
      }
    }
    final resume = ref.read(currentResumeProvider);
    ref.read(resumeHistoryProvider.notifier).initializeWithResume(resume);
    _loadCurrentResumeData();
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

  void _triggerLivePdfUpdate() {
    _pdfDebounceTimer?.cancel();
    _pdfDebounceTimer = Timer(const Duration(milliseconds: 300), () {
      if (mounted) {
        setState(() {
          _pdfRenderVersion++;
        });
      }
    });
  }

  void _updateResumeWithHistory(Resume Function(Resume current) updateFn) {
    try {
      final current = ref.read(currentResumeProvider);
      if (current != null) {
        ref.read(currentResumeProvider.notifier).updateResume(updateFn);
        final updated = ref.read(currentResumeProvider);
        if (updated != null) {
          ref.read(resumeHistoryProvider.notifier).recordSnapshot(updated);
        }
        _triggerLivePdfUpdate();
      }
    } catch (e) {
      debugPrint('[LIVE_STUDIO] Error updating resume: $e');
    }
  }

  @override
  void dispose() {
    _pdfDebounceTimer?.cancel();
    _tabController.dispose();
    _titleCtrl.dispose();
    _fullNameCtrl.dispose();
    _jobTitleCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _locationCtrl.dispose();
    _websiteCtrl.dispose();
    _summaryCtrl.dispose();
    _skillInputCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final resume = ref.watch(currentResumeProvider);

    // Sync controllers on external/history update
    ref.listen<Resume?>(currentResumeProvider, (previous, next) {
      if (next != null) {
        if (_titleCtrl.text != next.title) _titleCtrl.text = next.title;
        if (_fullNameCtrl.text != next.personalInfo.fullName) _fullNameCtrl.text = next.personalInfo.fullName;
        if (_jobTitleCtrl.text != next.personalInfo.jobTitle) _jobTitleCtrl.text = next.personalInfo.jobTitle;
        if (_emailCtrl.text != next.personalInfo.email) _emailCtrl.text = next.personalInfo.email;
        if (_phoneCtrl.text != next.personalInfo.phone) _phoneCtrl.text = next.personalInfo.phone;
        if (_locationCtrl.text != next.personalInfo.location) _locationCtrl.text = next.personalInfo.location;
        if (_websiteCtrl.text != next.personalInfo.website) _websiteCtrl.text = next.personalInfo.website;
        if (_summaryCtrl.text != next.summary.summaryText) _summaryCtrl.text = next.summary.summaryText;
      }
    });

    if (resume == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('3D Live Resume Studio')),
        body: const EmptyStateWidget(
          title: 'No Resume Selected',
          description: 'Please select or create a resume to launch the Live Studio.',
          icon: Icons.edit_document,
        ),
      );
    }

    final isWideScreen = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: AppRadius.borderSm,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.view_in_ar_rounded, size: 16, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    '3D STUDIO',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.1,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: _titleCtrl,
                style: AppTypography.titleMedium,
                inputFormatters: [ResumeInputScrubber.titleFormatter()],
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  hintText: 'Resume Title',
                  isDense: true,
                ),
                onChanged: (val) {
                  _updateResumeWithHistory((r) => r.copyWith(title: val));
                },
              ),
            ),
          ],
        ),
        actions: [
          // Undo / Redo
          Consumer(
            builder: (context, ref, _) {
              final canUndo = ref.watch(resumeHistoryProvider.select((s) => s.canUndo));
              return IconButton(
                icon: const Icon(Icons.undo),
                tooltip: 'Undo',
                color: canUndo ? AppColors.textPrimary : AppColors.textMuted.withValues(alpha: 0.35),
                onPressed: canUndo ? () => ref.read(resumeHistoryProvider.notifier).undo(ref) : null,
              );
            },
          ),
          Consumer(
            builder: (context, ref, _) {
              final canRedo = ref.watch(resumeHistoryProvider.select((s) => s.canRedo));
              return IconButton(
                icon: const Icon(Icons.redo),
                tooltip: 'Redo',
                color: canRedo ? AppColors.textPrimary : AppColors.textMuted.withValues(alpha: 0.35),
                onPressed: canRedo ? () => ref.read(resumeHistoryProvider.notifier).redo(ref) : null,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.palette_outlined, color: AppColors.accentPurple),
            tooltip: 'Template Gallery',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TemplateSelectorScreen()),
              );
            },
          ),
          if (!isWideScreen)
            IconButton(
              icon: Icon(
                _showMobilePreview ? Icons.edit_note_rounded : Icons.picture_as_pdf_outlined,
                color: AppColors.secondary,
              ),
              tooltip: _showMobilePreview ? 'Switch to Editor' : 'Live PDF Preview',
              onPressed: () {
                setState(() => _showMobilePreview = !_showMobilePreview);
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
            Tab(text: 'Sections'),
          ],
        ),
      ),
      body: Stack(
        children: [
          isWideScreen
              ? _buildDesktopSplitLayout(resume)
              : _buildMobileStudioLayout(resume),
          // 3D Floating Customization Pill
          _buildFloating3DCustomizationPill(),
        ],
      ),
    );
  }

  // ===========================================================================
  // DESKTOP & TABLET DUAL-PANE SPLIT LAYOUT
  // ===========================================================================
  Widget _buildDesktopSplitLayout(Resume resume) {
    return Row(
      children: [
        // Left Pane: Form Editor
        Expanded(
          flex: 5,
          child: Container(
            decoration: const BoxDecoration(
              border: Border(right: BorderSide(color: AppColors.surfaceBorder, width: 1)),
            ),
            child: _buildTabContentView(resume),
          ),
        ),
        // Right Pane: Live Vector PDF Canvas with 3D Depth Frame
        Expanded(
          flex: 6,
          child: Container(
            color: AppColors.background,
            child: _buildLivePdfPane(resume),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // MOBILE STUDIO LAYOUT (Tabs with Toggle or Bottom Sheet)
  // ===========================================================================
  Widget _buildMobileStudioLayout(Resume resume) {
    if (_showMobilePreview) {
      return Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            color: AppColors.surfaceLight,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.remove_red_eye_rounded, size: 16, color: AppColors.primary),
                    const SizedBox(width: 6),
                    Text('Live PDF Canvas', style: AppTypography.titleMedium.copyWith(fontSize: 13)),
                  ],
                ),
                TextButton.icon(
                  icon: const Icon(Icons.edit, size: 14),
                  label: const Text('Back to Fields'),
                  onPressed: () => setState(() => _showMobilePreview = false),
                ),
              ],
            ),
          ),
          Expanded(child: _buildLivePdfPane(resume)),
        ],
      );
    }

    return Column(
      children: [
        Expanded(child: _buildTabContentView(resume)),
        // Bottom bar button to open quick preview bottom sheet
        SafeArea(
          top: false,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: 8),
            decoration: const BoxDecoration(
              color: AppColors.surface,
              border: Border(top: BorderSide(color: AppColors.surfaceBorder)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.textPrimary,
                      side: const BorderSide(color: AppColors.surfaceBorder),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.tune_rounded, size: 18),
                    label: const Text('Styling', maxLines: 1, overflow: TextOverflow.ellipsis),
                    onPressed: () => setState(() => _isCustomizerOpen = !_isCustomizerOpen),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    icon: const Icon(Icons.visibility_outlined, size: 18),
                    label: const Text('Live Preview', maxLines: 1, overflow: TextOverflow.ellipsis),
                    onPressed: () => _openMobilePdfBottomSheet(resume),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ===========================================================================
  // LIVE PDF PANE WITH 3D DEPTH FRAME
  // ===========================================================================
  Widget _buildLivePdfPane(Resume resume) {
    final pdfService = ref.watch(pdfServiceProvider);

    return Container(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.35),
                blurRadius: 24,
                spreadRadius: 2,
                offset: const Offset(0, 10),
              ),
              BoxShadow(
                color: (_exportConfig.customPrimaryColor ?? AppColors.primary).withValues(alpha: 0.15),
                blurRadius: 36,
                spreadRadius: 1,
                offset: const Offset(0, 14),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: PdfPreview(
              key: ValueKey('pdf_canvas_${resume.templateId}_$_pdfRenderVersion'),
              build: (format) => pdfService.buildPdfBytes(
                resume,
                pageFormat: format,
                config: _exportConfig,
              ),
              allowPrinting: true,
              allowSharing: true,
              canChangeOrientation: false,
              canChangePageFormat: false,
              canDebug: false,
              pdfFileName: '${resume.title}.pdf',
              loadingWidget: const LoadingStateWidget(message: 'Compiling live vector PDF...'),
              scrollViewDecoration: const BoxDecoration(
                color: AppColors.surfaceLight,
              ),
            ),
          ),
        ),
      ),
    );
  }

  // Mobile Bottom Sheet PDF preview toggle
  void _openMobilePdfBottomSheet(Resume resume) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.85,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Column(
              children: [
                Container(
                  margin: const EdgeInsets.symmetric(vertical: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppColors.surfaceBorder,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Live Vector Preview', style: AppTypography.titleMedium),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Expanded(child: _buildLivePdfPane(resume)),
              ],
            );
          },
        );
      },
    );
  }

  // ===========================================================================
  // FLOATING 3D CUSTOMIZATION PILL
  // ===========================================================================
  Widget _buildFloating3DCustomizationPill() {
    return Positioned(
      bottom: 24,
      right: 24,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (_isCustomizerOpen)
            Container(
              width: 320,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.surfaceBorder, width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.45),
                    blurRadius: 28,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 18,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Expanded(
                          child: Row(
                            children: [
                              Icon(Icons.auto_awesome, color: AppColors.primary, size: 18),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  'Live Styling Controls',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: AppColors.textPrimary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: () => setState(() => _isCustomizerOpen = false),
                        ),
                      ],
                    ),
                    const Divider(height: 16),

                    // 1. Font Family Switcher
                    Text('FONT FAMILY', style: AppTypography.labelSmall.copyWith(color: AppColors.primary, fontSize: 10)),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<PdfFontFamily>(
                      initialValue: _exportConfig.fontFamily,
                      isExpanded: true,
                      isDense: true,
                      dropdownColor: AppColors.surfaceLight,
                      decoration: InputDecoration(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      items: PdfFontFamily.values.map((font) {
                        return DropdownMenuItem(
                          value: font,
                          child: Text(font.displayName, style: const TextStyle(fontSize: 12)),
                        );
                      }).toList(),
                      onChanged: (newFont) {
                        if (newFont != null) {
                          setState(() {
                            _exportConfig = _exportConfig.copyWith(fontFamily: newFont);
                          });
                          _triggerLivePdfUpdate();
                        }
                      },
                    ),
                    const SizedBox(height: 12),

                    // 2. Line Height Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('LINE HEIGHT', style: AppTypography.labelSmall.copyWith(color: AppColors.primary, fontSize: 10)),
                        Text('${_exportConfig.lineHeight.toStringAsFixed(2)}x', style: AppTypography.bodySmall),
                      ],
                    ),
                    Slider(
                      value: _exportConfig.lineHeight,
                      min: 1.0,
                      max: 2.0,
                      divisions: 10,
                      activeColor: AppColors.primary,
                      onChanged: (val) {
                        setState(() {
                          _exportConfig = _exportConfig.copyWith(lineHeight: val);
                        });
                        _triggerLivePdfUpdate();
                      },
                    ),

                    // 3. Margin Adjuster Slider
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('PAGE MARGIN', style: AppTypography.labelSmall.copyWith(color: AppColors.primary, fontSize: 10)),
                        Text('${(_exportConfig.customMargin ?? 36.0).toInt()} pt', style: AppTypography.bodySmall),
                      ],
                    ),
                    Slider(
                      value: _exportConfig.customMargin ?? 36.0,
                      min: 14.0,
                      max: 56.0,
                      divisions: 14,
                      activeColor: AppColors.secondary,
                      onChanged: (val) {
                        setState(() {
                          _exportConfig = _exportConfig.copyWith(customMargin: val);
                        });
                        _triggerLivePdfUpdate();
                      },
                    ),

                    // 4. Primary Accent Color Picker
                    Text('PRIMARY ACCENT COLOR', style: AppTypography.labelSmall.copyWith(color: AppColors.primary, fontSize: 10)),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        const Color(0xFF4F46E5), // Indigo
                        const Color(0xFF2563EB), // Royal Blue
                        const Color(0xFF0D9488), // Teal
                        const Color(0xFF059669), // Emerald
                        const Color(0xFF991B1B), // Crimson
                        const Color(0xFF7C3AED), // Purple
                        const Color(0xFF0F172A), // Slate Dark
                        const Color(0xFFEA580C), // Orange
                      ].map((color) {
                        final isSelected = _exportConfig.customPrimaryColor == color;
                        return GestureDetector(
                          onTap: () {
                            setState(() {
                              _exportConfig = _exportConfig.copyWith(customPrimaryColor: color);
                            });
                            _triggerLivePdfUpdate();
                          },
                          child: Container(
                            width: 28,
                            height: 28,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected ? Colors.white : Colors.transparent,
                                width: 2.5,
                              ),
                              boxShadow: [
                                if (isSelected)
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.6),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ],
                ),
              ),
            ),
          // The 3D Floating Pill Trigger Button
          Tooltip(
            message: '3D Styling Studio',
            child: GestureDetector(
              key: const ValueKey('pill_trigger_btn'),
              onTap: () => setState(() => _isCustomizerOpen = !_isCustomizerOpen),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
              decoration: BoxDecoration(
                gradient: AppColors.primaryGradient,
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.5),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _isCustomizerOpen ? Icons.tune_rounded : Icons.auto_fix_high_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _isCustomizerOpen ? 'Close Controls' : 'Live Styling Studio',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    ),
  );
  }

  // ===========================================================================
  // TAB CONTENT BUILDER (Personal, Summary, Experience, Edu, Skills, Projects, Sections)
  // ===========================================================================
  Widget _buildTabContentView(Resume resume) {
    return TabBarView(
      controller: _tabController,
      children: [
        ResumeErrorBoundary(
          sectionName: 'Personal Information',
          child: RepaintBoundary(child: _buildPersonalInfoTab(resume)),
        ),
        ResumeErrorBoundary(
          sectionName: 'Professional Summary',
          child: RepaintBoundary(child: _buildSummaryTab(resume)),
        ),
        ResumeErrorBoundary(
          sectionName: 'Work Experience',
          child: RepaintBoundary(child: _buildExperienceTab(resume)),
        ),
        ResumeErrorBoundary(
          sectionName: 'Education',
          child: RepaintBoundary(child: _buildEducationTab(resume)),
        ),
        ResumeErrorBoundary(
          sectionName: 'Skills Inventory',
          child: RepaintBoundary(child: _buildSkillsTab(resume)),
        ),
        ResumeErrorBoundary(
          sectionName: 'Showcase Projects',
          child: RepaintBoundary(child: _buildProjectsTab(resume)),
        ),
        ResumeErrorBoundary(
          sectionName: 'Supplementary Sections',
          child: RepaintBoundary(child: _buildSupplementarySectionsTab(resume)),
        ),
      ],
    );
  }

  // 1. Personal Information Tab
  Widget _buildPersonalInfoTab(Resume resume) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ValidatedFormField(
            label: 'Full Name',
            hint: 'e.g. Alex Morgan',
            controller: _fullNameCtrl,
            maxLength: 80,
            isRequired: true,
            inputFormatters: [ResumeInputScrubber.nameFormatter()],
            prefixIcon: const Icon(Icons.person_outline, size: 20),
            validator: (val) => ResumeValidators.validateRequired(val, 'Full name', minLength: 2, maxLength: 80),
            onChanged: (_) => _savePersonalInfo(),
          ),
          const SizedBox(height: AppSpacing.md),
          ValidatedFormField(
            label: 'Job Title / Target Role',
            hint: 'e.g. Senior Software Engineer',
            controller: _jobTitleCtrl,
            maxLength: 100,
            inputFormatters: [ResumeInputScrubber.titleFormatter()],
            prefixIcon: const Icon(Icons.badge_outlined, size: 20),
            validator: (val) => ResumeValidators.validateOptionalLength(val, 'Job title', maxLength: 100),
            onChanged: (_) => _savePersonalInfo(),
          ),
          const SizedBox(height: AppSpacing.md),
          ValidatedFormField(
            label: 'Email Address',
            hint: 'e.g. alex.morgan@example.com',
            keyboardType: TextInputType.emailAddress,
            controller: _emailCtrl,
            maxLength: 100,
            isRequired: true,
            inputFormatters: [ResumeInputScrubber.emailFormatter()],
            prefixIcon: const Icon(Icons.email_outlined, size: 20),
            validator: (val) => ResumeValidators.validateEmail(val, isRequired: true),
            onChanged: (_) => _savePersonalInfo(),
          ),
          const SizedBox(height: AppSpacing.md),
          ValidatedFormField(
            label: 'Phone Number',
            hint: 'e.g. +1 (555) 234-5678',
            keyboardType: TextInputType.phone,
            controller: _phoneCtrl,
            maxLength: 30,
            inputFormatters: [ResumeInputScrubber.phoneFormatter()],
            prefixIcon: const Icon(Icons.phone_outlined, size: 20),
            validator: (val) => ResumeValidators.validatePhone(val),
            onChanged: (_) => _savePersonalInfo(),
          ),
          const SizedBox(height: AppSpacing.md),
          ValidatedFormField(
            label: 'Location (City, Country)',
            hint: 'e.g. San Francisco, CA',
            controller: _locationCtrl,
            maxLength: 100,
            inputFormatters: [ResumeInputScrubber.titleFormatter()],
            prefixIcon: const Icon(Icons.location_on_outlined, size: 20),
            validator: (val) => ResumeValidators.validateOptionalLength(val, 'Location', maxLength: 100),
            onChanged: (_) => _savePersonalInfo(),
          ),
          const SizedBox(height: AppSpacing.md),
          ValidatedFormField(
            label: 'Website / Portfolio Link',
            hint: 'e.g. https://alexmorgan.dev',
            keyboardType: TextInputType.url,
            controller: _websiteCtrl,
            maxLength: 200,
            inputFormatters: [ResumeInputScrubber.urlFormatter()],
            prefixIcon: const Icon(Icons.link_outlined, size: 20),
            validator: (val) => ResumeValidators.validateUrl(val),
            onChanged: (_) => _savePersonalInfo(),
          ),
        ],
      ),
    );
  }

  void _savePersonalInfo() {
    _updateResumeWithHistory((r) => r.copyWith(
          personalInfo: PersonalInformation(
            fullName: _fullNameCtrl.text.trim(),
            jobTitle: _jobTitleCtrl.text.trim(),
            email: _emailCtrl.text.trim(),
            phone: _phoneCtrl.text.trim(),
            location: _locationCtrl.text.trim(),
            website: _websiteCtrl.text.trim(),
          ),
        ));
  }

  // 2. Summary Tab
  Widget _buildSummaryTab(Resume resume) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Professional Summary', style: AppTypography.titleLarge),
          const SizedBox(height: 4),
          Text(
            'Summarize your career highlights, core strengths, and goals.',
            style: AppTypography.bodySmall,
          ),
          const SizedBox(height: AppSpacing.md),
          ValidatedFormField(
            label: 'Summary Statement',
            hint: 'Write a compelling 2-4 sentence career overview...',
            controller: _summaryCtrl,
            maxLines: 6,
            maxLength: 1000,
            inputFormatters: [ResumeInputScrubber.textBlockFormatter()],
            validator: (val) => ResumeValidators.validateOptionalLength(val, 'Summary', maxLength: 1000),
            onChanged: (val) {
              _updateResumeWithHistory((r) => r.copyWith(
                    summary: ProfessionalSummary(summaryText: val.trim()),
                  ));
            },
          ),
        ],
      ),
    );
  }

  // 3. Experience Tab
  Widget _buildExperienceTab(Resume resume) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Work Experience (${resume.experiences.length})', style: AppTypography.titleLarge),
              AppButton(
                text: 'Add Experience',
                icon: Icons.add,
                isFullWidth: false,
                onPressed: () => _openExperienceDialog(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (resume.experiences.isEmpty)
            _buildEmptySectionCard('No work experience added yet.', Icons.work_outline, () => _openExperienceDialog(context))
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: resume.experiences.length,
              // ignore: deprecated_member_use
              onReorder: (oldIndex, newIndex) {
                if (oldIndex < newIndex) newIndex -= 1;
                final list = List<Experience>.from(resume.experiences);
                final item = list.removeAt(oldIndex);
                list.insert(newIndex, item);
                _updateResumeWithHistory((r) => r.copyWith(experiences: list));
              },
              itemBuilder: (context, index) {
                final exp = resume.experiences[index];
                return ReorderableSectionCard(
                  key: ValueKey('exp_${exp.id}'),
                  index: index,
                  leading: const Icon(Icons.work_outline, color: AppColors.primary, size: 20),
                  title: exp.position,
                  subtitle: '${exp.company} • ${exp.startDate} - ${exp.isCurrent ? "Present" : exp.endDate}',
                  description: exp.description,
                  onEdit: () => _openExperienceDialog(context, experience: exp),
                  onDelete: () => _updateResumeWithHistory((r) => r.copyWith(
                        experiences: r.experiences.where((e) => e.id != exp.id).toList(),
                      )),
                );
              },
            ),
        ],
      ),
    );
  }

  void _openExperienceDialog(BuildContext context, {Experience? experience}) {
    ExperienceEditorDialog.show(
      context: context,
      experience: experience,
      onSave: (exp) {
        _updateResumeWithHistory((r) {
          final list = List<Experience>.from(r.experiences);
          final index = list.indexWhere((item) => item.id == exp.id);
          if (index != -1) {
            list[index] = exp;
          } else {
            list.add(exp);
          }
          return r.copyWith(experiences: list);
        });
      },
    );
  }

  // 4. Education Tab
  Widget _buildEducationTab(Resume resume) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Education (${resume.educationList.length})', style: AppTypography.titleLarge),
              AppButton(
                text: 'Add Education',
                icon: Icons.add,
                isFullWidth: false,
                onPressed: () => _openEducationDialog(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (resume.educationList.isEmpty)
            _buildEmptySectionCard('No education entries added.', Icons.school_outlined, () => _openEducationDialog(context))
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: resume.educationList.length,
              // ignore: deprecated_member_use
              onReorder: (oldIndex, newIndex) {
                if (oldIndex < newIndex) newIndex -= 1;
                final list = List<Education>.from(resume.educationList);
                final item = list.removeAt(oldIndex);
                list.insert(newIndex, item);
                _updateResumeWithHistory((r) => r.copyWith(educationList: list));
              },
              itemBuilder: (context, index) {
                final edu = resume.educationList[index];
                return ReorderableSectionCard(
                  key: ValueKey('edu_${edu.id}'),
                  index: index,
                  leading: const Icon(Icons.school_outlined, color: AppColors.primary, size: 20),
                  title: '${edu.degree} in ${edu.fieldOfStudy}',
                  subtitle: '${edu.institution} • ${edu.startDate} - ${edu.endDate}',
                  onEdit: () => _openEducationDialog(context, education: edu),
                  onDelete: () => _updateResumeWithHistory((r) => r.copyWith(
                        educationList: r.educationList.where((e) => e.id != edu.id).toList(),
                      )),
                );
              },
            ),
        ],
      ),
    );
  }

  void _openEducationDialog(BuildContext context, {Education? education}) {
    EducationEditorDialog.show(
      context: context,
      education: education,
      onSave: (edu) {
        _updateResumeWithHistory((r) {
          final list = List<Education>.from(r.educationList);
          final index = list.indexWhere((item) => item.id == edu.id);
          if (index != -1) {
            list[index] = edu;
          } else {
            list.add(edu);
          }
          return r.copyWith(educationList: list);
        });
      },
    );
  }

  // 5. Skills Tab
  Widget _buildSkillsTab(Resume resume) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Skills (${resume.skills.length})', style: AppTypography.titleLarge),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: ValidatedFormField(
                  label: 'Add Skill',
                  hint: 'e.g. Flutter, TypeScript, Docker',
                  controller: _skillInputCtrl,
                  maxLength: 50,
                  inputFormatters: [ResumeInputScrubber.titleFormatter()],
                  textInputAction: TextInputAction.done,
                  onFieldSubmitted: (_) => _addSkill(resume),
                  validator: (_) => _skillError,
                ),
              ),
              const SizedBox(width: 8),
              Padding(
                padding: const EdgeInsets.only(top: 24),
                child: AppButton(
                  text: 'Add',
                  icon: Icons.add,
                  isFullWidth: false,
                  onPressed: () => _addSkill(resume),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (resume.skills.isEmpty)
            _buildEmptySectionCard('No skills added yet.', Icons.code, null)
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: resume.skills.length,
              // ignore: deprecated_member_use
              onReorder: (oldIndex, newIndex) {
                if (oldIndex < newIndex) newIndex -= 1;
                final list = List<Skill>.from(resume.skills);
                final item = list.removeAt(oldIndex);
                list.insert(newIndex, item);
                _updateResumeWithHistory((r) => r.copyWith(skills: list));
              },
              itemBuilder: (context, index) {
                final skill = resume.skills[index];
                return ReorderableSectionCard(
                  key: ValueKey('skill_${skill.id}'),
                  index: index,
                  leading: const Icon(Icons.code, color: AppColors.primary, size: 16),
                  title: skill.name,
                  onDelete: () => _updateResumeWithHistory((r) => r.copyWith(
                        skills: r.skills.where((s) => s.id != skill.id).toList(),
                      )),
                );
              },
            ),
        ],
      ),
    );
  }

  void _addSkill(Resume resume) {
    final text = _skillInputCtrl.text.trim();
    if (text.isEmpty) return;
    if (resume.skills.any((s) => s.name.toLowerCase() == text.toLowerCase())) {
      setState(() => _skillError = 'Skill already exists');
      return;
    }
    setState(() => _skillError = null);
    _updateResumeWithHistory((r) {
      final list = List<Skill>.from(r.skills)..add(Skill(name: text));
      return r.copyWith(skills: list);
    });
    _skillInputCtrl.clear();
  }

  // 6. Projects Tab
  Widget _buildProjectsTab(Resume resume) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Projects (${resume.projects.length})', style: AppTypography.titleLarge),
              AppButton(
                text: 'Add Project',
                icon: Icons.add,
                isFullWidth: false,
                onPressed: () => _openProjectDialog(context),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          if (resume.projects.isEmpty)
            _buildEmptySectionCard('No projects added.', Icons.lightbulb_outline, () => _openProjectDialog(context))
          else
            ReorderableListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              buildDefaultDragHandles: false,
              itemCount: resume.projects.length,
              // ignore: deprecated_member_use
              onReorder: (oldIndex, newIndex) {
                if (oldIndex < newIndex) newIndex -= 1;
                final list = List<Project>.from(resume.projects);
                final item = list.removeAt(oldIndex);
                list.insert(newIndex, item);
                _updateResumeWithHistory((r) => r.copyWith(projects: list));
              },
              itemBuilder: (context, index) {
                final proj = resume.projects[index];
                return ReorderableSectionCard(
                  key: ValueKey('proj_${proj.id}'),
                  index: index,
                  leading: const Icon(Icons.rocket_launch_outlined, color: AppColors.secondary, size: 20),
                  title: proj.name,
                  subtitle: proj.role.isNotEmpty ? proj.role : null,
                  description: proj.description,
                  onEdit: () => _openProjectDialog(context, project: proj),
                  onDelete: () => _updateResumeWithHistory((r) => r.copyWith(
                        projects: r.projects.where((p) => p.id != proj.id).toList(),
                      )),
                );
              },
            ),
        ],
      ),
    );
  }

  void _openProjectDialog(BuildContext context, {Project? project}) {
    ProjectEditorDialog.show(
      context: context,
      project: project,
      onSave: (proj) {
        _updateResumeWithHistory((r) {
          final list = List<Project>.from(r.projects);
          final index = list.indexWhere((p) => p.id == proj.id);
          if (index != -1) {
            list[index] = proj;
          } else {
            list.add(proj);
          }
          return r.copyWith(projects: list);
        });
      },
    );
  }

  // 7. Supplementary Sections Tab (Certifications, Languages, Custom)
  Widget _buildSupplementarySectionsTab(Resume resume) {
    return SingleChildScrollView(
      padding: AppSpacing.screenPadding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Certifications
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Certifications (${resume.certifications.length})', style: AppTypography.titleMedium),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                onPressed: () => CertificationEditorDialog.show(
                  context: context,
                  onSave: (cert) => _updateResumeWithHistory((r) {
                    final list = List<Certification>.from(r.certifications);
                    final idx = list.indexWhere((c) => c.id == cert.id);
                    if (idx != -1) {
                      list[idx] = cert;
                    } else {
                      list.add(cert);
                    }
                    return r.copyWith(certifications: list);
                  }),
                ),
              ),
            ],
          ),
          ...resume.certifications.map((c) => ListTile(
                dense: true,
                title: Text(c.name),
                subtitle: Text(c.issuingOrganization),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () => _updateResumeWithHistory((r) => r.copyWith(
                        certifications: r.certifications.where((cert) => cert.id != c.id).toList(),
                      )),
                ),
              )),
          const Divider(height: 24),

          // Languages
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Languages (${resume.languages.length})', style: AppTypography.titleMedium),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                onPressed: () => LanguageEditorDialog.show(
                  context: context,
                  onSave: (lang) => _updateResumeWithHistory((r) {
                    final list = List<Language>.from(r.languages);
                    final idx = list.indexWhere((l) => l.id == lang.id);
                    if (idx != -1) {
                      list[idx] = lang;
                    } else {
                      list.add(lang);
                    }
                    return r.copyWith(languages: list);
                  }),
                ),
              ),
            ],
          ),
          ...resume.languages.map((l) => ListTile(
                dense: true,
                title: Text(l.name),
                subtitle: Text(l.proficiency),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () => _updateResumeWithHistory((r) => r.copyWith(
                        languages: r.languages.where((lang) => lang.id != l.id).toList(),
                      )),
                ),
              )),
          const Divider(height: 24),

          // Custom Sections
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Custom Sections (${resume.customSections.length})', style: AppTypography.titleMedium),
              IconButton(
                icon: const Icon(Icons.add_circle_outline, color: AppColors.primary),
                onPressed: () => CustomSectionEditorDialog.show(
                  context: context,
                  onSave: (sec) => _updateResumeWithHistory((r) {
                    final list = List<CustomSection>.from(r.customSections);
                    final idx = list.indexWhere((s) => s.id == sec.id);
                    if (idx != -1) {
                      list[idx] = sec;
                    } else {
                      list.add(sec);
                    }
                    return r.copyWith(customSections: list);
                  }),
                ),
              ),
            ],
          ),
          ...resume.customSections.map((s) => ListTile(
                dense: true,
                title: Text(s.title),
                subtitle: Text('${s.items.length} bullet item(s)'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete_outline, size: 18),
                  onPressed: () => _updateResumeWithHistory((r) => r.copyWith(
                        customSections: r.customSections.where((sec) => sec.id != s.id).toList(),
                      )),
                ),
              )),
        ],
      ),
    );
  }

  Widget _buildEmptySectionCard(String text, IconData icon, VoidCallback? onAdd) {
    return AppCard(
      color: AppColors.surfaceLight.withValues(alpha: 0.5),
      child: Row(
        children: [
          Icon(icon, color: AppColors.textMuted, size: 28),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(text, style: AppTypography.bodySmall)),
          if (onAdd != null)
            AppButton(
              text: 'Add',
              icon: Icons.add,
              isFullWidth: false,
              variant: AppButtonVariant.secondary,
              onPressed: onAdd,
            ),
        ],
      ),
    );
  }
}
