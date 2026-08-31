import 'dart:convert';
import 'package:http/http.dart' as http;
import 'ai_service.dart';

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

    final prompt = _buildSystemPrompt(request);

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
          'temperature': 0.2,
          'response_format': {'type': 'json_object'},
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final rawText = data['choices']?[0]?['message']?['content'] ?? '';
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
        buffer.writeln('TASK: Calculate ATS percentage match score between candidate resume and target Job Description.');
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
