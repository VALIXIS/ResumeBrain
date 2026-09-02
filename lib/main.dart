import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/storage/storage_bootstrap.dart';
import 'core/theme/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_provider.dart';
import 'features/home/presentation/home_dashboard_screen.dart';

bool _firstFrameRendered = false;

void main() {
  // DIAGNOSTIC BOUNDARY 1: MAIN_ENTER
  StartupStages.logStage('MAIN_ENTER', 'main() entrypoint executed');

  // DIAGNOSTIC BOUNDARY 2: BINDING_READY
  WidgetsFlutterBinding.ensureInitialized();
  StartupStages.logStage('BINDING_READY', 'WidgetsFlutterBinding initialized');

  // Production-safe global exception logging
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    StartupStages.logStage('FLUTTER_ERROR', '${details.exception}\n${details.stack}');
  };

  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    StartupStages.logStage('PLATFORM_ERROR', '$error\n$stack');
    return true; // Prevents process termination
  };

  GoogleFonts.config.allowRuntimeFetching = true;

  // FIRST FRAME WATCHDOG (5 Seconds)
  Timer(const Duration(seconds: 5), () {
    if (!_firstFrameRendered) {
      StartupStages.logStage(
        'FIRST_FRAME_TIMEOUT',
        'CRITICAL ALERT: Flutter has not rendered the first frame within 5000ms. Storage status: ${StorageBootstrapService().status}',
      );
    }
  });

  // DIAGNOSTIC BOUNDARY 3: RUN_APP_CALLED
  StartupStages.logStage('RUN_APP_CALLED', 'Calling runApp with ProviderScope');
  runApp(
    const ProviderScope(
      child: ResumeBrainApp(),
    ),
  );
}

class ResumeBrainApp extends ConsumerStatefulWidget {
  const ResumeBrainApp({super.key});

  @override
  ConsumerState<ResumeBrainApp> createState() => _ResumeBrainAppState();
}

class _ResumeBrainAppState extends ConsumerState<ResumeBrainApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);

    // Register first frame callback
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _firstFrameRendered = true;
      StartupStages.logStage('FIRST_FRAME', 'First Flutter frame rendered successfully');
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        StartupStages.logStage('APP_RESUMED', 'Android Activity resumed into foreground');
        break;
      case AppLifecycleState.paused:
        StartupStages.logStage('APP_PAUSED', 'Android Activity paused into background');
        break;
      case AppLifecycleState.inactive:
        StartupStages.logStage('APP_INACTIVE', 'Android Activity inactive state');
        break;
      case AppLifecycleState.detached:
        StartupStages.logStage('APP_DETACHED', 'Android Activity detached state');
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    // DIAGNOSTIC BOUNDARY 4: APP_BUILD_ENTER
    StartupStages.logStage('APP_BUILD_ENTER', 'Building ResumeBrainApp root widget');
    final themeMode = ref.watch(themeModeProvider);

    if (themeMode == ThemeMode.system) {
      final brightness = WidgetsBinding.instance.platformDispatcher.platformBrightness;
      AppColors.isDarkMode = brightness == Brightness.dark;
    }

    // DIAGNOSTIC BOUNDARY 5: MATERIAL_APP_CREATED
    StartupStages.logStage('MATERIAL_APP_CREATED', 'Creating MaterialApp instance');

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
