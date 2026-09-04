import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/custom_button.dart';
import '../models/bullet_enhancement_models.dart';
import '../services/bullet_enhancement_service.dart';

/// Modal dialog providing interactive bullet-point enhancement with
/// action-verb suggestions, metric-quantifier scaffolding, industry keyword guidance,
/// multiple categorized AI variants, and 1-click replacement.
class BulletPointEnhancerDialog extends ConsumerStatefulWidget {
  final String initialBullet;
  final String? roleContext;
  final ValueChanged<String> onApply;

  const BulletPointEnhancerDialog({
    super.key,
    required this.initialBullet,
    this.roleContext,
    required this.onApply,
  });

  static Future<void> show({
    required BuildContext context,
    required String initialBullet,
    String? roleContext,
    required ValueChanged<String> onApply,
  }) {
    return showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) => BulletPointEnhancerDialog(
        initialBullet: initialBullet,
        roleContext: roleContext,
        onApply: onApply,
      ),
    );
  }

  @override
  ConsumerState<BulletPointEnhancerDialog> createState() => _BulletPointEnhancerDialogState();
}

class _BulletPointEnhancerDialogState extends ConsumerState<BulletPointEnhancerDialog> {
  late final TextEditingController _editingCtrl;
  late final BulletEnhancementService _enhancementService;

  BulletAnalysisResult? _analysis;
  List<EnhancedBulletSuggestion> _suggestions = [];
  bool _isLoading = true;
  String _selectedCategory = 'all';

  @override
  void initState() {
    super.initState();
    _editingCtrl = TextEditingController(text: widget.initialBullet);
    _enhancementService = ref.read(bulletEnhancementServiceProvider);
    _loadEnhancements();
  }

  @override
  void dispose() {
    _editingCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadEnhancements() async {
    setState(() => _isLoading = true);
    try {
      final analysis = _enhancementService.analyzeBullet(
        _editingCtrl.text,
        roleContext: widget.roleContext,
      );
      final suggestions = await _enhancementService.generateEnhancements(
        _editingCtrl.text,
        roleContext: widget.roleContext,
      );

      if (mounted) {
        setState(() {
          _analysis = analysis;
          _suggestions = suggestions;
          _isLoading = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _applySuggestion(String text) {
    setState(() {
      _editingCtrl.text = text;
      _analysis = _enhancementService.analyzeBullet(text, roleContext: widget.roleContext);
    });
  }

  void _insertPrefix(String verb) {
    final current = _editingCtrl.text.trim();
    if (current.isEmpty) {
      _applySuggestion('$verb ');
      return;
    }

    // Replace first word or prepend
    final words = current.split(' ');
    if (words.isNotEmpty) {
      words[0] = verb;
      _applySuggestion(words.join(' '));
    } else {
      _applySuggestion('$verb $current');
    }
  }

  void _appendScaffold(String scaffold) {
    final current = _editingCtrl.text.trim();
    if (current.isEmpty) {
      _applySuggestion(scaffold);
    } else {
      _applySuggestion('$current, $scaffold');
    }
  }

  void _handleConfirm() {
    final result = _editingCtrl.text.trim();
    if (result.isNotEmpty) {
      widget.onApply(result);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 660, maxHeight: 780),
        child: Column(
          children: [
            // Header
            _buildHeader(context),
            const Divider(color: AppColors.surfaceBorder, height: 1),

            // Main Content Area
            Expanded(
              child: _isLoading
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const CircularProgressIndicator(color: AppColors.accentPurple),
                          const SizedBox(height: 16),
                          Text(
                            'Analyzing bullet & generating AI suggestions...',
                            style: AppTypography.bodyMedium,
                          ),
                        ],
                      ),
                    )
                  : SingleChildScrollView(
                      padding: const EdgeInsets.all(AppSpacing.lg),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Quality Signals & Score
                          if (_analysis != null) _buildQualityScorecard(_analysis!),
                          const SizedBox(height: AppSpacing.md),

                          // Active / Editable Bullet Box
                          _buildWorkingBulletEditor(),
                          const SizedBox(height: AppSpacing.lg),

                          // Action Verbs
                          _buildActionVerbsSection(),
                          const SizedBox(height: AppSpacing.md),

                          // Metric Quantifier Scaffolds
                          _buildMetricScaffoldsSection(),
                          const SizedBox(height: AppSpacing.md),

                          // Industry Keywords
                          if (_analysis?.industryKeywords.isNotEmpty ?? false) ...[
                            _buildIndustryKeywordsSection(_analysis!.industryKeywords),
                            const SizedBox(height: AppSpacing.md),
                          ],

                          // Categorized AI Suggestions
                          _buildAiSuggestionsSection(),
                        ],
                      ),
                    ),
            ),

            // Footer / Actions
            const Divider(color: AppColors.surfaceBorder, height: 1),
            _buildFooter(context),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.accentPurple.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.auto_awesome,
              color: AppColors.accentPurple,
              size: 22,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'AI Bullet-Point Enhancer',
                  style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Strengthen impact with action verbs, quantifiable metrics, and keywords.',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Semantics(
            label: 'Close dialog',
            button: true,
            child: IconButton(
              icon: const Icon(Icons.close, color: AppColors.textMuted),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQualityScorecard(BulletAnalysisResult analysis) {
    final scorePercent = (analysis.overallScore * 100).toInt();
    Color scoreColor = AppColors.accentRed;
    if (analysis.overallScore >= 0.75) {
      scoreColor = AppColors.accentGreen;
    } else if (analysis.overallScore >= 0.5) {
      scoreColor = AppColors.accentOrange;
    }

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surfaceBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Bullet Impact Rating',
                style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: scoreColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: scoreColor.withValues(alpha: 0.4)),
                ),
                child: Text(
                  '$scorePercent% Impact',
                  style: AppTypography.labelLarge.copyWith(
                    color: scoreColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildSignalBadge(
                label: 'Strong Action Verb',
                active: analysis.hasActionVerb,
                tooltip: analysis.hasActionVerb
                    ? 'Starts with strong active verb'
                    : 'Missing strong opening action verb',
              ),
              _buildSignalBadge(
                label: 'Quantifiable Metric',
                active: analysis.hasMetric,
                tooltip: analysis.hasMetric
                    ? 'Contains quantifiable numbers or percentages'
                    : 'Consider quantifying your achievement',
              ),
              _buildSignalBadge(
                label: 'No Weak Phrases',
                active: !analysis.hasWeakPhrase,
                tooltip: analysis.hasWeakPhrase
                    ? 'Contains passive phrases (${analysis.weakPhrasesDetected.join(', ')})'
                    : 'Free of passive "responsible for" / "worked on" phrasing',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSignalBadge({
    required String label,
    required bool active,
    required String tooltip,
  }) {
    final color = active ? AppColors.accentGreen : AppColors.textMuted;
    final bg = active ? AppColors.accentGreen.withValues(alpha: 0.12) : AppColors.surfaceLight;

    return Semantics(
      label: '$label: ${active ? "Satisfied" : "Missing"}',
      child: Tooltip(
        message: tooltip,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.3)),
          ),
          child: Row(
            mainAxisSize: min(MainAxisSize.min, MainAxisSize.max),
            children: [
              Icon(
                active ? Icons.check_circle_outline : Icons.help_outline,
                size: 14,
                color: color,
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: active ? AppColors.textPrimary : AppColors.textMuted,
                  fontSize: 11,
                  fontWeight: active ? FontWeight.w600 : FontWeight.normal,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  MainAxisSize min(MainAxisSize a, MainAxisSize b) => a;

  Widget _buildWorkingBulletEditor() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Active Bullet Text',
              style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600),
            ),
            if (widget.initialBullet.trim() != _editingCtrl.text.trim())
              TextButton.icon(
                style: TextButton.styleFrom(
                  minimumSize: const Size(48, 48),
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                ),
                onPressed: () => _applySuggestion(widget.initialBullet),
                icon: const Icon(Icons.undo, size: 14, color: AppColors.textMuted),
                label: Text(
                  'Revert to Original',
                  style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Semantics(
          label: 'Active bullet text editor',
          child: TextFormField(
            controller: _editingCtrl,
            maxLines: 3,
            minLines: 2,
            maxLength: 500,
            onChanged: (val) {
              setState(() {
                _analysis = _enhancementService.analyzeBullet(val, roleContext: widget.roleContext);
              });
            },
            style: AppTypography.bodyMedium,
            decoration: InputDecoration(
              filled: true,
              fillColor: AppColors.surfaceLight,
              contentPadding: const EdgeInsets.all(12),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.surfaceBorder),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.surfaceBorder),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: const BorderSide(color: AppColors.accentPurple, width: 1.5),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildActionVerbsSection() {
    final categories = _enhancementService.categorizedActionVerbs;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.bolt, color: AppColors.accentOrange, size: 16),
            const SizedBox(width: 4),
            Text(
              'Action-Verb Power Boosters',
              style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              'Tap to insert',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: categories.entries.expand((entry) {
            return entry.value.take(4).map((verb) {
              return ConstrainedBox(
                constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
                child: Center(
                  child: ActionChip(
                    label: Text(verb),
                    labelStyle: AppTypography.bodySmall.copyWith(
                      color: AppColors.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    backgroundColor: AppColors.surfaceLight,
                    side: const BorderSide(color: AppColors.surfaceBorder),
                    tooltip: 'Insert "$verb" as opening verb',
                    onPressed: () => _insertPrefix(verb),
                  ),
                ),
              );
            });
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildMetricScaffoldsSection() {
    final scaffolds = _enhancementService.metricScaffolds;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.trending_up, color: AppColors.accentGreen, size: 16),
            const SizedBox(width: 4),
            Text(
              'Metric & Quantifier Scaffolds',
              style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600),
            ),
            const Spacer(),
            Text(
              'Tap to append template',
              style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted, fontSize: 11),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: scaffolds.take(6).map((scaffold) {
            return ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              child: Center(
                child: ActionChip(
                  avatar: const Icon(Icons.add, size: 14, color: AppColors.accentGreen),
                  label: Text(scaffold),
                  labelStyle: AppTypography.bodySmall.copyWith(
                    color: AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                  backgroundColor: AppColors.surfaceLight,
                  side: const BorderSide(color: AppColors.surfaceBorder),
                  tooltip: 'Append "$scaffold"',
                  onPressed: () => _appendScaffold(scaffold),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildIndustryKeywordsSection(List<String> keywords) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.tag, color: AppColors.primary, size: 16),
            const SizedBox(width: 4),
            Text(
              'Industry Keyword Guidance',
              style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: keywords.map((kw) {
            return ConstrainedBox(
              constraints: const BoxConstraints(minHeight: 48, minWidth: 48),
              child: Center(
                child: ActionChip(
                  label: Text(kw),
                  labelStyle: AppTypography.bodySmall.copyWith(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                  backgroundColor: AppColors.primary.withValues(alpha: 0.08),
                  side: BorderSide(color: AppColors.primary.withValues(alpha: 0.25)),
                  tooltip: 'Add keyword "$kw"',
                  onPressed: () => _appendScaffold('leveraging $kw'),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  Widget _buildAiSuggestionsSection() {
    final filtered = _selectedCategory == 'all'
        ? _suggestions
        : _suggestions.where((s) => s.category.name == _selectedCategory).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.auto_awesome, color: AppColors.accentPurple, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Categorized AI Recommendations',
                  style: AppTypography.labelLarge.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            // Filter dropdown or tabs
            DropdownButton<String>(
              value: _selectedCategory,
              underline: const SizedBox(),
              icon: const Icon(Icons.arrow_drop_down, color: AppColors.textMuted),
              style: AppTypography.bodySmall.copyWith(color: AppColors.textPrimary),
              items: const [
                DropdownMenuItem(value: 'all', child: Text('All Types')),
                DropdownMenuItem(value: 'actionOriented', child: Text('Action-Oriented')),
                DropdownMenuItem(value: 'metricFocused', child: Text('Metric-Focused')),
                DropdownMenuItem(value: 'concise', child: Text('Concise')),
                DropdownMenuItem(value: 'comprehensive', child: Text('Comprehensive')),
              ],
              onChanged: (val) {
                if (val != null) {
                  setState(() => _selectedCategory = val);
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 8),
        if (filtered.isEmpty)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppColors.surfaceLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Center(
              child: Text(
                'No suggestions found for selected category.',
                style: AppTypography.bodySmall,
              ),
            ),
          )
        else
          ...filtered.map((sug) => _buildSuggestionCard(sug)),
      ],
    );
  }

  Widget _buildSuggestionCard(EnhancedBulletSuggestion sug) {
    final isCurrent = _editingCtrl.text.trim() == sug.text.trim();

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppColors.accentPurple.withValues(alpha: 0.08)
            : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isCurrent ? AppColors.accentPurple : AppColors.surfaceBorder,
          width: isCurrent ? 1.5 : 1.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppColors.accentPurple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  sug.category.displayName,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.accentPurple,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  sug.rationale,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.textMuted,
                    fontSize: 11,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                child: Center(
                  child: Semantics(
                    button: true,
                    label: 'Use ${sug.category.displayName} suggestion',
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(
                          color: isCurrent ? AppColors.accentPurple : AppColors.surfaceBorder,
                        ),
                        backgroundColor: isCurrent ? AppColors.accentPurple.withValues(alpha: 0.1) : null,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => _applySuggestion(sug.text),
                      child: Text(
                        isCurrent ? 'Selected' : 'Use This',
                        style: AppTypography.labelSmall.copyWith(
                          color: isCurrent ? AppColors.accentPurple : AppColors.textPrimary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            sug.text,
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.textPrimary,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_editingCtrl.text.length}/500 chars',
            style: AppTypography.bodySmall.copyWith(color: AppColors.textMuted),
          ),
          Row(
            children: [
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                child: Center(
                  child: TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(
                      'Cancel',
                      style: AppTypography.labelLarge.copyWith(color: AppColors.textMuted),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ConstrainedBox(
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
                child: Center(
                  child: Semantics(
                    button: true,
                    label: 'Apply enhanced bullet to resume',
                    child: AppButton(
                      text: 'Replace Bullet',
                      icon: Icons.check,
                      isFullWidth: false,
                      onPressed: _handleConfirm,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
