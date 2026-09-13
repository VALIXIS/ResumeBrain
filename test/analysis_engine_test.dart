import 'package:flutter_test/flutter_test.dart';
import 'package:resume_brain/data/models/resume_models.dart';
import 'package:resume_brain/features/analysis/models/analysis_dashboard_stats.dart';
import 'package:resume_brain/features/analysis/models/resume_analysis_report.dart';
import 'package:resume_brain/features/analysis/services/analysis_engine.dart';

void main() {
  group('AnalysisEngine & ResumeAnalysisReport Tests', () {
    final mockEngine = MockAnalysisEngine();

    test('MockAnalysisEngine returns valid score and categories for sample resume', () async {
      final sampleResume = Resume(
        id: 'test-resume-1',
        title: 'Senior Developer Resume',
        personalInfo: PersonalInformation(
          fullName: 'John Doe',
          email: 'john@example.com',
          phone: '+1 555-0199',
          location: 'San Francisco, CA',
          website: 'https://johndoe.dev',
        ),
        summary: ProfessionalSummary(
          summaryText: 'Senior Software Engineer with over 8 years of experience building scalable Flutter applications.',
        ),
        experiences: [
          Experience(
            company: 'Tech Corp',
            position: 'Lead Flutter Developer',
            startDate: '2020',
            endDate: 'Present',
            description: 'Led a team of 5 mobile engineers, improved app load times by 40%, and deployed production apps to Play Store.',
          ),
          Experience(
            company: 'Startup Inc',
            position: 'Mobile Engineer',
            startDate: '2018',
            endDate: '2020',
            description: 'Developed cross-platform features using Dart and Flutter, integrated GraphQL APIs, and wrote unit tests.',
          ),
        ],
        educationList: [
          Education(
            institution: 'University of California',
            degree: 'Bachelor of Science',
            fieldOfStudy: 'Computer Science',
            startDate: '2014',
            endDate: '2018',
          ),
        ],
        skills: [
          Skill(name: 'Flutter'),
          Skill(name: 'Dart'),
          Skill(name: 'Riverpod'),
          Skill(name: 'REST APIs'),
          Skill(name: 'Git'),
          Skill(name: 'CI/CD'),
          Skill(name: 'Unit Testing'),
          Skill(name: 'Hive DB'),
        ],
        certifications: [
          Certification(name: 'Google Cloud Certified Professional'),
        ],
        languages: [
          Language(name: 'English', proficiency: 'Native'),
        ],
      );

      final report = await mockEngine.analyze(sampleResume);

      expect(report.resumeId, equals('test-resume-1'));
      expect(report.overallScore, greaterThanOrEqualTo(80));
      expect(report.categoryScores['contactInfo'], equals(100));
      expect(report.categoryScores['skills'], equals(100));
      expect(report.categoryScores['workExperience'], equals(100));
    });

    test('Strict 5-tier ATS score calibration: A < B < C < D < E in 0..100', () async {
      // Resume A: Name only
      final resumeA = Resume(
        id: 'res-A',
        title: 'Resume A',
        personalInfo: PersonalInformation(fullName: 'John Doe'),
      );

      // Resume B: Contact information
      final resumeB = Resume(
        id: 'res-B',
        title: 'Resume B',
        personalInfo: PersonalInformation(
          fullName: 'John Doe',
          email: 'john@example.com',
          phone: '+1 555 1234',
          location: 'New York, NY',
        ),
      );

      // Resume C: Contact + Summary + Skills
      final resumeC = Resume(
        id: 'res-C',
        title: 'Resume C',
        personalInfo: PersonalInformation(
          fullName: 'John Doe',
          email: 'john@example.com',
          phone: '+1 555 1234',
          location: 'New York, NY',
        ),
        summary: ProfessionalSummary(
          summaryText: 'Software engineer experienced in mobile app development and cross-platform architectures.',
        ),
        skills: [
          Skill(name: 'Flutter'),
          Skill(name: 'Dart'),
          Skill(name: 'REST APIs'),
          Skill(name: 'Git'),
        ],
      );

      // Resume D: Contact + Summary + Skills + Education + Experience
      final resumeD = Resume(
        id: 'res-D',
        title: 'Resume D',
        personalInfo: PersonalInformation(
          fullName: 'John Doe',
          email: 'john@example.com',
          phone: '+1 555 1234',
          location: 'New York, NY',
        ),
        summary: ProfessionalSummary(
          summaryText: 'Software engineer experienced in mobile app development and cross-platform architectures.',
        ),
        skills: [
          Skill(name: 'Flutter'),
          Skill(name: 'Dart'),
          Skill(name: 'REST APIs'),
          Skill(name: 'Git'),
          Skill(name: 'Firebase'),
          Skill(name: 'CI/CD'),
          Skill(name: 'SQL'),
          Skill(name: 'Python'),
        ],
        experiences: [
          Experience(
            company: 'Tech Corp',
            position: 'Senior Engineer',
            startDate: '2021',
            endDate: 'Present',
            description: 'Architected production Flutter apps serving over 500,000 active users with zero crash rate.',
          ),
          Experience(
            company: 'Dev Studio',
            position: 'Software Developer',
            startDate: '2019',
            endDate: '2021',
            description: 'Built cross-platform features, integrated GraphQL endpoints, and improved CI build times by 35%.',
          ),
        ],
        educationList: [
          Education(
            institution: 'NYU',
            degree: 'B.S.',
            fieldOfStudy: 'Computer Science',
            startDate: '2015',
            endDate: '2019',
          ),
        ],
      );

      // Resume E: Complete strong resume (Contact + Summary + Skills + Education + Experience + Projects + Certifications + Languages)
      final resumeE = Resume(
        id: 'res-E',
        title: 'Resume E',
        personalInfo: PersonalInformation(
          fullName: 'John Doe',
          email: 'john@example.com',
          phone: '+1 555 1234',
          location: 'New York, NY',
          website: 'https://johndoe.dev',
        ),
        summary: ProfessionalSummary(
          summaryText: 'Senior Software Engineer with over 8 years of experience building scalable Flutter applications.',
        ),
        skills: [
          Skill(name: 'Flutter'),
          Skill(name: 'Dart'),
          Skill(name: 'Riverpod'),
          Skill(name: 'REST APIs'),
          Skill(name: 'Git'),
          Skill(name: 'CI/CD'),
          Skill(name: 'Unit Testing'),
          Skill(name: 'Hive DB'),
        ],
        experiences: [
          Experience(
            company: 'Tech Corp',
            position: 'Senior Engineer',
            startDate: '2021',
            endDate: 'Present',
            description: 'Architected production Flutter applications serving over 500,000 active users with zero crash rate and automated deployment pipelines.',
          ),
          Experience(
            company: 'Dev Studio',
            position: 'Software Developer',
            startDate: '2019',
            endDate: '2021',
            description: 'Built cross-platform features, integrated GraphQL endpoints, and improved CI build times by 35%.',
          ),
        ],
        educationList: [
          Education(
            institution: 'NYU',
            degree: 'B.S.',
            fieldOfStudy: 'Computer Science',
            startDate: '2015',
            endDate: '2019',
          ),
        ],
        projects: [
          Project(name: 'Resume Brain', description: 'AI Resume Builder'),
        ],
        certifications: [
          Certification(name: 'Google Cloud Professional'),
        ],
        languages: [
          Language(name: 'English', proficiency: 'Native'),
        ],
      );

      final reportA = await mockEngine.analyze(resumeA);
      final reportB = await mockEngine.analyze(resumeB);
      final reportC = await mockEngine.analyze(resumeC);
      final reportD = await mockEngine.analyze(resumeD);
      final reportE = await mockEngine.analyze(resumeE);

      expect(reportA.overallScore, equals(0));
      expect(reportB.overallScore, equals(15));
      expect(reportC.overallScore, equals(35));
      expect(reportD.overallScore, equals(75));
      expect(reportE.overallScore, equals(100));

      expect(reportA.overallScore, lessThan(reportB.overallScore));
      expect(reportB.overallScore, lessThan(reportC.overallScore));
      expect(reportC.overallScore, lessThan(reportD.overallScore));
      expect(reportD.overallScore, lessThan(reportE.overallScore));
    });

    test('ResumeAnalysisReport serialization toMap and fromMap works cleanly', () {
      final report = ResumeAnalysisReport(
        resumeId: 'res-99',
        overallScore: 85,
        categoryScores: {'contact': 100, 'skills': 70},
        suggestions: ['Add project links.'],
        timestamp: DateTime(2026, 8, 28),
      );

      final map = report.toMap();
      final reconstructed = ResumeAnalysisReport.fromMap(map);

      expect(reconstructed.resumeId, equals('res-99'));
      expect(reconstructed.overallScore, equals(85));
      expect(reconstructed.suggestions, contains('Add project links.'));
    });

    test('AnalysisDashboardStats serialization toMap and fromMap works cleanly', () {
      final stats = AnalysisDashboardStats(
        totalResumes: 3,
        averageAtsScore: 78.5,
        recentActivity: const [],
      );

      final map = stats.toMap();
      final reconstructed = AnalysisDashboardStats.fromMap(map);

      expect(reconstructed.totalResumes, equals(3));
      expect(reconstructed.averageAtsScore, equals(78.5));
    });
  });
}
