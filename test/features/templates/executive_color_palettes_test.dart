import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:resume_brain/data/models/resume_models.dart';
import 'package:resume_brain/features/pdf/models/pdf_export_config.dart';
import 'package:resume_brain/features/templates/services/template_registry.dart';

void main() {
  group('Executive Color Palettes & Laser Printer Contrast QA Tests', () {
    final sampleResume = Resume(
      id: 'exec-palette-test-resume',
      title: 'Executive Resume',
      templateId: 'executive_minimal',
      personalInfo: PersonalInformation(
        fullName: 'Alexander Hamilton',
        jobTitle: 'Chief Executive Officer',
        email: 'alexander@treasury.gov',
        phone: '+1 (555) 019-2834',
        location: 'New York, NY',
        website: 'https://hamilton.org',
      ),
      summary: ProfessionalSummary(
        summaryText:
            'Accomplished executive leader with 18+ years driving organizational transformation, fiscal policy, and scalable enterprise architecture.',
      ),
      experiences: [
        Experience(
          company: 'First Bank of the United States',
          position: 'Secretary & Founding Executive',
          startDate: '1789',
          endDate: '1795',
          description:
              'Established modern financial system and national credit infrastructure.\nInstituted rigorous accounting controls and auditing standards across 13 states.\nDirected institutional capitalization exceeding \$10M in gold and silver reserve.',
        ),
      ],
      educationList: [
        Education(
          institution: "King's College (Columbia University)",
          degree: 'Master of Laws & Commerce',
          startDate: '1774',
          endDate: '1776',
        ),
      ],
      skills: [
        Skill(name: 'Executive Leadership'),
        Skill(name: 'Financial Engineering'),
        Skill(name: 'Strategic Operations'),
      ],
      certifications: [
        Certification(name: 'Chartered Financial Leader (CFL)'),
      ],
      languages: [
        Language(name: 'English', proficiency: 'Native'),
        Language(name: 'French', proficiency: 'Fluent'),
      ],
    );

    test('1. All executive palettes achieve WCAG AA/AAA contrast on standard white paper (>= 4.5:1)', () {
      final palettes = [
        ExecutivePalette.navy,
        ExecutivePalette.charcoal,
        ExecutivePalette.burgundy,
        ExecutivePalette.emerald,
        ExecutivePalette.teal,
        ExecutivePalette.steelBlue,
        ExecutivePalette.crimson,
        ExecutivePalette.indigo,
        ExecutivePalette.purple,
        ExecutivePalette.espresso,
        ExecutivePalette.monochrome,
      ];

      for (final p in palettes) {
        expect(p.hasHighWhitePaperContrast, isTrue,
            reason: '${p.name} accent must maintain contrast ratio >= 4.5:1 on white paper');
        expect(p.contrastRatioOnWhite, greaterThanOrEqualTo(4.5),
            reason: '${p.name} contrast ratio was ${p.contrastRatioOnWhite}');
        expect(ExecutivePalette.calculateContrastRatioOnWhite(p.text), greaterThanOrEqualTo(10.0),
            reason: '${p.name} body text must maintain high readability on white paper');
        expect(ExecutivePalette.calculateContrastRatioOnWhite(p.mutedText), greaterThanOrEqualTo(6.0),
            reason: '${p.name} muted details (dates, locations) must maintain high readability on white paper');
      }
    });

    test('2. All executive palettes meet black-and-white office laser printer density requirements (>= 0.55)', () {
      final palettes = [
        ExecutivePalette.navy,
        ExecutivePalette.charcoal,
        ExecutivePalette.burgundy,
        ExecutivePalette.emerald,
        ExecutivePalette.teal,
        ExecutivePalette.steelBlue,
        ExecutivePalette.crimson,
        ExecutivePalette.indigo,
        ExecutivePalette.purple,
        ExecutivePalette.espresso,
        ExecutivePalette.monochrome,
      ];

      for (final p in palettes) {
        expect(p.isLaserPrinterSafe, isTrue,
            reason: '${p.name} accent must maintain dark toner density (>= 0.55) to avoid faint dithering on laser printers');
        expect(p.laserPrinterDensity, greaterThanOrEqualTo(0.55),
            reason: '${p.name} laser toner density was ${p.laserPrinterDensity}');
        expect(ExecutivePalette.calculateLaserPrinterDensity(p.mutedText), greaterThanOrEqualTo(0.55),
            reason: '${p.name} muted text must not fade out into unreadable gray speckles on monochrome printers');
      }
    });

    test('3. PdfColorPalette enum maps each palette with valid displayName, uiColor, and executive tokens', () {
      for (final palette in PdfColorPalette.values) {
        expect(palette.displayName.isNotEmpty, isTrue);
        expect(palette.uiColor, isNotNull);

        if (palette == PdfColorPalette.templateDefault) {
          expect(palette.executivePalette, isNull);
          expect(palette.pdfColor, isNull);
        } else {
          expect(palette.executivePalette, isNotNull);
          expect(palette.pdfColor, isNotNull);
          expect(palette.paletteColors, equals(palette.executivePalette));
        }
      }
    });

    test('4. All 7 template implementations compile and render with each executive color palette', () async {
      final executivePalettes = PdfColorPalette.values
          .where((p) => p != PdfColorPalette.templateDefault)
          .toList();

      for (final template in TemplateRegistry.allTemplates) {
        for (final palette in executivePalettes) {
          final config = PdfExportConfig(colorPalette: palette);
          final doc = await template.generatePdf(
            sampleResume.copyWith(templateId: template.id),
            PdfPageFormat.a4,
            config: config,
          );

          final bytes = await doc.save();
          expect(bytes, isNotEmpty,
              reason: 'Template ${template.name} failed to generate PDF with palette ${palette.displayName}');
          expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
        }
      }
    });
  });
}
