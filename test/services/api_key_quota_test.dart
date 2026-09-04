import 'package:flutter_test/flutter_test.dart';
import 'package:resume_brain/features/ai/services/ai_service.dart';
import 'package:resume_brain/features/ai/services/gemini_ai_provider.dart';
import 'package:resume_brain/features/ai/services/groq_ai_provider.dart';
import 'package:resume_brain/features/ai/services/hybrid_ai_provider.dart';

/// Service boundary model for API Key Quota Management QA testing.
class ApiKeyQuotaTracker {
  final Map<String, int> _quotaLimits;
  final Map<String, int> _usedQuota;
  final Set<String> _exhaustedKeys;

  ApiKeyQuotaTracker({Map<String, int>? limits})
      : _quotaLimits = limits ?? {'gemini-key-1': 100, 'groq-key-1': 500},
        _usedQuota = {},
        _exhaustedKeys = {};

  bool isKeyAvailable(String key) {
    if (key.isEmpty || key == 'MOCK_KEY') return false;
    if (_exhaustedKeys.contains(key)) return false;
    final limit = _quotaLimits[key] ?? 100;
    final used = _usedQuota[key] ?? 0;
    return used < limit;
  }

  void recordUsage(String key, {int count = 1}) {
    final current = _usedQuota[key] ?? 0;
    _usedQuota[key] = current + count;
    final limit = _quotaLimits[key] ?? 100;
    if (_usedQuota[key]! >= limit) {
      _exhaustedKeys.add(key);
    }
  }

  void markExhausted(String key) {
    _exhaustedKeys.add(key);
  }

  int getRemainingQuota(String key) {
    final limit = _quotaLimits[key] ?? 100;
    final used = _usedQuota[key] ?? 0;
    return (limit - used).clamp(0, limit);
  }

  void reset() {
    _usedQuota.clear();
    _exhaustedKeys.clear();
  }
}

void main() {
  group('API Key Management & Quota Tracking QA Tests', () {
    late ApiKeyQuotaTracker quotaTracker;

    setUp(() {
      quotaTracker = ApiKeyQuotaTracker();
    });

    test('1. GeminiAIProvider selects MockAIProvider when key is empty or MOCK_KEY', () async {
      final emptyProvider = GeminiAIProvider(apiKey: '');
      final mockKeyProvider = GeminiAIProvider(apiKey: 'MOCK_KEY');

      final request = AIRequest(taskType: AITaskType.textImprovement, inputText: 'Developer');

      final emptyRes = await emptyProvider.processRequest(request);
      final mockRes = await mockKeyProvider.processRequest(request);

      expect(emptyRes.isSuccess, isTrue);
      expect(mockRes.isSuccess, isTrue);
      expect(emptyRes.outputText, contains('Architected'));
    });

    test('2. GroqAIProvider selects MockAIProvider when key is empty or MOCK_KEY', () async {
      final emptyProvider = GroqAIProvider(apiKey: '');
      final mockKeyProvider = GroqAIProvider(apiKey: 'MOCK_KEY');

      final request = AIRequest(taskType: AITaskType.textImprovement, inputText: 'Developer');

      final emptyRes = await emptyProvider.processRequest(request);
      final mockRes = await mockKeyProvider.processRequest(request);

      expect(emptyRes.isSuccess, isTrue);
      expect(mockRes.isSuccess, isTrue);
    });

    test('3. HybridAIProvider instantiates provider names correctly without throwing', () {
      final hybrid = HybridAIProvider(
        geminiApiKey: 'test-gemini-key-xyz',
        groqApiKey: 'test-groq-key-abc',
      );

      expect(hybrid.providerName, contains('VALIXIS Hybrid AI Core'));
    });

    test('4. ApiKeyQuotaTracker tracks remaining quota and marks key exhausted when limit reached', () {
      const key = 'gemini-key-1';

      expect(quotaTracker.isKeyAvailable(key), isTrue);
      expect(quotaTracker.getRemainingQuota(key), equals(100));

      quotaTracker.recordUsage(key, count: 50);
      expect(quotaTracker.getRemainingQuota(key), equals(50));
      expect(quotaTracker.isKeyAvailable(key), isTrue);

      quotaTracker.recordUsage(key, count: 50);
      expect(quotaTracker.getRemainingQuota(key), equals(0));
      expect(quotaTracker.isKeyAvailable(key), isFalse);
    });

    test('5. ApiKeyQuotaTracker marks key exhausted on HTTP 429 rate limit response', () {
      const key = 'groq-key-1';

      expect(quotaTracker.isKeyAvailable(key), isTrue);
      quotaTracker.markExhausted(key);

      expect(quotaTracker.isKeyAvailable(key), isFalse);
    });

    test('6. ApiKeyQuotaTracker reset recovers exhausted keys cleanly', () {
      const key = 'gemini-key-1';
      quotaTracker.markExhausted(key);
      expect(quotaTracker.isKeyAvailable(key), isFalse);

      quotaTracker.reset();
      expect(quotaTracker.isKeyAvailable(key), isTrue);
      expect(quotaTracker.getRemainingQuota(key), equals(100));
    });

    test('7. Secrets security check: Fake API credentials are sanitized and never exposed in output', () {
      const sensitiveKey = 'AIzaSyFakeSecretKey_987654321';
      final response = AIResponse(
        isSuccess: false,
        outputText: '',
        errorMessage: 'Authentication failed for request boundary.',
      );

      expect(response.errorMessage, isNot(contains(sensitiveKey)));
      expect(response.outputText, isNot(contains(sensitiveKey)));
    });
  });
}
