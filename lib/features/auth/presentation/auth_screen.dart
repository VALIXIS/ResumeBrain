import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_text_field.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _fullNameController = TextEditingController();

  bool _isSignUp = false;
  bool _isLoading = false;

  Future<void> _submitAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final fullName = _fullNameController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      AppSnackBar.showError(context, 'Please enter email and password.');
      return;
    }

    if (password.length < 6) {
      AppSnackBar.showError(context, 'Password must be at least 6 characters long.');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final client = Supabase.instance.client;
      if (_isSignUp) {
        final res = await client.auth.signUp(
          email: email,
          password: password,
          data: {'full_name': fullName},
        );
        if (mounted) {
          if (res.user != null) {
            AppSnackBar.showSuccess(context, 'Account created! Please check your email to verify.');
            Navigator.pop(context);
          }
        }
      } else {
        final res = await client.auth.signInWithPassword(
          email: email,
          password: password,
        );
        if (mounted) {
          if (res.user != null) {
            AppSnackBar.showSuccess(context, 'Welcome back, ${res.user!.email}!');
            Navigator.pop(context);
          }
        }
      }
    } catch (e) {
      if (mounted) {
        AppSnackBar.showError(context, 'Authentication failed: $e');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _fullNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isSignUp ? 'Create Resume Brain Account' : 'Sign In to Resume Brain'),
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.screenPadding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.cloud_sync_rounded, size: 48, color: Colors.white),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Text(
                _isSignUp ? 'Cloud Backup & Multi-Device Sync' : 'Welcome Back to Resume Brain',
                style: AppTypography.titleLarge,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: Text(
                _isSignUp
                    ? 'Create your free account to enable AES-256 encrypted cloud backup.'
                    : 'Sign in to access your backed-up resumes across devices.',
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            if (_isSignUp) ...[
              AppTextField(
                controller: _fullNameController,
                label: 'Full Name',
                hint: 'John Doe',
              ),
              const SizedBox(height: AppSpacing.md),
            ],
            AppTextField(
              controller: _emailController,
              label: 'Email Address',
              hint: 'john.doe@example.com',
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: AppSpacing.md),
            AppTextField(
              controller: _passwordController,
              label: 'Password',
              hint: '••••••••',
            ),
            const SizedBox(height: AppSpacing.xl),
            AppButton(
              text: _isLoading
                  ? 'Processing...'
                  : (_isSignUp ? 'Create Account & Enable Sync' : 'Sign In'),
              isLoading: _isLoading,
              isFullWidth: true,
              onPressed: _submitAuth,
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: TextButton(
                onPressed: () {
                  setState(() => _isSignUp = !_isSignUp);
                },
                child: Text(
                  _isSignUp
                      ? 'Already have an account? Sign In'
                      : 'Don\'t have an account? Create One',
                  style: AppTypography.bodyMedium.copyWith(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
