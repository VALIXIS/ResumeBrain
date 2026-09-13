import 'package:flutter_test/flutter_test.dart';
import 'package:resume_brain/features/ai/services/ai_service.dart';
import 'package:resume_brain/features/ai/services/hybrid_ai_provider.dart';

void main() {
  group('HybridAIProvider Tests', () {
    test('HybridAIProvider falls back to MockAIProvider when keys are empty — signals offline', () async {
      final provider = HybridAIProvider(geminiApiKey: '', groqApiKey: '');
      final response = await provider.processRequest(
        AIRequest(taskType: AITaskType.textImprovement, inputText: 'Software developer'),
      );

      // MockAIProvider now correctly signals AI is offline rather than faking success
      expect(response.isSuccess, isFalse);
      expect(response.errorMessage, isNotNull);
      expect(response.errorMessage, contains('AI offline'));
    });
  });
}
