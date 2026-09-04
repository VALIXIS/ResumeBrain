/// Service providing semantic similarity analysis and synonym matching
/// between Job Description terms/skills and candidate Resume content.
class SemanticMatcherService {
  /// Canonical skill synonym dictionary.
  static const Map<String, List<String>> _synonymGroups = {
    'react': ['react.js', 'reactjs', 'react native'],
    'javascript': ['js', 'ecmascript'],
    'typescript': ['ts'],
    'amazon web services': ['aws', 'amazon cloud'],
    'google cloud platform': ['gcp', 'google cloud'],
    'microsoft azure': ['azure'],
    'kubernetes': ['k8s'],
    'postgresql': ['postgres', 'pg'],
    'mongodb': ['mongo'],
    'machine learning': ['ml'],
    'artificial intelligence': ['ai'],
    'deep learning': ['dl'],
    'natural language processing': ['nlp'],
    'continuous integration': ['ci/cd', 'cicd', 'ci cd'],
    'rest api': ['restful', 'restful api', 'rest'],
    'node.js': ['nodejs', 'node'],
    'vue.js': ['vuejs', 'vue'],
    'next.js': ['nextjs', 'next'],
    'express.js': ['expressjs', 'express'],
    'c#': ['csharp', 'c-sharp'],
    'c++': ['cpp'],
  };

  /// Calculates semantic similarity score between two technical terms or skill names.
  /// Returns a value between 0.0 and 1.0.
  double calculateSimilarity(String term1, String term2) {
    final t1 = term1.trim().toLowerCase();
    final t2 = term2.trim().toLowerCase();

    if (t1.isEmpty || t2.isEmpty) return 0.0;
    if (t1 == t2) return 1.0;

    // Check synonym dictionary groups
    for (final entry in _synonymGroups.entries) {
      final canonical = entry.key;
      final aliases = entry.value;

      final set = {canonical, ...aliases};
      if (set.contains(t1) && set.contains(t2)) {
        return 0.95; // High confidence semantic match
      }
    }

    // Partial prefix/suffix overlap for domain terms (e.g., "react developer" vs "react")
    if (t1.contains(t2) || t2.contains(t1)) {
      return 0.75;
    }

    return 0.0;
  }

  /// Identifies semantic matches between missing JD skills and candidate resume skills.
  /// Returns a map of JD skill to matched Resume skill with similarity >= [threshold].
  Map<String, String> findSemanticMatches({
    required List<String> jdSkills,
    required List<String> resumeSkills,
    double threshold = 0.70,
  }) {
    final matches = <String, String>{};

    for (final jdSkill in jdSkills) {
      for (final resSkill in resumeSkills) {
        final score = calculateSimilarity(jdSkill, resSkill);
        if (score >= threshold) {
          matches[jdSkill] = resSkill;
          break; // take first high-confidence match
        }
      }
    }

    return matches;
  }
}
