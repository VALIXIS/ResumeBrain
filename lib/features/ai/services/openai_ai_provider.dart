import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_service.dart';
import 'resume_ai_prompt_engine.dart';

/// Production-ready OpenAI AI Provider using gpt-4o-mini.
class OpenAIProvider implements AIProvider {
  final String apiKey;
  final http.Client client;

  OpenAIProvider({
    required this.apiKey,
    http.Client? client,
  }) : client = client ?? http.Client();

  @override
  String get providerName => 'OpenAI (GPT-4o mini Engine)';

  @override
  Future<AIResponse> processRequest(AIRequest request) async {
    if (apiKey.isEmpty || apiKey == 'MOCK_KEY') {
      return MockAIProvider().processRequest(request);
    }

    final endpoint = Uri.parse('https://api.openai.com/v1/chat/completions');
    final prompt = _buildPrompt(request);

    try {
      final response = await client.post(
        endpoint,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $apiKey',
        },
        body: jsonEncode({
          'model': 'gpt-4o-mini',
          'messages': [
            {
              'role': 'system',
              'content': 'You are an expert ATS resume optimizer and career coach. Respond strictly with valid JSON.'
            },
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
          errorMessage: 'OpenAI API call failed with status ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      return AIResponse(
        isSuccess: false,
        outputText: '',
        errorMessage: 'OpenAI Provider Error: $e',
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
