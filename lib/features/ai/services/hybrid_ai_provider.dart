import 'dart:math';
import 'ai_key_storage_service.dart';
import 'ai_service.dart';
import 'gemini_ai_provider.dart';
import 'groq_ai_provider.dart';
import 'openai_ai_provider.dart';
import 'supabase_ai_provider.dart';

/// Production-grade Hybrid AI Provider for lakhs of students.
/// Automatically handles failover across Groq Llama 3.1 70B (Primary Fast Tier),
/// Google Gemini 1.5 Flash (Secondary Free), Supabase Edge Function AI Gateway (Secure Server Proxy),
/// and Rule-Based Mock Engine (Offline Fallback).
///
/// Implements exponential backoff retry for transient network errors (500, 502, 504, timeouts),
/// and immediate instant failover to secondary provider when HTTP 429 (Rate Limit) or 503 (Overloaded)
/// is returned.
class HybridAIProvider implements AIProvider {
  final String geminiApiKey;
  final String groqApiKey;
  final AIProvider? primaryProvider;
  final AIProvider? secondaryProvider;
  final AIProvider? cloudProvider;
  final AIProvider? offlineProvider;
  final int maxRetries;
  final Duration initialBackoff;
  final double backoffMultiplier;
  final bool preferGroqPrimary;

  late final AIProvider _effectivePrimary;
  late final AIProvider _effectiveSecondary;
  late final AIProvider _effectiveCloud;
  late final AIProvider _effectiveOffline;

  HybridAIProvider({
    this.geminiApiKey = '',
    this.groqApiKey = '',
    this.primaryProvider,
    this.secondaryProvider,
    this.cloudProvider,
    this.offlineProvider,
    this.maxRetries = 2,
    this.initialBackoff = const Duration(milliseconds: 100),
    this.backoffMultiplier = 2.0,
    this.preferGroqPrimary = true,
  }) {
    final gemini = GeminiAIProvider(apiKey: geminiApiKey);
    final groq = GroqAIProvider(apiKey: groqApiKey);

    if (primaryProvider != null && secondaryProvider != null) {
      _effectivePrimary = primaryProvider!;
      _effectiveSecondary = secondaryProvider!;
    } else if (primaryProvider != null) {
      _effectivePrimary = primaryProvider!;
      _effectiveSecondary = secondaryProvider ?? gemini;
    } else if (preferGroqPrimary && groqApiKey.isNotEmpty && groqApiKey != 'MOCK_KEY') {
      _effectivePrimary = groq;
      _effectiveSecondary = gemini;
    } else {
      _effectivePrimary = gemini;
      _effectiveSecondary = groq;
    }

    _effectiveCloud = cloudProvider ?? SupabaseAIProvider();
    _effectiveOffline = offlineProvider ?? MockAIProvider();
  }

  @override
  String get providerName => 'VALIXIS Hybrid AI Core (Gemini + Groq + Cloud Gateway)';

  @override
  Future<AIResponse> processRequest(AIRequest request) async {
    final hasGemini = geminiApiKey.isNotEmpty && geminiApiKey != 'MOCK_KEY';
    final hasGroq = groqApiKey.isNotEmpty && groqApiKey != 'MOCK_KEY';
    final hasExplicitProviders = primaryProvider != null || secondaryProvider != null;

    if (!hasGemini && !hasGroq && !hasExplicitProviders) {
      return _effectiveOffline.processRequest(request);
    }

    // 1. Try Primary Provider (e.g. Groq) with exponential backoff & instant 429/503 failover
    AIResponse primaryResponse = await _executeWithBackoff(
      _effectivePrimary,
      request,
    );

    if (primaryResponse.isSuccess) {
      return primaryResponse;
    }

    // 2. If HTTP 429 or 503 is returned, or retries exhausted, instantly fallback to Secondary Provider (e.g. Gemini)
    if (_hasKeyForProvider(_effectiveSecondary) || secondaryProvider != null) {
      final secondaryResponse = await _executeWithBackoff(
        _effectiveSecondary,
        request,
      );
      if (secondaryResponse.isSuccess) {
        return secondaryResponse;
      }
    }

    // 3. Try Supabase Edge Function AI Gateway Proxy
    try {
      final cloudResponse = await _effectiveCloud.processRequest(request);
      if (cloudResponse.isSuccess) {
        return cloudResponse;
      }
    } catch (_) {}

    // 4. Fallback to offline rule-based engine (Guarantees zero app crashes)
    return _effectiveOffline.processRequest(request);
  }

  Future<AIResponse> _executeWithBackoff(
    AIProvider provider,
    AIRequest request,
  ) async {
    AIResponse? lastResponse;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        final response = await provider.processRequest(request);

        if (response.isSuccess) {
          return response;
        }

        lastResponse = response;

        // When HTTP 429 (Rate Limit / Quota Exceeded) or 503 (Service Unavailable / Overloaded)
        // is encountered, immediately return without wasting time retrying, enabling instant fallback!
        if (isImmediateFailoverStatusCode(response)) {
          return response;
        }

        // For transient errors (500, 502, 504, network timeouts), apply exponential backoff retry
        if (attempt < maxRetries && isRetryableError(response)) {
          final delayMs = (initialBackoff.inMilliseconds * pow(backoffMultiplier, attempt)).toInt();
          if (delayMs > 0) {
            await Future.delayed(Duration(milliseconds: delayMs));
          }
          continue;
        }

        return response;
      } catch (e) {
        lastResponse = AIResponse(
          isSuccess: false,
          outputText: '',
          errorMessage: 'Provider ${provider.providerName} failed: $e',
        );

        if (attempt < maxRetries) {
          final delayMs = (initialBackoff.inMilliseconds * pow(backoffMultiplier, attempt)).toInt();
          if (delayMs > 0) {
            await Future.delayed(Duration(milliseconds: delayMs));
          }
          continue;
        }
      }
    }

    return lastResponse ??
        AIResponse(
          isSuccess: false,
          outputText: '',
          errorMessage: '${provider.providerName} failed after retries',
        );
  }

  bool _hasKeyForProvider(AIProvider provider) {
    if (provider is GeminiAIProvider) {
      return geminiApiKey.isNotEmpty && geminiApiKey != 'MOCK_KEY';
    }
    if (provider is GroqAIProvider) {
      return groqApiKey.isNotEmpty && groqApiKey != 'MOCK_KEY';
    }
    return true;
  }

  /// Determines if an AI response status indicates an immediate failover condition (429 or 503).
  static bool isImmediateFailoverStatusCode(AIResponse response) {
    final code = response.statusCode;
    if (code == 429 || code == 503) return true;

    final err = (response.errorMessage ?? '').toLowerCase();
    return err.contains('429') ||
        err.contains('503') ||
        err.contains('too many requests') ||
        err.contains('service unavailable') ||
        err.contains('rate limit') ||
        err.contains('resource exhausted');
  }

  /// Identifies retryable HTTP status codes (500, 502, 504) and transient network failures.
  static bool isRetryableError(AIResponse response) {
    final code = response.statusCode;
    if (code != null) {
      if (code == 500 || code == 502 || code == 504) return true;
      if (code >= 400 && code < 500) return false;
    }

    final err = (response.errorMessage ?? '').toLowerCase();
    return err.contains('500') ||
        err.contains('502') ||
        err.contains('504') ||
        err.contains('timeout') ||
        err.contains('socket') ||
        err.contains('network') ||
        err.contains('connection');
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

      if (activeProvider == ActiveAIProviderType.openai && openaiKey != null && openaiKey.isNotEmpty) {
        final res = await OpenAIProvider(apiKey: openaiKey).processRequest(request);
        if (res.isSuccess) return res;
      }

      return await HybridAIProvider(
        geminiApiKey: effectiveGemini,
        groqApiKey: effectiveGroq,
        preferGroqPrimary: activeProvider != ActiveAIProviderType.gemini,
      ).processRequest(request);
    } catch (_) {
      return await HybridAIProvider(
        geminiApiKey: defaultGeminiKey,
        groqApiKey: defaultGroqKey,
      ).processRequest(request);
    }
  }
}
