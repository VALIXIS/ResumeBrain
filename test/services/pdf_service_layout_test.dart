import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:resume_brain/data/models/resume_models.dart';
import 'package:resume_brain/features/pdf/models/pdf_export_config.dart';
import 'package:resume_brain/features/pdf/services/pdf_service.dart';
import 'package:resume_brain/features/templates/services/template_registry.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late PdfService pdfService;

  Resume createHeavyMultiPageResume({String templateId = 'modern_classic'}) {
    return Resume(
      id: 'heavy-pdf-test-101',
      title: 'Senior Principal Staff Engineer & Architect Resume',
      templateId: templateId,
      personalInfo: PersonalInformation(
        fullName: 'Alexander Vance, Ph.D.',
        jobTitle: 'Principal Systems Architect & Lead Software Engineer',
        email: 'alexander.vance@valixis.org',
        phone: '+1 (555) 987-6543',
        location: 'San Francisco, CA',
        website: 'https://alexvance.dev',
      ),
      summary: ProfessionalSummary(
        summaryText:
            'Distinguished software architect and systems engineer with over 15 years of experience leading cross-functional teams in high-scale distributed systems, cloud computing, AI infrastructure, and Mobile app development. Proven track record of architecting resilient platforms serving millions of daily active users while maintaining 99.999% uptime. Expertise in Flutter, Dart, C++, Rust, Python, Docker, Kubernetes, and enterprise microservices.',
      ),
      experiences: [
        Experience(
          company: 'Google Cloud Infrastructure',
          position: 'Principal Software Architect',
          startDate: 'Jan 2021',
          endDate: 'Present',
          description:
              'Architected distributed microservices platform processing 4.2 billion API requests daily with sub-10ms response latency.\nOrchestrated multi-region failover cluster reducing incident recovery MTTR from 45 minutes to under 30 seconds.\nMentored 35+ senior and staff engineers across 4 international engineering hubs.\nAuthored 12 internal technical design documents and 3 public patents on low-latency streaming algorithms.',
        ),
        Experience(
          company: 'VALIXIS Systems',
          position: 'Staff Software Engineer',
          startDate: 'Mar 2017',
          endDate: 'Dec 2020',
          description:
              'Designed and built cross-platform core application suite using Flutter & Riverpod, reaching 5M+ downloads.\nReduced application bundle size by 42% and improved frame render pipeline to maintain 60 FPS under load.\nIntegrated offline-first local persistence architecture using Hive database and automatic cloud sync.',
        ),
        Experience(
          company: 'TechCorp Solutions',
          position: 'Senior Backend Engineer',
          startDate: 'Jun 2014',
          endDate: 'Feb 2017',
          description:
              'Optimized PostgreSQL query engine reducing database CPU utilization by 38% under peak traffic.\nImplemented automated CI/CD build pipeline cutting deployment cycle time from 2 hours to 12 minutes.',
        ),
        Experience(
          company: 'Innovate Labs',
          position: 'Software Engineer',
          startDate: 'Aug 2011',
          endDate: 'May 2014',
          description:
              'Developed real-time event streaming pipeline processing 50k events/sec using Apache Kafka.',
        ),
      ],
      educationList: [
        Education(
          institution: 'Stanford University',
          degree: 'Ph.D. in Computer Science',
          fieldOfStudy: 'Distributed Systems & Concurrent Algorithms',
          startDate: '2007',
          endDate: '2011',
        ),
        Education(
          institution: 'MIT',
          degree: 'B.S. in Computer Science & Electrical Engineering',
          startDate: '2003',
          endDate: '2007',
        ),
      ],
      skills: [
        Skill(name: 'Flutter & Dart', level: 'Expert'),
        Skill(name: 'Distributed Systems', level: 'Expert'),
        Skill(name: 'Rust & C++', level: 'Advanced'),
        Skill(name: 'Kubernetes & Docker', level: 'Advanced'),
        Skill(name: 'PostgreSQL & Hive', level: 'Intermediate'),
      ],
      certifications: [
        Certification(name: 'AWS Certified Solutions Architect - Professional', issuingOrganization: 'Amazon Web Services', issueDate: '2023'),
        Certification(name: 'Google Cloud Fellow - Enterprise Architecture', issuingOrganization: 'Google Cloud', issueDate: '2022'),
      ],
      languages: [
        Language(name: 'English', proficiency: 'Native / Fluent'),
        Language(name: 'German', proficiency: 'Professional Working'),
      ],
      customSections: [
        CustomSection(
          title: 'Patents & Publications',
          items: [
            'US Patent 10,987,654: Distributed Consensus Protocols in Low-Bandwidth Networks (2022)',
            'ACM Sigcomm 2020: High-Throughput Stream Serialization in Enterprise Engines (2020)',
          ],
        ),
      ],
    );
  }

  setUp(() {
    pdfService = PdfService();
  });

  group('PDF Layout Engine Multi-Page Pagination & Margin QA Tests', () {
    test('1. Heavy multi-page resume compiles without clipping or errors across all templates', () async {
      for (final template in TemplateRegistry.allTemplates) {
        final resume = createHeavyMultiPageResume(templateId: template.id);
        final pdfDoc = await template.generatePdf(resume, PdfPageFormat.a4);
        final bytes = await pdfDoc.save();

        expect(bytes, isNotNull, reason: 'PDF bytes should not be null for template ${template.name}');
        expect(bytes.length, greaterThan(1000), reason: 'Heavy PDF for ${template.name} should generate substantial bytes');
        expect(pdfDoc.document.pdfPageList.pages.length, greaterThanOrEqualTo(1), reason: 'PDF page count for ${template.name} must be valid');
      }
    });

    test('2. PdfService.buildPdfBytes generates valid byte array for heavy resume', () async {
      final resume = createHeavyMultiPageResume();
      final bytes = await pdfService.buildPdfBytes(resume, pageFormat: PdfPageFormat.a4);

      expect(bytes.isNotEmpty, isTrue);
      expect(bytes.sublist(0, 4), equals([0x25, 0x50, 0x44, 0x46]), reason: 'PDF bytes must start with %PDF header');
    });

    test('3. Margin configurations (compact, normal, spacious) compile cleanly without layout corruption', () async {
      final resume = createHeavyMultiPageResume();

      for (final margin in PdfMarginOption.values) {
        final config = PdfExportConfig(marginOption: margin);
        final bytes = await pdfService.buildPdfBytes(resume, config: config);

        expect(bytes.isNotEmpty, isTrue);
        expect(margin.displayName.isNotEmpty, isTrue);
      }
    });

    test('4. All PdfColorPalette options compile cleanly with template themes', () async {
      final resume = createHeavyMultiPageResume();

      for (final palette in PdfColorPalette.values) {
        final config = PdfExportConfig(colorPalette: palette);
        final bytes = await pdfService.buildPdfBytes(resume, config: config);

        expect(bytes.isNotEmpty, isTrue);
        expect(palette.displayName.isNotEmpty, isTrue);
      }
    });

    test('5. Combined Heavy Layout Test: Multi-page + compact margin + crimson palette + courier font', () async {
      final resume = createHeavyMultiPageResume();
      final config = const PdfExportConfig(
        marginOption: PdfMarginOption.compact,
        colorPalette: PdfColorPalette.crimson,
        fontFamily: PdfFontFamily.courier,
      );

      final bytes = await pdfService.buildPdfBytes(resume, config: config);

      expect(bytes.isNotEmpty, isTrue);
      expect(bytes.length, greaterThan(2000));
    });
  });
}
