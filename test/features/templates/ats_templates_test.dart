import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:resume_brain/data/models/resume_models.dart';
import 'package:resume_brain/features/pdf/models/pdf_export_config.dart';
import 'package:resume_brain/features/templates/academic_clean_template.dart';
import 'package:resume_brain/features/templates/executive_minimal_template.dart';
import 'package:resume_brain/features/templates/services/template_registry.dart';
import 'package:resume_brain/features/templates/tech_modern_template.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Resume buildComprehensiveResume({
    String templateId = 'modern_classic',
  }) {
    return Resume(
      id: 'ats-test-resume-101',
      title: 'Senior Principal Engineering Leader & Academic Researcher',
      templateId: templateId,
      personalInfo: PersonalInformation(
        fullName: 'Dr. Krishna Vance, Ph.D.',
        jobTitle: 'Principal Systems Architect & Research Director',
        email: 'krishna.vance@valixis.ai',
        phone: '+1 (555) 432-8765',
        location: 'San Francisco, CA & Zurich, Switzerland',
        website: 'https://krishnavance.valixis.ai',
      ),
      summary: ProfessionalSummary(
        summaryText:
            'Distinguished technology leader and systems researcher with 16+ years designing mission-critical distributed systems, high-throughput streaming pipelines, and enterprise Flutter applications. Author of 14 peer-reviewed publications on concurrent memory safety and deterministic fault-tolerant consensus.',
      ),
      experiences: [
        Experience(
          company: 'VALIXIS Distributed Systems Group',
          position: 'Principal Architect & VP of Engineering',
          startDate: 'Jan 2021',
          endDate: 'Present',
          description:
              'Spearheaded the core platform architecture handling 100M+ real-time streaming transactions daily.\nDirected 4 distributed engineering pods across North America and Europe.\nArchitected low-latency microservices with sub-5ms P99 latency.',
        ),
        Experience(
          company: 'NextGen Cloud Infrastructure',
          position: 'Lead Staff Software Engineer',
          startDate: 'Mar 2017',
          endDate: 'Dec 2020',
          description:
              'Engineered offline-first state synchronization engine with cryptographic integrity verification.\nReduced system infrastructure costs by 45% through optimized resource scheduling.',
        ),
        Experience(
          company: 'Global Software Labs',
          position: 'Senior Software Engineer',
          startDate: 'Jun 2013',
          endDate: 'Feb 2017',
          description:
              'Designed REST and gRPC microservice APIs servicing 15 enterprise banking clients.',
        ),
      ],
      educationList: [
        Education(
          institution: 'ETH Zurich',
          degree: 'Ph.D. in Computer Science',
          fieldOfStudy: 'Distributed Consensus & Formal Verification',
          startDate: '2009',
          endDate: '2013',
        ),
        Education(
          institution: 'MIT',
          degree: 'B.S. in Electrical Engineering & Computer Science',
          fieldOfStudy: 'Computer Systems',
          startDate: '2005',
          endDate: '2009',
        ),
      ],
      skills: [
        Skill(name: 'Flutter & Dart', level: 'Expert'),
        Skill(name: 'Rust & C++', level: 'Expert'),
        Skill(name: 'Distributed Systems', level: 'Expert'),
        Skill(name: 'Kubernetes & Docker', level: 'Advanced'),
        Skill(name: 'Formal Methods (TLA+)', level: 'Advanced'),
        Skill(name: 'PostgreSQL & SQL', level: 'Intermediate'),
      ],
      certifications: [
        Certification(
          name: 'AWS Certified Solutions Architect - Professional',
          issuingOrganization: 'Amazon Web Services',
          issueDate: '2023',
        ),
        Certification(
          name: 'Google Cloud Certified Professional Cloud Architect',
          issuingOrganization: 'Google Cloud',
          issueDate: '2022',
        ),
      ],
      languages: [
        Language(name: 'English', proficiency: 'Native / Bilingual'),
        Language(name: 'German', proficiency: 'Professional Working'),
        Language(name: 'French', proficiency: 'Elementary'),
      ],
      customSections: [
        CustomSection(
          title: 'Peer-Reviewed Publications & Grants',
          items: [
            'ACM TOCS 2023: "Deterministic Vector Replication in Asynchronous Distributed Stores"',
            'IEEE Transactions on Software Engineering 2021: "Zero-Cost Memory Bounds for Realtime Kernels"',
            'EU Horizon 2020 Research Grant (EUR 1.8M): Principal Investigator on Autonomous Edge Mesh Networks',
          ],
        ),
        CustomSection(
          title: 'Selected Keynote Addresses',
          items: [
            'Keynote: "The Future of Type-Safe Systems at Scale", Strange Loop, St. Louis (2022)',
            'Invited Talk: "Cross-Platform High Performance Rendering", FOSDEM, Brussels (2021)',
          ],
        ),
      ],
    );
  }

  group('RSM-02 New ATS Standard Templates Tests', () {
    test('TemplateRegistry correctly discovers and registers all 3 ATS templates', () {
      final templates = TemplateRegistry.allTemplates;
      final ids = templates.map((t) => t.id).toList();

      expect(ids, contains('executive_minimal'));
      expect(ids, contains('tech_modern'));
      expect(ids, contains('academic_clean'));

      final execTemplate = TemplateRegistry.getTemplateById('executive_minimal');
      expect(execTemplate, isNotNull);
      expect(execTemplate.name, equals('Executive Minimal'));
      expect(execTemplate.isAtsFriendly, isTrue);

      final techTemplate = TemplateRegistry.getTemplateById('tech_modern');
      expect(techTemplate, isNotNull);
      expect(techTemplate.name, equals('Tech Modern'));
      expect(techTemplate.isAtsFriendly, isTrue);

      final academicTemplate = TemplateRegistry.getTemplateById('academic_clean');
      expect(academicTemplate, isNotNull);
      expect(academicTemplate.name, equals('Academic Clean'));
      expect(academicTemplate.isAtsFriendly, isTrue);
    });

    test('ExecutiveMinimalTemplate generates valid non-empty PDF document bytes', () async {
      final template = ExecutiveMinimalTemplate();
      final resume = buildComprehensiveResume(templateId: 'executive_minimal');

      final doc = await template.generatePdf(
        resume,
        PdfPageFormat.a4,
        config: const PdfExportConfig(
          fontFamily: PdfFontFamily.times,
          marginOption: PdfMarginOption.compact,
          colorPalette: PdfColorPalette.charcoal,
        ),
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
      // PDF header validation: starts with %PDF-
      final header = String.fromCharCodes(bytes.take(5));
      expect(header, equals('%PDF-'));
    });

    test('TechModernTemplate generates valid non-empty PDF document bytes with custom options', () async {
      final template = TechModernTemplate();
      final resume = buildComprehensiveResume(templateId: 'tech_modern');

      final doc = await template.generatePdf(
        resume,
        PdfPageFormat.letter,
        config: const PdfExportConfig(
          fontFamily: PdfFontFamily.helvetica,
          marginOption: PdfMarginOption.normal,
          colorPalette: PdfColorPalette.navy,
        ),
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
      final header = String.fromCharCodes(bytes.take(5));
      expect(header, equals('%PDF-'));
    });

    test('AcademicCleanTemplate generates valid non-empty PDF document bytes', () async {
      final template = AcademicCleanTemplate();
      final resume = buildComprehensiveResume(templateId: 'academic_clean');

      final doc = await template.generatePdf(
        resume,
        PdfPageFormat.a4,
        config: const PdfExportConfig(
          fontFamily: PdfFontFamily.courier,
          marginOption: PdfMarginOption.spacious,
          colorPalette: PdfColorPalette.teal,
        ),
      );

      final bytes = await doc.save();
      expect(bytes, isNotEmpty);
      expect(bytes.length, greaterThan(1000));
      final header = String.fromCharCodes(bytes.take(5));
      expect(header, equals('%PDF-'));
    });

    test('Templates gracefully handle empty optional fields without crashing', () async {
      final minimalResume = Resume(
        id: 'minimal-resume-test',
        title: 'Minimal Resume',
        templateId: 'tech_modern',
        personalInfo: PersonalInformation(
          fullName: 'Jane Doe',
          jobTitle: 'Software Engineer',
          email: 'jane@example.com',
          phone: '',
          location: '',
        ),
        summary: ProfessionalSummary(summaryText: ''),
        experiences: [],
        educationList: [],
        skills: [],
        certifications: [],
        languages: [],
        customSections: [],
      );

      for (final template in [
        ExecutiveMinimalTemplate(),
        TechModernTemplate(),
        AcademicCleanTemplate(),
      ]) {
        final doc = await template.generatePdf(
          minimalResume,
          PdfPageFormat.a4,
        );
        final bytes = await doc.save();
        expect(bytes, isNotEmpty);
        expect(String.fromCharCodes(bytes.take(5)), equals('%PDF-'));
      }
    });
  });
}
