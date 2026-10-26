import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:resume_brain/features/ai/services/ai_service.dart';
import 'package:resume_brain/features/ai/services/gemini_ai_provider.dart';
import 'package:resume_brain/features/ai/services/groq_ai_provider.dart';
import 'package:resume_brain/features/ai/services/hybrid_ai_provider.dart';
import 'package:resume_brain/features/ai/services/resume_ai_prompt_engine.dart';

class FakeAIProvider implements AIProvider {
  @override
  final String providerName;
  int callCount = 0;
  final List<AIResponse> queuedResponses;

  FakeAIProvider({
    required this.providerName,
    required this.queuedResponses,
  });

  @override
  Future<AIResponse> processRequest(AIRequest request) async {
    callCount++;
    if (queuedResponses.isNotEmpty) {
      if (queuedResponses.length == 1) {
        return queuedResponses.first;
      }
      return queuedResponses.removeAt(0);
    }
    return AIResponse(
      isSuccess: false,
      outputText: '',
      errorMessage: '$providerName has no more queued responses',
    );
  }
}

void main() {
  final sampleRequest = AIRequest(
    taskType: AITaskType.textImprovement,
    inputText: 'Built Flutter mobile application for 100k users.',
  );

  group('HybridAIProvider Fallback & Backoff Tests', () {
    test('HybridAIProvider falls back to MockAIProvider when keys are empty — signals offline', () async {
      final provider = HybridAIProvider(geminiApiKey: '', groqApiKey: '');
      final response = await provider.processRequest(sampleRequest);

      expect(response.isSuccess, isFalse);
      expect(response.errorMessage, isNotNull);
      expect(response.errorMessage, contains('AI offline'));
    });

    test('Immediate fallback from primary (Groq) to secondary (Gemini) on HTTP 429 without retries', () async {
      final groqMock = FakeAIProvider(
        providerName: 'Groq Cloud',
        queuedResponses: [
          AIResponse(
            isSuccess: false,
            outputText: '',
            statusCode: 429,
            errorMessage: 'Groq API call failed with status 429: Rate limit exceeded',
          ),
        ],
      );

      final geminiMock = FakeAIProvider(
        providerName: 'Google Gemini',
        queuedResponses: [
          AIResponse(
            isSuccess: true,
            outputText: 'Architected high-scale Flutter app serving 100,000+ active users.',
            score: 92.0,
          ),
        ],
      );

      final hybrid = HybridAIProvider(
        geminiApiKey: 'test-gemini',
        groqApiKey: 'valid-groq-key',
        primaryProvider: groqMock,
        secondaryProvider: geminiMock,
        initialBackoff: const Duration(milliseconds: 1),
      );

      final stopwatch = Stopwatch()..start();
      final response = await hybrid.processRequest(sampleRequest);
      stopwatch.stop();

      // Primary provider should be invoked exactly once — NO delay or backoff retry loop on 429
      expect(groqMock.callCount, equals(1));
      expect(geminiMock.callCount, equals(1));
      expect(response.isSuccess, isTrue);
      expect(response.outputText, contains('Architected high-scale Flutter app'));
      expect(response.score, equals(92.0));
      expect(stopwatch.elapsedMilliseconds, lessThan(500));
    });

    test('Immediate fallback from primary (Groq) to secondary (Gemini) on HTTP 503 without retries', () async {
      final groqMock = FakeAIProvider(
        providerName: 'Groq Cloud',
        queuedResponses: [
          AIResponse(
            isSuccess: false,
            outputText: '',
            statusCode: 503,
            errorMessage: 'Groq API call failed with status 503: Service Unavailable (model overloaded)',
          ),
        ],
      );

      final geminiMock = FakeAIProvider(
        providerName: 'Google Gemini',
        queuedResponses: [
          AIResponse(
            isSuccess: true,
            outputText: 'Engineered cross-platform mobile architecture reducing crash rate to 0.01%.',
            score: 95.0,
          ),
        ],
      );

      final hybrid = HybridAIProvider(
        geminiApiKey: 'test-gemini',
        groqApiKey: 'valid-groq-key',
        primaryProvider: groqMock,
        secondaryProvider: geminiMock,
        initialBackoff: const Duration(milliseconds: 1),
      );

      final response = await hybrid.processRequest(sampleRequest);

      // Groq called once, instantly failed over to Gemini
      expect(groqMock.callCount, equals(1));
      expect(geminiMock.callCount, equals(1));
      expect(response.isSuccess, isTrue);
      expect(response.outputText, contains('Engineered cross-platform mobile architecture'));
    });

    test('Exponential backoff retries transient 500 error on primary before falling back', () async {
      final groqMock = FakeAIProvider(
        providerName: 'Groq Cloud',
        queuedResponses: [
          AIResponse(isSuccess: false, outputText: '', statusCode: 500, errorMessage: 'Internal error'),
          AIResponse(isSuccess: false, outputText: '', statusCode: 500, errorMessage: 'Internal error retry 1'),
          AIResponse(isSuccess: false, outputText: '', statusCode: 500, errorMessage: 'Internal error retry 2'),
        ],
      );

      final geminiMock = FakeAIProvider(
        providerName: 'Google Gemini',
        queuedResponses: [
          AIResponse(
            isSuccess: true,
            outputText: 'Overhauled mobile client infrastructure.',
          ),
        ],
      );

      final hybrid = HybridAIProvider(
        geminiApiKey: 'test-gemini',
        groqApiKey: 'valid-groq-key',
        primaryProvider: groqMock,
        secondaryProvider: geminiMock,
        maxRetries: 2,
        initialBackoff: const Duration(milliseconds: 5),
        backoffMultiplier: 2.0,
      );

      final response = await hybrid.processRequest(sampleRequest);

      // Initial attempt (0) + 2 retries (1, 2) = 3 total attempts on primary
      expect(groqMock.callCount, equals(3));
      // Then falls back to secondary provider
      expect(geminiMock.callCount, equals(1));
      expect(response.isSuccess, isTrue);
      expect(response.outputText, contains('Overhauled mobile client infrastructure'));
    });

    test('Exponential backoff recovers on primary when transient failure succeeds on retry', () async {
      final groqMock = FakeAIProvider(
        providerName: 'Groq Cloud',
        queuedResponses: [
          AIResponse(isSuccess: false, outputText: '', statusCode: 502, errorMessage: 'Bad gateway'),
          AIResponse(
            isSuccess: true,
            outputText: 'Optimized real-time state synchronization.',
            score: 89.0,
          ),
        ],
      );

      final geminiMock = FakeAIProvider(
        providerName: 'Google Gemini',
        queuedResponses: [],
      );

      final hybrid = HybridAIProvider(
        geminiApiKey: 'test-gemini',
        groqApiKey: 'valid-groq-key',
        primaryProvider: groqMock,
        secondaryProvider: geminiMock,
        maxRetries: 2,
        initialBackoff: const Duration(milliseconds: 5),
      );

      final response = await hybrid.processRequest(sampleRequest);

      // Recovered on attempt 2 — secondary provider should never be called
      expect(groqMock.callCount, equals(2));
      expect(geminiMock.callCount, equals(0));
      expect(response.isSuccess, isTrue);
      expect(response.outputText, contains('Optimized real-time state synchronization'));
    });
  });

  group('ResumeAIPromptEngine JSON Sanitization & Unclosed Braces Tests', () {
    test('Repairs truncated nested JSON object with unclosed braces', () {
      const truncated = '{"outputText": "Spearheaded mobile development", "subScores": {"atsReadability": 90, "actionVerbs": 88';
      final sanitized = ResumeAIPromptEngine.sanitizeJsonResponse(truncated);
      final decoded = jsonDecode(sanitized) as Map<String, dynamic>;

      expect(decoded['outputText'], equals('Spearheaded mobile development'));
      expect(decoded['subScores']['atsReadability'], equals(90));
      expect(decoded['subScores']['actionVerbs'], equals(88));
    });

    test('Repairs truncated array with unclosed brackets and object braces', () {
      const truncated = '{"outputText": "Engineered microservices", "suggestions": ["Add metrics", "Highlight AWS"';
      final sanitized = ResumeAIPromptEngine.sanitizeJsonResponse(truncated);
      final decoded = jsonDecode(sanitized) as Map<String, dynamic>;

      expect(decoded['outputText'], equals('Engineered microservices'));
      expect(decoded['suggestions'], isA<List>());
      expect(decoded['suggestions'].length, greaterThanOrEqualTo(1));
    });

    test('Repairs unclosed string literal and trailing comma', () {
      const truncated = '{"outputText": "Streamlined CI/CD pipeline reducing build times by 45%,';
      final sanitized = ResumeAIPromptEngine.sanitizeJsonResponse(truncated);
      final decoded = jsonDecode(sanitized) as Map<String, dynamic>;

      expect(decoded['outputText'], contains('Streamlined CI/CD pipeline'));
    });

    test('Strips markdown code fences and preamble text around truncated JSON', () {
      const rawWithMarkdown = '''
Here is your optimized ATS resume data:
```json
{
  "outputText": "Architected event-driven architecture",
  "score": 94,
  "metricsApplied": ["45% latency reduction"]
''';
      final parsed = ResumeAIPromptEngine.parseAndSanitizeJson(rawWithMarkdown);

      expect(parsed['outputText'], equals('Architected event-driven architecture'));
      expect(parsed['score'], equals(94));
      expect(parsed['metricsApplied'], contains('45% latency reduction'));
    });

    test('Repairs trailing incomplete key at end of JSON', () {
      const truncatedKey = '{"outputText": "Quantified team output", "score": 85, "brokenKey';
      final parsed = ResumeAIPromptEngine.parseAndSanitizeJson(truncatedKey);

      expect(parsed['outputText'], equals('Quantified team output'));
      expect(parsed['score'], equals(85));
    });

    test('Handles empty or invalid input with safe fallback', () {
      final parsed = ResumeAIPromptEngine.parseAndSanitizeJson('');
      expect(parsed, isA<Map<String, dynamic>>());
      expect(parsed['score'], equals(0.0));
      expect(parsed['outputText'], equals(''));
    });

    test('GroqAIProvider seamlessly handles unclosed JSON response from LLM', () async {
      // Simulate LLM cutting off mid-stream due to max token limits
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': '{"outputText": "Pioneered automated testing suite", "score": 91, "suggestions": ["Increase unit test coverage"'
                }
              }
            ]
          }),
          200,
        );
      });

      final groq = GroqAIProvider(apiKey: 'test-groq-key', client: mockClient);
      final response = await groq.processRequest(sampleRequest);

      expect(response.isSuccess, isTrue);
      expect(response.outputText, equals('Pioneered automated testing suite'));
      expect(response.score, equals(91.0));
      expect(response.suggestions, isNotEmpty);
    });

    test('GeminiAIProvider seamlessly handles unclosed JSON response from LLM', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {
                      'text': '{"outputText": "Consolidated legacy services into microservices", "subScores": {"impactQuantification": 94'
                    }
                  ]
                }
              }
            ]
          }),
          200,
        );
      });

      final gemini = GeminiAIProvider(apiKey: 'test-gemini-key', client: mockClient);
      final response = await gemini.processRequest(sampleRequest);

      expect(response.isSuccess, isTrue);
      expect(response.outputText, equals('Consolidated legacy services into microservices'));
      expect(response.subScores['impactQuantification'], equals(94.0));
    });
  });
}
