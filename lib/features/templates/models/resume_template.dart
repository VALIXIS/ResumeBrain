import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../data/models/resume_models.dart';
import '../../pdf/models/pdf_export_config.dart';

abstract class ResumeTemplate {
  String get id;
  String get name;
  String get description;
  String get previewThumbnail;
  bool get isAtsFriendly;

  Future<pw.Document> generatePdf(
    Resume resume,
    PdfPageFormat pageFormat, {
    PdfExportConfig? config,
  });
}
