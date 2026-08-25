import 'package:flutter/material.dart';

class AppColors {
  // Dark Premium Theme Palette
  static const Color background = Color(0xFF0A0E1A);
  static const Color surface = Color(0xFF13192B);
  static const Color surfaceLight = Color(0xFF1E293B);
  static const Color surfaceBorder = Color(0xFF334155);

  // Primary & Secondary Brand Colors
  static const Color primary = Color(0xFF6366F1); // Indigo
  static const Color primaryDark = Color(0xFF4F46E5);
  static const Color secondary = Color(0xFF3B82F6); // Blue
  static const Color accentPurple = Color(0xFF8B5CF6);

  // Status & Accent Highlights
  static const Color accentGreen = Color(0xFF10B981); // Success / ATS Pass
  static const Color accentOrange = Color(0xFFF59E0B); // Warning / Moderate
  static const Color accentRed = Color(0xFFEF4444); // Error / Action Needed
  static const Color accentTeal = Color(0xFF14B8A6);

  // Text Colors
  static const Color textPrimary = Color(0xFFF8FAFC);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textMuted = Color(0xFF64748B);
  static const Color textDisabled = Color(0xFF475569);

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

  static const LinearGradient cardGradient = LinearGradient(
    colors: [Color(0xFF13192B), Color(0xFF1E293B)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
