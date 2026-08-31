import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_service.dart';

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

    final prompt = _buildSystemPrompt(request);

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
            'temperature': 0.2,
            'responseMimeType': 'application/json',
          }
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawText = data['candidates']?[0]?['content']?['parts']?[0]?['text'] ?? '';
        final parsedJson = jsonDecode(rawText);

        return AIResponse(
          isSuccess: true,
          outputText: parsedJson['outputText'] ?? rawText,
          score: (parsedJson['score'] as num?)?.toDouble(),
          suggestions: List<String>.from(parsedJson['suggestions'] ?? []),
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

  String _buildSystemPrompt(AIRequest request) {
    final buffer = StringBuffer();
    buffer.writeln(
      'You are the Lead ATS Resume Intelligence System for Resume Brain (VALIXIS). '
      'Respond STRICTLY in JSON format with fields: "outputText" (string), "score" (number 0-100 or null), and "suggestions" (array of strings).',
    );

    switch (request.taskType) {
      case AITaskType.textImprovement:
        buffer.writeln('TASK: Enhance resume bullet point using active action verbs and measurable metrics.');
        buffer.writeln('INPUT TEXT: "${request.inputText}"');
        break;

      case AITaskType.resumeAnalysis:
        buffer.writeln('TASK: Analyze the resume for ATS compliance, content quality, formatting, and keyword density.');
        if (request.resume != null) {
          buffer.writeln('RESUME TITLE: ${request.resume!.title}');
          buffer.writeln('RESUME SUMMARY: ${request.resume!.summary}');
          buffer.writeln('SKILLS: ${request.resume!.skills.join(", ")}');
        }
        break;

      case AITaskType.jobMatching:
        buffer.writeln('TASK: Calculate ATS percentage match score between the candidate resume and target Job Description.');
        buffer.writeln('JOB DESCRIPTION: "${request.jobDescription}"');
        if (request.resume != null) {
          buffer.writeln('RESUME SUMMARY: ${request.resume!.summary}');
          buffer.writeln('SKILLS: ${request.resume!.skills.join(", ")}');
        }
        break;

      case AITaskType.resumeTailoring:
        buffer.writeln('TASK: Generate tailored, high-impact bullet points aligned with keywords in target Job Description.');
        buffer.writeln('JOB DESCRIPTION: "${request.jobDescription}"');
        if (request.resume != null) {
          buffer.writeln('RESUME SUMMARY: ${request.resume!.summary}');
          buffer.writeln('SKILLS: ${request.resume!.skills.join(", ")}');
        }
        break;
    }

    return buffer.toString();
  }
}
