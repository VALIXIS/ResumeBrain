import 'dart:io';
import 'dart:typed_data';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:share_plus/share_plus.dart';
import '../../../data/models/resume_models.dart';
import '../../templates/services/template_registry.dart';
import '../models/pdf_export_config.dart';

class PdfService {
  Future<Uint8List> buildPdfBytes(
    Resume resume, {
    PdfPageFormat pageFormat = PdfPageFormat.a4,
    PdfExportConfig? config,
  }) async {
    final template = TemplateRegistry.getTemplateById(resume.templateId);
    final pdfDocument = await template.generatePdf(
      resume,
      pageFormat,
      config: config,
    );
    return pdfDocument.save();
  }

  Future<File> savePdfFile(Resume resume, Uint8List pdfBytes) async {
    final outputDir = await getApplicationDocumentsDirectory();
    final safeId = resume.id.length >= 6 ? resume.id.substring(0, 6) : resume.id;
    final fileName = '${resume.title.replaceAll(RegExp(r'[^\w\s\.-]'), '_')}_$safeId.pdf';
    final file = File('${outputDir.path}/$fileName');
    await file.writeAsBytes(pdfBytes);
    return file;
  }

  Future<void> sharePdf(Resume resume, Uint8List pdfBytes) async {
    final file = await savePdfFile(resume, pdfBytes);
    await Share.shareXFiles(
      [XFile(file.path)],
      text: 'Sharing my resume (${resume.title}) created with Resume Brain',
    );
  }
}
