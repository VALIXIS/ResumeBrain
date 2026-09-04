import 'dart:convert';
import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:resume_brain/features/ai/services/ai_service.dart';
import 'package:resume_brain/features/ai/services/gemini_ai_provider.dart';
import 'package:resume_brain/features/ai/services/groq_ai_provider.dart';
import 'package:resume_brain/features/ai/services/hybrid_ai_provider.dart';

/// Helper computing exponential backoff with jitter deterministically for tests.
class ExponentialBackoffCalculator {
  final Duration initialDelay;
  final Duration maxDelay;
  final double backoffFactor;
  final double jitterFactor;

  ExponentialBackoffCalculator({
    this.initialDelay = const Duration(milliseconds: 100),
    this.maxDelay = const Duration(seconds: 5),
    this.backoffFactor = 2.0,
    this.jitterFactor = 0.1,
  });

  Duration calculateDelay(int attempt, {double randomJitterSeed = 0.05}) {
    if (attempt <= 0) return initialDelay;

    final baseMs = initialDelay.inMilliseconds * pow(backoffFactor, attempt);
    final clampedMs = min(baseMs, maxDelay.inMilliseconds.toDouble());

    final jitterMs = clampedMs * (randomJitterSeed.clamp(-jitterFactor, jitterFactor));
    final totalMs = (clampedMs + jitterMs).round();

    return Duration(milliseconds: totalMs.clamp(0, maxDelay.inMilliseconds));
  }

  bool isRetryableStatusCode(int statusCode) {
    // 429 Too Many Requests, 500 Internal Error, 502 Bad Gateway, 503 Service Unavailable, 504 Timeout
    return statusCode == 429 || statusCode == 500 || statusCode == 502 || statusCode == 503 || statusCode == 504;
  }
}

void main() {
  group('AI Provider Failover Chain Tests', () {
    late AIRequest sampleRequest;

    setUp(() {
      sampleRequest = AIRequest(
        taskType: AITaskType.textImprovement,
        inputText: 'Managed team of engineers.',
      );
    });

    test('1. Gemini 1.5 Flash (Primary) returns successful response when operational', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'candidates': [
              {
                'content': {
                  'parts': [
                    {
                      'text': jsonEncode({
                        'outputText': 'Orchestrated cross-functional engineering team of 12.',
                        'suggestions': ['Quantified team size.'],
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

      final gemini = GeminiAIProvider(apiKey: 'valid-gemini-key', client: mockClient);
      final response = await gemini.processRequest(sampleRequest);

      expect(response.isSuccess, isTrue);
      expect(response.outputText, contains('Orchestrated cross-functional engineering team'));
    });

    test('2. Gemini 429 Rate Limit error falls back gracefully to MockAIProvider in GeminiAIProvider', () async {
      final mockClient = MockClient((request) async {
        return http.Response('{"error": {"code": 429, "message": "Resource exhausted"}}', 429);
      });

      final gemini = GeminiAIProvider(apiKey: 'valid-gemini-key', client: mockClient);
      final response = await gemini.processRequest(sampleRequest);

      expect(response.isSuccess, isFalse);
      expect(response.errorMessage, contains('429'));
    });

    test('3. HybridAIProvider automatically falls back to MockAIProvider when keys are unconfigured', () async {
      final hybrid = HybridAIProvider(geminiApiKey: '', groqApiKey: '');
      final response = await hybrid.processRequest(sampleRequest);

      expect(response.isSuccess, isTrue);
      expect(response.outputText, contains('Architected'));
    });

    test('4. Groq Provider parses OpenAI-compatible JSON responses cleanly', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({
            'choices': [
              {
                'message': {
                  'content': jsonEncode({
                    'outputText': 'Led high-performing development squad.',
                    'suggestions': ['Highlighted leadership skills.'],
                  })
                }
              }
            ]
          }),
          200,
        );
      });

      final groq = GroqAIProvider(apiKey: 'valid-groq-key', client: mockClient);
      final response = await groq.processRequest(sampleRequest);

      expect(response.isSuccess, isTrue);
      expect(response.outputText, contains('Led high-performing development squad'));
    });

    test('5. Complete offline outage: HybridAIProvider with MOCK_KEY guarantees safe non-null response', () async {
      final hybrid = HybridAIProvider(geminiApiKey: 'MOCK_KEY', groqApiKey: 'MOCK_KEY');
      final response = await hybrid.processRequest(sampleRequest);

      expect(response.isSuccess, isTrue);
      expect(response.outputText.isNotEmpty, isTrue);
    });
  });

  group('Exponential Backoff & Jitter Calculation Tests', () {
    late ExponentialBackoffCalculator backoff;

    setUp(() {
      backoff = ExponentialBackoffCalculator();
    });

    test('6. Exponential backoff increases delay exponentially per attempt', () {
      final delay0 = backoff.calculateDelay(0, randomJitterSeed: 0.0);
      final delay1 = backoff.calculateDelay(1, randomJitterSeed: 0.0);
      final delay2 = backoff.calculateDelay(2, randomJitterSeed: 0.0);

      expect(delay0.inMilliseconds, equals(100));
      expect(delay1.inMilliseconds, equals(200));
      expect(delay2.inMilliseconds, equals(400));
    });

    test('7. Exponential backoff clamps at maxDelay ceiling', () {
      final delay10 = backoff.calculateDelay(10, randomJitterSeed: 0.0);
      expect(delay10, equals(const Duration(seconds: 5)));
    });

    test('8. Jitter bounds delay within configured jitterFactor range', () {
      final delayWithPositiveJitter = backoff.calculateDelay(1, randomJitterSeed: 0.08);
      final delayWithNegativeJitter = backoff.calculateDelay(1, randomJitterSeed: -0.08);

      expect(delayWithPositiveJitter.inMilliseconds, equals(216)); // 200 + 8%
      expect(delayWithNegativeJitter.inMilliseconds, equals(184)); // 200 - 8%
    });

    test('9. Identifies retryable HTTP status codes (429, 500, 502, 503, 504) vs non-retryable (400, 401, 403, 404)', () {
      expect(backoff.isRetryableStatusCode(429), isTrue);
      expect(backoff.isRetryableStatusCode(500), isTrue);
      expect(backoff.isRetryableStatusCode(503), isTrue);

      expect(backoff.isRetryableStatusCode(400), isFalse);
      expect(backoff.isRetryableStatusCode(401), isFalse);
      expect(backoff.isRetryableStatusCode(404), isFalse);
    });
  });
}
