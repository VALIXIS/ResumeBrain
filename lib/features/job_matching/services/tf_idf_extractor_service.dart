import 'dart:math';

/// Service providing deterministic TF-IDF term scoring and keyword extraction
/// for job description text analysis.
class TfIdfExtractorService {
  /// Standard English stop words to filter out.
  static const Set<String> _stopWords = {
    'a', 'about', 'above', 'across', 'after', 'again', 'against', 'all', 'almost',
    'alone', 'along', 'already', 'also', 'although', 'always', 'among', 'an',
    'and', 'another', 'any', 'anybody', 'anyone', 'anything', 'anywhere', 'are',
    'around', 'as', 'at', 'back', 'be', 'became', 'because', 'become', 'becomes',
    'becoming', 'been', 'before', 'behind', 'being', 'below', 'beside', 'besides',
    'between', 'beyond', 'both', 'but', 'by', 'came', 'can', 'cannot', 'come',
    'could', 'did', 'do', 'does', 'doing', 'done', 'down', 'during', 'each',
    'either', 'else', 'elsewhere', 'enough', 'etc', 'even', 'ever', 'every',
    'everybody', 'everyone', 'everything', 'everywhere', 'except', 'few', 'for',
    'former', 'formerly', 'from', 'further', 'had', 'has', 'have', 'having', 'he',
    'hence', 'her', 'here', 'hers', 'herself', 'him', 'himself', 'his', 'how',
    'however', 'i', 'if', 'in', 'into', 'is', 'it', 'its', 'itself', 'just', 'keep',
    'keeps', 'kept', 'know', 'knows', 'known', 'last', 'latter', 'latterly', 'least',
    'less', 'made', 'make', 'many', 'may', 'me', 'meanwhile', 'might', 'mine',
    'more', 'moreover', 'most', 'mostly', 'much', 'must', 'my', 'myself', 'name',
    'namely', 'neither', 'never', 'nevertheless', 'new', 'next', 'no', 'nobody',
    'none', 'noone', 'nor', 'not', 'nothing', 'now', 'nowhere', 'of', 'off',
    'often', 'on', 'once', 'one', 'only', 'onto', 'or', 'other', 'others',
    'otherwise', 'our', 'ours', 'ourselves', 'out', 'over', 'own', 'part', 'per',
    'perhaps', 'please', 'put', 'rather', 'same', 'see', 'seem', 'seemed',
    'seeming', 'seems', 'several', 'she', 'should', 'show', 'side', 'since', 'so',
    'some', 'somehow', 'someone', 'something', 'sometime', 'sometimes', 'somewhere',
    'still', 'such', 'take', 'than', 'that', 'the', 'their', 'them', 'themselves',
    'then', 'thence', 'there', 'thereafter', 'thereby', 'therefore', 'therein',
    'thereupon', 'these', 'they', 'this', 'those', 'through', 'throughout', 'thru',
    'thus', 'to', 'together', 'too', 'toward', 'towards', 'under', 'until', 'up',
    'upon', 'us', 'very', 'via', 'was', 'we', 'well', 'were', 'what', 'whatever',
    'when', 'whence', 'whenever', 'where', 'whereafter', 'whereas', 'whereby',
    'wherein', 'whereupon', 'wherever', 'whether', 'which', 'while', 'whither',
    'who', 'whoever', 'whole', 'whom', 'whose', 'why', 'will', 'with', 'within',
    'without', 'would', 'yet', 'you', 'your', 'yours', 'yourself', 'yourselves'
  };

  /// Noise terms typical of job postings that should not be treated as technical skills.
  static const Set<String> _jobNoiseWords = {
    'job', 'description', 'requirements', 'responsibilities', 'role', 'candidate',
    'position', 'company', 'team', 'work', 'experience', 'years', 'qualification',
    'qualifications', 'duties', 'environment', 'ability', 'skills', 'knowledge',
    'working', 'looking', 'seeking', 'opportunity', 'strong', 'excellent',
    'preferred', 'required', 'plus', 'ideal', 'successful', 'degree', 'bachelor',
    'bachelors', 'master', 'masters', 'phd', 'field', 'related', 'full', 'time',
    'part', 'hybrid', 'remote', 'office', 'day', 'days', 'week', 'month', 'year',
    'location', 'salary', 'benefits', 'apply', 'joining', 'join'
  };

  /// Pre-computed Document Frequency (DF) map across a reference corpus of 100 job documents.
  static const int _corpusTotalDocs = 100;
  static const Map<String, int> _corpusDocumentFrequencies = {
    'experience': 95,
    'team': 90,
    'work': 88,
    'role': 85,
    'skills': 80,
    'development': 75,
    'building': 70,
    'design': 65,
    'systems': 60,
    'solutions': 55,
    'flutter': 10,
    'dart': 10,
    'react': 15,
    'python': 18,
    'java': 20,
    'javascript': 22,
    'typescript': 20,
    'docker': 12,
    'kubernetes': 8,
    'aws': 16,
    'postgresql': 12,
    'mongodb': 14,
    'graphql': 10,
    'rest': 25,
    'ci/cd': 15,
    'git': 30,
    'redux': 8,
    'riverpod': 5,
    'spring': 12,
    'django': 10,
    'fastapi': 6,
    'tensorflow': 8,
    'pytorch': 7,
  };

  /// Tokenizes text into normalized candidate term tokens.
  List<String> tokenize(String text) {
    if (text.trim().isEmpty) return [];

    final cleaned = text.toLowerCase().replaceAll(RegExp(r'[^\w\s+#/-]'), ' ');
    final rawTokens = cleaned.split(RegExp(r'\s+'));

    final validTokens = <String>[];
    for (final token in rawTokens) {
      final t = token.replaceAll(RegExp(r'^[^\w+#]+|[^\w+#]+$'), '');
      if (t.length >= 2 && !_stopWords.contains(t) && !_jobNoiseWords.contains(t)) {
        validTokens.add(t);
      }
    }
    return validTokens;
  }

  /// Calculates deterministic TF-IDF scores for extracted tokens in [text].
  Map<String, double> extractTfIdfScores(String text) {
    final tokens = tokenize(text);
    if (tokens.isEmpty) return {};

    final termCounts = <String, int>{};
    for (final token in tokens) {
      termCounts[token] = (termCounts[token] ?? 0) + 1;
    }

    final totalTokens = tokens.length;
    final tfMap = <String, double>{};
    termCounts.forEach((term, count) {
      tfMap[term] = count / totalTokens;
    });

    final tfidfMap = <String, double>{};
    tfMap.forEach((term, tf) {
      final df = _corpusDocumentFrequencies[term] ?? 15;
      final idf = log((_corpusTotalDocs + 1) / (df + 1)) + 1.0;
      final score = tf * idf;
      tfidfMap[term] = double.parse(score.toStringAsFixed(4));
    });

    final sortedEntries = tfidfMap.entries.toList()
      ..sort((a, b) {
        final cmp = b.value.compareTo(a.value);
        return cmp != 0 ? cmp : a.key.compareTo(b.key);
      });

    return Map.fromEntries(sortedEntries);
  }
}
