import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'app/providers.dart';
import 'core/theme/app_theme.dart';
import 'features/home/presentation/home_dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive repository before launching app UI
  final container = ProviderContainer();
  final repo = container.read(resumeRepositoryProvider);
  await repo.init();

  runApp(
    UncontrolledProviderScope(
      container: container,
      child: const ResumeBrainApp(),
    ),
  );
}

class ResumeBrainApp extends StatelessWidget {
  const ResumeBrainApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Resume Brain',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      home: const HomeDashboardScreen(),
    );
  }
}
