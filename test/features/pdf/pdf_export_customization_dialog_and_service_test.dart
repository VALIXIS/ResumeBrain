import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:resume_brain/data/models/resume_models.dart';
import 'package:resume_brain/features/pdf/models/pdf_export_config.dart';
import 'package:resume_brain/features/pdf/services/pdf_service.dart';
import 'package:resume_brain/features/pdf/widgets/pdf_export_customization_dialog.dart';
import 'package:resume_brain/features/templates/services/template_registry.dart';

void main() {
  group('PdfExportConfig Model & Formatting Tests', () {
    test('1. Default values are correctly initialized', () {
      const config = PdfExportConfig();
      expect(config.marginOption, equals(PdfMarginOption.normal));
      expect(config.colorPalette, equals(PdfColorPalette.templateDefault));
      expect(config.fontFamily, equals(PdfFontFamily.helvetica));
      expect(config.showPageNumbers, isTrue);
      expect(config.contactIconStyle, equals(PdfContactIconStyle.icon));
      expect(config.dateFormat, equals(PdfDateFormat.monthYear));
    });

    test('2. copyWith correctly updates individual settings', () {
      const config = PdfExportConfig();

      final updated = config.copyWith(
        showPageNumbers: false,
        contactIconStyle: PdfContactIconStyle.text,
        dateFormat: PdfDateFormat.numericMonthYear,
      );

      expect(updated.showPageNumbers, isFalse);
      expect(updated.contactIconStyle, equals(PdfContactIconStyle.text));
      expect(updated.dateFormat, equals(PdfDateFormat.numericMonthYear));
      expect(updated.marginOption, equals(config.marginOption));
      expect(updated.colorPalette, equals(config.colorPalette));
      expect(updated.fontFamily, equals(config.fontFamily));
    });

    test('3. Value equality and hashCode work as expected', () {
      const config1 = PdfExportConfig(
        showPageNumbers: false,
        contactIconStyle: PdfContactIconStyle.text,
        dateFormat: PdfDateFormat.numericMonthYear,
      );
      const config2 = PdfExportConfig(
        showPageNumbers: false,
        contactIconStyle: PdfContactIconStyle.text,
        dateFormat: PdfDateFormat.numericMonthYear,
      );
      const config3 = PdfExportConfig(
        showPageNumbers: true,
        contactIconStyle: PdfContactIconStyle.icon,
        dateFormat: PdfDateFormat.monthYear,
      );

      expect(config1, equals(config2));
      expect(config1.hashCode, equals(config2.hashCode));
      expect(config1 == config3, isFalse);
      expect(config1.toString(), contains('pageNumbers: false'));
      expect(config1.toString(), contains('contactIcons: PdfContactIconStyle.text'));
      expect(config1.toString(), contains('dateFormat: PdfDateFormat.numericMonthYear'));
    });

    test('4. Date formatting helper formats MM/YYYY and Month YYYY reliably', () {
      // Month YYYY (default)
      expect(PdfExportConfig.formatDate('2021-01', PdfDateFormat.monthYear), equals('Jan 2021'));
      expect(PdfExportConfig.formatDate('05/2023', PdfDateFormat.monthYear), equals('May 2023'));
      expect(PdfExportConfig.formatDate('March 2020', PdfDateFormat.monthYear), equals('Mar 2020'));
      expect(PdfExportConfig.formatDate('2022', PdfDateFormat.monthYear), equals('2022'));
      expect(PdfExportConfig.formatDate('Present', PdfDateFormat.monthYear), equals('Present'));
      expect(PdfExportConfig.formatDate('', PdfDateFormat.monthYear), equals(''));

      // Numeric MM/YYYY
      expect(PdfExportConfig.formatDate('Jan 2021', PdfDateFormat.numericMonthYear), equals('01/2021'));
      expect(PdfExportConfig.formatDate('2021-05', PdfDateFormat.numericMonthYear), equals('05/2021'));
      expect(PdfExportConfig.formatDate('5/2023', PdfDateFormat.numericMonthYear), equals('05/2023'));
      expect(PdfExportConfig.formatDate('December 2024', PdfDateFormat.numericMonthYear), equals('12/2024'));
      expect(PdfExportConfig.formatDate('2022', PdfDateFormat.numericMonthYear), equals('2022'));
      expect(PdfExportConfig.formatDate('Present', PdfDateFormat.numericMonthYear), equals('Present'));
    });

    test('5. Date range helper handles current positions and single dates', () {
      expect(
        PdfExportConfig.formatDateRange(
          startDate: 'Jan 2021',
          endDate: '',
          isCurrent: true,
          format: PdfDateFormat.numericMonthYear,
        ),
        equals('01/2021 - Present'),
      );

      expect(
        PdfExportConfig.formatDateRange(
          startDate: '2021-01',
          endDate: '2023-08',
          isCurrent: false,
          format: PdfDateFormat.monthYear,
        ),
        equals('Jan 2021 - Aug 2023'),
      );
    });

    test('6. PdfService contact list formatting handles text vs icon style', () {
      final resume = Resume(
        personalInfo: PersonalInformation(
          fullName: 'Jane Doe',
          email: 'jane@example.com',
          phone: '+1 555-0199',
          location: 'San Francisco, CA',
          website: 'https://janedoe.dev',
        ),
      );

      final iconItems = PdfService.formatContactList(resume, style: PdfContactIconStyle.icon);
      expect(iconItems, contains('jane@example.com'));
      expect(iconItems, contains('+1 555-0199'));
      expect(iconItems.any((item) => item.startsWith('Email:')), isFalse);

      final textItems = PdfService.formatContactList(resume, style: PdfContactIconStyle.text);
      expect(textItems, contains('Email: jane@example.com'));
      expect(textItems, contains('Phone: +1 555-0199'));
      expect(textItems, contains('Location: San Francisco, CA'));
      expect(textItems, contains('Website: https://janedoe.dev'));
    });
  });

  group('PdfExportCustomizationDialog UI Tests', () {
    testWidgets('Renders all customization switches and updates settings interactively', (tester) async {
      PdfExportConfig? returnedConfig;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  returnedConfig = await showDialog<PdfExportConfig>(
                    context: context,
                    builder: (context) => const PdfExportCustomizationDialog(
                      initialConfig: PdfExportConfig(),
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open Dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Verify title and section headers
      expect(find.text('Customize PDF Export'), findsOneWidget);
      expect(find.text('Page Margins'), findsOneWidget);
      expect(find.text('Color Palette / Accent'), findsOneWidget);
      expect(find.text('Font Family'), findsOneWidget);

      // Scroll to reveal the switches and verify sections
      final switches = find.byType(Switch);
      expect(switches, findsNWidgets(3));

      // Toggle Page Numbering off
      await tester.ensureVisible(switches.at(0));
      await tester.pumpAndSettle();
      expect(find.text('Page Numbering'), findsOneWidget);
      expect(find.text('Page Numbers (e.g. Page 1 of 2)'), findsOneWidget);
      await tester.tap(switches.at(0));
      await tester.pumpAndSettle();
      expect(find.text('Page numbering disabled in document footer'), findsOneWidget);

      // Toggle Contact Display Style to Text
      await tester.ensureVisible(switches.at(1));
      await tester.pumpAndSettle();
      expect(find.text('Contact Icon Style'), findsOneWidget);
      expect(find.text('Contact Display Style'), findsOneWidget);
      await tester.tap(switches.at(1));
      await tester.pumpAndSettle();
      expect(find.text('Text labels (e.g. Email:, Phone:)'), findsOneWidget);

      // Toggle Date Format to Numeric MM/YYYY
      await tester.ensureVisible(switches.at(2));
      await tester.pumpAndSettle();
      expect(find.text('Date Format'), findsOneWidget);
      expect(find.text('Numeric Date Format (MM/YYYY)'), findsOneWidget);
      await tester.tap(switches.at(2));
      await tester.pumpAndSettle();
      expect(find.text('MM/YYYY (e.g. 05/2023 - Present)'), findsOneWidget);

      // Apply & Export
      await tester.tap(find.text('Apply & Export'));
      await tester.pumpAndSettle();

      expect(returnedConfig, isNotNull);
      expect(returnedConfig!.showPageNumbers, isFalse);
      expect(returnedConfig!.contactIconStyle, equals(PdfContactIconStyle.text));
      expect(returnedConfig!.dateFormat, equals(PdfDateFormat.numericMonthYear));
    });

    testWidgets('Reset button restores default settings in dialog', (tester) async {
      PdfExportConfig? returnedConfig;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () async {
                  returnedConfig = await showDialog<PdfExportConfig>(
                    context: context,
                    builder: (context) => const PdfExportCustomizationDialog(
                      initialConfig: PdfExportConfig(
                        showPageNumbers: false,
                        contactIconStyle: PdfContactIconStyle.text,
                        dateFormat: PdfDateFormat.numericMonthYear,
                      ),
                    ),
                  );
                },
                child: const Text('Open Dialog'),
              ),
            ),
          ),
        ),
      );

      // Open Dialog
      await tester.tap(find.text('Open Dialog'));
      await tester.pumpAndSettle();

      // Click Reset
      await tester.tap(find.text('Reset'));
      await tester.pumpAndSettle();

      // Apply & Export
      await tester.tap(find.text('Apply & Export'));
      await tester.pumpAndSettle();

      expect(returnedConfig, isNotNull);
      expect(returnedConfig!.showPageNumbers, isTrue);
      expect(returnedConfig!.contactIconStyle, equals(PdfContactIconStyle.icon));
      expect(returnedConfig!.dateFormat, equals(PdfDateFormat.monthYear));
      expect(returnedConfig!.marginOption, equals(PdfMarginOption.normal));
      expect(returnedConfig!.colorPalette, equals(PdfColorPalette.templateDefault));
      expect(returnedConfig!.fontFamily, equals(PdfFontFamily.helvetica));
    });
  });

  group('Dynamic PDF Compilation Across Templates with Customization Settings', () {
    final testResume = Resume(
      id: 'dynamic-customization-test',
      title: 'Full Resume',
      personalInfo: PersonalInformation(
        fullName: 'Dr. Evelyn Reed',
        jobTitle: 'Principal Research Scientist',
        email: 'evelyn.reed@lab.org',
        phone: '+1 (555) 349-9281',
        location: 'Boston, MA',
        website: 'https://evelynreed.org',
      ),
      summary: ProfessionalSummary(
        summaryText:
            'Dedicated research scientist specializing in distributed systems, computational physics, and machine learning.',
      ),
      experiences: [
        Experience(
          company: 'Applied Science Institute',
          position: 'Lead AI Researcher',
          startDate: '2021-03',
          endDate: '',
          isCurrent: true,
          description: 'Pioneered neuro-symbolic algorithms.\nPublished 6 peer-reviewed papers.',
        ),
        Experience(
          company: 'Quantum Dynamics Corp',
          position: 'Research Associate',
          startDate: '2018-09',
          endDate: '2021-02',
          isCurrent: false,
          description: 'Designed quantum simulation kernels.\nOptimized linear algebra pipelines.',
        ),
      ],
      educationList: [
        Education(
          institution: 'Massachusetts Institute of Technology',
          degree: 'Ph.D. in Computer Science',
          startDate: '2014',
          endDate: '2018',
        ),
      ],
      skills: [
        Skill(name: 'Python'),
        Skill(name: 'Rust'),
        Skill(name: 'PyTorch'),
      ],
    );

    final templates = TemplateRegistry.allTemplates;
    final pdfService = PdfService();

    for (final template in templates) {
      test('Template "${template.name}" generates valid PDF with numeric dates and text contacts', () async {
        final config = const PdfExportConfig(
          showPageNumbers: false,
          contactIconStyle: PdfContactIconStyle.text,
          dateFormat: PdfDateFormat.numericMonthYear,
        );

        final resumeWithTemplate = testResume.copyWith(templateId: template.id);
        final bytes = await pdfService.buildPdfBytes(
          resumeWithTemplate,
          pageFormat: PdfPageFormat.a4,
          config: config,
        );

        expect(bytes, isNotNull);
        expect(bytes.isNotEmpty, isTrue);
        // Valid PDF magic header %PDF-
        expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
      });

      test('Template "${template.name}" generates valid PDF with page numbers and icon contacts', () async {
        final config = const PdfExportConfig(
          showPageNumbers: true,
          contactIconStyle: PdfContactIconStyle.icon,
          dateFormat: PdfDateFormat.monthYear,
        );

        final resumeWithTemplate = testResume.copyWith(templateId: template.id);
        final bytes = await pdfService.buildPdfBytes(
          resumeWithTemplate,
          pageFormat: PdfPageFormat.a4,
          config: config,
        );

        expect(bytes, isNotNull);
        expect(bytes.isNotEmpty, isTrue);
        expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
      });
    }
  });
}
