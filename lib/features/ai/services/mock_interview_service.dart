import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../data/models/resume_models.dart';

/// Representation of a single STAR-focused interview question.
class InterviewQuestion {
  final int id;
  final String question;
  final String resumeContext;
  final String competency;
  final String sampleAnswer;
  final List<String> starKeywords;

  const InterviewQuestion({
    required this.id,
    required this.question,
    required this.resumeContext,
    required this.competency,
    required this.sampleAnswer,
    this.starKeywords = const [],
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'resumeContext': resumeContext,
        'competency': competency,
        'sampleAnswer': sampleAnswer,
        'starKeywords': starKeywords,
      };

  factory InterviewQuestion.fromJson(Map<String, dynamic> json) {
    return InterviewQuestion(
      id: json['id'] as int? ?? 1,
      question: json['question'] as String? ?? '',
      resumeContext: json['resumeContext'] as String? ?? 'General Experience',
      competency: json['competency'] as String? ?? 'Behavioral Competency',
      sampleAnswer: json['sampleAnswer'] as String? ?? '',
      starKeywords: List<String>.from(json['starKeywords'] ?? []),
    );
  }
}

/// Detailed STAR (Situation, Task, Action, Result) breakdown score.
class StarScore {
  final int situationScore;
  final int taskScore;
  final int actionScore;
  final int resultScore;
  final int overallScore;

  final String situationFeedback;
  final String taskFeedback;
  final String actionFeedback;
  final String resultFeedback;

  const StarScore({
    required this.situationScore,
    required this.taskScore,
    required this.actionScore,
    required this.resultScore,
    required this.overallScore,
    required this.situationFeedback,
    required this.taskFeedback,
    required this.actionFeedback,
    required this.resultFeedback,
  });

  Map<String, dynamic> toJson() => {
        'situationScore': situationScore,
        'taskScore': taskScore,
        'actionScore': actionScore,
        'resultScore': resultScore,
        'overallScore': overallScore,
        'situationFeedback': situationFeedback,
        'taskFeedback': taskFeedback,
        'actionFeedback': actionFeedback,
        'resultFeedback': resultFeedback,
      };

  factory StarScore.fromJson(Map<String, dynamic> json) {
    return StarScore(
      situationScore: (json['situationScore'] as num?)?.toInt() ?? 75,
      taskScore: (json['taskScore'] as num?)?.toInt() ?? 75,
      actionScore: (json['actionScore'] as num?)?.toInt() ?? 80,
      resultScore: (json['resultScore'] as num?)?.toInt() ?? 70,
      overallScore: (json['overallScore'] as num?)?.toInt() ?? 75,
      situationFeedback: json['situationFeedback'] as String? ?? 'Situation was set clearly.',
      taskFeedback: json['taskFeedback'] as String? ?? 'Task and objective defined.',
      actionFeedback: json['actionFeedback'] as String? ?? 'Actions described well.',
      resultFeedback: json['resultFeedback'] as String? ?? 'Quantify results for extra impact.',
    );
  }
}

/// Evaluation result for a single question response.
class QuestionEvaluation {
  final int questionId;
  final String candidateAnswer;
  final StarScore starScore;
  final List<String> strengths;
  final List<String> improvements;
  final String actionableTip;

  const QuestionEvaluation({
    required this.questionId,
    required this.candidateAnswer,
    required this.starScore,
    required this.strengths,
    required this.improvements,
    required this.actionableTip,
  });
}

/// Final summary scorecard for a full 5-question interview session.
class InterviewSessionResult {
  final int overallReadinessScore;
  final String readinessTier;
  final double averageSituation;
  final double averageTask;
  final double averageAction;
  final double averageResult;
  final List<String> topStrengths;
  final List<String> priorityImprovements;
  final List<QuestionEvaluation> evaluations;

  const InterviewSessionResult({
    required this.overallReadinessScore,
    required this.readinessTier,
    required this.averageSituation,
    required this.averageTask,
    required this.averageAction,
    required this.averageResult,
    required this.topStrengths,
    required this.priorityImprovements,
    required this.evaluations,
  });
}

/// Service providing AI-powered question generation and STAR evaluation
/// using Google Gemini API with fallback to local heuristic engine.
class MockInterviewService {
  final http.Client _client;

  MockInterviewService({http.Client? client}) : _client = client ?? http.Client();

  /// Generates 5 tailored behavioral interview questions based on candidate's resume experiences.
  Future<List<InterviewQuestion>> generate5Questions({
    required Resume? resume,
    required String track,
    required String seniority,
    String? apiKey,
  }) async {
    if (apiKey != null && apiKey.isNotEmpty && apiKey != 'MOCK_KEY') {
      try {
        final prompt = _buildQuestionsPrompt(resume, track, seniority);
        final endpoint = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
        );

        final response = await _client.post(
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
          final parsed = jsonDecode(rawText);

          final qListRaw = parsed['questions'] as List<dynamic>?;
          if (qListRaw != null && qListRaw.length >= 5) {
            return qListRaw
                .take(5)
                .map((q) => InterviewQuestion.fromJson(q as Map<String, dynamic>))
                .toList();
          }
        }
      } catch (_) {
        // Fall back to local tailored generation if Gemini network error occurs
      }
    }

    // Fallback heuristic question generation based on candidate resume content
    return _generateFallbackQuestions(resume, track, seniority);
  }

  /// Evaluates candidate's written or spoken response using STAR framework.
  Future<QuestionEvaluation> evaluateAnswer({
    required InterviewQuestion question,
    required String candidateAnswer,
    required Resume? resume,
    required String seniority,
    String? apiKey,
  }) async {
    if (apiKey != null && apiKey.isNotEmpty && apiKey != 'MOCK_KEY') {
      try {
        final prompt = _buildEvaluationPrompt(question, candidateAnswer, seniority);
        final endpoint = Uri.parse(
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$apiKey',
        );

        final response = await _client.post(
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
          final parsed = jsonDecode(rawText) as Map<String, dynamic>;

          final starScore = StarScore.fromJson(parsed['starScore'] as Map<String, dynamic>? ?? parsed);
          final strengths = List<String>.from(parsed['strengths'] ?? []);
          final improvements = List<String>.from(parsed['improvements'] ?? []);
          final actionableTip = parsed['actionableTip'] as String? ??
              'Structure your response: Situation -> Task -> Action -> Result.';

          return QuestionEvaluation(
            questionId: question.id,
            candidateAnswer: candidateAnswer,
            starScore: starScore,
            strengths: strengths.isNotEmpty
                ? strengths
                : ['Directly addresses the question scenario', 'Clear ownership of actions'],
            improvements: improvements.isNotEmpty
                ? improvements
                : ['Quantify specific business results', 'Elaborate on technical trade-offs'],
            actionableTip: actionableTip,
          );
        }
      } catch (_) {
        // Fall back to local STAR evaluation
      }
    }

    return _evaluateFallback(question, candidateAnswer, seniority);
  }

  /// Calculates the final interview readiness scorecard from all 5 completed question evaluations.
  InterviewSessionResult computeFinalScorecard(List<QuestionEvaluation> evaluations) {
    if (evaluations.isEmpty) {
      return const InterviewSessionResult(
        overallReadinessScore: 0,
        readinessTier: 'Needs Practice',
        averageSituation: 0,
        averageTask: 0,
        averageAction: 0,
        averageResult: 0,
        topStrengths: [],
        priorityImprovements: [],
        evaluations: [],
      );
    }

    double sumSit = 0, sumTask = 0, sumAct = 0, sumRes = 0, sumOverall = 0;
    final allStrengths = <String>{};
    final allImprovements = <String>{};

    for (final eval in evaluations) {
      sumSit += eval.starScore.situationScore;
      sumTask += eval.starScore.taskScore;
      sumAct += eval.starScore.actionScore;
      sumRes += eval.starScore.resultScore;
      sumOverall += eval.starScore.overallScore;

      allStrengths.addAll(eval.strengths);
      allImprovements.addAll(eval.improvements);
    }

    final count = evaluations.length;
    final avgSit = sumSit / count;
    final avgTask = sumTask / count;
    final avgAct = sumAct / count;
    final avgRes = sumRes / count;
    final overall = (sumOverall / count).round();

    String tier;
    if (overall >= 90) {
      tier = 'Executive STAR Master 🏆';
    } else if (overall >= 80) {
      tier = 'Strong Interview Candidate 🌟';
    } else if (overall >= 68) {
      tier = 'Interview Prepared - Minor Polish Needed 📈';
    } else {
      tier = 'Needs STAR Framework Restructuring 💡';
    }

    return InterviewSessionResult(
      overallReadinessScore: overall,
      readinessTier: tier,
      averageSituation: avgSit,
      averageTask: avgTask,
      averageAction: avgAct,
      averageResult: avgRes,
      topStrengths: allStrengths.take(4).toList(),
      priorityImprovements: allImprovements.take(4).toList(),
      evaluations: evaluations,
    );
  }

  // Helper Prompts & Fallbacks
  String _buildQuestionsPrompt(Resume? resume, String track, String seniority) {
    final expText = resume?.experiences
            .map((e) => '- ${e.position} at ${e.company}: ${e.description}')
            .join('\n') ??
        'Mobile Engineering background with Flutter, Dart, REST APIs, and Offline Storage.';

    final projText = resume?.projects
            .map((p) => '- ${p.name}: ${p.description} (${p.technologies})')
            .join('\n') ??
        'Resume Brain PDF tailoring application.';

    return '''
You are a Lead Tech Recruiter and Executive Interview Coach.
Generate EXACTLY 5 tailored behavioral interview questions for a candidate with the following background:

Candidate Target Level: $seniority
Interview Track: $track
Resume Experiences:
$expText

Resume Projects:
$projText

REQUIREMENTS:
1. Generate 5 distinct questions covering 5 key competencies: (1) Situation Framing & Technical Complexity, (2) Problem Solving & Trade-offs, (3) Cross-Functional Conflict & Stakeholders, (4) Failure & Lessons Learned, (5) Measurable Impact & Optimization.
2. Direct each question specifically to bullet points or projects in the candidate's resume!
3. Format as raw JSON:
{
  "questions": [
    {
      "id": 1,
      "question": "...",
      "resumeContext": "Based on your role as...",
      "competency": "Technical Complexity & Architecture",
      "sampleAnswer": "High-scoring sample answer following STAR method...",
      "starKeywords": ["Situation", "Task", "Action", "Result", "Metric"]
    }, ...
  ]
}
''';
  }

  String _buildEvaluationPrompt(InterviewQuestion question, String candidateAnswer, String seniority) {
    return '''
You are an Executive Behavioral Interview Coach evaluating a candidate's response using the STAR Framework (Situation, Task, Action, Result).

Target Seniority: $seniority
Question: "${question.question}"
Candidate Answer: "$candidateAnswer"

Scoring Criteria:
- Situation (0-100): Clear setting of context, constraints, and business environment.
- Task (0-100): Explicit definition of personal goal, responsibility, or obstacle.
- Action (0-100): Concrete step-by-step actions using strong personal verbs ("I engineered", "I refactored").
- Result (0-100): Quantified business metrics (%, latency, revenue, crash rate reduction).

Return raw JSON:
{
  "starScore": {
    "situationScore": 85,
    "taskScore": 80,
    "actionScore": 90,
    "resultScore": 75,
    "overallScore": 83,
    "situationFeedback": "...",
    "taskFeedback": "...",
    "actionFeedback": "...",
    "resultFeedback": "..."
  },
  "strengths": ["...", "..."],
  "improvements": ["...", "..."],
  "actionableTip": "..."
}
''';
  }

  List<InterviewQuestion> _generateFallbackQuestions(Resume? resume, String track, String seniority) {
    final exp = resume?.experiences;
    final firstRole = (exp != null && exp.isNotEmpty) ? exp.first.position : 'Software Engineer';
    final firstComp = (exp != null && exp.isNotEmpty) ? exp.first.company : 'VALIXIS';
    final firstDesc = (exp != null && exp.isNotEmpty && exp.first.description.isNotEmpty)
        ? exp.first.description
        : 'built scalable mobile applications and API integrations';

    final proj = resume?.projects;
    final projName = (proj != null && proj.isNotEmpty) ? proj.first.name : 'Resume Brain';

    return [
      InterviewQuestion(
        id: 1,
        question:
            'In your role as $firstRole at $firstComp, you mentioned: "$firstDesc". Can you describe a specific high-stakes situation where system constraints pushed your technical architecture to its limits?',
        resumeContext: 'Derived from experience at $firstComp',
        competency: 'Technical Complexity & Architecture',
        sampleAnswer:
            'At $firstComp, our sync engine faced high latency under heavy concurrency. I diagnosed the bottleneck, refactored data serialization with Hive local caching, and reduced sync response time by 62% across 100k active users.',
        starKeywords: ['Architecture', 'Latency', 'Hive', 'Concurrency', 'Quantified Result'],
      ),
      InterviewQuestion(
        id: 2,
        question:
            'Tell me about a time during project "$projName" when you had to balance technical debt cleanup against urgent feature delivery. How did you make trade-offs?',
        resumeContext: 'Derived from project "$projName"',
        competency: 'Trade-offs & Technical Debt',
        sampleAnswer:
            'While developing $projName, refactoring state management was essential to prevent memory leaks. I presented a crash metrics report to leadership, negotiated a 70/30 sprint allocation, and achieved 99.9% crash-free sessions.',
        starKeywords: ['Trade-offs', 'Metrics', 'Negotiation', 'Crash Rate', 'Sprint Allocation'],
      ),
      InterviewQuestion(
        id: 3,
        question:
            'Can you recall a scenario where you experienced cross-functional disagreement with Product or Engineering leadership on feature priorities? How did you align stakeholders?',
        resumeContext: 'Derived from leadership experience at $firstComp',
        competency: 'Stakeholder Alignment & Conflict',
        sampleAnswer:
            'Product leadership requested rapid release of an feature without full integration tests. I created an automated test coverage report showing potential regression risks, proposed a phased beta rollout, and preserved code quality without missing deadlines.',
        starKeywords: ['Stakeholder Management', 'Risk Assessment', 'Phased Rollout', 'Quality'],
      ),
      InterviewQuestion(
        id: 4,
        question:
            'Describe a situation where a key deployment or system update failed or produced unexpected bugs in production. What immediate actions did you take and what systemic fixes resulted?',
        resumeContext: 'Derived from production delivery at $firstComp',
        competency: 'Incident Response & Ownership',
        sampleAnswer:
            'During a production release, an unhandled null payload caused intermittent crashes. I immediately executed a roll-back within 4 minutes, added null-safety guards, and authored a post-mortem to update our CI pipeline.',
        starKeywords: ['Ownership', 'Roll-back', 'Post-Mortem', 'CI Pipeline', 'Null Safety'],
      ),
      InterviewQuestion(
        id: 5,
        question:
            'Walk me through your most impactful technical achievement. What specific metric or business outcome proved your solution succeeded?',
        resumeContext: 'Overall Career Impact',
        competency: 'Quantified Business Result',
        sampleAnswer:
            'I spearheaded the migration of legacy REST calls to optimized GraphQL queries. This cut data consumption by 45%, decreased load time from 2.4s to 650ms, and increased user retention by 18%.',
        starKeywords: ['Optimization', 'Data Reduction', 'Page Speed', 'User Retention'],
      ),
    ];
  }

  QuestionEvaluation _evaluateFallback(
    InterviewQuestion question,
    String candidateAnswer,
    String seniority,
  ) {
    final text = candidateAnswer.trim();
    final length = text.length;

    // Detect STAR components heuristic
    final hasMetrics = RegExp(r'\d+%|\$\d+|\b\d+\b|ms|sec|hours').hasMatch(text);
    final hasSituationWords =
        RegExp(r'\b(at|when|during|while|project|company|team|role|situation|as)\b', caseSensitive: false)
            .hasMatch(text);
    final hasTaskWords =
        RegExp(r'\b(needed to|tasked with|goal|objective|challenge|problem|required|responsibility)\b', caseSensitive: false)
            .hasMatch(text);
    final hasActionVerbs = RegExp(r'\b(I|spearheaded|architected|engineered|built|implemented|refactored|led|designed|created|optimized)\b', caseSensitive: false)
        .hasMatch(text);

    int sitScore = (hasSituationWords ? 85 : 60) + (length > 100 ? 10 : 0);
    int taskScore = (hasTaskWords ? 85 : 62) + (length > 150 ? 10 : 0);
    int actScore = (hasActionVerbs ? 88 : 65) + (length > 200 ? 10 : 0);
    int resScore = (hasMetrics ? 92 : 55) + (length > 180 ? 8 : 0);

    sitScore = sitScore.clamp(50, 98);
    taskScore = taskScore.clamp(50, 98);
    actScore = actScore.clamp(50, 98);
    resScore = resScore.clamp(45, 98);

    final overall = ((sitScore * 0.2) + (taskScore * 0.2) + (actScore * 0.35) + (resScore * 0.25)).round();

    return QuestionEvaluation(
      questionId: question.id,
      candidateAnswer: candidateAnswer,
      starScore: StarScore(
        situationScore: sitScore,
        taskScore: taskScore,
        actionScore: actScore,
        resultScore: resScore,
        overallScore: overall,
        situationFeedback: hasSituationWords
            ? 'Clear background context established.'
            : 'Specify the company/team context earlier in your response.',
        taskFeedback: hasTaskWords
            ? 'Problem statement and core objective stated.'
            : 'Explicitly state the primary obstacle or task expectation.',
        actionFeedback: hasActionVerbs
            ? 'Strong first-person action verbs demonstrate active leadership.'
            : 'Use "I engineered / I refactored" instead of general team actions.',
        resultFeedback: hasMetrics
            ? 'Excellent inclusion of quantified impact metrics.'
            : 'Add concrete numbers (%, latency, users) to prove business value.',
      ),
      strengths: [
        if (hasActionVerbs) 'Clear individual accountability and action steps' else 'Direct answer to question',
        if (hasMetrics) 'Quantifies measurable business results with data' else 'Good problem framing',
        'Relevant alignment with $seniority expectations',
      ],
      improvements: [
        if (!hasMetrics) 'Inject specific metrics (e.g. % improvement, time saved, DAU)' else 'Elaborate on technical trade-offs',
        if (!hasTaskWords) 'Frame your personal task/objective more explicitly' else 'Detail post-launch reflections',
      ],
      actionableTip: hasMetrics
          ? 'Great response! Emphasize the long-term architectural maintenance impact for extra polish.'
          : 'Follow Google XYZ rule: "Accomplished [X] measured by [Y], by doing [Z]".',
    );
  }
}
