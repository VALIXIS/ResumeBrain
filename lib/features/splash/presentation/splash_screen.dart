import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../app/providers.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/smooth_page_route.dart';
import '../../home/presentation/home_dashboard_screen.dart';
import '../../onboarding/presentation/onboarding_screen.dart';

import '../../../core/storage/storage_bootstrap.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();

    _bootstrapApp();
  }

  Future<void> _bootstrapApp() async {
    // 1. Await storage initialization first to prevent race condition
    await StorageBootstrapService().initializeStorage();

    // Small delay to ensure splash animation plays smoothly
    await Future.delayed(const Duration(milliseconds: 1000));

    if (!mounted) return;

    try {
      final storage = StorageBootstrapService();
      bool onboardingDone = storage.isOnboardingCompleted;

      if (!onboardingDone) {
        try {
          final prefs = await SharedPreferences.getInstance();
          onboardingDone = prefs.getBool('onboarding_completed') ?? false;
        } catch (_) {}
      }

      final repo = ref.read(resumeRepositoryProvider);
      final resumes = await repo.getAllResumes();

      if (!mounted) return;

      if (onboardingDone || resumes.isNotEmpty) {
        // Mark onboarding completed persistently if resumes exist
        if (!onboardingDone) {
          await storage.setOnboardingCompleted(true);
        }
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          SmoothPageRoute(page: const HomeDashboardScreen()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          SmoothPageRoute(page: const OnboardingScreen()),
        );
      }
    } catch (_) {
      if (!mounted) return;
      Navigator.pushReplacement(
        context,
        SmoothPageRoute(page: const HomeDashboardScreen()),
      );
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      blurRadius: 24,
                      spreadRadius: 4,
                    ),
                  ],
                ),
                child: const Icon(Icons.psychology_rounded, size: 64, color: Colors.white),
              ),
              const SizedBox(height: AppSpacing.xl),
              Text(
                AppConstants.appName,
                style: AppTypography.displayMedium,
              ),
              const SizedBox(height: AppSpacing.xs),
              Text(
                'AI-POWERED RESUME BUILDER',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.primary,
                  letterSpacing: 2.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: AppSpacing.xxl),
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
