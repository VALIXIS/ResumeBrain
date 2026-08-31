import 'ai_service.dart';
import 'gemini_ai_provider.dart';
import 'groq_ai_provider.dart';

/// Production-grade Hybrid AI Provider for lakhs of students.
/// Automatically handles failover across Google Gemini 1.5 Flash (Primary Free),
/// Groq Llama 3.1 70B (Secondary Free), and Rule-Based Mock Engine (Offline Fallback).
class HybridAIProvider implements AIProvider {
  final String geminiApiKey;
  final String groqApiKey;

  late final GeminiAIProvider _geminiProvider;
  late final GroqAIProvider _groqProvider;
  final MockAIProvider _mockProvider = MockAIProvider();

  HybridAIProvider({
    this.geminiApiKey = '',
    this.groqApiKey = '',
  }) {
    _geminiProvider = GeminiAIProvider(apiKey: geminiApiKey);
    _groqProvider = GroqAIProvider(apiKey: groqApiKey);
  }

  @override
  String get providerName => 'VALIXIS Hybrid AI Core (Gemini + Groq Failover)';

  @override
  Future<AIResponse> processRequest(AIRequest request) async {
    // 1. Try Google Gemini 1.5 Flash (Primary)
    if (geminiApiKey.isNotEmpty && geminiApiKey != 'MOCK_KEY') {
      final response = await _geminiProvider.processRequest(request);
      if (response.isSuccess) return response;
    }

    // 2. Try Groq Cloud Llama 3.1 70B (Secondary Failover)
    if (groqApiKey.isNotEmpty && groqApiKey != 'MOCK_KEY') {
      final response = await _groqProvider.processRequest(request);
      if (response.isSuccess) return response;
    }

    // 3. Fallback to offline rule-based engine (Guarantees zero app crashes)
    return _mockProvider.processRequest(request);
  }
}
