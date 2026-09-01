import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:resume_brain/app/providers.dart';
import 'package:resume_brain/data/models/resume_models.dart';
import 'package:resume_brain/data/repositories/resume_repository.dart';

/// In-memory repository for isolated unit and widget tests without Hive dependencies.
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
}

void main() {
  late InMemoryResumeRepository mockRepo;
  late ProviderContainer container;

  Resume createSampleResume({
    String id = 'test-resume-id',
    String title = 'Full Stack Engineer Resume',
  }) {
    return Resume(
      id: id,
      title: title,
      personalInfo: PersonalInformation(
        fullName: 'Alex Morgan',
        jobTitle: 'Senior Software Engineer',
        email: 'alex.morgan@example.com',
        phone: '+1 (555) 019-2834',
        location: 'Austin, TX',
      ),
      summary: ProfessionalSummary(
        summaryText: 'Software developer with 5 years experience in building mobile and backend systems.',
      ),
      experiences: [
        Experience(
          id: 'exp-1',
          company: 'Tech Innovations LLC',
          position: 'Lead Flutter Developer',
          location: 'Austin, TX',
          startDate: '2021',
          endDate: 'Present',
          isCurrent: true,
          description: 'Developed mobile applications and integrated REST APIs.',
        ),
      ],
      educationList: [
        Education(
          id: 'edu-1',
          institution: 'University of Texas',
          degree: 'Bachelor of Science',
          fieldOfStudy: 'Computer Science',
          startDate: '2016',
          endDate: '2020',
        ),
      ],
      skills: [
        Skill(id: 'skill-1', name: 'Flutter', level: 'Expert'),
        Skill(id: 'skill-2', name: 'Dart', level: 'Expert'),
      ],
      projects: [
        Project(
          id: 'proj-1',
          name: 'Resume Brain App',
          role: 'Architect & Lead Developer',
          technologies: 'Flutter, Riverpod, Hive',
          description: 'ATS resume optimization engine.',
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

  group('Apply Suggestions Workflow - Unit & State Tests', () {
    test('1. Initial Resume State is correctly established in currentResumeProvider', () {
      final initialResume = createSampleResume();
      container.read(currentResumeProvider.notifier).setResume(initialResume);

      final state = container.read(currentResumeProvider);
      expect(state, isNotNull);
      expect(state!.id, equals('test-resume-id'));
      expect(state.title, equals('Full Stack Engineer Resume'));
      expect(state.personalInfo.fullName, equals('Alex Morgan'));
      expect(state.skills.length, equals(2));
      expect(state.experiences.length, equals(1));
    });

    test('2. Applying single summary suggestion updates summary and preserves all other sections', () {
      final initialResume = createSampleResume();
      container.read(currentResumeProvider.notifier).setResume(initialResume);

      const tailoredSummary =
          'Results-driven Senior Software Engineer with 5+ years specializing in high-throughput mobile architectures and cloud APIs.';
      container.read(currentResumeProvider.notifier).updateSummary(
            ProfessionalSummary(summaryText: tailoredSummary),
          );

      final updated = container.read(currentResumeProvider);
      expect(updated!.summary.summaryText, equals(tailoredSummary));
      
      // Verify other fields remain completely intact
      expect(updated.id, equals(initialResume.id));
      expect(updated.personalInfo.fullName, equals(initialResume.personalInfo.fullName));
      expect(updated.personalInfo.jobTitle, equals(initialResume.personalInfo.jobTitle));
      expect(updated.experiences.length, equals(initialResume.experiences.length));
      expect(updated.skills.length, equals(initialResume.skills.length));
      expect(updated.projects.length, equals(initialResume.projects.length));
      expect(updated.educationList.length, equals(initialResume.educationList.length));
    });

    test('3. Applying missing keyword / skill suggestions adds new skills correctly', () {
      final initialResume = createSampleResume();
      container.read(currentResumeProvider.notifier).setResume(initialResume);

      // Apply skill suggestions (e.g. from Job Matching Keyword Gaps)
      final suggestedSkill1 = Skill(id: 'skill-suggested-1', name: 'Docker', level: 'Intermediate');
      final suggestedSkill2 = Skill(id: 'skill-suggested-2', name: 'Kubernetes', level: 'Beginner');

      container.read(currentResumeProvider.notifier).addSkill(suggestedSkill1);
      container.read(currentResumeProvider.notifier).addSkill(suggestedSkill2);

      final updated = container.read(currentResumeProvider);
      expect(updated!.skills.length, equals(4));
      expect(updated.skills.map((s) => s.name), containsAll(['Flutter', 'Dart', 'Docker', 'Kubernetes']));
    });

    test('4. Applying experience bullet point suggestion updates existing entry in-place', () {
      final initialResume = createSampleResume();
      container.read(currentResumeProvider.notifier).setResume(initialResume);

      const improvedBullet =
          'Spearheaded mobile development, architecting 5+ production Flutter apps and improving API throughput by 42%.';
      
      final updatedExperience = initialResume.experiences.first.copyWith(
        description: improvedBullet,
      );

      container.read(currentResumeProvider.notifier).addExperience(updatedExperience);

      final updated = container.read(currentResumeProvider);
      expect(updated!.experiences.length, equals(1)); // In-place update, not appended
      expect(updated.experiences.first.id, equals('exp-1'));
      expect(updated.experiences.first.description, equals(improvedBullet));
      expect(updated.experiences.first.company, equals('Tech Innovations LLC'));
    });

    test('5. Applying multiple suggestions simultaneously updates all target sections atomically', () {
      final initialResume = createSampleResume();
      container.read(currentResumeProvider.notifier).setResume(initialResume);

      const tailoredSummary = 'Tailored AI Engineer Summary';
      final newSkill = Skill(id: 'skill-3', name: 'Python', level: 'Expert');
      const tailoredProject = 'Integrated Groq and Gemini AI APIs for live suggestions.';

      container.read(currentResumeProvider.notifier).updateResume((current) {
        return current.copyWith(
          summary: ProfessionalSummary(summaryText: tailoredSummary),
          skills: [...current.skills, newSkill],
          projects: current.projects.map((p) {
            return p.id == 'proj-1' ? p.copyWith(description: tailoredProject) : p;
          }).toList(),
        );
      });

      final updated = container.read(currentResumeProvider);
      expect(updated!.summary.summaryText, equals(tailoredSummary));
      expect(updated.skills.length, equals(3));
      expect(updated.skills.map((s) => s.name), contains('Python'));
      expect(updated.projects.first.description, equals(tailoredProject));
      
      // Untargeted sections remain unaffected
      expect(updated.personalInfo.fullName, equals('Alex Morgan'));
      expect(updated.educationList.first.institution, equals('University of Texas'));
    });

    test('6. Repeated application of the same suggestion maintains idempotence and prevents duplicates', () {
      final initialResume = createSampleResume();
      container.read(currentResumeProvider.notifier).setResume(initialResume);

      final skill = Skill(id: 'unique-skill-id', name: 'GraphQL', level: 'Intermediate');

      // Apply skill suggestion first time
      container.read(currentResumeProvider.notifier).addSkill(skill);
      expect(container.read(currentResumeProvider)!.skills.length, equals(3));

      // Apply same skill suggestion second time with updated proficiency
      final updatedSkill = skill.copyWith(level: 'Expert');
      container.read(currentResumeProvider.notifier).addSkill(updatedSkill);

      final state = container.read(currentResumeProvider);
      expect(state!.skills.length, equals(3)); // Still 3, not 4
      expect(state.skills.firstWhere((s) => s.id == 'unique-skill-id').level, equals('Expert'));
    });

    test('7. Empty suggestions and no-op update functions execute without error or unexpected mutation', () {
      final initialResume = createSampleResume();
      container.read(currentResumeProvider.notifier).setResume(initialResume);

      // Apply no-op
      container.read(currentResumeProvider.notifier).updateResume((current) => current);

      final state = container.read(currentResumeProvider);
      expect(state!.toMap(), equals(initialResume.toMap()));
    });

    test('8. Edge case: Applying suggestions to a minimal/partially populated Resume works cleanly', () {
      final emptyResume = Resume(
        id: 'minimal-id',
        title: 'Draft Resume',
        experiences: const [],
        skills: const [],
        projects: const [],
        educationList: const [],
      );

      container.read(currentResumeProvider.notifier).setResume(emptyResume);

      // Apply summary suggestion to empty resume
      container.read(currentResumeProvider.notifier).updateSummary(
            ProfessionalSummary(summaryText: 'Brand new summary'),
          );

      // Apply new skill to empty list
      container.read(currentResumeProvider.notifier).addSkill(
            Skill(id: 's-1', name: 'Rust', level: 'Beginner'),
          );

      final state = container.read(currentResumeProvider);
      expect(state!.summary.summaryText, equals('Brand new summary'));
      expect(state.skills.length, equals(1));
      expect(state.skills.first.name, equals('Rust'));
      expect(state.experiences, isEmpty);
    });

    test('9. Provider state isolation: independent containers do not leak state', () async {
      final containerA = ProviderContainer(
        overrides: [resumeRepositoryProvider.overrideWithValue(InMemoryResumeRepository())],
      );
      final containerB = ProviderContainer(
        overrides: [resumeRepositoryProvider.overrideWithValue(InMemoryResumeRepository())],
      );

      final resumeA = createSampleResume(id: 'resume-a', title: 'Resume A');
      final resumeB = createSampleResume(id: 'resume-b', title: 'Resume B');

      containerA.read(currentResumeProvider.notifier).setResume(resumeA);
      containerB.read(currentResumeProvider.notifier).setResume(resumeB);

      // Apply suggestion only in Container A
      containerA.read(currentResumeProvider.notifier).updateSummary(
            ProfessionalSummary(summaryText: 'Tailored Summary A'),
          );

      expect(containerA.read(currentResumeProvider)!.summary.summaryText, equals('Tailored Summary A'));
      expect(containerB.read(currentResumeProvider)!.summary.summaryText, equals(resumeB.summary.summaryText));

      await Future.delayed(Duration.zero);

      containerA.dispose();
      containerB.dispose();
    });

    test('10. Data serialization & schema regression test after applying suggestions', () {
      final initialResume = createSampleResume();
      container.read(currentResumeProvider.notifier).setResume(initialResume);

      container.read(currentResumeProvider.notifier).updateResume((current) => current.copyWith(
            summary: ProfessionalSummary(summaryText: 'Serialized Tailored Summary'),
            skills: [...current.skills, Skill(id: 's-new', name: 'AWS')],
          ));

      final updatedResume = container.read(currentResumeProvider)!;
      final map = updatedResume.toMap();
      final restored = Resume.fromMap(map);

      expect(restored.id, equals(updatedResume.id));
      expect(restored.summary.summaryText, equals('Serialized Tailored Summary'));
      expect(restored.skills.length, equals(3));
      expect(restored.skills.last.name, equals('AWS'));
    });
  });

  group('Apply Suggestions Workflow - UI Interaction Widget Tests', () {
    testWidgets('11. UI action triggers suggestion application and updates currentResumeProvider', (tester) async {
      final initialResume = createSampleResume();
      final testRepo = InMemoryResumeRepository();

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            resumeRepositoryProvider.overrideWithValue(testRepo),
          ],
          child: MaterialApp(
            home: Consumer(
              builder: (context, ref, child) {
                final resume = ref.watch(currentResumeProvider);

                return Scaffold(
                  body: Column(
                    children: [
                      Text(resume?.summary.summaryText ?? 'No Summary'),
                      ElevatedButton(
                        key: const Key('apply-suggestion-btn'),
                        onPressed: () {
                          ref.read(currentResumeProvider.notifier).updateSummary(
                                ProfessionalSummary(
                                  summaryText: 'Applied from UI Action: Highly scalable engineer',
                                ),
                              );
                        },
                        child: const Text('Apply Suggestion'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      );

      // Initially set the resume in the container of the pumped widget
      final element = tester.element(find.byType(Consumer));
      final ref = ProviderScope.containerOf(element);
      ref.read(currentResumeProvider.notifier).setResume(initialResume);
      await tester.pump();

      expect(find.text(initialResume.summary.summaryText), findsOneWidget);

      // Tap Apply Suggestion button
      await tester.tap(find.byKey(const Key('apply-suggestion-btn')));
      await tester.pump();

      // Verify UI and currentResumeProvider updated
      expect(find.text('Applied from UI Action: Highly scalable engineer'), findsOneWidget);
      expect(
        ref.read(currentResumeProvider)!.summary.summaryText,
        equals('Applied from UI Action: Highly scalable engineer'),
      );
    });
  });
}
