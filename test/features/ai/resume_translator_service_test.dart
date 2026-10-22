import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:resume_brain/app/providers.dart';
import 'package:resume_brain/data/models/resume_models.dart';
import 'package:resume_brain/features/ai/services/ai_key_storage_service.dart';
import 'package:resume_brain/features/ai/services/resume_translator_service.dart';
import 'package:resume_brain/features/resume/screens/translate_resume_screen.dart';

class MockKeyStorageService extends AIKeyStorageService {
  final String? geminiKey;
  MockKeyStorageService({this.geminiKey});

  @override
  Future<String?> getGeminiKey() async => geminiKey;
}

void main() {
  final testResume = Resume(
    id: 'test-resume-101',
    title: 'Mobile Architect Resume',
    templateId: 'modern_classic',
    personalInfo: PersonalInformation(
      fullName: 'Marcus Vance',
      jobTitle: 'Senior Software Engineer',
      email: 'marcus.vance@techcorp.io',
      phone: '+1 (555) 839-2049',
      location: 'San Francisco, CA, United States',
      website: 'https://marcusvance.dev',
    ),
    summary: ProfessionalSummary(
      summaryText: 'Engineered high-scale mobile platforms serving 1.5M+ active users with 99.9% uptime.',
    ),
    experiences: [
      Experience(
        id: 'exp-1',
        company: 'CloudScale Technologies',
        position: 'Senior Software Engineer',
        startDate: 'Jan 2022',
        endDate: 'Present',
        isCurrent: true,
        description: 'Architected real-time WebSocket messaging layer, reducing API latency by 42% and scaling to 25,000+ RPS.',
      ),
    ],
    educationList: [
      Education(
        id: 'edu-1',
        institution: 'University of California, Berkeley',
        degree: 'Bachelor of Science',
        fieldOfStudy: 'Computer Science',
        startDate: '2017',
        endDate: '2021',
      ),
    ],
    skills: [
      Skill(id: 'skill-1', name: 'Flutter', level: 'Expert'),
      Skill(id: 'skill-2', name: 'Dart', level: 'Expert'),
      Skill(id: 'skill-3', name: 'AWS', level: 'Intermediate'),
    ],
    customSections: [
      CustomSection(
        id: 'sec-1',
        title: 'Publications',
        items: ['Published paper on Reactive Distributed Mobile State Machines (2024).'],
      ),
    ],
  );

  group('ResumeTranslatorService Multi-Language Tests', () {
    test('Offline translation to Spanish preserves IDs, URLs, numbers and translates titles/actions', () async {
      final keyStorage = MockKeyStorageService(geminiKey: null);
      final service = ResumeTranslatorService(keyStorage: keyStorage);

      final result = await service.translateResume(
        resume: testResume,
        targetLanguage: ResumeLanguage.spanish,
      );

      expect(result.isSuccess, isTrue);
      final translated = result.translatedResume!;

      // Preserved fields
      expect(translated.id, equals(testResume.id));
      expect(translated.templateId, equals(testResume.templateId));
      expect(translated.personalInfo.email, equals(testResume.personalInfo.email));
      expect(translated.personalInfo.phone, equals(testResume.personalInfo.phone));
      expect(translated.personalInfo.website, equals(testResume.personalInfo.website));

      // Localized fields
      expect(translated.personalInfo.jobTitle, contains('Ingeniero de Software Senior'));
      expect(translated.personalInfo.location, contains('Estados Unidos'));
      expect(translated.experiences.first.description, contains('Diseñó la arquitectura de'));
      expect(translated.experiences.first.description, contains('42%'));
      expect(translated.experiences.first.description, contains('25,000+ RPS'));
      expect(translated.educationList.first.fieldOfStudy, contains('Ciencias de la Computación'));
      expect(translated.customSections.first.title, equals('Publicaciones'));
    });

    test('Offline translation to German localizes job title and action verbs correctly', () async {
      final keyStorage = MockKeyStorageService(geminiKey: null);
      final service = ResumeTranslatorService(keyStorage: keyStorage);

      final result = await service.translateResume(
        resume: testResume,
        targetLanguage: ResumeLanguage.german,
      );

      expect(result.isSuccess, isTrue);
      final translated = result.translatedResume!;

      expect(translated.personalInfo.jobTitle, contains('Leitender Softwareentwickler'));
      expect(translated.personalInfo.location, contains('Vereinigte Staaten'));
      expect(translated.experiences.first.description, contains('Entwarf die Architektur von'));
      expect(translated.educationList.first.fieldOfStudy, contains('Informatik'));
      expect(translated.customSections.first.title, equals('Veröffentlichungen'));
    });

    test('Offline translation to French translates degrees and sections accurately', () async {
      final keyStorage = MockKeyStorageService(geminiKey: null);
      final service = ResumeTranslatorService(keyStorage: keyStorage);

      final result = await service.translateResume(
        resume: testResume,
        targetLanguage: ResumeLanguage.french,
      );

      expect(result.isSuccess, isTrue);
      final translated = result.translatedResume!;

      expect(translated.personalInfo.jobTitle, contains('Ingénieur Logiciel Senior'));
      expect(translated.personalInfo.location, contains('États-Unis'));
      expect(translated.experiences.first.description, contains('A architecturé'));
      expect(translated.educationList.first.fieldOfStudy, contains('Informatique'));
      expect(translated.customSections.first.title, equals('Publications'));
    });

    test('Offline translation to Japanese formats business CV style with token preservation', () async {
      final keyStorage = MockKeyStorageService(geminiKey: null);
      final service = ResumeTranslatorService(keyStorage: keyStorage);

      final result = await service.translateResume(
        resume: testResume,
        targetLanguage: ResumeLanguage.japanese,
      );

      expect(result.isSuccess, isTrue);
      final translated = result.translatedResume!;

      expect(translated.personalInfo.jobTitle, contains('シニアソフトウェアエンジニア'));
      expect(translated.personalInfo.location, contains('アメリカ合衆国'));
      expect(translated.experiences.first.description, contains('アーキテクチャ構築：'));
      expect(translated.educationList.first.fieldOfStudy, contains('情報科学'));
      expect(translated.customSections.first.title, equals('発表・論文'));
    });

    test('Online Gemini API translation response parses schema safely with merged fields', () async {
      final mockApiResponse = {
        'schemaVersion': 1,
        'id': 'temp-id',
        'title': 'Translated Title',
        'createdAt': '2026-10-01T00:00:00.000Z',
        'updatedAt': '2026-10-01T00:00:00.000Z',
        'templateId': 'modern_classic',
        'personalInfo': {
          'fullName': 'Marcus Vance',
          'jobTitle': 'Ingénieur Logiciel Principal',
          'email': 'should_be_preserved@techcorp.io',
          'phone': '+1 (555) 839-2049',
          'location': 'San Francisco, CA, États-Unis',
          'website': 'https://marcusvance.dev'
        },
        'summary': {
          'summaryText': 'A conçu des plateformes mobiles haute performance pour 1.5M+ utilisateurs actifs.'
        },
        'experiences': [
          {
            'id': 'exp-1',
            'company': 'CloudScale Technologies',
            'position': 'Ingénieur Logiciel Principal',
            'location': '',
            'startDate': 'Jan 2022',
            'endDate': 'Present',
            'isCurrent': true,
            'description': 'A architecturé la couche de messagerie WebSocket temps réel.'
          }
        ],
        'educationList': [],
        'projects': [],
        'skills': [],
        'certifications': [],
        'languages': [],
        'customSections': [],
        'socialLinks': []
      };

      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': jsonEncode(mockApiResponse)}
                  ]
                }
              }
            ]
          }),
          200,
        );
      });

      final keyStorage = MockKeyStorageService(geminiKey: 'AIzaSyOnlineKey123');
      final service = ResumeTranslatorService(keyStorage: keyStorage, client: mockClient);

      final result = await service.translateResume(
        resume: testResume,
        targetLanguage: ResumeLanguage.french,
      );

      expect(result.isSuccess, isTrue);
      expect(result.translatedResume!.personalInfo.jobTitle, equals('Ingénieur Logiciel Principal'));
      expect(result.translatedResume!.personalInfo.email, equals(testResume.personalInfo.email));
    });

    test('Translated Resume compiles valid PDF bytes', () async {
      final keyStorage = MockKeyStorageService(geminiKey: null);
      final service = ResumeTranslatorService(keyStorage: keyStorage);

      final result = await service.translateResume(
        resume: testResume,
        targetLanguage: ResumeLanguage.spanish,
      );

      final pdfBytes = await service.buildTranslatedPdfBytes(result.translatedResume!);
      expect(pdfBytes, isNotNull);
      expect(pdfBytes.length, greaterThan(100));
      expect(pdfBytes[0], 0x25); // '%'
      expect(pdfBytes[1], 0x50); // 'P'
      expect(pdfBytes[2], 0x44); // 'D'
      expect(pdfBytes[3], 0x46); // 'F'
    });
  });

  group('TranslateResumeScreen Widget Tests', () {
    testWidgets('Renders language picker, original vs translated panels, and triggers translation',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            aiKeyStorageServiceProvider.overrideWithValue(MockKeyStorageService(geminiKey: null)),
            currentResumeProvider.overrideWith((ref) {
              final notifier = CurrentResumeNotifier(ref);
              notifier.setResume(testResume);
              return notifier;
            }),
          ],
          child: MaterialApp(
            home: TranslateResumeScreen(initialResume: testResume),
          ),
        ),
      );

      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(find.text('Multi-Language Translation'), findsOneWidget);
      expect(find.text('Spanish'), findsOneWidget);
      expect(find.text('German'), findsOneWidget);
      expect(find.text('French'), findsOneWidget);
      expect(find.text('Japanese'), findsOneWidget);

      // Tap German chip
      await tester.tap(find.text('German'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      // Tap Translate Button
      expect(find.textContaining('Translate to German'), findsOneWidget);
      await tester.tap(find.textContaining('Translate to German'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();

      // Verify translated elements appear
      expect(find.text('Export Translated PDF'), findsOneWidget);
      expect(find.text('Save As Resume'), findsOneWidget);
    });
  });
}
