import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/storage/storage_bootstrap.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/home/presentation/home_dashboard_screen.dart';

void main() {
  // STARTUP STAGE 1: Bindings
  StartupStages.logStage(StartupStages.stage1Binding, 'WidgetsFlutterBinding.ensureInitialized()');
  WidgetsFlutterBinding.ensureInitialized();

  // Production-safe global exception logging
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    StartupStages.logStage('FLUTTER_ERROR', '${details.exception}\n${details.stack}');
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    StartupStages.logStage('PLATFORM_ERROR', '$error\n$stack');
    return true; // Prevents app process termination
  };

  // GoogleFonts configuration
  GoogleFonts.config.allowRuntimeFetching = true;

  // STARTUP STAGE 2: Immediate, non-blocking runApp() using standard ProviderScope
  StartupStages.logStage(StartupStages.stage2RunApp, 'Invoking runApp with standard ProviderScope');
  runApp(
    const ProviderScope(
      child: ResumeBrainApp(),
    ),
  );
}

class ResumeBrainApp extends ConsumerWidget {
  const ResumeBrainApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);

    // Synchronize AppColors.isDarkMode with platform brightness safely
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
