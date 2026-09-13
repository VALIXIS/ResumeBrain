import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'ai_service.dart';
import 'resume_ai_prompt_engine.dart';

/// Secure production AI Provider that routes requests through Supabase Edge Function (`resume-ai-proxy`).
/// Keeps API keys 100% server-side, protecting quota and eliminating secret leaks.
class SupabaseAIProvider implements AIProvider {
  final SupabaseClient? _client;

  SupabaseAIProvider({SupabaseClient? client}) : _client = client;

  SupabaseClient? get _activeClient {
    if (_client != null) return _client;
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  @override
  String get providerName => 'VALIXIS Cloud AI Gateway (Supabase Secure Proxy)';

  @override
  Future<AIResponse> processRequest(AIRequest request) async {
    final client = _activeClient;
    if (client == null) {
      return AIResponse(
        isSuccess: false,
        outputText: '',
        errorMessage: 'Supabase Cloud Client uninitialized.',
      );
    }

    final prompt = _buildPrompt(request);

    try {
      final res = await client.functions.invoke(
        'resume-ai-proxy',
        body: {'prompt': prompt},
      );

      if (res.status == 200) {
        final data = res.data as Map<String, dynamic>?;
        if (data == null) {
          return AIResponse(
            isSuccess: false,
            outputText: '',
            errorMessage: 'Empty response payload from AI Edge gateway.',
          );
        }

        if (data['isSuccess'] == true) {
          final subScoresRaw = data['subScores'] as Map<String, dynamic>?;
          final subScores = <String, double>{};
          if (subScoresRaw != null) {
            subScoresRaw.forEach((k, v) {
              if (v is num) subScores[k] = v.toDouble();
            });
          }

          return AIResponse(
            isSuccess: true,
            outputText: data['outputText'] ?? '',
            score: (data['score'] as num?)?.toDouble(),
            suggestions: List<String>.from(data['suggestions'] ?? []),
            metricsApplied: List<String>.from(data['metricsApplied'] ?? []),
            powerVerbs: List<String>.from(data['powerVerbs'] ?? []),
            missingKeywords: List<String>.from(data['missingKeywords'] ?? []),
            subScores: subScores,
          );
        } else {
          return AIResponse(
            isSuccess: false,
            outputText: '',
            errorMessage: data['errorMessage'] ?? 'AI Edge Proxy returned failure state.',
          );
        }
      } else {
        return AIResponse(
          isSuccess: false,
          outputText: '',
          errorMessage: 'AI Edge Proxy returned HTTP ${res.status}',
        );
      }
    } catch (e) {
      debugPrint('SupabaseAIProvider error: $e');
      return AIResponse(
        isSuccess: false,
        outputText: '',
        errorMessage: 'AI Edge Proxy Error: $e',
      );
    }
  }

  String _buildPrompt(AIRequest request) {
    switch (request.taskType) {
      case AITaskType.textImprovement:
        return ResumeAIPromptEngine.buildTextImprovementPrompt(request.inputText);
      case AITaskType.resumeAnalysis:
        if (request.resume != null) {
          return ResumeAIPromptEngine.buildResumeAnalysisPrompt(request.resume!);
        }
        return ResumeAIPromptEngine.buildTextImprovementPrompt(request.inputText);
      case AITaskType.jobMatching:
        if (request.resume != null) {
          return ResumeAIPromptEngine.buildJobMatchingPrompt(
            request.resume!,
            request.jobDescription ?? '',
          );
        }
        return ResumeAIPromptEngine.buildTextImprovementPrompt(request.inputText);
      case AITaskType.resumeTailoring:
        if (request.resume != null) {
          return ResumeAIPromptEngine.buildResumeTailoringPrompt(
            request.resume!,
            request.jobDescription ?? '',
          );
        }
        return ResumeAIPromptEngine.buildTextImprovementPrompt(request.inputText);
    }
  }
}
