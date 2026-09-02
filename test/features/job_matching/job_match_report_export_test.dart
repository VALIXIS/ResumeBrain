import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resume_brain/data/models/resume_models.dart';
import 'package:resume_brain/features/job_matching/controllers/job_matching_controller.dart';
import 'package:resume_brain/features/job_matching/models/job_description.dart';
import 'package:resume_brain/features/job_matching/models/keyword_extraction_result.dart';
import 'package:resume_brain/features/job_matching/services/keyword_extractor_service.dart';

/// Test helper class representing the Job Match Summary Report Exporter.
class JobMatchReportExporter {
  /// Generates a human-readable plain text summary report.
  static String exportAsTextReport({
    required JobDescription jobDescription,
    required KeywordExtractionResult result,
    Resume? resume,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('==================================================');
    buffer.writeln('           JOB MATCH SUMMARY REPORT               ');
    buffer.writeln('==================================================');
    buffer.writeln('Job Title: ${jobDescription.title.isNotEmpty ? jobDescription.title : "Target Job Description"}');
    if (resume != null) {
      buffer.writeln('Candidate: ${resume.personalInfo.fullName.isNotEmpty ? resume.personalInfo.fullName : "Active Candidate"}');
    }
    buffer.writeln('Overall Match Score: ${result.overlapPercentage.toStringAsFixed(1)}%');
    buffer.writeln('--------------------------------------------------');
    buffer.writeln('MATCHED TECHNICAL SKILLS (${result.matchedSkills.length}):');
    if (result.matchedSkills.isEmpty) {
      buffer.writeln('  - None detected.');
    } else {
      for (final skill in result.matchedSkills) {
        buffer.writeln('  [✓] $skill');
      }
    }
    buffer.writeln('--------------------------------------------------');
    buffer.writeln('MISSING KEYWORDS GAP (${result.missingSkills.length}):');
    if (result.missingSkills.isEmpty) {
      buffer.writeln('  - No missing keywords detected!');
    } else {
      for (final skill in result.missingSkills) {
        buffer.writeln('  [!] $skill');
      }
    }
    buffer.writeln('==================================================');
    return buffer.toString();
  }

  /// Generates a GitHub-flavored Markdown report.
  static String exportAsMarkdownReport({
    required JobDescription jobDescription,
    required KeywordExtractionResult result,
    Resume? resume,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('# Job Match Summary Report');
    buffer.writeln('');
    buffer.writeln('**Job Title:** ${jobDescription.title.isNotEmpty ? jobDescription.title : "Target Job"}  ');
    if (resume != null) {
      buffer.writeln('**Candidate:** ${resume.personalInfo.fullName.isNotEmpty ? resume.personalInfo.fullName : "Candidate"}  ');
    }
    buffer.writeln('**Overall Match Score:** `${result.overlapPercentage.toStringAsFixed(1)}%`');
    buffer.writeln('');
    buffer.writeln('### Matched Technical Skills (${result.matchedSkills.length})');
    if (result.matchedSkills.isEmpty) {
      buffer.writeln('*No matching technical skills detected.*');
    } else {
      for (final skill in result.matchedSkills) {
        buffer.writeln('- ✅ **$skill**');
      }
    }
    buffer.writeln('');
    buffer.writeln('### Missing Keywords Gap (${result.missingSkills.length})');
    if (result.missingSkills.isEmpty) {
      buffer.writeln('*No missing technical keywords detected!*');
    } else {
      for (final skill in result.missingSkills) {
        buffer.writeln('- ⚠️ **$skill**');
      }
    }
    return buffer.toString();
  }

  /// Generates a structured JSON string summary export.
  static String exportAsJsonReport({
    required JobDescription jobDescription,
    required KeywordExtractionResult result,
    Resume? resume,
  }) {
    final map = {
      'jobTitle': jobDescription.title,
      'jobDescriptionSnippet': jobDescription.descriptionText.length > 100
          ? '${jobDescription.descriptionText.substring(0, 100)}...'
          : jobDescription.descriptionText,
      'candidateName': resume?.personalInfo.fullName ?? '',
      'overlapPercentage': result.overlapPercentage,
      'matchedSkillsCount': result.matchedSkills.length,
      'missingSkillsCount': result.missingSkills.length,
      'matchedSkills': result.matchedSkills,
      'missingSkills': result.missingSkills,
      'extractedJdSkills': result.extractedJdSkills,
      'exportedAt': DateTime.now().toIso8601String(),
    };
    return const JsonEncoder.withIndent('  ').convert(map);
  }
}

void main() {
  late KeywordExtractorService extractorService;
  late ProviderContainer container;

  setUp(() {
    extractorService = KeywordExtractorService();
    container = ProviderContainer(
      overrides: [
        keywordExtractorServiceProvider.overrideWithValue(extractorService),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  Resume createSampleResume() {
    return Resume(
      id: 'res-report-1',
      title: 'Senior Developer',
      personalInfo: PersonalInformation(fullName: 'Jordan Lee'),
      skills: [
        Skill(name: 'Flutter'),
        Skill(name: 'Dart'),
        Skill(name: 'SQL'),
      ],
    );
  }

  group('Job Match Summary Report - Generation & Content Integrity Tests', () {
    test('1. Report generation accurately computes and reflects match metrics', () {
      const jdText = 'We need a developer skilled in Flutter, Dart, SQL, Docker, and AWS.';
      final jobDescription = JobDescription(title: 'Senior Mobile Lead', descriptionText: jdText);
      final resume = createSampleResume();

      final result = extractorService.extractAndCompare(
        jobDescriptionText: jdText,
        resume: resume,
      );

      final textReport = JobMatchReportExporter.exportAsTextReport(
        jobDescription: jobDescription,
        result: result,
        resume: resume,
      );

      expect(textReport, contains('Senior Mobile Lead'));
      expect(textReport, contains('Jordan Lee'));
      expect(textReport, contains('60.0%')); // 3 out of 5 skills = 60.0%
      expect(textReport, contains('[✓] Flutter'));
      expect(textReport, contains('[✓] Dart'));
      expect(textReport, contains('[✓] SQL'));
      expect(textReport, contains('[!] Amazon Web Services'));
      expect(textReport, contains('[!] Docker'));
    });

    test('2. Markdown report format generation produces valid GFM document', () {
      const jdText = 'Skills: Python, Java, Docker.';
      final jobDescription = JobDescription(title: 'Backend Specialist', descriptionText: jdText);

      final result = extractorService.extractAndCompare(
        jobDescriptionText: jdText,
        userSkills: ['Python', 'Java'],
      );

      final mdReport = JobMatchReportExporter.exportAsMarkdownReport(
        jobDescription: jobDescription,
        result: result,
      );

      expect(mdReport, startsWith('# Job Match Summary Report'));
      expect(mdReport, contains('**Job Title:** Backend Specialist'));
      expect(mdReport, contains('`66.7%`')); // 2 out of 3 = 66.67% -> 66.7%
      expect(mdReport, contains('- ✅ **Java**'));
      expect(mdReport, contains('- ✅ **Python**'));
      expect(mdReport, contains('- ⚠️ **Docker**'));
    });

    test('3. JSON report export parses as valid JSON with accurate fields', () {
      const jdText = 'Required: Rust, Go, Git.';
      final jobDescription = JobDescription(title: 'Systems Engineer', descriptionText: jdText);

      final result = extractorService.extractAndCompare(
        jobDescriptionText: jdText,
        userSkills: ['Git'],
      );

      final jsonString = JobMatchReportExporter.exportAsJsonReport(
        jobDescription: jobDescription,
        result: result,
      );

      final decoded = json.decode(jsonString) as Map<String, dynamic>;
      expect(decoded['jobTitle'], equals('Systems Engineer'));
      expect(decoded['overlapPercentage'], equals(33.33)); // 1 / 3 = 33.33%
      expect(decoded['matchedSkillsCount'], equals(1));
      expect(decoded['missingSkillsCount'], equals(2));
      expect(decoded['matchedSkills'], equals(['Git']));
      expect(decoded['missingSkills'], containsAll(['Go', 'Rust']));
    });
  });

  group('Job Match Summary Report - Edge Cases & Boundaries', () {
    test('4. Full Skill Match (100.0% overlap) report formatting', () {
      const jdText = 'Tech: Flutter, Dart.';
      final jobDescription = JobDescription(title: 'Flutter Developer', descriptionText: jdText);

      final result = extractorService.extractAndCompare(
        jobDescriptionText: jdText,
        userSkills: ['Flutter', 'Dart'],
      );

      final report = JobMatchReportExporter.exportAsTextReport(
        jobDescription: jobDescription,
        result: result,
      );

      expect(report, contains('100.0%'));
      expect(report, contains('MISSING KEYWORDS GAP (0):'));
      expect(report, contains('- No missing keywords detected!'));
    });

    test('5. Zero Skill Match (0.0% overlap) report formatting', () {
      const jdText = 'Tech: Ruby, Elixir, Haskell.';
      final jobDescription = JobDescription(title: 'Functional Dev', descriptionText: jdText);

      final result = extractorService.extractAndCompare(
        jobDescriptionText: jdText,
        userSkills: ['Python', 'Java'],
      );

      final report = JobMatchReportExporter.exportAsTextReport(
        jobDescription: jobDescription,
        result: result,
      );

      expect(report, contains('0.0%'));
      expect(report, contains('MATCHED TECHNICAL SKILLS (0):'));
      expect(report, contains('- None detected.'));
      expect(report, contains('MISSING KEYWORDS GAP (3):'));
    });

    test('6. Empty or missing optional fields do not cause crash or invalid output', () {
      final jobDescription = JobDescription(descriptionText: '');

      final result = extractorService.extractAndCompare(
        jobDescriptionText: '',
      );

      final textReport = JobMatchReportExporter.exportAsTextReport(
        jobDescription: jobDescription,
        result: result,
      );

      expect(textReport, contains('Target Job Description'));
      expect(textReport, contains('0.0%'));

      final jsonString = JobMatchReportExporter.exportAsJsonReport(
        jobDescription: jobDescription,
        result: result,
      );
      final decoded = json.decode(jsonString) as Map<String, dynamic>;
      expect(decoded['overlapPercentage'], equals(0.0));
      expect(decoded['matchedSkills'], isEmpty);
    });
  });

  group('Job Match Report - Riverpod Controller Integration', () {
    test('7. Riverpod controller integration extracts and exposes report data cleanly', () async {
      final controller = container.read(jobMatchingControllerProvider.notifier);

      const jdText = 'We require Flutter, Dart, Riverpod, and GraphQL.';
      final resume = createSampleResume();

      await controller.submitJobDescriptionWithResume(
        jdText,
        title: 'Lead Flutter Architect',
        resume: resume,
      );

      final state = container.read(jobMatchingControllerProvider);
      expect(state.currentJob, isNotNull);
      expect(state.extractionResult, isNotNull);

      final reportText = JobMatchReportExporter.exportAsTextReport(
        jobDescription: state.currentJob!,
        result: state.extractionResult!,
        resume: resume,
      );

      expect(reportText, contains('Lead Flutter Architect'));
      expect(reportText, contains('50.0%')); // 2 of 4 extracted skills matched (Flutter, Dart)
      expect(reportText, contains('[✓] Flutter'));
      expect(reportText, contains('[✓] Dart'));
      expect(reportText, contains('[!] GraphQL'));
      expect(reportText, contains('[!] Riverpod'));
    });
  });
}
