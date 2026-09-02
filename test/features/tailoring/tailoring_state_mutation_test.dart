import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resume_brain/app/providers.dart';
import 'package:resume_brain/data/models/resume_models.dart';
import 'package:resume_brain/data/repositories/cloud_sync_adapter.dart';
import 'package:resume_brain/data/repositories/resume_repository.dart';

/// In-memory repository implementation for state mutation QA tests.
class InMemoryResumeRepository implements ResumeRepository {
  final Map<String, Resume> _storage = {};

  @override
  Future<void> init() async {}

  @override
  Future<List<Resume>> getAllResumes() async => _storage.values.toList();

  @override
  Future<Resume?> getResumeById(String id) async => _storage[id];

  @override
  Future<void> saveResume(Resume resume) async {
    _storage[resume.id] = resume;
  }

  @override
  Future<void> deleteResume(String id) async {
    _storage.remove(id);
  }

  @override
  Future<CloudSyncResult> syncResumeToCloud(Resume resume) async => CloudSyncResult.unsupported();

  @override
  Future<CloudSyncResult> syncAllToCloud() async => CloudSyncResult.unsupported();
}

void main() {
  late InMemoryResumeRepository mockRepo;
  late ProviderContainer container;

  Resume createSampleResume() {
    return Resume(
      id: 'mutation-test-resume-101',
      title: 'Full Stack Engineer Profile',
      personalInfo: PersonalInformation(
        fullName: 'Morgan Blake',
        jobTitle: 'Senior Full Stack Engineer',
        email: 'morgan.blake@example.com',
        phone: '+1 (555) 987-6543',
        location: 'Seattle, WA',
        website: 'https://morganblake.dev',
      ),
      summary: ProfessionalSummary(
        summaryText: 'Software engineer building web and cloud services.',
      ),
      experiences: [
        Experience(
          id: 'exp-101',
          company: 'CloudTech Systems',
          position: 'Lead Backend Developer',
          location: 'Seattle, WA',
          startDate: '2021',
          endDate: 'Present',
          isCurrent: true,
          description: 'Developed REST APIs and managed PostgreSQL databases.',
        ),
      ],
      educationList: [
        Education(
          id: 'edu-101',
          institution: 'University of Washington',
          degree: 'Bachelor of Science',
          fieldOfStudy: 'Computer Science',
          startDate: '2016',
          endDate: '2020',
        ),
      ],
      skills: [
        Skill(id: 'skill-101', name: 'Go', level: 'Expert'),
        Skill(id: 'skill-102', name: 'PostgreSQL', level: 'Expert'),
      ],
      projects: [
        Project(
          id: 'proj-101',
          name: 'Microservice Gateway',
          role: 'Lead Architect',
          technologies: 'Go, Docker, gRPC',
          description: 'High-performance API gateway.',
        ),
      ],
      certifications: [
        Certification(
          id: 'cert-101',
          name: 'AWS Solutions Architect',
          issuingOrganization: 'Amazon Web Services',
          issueDate: '2022',
        ),
      ],
      languages: [
        Language(
          id: 'lang-101',
          name: 'English',
          proficiency: 'Native',
        ),
      ],
      customSections: [
        CustomSection(
          id: 'cs-101',
          title: 'Open Source',
          items: const ['Contributed to Go standard library.'],
        ),
      ],
    );
  }

  setUp(() {
    mockRepo = InMemoryResumeRepository();
    container = ProviderContainer(
      overrides: [
        resumeRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
  });

  tearDown(() {
    container.dispose();
  });

  group('Tailoring State Mutation Safety & Isolation Tests', () {
    test('1. Generating tailoring AI response alone does NOT mutate active Resume in currentResumeProvider', () async {
      final initialResume = createSampleResume();
      container.read(currentResumeProvider.notifier).setResume(initialResume);

      final stateBefore = container.read(currentResumeProvider);
      expect(stateBefore, isNotNull);

      // Perform AI tailoring generation via AIService
      final aiService = container.read(aiServiceProvider);
      final aiResponse = await aiService.tailorResume(
        initialResume,
        'Seeking Senior Go & Distributed Systems Engineer.',
      );

      expect(aiResponse.isSuccess, isTrue);
      expect(aiResponse.outputText, isNotEmpty);

      // Verify currentResumeProvider state is 100% identical to initial state
      final stateAfter = container.read(currentResumeProvider);
      expect(stateAfter!.toMap(), equals(initialResume.toMap()));
    });

    test('2. Applying tailored summary mutates only summary and leaves all other sections untouched', () async {
      final initialResume = createSampleResume();
      container.read(currentResumeProvider.notifier).setResume(initialResume);

      const tailoredSummary =
          'Architected distributed microservices handling 20,000+ RPS using Go, PostgreSQL, and Docker with 99.99% uptime.';

      container.read(currentResumeProvider.notifier).updateSummary(
            ProfessionalSummary(summaryText: tailoredSummary),
          );

      final updatedState = container.read(currentResumeProvider)!;
      expect(updatedState.summary.summaryText, equals(tailoredSummary));

      // Verify all other fields and nested lists remain untouched
      expect(updatedState.id, equals(initialResume.id));
      expect(updatedState.title, equals(initialResume.title));
      expect(updatedState.personalInfo.fullName, equals(initialResume.personalInfo.fullName));
      expect(updatedState.personalInfo.email, equals(initialResume.personalInfo.email));
      expect(updatedState.experiences.length, equals(initialResume.experiences.length));
      expect(updatedState.educationList.length, equals(initialResume.educationList.length));
      expect(updatedState.skills.length, equals(initialResume.skills.length));
      expect(updatedState.projects.length, equals(initialResume.projects.length));
      expect(updatedState.certifications.length, equals(initialResume.certifications.length));
      expect(updatedState.languages.length, equals(initialResume.languages.length));
      expect(updatedState.customSections.length, equals(initialResume.customSections.length));
    });

    test('3. Strict Immutability: original Resume fixture reference is never mutated in-place', () async {
      final originalResumeFixture = createSampleResume();
      final originalSummaryText = originalResumeFixture.summary.summaryText;
      final originalSkillsCount = originalResumeFixture.skills.length;

      container.read(currentResumeProvider.notifier).setResume(originalResumeFixture);

      // Mutate currentResumeProvider via notifier
      container.read(currentResumeProvider.notifier).updateSummary(
            ProfessionalSummary(summaryText: 'Brand New Tailored Summary Text'),
          );

      container.read(currentResumeProvider.notifier).addSkill(
            Skill(id: 's-new-999', name: 'Kubernetes', level: 'Expert'),
          );

      // Assert original object fixture retained its immutable initial state
      expect(originalResumeFixture.summary.summaryText, equals(originalSummaryText));
      expect(originalResumeFixture.skills.length, equals(originalSkillsCount));
      expect(originalResumeFixture.skills.map((s) => s.name), isNot(contains('Kubernetes')));
    });

    test('4. Cumulative Multi-Section Tailoring updates persist correctly without overwriting each other', () async {
      final initialResume = createSampleResume();
      container.read(currentResumeProvider.notifier).setResume(initialResume);

      const newSummary = 'Tailored Lead Go Systems Engineer';
      final newSkill1 = Skill(id: 'skill-docker', name: 'Docker', level: 'Expert');
      final newSkill2 = Skill(id: 'skill-grpc', name: 'gRPC', level: 'Intermediate');

      final updatedExp = initialResume.experiences.first.copyWith(
        description: 'Spearheaded gRPC microservices deployment reducing p99 latency by 35%.',
      );

      // Apply batch updates
      container.read(currentResumeProvider.notifier).updateResume((current) {
        return current.copyWith(
          summary: ProfessionalSummary(summaryText: newSummary),
          skills: [...current.skills, newSkill1, newSkill2],
          experiences: [updatedExp],
        );
      });

      final finalState = container.read(currentResumeProvider)!;
      expect(finalState.summary.summaryText, equals(newSummary));
      expect(finalState.skills.length, equals(4));
      expect(finalState.skills.map((s) => s.name), containsAll(['Go', 'PostgreSQL', 'Docker', 'gRPC']));
      expect(finalState.experiences.first.description, contains('reducing p99 latency by 35%'));
    });

    test('5. Idempotent Skill Application prevents duplicate entries and handles level updates', () async {
      final initialResume = createSampleResume();
      container.read(currentResumeProvider.notifier).setResume(initialResume);

      final skillToUpdate = Skill(id: 'skill-101', name: 'Go', level: 'Staff Level');

      // Update existing skill ID
      container.read(currentResumeProvider.notifier).addSkill(skillToUpdate);

      final state = container.read(currentResumeProvider)!;
      expect(state.skills.length, equals(2)); // Length remains 2
      expect(state.skills.firstWhere((s) => s.id == 'skill-101').level, equals('Staff Level'));
    });

    test('6. Boundary & Minimal Resume Safety: Applying suggestions to empty resume succeeds cleanly', () async {
      final emptyResume = Resume(
        id: 'empty-resume-id',
        title: 'Minimal Resume',
        experiences: const [],
        skills: const [],
        projects: const [],
        educationList: const [],
      );

      container.read(currentResumeProvider.notifier).setResume(emptyResume);

      // Apply tailored summary
      container.read(currentResumeProvider.notifier).updateSummary(
            ProfessionalSummary(summaryText: 'Tailored summary for empty profile.'),
          );

      // Add tailored skill
      container.read(currentResumeProvider.notifier).addSkill(
            Skill(id: 'sk-1', name: 'Rust', level: 'Beginner'),
          );

      final state = container.read(currentResumeProvider)!;
      expect(state.summary.summaryText, equals('Tailored summary for empty profile.'));
      expect(state.skills.length, equals(1));
      expect(state.skills.first.name, equals('Rust'));
      expect(state.experiences, isEmpty);
      expect(state.projects, isEmpty);
    });

    test('7. Schema & Serialization Regression: toMap and fromMap preserve tailored resume state', () async {
      final initialResume = createSampleResume();
      container.read(currentResumeProvider.notifier).setResume(initialResume);

      container.read(currentResumeProvider.notifier).updateSummary(
            ProfessionalSummary(summaryText: 'Serialized Tailored Summary Value'),
          );

      final state = container.read(currentResumeProvider)!;
      final map = state.toMap();
      final restoredResume = Resume.fromMap(map);

      expect(restoredResume.id, equals(state.id));
      expect(restoredResume.summary.summaryText, equals('Serialized Tailored Summary Value'));
      expect(restoredResume.skills.length, equals(state.skills.length));
      expect(restoredResume.experiences.first.id, equals('exp-101'));
    });

    test('8. Isolated ProviderContainer instances prevent state leakage during tailoring tests', () async {
      final container1 = ProviderContainer(
        overrides: [resumeRepositoryProvider.overrideWithValue(InMemoryResumeRepository())],
      );
      final container2 = ProviderContainer(
        overrides: [resumeRepositoryProvider.overrideWithValue(InMemoryResumeRepository())],
      );

      final r1 = createSampleResume();
      final r2 = createSampleResume();

      container1.read(currentResumeProvider.notifier).setResume(r1);
      container2.read(currentResumeProvider.notifier).setResume(r2);

      container1.read(currentResumeProvider.notifier).updateSummary(
            ProfessionalSummary(summaryText: 'Container 1 Summary Update'),
          );

      expect(container1.read(currentResumeProvider)!.summary.summaryText, equals('Container 1 Summary Update'));
      expect(container2.read(currentResumeProvider)!.summary.summaryText, equals(r2.summary.summaryText));

      await Future.delayed(Duration.zero);

      container1.dispose();
      container2.dispose();
    });
  });
}
