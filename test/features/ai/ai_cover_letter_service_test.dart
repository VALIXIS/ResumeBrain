import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:resume_brain/app/providers.dart';
import 'package:resume_brain/data/models/resume_models.dart';
import 'package:resume_brain/features/ai/screens/cover_letter_generator_screen.dart';
import 'package:resume_brain/features/ai/services/ai_cover_letter_service.dart';
import 'package:resume_brain/features/ai/services/ai_key_storage_service.dart';

class MockKeyStorageService extends AIKeyStorageService {
  final String? geminiKey;
  MockKeyStorageService({this.geminiKey});

  @override
  Future<String?> getGeminiKey() async => geminiKey;
}

void main() {
  final sampleResume = Resume(
    id: 'res-test-1',
    title: 'Senior Mobile Engineer',
    personalInfo: PersonalInformation(
      fullName: 'Alex Morgan',
      jobTitle: 'Senior Flutter Engineer',
      email: 'alex.morgan@example.com',
      phone: '+1 555 234 5678',
      location: 'Austin, TX',
    ),
    summary: ProfessionalSummary(
      summaryText: 'Architected high-performance mobile applications used by 2M+ active users.',
    ),
    experiences: [
      Experience(
        company: 'Valixis Systems',
        position: 'Lead Mobile Architect',
        startDate: '2023',
        isCurrent: true,
        description: 'Engineered reactive architecture scaling to 500k DAU with 99.9% uptime.',
      ),
    ],
    skills: [
      Skill(name: 'Flutter'),
      Skill(name: 'Dart'),
      Skill(name: 'System Architecture'),
    ],
  );

  group('AICoverLetterService Tests', () {
    test('Offline generation fallback produces valid markdown in all 3 tones', () async {
      final keyStorage = MockKeyStorageService(geminiKey: null);
      final service = AICoverLetterService(keyStorage: keyStorage);

      // Professional
      final prof = await service.generateCoverLetter(
        resume: sampleResume,
        jobDescription: 'Seeking Senior Flutter Engineer to lead mobile platform.',
        tone: CoverLetterTone.professional,
        companyName: 'Acme Corp',
        jobTitle: 'Senior Flutter Engineer',
      );
      expect(prof, contains('Alex Morgan'));
      expect(prof, contains('Acme Corp'));
      expect(prof, contains('Senior Flutter Engineer'));
      expect(prof, contains('Sincerely'));

      // Confident
      final conf = await service.generateCoverLetter(
        resume: sampleResume,
        jobDescription: 'Seeking Senior Flutter Engineer.',
        tone: CoverLetterTone.confident,
        companyName: 'Acme Corp',
      );
      expect(conf, contains('Alex Morgan'));
      expect(conf, contains('high-conviction'));

      // Creative
      final creative = await service.generateCoverLetter(
        resume: sampleResume,
        jobDescription: 'Seeking creative engineer.',
        tone: CoverLetterTone.creative,
        companyName: 'Acme Corp',
      );
      expect(creative, contains('Alex Morgan'));
      expect(creative, contains('intersection of curiosity'));
    });

    test('Cover letter stream emits incremental chunks smoothly', () async {
      final keyStorage = MockKeyStorageService(geminiKey: null);
      final service = AICoverLetterService(keyStorage: keyStorage);

      final chunks = <String>[];
      await for (final chunk in service.generateCoverLetterStream(
        resume: sampleResume,
        jobDescription: 'Flutter job description',
        tone: CoverLetterTone.professional,
      )) {
        chunks.add(chunk);
      }

      expect(chunks.length, greaterThan(1));
      final fullText = chunks.join('');
      expect(fullText, contains('Alex Morgan'));
    });

    test('LinkedIn outreach note strictly enforces <= 300 character constraint', () async {
      final keyStorage = MockKeyStorageService(geminiKey: null);
      final service = AICoverLetterService(keyStorage: keyStorage);

      final note = await service.generateLinkedInOutreach(
        resume: sampleResume,
        jobDescription: 'Seeking Staff Mobile Engineer with deep Flutter knowledge.',
        recruiterName: 'Jessica',
        companyName: 'Acme Technologies',
        jobTitle: 'Staff Mobile Engineer',
      );

      expect(note.length, lessThanOrEqualTo(300));
      expect(note, contains('Jessica'));
      expect(note, contains('Acme Technologies'));
    });

    test('Gemini API online mock client generates and streams cover letter', () async {
      final mockClient = MockClient((request) async {
        if (request.url.queryParameters['alt'] == 'sse') {
          final sseData = 'data: {"candidates": [{"content": {"parts": [{"text": "# Alex Morgan\\nDear Hiring Team at TechCorp,\\n\\nI am excited to apply."}]}}]}\n\n';
          return http.Response(sseData, 200, headers: {'content-type': 'text/event-stream'});
        } else {
          return http.Response(
            jsonEncode({
              'candidates': [
                {
                  'content': {
                    'parts': [{'text': 'Hi Recruiter, saw TechCorp is hiring!'}]
                  }
                }
              ]
            }),
            200,
          );
        }
      });

      final keyStorage = MockKeyStorageService(geminiKey: 'AIzaSyFakeKey123');
      final service = AICoverLetterService(keyStorage: keyStorage, client: mockClient);

      final streamResult = await service.generateCoverLetter(
        resume: sampleResume,
        jobDescription: 'We need a Lead Mobile Engineer',
        tone: CoverLetterTone.professional,
        companyName: 'TechCorp',
      );

      expect(streamResult, contains('TechCorp'));
      expect(streamResult, contains('Alex Morgan'));
    });

    test('Cover letter PDF compiles valid binary PDF bytes', () async {
      final keyStorage = MockKeyStorageService(geminiKey: null);
      final service = AICoverLetterService(keyStorage: keyStorage);

      final coverLetterMarkdown = '''
# Alex Morgan
Senior Flutter Engineer

October 1, 2026

Hiring Manager
Acme Corp

Subject: Application for Senior Flutter Engineer

Dear Hiring Manager,

I am writing to express my interest in the position.

Sincerely,
Alex Morgan
''';

      final pdfBytes = await service.generateCoverLetterPdf(
        resume: sampleResume,
        coverLetterText: coverLetterMarkdown,
        companyName: 'Acme Corp',
        jobTitle: 'Senior Flutter Engineer',
      );

      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(100));
      // PDF header validation (%PDF-)
      expect(pdfBytes[0], 0x25); // '%'
      expect(pdfBytes[1], 0x50); // 'P'
      expect(pdfBytes[2], 0x44); // 'D'
      expect(pdfBytes[3], 0x46); // 'F'
    });
  });

  group('CoverLetterGeneratorScreen Widget Tests', () {
    testWidgets('Renders Cover Letter tab, tone selectors, and switches to LinkedIn tab',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            currentResumeProvider.overrideWith((ref) {
              final notifier = CurrentResumeNotifier(ref);
              notifier.setResume(sampleResume);
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: CoverLetterGeneratorScreen(initialResume: sampleResume),
          ),
        ),
      );

      await tester.pumpAndSettle();

      expect(find.text('AI Cover Letter & Outreach'), findsOneWidget);
      expect(find.text('Cover Letter'), findsOneWidget);
      expect(find.text('LinkedIn Outreach'), findsOneWidget);
      expect(find.text('Professional'), findsOneWidget);
      expect(find.text('Confident'), findsOneWidget);
      expect(find.text('Creative'), findsOneWidget);
      expect(find.text('Generate AI Cover Letter'), findsOneWidget);

      // Switch to LinkedIn Outreach tab
      await tester.tap(find.text('LinkedIn Outreach'));
      await tester.pumpAndSettle();

      expect(find.text('LinkedIn Recruiter DM (Max 300 Chars)'), findsOneWidget);
      expect(find.text('Generate Tailored Outreach Note'), findsOneWidget);
    });
  });
}
