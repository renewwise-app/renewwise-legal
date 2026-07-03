import 'package:renew_wise/models/goal_planner_models.dart';
import 'package:renew_wise/models/renewal_priority.dart';
import 'package:renew_wise/models/renewal_status.dart';
import 'package:renew_wise/models/smart_analytics_models.dart';
import 'package:renew_wise/services/renewal_service.dart';
import 'package:renew_wise/utils/date_utils.dart';
import 'package:renew_wise/utils/empty_state_guidance.dart';

/// Presentation-only helpers for Smart Insights dashboard summaries.
/// Does not modify analytics calculations.
abstract final class SmartInsightsPresentation {
  /// One concise insight for the Home dashboard Smart Insights card.
  static String homeCardInsight({required SmartAnalyticsSnapshot snapshot}) {
    if (!snapshot.hasReminderData && !snapshot.hasExpenseData) {
      return EmptyStateGuidance.smartInsights;
    }

    final overview = snapshot.thisMonth;
    if (overview != null && overview.status == 'On Track') {
      return "You're on track this month.";
    }

    if (snapshot.spendingConclusion != null) {
      return snapshot.spendingConclusion!;
    }

    final goalProgress = snapshot.goalProgress;
    if (goalProgress != null && goalProgress.completionPercent > 0) {
      return 'Goal progress: ${goalProgress.completionPercent.round()}%.';
    }

    if (snapshot.yearlyConclusion != null) {
      return snapshot.yearlyConclusion!;
    }

    if (snapshot.topInsights.isNotEmpty) {
      return snapshot.topInsights.first;
    }

    if (overview != null && overview.highestCategory != '—') {
      return '${overview.highestCategory} is your biggest expense.';
    }

    if (snapshot.hasReminderData || snapshot.hasExpenseData) {
      return 'Your financial insights will appear as you use RenewWise.';
    }

    return EmptyStateGuidance.smartInsights;
  }

  static List<String> thisMonthSummary({
    required SmartAnalyticsSnapshot snapshot,
    required RenewalService renewalService,
  }) {
    final lines = <String>[];
    final overview = snapshot.thisMonth;

    if (overview != null) {
      final status = overview.status.toLowerCase();
      lines.add("You're $status this month.");
      lines.add('${overview.expectedSpending} expected spending.');
      if (overview.highestCategory != '—') {
        lines.add('Highest expense: ${overview.highestCategory}.');
      }
    }

    final remaining = _importantRemindersRemaining(renewalService);
    if (remaining > 0) {
      lines.add(
        '$remaining important reminder${remaining == 1 ? '' : 's'} remaining.',
      );
    }

    if (lines.isEmpty) {
      lines.add(EmptyStateGuidance.smartInsights);
    }
    return lines.take(4).toList();
  }

  static List<String> goalPlannerSummary({
    required SmartAnalyticsSnapshot snapshot,
    required GoalPlannerSettings settings,
  }) {
    final progress = snapshot.goalProgress;
    if (progress == null) {
      return const ['Set a savings goal to track progress.'];
    }

    final lines = <String>[
      'Goal Progress: ${progress.completionPercent.round()}%',
    ];

    if (settings.targetYear != null && settings.targetMonth != null) {
      lines.add(
        'Est. completion: ${RenewalDateUtils.monthName(settings.targetMonth!)} ${settings.targetYear}',
      );
    }

    lines.add(progress.conclusion);
    return lines.take(4).toList();
  }

  static List<String> spendingSummary({required SmartAnalyticsSnapshot snapshot}) {
    if (snapshot.spendingConclusion != null) {
      return [snapshot.spendingConclusion!];
    }
    if (snapshot.hasExpenseData) {
      return const ['Review your category breakdown for details.'];
    }
    return [EmptyStateGuidance.spendingAnalysis];
  }

  static List<String> yearlyTrendSummary({
    required SmartAnalyticsSnapshot snapshot,
  }) {
    final lines = <String>[];
    if (snapshot.yearlyConclusion != null) {
      lines.add(snapshot.yearlyConclusion!);
    }

    final withTotals = snapshot.yearlyMonths
        .where((month) => month.totalAmount > 0)
        .toList();
    if (withTotals.length >= 2) {
      withTotals.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
      final highest = withTotals.first;
      final lowest = withTotals.last;
      if (highest.month != lowest.month) {
        lines.add(
          '${RenewalDateUtils.monthName(lowest.month)} has the lowest spending.',
        );
      }
    }

    if (lines.isEmpty) {
      lines.add(EmptyStateGuidance.yearlyTrend);
    }
    return lines.take(3).toList();
  }

  static int _importantRemindersRemaining(RenewalService renewalService) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    return renewalService.renewals.where((renewal) {
      if (renewal.status == RenewalStatus.paid ||
          renewal.status == RenewalStatus.cancelled) {
        return false;
      }
      final date = RenewalDateUtils.dateOnly(renewal.renewalDate);
      if (date.isBefore(monthStart) || date.isAfter(monthEnd)) return false;
      return renewal.priority == RenewalPriority.critical ||
          renewal.priority == RenewalPriority.high;
    }).length;
  }
}
