import 'package:flutter_test/flutter_test.dart';
import 'package:resume_brain/data/models/resume_models.dart';
import 'package:resume_brain/features/job_matching/services/keyword_extractor_service.dart';


void main() {
  group('KeywordExtractorService Unit Tests', () {
    late KeywordExtractorService service;

    setUp(() {
      service = KeywordExtractorService();
    });

    test('Basic Technical Skill Extraction', () {
      const jdText = '''
        We are looking for a Software Engineer. The ideal candidate must have experience in
        Python and Java. You will build cross-platform mobile apps using Flutter and Dart.
        Knowledge of SQL, Machine Learning, AWS, and Git is highly desirable.
      ''';

      final skills = service.extractKeywords(jdText);

      // Verify technical terms are extracted and sorted alphabetically
      expect(skills, containsAll([
        'Python',
        'Java',
        'Flutter',
        'Dart',
        'SQL',
        'Machine Learning',
        'Amazon Web Services', // Canonical form of AWS
        'Git',
      ]));

      // Verify that unrelated natural language words are not extracted as skills
      expect(skills, isNot(contains('looking')));
      expect(skills, isNot(contains('candidate')));
      expect(skills, isNot(contains('Software')));
    });

    test('Case Insensitivity and Normalization', () {
      // Test different case variations of the same skill
      expect(service.normalizeSkill('python'), equals('Python'));
      expect(service.normalizeSkill('PYTHON'), equals('Python'));
      expect(service.normalizeSkill('Python'), equals('Python'));

      // Verify aliases canonicalize correctly
      expect(service.normalizeSkill('aws'), equals('Amazon Web Services'));
      expect(service.normalizeSkill('js'), equals('JavaScript'));
      expect(service.normalizeSkill('cpp'), equals('C++'));

      // Verify that extractKeywords handles case variations
      const jdText = 'We use python, PYTHON, and PyThOn in our backend.';
      final skills = service.extractKeywords(jdText);

      // Verify it extracts only one unique canonical skill
      expect(skills, equals(['Python']));
    });

    test('Duplicate Handling', () {
      const jdText = '''
        Python developers needed. Python is our primary language.
        We also use Git and Git for version control.
      ''';

      final skills = service.extractKeywords(jdText);

      // Verify duplicates are removed and returned skills are unique
      expect(skills, equals(['Git', 'Python']));

      // Verify duplicates do not inflate overlap percentage in comparison
      final result = service.extractAndCompare(
        jobDescriptionText: jdText,
        userSkills: ['Python', 'Python', 'Git'],
      );

      // JD has 2 unique skills ('Git', 'Python'). Resume has 2 unique matching skills.
      // Overlap should be exactly 100.0%
      expect(result.extractedJdSkills, equals(['Git', 'Python']));
      expect(result.matchedSkills, equals(['Git', 'Python']));
      expect(result.overlapPercentage, equals(100.0));
    });

    test('Multi-word Technical Skills and Longest Match Priority', () {
      const jdText = '''
        Requirements: Machine Learning, Deep Learning, Computer Vision,
        Natural Language Processing, and React Native development.
      ''';

      final skills = service.extractKeywords(jdText);

      expect(skills, containsAll([
        'Machine Learning',
        'Deep Learning',
        'Computer Vision',
        'Natural Language Processing',
        'React Native',
      ]));

      // Verify longest match priority prevents sub-term duplicates (e.g. React Native matching React)
      expect(skills, isNot(contains('React')));
    });

    test('Punctuation, Formatting, and Word Boundaries', () {
      // 1. Punctuation and formatting
      const formattedText = 'Required skills: C++, Java/React, (Python), and Docker.';
      final skills = service.extractKeywords(formattedText);

      expect(skills, containsAll(['C++', 'Java', 'React', 'Python', 'Docker']));

      // 2. Word boundary checks to prevent substring false positives
      // "go" should not match inside "good" or "outgoing"
      const boundaryText1 = 'This is a good candidate with outgoing personality.';
      expect(service.extractKeywords(boundaryText1), isNot(contains('Go')));

      // "go" should match as a separate word
      const boundaryText2 = 'We need developer who can write Go services.';
      expect(service.extractKeywords(boundaryText2), contains('Go'));

      // "shell" should not match inside "eggshell"
      const boundaryText3 = 'We have eggshell color walls.';
      expect(service.extractKeywords(boundaryText3), isNot(contains('Shell')));
    });

    test('Skill Overlap Calculations (Full, Partial, Zero)', () {
      const jdText = 'We need Python, Java, Docker, and Kubernetes.'; // 4 unique JD skills

      // 1. Full Overlap (100.0%)
      final fullResult = service.extractAndCompare(
        jobDescriptionText: jdText,
        userSkills: ['Python', 'Java', 'Docker', 'Kubernetes'],
      );
      expect(fullResult.overlapPercentage, equals(100.0));
      expect(fullResult.matchedSkills.length, equals(4));
      expect(fullResult.missingSkills.isEmpty, isTrue);

      // 2. Partial Overlap (50.0%)
      final partialResult = service.extractAndCompare(
        jobDescriptionText: jdText,
        userSkills: ['Python', 'Java', 'JavaScript'], // JavaScript is not in JD
      );
      expect(partialResult.overlapPercentage, equals(50.0));
      expect(partialResult.matchedSkills, equals(['Java', 'Python']));
      expect(partialResult.missingSkills, equals(['Docker', 'Kubernetes']));

      // 3. Zero Overlap (0.0%)
      final zeroResult = service.extractAndCompare(
        jobDescriptionText: jdText,
        userSkills: ['TypeScript', 'Vue.js'],
      );
      expect(zeroResult.overlapPercentage, equals(0.0));
      expect(zeroResult.matchedSkills.isEmpty, isTrue);
      expect(zeroResult.missingSkills, equals(['Docker', 'Java', 'Kubernetes', 'Python']));
    });

    test('Comparison using Full Resume Object', () {
      const jdText = 'Backend: Python, PostgreSQL, Redis, Docker.'; // 4 unique JD skills

      final resume = Resume(
        title: 'Backend Resume',
        personalInfo: PersonalInformation(jobTitle: 'Python Developer'),
        summary: ProfessionalSummary(summaryText: 'Expert in Postgres databases.'),
        skills: [Skill(name: 'Redis')],
        experiences: [
          Experience(description: 'We deployed backend containers to cloud.') // No matched JD skills here
        ],
      );

      final result = service.extractAndCompare(
        jobDescriptionText: jdText,
        resume: resume,
      );

      // 'Python' in jobTitle, 'PostgreSQL' matched by 'Postgres' in summary, 'Redis' in skills.
      // Expected matching skills: 'PostgreSQL', 'Python', 'Redis' (3 out of 4)
      // Percentage: 3 / 4 * 100.0 = 75.0%
      expect(result.matchedSkills, equals(['PostgreSQL', 'Python', 'Redis']));
      expect(result.missingSkills, equals(['Docker']));
      expect(result.overlapPercentage, equals(75.0));
    });

    test('Edge Cases handling', () {
      // 1. Empty JD
      final emptyJdResult = service.extractAndCompare(
        jobDescriptionText: '',
        userSkills: ['Python'],
      );
      expect(emptyJdResult.extractedJdSkills.isEmpty, isTrue);
      expect(emptyJdResult.matchedSkills.isEmpty, isTrue);
      expect(emptyJdResult.overlapPercentage, equals(0.0));

      // 2. Empty Resume Skills
      final emptyResumeResult = service.extractAndCompare(
        jobDescriptionText: 'Python, Java',
        userSkills: [],
      );
      expect(emptyResumeResult.overlapPercentage, equals(0.0));
      expect(emptyResumeResult.missingSkills, equals(['Java', 'Python']));

      // 3. Both Empty
      final bothEmptyResult = service.extractAndCompare(
        jobDescriptionText: '',
        userSkills: [],
      );
      expect(bothEmptyResult.overlapPercentage, equals(0.0));

      // 4. JD with no recognized technical skills
      final unrecognizedResult = service.extractKeywords('We want a quick learner who is highly motivated.');
      expect(unrecognizedResult.isEmpty, isTrue);

      // 5. Whitespace-heavy inputs
      final whitespaceResult = service.extractKeywords('  \n  Python  \t  \n  ');
      expect(whitespaceResult, equals(['Python']));
    });

    test('Result Consistency and Deterministic Ordering', () {
      const text = 'We need Docker, Python, Java, and Kubernetes.';

      // Run multiple times and verify results are identical
      final firstRun = service.extractKeywords(text);
      final secondRun = service.extractKeywords(text);

      expect(firstRun, equals(secondRun));

      // Verify alphabetical sorting order
      expect(firstRun, equals(['Docker', 'Java', 'Kubernetes', 'Python']));
    });

    test('normalizeSkill fallback and TitleCase formatting', () {
      // 1. Trim whitespace
      expect(service.normalizeSkill('  python  '), equals('Python'));

      // 2. Empty string
      expect(service.normalizeSkill(''), equals(''));
      expect(service.normalizeSkill('   '), equals(''));

      // 3. Fallback to Title Case for unrecognized terms
      expect(service.normalizeSkill('new_tech_skill'), equals('New_tech_skill'));
      expect(service.normalizeSkill('custom service mesh'), equals('Custom Service Mesh'));
    });
  });
}
