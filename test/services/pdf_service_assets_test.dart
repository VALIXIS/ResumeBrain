import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:resume_brain/data/models/resume_models.dart';
import 'package:resume_brain/features/pdf/models/pdf_export_config.dart';
import 'package:resume_brain/features/pdf/services/pdf_service.dart';
import 'package:resume_brain/features/templates/services/template_registry.dart';

void main() {
  late PdfService pdfService;
  late Resume testResume;

  setUp(() {
    pdfService = PdfService();
    testResume = Resume(
      id: 'asset-test-resume-1',
      title: 'Vector & Font Test Resume',
      personalInfo: PersonalInformation(
        fullName: 'Jordan Miller',
        jobTitle: 'Senior UX Architect & Graphics Specialist',
        email: 'jordan@valixis.org',
        location: 'Seattle, WA',
      ),
      summary: ProfessionalSummary(
        summaryText: 'Specialist in vector graphics pipelines, typography rendering, and accessible document layout.',
      ),
      skills: [
        Skill(name: 'SVG Vector Graphics', level: 'Expert'),
        Skill(name: 'Typography System Design', level: 'Expert'),
        Skill(name: 'PDF Specification Standards', level: 'Advanced'),
      ],
    );
  });

  group('Vector Assets & Font Switching QA Tests', () {
    test('1. Custom font switching (Helvetica, Times, Courier) produces valid PDFs without exceptions', () async {
      for (final font in PdfFontFamily.values) {
        final config = PdfExportConfig(fontFamily: font);
        final bytes = await pdfService.buildPdfBytes(testResume, config: config);

        expect(bytes.isNotEmpty, isTrue, reason: 'Font ${font.displayName} should generate valid PDF bytes');
        expect(font.baseFont, isNotNull);
        expect(font.boldFont, isNotNull);
      }
    });

    test('2. PdfExportConfig themeData incorporates base and bold fonts cleanly', () {
      for (final font in PdfFontFamily.values) {
        final config = PdfExportConfig(fontFamily: font);
        final theme = config.themeData;

        expect(theme.defaultTextStyle.font, isNotNull);
      }
    });

    test('3. Vector graphics structures (shapes, borders, dividers) compile cleanly across all templates', () async {
      for (final template in TemplateRegistry.allTemplates) {
        final pdfDoc = await template.generatePdf(testResume, PdfPageFormat.a4);
        final bytes = await pdfDoc.save();

        expect(bytes.isNotEmpty, isTrue);
        expect(pdfDoc.document.pdfPageList.pages.length, greaterThanOrEqualTo(1));
      }
    });

    test('4. Font switching does not corrupt layout when combined with custom margins and palettes', () async {
      final config = const PdfExportConfig(
        fontFamily: PdfFontFamily.times,
        marginOption: PdfMarginOption.compact,
        colorPalette: PdfColorPalette.navy,
      );

      final bytes = await pdfService.buildPdfBytes(testResume, config: config);
      expect(bytes.isNotEmpty, isTrue);
    });

    test('5. Multi-font compilation stability test', () async {
      final doc = pw.Document(theme: pw.ThemeData.withFont(base: pw.Font.courier(), bold: pw.Font.courierBold()));
      doc.addPage(
        pw.Page(
          build: (context) => pw.Center(
            child: pw.Text('Courier Monospace Text Engine Test'),
          ),
        ),
      );

      final bytes = await doc.save();
      expect(bytes.isNotEmpty, isTrue);
      expect(bytes.sublist(0, 4), equals([0x25, 0x50, 0x44, 0x46]));
    });
  });
}
