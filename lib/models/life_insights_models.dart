import 'package:renew_wise/models/history_entry.dart';
import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/models/renewal_category.dart';
import 'package:renew_wise/models/renewal_currency.dart';

enum InsightsTimeFilter {
  today('Today'),
  week('Week'),
  month('Month'),
  quarter('Quarter'),
  year('Year'),
  custom('Custom');

  const InsightsTimeFilter(this.label);
  final String label;
}

enum SpendingGranularity {
  month('Month'),
  quarter('Quarter'),
  year('Year');

  const SpendingGranularity(this.label);
  final String label;
}

enum DayCellKind {
  none,
  reminder,
  completed,
  overdue,
  mixed,
}

enum HealthInsightKind {
  missingDocuments('Missing Documents'),
  missingNotes('Missing Notes'),
  withoutAmount('Without Amount'),
  overdue('Overdue'),
  shared('Shared'),
  recurring('Recurring');

  const HealthInsightKind(this.label);
  final String label;
}

enum OverviewMetricKind {
  activeEvents('Total Active Events'),
  upcomingThisMonth('Upcoming This Month'),
  completedThisYear('Completed This Year'),
  totalAmountDue('Total Amount Due');

  const OverviewMetricKind(this.label);
  final String label;
}

enum FinancialMetricKind {
  dueThisMonth('Amount Due This Month'),
  dueThisYear('Amount Due This Year'),
  paidThisYear('Paid This Year'),
  avgMonthly('Average Monthly Payments'),
  highestCategory('Highest Expense Category'),
  lowestCategory('Lowest Expense Category');

  const FinancialMetricKind(this.label);
  final String label;
}

/// High-level category groups for analytics display.
enum CategoryAnalyticsGroup {
  insurance('Insurance'),
  medical('Medical'),
  vehicle('Vehicle'),
  subscriptions('Subscriptions'),
  property('Property'),
  identity('Identity'),
  others('Others');

  const CategoryAnalyticsGroup(this.label);
  final String label;

  static CategoryAnalyticsGroup fromRenewalCategory(RenewalCategory c) {
    return switch (c) {
      RenewalCategory.insurance => CategoryAnalyticsGroup.insurance,
      RenewalCategory.vehicle ||
      RenewalCategory.drivingLicence =>
        CategoryAnalyticsGroup.vehicle,
      RenewalCategory.subscription ||
      RenewalCategory.gym ||
      RenewalCategory.internet =>
        CategoryAnalyticsGroup.subscriptions,
      RenewalCategory.electricity ||
      RenewalCategory.water ||
      RenewalCategory.gas ||
      RenewalCategory.loanEmi =>
        CategoryAnalyticsGroup.property,
      RenewalCategory.passport => CategoryAnalyticsGroup.identity,
      RenewalCategory.warranty => CategoryAnalyticsGroup.medical,
      _ => CategoryAnalyticsGroup.others,
    };
  }
}

class CategoryGroupStat {
  const CategoryGroupStat({
    required this.group,
    required this.count,
    required this.amount,
    required this.renewals,
  });

  final CategoryAnalyticsGroup group;
  final int count;
  final double amount;
  final List<Renewal> renewals;
}

class CompletionInsights {
  const CompletionInsights({
    required this.completionRate,
    required this.completedOnTime,
    required this.completedLate,
    required this.averageDelayDays,
    required this.longestStreak,
    required this.currentStreak,
  });

  final double completionRate;
  final int completedOnTime;
  final int completedLate;
  final double averageDelayDays;
  final int longestStreak;
  final int currentStreak;
}

class DayInsights {
  const DayInsights({
    required this.date,
    required this.kind,
    required this.renewals,
    required this.historyEntries,
  });

  final DateTime date;
  final DayCellKind kind;
  final List<Renewal> renewals;
  final List<HistoryEntry> historyEntries;
}

class SpendingPeriodStat {
  const SpendingPeriodStat({
    required this.label,
    required this.amount,
    required this.count,
    required this.year,
    required this.month,
  });

  final String label;
  final double amount;
  final int count;
  final int year;
  final int month;
}

class AchievementInsight {
  const AchievementInsight({
    required this.title,
    required this.subtitle,
    required this.achieved,
    required this.iconName,
  });

  final String title;
  final String subtitle;
  final bool achieved;
  final String iconName;
}

class HealthInsight {
  const HealthInsight({
    required this.kind,
    required this.count,
    required this.renewals,
  });

  final HealthInsightKind kind;
  final int count;
  final List<Renewal> renewals;
}

class LifeInsightsSnapshot {
  const LifeInsightsSnapshot({
    required this.filter,
    required this.currency,
    required this.activeEvents,
    required this.upcomingThisMonth,
    required this.completedThisYear,
    required this.totalAmountDue,
    required this.amountDueThisMonth,
    required this.amountDueThisYear,
    required this.paidThisYear,
    required this.avgMonthlyPayments,
    required this.highestCategory,
    required this.lowestCategory,
    required this.categoryGroups,
    required this.completion,
    required this.calendarDays,
    required this.upcoming7,
    required this.upcoming30,
    required this.upcoming90,
    required this.spendingTimeline,
    required this.healthInsights,
    required this.achievements,
    required this.filteredRenewals,
    required this.isEmpty,
  });

  final InsightsTimeFilter filter;
  final RenewalCurrency currency;
  final int activeEvents;
  final int upcomingThisMonth;
  final int completedThisYear;
  final double totalAmountDue;
  final double amountDueThisMonth;
  final double amountDueThisYear;
  final double paidThisYear;
  final double avgMonthlyPayments;
  final CategoryGroupStat? highestCategory;
  final CategoryGroupStat? lowestCategory;
  final List<CategoryGroupStat> categoryGroups;
  final CompletionInsights completion;
  final List<DayInsights> calendarDays;
  final List<Renewal> upcoming7;
  final List<Renewal> upcoming30;
  final List<Renewal> upcoming90;
  final List<SpendingPeriodStat> spendingTimeline;
  final List<HealthInsight> healthInsights;
  final List<AchievementInsight> achievements;
  final List<Renewal> filteredRenewals;
  final bool isEmpty;
}
