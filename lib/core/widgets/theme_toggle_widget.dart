import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../theme/theme_provider.dart';

/// An interactive theme toggle widget that allows the user to switch
/// between light, dark, and system default themes.
class ThemeToggleWidget extends ConsumerWidget {
  const ThemeToggleWidget({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    IconData getThemeIcon() {
      switch (themeMode) {
        case ThemeMode.light:
          return Icons.light_mode_rounded;
        case ThemeMode.dark:
          return Icons.dark_mode_rounded;
        case ThemeMode.system:
          return Icons.brightness_auto_rounded;
      }
    }

    String getThemeLabel() {
      switch (themeMode) {
        case ThemeMode.light:
          return 'Light';
        case ThemeMode.dark:
          return 'Dark';
        case ThemeMode.system:
          return 'System';
      }
    }

    return PopupMenuButton<ThemeMode>(
      tooltip: 'Change Theme (Current: ${getThemeLabel()})',
      icon: Icon(getThemeIcon()),
      onSelected: (mode) {
        ref.read(themeModeProvider.notifier).setThemeMode(mode);
      },
      itemBuilder: (context) => [
        const PopupMenuItem(
          value: ThemeMode.light,
          child: Row(
            children: [
              Icon(Icons.light_mode_rounded),
              SizedBox(width: 8),
              Text('Light Mode'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: ThemeMode.dark,
          child: Row(
            children: [
              Icon(Icons.dark_mode_rounded),
              SizedBox(width: 8),
              Text('Dark Mode'),
            ],
          ),
        ),
        const PopupMenuItem(
          value: ThemeMode.system,
          child: Row(
            children: [
              Icon(Icons.brightness_auto_rounded),
              SizedBox(width: 8),
              Text('System Default'),
            ],
          ),
        ),
      ],
    );
  }
}
