import 'package:flutter_test/flutter_test.dart';
import 'package:resume_brain/features/job_matching/services/salary_analyzer_service.dart';

void main() {
  late SalaryAnalyzerService service;

  setUp(() {
    service = SalaryAnalyzerService();
  });

  group('SalaryAnalyzerService Unit Tests', () {
    test('Parses Rupee LPA ranges correctly', () {
      const text = 'Compensation: ₹10 - 15 LPA plus performance bonus.';
      final result = service.parseSalary(text);

      expect(result.hasSalary, isTrue);
      expect(result.currency, equals('INR'));
      expect(result.minAmount, equals(1000000.0));
      expect(result.maxAmount, equals(1500000.0));
      expect(result.period, equals('annual'));
      expect(result.formattedRange, contains('₹10 - ₹15 LPA'));
    });

    test('Parses single Rupee LPA amount correctly', () {
      const text = 'Salary offered: 8 LPA';
      final result = service.parseSalary(text);

      expect(result.hasSalary, isTrue);
      expect(result.currency, equals('INR'));
      expect(result.minAmount, equals(800000.0));
      expect(result.maxAmount, equals(800000.0));
    });

    test('Parses USD ranges correctly', () {
      const text = r'Base salary: $80,000 - $120,000 per year.';
      final result = service.parseSalary(text);

      expect(result.hasSalary, isTrue);
      expect(result.currency, equals('USD'));
      expect(result.minAmount, equals(80000.0));
      expect(result.maxAmount, equals(120000.0));
      expect(result.formattedRange, contains(r'$80k - $120k'));
    });

    test('Parses hourly rates correctly', () {
      const text = r'Pay rate: $50/hr';
      final result = service.parseSalary(text);

      expect(result.hasSalary, isTrue);
      expect(result.period, equals('hourly'));
      expect(result.minAmount, equals(50.0));
      expect(result.formattedRange, contains('/hr'));
    });

    test('Ignores unrelated numbers like team size or years of experience', () {
      const text = 'Looking for a developer with 5 years experience in a team of 100 people.';
      final result = service.parseSalary(text);

      expect(result.hasSalary, isFalse);
      expect(result.formattedRange, equals('Not specified'));
    });
  });
}
