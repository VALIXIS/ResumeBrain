import 'package:flutter_test/flutter_test.dart';
import 'package:resume_brain/data/models/resume_models.dart';
import 'package:resume_brain/features/ai/services/mock_interview_service.dart';

void main() {
  group('MockInterviewService Unit Tests', () {
    late MockInterviewService service;
    late Resume sampleResume;

    setUp(() {
      service = MockInterviewService();
      sampleResume = Resume(
        id: 'test-resume-1',
        title: 'Senior Mobile Engineer Resume',
        personalInfo: PersonalInformation(
          fullName: 'Vaseem Developer',
          jobTitle: 'Senior Mobile Systems Engineer',
          email: 'vaseem@example.com',
          location: 'San Francisco, CA',
        ),
        experiences: [
          Experience(
            id: 'exp-1',
            company: 'VALIXIS',
            position: 'Senior Mobile Engineer',
            startDate: '2023-01',
            endDate: 'Present',
            description:
                'Architected offline-first sync engine using Hive and vector caching, reducing sync latency by 68% for 250k active users.',
          ),
        ],
        projects: [
          Project(
            id: 'proj-1',
            name: 'Resume Brain',
            description: 'AI-powered resume tailoring app with live PDF generation',
            technologies: 'Flutter, Dart, Riverpod, Gemini API',
          ),
        ],
        skills: [
          Skill(id: 's-1', name: 'Flutter'),
          Skill(id: 's-2', name: 'Dart'),
          Skill(id: 's-3', name: 'System Architecture'),
        ],
      );
    });

    test('generate5Questions creates 5 tailored questions derived from candidate experience', () async {
      final questions = await service.generate5Questions(
        resume: sampleResume,
        track: 'Behavioral & Leadership (STAR)',
        seniority: 'Senior / Staff (5-10 YOE)',
      );

      expect(questions.length, equals(5));
      expect(questions.first.question, contains('Senior Mobile Engineer'));
      expect(questions.first.resumeContext, contains('VALIXIS'));
      expect(questions.first.sampleAnswer, isNotEmpty);
    });

    test('evaluateAnswer scores response according to STAR Framework', () async {
      const candidateAnswer =
          'At VALIXIS, our mobile sync engine had high latency during offline reconnects. As Lead Engineer, I needed to eliminate data races while preserving offline usability. I architected a client-side vector caching layer with Hive and revision tokens. This reduced p99 sync latency by 68% and eliminated 100% of data race collisions across 250,000 active users.';

      final questions = await service.generate5Questions(
        resume: sampleResume,
        track: 'Behavioral & Leadership (STAR)',
        seniority: 'Senior / Staff (5-10 YOE)',
      );

      final eval = await service.evaluateAnswer(
        question: questions.first,
        candidateAnswer: candidateAnswer,
        resume: sampleResume,
        seniority: 'Senior / Staff (5-10 YOE)',
      );

      expect(eval.questionId, equals(questions.first.id));
      expect(eval.starScore.situationScore, greaterThanOrEqualTo(70));
      expect(eval.starScore.taskScore, greaterThanOrEqualTo(70));
      expect(eval.starScore.actionScore, greaterThanOrEqualTo(70));
      expect(eval.starScore.resultScore, greaterThanOrEqualTo(70));
      expect(eval.starScore.overallScore, greaterThanOrEqualTo(75));
      expect(eval.strengths, isNotEmpty);
      expect(eval.actionableTip, isNotEmpty);
    });

    test('computeFinalScorecard aggregates 5 question evaluations into readiness tier', () async {
      final questions = await service.generate5Questions(
        resume: sampleResume,
        track: 'Behavioral & Leadership (STAR)',
        seniority: 'Senior / Staff (5-10 YOE)',
      );

      final evaluations = <QuestionEvaluation>[];
      for (final q in questions) {
        final eval = await service.evaluateAnswer(
          question: q,
          candidateAnswer:
              'At my previous role, I led the technical architecture optimization. I engineered automated testing pipeline reducing build times by 40% across 50 mobile releases.',
          resume: sampleResume,
          seniority: 'Senior / Staff (5-10 YOE)',
        );
        evaluations.add(eval);
      }

      final scorecard = service.computeFinalScorecard(evaluations);

      expect(scorecard.evaluations.length, equals(5));
      expect(scorecard.overallReadinessScore, greaterThan(0));
      expect(scorecard.readinessTier, isNotEmpty);
      expect(scorecard.averageSituation, greaterThan(0));
      expect(scorecard.averageTask, greaterThan(0));
      expect(scorecard.averageAction, greaterThan(0));
      expect(scorecard.averageResult, greaterThan(0));
    });
  });
}
