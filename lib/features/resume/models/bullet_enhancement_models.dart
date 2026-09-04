/// Categories for bullet point improvement suggestions.
enum BulletEnhancementCategory {
  actionOriented,
  metricFocused,
  concise,
  comprehensive,
  keywordRelevance,
  aiGenerated;

  String get displayName {
    switch (this) {
      case BulletEnhancementCategory.actionOriented:
        return 'Action-Oriented';
      case BulletEnhancementCategory.metricFocused:
        return 'Metric-Focused';
      case BulletEnhancementCategory.concise:
        return 'Concise & Punchy';
      case BulletEnhancementCategory.comprehensive:
        return 'Comprehensive';
      case BulletEnhancementCategory.keywordRelevance:
        return 'Keyword-Optimized';
      case BulletEnhancementCategory.aiGenerated:
        return 'AI Enhanced';
    }
  }
}

/// A specific enhanced bullet suggestion with rationale and categorization.
class EnhancedBulletSuggestion {
  final String text;
  final BulletEnhancementCategory category;
  final String reason;
  final String? categoryLabel;
  final bool isAiGenerated;

  const EnhancedBulletSuggestion({
    required this.text,
    required this.category,
    required this.reason,
    this.categoryLabel,
    this.isAiGenerated = false,
  });

  String get rationale => reason;

  String get displayCategory => categoryLabel ?? category.displayName;
}

/// Analysis breakdown of an individual resume bullet point.
class BulletAnalysisResult {
  final String originalText;
  final String? detectedActionVerb;
  final String? weakPhraseDetected;
  final bool hasQuantifiableMetric;
  final List<String> suggestedVerbs;
  final List<String> suggestedMetricPrompts;
  final List<String> suggestedKeywords;
  final List<String> strengthSignals;
  final List<EnhancedBulletSuggestion> suggestions;

  const BulletAnalysisResult({
    required this.originalText,
    this.detectedActionVerb,
    this.weakPhraseDetected,
    this.hasQuantifiableMetric = false,
    this.suggestedVerbs = const [],
    this.suggestedMetricPrompts = const [],
    this.suggestedKeywords = const [],
    this.strengthSignals = const [],
    this.suggestions = const [],
  });

  bool get hasActionVerb => detectedActionVerb != null && weakPhraseDetected == null;
  bool get hasMetric => hasQuantifiableMetric;
  bool get hasWeakPhrase => weakPhraseDetected != null;
  List<String> get weakPhrasesDetected => weakPhraseDetected != null ? [weakPhraseDetected!] : [];
  List<String> get industryKeywords => suggestedKeywords;

  double get overallScore {
    double score = 0.3; // Baseline score for having text
    if (hasActionVerb) score += 0.35;
    if (hasMetric) score += 0.25;
    if (!hasWeakPhrase) score += 0.10;
    return score.clamp(0.0, 1.0);
  }
}
