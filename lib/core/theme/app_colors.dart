import 'package:flutter/material.dart';

/// A custom [Color] that dynamically resolves its value at runtime
/// using a resolver function, while remaining constructible as a compile-time const.
class DynamicColor extends Color {
  final Color Function() resolver;

  const DynamicColor(super.defaultValue, this.resolver);

  @override
  // ignore: deprecated_member_use
  int get value => resolver().value;

  // Overrides for Flutter 3.22+ double-based color channels
  @override
  double get r => resolver().r;

  @override
  double get g => resolver().g;

  @override
  double get b => resolver().b;

  @override
  double get a => resolver().a;

  // Overrides for legacy/deprecated integer-based color channels
  @override
  // ignore: deprecated_member_use
  int get alpha => resolver().alpha;

  @override
  // ignore: deprecated_member_use
  int get red => resolver().red;

  @override
  // ignore: deprecated_member_use
  int get green => resolver().green;

  @override
  // ignore: deprecated_member_use
  int get blue => resolver().blue;
}

class AppColors {
  /// Global state flag indicating whether dark mode is currently active.
  /// Modified by the theme provider during runtime changes.
  static bool isDarkMode = true;

  // Explicit theme color constants
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Colors.white;
  static const Color lightSurfaceLight = Color(0xFFF1F5F9);
  static const Color lightSurfaceBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF475569);
  static const Color lightTextMuted = Color(0xFF64748B);

  static const Color darkBackground = Color(0xFF0A0E1A);
  static const Color darkSurface = Color(0xFF13192B);
  static const Color darkSurfaceLight = Color(0xFF1E293B);
  static const Color darkSurfaceBorder = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextMuted = Color(0xFF64748B);

  // Static resolver functions
  static Color _backgroundResolver() => isDarkMode ? darkBackground : lightBackground;
  static Color _surfaceResolver() => isDarkMode ? darkSurface : lightSurface;
  static Color _surfaceLightResolver() => isDarkMode ? darkSurfaceLight : lightSurfaceLight;
  static Color _surfaceBorderResolver() => isDarkMode ? darkSurfaceBorder : lightSurfaceBorder;
  
  static Color _textPrimaryResolver() => isDarkMode ? darkTextPrimary : lightTextPrimary;
  static Color _textSecondaryResolver() => isDarkMode ? darkTextSecondary : lightTextSecondary;
  static Color _textMutedResolver() => isDarkMode ? darkTextMuted : lightTextMuted;
  static Color _textDisabledResolver() => isDarkMode ? darkTextSecondary : lightTextSecondary;

  // Dynamic colors defined as const using DynamicColor
  static const Color background = DynamicColor(0xFF0A0E1A, _backgroundResolver);
  static const Color surface = DynamicColor(0xFF13192B, _surfaceResolver);
  static const Color surfaceLight = DynamicColor(0xFF1E293B, _surfaceLightResolver);
  static const Color surfaceBorder = DynamicColor(0xFF334155, _surfaceBorderResolver);

  // Primary & Secondary Brand Colors (Constant across themes)
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color secondary = Color(0xFF3B82F6); // Blue
  static const Color accentPurple = Color(0xFF8B5CF6);

  // Status & Accent Highlights (Constant across themes)
  static const Color accentGreen = Color(0xFF10B981); // Success / ATS Pass
  static const Color accentOrange = Color(0xFFF59E0B); // Warning / Moderate
  static const Color accentRed = Color(0xFFEF4444); // Error / Action Needed
  static const Color accentTeal = Color(0xFF14B8A6);

  // Dynamic Text Colors
  static const Color textPrimary = DynamicColor(0xFFF8FAFC, _textPrimaryResolver);
  static const Color textSecondary = DynamicColor(0xFF94A3B8, _textSecondaryResolver);
  static const Color textMuted = DynamicColor(0xFF64748B, _textMutedResolver);
  static const Color textDisabled = DynamicColor(0xFF475569, _textDisabledResolver);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [Color(0xFF6366F1), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static const LinearGradient aiGradient = LinearGradient(
    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1), Color(0xFF3B82F6)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get cardGradient => LinearGradient(
    colors: const [surface, surfaceLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
