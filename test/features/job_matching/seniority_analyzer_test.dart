import 'package:flutter_test/flutter_test.dart';
import 'package:resume_brain/data/models/resume_models.dart';
import 'package:resume_brain/features/job_matching/services/seniority_analyzer_service.dart';

void main() {
  late SeniorityAnalyzerService service;

  setUp(() {
    service = SeniorityAnalyzerService();
  });

  group('SeniorityAnalyzerService Unit Tests', () {
    test('Detects Senior level from title and experience requirement', () {
      const text = 'Senior Software Engineer required with 5+ years experience.';
      final result = service.analyzeSeniority(text);

      expect(result.detectedJdSeniority, equals('Senior'));
      expect(result.requiredYearsOfExperience, equals(5));
    });

    test('Detects Lead level correctly', () {
      const text = 'Tech Lead position responsible for team of 6 engineers.';
      final result = service.analyzeSeniority(text);

      expect(result.detectedJdSeniority, equals('Lead'));
    });

    test('Detects Intern level correctly', () {
      const text = 'Software Engineering Intern - Summer 2026';
      final result = service.analyzeSeniority(text);

      expect(result.detectedJdSeniority, equals('Intern'));
    });

    test('Compares candidate resume experience with target JD seniority', () {
      const text = 'Senior Flutter Developer with 5+ years experience.';
      final resume = Resume(
        experiences: [
          Experience(
            company: 'Tech Corp',
            position: 'Flutter Developer',
            startDate: '2019',
            endDate: '2026',
            isCurrent: true,
          ),
        ],
      );

      final result = service.analyzeSeniority(text, resume: resume);
      expect(result.detectedJdSeniority, equals('Senior'));
      expect(result.candidateYearsOfExperience, greaterThanOrEqualTo(5));
      expect(result.alignmentStatus, equals('Well Aligned'));
    });
  });
}
