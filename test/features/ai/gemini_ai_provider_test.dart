import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:resume_brain/data/models/resume_models.dart';
import 'package:resume_brain/features/ai/services/ai_service.dart';
import 'package:resume_brain/features/ai/services/gemini_ai_provider.dart';

void main() {
  group('GeminiAIProvider Tests', () {
    test('Fallback to MockAIProvider when API key is empty or MOCK_KEY', () async {
      final provider = GeminiAIProvider(apiKey: 'MOCK_KEY');
      final response = await provider.processRequest(
        AIRequest(taskType: AITaskType.textImprovement, inputText: 'Lead developer'),
      );

      expect(response.isSuccess, isTrue);
      expect(response.outputText, contains('Architected'));
    });

    test('Successful Gemini API JSON response parsing with Google XYZ metrics & subScores', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {
                      'text': jsonEncode({
                        'outputText': 'Spearheaded mobile development with 99.9% crash-free rate.',
                        'score': 94.0,
                        'suggestions': ['Quantified success with concrete metrics.'],
                        'metricsApplied': ['99.9% crash-free rate'],
                        'powerVerbs': ['Spearheaded'],
                        'missingKeywords': ['CI/CD', 'GraphQL'],
                        'subScores': {
                          'impactQuantification': 95.0,
                          'atsReadability': 98.0,
                          'actionVerbs': 92.0,
                          'skillsRelevance': 90.0
                        }
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

      final provider = GeminiAIProvider(apiKey: 'VALID_GEMINI_KEY', client: mockClient);
      final sampleResume = Resume(
        id: 'test-1',
        title: 'Software Engineer Resume',
        personalInfo: PersonalInformation(
          fullName: 'John Doe',
          email: 'john@example.com',
          phoneNumber: '+1234567890',
          location: 'San Francisco, CA',
          website: 'https://johndoe.dev',
          jobTitle: 'Senior Flutter Engineer',
        ),
        summary: ProfessionalSummary(
          summaryText: 'Experienced Mobile Engineer specializing in Flutter and Riverpod state management.',
        ),
        experiences: [
          Experience(
            id: 'exp-1',
            company: 'Tech Corp',
            position: 'Mobile Engineer',
            location: 'Remote',
            startDate: '2022',
            endDate: 'Present',
            isCurrent: true,
            bulletPoints: ['Engineered high-performance Flutter mobile application.'],
          )
        ],
        educationList: [
          Education(
            id: 'edu-1',
            institution: 'Stanford University',
            degree: 'B.S.',
            fieldOfStudy: 'Computer Science',
            startDate: '2018',
            endDate: '2022',
          )
        ],
        skills: [
          Skill(id: 's1', name: 'Flutter', category: 'Mobile'),
          Skill(id: 's2', name: 'Dart', category: 'Language'),
        ],
      );

      final response = await provider.processRequest(
        AIRequest(taskType: AITaskType.resumeAnalysis, resume: sampleResume),
      );

      expect(response.isSuccess, isTrue);
      expect(response.outputText, contains('Spearheaded'));
      expect(response.score, 94.0);
      expect(response.suggestions.length, 1);
      expect(response.metricsApplied.first, '99.9% crash-free rate');
      expect(response.powerVerbs.first, 'Spearheaded');
      expect(response.missingKeywords, contains('CI/CD'));
      expect(response.subScores['impactQuantification'], 95.0);
    });
  });
}
