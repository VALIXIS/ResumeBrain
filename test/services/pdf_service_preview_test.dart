import 'dart:io';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:resume_brain/data/models/resume_models.dart';
import 'package:resume_brain/features/pdf/models/pdf_export_config.dart';
import 'package:resume_brain/features/pdf/services/pdf_service.dart';
import 'package:resume_brain/features/templates/services/template_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/path_provider'),
      (MethodCall methodCall) async {
        return Directory.systemTemp.path;
      },
    );
  });

  late PdfService pdfService;
  late Resume sampleResume;

  setUp(() {
    pdfService = PdfService();
    sampleResume = Resume(
      id: 'preview-test-resume-101',
      title: 'Senior Software Engineer Resume',
      personalInfo: PersonalInformation(
        fullName: 'Taylor Morgan',
        jobTitle: 'Lead Flutter Developer',
        email: 'taylor@valixis.com',
        phone: '+1 555-0192',
        location: 'Austin, TX',
      ),
      summary: ProfessionalSummary(
        summaryText: 'Passionate software engineer specializing in mobile apps, high-performance UI, and automated QA testing.',
      ),
      experiences: [
        Experience(
          company: 'VALIXIS Technologies',
          position: 'Lead Flutter Developer',
          startDate: '2022',
          endDate: 'Present',
          description: 'Architected high-performance mobile software solutions.',
        ),
      ],
      skills: [
        Skill(name: 'Flutter & Dart'),
        Skill(name: 'PDF Rendering'),
      ],
    );
  });

  group('PDF Service Integrity & Preview Generation QA Tests', () {
    test('1. PdfService.buildPdfBytes produces valid %PDF binary output', () async {
      final bytes = await pdfService.buildPdfBytes(sampleResume);

      expect(bytes, isNotNull);
      expect(bytes.length, greaterThan(500));
      expect(String.fromCharCodes(bytes.sublist(0, 5)), equals('%PDF-'));
    });

    test('2. PdfService.savePdfFile creates document file with sanitized filename', () async {
      final bytes = await pdfService.buildPdfBytes(sampleResume);

      final file = await pdfService.savePdfFile(sampleResume, bytes);

      expect(await file.exists(), isTrue);
      expect(file.path, contains('Senior Software Engineer Resume_previe.pdf'));

      final readBytes = await file.readAsBytes();
      expect(readBytes.length, equals(bytes.length));

      // Cleanup generated file after test
      await file.delete();
    });

    test('3. Template Regression Test: All registered templates generate valid non-empty PDFs', () async {
      final templates = TemplateRegistry.allTemplates;
      expect(templates.length, equals(5));

      for (final template in templates) {
        final pdfDoc = await template.generatePdf(sampleResume, PdfPageFormat.a4);
        final bytes = await pdfDoc.save();

        expect(bytes.isNotEmpty, isTrue, reason: 'Template ${template.id} should generate bytes');
        expect(pdfDoc.document.pdfPageList.pages.isNotEmpty, isTrue, reason: 'Template ${template.id} should have pages');
      }
    });

    test('4. PDF integrity verification: PDF contains end-of-file trailer marker', () async {
      final bytes = await pdfService.buildPdfBytes(sampleResume);
      final pdfString = String.fromCharCodes(bytes.sublist(bytes.length - 100));

      expect(pdfString, contains('%%EOF'), reason: 'Valid PDF document must end with %%EOF marker');
    });

    test('5. PdfExportConfig presets map to expected insets and colors', () {
      expect(PdfMarginOption.compact.insets.bottom, equals(18));
      expect(PdfMarginOption.normal.insets.bottom, equals(36));
      expect(PdfMarginOption.spacious.insets.bottom, equals(54));

      expect(PdfColorPalette.indigo.pdfColor, isNotNull);
      expect(PdfColorPalette.teal.pdfColor, isNotNull);
      expect(PdfColorPalette.navy.pdfColor, isNotNull);
    });
  });
}
