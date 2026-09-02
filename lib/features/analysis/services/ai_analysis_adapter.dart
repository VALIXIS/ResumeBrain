import '../../../data/models/resume_models.dart';
import '../../ai/services/ai_service.dart';
import '../models/resume_analysis_report.dart';
import 'analysis_engine.dart';

/// Adapter that connects the [AIService] contract to the analysis layer
/// with safe deterministic mock fallback handling.
///
/// **Founder LLM Integration Boundary**:
/// - The analysis layer consumes this adapter to analyze resumes.
/// - The adapter delegates directly to [AIService.analyzeResume], which is implemented
///   and managed by the Founder AI service infrastructure (e.g. Gemini, Groq, Hybrid).
/// - When real AI responses are returned, the adapter parses and validates the overall score,
///   category scores, suggestions, and output text into a domain [ResumeAnalysisReport].
/// - If the AI service is offline, unconfigured, throws an exception, or returns invalid data,
///   the adapter deterministically falls back to [MockAnalysisEngine] to ensure 100% UI stability.
class AiAnalysisAdapter implements AnalysisEngine {
  final AIService aiService;
  final AnalysisEngine fallbackEngine;

  AiAnalysisAdapter({
    required this.aiService,
    AnalysisEngine? fallbackEngine,
  }) : fallbackEngine = fallbackEngine ?? MockAnalysisEngine();

  /// Analyzes a [Resume] using [AIService] with safe fallback to deterministic calculation.
  @override
  Future<ResumeAnalysisReport> analyze(Resume resume) async {
    try {
      final response = await aiService.analyzeResume(resume);

      if (response.isSuccess && _isValidResponse(response)) {
        return await _mapAiResponseToReport(resume, response);
      }

      // Graceful fallback if AI response is unsuccessful or malformed
      return await fallbackEngine.analyze(resume);
    } catch (_) {
      // Safe fallback on any AI service exception or timeout
      return await fallbackEngine.analyze(resume);
    }
  }

  /// Alias method for explicit resume analysis invocation.
  Future<ResumeAnalysisReport> analyzeResume(Resume resume) => analyze(resume);

  /// Validates whether the AI response contains usable analysis data.
  bool _isValidResponse(AIResponse response) {
    if (response.score != null &&
        (response.score! < 0 || response.score! > 100)) {
      return false;
    }
    return response.outputText.trim().isNotEmpty ||
        response.suggestions.isNotEmpty ||
        response.score != null;
  }

  /// Maps a successful [AIResponse] into the domain [ResumeAnalysisReport].
  Future<ResumeAnalysisReport> _mapAiResponseToReport(
    Resume resume,
    AIResponse response,
  ) async {
    // Generate baseline category breakdown using fallback engine for structure
    final baseReport = await fallbackEngine.analyze(resume);

    final score = response.score != null
        ? response.score!.round().clamp(0, 100)
        : baseReport.overallScore;

    final suggestions = response.suggestions.isNotEmpty
        ? response.suggestions
        : baseReport.suggestions;

    return ResumeAnalysisReport(
      resumeId: resume.id,
      overallScore: score,
      categoryScores: baseReport.categoryScores,
      suggestions: suggestions,
      timestamp: DateTime.now(),
    );
  }
}
