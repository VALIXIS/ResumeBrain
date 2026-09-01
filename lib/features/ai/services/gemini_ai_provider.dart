import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_service.dart';
import 'resume_ai_prompt_engine.dart';

/// Production-ready Google Gemini AI Provider implementation for Resume Brain.
/// Supports live Gemini 1.5 Flash API calls with fallback to MockAIProvider when no API key is provided.
class GeminiAIProvider implements AIProvider {
  final String apiKey;
  final http.Client client;

  GeminiAIProvider({
    required this.apiKey,
    http.Client? client,
  }) : client = client ?? http.Client();

  @override
  String get providerName => 'Google Gemini 1.5 Flash (VALIXIS AI Core)';

  @override
  Future<AIResponse> processRequest(AIRequest request) async {
    if (apiKey.isEmpty || apiKey == 'MOCK_KEY') {
      return MockAIProvider().processRequest(request);
    }

    final endpoint = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
    );

    final prompt = _buildPrompt(request);

    try {
      final response = await client.post(
        endpoint,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.15,
            'responseMimeType': 'application/json',
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawText = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
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
          errorMessage: 'Gemini API call failed with status ${response.statusCode}: ${response.body}',
        );
      }
    } catch (e) {
      return AIResponse(
        isSuccess: false,
        outputText: '',
        errorMessage: 'Gemini AI Provider Error: $e',
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
