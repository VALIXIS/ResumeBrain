import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:resume_brain/data/models/resume_models.dart';
import 'package:resume_brain/features/templates/implementations/academic_cv_template.dart';
import 'package:resume_brain/features/templates/implementations/creative_professional_template.dart';
import 'package:resume_brain/features/templates/implementations/executive_minimal_template.dart';
import 'package:resume_brain/features/templates/implementations/modern_classic_template.dart';
import 'package:resume_brain/features/templates/implementations/tech_specialist_template.dart';
import 'package:resume_brain/features/templates/services/template_registry.dart';

void main() {
  group('Resume Data Model Tests', () {
    test('Resume default model creation and copyWith', () {
      final resume = Resume(title: 'Software Engineer Resume');
      expect(resume.title, 'Software Engineer Resume');
      expect(resume.templateId, 'modern_classic');

      final updated = resume.copyWith(
        personalInfo: PersonalInformation(
          fullName: 'Jane Doe',
          jobTitle: 'Senior Developer',
          email: 'jane@valixis.com',
        ),
      );

      expect(updated.personalInfo.fullName, 'Jane Doe');
      expect(updated.personalInfo.jobTitle, 'Senior Developer');
      expect(updated.personalInfo.email, 'jane@valixis.com');
    });

    test('Resume serialization toMap and fromMap', () {
      final original = Resume(
        title: 'Cloud Architect',
        personalInfo: PersonalInformation(
          fullName: 'John Smith',
          jobTitle: 'Cloud Architect',
          email: 'john@valixis.com',
          location: 'New York, NY',
        ),
        experiences: [
          Experience(
            company: 'VALIXIS Tech',
            position: 'Lead Architect',
            startDate: '2022',
            endDate: 'Present',
            isCurrent: true,
            description: 'Designed microservices architecture',
          ),
        ],
        skills: [
          Skill(name: 'Flutter'),
          Skill(name: 'Dart'),
        ],
      );

      final map = original.toMap();
      final restored = Resume.fromMap(map);

      expect(restored.id, original.id);
      expect(restored.title, 'Cloud Architect');
      expect(restored.personalInfo.fullName, 'John Smith');
      expect(restored.experiences.length, 1);
      expect(restored.experiences.first.company, 'VALIXIS Tech');
      expect(restored.skills.length, 2);
    });
  });

  group('Template Registry & PDF Rendering Tests', () {
    test(
      'TemplateRegistry returns all templates including Academic CV',
      () {
        final templates = TemplateRegistry.allTemplates;
        expect(templates.length, 5);
        expect(
          templates.map((t) => t.id),
          containsAll([
            'modern_classic',
            'executive_minimal',
            'creative_professional',
            'tech_specialist',
            'academic_cv',
          ]),
        );
      },
    );

    test('ModernClassicTemplate PDF compiles cleanly', () async {
      final template = ModernClassicTemplate();
      final resume = Resume(
        title: 'Test Resume',
        personalInfo: PersonalInformation(
          fullName: 'Alice Developer',
          jobTitle: 'Mobile Lead',
          email: 'alice@test.com',
        ),
      );

      final pdfDoc = await template.generatePdf(resume, PdfPageFormat.a4);
      final pdfBytes = await pdfDoc.save();

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);
    });

    test('ExecutiveMinimalTemplate PDF compiles cleanly', () async {
      final template = ExecutiveMinimalTemplate();
      final resume = Resume(
        title: 'Executive Resume',
        personalInfo: PersonalInformation(
          fullName: 'Robert Executive',
          jobTitle: 'Chief Technology Officer',
        ),
      );

      final pdfDoc = await template.generatePdf(resume, PdfPageFormat.a4);
      final pdfBytes = await pdfDoc.save();

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);
    });

    test('CreativeProfessionalTemplate PDF compiles cleanly', () async {
      final template = CreativeProfessionalTemplate();
      final resume = Resume(
        title: 'Creative Resume',
        personalInfo: PersonalInformation(
          fullName: 'Vaseem Developer',
          jobTitle: 'PDF Engine Specialist',
          email: 'vaseem@valixis.com',
        ),
        skills: [
          Skill(name: 'Vector Graphics'),
          Skill(name: 'PDF Layouts'),
        ],
      );

      final pdfDoc = await template.generatePdf(resume, PdfPageFormat.a4);
      final pdfBytes = await pdfDoc.save();

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.isNotEmpty, isTrue);
    });

    test(
      'TechSpecialistTemplate PDF compiles cleanly with comprehensive tech resume',
      () async {
        final template = TechSpecialistTemplate();
        final resume = Resume(
          title: 'Senior Tech Specialist Resume',
          templateId: 'tech_specialist',
          personalInfo: PersonalInformation(
            fullName: 'Alex Vance',
            jobTitle: 'Principal Cloud Systems Engineer',
            email: 'alex.vance@valixis.com',
            phone: '+1 (555) 019-2834',
            location: 'San Francisco, CA',
            website: 'https://alexvance.dev',
          ),
          socialLinks: [
            SocialLink(platform: 'GitHub', url: 'github.com/alexvance'),
            SocialLink(platform: 'LinkedIn', url: 'linkedin.com/in/alexvance'),
          ],
          summary: ProfessionalSummary(
            summaryText:
                'Senior Cloud Engineer with 8+ years designing high-throughput microservices, Kubernetes clusters, and automated CI/CD pipelines.',
          ),
          skills: [
            Skill(name: 'Go', level: 'Expert'),
            Skill(name: 'Python', level: 'Expert'),
            Skill(name: 'Rust', level: 'Intermediate'),
            Skill(name: 'Flutter & Dart', level: 'Advanced'),
            Skill(name: 'Docker & Kubernetes', level: 'Expert'),
            Skill(name: 'AWS / GCP Cloud Architecture', level: 'Expert'),
            Skill(name: 'PostgreSQL & Redis', level: 'Advanced'),
            Skill(name: 'Terraform & Ansible', level: 'Expert'),
          ],
          experiences: [
            Experience(
              company: 'Valixis Systems',
              position: 'Lead Systems Architect',
              location: 'San Francisco, CA',
              startDate: '2022',
              endDate: 'Present',
              isCurrent: true,
              description:
                  'Architected distributed cloud engine scaling to 5M daily active users with 99.99% availability. Reduced infrastructure latency by 45%.',
            ),
            Experience(
              company: 'TechCorp Solutions',
              position: 'Senior DevOps Engineer',
              location: 'Austin, TX',
              startDate: '2019',
              endDate: '2022',
              isCurrent: false,
              description:
                  'Built automated deployment pipelines using GitHub Actions and Kubernetes, decreasing deployment failure rate by 60%.',
            ),
          ],
          projects: [
            Project(
              name: 'Resume Brain PDF Engine',
              role: 'Lead Developer',
              link: 'github.com/valixis/resumebrain',
              description:
                  'High-performance PDF generation layout engine supporting multi-page pagination and custom ATS resume themes.',
              technologies: 'Flutter, Dart, PDF Engine, SQLite, Riverpod',
            ),
            Project(
              name: 'KubeWatch Micro-Monitor',
              role: 'Creator & Maintainer',
              link: 'github.com/alexvance/kubewatch',
              description:
                  'Open-source cluster resource monitor with real-time alert routing.',
              technologies: 'Go, Kubernetes API, Prometheus, Grafana, Docker',
            ),
          ],
          educationList: [
            Education(
              institution: 'University of California, Berkeley',
              degree: 'Bachelor of Science',
              fieldOfStudy: 'Computer Science',
              location: 'Berkeley, CA',
              startDate: '2015',
              endDate: '2019',
              gpa: '3.88',
            ),
          ],
          certifications: [
            Certification(
              name: 'AWS Certified Solutions Architect - Professional',
              issuingOrganization: 'Amazon Web Services',
              issueDate: '2024',
            ),
            Certification(
              name: 'Certified Kubernetes Administrator (CKA)',
              issuingOrganization: 'Linux Foundation',
              issueDate: '2023',
            ),
          ],
          languages: [
            Language(name: 'English', proficiency: 'Native'),
            Language(name: 'German', proficiency: 'Conversational'),
          ],
          customSections: [
            CustomSection(
              title: 'Open Source Contributions',
              items: [
                'Contributor to CNCF Kubernetes ecosystem repositories',
                'Speaker at Cloud Native Summit 2025 on Microservice Resilience',
              ],
            ),
          ],
        );

        final pdfDoc = await template.generatePdf(resume, PdfPageFormat.a4);
        final pdfBytes = await pdfDoc.save();

        expect(pdfBytes, isNotNull);
        expect(pdfBytes.isNotEmpty, isTrue);
        expect(pdfBytes.length, greaterThan(1000));
      },
    );

    test(
      'AcademicCvTemplate PDF compiles cleanly with multi-page academic CV',
      () async {
        final template = AcademicCvTemplate();
        final resume = Resume(
          title: 'Academic CV Resume',
          templateId: 'academic_cv',
          personalInfo: PersonalInformation(
            fullName: 'Dr. Evelyn Reed',
            jobTitle: 'Associate Professor of Computer Science',
            email: 'evelyn.reed@university.edu',
            phone: '+1 (555) 234-5678',
            location: 'Cambridge, MA',
            website: 'https://evelynreed.org',
          ),
          summary: ProfessionalSummary(
            summaryText:
                'Researcher specializing in distributed systems, formal methods, and programming language design with 15+ peer-reviewed publications.',
          ),
          educationList: [
            Education(
              institution: 'Massachusetts Institute of Technology',
              degree: 'Ph.D.',
              fieldOfStudy: 'Computer Science',
              location: 'Cambridge, MA',
              startDate: '2014',
              endDate: '2019',
              gpa: '4.0',
            ),
            Education(
              institution: 'Stanford University',
              degree: 'B.S.',
              fieldOfStudy: 'Computer Science',
              location: 'Stanford, CA',
              startDate: '2010',
              endDate: '2014',
            ),
          ],
          experiences: [
            Experience(
              company: 'Harvard University',
              position: 'Associate Professor',
              location: 'Cambridge, MA',
              startDate: '2022',
              endDate: 'Present',
              isCurrent: true,
              description:
                  'Leading the Concurrent Systems Laboratory. Principal Investigator on NSF Grant #2049182.',
            ),
            Experience(
              company: 'MIT CSAIL',
              position: 'Postdoctoral Researcher',
              location: 'Cambridge, MA',
              startDate: '2019',
              endDate: '2022',
              description:
                  'Researched mechanized proofs for fault-tolerant consensus protocols.',
            ),
          ],
          projects: [
            Project(
              name: 'VeriLog Logic Verifier',
              role: 'Principal Investigator',
              description: 'Formally verified model checker for distributed protocols.',
              technologies: 'Coq, OCaml, C++',
            ),
          ],
          customSections: [
            CustomSection(
              title: 'Selected Publications',
              items: [
                'Reed, E. et al. (2024). "Mechanized Verification of Raft Consensus." POPL 2024.',
                'Reed, E. & Smith, A. (2023). "Linearizability at Scale." OSDI 2023.',
              ],
            ),
          ],
        );

        final pdfDoc = await template.generatePdf(resume, PdfPageFormat.a4);
        final pdfBytes = await pdfDoc.save();

        expect(pdfBytes, isNotNull);
        expect(pdfBytes.isNotEmpty, isTrue);
        expect(pdfBytes.length, greaterThan(1000));
      },
    );
  });
}
