import 'package:flutter_test/flutter_test.dart';
import 'package:resume_brain/data/models/resume_models.dart';
import 'package:resume_brain/features/analysis/services/ats_engine.dart';

void main() {
  group('AtsEngine Production Unit Tests', () {
    late AtsEngine atsEngine;

    setUp(() {
      atsEngine = AtsEngine();
    });

    test('1. Empty/minimal resume returns clamped scores and recommendations', () {
      final emptyResume = Resume(
        id: 'empty-1',
        title: 'Empty Resume',
        personalInfo: PersonalInformation(),
      );

      final report = atsEngine.analyze(emptyResume);

      expect(report.overallScore, greaterThanOrEqualTo(0));
      expect(report.overallScore, lessThanOrEqualTo(100));
      expect(report.impactVerbsScore, equals(0));
      expect(report.formattingScore, equals(0));
      expect(report.contactCompletenessScore, equals(0));
      expect(report.keywordDensityScore, equals(0));
      expect(report.recommendations, isNotEmpty);
    });

    test('2. Complete resume scores high (near or equal to 100)', () {
      final completeResume = Resume(
        id: 'complete-1',
        title: 'Complete Executive Resume',
        personalInfo: PersonalInformation(
          fullName: 'Jane Smith',
          email: 'jane.smith@example.com',
          phone: '+1 (555) 234-5678',
          location: 'San Jose, CA',
          website: 'https://janesmith.dev',
        ),
        socialLinks: [
          SocialLink(platform: 'LinkedIn', url: 'https://linkedin.com/in/janesmith'),
          SocialLink(platform: 'GitHub', url: 'https://github.com/janesmith'),
        ],
        summary: ProfessionalSummary(
          summaryText: 'Principal Software Architect with over 10 years of experience designing high-scale cloud platforms, distributed Dart backend services, and Flutter enterprise apps.',
        ),
        experiences: [
          Experience(
            company: 'Tech Corp',
            position: 'Principal Engineer',
            startDate: '2021',
            endDate: 'Present',
            description: 'Architected microservices infrastructure serving over 500,000 active users.\nEngineered real-time sync algorithm reducing data latency by 45%.\nAutomated CI/CD pipelines increasing deployment frequency by 3x.',
          ),
          Experience(
            company: 'Dev Innovations',
            position: 'Senior Developer',
            startDate: '2017',
            endDate: '2021',
            description: 'Developed cross-platform Flutter applications with Riverpod and Hive DB.\nOptimized app startup time by 35% through lazy loading.',
          ),
        ],
        educationList: [
          Education(
            institution: 'Stanford University',
            degree: 'Master of Science',
            fieldOfStudy: 'Computer Science',
            startDate: '2015',
            endDate: '2017',
          ),
        ],
        skills: [
          Skill(name: 'Flutter'),
          Skill(name: 'Dart'),
          Skill(name: 'System Architecture'),
          Skill(name: 'Riverpod'),
          Skill(name: 'GraphQL'),
          Skill(name: 'PostgreSQL'),
          Skill(name: 'CI/CD'),
          Skill(name: 'Docker'),
          Skill(name: 'Kubernetes'),
          Skill(name: 'AWS'),
        ],
        projects: [
          Project(
            name: 'Resume Brain',
            role: 'Lead Architect',
            description: 'Built offline-first AI resume management platform with local encryption.',
            technologies: 'Flutter, Dart, Hive, Supabase',
          ),
        ],
        certifications: [
          Certification(name: 'AWS Solutions Architect Professional'),
        ],
        languages: [
          Language(name: 'English', proficiency: 'Native'),
        ],
      );

      final report = atsEngine.analyze(completeResume);

      expect(report.overallScore, greaterThanOrEqualTo(90));
      expect(report.impactVerbsScore, greaterThanOrEqualTo(85));
      expect(report.formattingScore, equals(100));
      expect(report.contactCompletenessScore, equals(100));
      expect(report.keywordDensityScore, equals(100));
    });

    test('3. Strong action verbs increase Impact Verbs score', () {
      final resumeWithStrongVerbs = Resume(
        id: 'verbs-1',
        title: 'Strong Verbs Resume',
        experiences: [
          Experience(
            company: 'Company A',
            position: 'Lead Developer',
            description: 'Architected cloud backend services.\nEngineered high throughput pipelines.\nOptimized database query performance by 40%.\nAutomated integration test execution.',
          ),
        ],
      );

      final report = atsEngine.analyze(resumeWithStrongVerbs);

      expect(report.impactVerbsScore, greaterThanOrEqualTo(75));
    });

    test('4. Weak bullet wording generates recommendations and lowers score', () {
      final resumeWithWeakBullets = Resume(
        id: 'weak-1',
        title: 'Weak Bullets Resume',
        experiences: [
          Experience(
            company: 'Company B',
            position: 'Assistant Developer',
            description: 'worked on fixing UI bugs.\nresponsible for writing documentation.\nhelped with customer support calls.\nassisted in testing releases.',
          ),
        ],
      );

      final report = atsEngine.analyze(resumeWithWeakBullets);

      expect(report.impactVerbsScore, lessThan(60));
      final weakRecs = report.recommendations
          .where((r) => r.dimension == AtsDimension.impactVerbs)
          .toList();
      expect(weakRecs, isNotEmpty);
      expect(weakRecs.any((r) => r.title.contains('Replace Weak')), isTrue);
    });

    test('5. Complete contact information yields 100 in Contact Completeness', () {
      final completeContactResume = Resume(
        id: 'contact-full',
        personalInfo: PersonalInformation(
          fullName: 'Alice Johnson',
          email: 'alice@example.com',
          phone: '+1 800 555 0199',
          location: 'Austin, TX',
          website: 'https://alice.dev',
        ),
      );

      final report = atsEngine.analyze(completeContactResume);

      expect(report.contactCompletenessScore, equals(100));
    });

    test('6. Missing contact information yields 0 or low score and triggers high priority recommendation', () {
      final missingContactResume = Resume(
        id: 'contact-missing',
        personalInfo: PersonalInformation(
          fullName: 'Bob Unknown',
          // No email, phone, location, or website
        ),
      );

      final report = atsEngine.analyze(missingContactResume);

      expect(report.contactCompletenessScore, equals(0));
      final contactRecs = report.recommendations
          .where((r) => r.dimension == AtsDimension.contactCompleteness)
          .toList();
      expect(contactRecs, isNotEmpty);
    });

    test('7. Keyword-rich resume yields high Keyword Density score', () {
      final richResume = Resume(
        id: 'kw-rich',
        summary: ProfessionalSummary(
          summaryText: 'Senior Mobile Engineer skilled in Flutter, Dart, Riverpod, Firebase, GraphQL, REST APIs, and DevOps pipelines.',
        ),
        skills: List.generate(10, (i) => Skill(name: 'Skill $i')),
        experiences: [
          Experience(
            company: 'Tech House',
            position: 'Developer',
            description: 'Integrated GraphQL, REST API, SQLite, Hive, Docker, and Kubernetes.',
          ),
        ],
        projects: [
          Project(name: 'Project Alpha', technologies: 'Flutter, Dart, Cloud Functions'),
        ],
        certifications: [Certification(name: 'Google Cloud Professional')],
        languages: [Language(name: 'English')],
      );

      final report = atsEngine.analyze(richResume);

      expect(report.keywordDensityScore, greaterThanOrEqualTo(80));
    });

    test('8. Sparse resume yields low Keyword Density score', () {
      final sparseResume = Resume(
        id: 'kw-sparse',
        skills: [Skill(name: 'Communication')],
      );

      final report = atsEngine.analyze(sparseResume);

      expect(report.keywordDensityScore, lessThan(40));
    });

    test('9. Score clamping guarantees 0 to 100 boundary', () {
      final emptyResume = Resume(id: 'clamp-min');
      final fullResume = Resume(
        id: 'clamp-max',
        personalInfo: PersonalInformation(
          fullName: 'Test Candidate',
          email: 'test@example.com',
          phone: '1234567890',
          location: 'Test City',
          website: 'https://test.dev',
        ),
        summary: ProfessionalSummary(
          summaryText: 'Architected software systems for enterprise scale.',
        ),
        experiences: [
          Experience(
            company: 'Company',
            position: 'Engineer',
            description: 'Developed, engineered, automated, optimized software systems.',
          ),
          Experience(
            company: 'Company 2',
            position: 'Developer',
            description: 'Built cross-platform apps with 50% performance increase.',
          ),
        ],
        educationList: [Education(institution: 'University', degree: 'B.S.')],
        skills: List.generate(10, (i) => Skill(name: 'TechSkill_$i')),
        projects: [Project(name: 'P1')],
        certifications: [Certification(name: 'C1')],
        languages: [Language(name: 'L1')],
      );

      final minReport = atsEngine.analyze(emptyResume);
      final maxReport = atsEngine.analyze(fullResume);

      expect(minReport.overallScore, greaterThanOrEqualTo(0));
      expect(minReport.overallScore, lessThanOrEqualTo(100));

      expect(maxReport.overallScore, greaterThanOrEqualTo(0));
      expect(maxReport.overallScore, lessThanOrEqualTo(100));
    });

    test('10. Recommendation generation produces well-formatted, actionable objects', () {
      final resumeWithIssues = Resume(
        id: 'recs-test',
        personalInfo: PersonalInformation(
          fullName: 'John Mark',
          email: 'john@example.com',
        ),
        experiences: [
          Experience(
            company: 'Old Corp',
            position: 'Staff',
            description: 'worked on small tasks.',
          ),
        ],
      );

      final report = atsEngine.analyze(resumeWithIssues);

      expect(report.recommendations, isNotEmpty);
      for (final rec in report.recommendations) {
        expect(rec.id, isNotEmpty);
        expect(rec.title, isNotEmpty);
        expect(rec.description, isNotEmpty);
        expect(rec.dimension, isNotNull);
        expect(rec.priority, isNotNull);
      }
    });
  });
}
