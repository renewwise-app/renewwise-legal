import 'package:flutter/material.dart';

import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';
import 'package:renew_wise/utils/feature_purpose_messaging.dart';
import 'package:renew_wise/utils/history_events_scope.dart';
import 'package:renew_wise/widgets/common/feature_purpose_subtitle.dart';
import 'package:renew_wise/widgets/home/home_summary_card.dart';

/// Dashboard card for History — mirrors [HomeSummaryCard].
class HistorySummaryCard extends StatelessWidget {
  const HistorySummaryCard({
    super.key,
    required this.title,
    required this.summary,
    required this.theme,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final HistoryPeriodSummary summary;
  final HomeDashboardCardTheme theme;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HomePremiumSummaryCard(
      title: title,
      theme: theme,
      icon: icon,
      onTap: onTap,
      supportingText: summary.completedLabel,
      actionLabel: 'View →',
    );
  }
}

/// Choose Period entry card on the History dashboard.
class HistoryChoosePeriodCard extends StatelessWidget {
  const HistoryChoosePeriodCard({
    super.key,
    required this.onTap,
  });

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return HomePremiumSummaryCard(
      title: 'Choose Period',
      theme: HomeDashboardCardTheme.customSearch,
      icon: Icons.date_range_outlined,
      onTap: onTap,
      supportingText: 'Browse completed reminders between any two dates.',
      actionLabel: 'Search →',
    );
  }
}

/// History tab header with friendly weekly summary.
class HistoryPageHeader extends StatelessWidget {
  const HistoryPageHeader({
    super.key,
    required this.weeklyCompletedCount,
  });

  final int weeklyCompletedCount;

  @override
  Widget build(BuildContext context) {
    final summaryText = weeklyCompletedCount == 0
        ? 'No reminders completed this week yet.'
        : weeklyCompletedCount == 1
            ? 'You completed 1 reminder this week.'
            : 'You completed $weeklyCompletedCount reminders this week.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'History',
          style: RenewWiseTypography.screenTitle,
        ),
        const SizedBox(height: 8),
        const FeaturePurposeSubtitle(FeaturePurposeMessaging.history),
        const SizedBox(height: AppSpacing.section),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                RenewWisePalette.greenSoftStart,
                RenewWisePalette.greenSoftEnd,
              ],
            ),
            borderRadius: BorderRadius.circular(AppRadius.homeCard),
            boxShadow: RenewWiseShadows.homeCard(RenewWisePalette.green),
          ),
          child: Text(
            summaryText,
            style: RenewWiseTypography.secondary.copyWith(
              color: RenewWisePalette.textPrimary,
              fontWeight: FontWeight.w600,
              height: 1.35,
            ),
          ),
        ),
      ],
    );
  }
}
