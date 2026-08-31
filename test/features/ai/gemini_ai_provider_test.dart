import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
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

    test('Successful Gemini API JSON response parsing', () async {
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
                        'score': 92.0,
                        'suggestions': ['Quantified success with concrete metrics.']
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
      final response = await provider.processRequest(
        AIRequest(taskType: AITaskType.textImprovement, inputText: 'Developer on app'),
      );

      expect(response.isSuccess, isTrue);
      expect(response.outputText, contains('Spearheaded'));
      expect(response.score, 92.0);
      expect(response.suggestions.length, 1);
    });
  });
}
