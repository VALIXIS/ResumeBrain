import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../../app/providers.dart';
import '../../../data/models/resume_models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../templates/presentation/template_selector_screen.dart';
import '../models/pdf_export_config.dart';
import '../services/pdf_service.dart';
import '../widgets/pdf_export_customization_dialog.dart';
import '../../../core/widgets/smooth_page_route.dart';
import '../../home/presentation/home_dashboard_screen.dart';

class ResumePreviewScreen extends ConsumerStatefulWidget {
  const ResumePreviewScreen({super.key});

  @override
  ConsumerState<ResumePreviewScreen> createState() => _ResumePreviewScreenState();
}

class _ResumePreviewScreenState extends ConsumerState<ResumePreviewScreen> {
  PdfExportConfig _activeConfig = const PdfExportConfig();
  PdfExportConfig _pendingConfig = const PdfExportConfig();
  Timer? _debounceTimer;
  final TransformationController _transformationController = TransformationController();

  Uint8List? _cachedPdfBytes;
  String? _cacheKey;

  /// Optimized rasterization scale factor: 150 DPI delivers razor-sharp retina
  /// rendering while avoiding GPU texture memory bloat and frame drops during pinch-to-zoom.
  static const double _optimizedDpi = 150.0;
  static const Duration _debounceDuration = Duration(milliseconds: 300);

  @override
  void dispose() {
    _debounceTimer?.cancel();
    _transformationController.dispose();
    super.dispose();
  }

  /// Debounces PDF regeneration when preview options or customization settings change.
  void _onExportConfigChanged(PdfExportConfig newConfig) {
    _pendingConfig = newConfig;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, () {
      if (mounted) {
        setState(() {
          _activeConfig = _pendingConfig;
        });
      }
    });
  }

  /// Builds and caches the PDF document bytes, debouncing duplicate generation passes.
  Future<Uint8List> _buildDebouncedPdf(
    PdfPageFormat format,
    Resume resume,
    PdfService pdfService,
  ) async {
    final key = '${resume.id}_${resume.templateId}_${_activeConfig.fontFamily}_'
        '${_activeConfig.marginOption}_${_activeConfig.colorPalette}_'
        '${format.width}x${format.height}';

    if (_cachedPdfBytes != null && _cacheKey == key) {
      return _cachedPdfBytes!;
    }

    final bytes = await pdfService.buildPdfBytes(
      resume,
      pageFormat: format,
      config: _activeConfig,
    );

    _cachedPdfBytes = bytes;
    _cacheKey = key;
    return bytes;
  }

  @override
  Widget build(BuildContext context) {
    final resume = ref.watch(currentResumeProvider);
    final pdfService = ref.watch(pdfServiceProvider);

    final resumesList = ref.watch(resumesListProvider).value ?? [];

    if (resume == null) {
      if (resumesList.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.read(currentResumeProvider.notifier).setResume(resumesList.first);
        });
        return Scaffold(
          appBar: AppBar(title: const Text('Resume Preview')),
          body: const LoadingStateWidget(message: 'Loading resume preview...'),
        );
      }

      return Scaffold(
        appBar: AppBar(title: const Text('Resume Preview')),
        body: EmptyStateWidget(
          title: 'No Resume Available',
          description: 'Create or select a resume to preview and export to PDF.',
          icon: Icons.picture_as_pdf_outlined,
          actionText: 'Create Resume Now',
          onAction: () {
            final newResume = Resume(
              title: 'New Resume ${DateTime.now().day}',
            );
            ref.read(currentResumeProvider.notifier).setResume(newResume);
            ref.read(resumesListProvider.notifier).saveResume(newResume);
          },
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          tooltip: 'Back to Dashboard',
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              Navigator.pushReplacement(
                context,
                SmoothPageRoute(page: const HomeDashboardScreen()),
              );
            }
          },
        ),
        title: Text(resume.title, style: AppTypography.titleLarge),
        actions: [
          IconButton(
            icon: const Icon(Icons.home_rounded, color: AppColors.primary),
            tooltip: 'Go to Dashboard',
            onPressed: () {
              Navigator.of(context).pushAndRemoveUntil(
                SmoothPageRoute(page: const HomeDashboardScreen()),
                (route) => false,
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.style_outlined, color: AppColors.accentPurple),
            tooltip: 'Switch Template',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TemplateSelectorScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.tune_outlined, color: AppColors.secondary),
            tooltip: 'Customize PDF Export',
            onPressed: () async {
              final result = await showDialog<PdfExportConfig>(
                context: context,
                builder: (context) => PdfExportCustomizationDialog(
                  initialConfig: _pendingConfig,
                ),
              );
              if (result != null) {
                _onExportConfigChanged(result);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.accentTeal),
            tooltip: 'Share PDF',
            onPressed: () async {
              final pdfBytes = _cachedPdfBytes ??
                  await pdfService.buildPdfBytes(
                    resume,
                    config: _activeConfig,
                  );
              await pdfService.sharePdf(resume, pdfBytes);
            },
          ),
        ],
      ),
      body: PdfPreview.builder(
        build: (format) => _buildDebouncedPdf(format, resume, pdfService),
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        dpi: _optimizedDpi,
        pdfFileName: '${resume.title}.pdf',
        loadingWidget: const LoadingStateWidget(message: 'Compiling PDF document...'),
        pagesBuilder: (context, pages) {
          return GestureDetector(
            onDoubleTap: () {
              if (_transformationController.value != Matrix4.identity()) {
                _transformationController.value = Matrix4.identity();
              }
            },
            child: InteractiveViewer(
              transformationController: _transformationController,
              minScale: 0.75,
              maxScale: 4.0,
              panEnabled: true,
              scaleEnabled: true,
              clipBehavior: Clip.none,
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                child: Center(
                  child: Column(
                    children: pages.map((page) {
                      // Hardware-accelerated layer caching via RepaintBoundary prevents frame drops during zoom
                      return RepaintBoundary(
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 16),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(4),
                            boxShadow: const [
                              BoxShadow(
                                color: Color(0x26000000),
                                offset: Offset(0, 4),
                                blurRadius: 10,
                              ),
                            ],
                          ),
                          child: AspectRatio(
                            aspectRatio: page.aspectRatio,
                            child: Image(
                              image: page.image,
                              fit: BoxFit.contain,
                              filterQuality: FilterQuality.medium,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}
