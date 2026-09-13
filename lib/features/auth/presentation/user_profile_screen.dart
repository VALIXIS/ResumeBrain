import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../app/providers.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';
import '../../../core/widgets/smooth_page_route.dart';
import 'auth_screen.dart';

class UserProfileScreen extends ConsumerStatefulWidget {
  const UserProfileScreen({super.key});

  @override
  ConsumerState<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends ConsumerState<UserProfileScreen> {
  bool _isSyncing = false;

  User? get _currentUser {
    try {
      return Supabase.instance.client.auth.currentUser;
    } catch (_) {
      return null;
    }
  }

  Future<void> _triggerCloudSync() async {
    final adapter = ref.read(cloudSyncAdapterProvider);
    final localResumesAsync = ref.read(resumesListProvider);

    final localResumes = localResumesAsync.value ?? [];

    setState(() => _isSyncing = true);

    try {
      final result = await adapter.syncAll(localResumes);
      if (mounted) {
        if (result.isSuccess) {
          AppSnackBar.showSuccess(context, result.message);
          ref.read(resumesListProvider.notifier).loadResumes();
        } else {
          AppSnackBar.showError(context, result.message);
        }
      }
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, 'Sync error: $e');
    } finally {
      if (mounted) setState(() => _isSyncing = false);
    }
  }

  Future<void> _signOut() async {
    try {
      await Supabase.instance.client.auth.signOut();
      if (mounted) {
        AppSnackBar.showSuccess(context, 'Signed out successfully.');
        setState(() {});
      }
    } catch (e) {
      if (mounted) AppSnackBar.showError(context, 'Sign out error: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = _currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('User Account & Cloud Sync'),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (user == null) ...[
              AppCard(
                color: AppColors.primary.withValues(alpha: 0.1),
                child: Column(
                  children: [
                    const Icon(Icons.cloud_off_rounded, size: 48, color: AppColors.primary),
                    const SizedBox(height: AppSpacing.sm),
                    Text('Cloud Sync Inactive', style: AppTypography.titleMedium),
                    const SizedBox(height: AppSpacing.xs),
                    Text(
                      'Sign in or create an account to activate AES-256 encrypted multi-device cloud backup.',
                      style: AppTypography.bodySmall,
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      text: 'Sign In / Register Now',
                      isFullWidth: true,
                      onPressed: () {
                        Navigator.push(
                          context,
                          SmoothPageRoute(page: const AuthScreen()),
                        ).then((_) => setState(() {}));
                      },
                    ),
                  ],
                ),
              ),
            ] else ...[
              AppCard(
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: AppColors.primary.withValues(alpha: 0.2),
                      child: Text(
                        (user.email ?? 'U')[0].toUpperCase(),
                        style: AppTypography.titleLarge.copyWith(color: AppColors.primary),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.userMetadata?['full_name'] ?? 'Resume Brain User', style: AppTypography.titleMedium),
                          Text(user.email ?? '', style: AppTypography.bodySmall),
                          const SizedBox(height: 4),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.2),
                              borderRadius: AppRadius.borderSm,
                            ),
                            child: Text(
                              'AUTHENTICATED & SYNC ENABLED',
                              style: AppTypography.labelSmall.copyWith(color: Colors.green, fontSize: 9),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.lg),
              Text('Cloud Sync Actions', style: AppTypography.titleMedium),
              const SizedBox(height: AppSpacing.sm),
              AppCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.cloud_upload_outlined, color: AppColors.accentTeal),
                        const SizedBox(width: AppSpacing.sm),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Manual Cloud Backup', style: AppTypography.titleMedium),
                              Text('Synchronize all local resumes with cloud database.', style: AppTypography.bodySmall),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    AppButton(
                      text: _isSyncing ? 'Syncing Resumes...' : 'Sync All Resumes Now',
                      isLoading: _isSyncing,
                      isFullWidth: true,
                      onPressed: _triggerCloudSync,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: AppSpacing.xl),
              AppButton(
                text: 'Sign Out',
                isFullWidth: true,
                variant: AppButtonVariant.outline,
                onPressed: _signOut,
              ),
            ],
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
