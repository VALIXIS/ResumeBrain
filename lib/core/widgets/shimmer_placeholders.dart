import 'package:flutter/material.dart';
import '../theme/app_radius.dart';
import '../theme/app_spacing.dart';
import 'app_shimmer.dart';
import 'custom_card.dart';

/// Pre-configured shimmer placeholder representing a dashboard statistic card.
class StatCardShimmer extends StatelessWidget {
  const StatCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading statistics card',
      child: const AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            AppShimmer(width: 80, height: 14),
            SizedBox(height: AppSpacing.sm),
            AppShimmer(width: 50, height: 28),
            SizedBox(height: AppSpacing.xs),
            AppShimmer(width: 110, height: 10),
          ],
        ),
      ),
    );
  }
}

/// Pre-configured shimmer placeholder representing a list item row.
class ListRowShimmer extends StatelessWidget {
  const ListRowShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading list item',
      child: const AppCard(
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AppShimmer(width: 160, height: 16),
                  SizedBox(height: AppSpacing.xs),
                  AppShimmer(width: 220, height: 12),
                ],
              ),
            ),
            SizedBox(width: AppSpacing.md),
            AppShimmer(width: 24, height: 24, borderRadius: AppRadius.borderSm),
          ],
        ),
      ),
    );
  }
}

/// Pre-configured shimmer placeholder representing a major dashboard feature card.
class DashboardCardShimmer extends StatelessWidget {
  const DashboardCardShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading feature card',
      child: const AppCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                AppShimmer(width: 20, height: 20, borderRadius: AppRadius.borderSm),
                SizedBox(width: AppSpacing.xs),
                AppShimmer(width: 140, height: 12),
              ],
            ),
            SizedBox(height: AppSpacing.sm),
            AppShimmer(width: double.infinity, height: 20),
            SizedBox(height: AppSpacing.xs),
            AppShimmer(width: 240, height: 14),
            SizedBox(height: AppSpacing.md),
            AppShimmer(width: 120, height: 36),
          ],
        ),
      ),
    );
  }
}

/// Pre-configured shimmer placeholder representing blocks of textual content.
class TextBlockShimmer extends StatelessWidget {
  final int lines;

  const TextBlockShimmer({
    super.key,
    this.lines = 3,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Loading text content',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(lines, (index) {
          final isLast = index == lines - 1;
          return Padding(
            padding: EdgeInsets.only(bottom: isLast ? 0.0 : AppSpacing.xs),
            child: AppShimmer(
              width: isLast ? 160 : double.infinity,
              height: 14,
            ),
          );
        }),
      ),
    );
  }
}
