import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_service.dart';
import 'resume_ai_prompt_engine.dart';

/// Production-ready Google Gemini AI Provider implementation for Resume Brain.
/// Supports live Gemini Flash API calls with automatic model cascade fallback
/// across gemini-2.0-flash, gemini-1.5-flash, gemini-2.5-flash, and v1beta/v1 endpoints.
class GeminiAIProvider implements AIProvider {
  final String apiKey;
  final http.Client client;
  final String? preferredModel;

  static String? _discoveredWorkingModel;

  static const List<String> supportedModels = [
    'gemini-2.0-flash',
    'gemini-1.5-flash',
    'gemini-2.5-flash',
    'gemini-1.5-flash-8b',
    'gemini-1.5-pro',
  ];

  GeminiAIProvider({
    required this.apiKey,
    http.Client? client,
    this.preferredModel,
  }) : client = client ?? http.Client();

  @override
  String get providerName => 'Google Gemini Flash (VALIXIS AI Core)';

  @override
  Future<AIResponse> processRequest(AIRequest request) async {
    var cleanKey = apiKey.trim();
    if (cleanKey.isEmpty || cleanKey == 'MOCK_KEY') {
      return MockAIProvider().processRequest(request);
    }

    if (cleanKey.length == 33 && !cleanKey.startsWith('AIzaSy')) {
      cleanKey = 'AIzaSy$cleanKey';
    }

    final prompt = _buildPrompt(request);

    final modelsToTry = <String>[];
    if (preferredModel != null && preferredModel!.isNotEmpty) {
      modelsToTry.add(preferredModel!);
    }
    if (_discoveredWorkingModel != null && !modelsToTry.contains(_discoveredWorkingModel)) {
      modelsToTry.add(_discoveredWorkingModel!);
    }
    for (final m in supportedModels) {
      if (!modelsToTry.contains(m)) {
        modelsToTry.add(m);
      }
    }

    final requestBody = jsonEncode({
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
    });

    http.Response? lastResponse;

    for (final modelName in modelsToTry) {
      for (final apiVersion in ['v1beta', 'v1']) {
        final endpoint = Uri.parse(
          'https://generativelanguage.googleapis.com/$apiVersion/models/$modelName:generateContent?key=$cleanKey',
        );

        try {
          final response = await client.post(
            endpoint,
            headers: {'Content-Type': 'application/json'},
            body: requestBody,
          );

          lastResponse = response;

          if (response.statusCode == 200) {
            _discoveredWorkingModel = modelName;
            final data = jsonDecode(response.body);
            final rawText = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
            final parsedJson = ResumeAIPromptEngine.parseAndSanitizeJson(rawText);

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
              statusCode: 200,
            );
          }

          if (response.statusCode == 404) {
            continue;
          }

          return AIResponse(
            isSuccess: false,
            outputText: '',
            statusCode: response.statusCode,
            errorMessage: 'Gemini API call failed with status ${response.statusCode}: ${response.body}',
          );
        } catch (e) {
          if (modelName == modelsToTry.last && apiVersion == 'v1') {
            return AIResponse(
              isSuccess: false,
              outputText: '',
              errorMessage: 'Gemini AI Provider Error: $e',
            );
          }
        }
      }
    }

    return AIResponse(
      isSuccess: false,
      outputText: '',
      statusCode: lastResponse?.statusCode ?? 404,
      errorMessage: lastResponse != null
          ? 'Gemini API call failed with status ${lastResponse.statusCode}: ${lastResponse.body}'
          : 'Gemini AI Provider failed: Model not found.',
    );
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
