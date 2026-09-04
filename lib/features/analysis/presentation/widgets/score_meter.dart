import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_typography.dart';
import 'analysis_accessibility_helper.dart';

/// Circular animated score meter displaying overall ATS Score (0 to 100).
/// Uses CustomPainter for smooth rendering with comprehensive accessibility semantics,
/// WCAG AAA contrast compliance, and color-independent status indicators.
class CircularScoreMeter extends StatelessWidget {
  final int? score; // 0 to 100 or null
  final double size;

  const CircularScoreMeter({
    super.key,
    required this.score,
    this.size = 180,
  });

  Color _getScoreColor(double score) {
    if (score >= 80) return AppColors.accentGreen;
    if (score >= 60) return AppColors.accentOrange;
    return AppColors.accentRed;
  }

  String _getScoreLabel(double score) {
    if (score >= 85) return 'Excellent';
    if (score >= 70) return 'ATS Ready';
    if (score >= 50) return 'Moderate';
    return 'Needs Work';
  }

  @override
  Widget build(BuildContext context) {
    if (score == null) {
      return Semantics(
        label: 'Overall resume ATS score: No analysis score available. Please run analysis to evaluate.',
        child: SizedBox(
          width: size,
          height: size,
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(
                  Icons.analytics_outlined,
                  size: 40,
                  color: AppColors.textMuted,
                ),
                const SizedBox(height: 8),
                Text(
                  'No Score',
                  style: AppTypography.titleMedium.copyWith(
                    color: AppColors.textMuted,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final validScore = score!.clamp(0, 100).toDouble();
    final scoreInt = validScore.toInt();
    final arcColor = _getScoreColor(validScore);
    final scoreLabel = _getScoreLabel(validScore);
    final status = AnalysisA11y.getScoreStatus(context, scoreInt);

    return Semantics(
      label: 'Overall resume ATS score: $scoreInt out of 100, rated $scoreLabel (${status.statusLabel})',
      value: '$scoreInt',
      child: TweenAnimationBuilder<double>(
        tween: Tween<double>(begin: 0.0, end: validScore),
        duration: const Duration(milliseconds: 1200),
        curve: Curves.easeOutCubic,
        builder: (context, animatedScore, child) {
          final currentScore = animatedScore.toInt();
          return SizedBox(
            width: size,
            height: size,
            child: Stack(
              alignment: Alignment.center,
              children: [
                // Custom painted circular progress arc
                CustomPaint(
                  size: Size(size, size),
                  painter: _ScoreMeterPainter(
                    score: animatedScore,
                    scoreColor: arcColor,
                  ),
                ),
                // Center content with high-contrast text and non-color icon
                Padding(
                  padding: EdgeInsets.all(size * 0.12),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        currentScore.toString(),
                        style: AppTypography.displayLarge.copyWith(
                          fontSize: (size * 0.26).clamp(24.0, 52.0),
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimary,
                          height: 1.0,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'OUT OF 100',
                        style: AppTypography.labelSmall.copyWith(
                          color: AnalysisA11y.textSecondary(context),
                          fontSize: (size * 0.065).clamp(10.0, 13.0),
                          letterSpacing: 1.0,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: status.bgColor,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: status.borderColor,
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              status.icon,
                              size: 12,
                              color: status.textColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              scoreLabel,
                              style: AppTypography.labelSmall.copyWith(
                                color: status.textColor,
                                fontWeight: FontWeight.w800,
                                fontSize: (size * 0.065).clamp(10.0, 13.0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ScoreMeterPainter extends CustomPainter {
  final double score;
  final Color scoreColor;

  _ScoreMeterPainter({
    required this.score,
    required this.scoreColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final strokeWidth = size.width * 0.085;
    final radius = (size.width - strokeWidth) / 2;

    const startAngle = -math.pi / 2;
    final sweepAngle = 2 * math.pi * (score / 100);

    // Background track
    final trackPaint = Paint()
      ..color = AppColors.surfaceBorder.withValues(alpha: 0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    canvas.drawCircle(center, radius, trackPaint);

    // Foreground progress arc
    if (score > 0) {
      final progressPaint = Paint()
        ..shader = SweepGradient(
          startAngle: 0.0,
          endAngle: math.pi * 2,
          colors: [
            scoreColor.withValues(alpha: 0.7),
            scoreColor,
          ],
        ).createShader(Rect.fromCircle(center: center, radius: radius))
        ..style = PaintingStyle.stroke
        ..strokeWidth = strokeWidth
        ..strokeCap = StrokeCap.round;

      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        startAngle,
        sweepAngle,
        false,
        progressPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _ScoreMeterPainter oldDelegate) {
    return oldDelegate.score != score || oldDelegate.scoreColor != scoreColor;
  }
}
