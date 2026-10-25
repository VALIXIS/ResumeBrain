import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_service.dart';
import 'resume_ai_prompt_engine.dart';

/// Production-ready Google Gemini AI Provider implementation for Resume Brain.
/// Dynamically queries Google's ModelService to resolve valid generateContent models
/// for the user's specific API key, with cascade fallback across Gemini 2.0 Flash,
/// Gemini 1.5 Flash, and Gemini 1.5 Pro.
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
    var cleanKey = apiKey.trim().replaceAll('"', '').replaceAll("'", '');
    if (cleanKey.isEmpty || cleanKey == 'MOCK_KEY') {
      return MockAIProvider().processRequest(request);
    }

    // Auto-fix if key was clipped without AIzaSy prefix
    if (!cleanKey.startsWith('AIzaSy') && cleanKey.length >= 30 && cleanKey.length <= 36) {
      cleanKey = 'AIzaSy$cleanKey';
    }

    // 1. First, try dynamic model discovery via Google ModelService.ListModels
    if (_discoveredWorkingModel == null) {
      final discovered = await _discoverWorkingModel(cleanKey);
      if (discovered != null) {
        _discoveredWorkingModel = discovered;
      }
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

          if (response.statusCode == 404 ||
              (response.statusCode == 400 &&
                  (response.body.toLowerCase().contains('not found') ||
                      response.body.toLowerCase().contains('not supported')))) {
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

    final detail = lastResponse?.body ?? 'No compatible Gemini model found.';
    return AIResponse(
      isSuccess: false,
      outputText: '',
      statusCode: lastResponse?.statusCode ?? 404,
      errorMessage: 'Gemini API call failed with status ${lastResponse?.statusCode ?? 404}: $detail\n'
          'Tip: Ensure your key was created at https://aistudio.google.com/app/apikey and starts with AIzaSy.',
    );
  }

  /// Queries Google's ModelService to find models that support generateContent for this key
  Future<String?> _discoverWorkingModel(String cleanKey) async {
    for (final apiVersion in ['v1beta', 'v1']) {
      try {
        final endpoint = Uri.parse(
          'https://generativelanguage.googleapis.com/$apiVersion/models?key=$cleanKey',
        );
        final response = await client.get(endpoint);
        if (response.statusCode == 200) {
          final data = jsonDecode(response.body);
          final models = data['models'] as List<dynamic>?;
          if (models != null) {
            // First look for flash models
            for (final m in models) {
              final name = (m['name'] as String?)?.replaceFirst('models/', '');
              final methods = (m['supportedGenerationMethods'] as List<dynamic>?)?.cast<String>() ?? [];
              if (methods.contains('generateContent') && name != null) {
                if (name.contains('flash')) {
                  return name;
                }
              }
            }
            // Otherwise any generateContent model
            for (final m in models) {
              final name = (m['name'] as String?)?.replaceFirst('models/', '');
              final methods = (m['supportedGenerationMethods'] as List<dynamic>?)?.cast<String>() ?? [];
              if (methods.contains('generateContent') && name != null) {
                return name;
              }
            }
          }
        }
      } catch (_) {}
    }
    return null;
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
