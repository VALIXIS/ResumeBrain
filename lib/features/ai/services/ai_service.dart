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
  final String? errorMessage;

  AIResponse({
    required this.isSuccess,
    required this.outputText,
    this.score,
    this.suggestions = const [],
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
    // Simulate AI network delay
    await Future.delayed(const Duration(milliseconds: 600));

    switch (request.taskType) {
      case AITaskType.textImprovement:
        return AIResponse(
          isSuccess: true,
          outputText:
              'Architected and deployed high-scalability production systems, reducing latency by 35% and improving overall system throughput.',
          suggestions: [
            'Quantify achievements with measurable metrics.',
            'Use strong action verbs like Architected, Spearheaded, Orchestrated.',
          ],
        );

      case AITaskType.resumeAnalysis:
        return AIResponse(
          isSuccess: true,
          outputText:
              'Strong professional structure with clear experience bullets. Highly ATS-friendly formatting.',
          score: 88.5,
          suggestions: [
            'Add 2-3 additional skill tags relevant to current industry standards.',
            'Include direct metrics in your most recent employment experience.',
            'Ensure LinkedIn link is complete.',
          ],
        );

      case AITaskType.jobMatching:
        return AIResponse(
          isSuccess: true,
          outputText: '85% match for Senior Software Engineer position.',
          score: 85.0,
          suggestions: [
            'Include cloud deployment keywords (Docker, AWS, Kubernetes).',
            'Highlight leadership in cross-functional projects.',
          ],
        );

      case AITaskType.resumeTailoring:
        return AIResponse(
          isSuccess: true,
          outputText:
              'Tailored summary and experience sections to emphasize targeted keywords from job description.',
          suggestions: [
            'Emphasized backend microservices experience.',
            'Reordered skills to highlight primary requirements.',
          ],
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
