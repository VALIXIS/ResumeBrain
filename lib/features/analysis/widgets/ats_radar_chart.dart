import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../services/ats_engine.dart';

/// An interactive, animated 4-axis ATS Radar / Spider Chart widget.
/// Visualizes ATS compliance across:
/// 1. Impact Verbs
/// 2. Formatting
/// 3. Contact Completeness
/// 4. Keyword Density
class AtsRadarChart extends StatefulWidget {
  final AtsScoreReport report;
  final double size;
  final AtsDimension? selectedDimension;
  final ValueChanged<AtsDimension?>? onDimensionSelected;

  const AtsRadarChart({
    super.key,
    required this.report,
    this.size = 280.0,
    this.selectedDimension,
    this.onDimensionSelected,
  });

  @override
  State<AtsRadarChart> createState() => _AtsRadarChartState();
}

class _AtsRadarChartState extends State<AtsRadarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(AtsRadarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.report.overallScore != widget.report.overallScore ||
        oldWidget.report.impactVerbsScore != widget.report.impactVerbsScore ||
        oldWidget.report.formattingScore != widget.report.formattingScore ||
        oldWidget.report.contactCompletenessScore != widget.report.contactCompletenessScore ||
        oldWidget.report.keywordDensityScore != widget.report.keywordDensityScore) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  int _getScoreForDimension(AtsDimension dimension) {
    switch (dimension) {
      case AtsDimension.impactVerbs:
        return widget.report.impactVerbsScore;
      case AtsDimension.formatting:
        return widget.report.formattingScore;
      case AtsDimension.contactCompleteness:
        return widget.report.contactCompletenessScore;
      case AtsDimension.keywordDensity:
        return widget.report.keywordDensityScore;
    }
  }

  void _handleTapDown(TapDownDetails details, Size containerSize) {
    final center = Offset(containerSize.width / 2, containerSize.height / 2);
    final tapPosition = details.localPosition;
    final dx = tapPosition.dx - center.dx;
    final dy = tapPosition.dy - center.dy;

    double angle = math.atan2(dy, dx);
    final axesAngles = [-math.pi / 2, 0.0, math.pi / 2, math.pi];
    int closestIndex = 0;
    double minDiff = double.infinity;

    for (int i = 0; i < axesAngles.length; i++) {
      double diff = (angle - axesAngles[i]).abs();
      if (diff > math.pi) {
        diff = (2 * math.pi) - diff;
      }
      if (diff < minDiff) {
        minDiff = diff;
        closestIndex = i;
      }
    }

    final dimensions = [
      AtsDimension.impactVerbs,
      AtsDimension.formatting,
      AtsDimension.contactCompleteness,
      AtsDimension.keywordDensity,
    ];

    final tappedDim = dimensions[closestIndex];
    if (widget.selectedDimension == tappedDim) {
      widget.onDimensionSelected?.call(null);
    } else {
      widget.onDimensionSelected?.call(tappedDim);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Semantics(
      label: 'ATS 4-Axis Score Radar Chart. Overall ATS Score: ${widget.report.overallScore} out of 100. Impact Verbs: ${widget.report.impactVerbsScore}, Formatting: ${widget.report.formattingScore}, Contact Completeness: ${widget.report.contactCompletenessScore}, Keyword Density: ${widget.report.keywordDensityScore}. Tap any dimension to view detailed recommendations.',
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surface : Colors.white,
          borderRadius: AppRadius.borderLg,
          border: Border.all(color: AppColors.surfaceBorder),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // Chart Title & Active Indicator Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.15),
                        borderRadius: AppRadius.borderSm,
                      ),
                      child: const Icon(
                        Icons.radar_rounded,
                        color: AppColors.primary,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Text(
                      'ATS Dimension Radar',
                      style: AppTypography.titleMedium.copyWith(
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.sm,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: _getOverallScoreColor(widget.report.overallScore).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: _getOverallScoreColor(widget.report.overallScore).withValues(alpha: 0.5),
                    ),
                  ),
                  child: Text(
                    '${widget.report.overallScore}/100',
                    style: AppTypography.labelLarge.copyWith(
                      color: _getOverallScoreColor(widget.report.overallScore),
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: AppSpacing.md),

            // Animated CustomPainter Radar Canvas
            LayoutBuilder(
              builder: (context, constraints) {
                final availableWidth = constraints.maxWidth;
                final chartDimension = math.min(availableWidth, widget.size);

                return SizedBox(
                  width: chartDimension,
                  height: chartDimension,
                  child: GestureDetector(
                    onTapDown: (details) => _handleTapDown(details, Size(chartDimension, chartDimension)),
                    child: AnimatedBuilder(
                      animation: _animation,
                      builder: (context, child) {
                        return CustomPaint(
                          size: Size(chartDimension, chartDimension),
                          painter: _AtsRadarChartPainter(
                            progress: _animation.value,
                            impactVerbsScore: widget.report.impactVerbsScore,
                            formattingScore: widget.report.formattingScore,
                            contactCompletenessScore: widget.report.contactCompletenessScore,
                            keywordDensityScore: widget.report.keywordDensityScore,
                            selectedDimension: widget.selectedDimension,
                            isDark: isDark,
                            primaryColor: AppColors.primary,
                            accentColor: AppColors.secondary,
                            gridColor: isDark
                                ? AppColors.surfaceBorder
                                : Colors.grey.shade300,
                            textColor: AppColors.textPrimary,
                            subtextColor: AppColors.textSecondary,
                          ),
                        );
                      },
                    ),
                  ),
                );
              },
            ),

            const SizedBox(height: AppSpacing.md),

            // Dimension Quick Selector Badges below Chart
            Wrap(
              spacing: AppSpacing.xs,
              runSpacing: AppSpacing.xs,
              alignment: WrapAlignment.center,
              children: AtsDimension.values.map((dimension) {
                final score = _getScoreForDimension(dimension);
                final isSelected = widget.selectedDimension == dimension;

                return ChoiceChip(
                  label: Text('${dimension.displayName}: $score%'),
                  selected: isSelected,
                  selectedColor: AppColors.primary.withValues(alpha: 0.2),
                  backgroundColor: isDark
                      ? AppColors.surfaceLight
                      : const Color(0xFFF1F5F9),
                  side: BorderSide(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.surfaceBorder,
                    width: isSelected ? 1.5 : 1.0,
                  ),
                  labelStyle: AppTypography.bodySmall.copyWith(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.textSecondary,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                  onSelected: (selected) {
                    widget.onDimensionSelected?.call(selected ? dimension : null);
                  },
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Color _getOverallScoreColor(int score) {
    if (score >= 80) return AppColors.accentGreen;
    if (score >= 60) return AppColors.accentOrange;
    return AppColors.accentRed;
  }
}

/// CustomPainter for rendering the 4-axis radar polygon, concentric web grid, and labels.
class _AtsRadarChartPainter extends CustomPainter {
  final double progress;
  final int impactVerbsScore;
  final int formattingScore;
  final int contactCompletenessScore;
  final int keywordDensityScore;
  final AtsDimension? selectedDimension;
  final bool isDark;
  final Color primaryColor;
  final Color accentColor;
  final Color gridColor;
  final Color textColor;
  final Color subtextColor;

  _AtsRadarChartPainter({
    required this.progress,
    required this.impactVerbsScore,
    required this.formattingScore,
    required this.contactCompletenessScore,
    required this.keywordDensityScore,
    this.selectedDimension,
    required this.isDark,
    required this.primaryColor,
    required this.accentColor,
    required this.gridColor,
    required this.textColor,
    required this.subtextColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final maxRadius = (math.min(size.width, size.height) / 2) * 0.68;

    final angles = [
      -math.pi / 2, // Top: Impact Verbs
      0.0,          // Right: Formatting
      math.pi / 2,  // Bottom: Contact Completeness
      math.pi,      // Left: Keyword Density
    ];

    final scores = [
      impactVerbsScore,
      formattingScore,
      contactCompletenessScore,
      keywordDensityScore,
    ];

    final dimensions = [
      AtsDimension.impactVerbs,
      AtsDimension.formatting,
      AtsDimension.contactCompleteness,
      AtsDimension.keywordDensity,
    ];

    // 1. Draw Concentric Web Rings (25%, 50%, 75%, 100%)
    final gridPaint = Paint()
      ..color = gridColor.withValues(alpha: isDark ? 0.4 : 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    final rings = [0.25, 0.50, 0.75, 1.0];
    for (final ring in rings) {
      final r = maxRadius * ring;
      final ringPath = Path();
      for (int i = 0; i < angles.length; i++) {
        final x = center.dx + r * math.cos(angles[i]);
        final y = center.dy + r * math.sin(angles[i]);
        if (i == 0) {
          ringPath.moveTo(x, y);
        } else {
          ringPath.lineTo(x, y);
        }
      }
      ringPath.close();
      canvas.drawPath(ringPath, gridPaint);
    }

    // 2. Draw Axis Spokes & Radial Lines
    final spokePaint = Paint()
      ..color = gridColor.withValues(alpha: isDark ? 0.6 : 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;

    for (int i = 0; i < angles.length; i++) {
      final x = center.dx + maxRadius * math.cos(angles[i]);
      final y = center.dy + maxRadius * math.sin(angles[i]);
      canvas.drawLine(center, Offset(x, y), spokePaint);
    }

    // 3. Draw Highlight for Selected Dimension Spoke Sector (if selected)
    if (selectedDimension != null) {
      final index = dimensions.indexOf(selectedDimension!);
      if (index != -1) {
        final highlightPaint = Paint()
          ..color = primaryColor.withValues(alpha: 0.15)
          ..style = PaintingStyle.fill;

        final prevAngle = angles[(index - 1 + angles.length) % angles.length];
        final nextAngle = angles[(index + 1) % angles.length];
        final currentAngle = angles[index];

        final sectorPath = Path()
          ..moveTo(center.dx, center.dy)
          ..lineTo(
            center.dx + maxRadius * math.cos((currentAngle + prevAngle) / 2),
            center.dy + maxRadius * math.sin((currentAngle + prevAngle) / 2),
          )
          ..lineTo(
            center.dx + maxRadius * 1.15 * math.cos(currentAngle),
            center.dy + maxRadius * 1.15 * math.sin(currentAngle),
          )
          ..lineTo(
            center.dx + maxRadius * math.cos((currentAngle + nextAngle) / 2),
            center.dy + maxRadius * math.sin((currentAngle + nextAngle) / 2),
          )
          ..close();

        canvas.drawPath(sectorPath, highlightPaint);
      }
    }

    // 4. Calculate Polygon Vertices based on score & animation progress
    final polyPoints = <Offset>[];
    for (int i = 0; i < angles.length; i++) {
      final scaledScore = (scores[i] / 100.0) * progress;
      final r = maxRadius * scaledScore;
      final x = center.dx + r * math.cos(angles[i]);
      final y = center.dy + r * math.sin(angles[i]);
      polyPoints.add(Offset(x, y));
    }

    // 5. Draw Fill Polygon
    final fillPath = Path();
    for (int i = 0; i < polyPoints.length; i++) {
      if (i == 0) {
        fillPath.moveTo(polyPoints[i].dx, polyPoints[i].dy);
      } else {
        fillPath.lineTo(polyPoints[i].dx, polyPoints[i].dy);
      }
    }
    fillPath.close();

    final fillPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.28)
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // 6. Draw Polygon Border
    final borderPaint = Paint()
      ..color = primaryColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(fillPath, borderPaint);

    // 7. Draw Vertex Data Points & Selection Rings
    for (int i = 0; i < polyPoints.length; i++) {
      final pt = polyPoints[i];
      final isSelected = selectedDimension == dimensions[i];

      final dotPaint = Paint()
        ..color = isSelected ? AppColors.accentOrange : primaryColor
        ..style = PaintingStyle.fill;
      canvas.drawCircle(pt, isSelected ? 6.5 : 4.5, dotPaint);

      final outlinePaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawCircle(pt, isSelected ? 6.5 : 4.5, outlinePaint);

      if (isSelected) {
        final ringPaint = Paint()
          ..color = AppColors.accentOrange.withValues(alpha: 0.4)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;
        canvas.drawCircle(pt, 10.0, ringPaint);
      }
    }

    // 8. Draw Axis Labels with score values outside radar
    for (int i = 0; i < angles.length; i++) {
      final angle = angles[i];
      final dimension = dimensions[i];
      final score = scores[i];
      final isSelected = selectedDimension == dimension;

      final labelRadius = maxRadius + 20.0;
      final lx = center.dx + labelRadius * math.cos(angle);
      final ly = center.dy + labelRadius * math.sin(angle);

      final textSpan = TextSpan(
        children: [
          TextSpan(
            text: '${dimension.displayName}\n',
            style: TextStyle(
              color: isSelected
                  ? primaryColor
                  : textColor,
              fontSize: 11.5,
              fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            ),
          ),
          TextSpan(
            text: '$score%',
            style: TextStyle(
              color: isSelected
                  ? AppColors.accentOrange
                  : _getScoreColor(score),
              fontSize: 12.0,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      );

      final textPainter = TextPainter(
        text: textSpan,
        textAlign: i == 1
            ? TextAlign.left
            : i == 3
                ? TextAlign.right
                : TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();

      double tx = lx;
      double ty = ly;

      if (i == 0) {
        tx = lx - (textPainter.width / 2);
        ty = ly - textPainter.height - 4;
      } else if (i == 1) {
        tx = lx + 4;
        ty = ly - (textPainter.height / 2);
      } else if (i == 2) {
        tx = lx - (textPainter.width / 2);
        ty = ly + 4;
      } else if (i == 3) {
        tx = lx - textPainter.width - 4;
        ty = ly - (textPainter.height / 2);
      }

      textPainter.paint(canvas, Offset(tx, ty));
    }
  }

  Color _getScoreColor(int score) {
    if (score >= 80) return AppColors.accentGreen;
    if (score >= 60) return AppColors.accentOrange;
    return AppColors.accentRed;
  }

  @override
  bool shouldRepaint(covariant _AtsRadarChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.impactVerbsScore != impactVerbsScore ||
        oldDelegate.formattingScore != formattingScore ||
        oldDelegate.contactCompletenessScore != contactCompletenessScore ||
        oldDelegate.keywordDensityScore != keywordDensityScore ||
        oldDelegate.selectedDimension != selectedDimension ||
        oldDelegate.isDark != isDark;
  }
}
