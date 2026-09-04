import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../data/models/resume_models.dart';
import '../../ai/services/ai_service.dart';
import '../models/bullet_enhancement_models.dart';

/// Provider for BulletEnhancementService.
final bulletEnhancementServiceProvider = Provider<BulletEnhancementService>((ref) {
  final aiService = ref.watch(aiServiceProvider);
  return BulletEnhancementService(aiService: aiService);
});

/// Service providing contextual analysis, action-verb suggestions, metric quantifier prompts,
/// industry keyword guidance, and deterministic + AI enhancement variations for resume bullet points.
class BulletEnhancementService {
  final AIService? aiService;

  BulletEnhancementService({this.aiService});

  // Weak opening phrases mapped to primary recommended strong verbs
  static const Map<String, List<String>> _weakVerbReplacements = {
    'worked on': ['Developed', 'Engineered', 'Architected', 'Implemented', 'Optimized'],
    'worked with': ['Collaborated with', 'Partnered with', 'Leveraged', 'Integrated'],
    'responsible for': ['Led', 'Directed', 'Managed', 'Spearheaded', 'Executed'],
    'was responsible for': ['Led', 'Directed', 'Managed', 'Spearheaded', 'Executed'],
    'helped with': ['Accelerated', 'Assisted in deploying', 'Facilitated', 'Co-authored'],
    'helped to': ['Accelerated', 'Enabled', 'Streamlined', 'Co-developed'],
    'helped': ['Facilitated', 'Enabled', 'Accelerated', 'Co-authored'],
    'did': ['Executed', 'Completed', 'Authored', 'Produced'],
    'handled': ['Managed', 'Resolved', 'Orchestrated', 'Maintained'],
    'assisted in': ['Contributed to', 'Co-developed', 'Supported deployment of'],
    'assisted with': ['Contributed to', 'Co-developed', 'Supported deployment of'],
    'participated in': ['Collaborated on', 'Engaged in', 'Contributed to'],
    'was part of': ['Collaborated on', 'Co-built', 'Partnered with team to deliver'],
    'managed to': ['Successfully delivered', 'Achieved', 'Executed'],
    'tried to': ['Spearheaded initiatives to', 'Iterated on'],
    'involved in': ['Drove', 'Engineered', 'Championed', 'Spearheaded'],
    'made': ['Created', 'Authored', 'Engineered', 'Designed'],
    'changed': ['Refactored', 'Modernized', 'Redesigned', 'Overhauled'],
  };

  // Strong action verbs categorized by domain
  static const List<String> kLeadershipVerbs = [
    'Led',
    'Spearheaded',
    'Orchestrated',
    'Directed',
    'Managed',
    'Championed',
    'Guided',
    'Mentored',
  ];

  static const List<String> kTechnicalVerbs = [
    'Architected',
    'Developed',
    'Engineered',
    'Implemented',
    'Automated',
    'Refactored',
    'Built',
    'Deployed',
  ];

  static const List<String> kOptimizationVerbs = [
    'Optimized',
    'Accelerated',
    'Streamlined',
    'Maximized',
    'Reduced',
    'Enhanced',
    'Upgraded',
    'Overhauled',
  ];

  static const List<String> kDeliveryVerbs = [
    'Delivered',
    'Launched',
    'Shipped',
    'Executed',
    'Published',
    'Pioneered',
    'Integrated',
    'Standardized',
  ];

  // Metric quantifier scaffolds
  static const List<String> kMetricScaffolds = [
    'increasing efficiency by 25%',
    'reducing latency by 40%',
    'serving 50,000+ active users',
    'saving \$15,000 in monthly cloud costs',
    'saving 10+ engineering hours weekly',
    'leading a cross-functional team of 6',
    'accelerating release cycle by 3x',
    'boosting user engagement by 35%',
  ];

  // Metric prompt templates
  static const List<String> kMetricPrompts = [
    '% increase',
    '% reduction / decrease',
    '\$ cost saved',
    '\$ revenue generated',
    'hours saved weekly',
    'users served / impacted',
    'team size led',
    'projects delivered',
    'performance speedup',
    'conversion rate boost',
  ];

  // Role / Industry specific keywords mapping
  static const Map<String, List<String>> _industryKeywords = {
    'software': [
      'REST APIs',
      'CI/CD Pipelines',
      'Docker',
      'Kubernetes',
      'AWS / Cloud',
      'Microservices',
      'Flutter / Dart',
      'SQL / NoSQL',
      'Unit & Integration Testing',
      'Agile / Scrum',
    ],
    'tech': [
      'Scalable Architecture',
      'CI/CD',
      'Cloud Infrastructure',
      'Git Workflow',
      'API Integration',
      'Security Compliance',
      'Performance Profiling',
    ],
    'data': [
      'Python',
      'SQL Queries',
      'Pandas / NumPy',
      'ETL Pipelines',
      'Machine Learning Models',
      'Data Visualization',
      'A/B Testing',
      'Statistical Analysis',
      'Tableau / PowerBI',
    ],
    'product': [
      'Product Roadmap',
      'User Stories',
      'Cross-Functional Alignment',
      'KPI Metrics',
      'User Research',
      'Go-to-Market (GTM)',
      'Feature Prioritization',
      'Sprint Planning',
    ],
    'marketing': [
      'SEO / SEM',
      'Conversion Funnel',
      'Customer Acquisition (CAC)',
      'CTR & Engagement',
      'Campaign ROI',
      'Retention Rate',
      'Email Automations',
      'Google Analytics',
    ],
    'finance': [
      'Financial Modeling',
      'Budget Forecasting',
      'P&L Management',
      'Cost Optimization',
      'Risk Assessment',
      'Audit Compliance',
      'ROI Analysis',
    ],
  };

  /// Returns categorized map of strong action verbs.
  Map<String, List<String>> get categorizedActionVerbs => {
        'Leadership': kLeadershipVerbs,
        'Technical': kTechnicalVerbs,
        'Optimization': kOptimizationVerbs,
        'Delivery': kDeliveryVerbs,
      };

  /// Returns metric quantifier template scaffolds.
  List<String> get metricScaffolds => kMetricScaffolds;

  /// Synchronous analysis of a bullet point.
  BulletAnalysisResult analyzeBullet(String rawBullet, {String? roleContext}) {
    final cleaned = rawBullet.trim().replaceAll(RegExp(r'^[•\-\*\s]+'), '').trim();
    if (cleaned.isEmpty) {
      return const BulletAnalysisResult(
        originalText: '',
        strengthSignals: ['Empty bullet point'],
      );
    }

    // 1. Weak phrase check
    String? weakPhrase;
    List<String> suggestedVerbs = [];
    final lower = cleaned.toLowerCase();

    for (final entry in _weakVerbReplacements.entries) {
      if (lower.startsWith(entry.key)) {
        weakPhrase = entry.key;
        suggestedVerbs = entry.value;
        break;
      }
    }

    // Check detected action verb if not weak phrase
    String? detectedVerb;
    if (weakPhrase == null) {
      final firstWord = cleaned.split(' ').first;
      final allVerbs = [...kLeadershipVerbs, ...kTechnicalVerbs, ...kOptimizationVerbs, ...kDeliveryVerbs];
      if (allVerbs.any((v) => v.toLowerCase() == firstWord.toLowerCase())) {
        detectedVerb = firstWord;
      }
    }

    if (suggestedVerbs.isEmpty) {
      suggestedVerbs = [
        ...kTechnicalVerbs.take(3),
        ...kOptimizationVerbs.take(3),
        ...kLeadershipVerbs.take(2),
      ];
    }

    // 2. Metric check
    final hasMetric = RegExp(
      r'(\d+%|\$\s?\d+|\b\d+\+?\s?(users|clients|hours|days|weeks|engineers|projects|x|times)\b|\b\d{2,}\b)',
      caseSensitive: false,
    ).hasMatch(cleaned);

    // 3. Industry keywords
    final keywords = _resolveKeywordsFromRole(roleContext);

    // 4. Strength Signals
    final List<String> signals = [];
    if (weakPhrase != null) {
      signals.add('Weak opening phrase detected ("$weakPhrase")');
    } else if (detectedVerb != null) {
      signals.add('Strong action verb opening ("$detectedVerb")');
    } else {
      signals.add('Standard opening');
    }

    if (hasMetric) {
      signals.add('Quantifiable metric included');
    } else {
      signals.add('Measurable metric missing — consider quantifying result');
    }

    return BulletAnalysisResult(
      originalText: cleaned,
      detectedActionVerb: detectedVerb,
      weakPhraseDetected: weakPhrase,
      hasQuantifiableMetric: hasMetric,
      suggestedVerbs: suggestedVerbs,
      suggestedMetricPrompts: kMetricPrompts,
      suggestedKeywords: keywords,
      strengthSignals: signals,
    );
  }

  /// Generate enhanced bullet variations (deterministic + AI fallback).
  Future<List<EnhancedBulletSuggestion>> generateEnhancements(
    String rawBullet, {
    String? roleContext,
    Resume? resumeContext,
  }) async {
    final cleaned = rawBullet.trim().replaceAll(RegExp(r'^[•\-\*\s]+'), '').trim();
    if (cleaned.isEmpty) {
      return [];
    }

    final analysis = analyzeBullet(cleaned, roleContext: roleContext);
    final List<EnhancedBulletSuggestion> suggestions = [];

    // 1. Action-Oriented Suggestion
    if (analysis.weakPhraseDetected != null) {
      final weak = analysis.weakPhraseDetected!;
      final remainder = cleaned.substring(weak.length).trim();
      final topVerb = analysis.suggestedVerbs.first;
      final formattedRemainder = remainder.isNotEmpty ? remainder[0].toLowerCase() + remainder.substring(1) : '';
      suggestions.add(
        EnhancedBulletSuggestion(
          category: BulletEnhancementCategory.actionOriented,
          reason: 'Replaces passive phrase "$weak" with authoritative verb "$topVerb".',
          text: '$topVerb $formattedRemainder'.trim(),
        ),
      );
    } else {
      final firstWord = cleaned.split(' ').first;
      final alternateVerb = kOptimizationVerbs.firstWhere(
        (v) => v.toLowerCase() != firstWord.toLowerCase(),
        orElse: () => 'Streamlined',
      );
      final remainder = cleaned.contains(' ') ? cleaned.substring(firstWord.length).trim() : '';
      suggestions.add(
        EnhancedBulletSuggestion(
          category: BulletEnhancementCategory.actionOriented,
          reason: 'Enhances initiative and ownership using "$alternateVerb".',
          text: '$alternateVerb $remainder'.trim(),
        ),
      );
    }

    // 2. Metric-Focused Suggestion
    final baseForMetric = suggestions.isNotEmpty ? suggestions.first.text : cleaned;
    final cleanBase = baseForMetric.endsWith('.') ? baseForMetric.substring(0, baseForMetric.length - 1) : baseForMetric;
    final scaffold = kMetricScaffolds.first;
    suggestions.add(
      EnhancedBulletSuggestion(
        category: BulletEnhancementCategory.metricFocused,
        reason: 'Adds measurable proof of achievement and ROI.',
        text: '$cleanBase, $scaffold.',
      ),
    );

    // 3. Concise & Punchy Suggestion
    final conciseText = _generateConciseVariation(cleaned, analysis.weakPhraseDetected);
    if (conciseText != cleaned && !suggestions.any((s) => s.text == conciseText)) {
      suggestions.add(
        EnhancedBulletSuggestion(
          category: BulletEnhancementCategory.concise,
          reason: 'Eliminates filler words and highlights core impact directly.',
          text: conciseText,
        ),
      );
    }

    // 4. Comprehensive Suggestion
    final keyword = analysis.suggestedKeywords.isNotEmpty ? analysis.suggestedKeywords.first : 'industry best practices';
    suggestions.add(
      EnhancedBulletSuggestion(
        category: BulletEnhancementCategory.comprehensive,
        reason: 'Combines proactive leadership, technical skill ($keyword), and quantified outcome.',
        text: '$cleanBase leveraging $keyword, delivering measurable performance gains.',
      ),
    );

    // 5. Try AIService if available
    if (aiService != null) {
      try {
        final aiResult = await aiService!.improveText(cleaned, roleContext ?? 'resume bullet');
        if (aiResult.isSuccess && aiResult.outputText.isNotEmpty && aiResult.outputText != cleaned) {
          suggestions.insert(
            0,
            EnhancedBulletSuggestion(
              category: BulletEnhancementCategory.aiGenerated,
              reason: aiResult.suggestions.isNotEmpty
                  ? aiResult.suggestions.first
                  : 'Synthesized via AI for maximum ATS scoring and narrative polish.',
              text: aiResult.outputText.replaceAll(RegExp(r'^[•\-\*\s]+'), '').trim(),
              isAiGenerated: true,
            ),
          );
        }
      } catch (_) {
        // Safe deterministic fallback
      }
    }

    return suggestions;
  }

  /// Analyze a bullet point and return structured suggestions and signals (legacy compatibility).
  Future<BulletAnalysisResult> analyzeAndEnhanceBullet({
    required String rawBullet,
    Resume? resumeContext,
    String sectionContext = 'experience',
  }) async {
    final analysis = analyzeBullet(rawBullet, roleContext: sectionContext);
    final suggestions = await generateEnhancements(rawBullet, roleContext: sectionContext, resumeContext: resumeContext);
    return BulletAnalysisResult(
      originalText: analysis.originalText,
      detectedActionVerb: analysis.detectedActionVerb,
      weakPhraseDetected: analysis.weakPhraseDetected,
      hasQuantifiableMetric: analysis.hasQuantifiableMetric,
      suggestedVerbs: analysis.suggestedVerbs,
      suggestedMetricPrompts: analysis.suggestedMetricPrompts,
      suggestedKeywords: analysis.suggestedKeywords,
      strengthSignals: analysis.strengthSignals,
      suggestions: suggestions,
    );
  }

  List<String> _resolveKeywordsFromRole(String? roleContext) {
    if (roleContext == null || roleContext.trim().isEmpty) {
      return _industryKeywords['software']!;
    }
    final lower = roleContext.toLowerCase();
    for (final entry in _industryKeywords.entries) {
      if (lower.contains(entry.key)) {
        return entry.value;
      }
    }
    return _industryKeywords['software']!;
  }

  String _generateConciseVariation(String text, String? weakPhrase) {
    String result = text;
    if (weakPhrase != null && _weakVerbReplacements.containsKey(weakPhrase)) {
      final verb = _weakVerbReplacements[weakPhrase]!.first;
      result = '$verb ${text.substring(weakPhrase.length).trim()}';
    }

    // Remove common filler words
    result = result
        .replaceAll(RegExp(r'\bin order to\b', caseSensitive: false), 'to')
        .replaceAll(RegExp(r'\bduties included\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\btasked with\b', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (result.isNotEmpty) {
      result = result[0].toUpperCase() + result.substring(1);
    }
    return result;
  }
}
