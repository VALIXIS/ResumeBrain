import 'package:flutter/material.dart';
import '../../../../core/theme/app_colors.dart';

/// Accessibility helper for Analysis UI providing WCAG AAA compliant color combinations,
/// 48x48 dp touch target enforcement, and semantic formatting.
class AnalysisA11y {
  AnalysisA11y._();

  /// Minimum touch target size required by WCAG 2.1 / Material 3 accessibility guidelines (48x48 dp).
  static const double minTouchTargetSize = 48.0;
  static const BoxConstraints minTouchTargetConstraints = BoxConstraints(
    minWidth: minTouchTargetSize,
    minHeight: minTouchTargetSize,
  );

  /// Determine if dark mode is active in the given [BuildContext].
  static bool isDark(BuildContext context) {
    return Theme.of(context).brightness == Brightness.dark || AppColors.isDarkMode;
  }

  // ==========================================
  // WCAG AAA CONTRAST COLOR PALETTE (>= 7.0:1)
  // ==========================================

  /// AAA Compliant Primary / Indigo Text & Icon Color
  static Color primaryText(BuildContext context) {
    return isDark(context) ? const Color(0xFFC7D2FE) : const Color(0xFF3730A3);
  }

  /// AAA Compliant Primary / Indigo Background Tint
  static Color primaryBg(BuildContext context) {
    return isDark(context)
        ? const Color(0xFF312E81).withValues(alpha: 0.5)
        : const Color(0xFFEEF2FF);
  }

  /// AAA Compliant Primary / Indigo Border
  static Color primaryBorder(BuildContext context) {
    return isDark(context) ? const Color(0xFF6366F1) : const Color(0xFF818CF8);
  }

  /// AAA Compliant Success Green Text & Icon Color (Contrast >= 7.0:1)
  static Color successText(BuildContext context) {
    return isDark(context) ? const Color(0xFF6EE7B7) : const Color(0xFF065F46);
  }

  /// AAA Compliant Success Green Background
  static Color successBg(BuildContext context) {
    return isDark(context)
        ? const Color(0xFF064E3B).withValues(alpha: 0.45)
        : const Color(0xFFECFDF5);
  }

  /// AAA Compliant Success Green Border
  static Color successBorder(BuildContext context) {
    return isDark(context) ? const Color(0xFF10B981) : const Color(0xFF34D399);
  }

  /// AAA Compliant Warning Amber/Orange Text & Icon Color (Contrast >= 7.0:1)
  static Color warningText(BuildContext context) {
    return isDark(context) ? const Color(0xFFFDE68A) : const Color(0xFF78350F);
  }

  /// AAA Compliant Warning Amber Background
  static Color warningBg(BuildContext context) {
    return isDark(context)
        ? const Color(0xFF78350F).withValues(alpha: 0.45)
        : const Color(0xFFFEF3C7);
  }

  /// AAA Compliant Warning Amber Border
  static Color warningBorder(BuildContext context) {
    return isDark(context) ? const Color(0xFFF59E0B) : const Color(0xFFFBBF24);
  }

  /// AAA Compliant Error Red Text & Icon Color (Contrast >= 7.0:1)
  static Color errorText(BuildContext context) {
    return isDark(context) ? const Color(0xFFFECACA) : const Color(0xFF991B1B);
  }

  /// AAA Compliant Error Red Background
  static Color errorBg(BuildContext context) {
    return isDark(context)
        ? const Color(0xFF7F1D1D).withValues(alpha: 0.45)
        : const Color(0xFFFEE2E2);
  }

  /// AAA Compliant Error Red Border
  static Color errorBorder(BuildContext context) {
    return isDark(context) ? const Color(0xFFEF4444) : const Color(0xFFF87171);
  }

  /// AAA Compliant Purple Text & Icon Color (Contrast >= 7.0:1)
  static Color purpleText(BuildContext context) {
    return isDark(context) ? const Color(0xFFDDD6FE) : const Color(0xFF5B21B6);
  }

  /// AAA Compliant Purple Background
  static Color purpleBg(BuildContext context) {
    return isDark(context)
        ? const Color(0xFF4C1D95).withValues(alpha: 0.45)
        : const Color(0xFFF5F3FF);
  }

  /// AAA Compliant Purple Border
  static Color purpleBorder(BuildContext context) {
    return isDark(context) ? const Color(0xFF8B5CF6) : const Color(0xFFA78BFA);
  }

  /// AAA Compliant High-Contrast Secondary Text
  static Color textSecondary(BuildContext context) {
    return isDark(context) ? const Color(0xFFCBD5E1) : const Color(0xFF334155);
  }

  /// AAA Compliant Muted / Caption Text
  static Color textMuted(BuildContext context) {
    return isDark(context) ? const Color(0xFF94A3B8) : const Color(0xFF475569);
  }

  // ==========================================
  // SCORE STATUS RESOLVER
  // ==========================================

  /// Get AAA status colors and labels for a numeric score
  static ({
    Color textColor,
    Color bgColor,
    Color borderColor,
    IconData icon,
    String statusLabel,
    String gradeLabel,
  }) getScoreStatus(BuildContext context, int score) {
    final String grade;
    if (score >= 90) {
      grade = 'A+';
    } else if (score >= 80) {
      grade = 'A';
    } else if (score >= 70) {
      grade = 'B';
    } else if (score >= 60) {
      grade = 'C';
    } else {
      grade = 'Needs Work';
    }

    if (score >= 80) {
      return (
        textColor: successText(context),
        bgColor: successBg(context),
        borderColor: successBorder(context),
        icon: Icons.check_circle_outline_rounded,
        statusLabel: 'Strong / ATS Ready',
        gradeLabel: grade,
      );
    } else if (score >= 60) {
      return (
        textColor: warningText(context),
        bgColor: warningBg(context),
        borderColor: warningBorder(context),
        icon: Icons.info_outline_rounded,
        statusLabel: 'Moderate Compliance',
        gradeLabel: grade,
      );
    } else {
      return (
        textColor: errorText(context),
        bgColor: errorBg(context),
        borderColor: errorBorder(context),
        icon: Icons.warning_amber_rounded,
        statusLabel: 'Needs Improvement',
        gradeLabel: grade,
      );
    }
  }
}
