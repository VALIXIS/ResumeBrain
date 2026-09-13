import 'ai_key_storage_service.dart';
import 'ai_service.dart';
import 'gemini_ai_provider.dart';
import 'groq_ai_provider.dart';
import 'openai_ai_provider.dart';
import 'supabase_ai_provider.dart';

/// Production-grade Hybrid AI Provider for lakhs of students.
/// Automatically handles failover across Google Gemini 1.5 Flash (Primary Free),
/// Groq Llama 3.1 70B (Secondary Free), Supabase Edge Function AI Gateway (Secure Server Proxy),
/// and Rule-Based Mock Engine (Offline Fallback).
class HybridAIProvider implements AIProvider {
  final String geminiApiKey;
  final String groqApiKey;

  late final GeminiAIProvider _geminiProvider;
  late final GroqAIProvider _groqProvider;
  final SupabaseAIProvider _supabaseAIProvider = SupabaseAIProvider();
  final MockAIProvider _mockProvider = MockAIProvider();

  HybridAIProvider({
    this.geminiApiKey = '',
    this.groqApiKey = '',
  }) {
    _geminiProvider = GeminiAIProvider(apiKey: geminiApiKey);
    _groqProvider = GroqAIProvider(apiKey: groqApiKey);
  }

  @override
  String get providerName => 'VALIXIS Hybrid AI Core (Gemini + Groq + Cloud Gateway)';

  @override
  Future<AIResponse> processRequest(AIRequest request) async {
    // 1. Try Google Gemini 1.5 Flash (User BYOK Direct)
    if (geminiApiKey.isNotEmpty && geminiApiKey != 'MOCK_KEY') {
      final response = await _geminiProvider.processRequest(request);
      if (response.isSuccess) return response;
    }

    // 2. Try Groq Cloud Llama 3.1 70B (User BYOK Direct)
    if (groqApiKey.isNotEmpty && groqApiKey != 'MOCK_KEY') {
      final response = await _groqProvider.processRequest(request);
      if (response.isSuccess) return response;
    }

    // 3. Try Supabase Edge Function AI Gateway Proxy (Secure Production Server-Side API)
    final cloudResponse = await _supabaseAIProvider.processRequest(request);
    if (cloudResponse.isSuccess) return cloudResponse;

    // 4. Fallback to offline rule-based engine (Guarantees zero app crashes)
    return _mockProvider.processRequest(request);
  }
}

/// Dynamic AI Provider that dynamically consumes user-configured API keys
/// from hardware-backed secure storage, falling back to compile-time keys and rule-based mock engine.
class DynamicAIProvider implements AIProvider {
  final AIKeyStorageService keyStorage;
  final String defaultGeminiKey;
  final String defaultGroqKey;

  DynamicAIProvider({
    required this.keyStorage,
    this.defaultGeminiKey = '',
    this.defaultGroqKey = '',
  });

  @override
  String get providerName => 'VALIXIS Dynamic AI Core';

  @override
  Future<AIResponse> processRequest(AIRequest request) async {
    try {
      final activeProvider = await keyStorage.getActiveProvider();
      final geminiKey = (await keyStorage.getGeminiKey())?.trim();
      final groqKey = (await keyStorage.getGroqKey())?.trim();
      final openaiKey = (await keyStorage.getOpenAIKey())?.trim();

      final effectiveGemini = (geminiKey != null && geminiKey.isNotEmpty) ? geminiKey : defaultGeminiKey;
      final effectiveGroq = (groqKey != null && groqKey.isNotEmpty) ? groqKey : defaultGroqKey;

      if (activeProvider == ActiveAIProviderType.gemini && effectiveGemini.isNotEmpty) {
        return await GeminiAIProvider(apiKey: effectiveGemini).processRequest(request);
      } else if (activeProvider == ActiveAIProviderType.groq && effectiveGroq.isNotEmpty) {
        return await GroqAIProvider(apiKey: effectiveGroq).processRequest(request);
      } else if (activeProvider == ActiveAIProviderType.openai && openaiKey != null && openaiKey.isNotEmpty) {
        return await OpenAIProvider(apiKey: openaiKey).processRequest(request);
      }

      return HybridAIProvider(
        geminiApiKey: effectiveGemini,
        groqApiKey: effectiveGroq,
      ).processRequest(request);
    } catch (_) {
      return HybridAIProvider(
        geminiApiKey: defaultGeminiKey,
        groqApiKey: defaultGroqKey,
      ).processRequest(request);
    }
  }
}
