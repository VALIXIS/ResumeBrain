import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:printing/printing.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/state_widgets.dart';
import '../../templates/presentation/template_selector_screen.dart';
import '../models/pdf_export_config.dart';
import '../widgets/pdf_export_customization_dialog.dart';

class ResumePreviewScreen extends ConsumerStatefulWidget {
  const ResumePreviewScreen({super.key});

  @override
  ConsumerState<ResumePreviewScreen> createState() => _ResumePreviewScreenState();
}

class _ResumePreviewScreenState extends ConsumerState<ResumePreviewScreen> {
  PdfExportConfig _exportConfig = const PdfExportConfig();

  @override
  Widget build(BuildContext context) {
    final resume = ref.watch(currentResumeProvider);
    final pdfService = ref.watch(pdfServiceProvider);

    if (resume == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Resume Preview')),
        body: const Center(child: Text('No resume selected')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(resume.title, style: AppTypography.titleLarge),
        actions: [
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
                  initialConfig: _exportConfig,
                ),
              );
              if (result != null) {
                setState(() {
                  _exportConfig = result;
                });
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined, color: AppColors.primary),
            tooltip: 'Share PDF',
            onPressed: () async {
              final pdfBytes = await pdfService.buildPdfBytes(
                resume,
                config: _exportConfig,
              );
              await pdfService.sharePdf(resume, pdfBytes);
            },
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => pdfService.buildPdfBytes(
          resume,
          pageFormat: format,
          config: _exportConfig,
        ),
        allowPrinting: true,
        allowSharing: true,
        canChangeOrientation: false,
        canChangePageFormat: false,
        pdfFileName: '${resume.title}.pdf',
        loadingWidget: const LoadingStateWidget(message: 'Compiling PDF document...'),
      ),
    );
  }
}
