import 'package:flutter/material.dart';
import '../constants/app_constants.dart';
import '../theme/app_colors.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';
import 'theme_toggle_widget.dart';

class NavDestinationItem {
  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final String tooltip;

  const NavDestinationItem({
    required this.label,
    required this.icon,
    required this.selectedIcon,
    required this.tooltip,
  });
}

/// A responsive navigation drawer/sidebar supporting active states,
/// touch accessibility, and theme adaptability.
class AppNavigationDrawer extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onDestinationSelected;
  final bool isPermanent;

  const AppNavigationDrawer({
    super.key,
    required this.selectedIndex,
    required this.onDestinationSelected,
    this.isPermanent = false,
  });

  static const List<NavDestinationItem> destinations = [
    NavDestinationItem(
      label: 'My Resumes',
      icon: Icons.description_outlined,
      selectedIcon: Icons.description_rounded,
      tooltip: 'View and manage your saved resumes',
    ),
    NavDestinationItem(
      label: 'ATS Analysis',
      icon: Icons.analytics_outlined,
      selectedIcon: Icons.analytics_rounded,
      tooltip: 'AI-powered ATS score and resume feedback',
    ),
    NavDestinationItem(
      label: 'Job Match',
      icon: Icons.work_outline_rounded,
      selectedIcon: Icons.work_rounded,
      tooltip: 'Match and tailor resume against job descriptions',
    ),
    NavDestinationItem(
      label: 'Templates',
      icon: Icons.palette_outlined,
      selectedIcon: Icons.palette_rounded,
      tooltip: 'Choose ATS-optimized resume templates',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final drawerContent = SafeArea(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: AppRadius.borderSm,
                  ),
                  child: const Icon(Icons.psychology, size: 24, color: Colors.white),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppConstants.appName,
                        style: AppTypography.titleLarge.copyWith(fontSize: 18),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'BY ${AppConstants.companyName}',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.primary,
                          letterSpacing: 1.2,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Divider(color: AppColors.surfaceBorder, height: 1),
          const SizedBox(height: AppSpacing.sm),

          // Navigation items list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              itemCount: destinations.length,
              itemBuilder: (context, index) {
                final item = destinations[index];
                final isSelected = selectedIndex == index;

                return Padding(
                  padding: const EdgeInsets.only(bottom: 4),
                  child: Semantics(
                    button: true,
                    selected: isSelected,
                    label: '${item.label}, navigation destination',
                    child: Material(
                      color: isSelected
                          ? AppColors.primary.withValues(alpha: 0.12)
                          : Colors.transparent,
                      borderRadius: AppRadius.borderMd,
                      child: InkWell(
                        onTap: () {
                          if (!isPermanent) {
                            Navigator.of(context).pop();
                          }
                          onDestinationSelected(index);
                        },
                        borderRadius: AppRadius.borderMd,
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(minHeight: 48),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: Row(
                              children: [
                                Icon(
                                  isSelected ? item.selectedIcon : item.icon,
                                  size: 22,
                                  color: isSelected
                                      ? AppColors.primary
                                      : AppColors.textSecondary,
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: Text(
                                    item.label,
                                    style: AppTypography.labelLarge.copyWith(
                                      color: isSelected
                                          ? AppColors.primary
                                          : AppColors.textPrimary,
                                      fontWeight:
                                          isSelected ? FontWeight.w600 : FontWeight.w500,
                                    ),
                                  ),
                                ),
                                if (isSelected)
                                  Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: AppColors.primary,
                                    ),
                                  ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Footer
          Divider(color: AppColors.surfaceBorder, height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Appearance',
                        style: AppTypography.bodySmall.copyWith(fontSize: 11),
                      ),
                      Text(
                        'v1.0.0 • Production',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.textMuted,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const ThemeToggleWidget(),
              ],
            ),
          ),
        ],
      ),
    );

    if (isPermanent) {
      return Container(
        width: 240,
        decoration: BoxDecoration(
          color: AppColors.surface,
          border: Border(
            right: BorderSide(color: AppColors.surfaceBorder, width: 1),
          ),
        ),
        child: drawerContent,
      );
    }

    return Drawer(
      backgroundColor: AppColors.surface,
      elevation: 16,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.horizontal(right: Radius.circular(AppRadius.lg)),
      ),
      child: drawerContent,
    );
  }
}
