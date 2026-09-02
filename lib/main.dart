import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/providers.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/home/presentation/home_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive repository before launching app UI with safety fallback
  final container = ProviderContainer();
  try {
    final repo = container.read(resumeRepositoryProvider);
    await repo.init();
  } catch (e, stack) {
    debugPrint('Failed to initialize ResumeRepository during startup: $e\n$stack');
  }

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ResumeBrainApp(),
    ),
  );
}

class ResumeBrainApp extends ConsumerWidget {
  const ResumeBrainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    // Synchronize AppColors.isDarkMode with platform brightness safely without ancestor MediaQuery requirement
    if (themeMode == ThemeMode.system) {
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      AppColors.isDarkMode = brightness == Brightness.dark;
    }

    return MaterialApp(
      title: 'Resume Brain',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: const HomeDashboardScreen(),
    );
  }
}
