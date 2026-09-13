import '../../../data/models/resume_models.dart';

enum AITaskType { textImprovement, resumeAnalysis, jobMatching, resumeTailoring }

class AIRequest {
  final AITaskType taskType;
  final String inputText;
  final Resume? resume;
  final String? jobDescription;

  AIRequest({
    required this.taskType,
    this.inputText = '',
    this.resume,
    this.jobDescription,
  });
}

class AIResponse {
  final bool isSuccess;
  final String outputText;
  final double? score; // e.g. ATS Score or Job Match percentage
  final List<String> suggestions;
  final List<String> metricsApplied;
  final List<String> powerVerbs;
  final List<String> missingKeywords;
  final Map<String, double> subScores;
  final String? errorMessage;

  AIResponse({
    required this.isSuccess,
    required this.outputText,
    this.score,
    this.suggestions = const [],
    this.metricsApplied = const [],
    this.powerVerbs = const [],
    this.missingKeywords = const [],
    this.subScores = const {},
    this.errorMessage,
  });
}

abstract class AIProvider {
  String get providerName;
  Future<AIResponse> processRequest(AIRequest request);
}

abstract class AIService {
  Future<AIResponse> improveText(String text, String sectionContext);
  Future<AIResponse> analyzeResume(Resume resume);
  Future<AIResponse> matchJob(Resume resume, String jobDescription);
  Future<AIResponse> tailorResume(Resume resume, String jobDescription);
}

class MockAIProvider implements AIProvider {
  @override
  String get providerName => 'MockAI (VALIXIS Staging Engine)';

  @override
  Future<AIResponse> processRequest(AIRequest request) async {
    // No real AI available — signal failure for scoring tasks so the
    // AiAnalysisAdapter falls back to the content-dependent MockAnalysisEngine.
    // Text-improvement and tailoring still provide basic offline tips.
    switch (request.taskType) {
      case AITaskType.textImprovement:
        await Future.delayed(const Duration(milliseconds: 300));
        return AIResponse(
          isSuccess: false,
          outputText: '',
          errorMessage: 'AI offline — configure a Gemini or Groq API key in AI Settings.',
        );

      case AITaskType.resumeAnalysis:
        // Return failure → AiAnalysisAdapter will compute a real content-based score
        // using MockAnalysisEngine.analyze() instead of serving a hardcoded value.
        return AIResponse(
          isSuccess: false,
          outputText: '',
          errorMessage: 'AI offline — using local ATS engine for scoring.',
        );

      case AITaskType.jobMatching:
        // Return failure → caller falls back to local keyword-overlap matching.
        return AIResponse(
          isSuccess: false,
          outputText: '',
          errorMessage: 'AI offline — using local keyword matcher for job scoring.',
        );

      case AITaskType.resumeTailoring:
        return AIResponse(
          isSuccess: false,
          outputText: '',
          errorMessage: 'AI offline — configure an API key in AI Settings to use live tailoring.',
        );
    }
  }
}

class ResumeBrainAIService implements AIService {
  final AIProvider provider;

  ResumeBrainAIService({required this.provider});

  @override
  Future<AIResponse> improveText(String text, String sectionContext) {
    return provider.processRequest(
      AIRequest(
        taskType: AITaskType.textImprovement,
        inputText: text,
      ),
    );
  }

  @override
  Future<AIResponse> analyzeResume(Resume resume) {
    return provider.processRequest(
      AIRequest(
        taskType: AITaskType.resumeAnalysis,
        resume: resume,
      ),
    );
  }

  @override
  Future<AIResponse> matchJob(Resume resume, String jobDescription) {
    return provider.processRequest(
      AIRequest(
        taskType: AITaskType.jobMatching,
        resume: resume,
        jobDescription: jobDescription,
      ),
    );
  }

  @override
  Future<AIResponse> tailorResume(Resume resume, String jobDescription) {
    return provider.processRequest(
      AIRequest(
        taskType: AITaskType.resumeTailoring,
        resume: resume,
        jobDescription: jobDescription,
      ),
    );
  }
}
