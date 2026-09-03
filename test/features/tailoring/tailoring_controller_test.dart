import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:resume_brain/app/providers.dart';
import 'package:resume_brain/data/models/resume_models.dart';
import 'package:resume_brain/features/ai/services/ai_service.dart';
import 'package:resume_brain/features/ai/services/gemini_ai_provider.dart';
import 'package:resume_brain/features/ai/services/groq_ai_provider.dart';
import 'package:resume_brain/features/ai/services/resume_ai_prompt_engine.dart';

void main() {
  late Resume sampleResume;

  setUp(() {
    sampleResume = Resume(
      id: 'tailor-test-resume-1',
      title: 'Senior Software Engineer',
      personalInfo: PersonalInformation(
        fullName: 'Alex Vance',
        jobTitle: 'Senior Full Stack Engineer',
        email: 'alex.vance@valixis.com',
        phone: '+1 555-019-9988',
        location: 'San Francisco, CA',
      ),
      summary: ProfessionalSummary(
        summaryText: 'Software engineer building web and mobile applications.',
      ),
      experiences: [
        Experience(
          id: 'exp-1',
          company: 'Acme Corp',
          position: 'Senior Engineer',
          description: 'Built backend microservices and Flutter apps.',
        ),
      ],
      skills: [
        Skill(id: 's-1', name: 'Flutter', level: 'Expert'),
        Skill(id: 's-2', name: 'Dart', level: 'Expert'),
      ],
    );
  });

  group('ResumeAIPromptEngine - Prompt Generation Unit Tests', () {
    test('1. buildResumeTailoringPrompt generates complete prompt with system persona and XYZ formula', () {
      const jdText = 'Seeking a Senior Mobile Engineer with Flutter, Dart, and GraphQL experience.';

      final prompt = ResumeAIPromptEngine.buildResumeTailoringPrompt(sampleResume, jdText);

      expect(prompt, contains('Chief AI Resume Strategist'));
      expect(prompt, contains('GOOGLE XYZ FORMULA'));
      expect(prompt, contains('TASK: 1-CLICK RESUME TAILORING'));
      expect(prompt, contains('TARGET JOB DESCRIPTION'));
      expect(prompt, contains(jdText));
      expect(prompt, contains('Software engineer building web and mobile applications.'));
      expect(prompt, contains('Acme Corp'));
    });

    test('2. buildTextImprovementPrompt constructs section-specific enhancement prompt', () {
      const textToImprove = 'Responsible for managing database backups and API development.';

      final prompt = ResumeAIPromptEngine.buildTextImprovementPrompt(textToImprove, sectionContext: 'Work Experience');

      expect(prompt, contains('SECTION CONTEXT: Work Experience'));
      expect(prompt, contains(textToImprove));
      expect(prompt, contains('STRICT BANNED WEAK PHRASES'));
      expect(prompt, contains('ELITE POWER VERBS ONLY'));
    });

    test('3. buildResumeAnalysisPrompt incorporates full resume audit structure', () {
      final prompt = ResumeAIPromptEngine.buildResumeAnalysisPrompt(sampleResume);

      expect(prompt, contains('COMPREHENSIVE ATS RESUME AUDIT'));
      expect(prompt, contains('Alex Vance'));
      expect(prompt, contains('Senior Full Stack Engineer'));
      expect(prompt, contains('Flutter, Dart'));
      expect(prompt, contains('EVALUATION MATRIX:'));
    });

    test('4. buildJobMatchingPrompt incorporates JD and resume candidate summary', () {
      const jdText = 'Requirements: Python, FastAPI, Docker, Kubernetes.';

      final prompt = ResumeAIPromptEngine.buildJobMatchingPrompt(sampleResume, jdText);

      expect(prompt, contains('JOB DESCRIPTION MATCHING & SKILL GAP ANALYSIS'));
      expect(prompt, contains(jdText));
      expect(prompt, contains('Senior Full Stack Engineer'));
    });
  });

  group('GeminiAIProvider - Live HTTP Boundary & Mocking Tests', () {
    test('5. GeminiAIProvider formats HTTP request and parses valid JSON AI response', () async {
      final mockJsonResponse = jsonEncode({
        'candidates': [
          {
            'content': {
              'parts': [
                {
                  'text': jsonEncode({
                    'outputText': 'Spearheaded mobile development using Flutter and Dart, boosting app performance by 40%.',
                    'score': 92.5,
                    'suggestions': [
                      'Highlight backend microservices experience.',
                      'Quantify database query optimization.',
                    ],
                    'metricsApplied': ['40% performance boost'],
                    'powerVerbs': ['Spearheaded', 'Optimized'],
                    'missingKeywords': ['GraphQL', 'Docker'],
                    'subScores': {
                      'impactQuantification': 90.0,
                      'atsReadability': 95.0,
                      'actionVerbs': 92.0,
                      'skillsRelevance': 93.0,
                    },
                  })
                }
              ]
            }
          }
        ]
      });

      late String interceptedRequestBody;

      final mockClient = MockClient((request) async {
        interceptedRequestBody = request.body;
        expect(request.url.host, equals('generativelanguage.googleapis.com'));
        expect(request.headers['Content-Type'], equals('application/json'));

        return http.Response(mockJsonResponse, 200);
      });

      final provider = GeminiAIProvider(
        apiKey: 'TEST_GEMINI_LIVE_KEY_123',
        client: mockClient,
      );

      final service = ResumeBrainAIService(provider: provider);
      final response = await service.tailorResume(
        sampleResume,
        'Seeking Flutter Engineer with GraphQL experience.',
      );

      expect(response.isSuccess, isTrue);
      expect(response.outputText, contains('Spearheaded mobile development'));
      expect(response.score, equals(92.5));
      expect(response.suggestions.length, equals(2));
      expect(response.metricsApplied, contains('40% performance boost'));
      expect(response.powerVerbs, contains('Spearheaded'));
      expect(response.missingKeywords, contains('GraphQL'));
      expect(response.subScores['impactQuantification'], equals(90.0));

      expect(interceptedRequestBody, contains('1-CLICK RESUME TAILORING'));
    });

    test('6. GroqAIProvider handles HTTP 500 error gracefully without throwing exception', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"error": "Internal Server Error"}', 500);
      });

      final provider = GroqAIProvider(
        apiKey: 'TEST_GROQ_KEY_456',
        client: mockClient,
      );

      final service = ResumeBrainAIService(provider: provider);
      final response = await service.tailorResume(
        sampleResume,
        'Backend Engineer Job Description',
      );

      expect(response.isSuccess, isFalse);
      expect(response.outputText, isEmpty);
      expect(response.errorMessage, contains('Groq API call failed with status 500'));
    });

    test('7. Handles malformed non-JSON AI output safely with fallback error message', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {'text': 'This is raw unformatted text without valid JSON wrapper.'}
                  ]
                }
              }
            ]
          }),
          200,
        );
      });

      final provider = GeminiAIProvider(
        apiKey: 'TEST_GEMINI_KEY_789',
        client: mockClient,
      );

      final response = await provider.processRequest(
        AIRequest(
          taskType: AITaskType.resumeTailoring,
          resume: sampleResume,
          jobDescription: 'Mobile Developer',
        ),
      );

      expect(response.isSuccess, isFalse);
      expect(response.errorMessage, contains('Gemini AI Provider Error'));
    });

    test('8. Handles missing or empty API keys by falling back to MockAIProvider', () async {
      final provider = GeminiAIProvider(apiKey: '');
      final service = ResumeBrainAIService(provider: provider);

      final response = await service.improveText('Worked on backend APIs.', 'experience');

      expect(response.isSuccess, isTrue);
      expect(response.outputText, contains('Architected and deployed'));
      expect(response.suggestions, isNotEmpty);
    });
  });

  group('Concurrent & Rapid AI Request Tests', () {
    test('9. Executes rapid sequential AI tailoring requests without state cross-pollution', () async {
      final mockClient = MockClient((request) async {
        final isFirst = request.body.contains('Python Developer');
        final output = isFirst ? 'Tailored Python Output' : 'Tailored Java Output';

        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {
                      'text': jsonEncode({
                        'outputText': output,
                        'suggestions': [output],
                      })
                    }
                  ]
                }
              }
            ]
          }),
          200,
        );
      });

      final provider = GeminiAIProvider(apiKey: 'VALID_KEY', client: mockClient);
      final service = ResumeBrainAIService(provider: provider);

      final future1 = service.tailorResume(sampleResume, 'Python Developer');
      final future2 = service.tailorResume(sampleResume, 'Java Developer');

      final results = await Future.wait([future1, future2]);

      expect(results[0].outputText, equals('Tailored Python Output'));
      expect(results[1].outputText, equals('Tailored Java Output'));
    });

    test('10. ProviderContainer state isolation across AI service instances', () async {
      final containerA = ProviderContainer(
        overrides: [
          aiServiceProvider.overrideWithValue(
            ResumeBrainAIService(provider: MockAIProvider()),
          ),
        ],
      );
      final containerB = ProviderContainer(
        overrides: [
          aiServiceProvider.overrideWithValue(
            ResumeBrainAIService(provider: MockAIProvider()),
          ),
        ],
      );

      final serviceA = containerA.read(aiServiceProvider);
      final serviceB = containerB.read(aiServiceProvider);

      final resA = await serviceA.improveText('Text A', 'summary');
      final resB = await serviceB.improveText('Text B', 'summary');

      expect(resA.isSuccess, isTrue);
      expect(resB.isSuccess, isTrue);

      containerA.dispose();
      containerB.dispose();
    });
  });
}
