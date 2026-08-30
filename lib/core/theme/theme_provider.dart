import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app_colors.dart';

/// Notifier that manages the runtime application [ThemeMode].
class ThemeModeNotifier extends StateNotifier<ThemeMode> {
  ThemeModeNotifier() : super(ThemeMode.system) {
    _updateColors(ThemeMode.system);
  }

  /// Sets the application [ThemeMode] and updates design token brightness flags.
  void setThemeMode(ThemeMode mode) {
    state = mode;
    _updateColors(mode);
  }

  /// Updates the dynamic dark mode flag in [AppColors] based on the selected mode.
  void _updateColors(ThemeMode mode) {
    if (mode == ThemeMode.dark) {
      AppColors.isDarkMode = true;
    } else if (mode == ThemeMode.light) {
      AppColors.isDarkMode = false;
    } else {
      // Fallback to system brightness
      final brightness = SchedulerBinding.instance.platformDispatcher.platformBrightness;
      AppColors.isDarkMode = brightness == Brightness.dark;
    }
  }

  /// Updates the flag if system brightness changes while in system theme mode.
  void updateSystemBrightness(Brightness brightness) {
    if (state == ThemeMode.system) {
      AppColors.isDarkMode = brightness == Brightness.dark;
    }
  }
}

/// Provider exposing the active [ThemeMode] and its modifier methods.
final themeModeProvider = StateNotifierProvider<ThemeModeNotifier, ThemeMode>((ref) {
  return ThemeModeNotifier();
});
