import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:resume_brain/features/resume/services/resume_parser_service.dart';

void main() {
  group('ResumeParserService Tests', () {
    late ResumeParserService parserService;

    setUp(() {
      parserService = ResumeParserService();
    });

    test('extracts text from simulated raw PDF stream operators', () {
      const samplePdfContent = '''
%PDF-1.4
1 0 obj
<< /Length 120 >>
stream
BT
/F1 12 Tf
(JOHN DOE) Tj
T*
(Senior Flutter Developer) Tj
T*
(john.doe@example.com) Tj
ET
endstream
endobj
%%EOF
''';

      final pdfBytes = Uint8List.fromList(latin1.encode(samplePdfContent));
      final extracted = ResumeParserService.extractTextFromPdf(pdfBytes);

      expect(extracted, contains('JOHN DOE'));
      expect(extracted, contains('Senior Flutter Developer'));
      expect(extracted, contains('john.doe@example.com'));
    });

    test('extracts text from FlateDecode compressed PDF stream', () {
      const pageText = '''
BT
(ALEXANDER WRIGHT) Tj
T*
(alex.wright@techcorp.io) Tj
T*
(Experience) Tj
T*
(Lead Engineer - Apex Labs) Tj
T*
(2021 - Present) Tj
ET
''';

      final compressedBytes = zlib.encode(utf8.encode(pageText));
      final compressedLatin1 = latin1.decode(compressedBytes);

      final pdfDocument = '''
%PDF-1.4
1 0 obj
<< /Filter /FlateDecode /Length ${compressedBytes.length} >>
stream
$compressedLatin1
endstream
endobj
%%EOF
''';

      final pdfBytes = Uint8List.fromList(latin1.encode(pdfDocument));
      final extracted = ResumeParserService.extractTextFromPdf(pdfBytes);

      expect(extracted, contains('ALEXANDER WRIGHT'));
      expect(extracted, contains('alex.wright@techcorp.io'));
      expect(extracted, contains('Lead Engineer - Apex Labs'));
    });

    test('parses structured resume and extracts all core sections in under 5 seconds', () async {
      const fullResumeText = '''
SARAH CONNOR
Principal Mobile Systems Engineer
sarah.connor@cyberdyne.com | +1 (555) 987-6543 | Los Angeles, CA | linkedin.com/in/sarahconnor

PROFESSIONAL SUMMARY
Visionary mobile engineering leader with 8+ years building enterprise Flutter and distributed mobile apps.

WORK EXPERIENCE
Staff Mobile Engineer - Resistance Systems
Jan 2021 - Present
• Spearheaded offline-first synchronization engine with 99.99% uptime.
• Reduced build and test iteration cycles by 60% through automated CI/CD.

Senior Software Engineer - TechCorp
Mar 2018 - Dec 2020
• Developed core features in Flutter and Dart for 1M+ active users.

EDUCATION
Master of Science in Computer Science
MIT | 2016 - 2018 | GPA: 3.95

Bachelor of Science in Computer Engineering
UC Berkeley | 2012 - 2016

CORE SKILLS & TECHNOLOGIES
Flutter, Dart, Riverpod, SQLite, GraphQL, Docker, TypeScript, Git

CERTIFICATIONS
AWS Certified Solutions Architect
Google Cloud Professional Architect

LANGUAGES
English (Native), French (Fluent)
''';

      final pdfBytes = Uint8List.fromList(utf8.encode(fullResumeText));
      final stopwatch = Stopwatch()..start();
      final result = await parserService.parsePdfBytes(pdfBytes, enableAiFallback: false);
      stopwatch.stop();

      // Verify sub-5s speed constraint
      expect(stopwatch.elapsedMilliseconds, lessThan(5000));
      expect(result.parsingDuration.inMilliseconds, lessThan(5000));

      // Personal Info
      expect(result.resume.personalInfo.fullName, contains('SARAH CONNOR'));
      expect(result.resume.personalInfo.email, equals('sarah.connor@cyberdyne.com'));
      expect(result.resume.personalInfo.phone, contains('555'));
      expect(result.resume.personalInfo.location, contains('Los Angeles'));
      expect(result.resume.socialLinks.any((l) => l.platform == 'LinkedIn'), isTrue);

      // Summary
      expect(result.resume.summary.summaryText, contains('Visionary mobile engineering leader'));

      // Experience
      expect(result.resume.experiences.length, greaterThanOrEqualTo(2));
      expect(result.resume.experiences.first.position, contains('Staff Mobile Engineer'));

      // Education
      expect(result.resume.educationList.isNotEmpty, isTrue);
      expect(result.resume.educationList.first.institution, contains('MIT'));

      // Skills
      expect(result.resume.skills.length, greaterThanOrEqualTo(4));
      expect(result.resume.skills.any((s) => s.name.contains('Flutter')), isTrue);
      expect(result.resume.skills.any((s) => s.name.contains('Dart')), isTrue);

      // Certifications
      expect(result.resume.certifications.isNotEmpty, isTrue);

      // Languages
      expect(result.resume.languages.isNotEmpty, isTrue);

      // Confidence
      expect(result.confidenceScore, greaterThanOrEqualTo(0.7));
    });

    test('gracefully handles empty and corrupted bytes without crashing', () async {
      final emptyBytes = Uint8List(0);
      final result = await parserService.parsePdfBytes(emptyBytes, enableAiFallback: false);

      expect(result.resume.title, isNotEmpty);
      expect(result.confidenceScore, lessThanOrEqualTo(0.5));
      expect(result.parsingDuration.inMilliseconds, lessThan(5000));
    });
  });
}
