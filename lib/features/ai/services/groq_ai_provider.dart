import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_service.dart';
import 'resume_ai_prompt_engine.dart';

/// Free Ultra-Fast Groq Cloud AI Provider using Llama 3.1 70B.
/// Provides up to 14,400 FREE requests per day with sub-second latency.
class GroqAIProvider implements AIProvider {
  final String apiKey;
  final http.Client client;

  GroqAIProvider({
    required this.apiKey,
    http.Client? client,
  }) : client = client ?? http.Client();

  @override
  String get providerName => 'Groq Cloud (Llama 3.1 70B Free Engine)';

  @override
  Future<AIResponse> processRequest(AIRequest request) async {
    if (apiKey.isEmpty || apiKey == 'MOCK_KEY') {
      return MockAIProvider().processRequest(request);
    }

    final endpoint = Uri.parse('https://api.groq.com/openai/v1/chat/completions');

    final prompt = _buildPrompt(request);

    try {
      final response = await client.post(
        endpoint,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'llama-3.1-70b-versatile',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
          'temperature': 0.15,
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawText = data['choices']?[0]?['message']?['content'] ?? '';
        final parsedJson = jsonDecode(rawText);

        final subScoresRaw = parsedJson['subScores'] as Map<String, dynamic>?;
        final subScores = <String, double>{};
        if (subScoresRaw != null) {
          subScoresRaw.forEach((k, v) {
            if (v is num) subScores[k] = v.toDouble();
          });
        }

        return AIResponse(
          isSuccess: true,
          outputText: parsedJson['outputText'] ?? rawText,
          score: (parsedJson['score'] as num?)?.toDouble(),
          suggestions: List<String>.from(parsedJson['suggestions'] ?? []),
          metricsApplied: List<String>.from(parsedJson['metricsApplied'] ?? []),
          powerVerbs: List<String>.from(parsedJson['powerVerbs'] ?? []),
          missingKeywords: List<String>.from(parsedJson['missingKeywords'] ?? []),
          subScores: subScores,
        );
      } else {
        return AIResponse(
          isSuccess: false,
          outputText: '',
          errorMessage: 'Groq API call failed with status ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      return AIResponse(
        isSuccess: false,
        outputText: '',
        errorMessage: 'Groq AI Provider Error: $e',
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
