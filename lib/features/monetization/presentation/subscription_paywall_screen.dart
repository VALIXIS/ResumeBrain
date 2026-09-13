import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_radius.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/app_snackbar.dart';
import '../../../core/widgets/custom_button.dart';
import '../../../core/widgets/custom_card.dart';

class SubscriptionPaywallScreen extends StatefulWidget {
  const SubscriptionPaywallScreen({super.key});

  @override
  State<SubscriptionPaywallScreen> createState() => _SubscriptionPaywallScreenState();
}

class _SubscriptionPaywallScreenState extends State<SubscriptionPaywallScreen> {
  int _selectedPlanIndex = 0; // 0 = Yearly (Best Value), 1 = Monthly

  final List<Map<String, String>> _plans = [
    {
      'title': 'Annual Pro Pass',
      'price': '\$59.99 / year',
      'subtitle': '\$4.99/mo (Save 50%)',
      'badge': 'BEST VALUE',
    },
    {
      'title': 'Monthly Pro Pass',
      'price': '\$9.99 / month',
      'subtitle': 'Cancel anytime',
      'badge': 'FLEXIBLE',
    },
  ];

  void _upgradeToPro() {
    AppSnackBar.showSuccess(context, 'Subscribed to ${_plans[_selectedPlanIndex]['title']}! Pro features unlocked.');
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Upgrade to Resume Brain PRO'),
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
                  gradient: AppColors.aiGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star_rounded, size: 48, color: Colors.white),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            Center(
              child: Text(
                'Unlock Unlimited Career AI Power',
                style: AppTypography.displayMedium,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Center(
              child: Text(
                'Accelerate your job search with unlimited ATS scoring, AI rewrites, and PDF template customizer.',
                style: AppTypography.bodySmall,
                textAlign: TextAlign.center,
              ),
            ),
            const SizedBox(height: AppSpacing.xl),
            Text('Pro Tier Features', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.md),
            _buildFeatureRow('Unlimited AI Resume Analysis & ATS Scoring', Icons.auto_awesome),
            _buildFeatureRow('1-Click Job Tailoring & Experience Rewrites', Icons.work_history),
            _buildFeatureRow('AES-256 Multi-Device Cloud Backup', Icons.cloud_sync),
            _buildFeatureRow('All 5 Premium PDF Design Templates', Icons.style),
            _buildFeatureRow('Custom Typography & Color Palette Customizer', Icons.palette),
            _buildFeatureRow('Password-Protected Encrypted PDF Export', Icons.lock),
            const SizedBox(height: AppSpacing.xl),
            Text('Select Subscription Plan', style: AppTypography.titleMedium),
            const SizedBox(height: AppSpacing.md),
            ...List.generate(_plans.length, (index) {
              final plan = _plans[index];
              final isSelected = _selectedPlanIndex == index;

              return Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: AppCard(
                  color: isSelected ? AppColors.primary.withValues(alpha: 0.12) : AppColors.surface,
                  onTap: () => setState(() => _selectedPlanIndex = index),
                  child: Row(
                    children: [
                      // ignore: deprecated_member_use
                      Radio<int>(
                        value: index,
                        // ignore: deprecated_member_use
                        groupValue: _selectedPlanIndex,
                        activeColor: AppColors.primary,
                        // ignore: deprecated_member_use
                        onChanged: (val) {
                          if (val != null) setState(() => _selectedPlanIndex = val);
                        },
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(plan['title']!, style: AppTypography.titleMedium),
                                const Spacer(),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: isSelected ? AppColors.primary : AppColors.surfaceBorder,
                                    borderRadius: AppRadius.borderSm,
                                  ),
                                  child: Text(
                                    plan['badge']!,
                                    style: AppTypography.labelSmall.copyWith(
                                      color: isSelected ? Colors.white : AppColors.textMuted,
                                      fontSize: 9,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(plan['price']!, style: AppTypography.titleMedium.copyWith(color: AppColors.primary)),
                            Text(plan['subtitle']!, style: AppTypography.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            const SizedBox(height: AppSpacing.lg),
            AppButton(
              text: 'Start 7-Day Free Trial & Upgrade',
              isFullWidth: true,
              onPressed: _upgradeToPro,
            ),
            const SizedBox(height: AppSpacing.md),
            Center(
              child: Text(
                'Cancel anytime. Terms of Service & Privacy Policy apply.',
                style: AppTypography.labelSmall.copyWith(color: AppColors.textMuted),
              ),
            ),
            const SizedBox(height: AppSpacing.xxl),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureRow(String text, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: AppColors.accentTeal.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 16, color: AppColors.accentTeal),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(text, style: AppTypography.bodyMedium),
          ),
        ],
      ),
    );
  }
}
