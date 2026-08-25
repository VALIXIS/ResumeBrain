import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:resume_brain/data/models/resume_models.dart';
import 'package:resume_brain/features/templates/implementations/executive_minimal_template.dart';
import 'package:resume_brain/features/templates/implementations/modern_classic_template.dart';
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
    test('TemplateRegistry returns all templates', () {
      final templates = TemplateRegistry.allTemplates;
      expect(templates.length, 2);
      expect(templates.first.id, 'modern_classic');
      expect(templates.last.id, 'executive_minimal');
    });

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
  });
}
