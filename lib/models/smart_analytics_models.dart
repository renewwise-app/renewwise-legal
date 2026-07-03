import 'package:flutter/material.dart';

import 'package:renew_wise/models/expense_record.dart';
import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/models/renewal_category.dart';
import 'package:renew_wise/models/renewal_currency.dart';

enum SmartAnalyticsDateFilter {
  currentMonth('Current Month'),
  last30Days('Last 30 Days'),
  currentYear('Current Year'),
  customRange('Custom Date Range');

  const SmartAnalyticsDateFilter(this.label);
  final String label;
}

class SmartAnalyticsFilterState {
  const SmartAnalyticsFilterState({
    this.dateFilter = SmartAnalyticsDateFilter.currentMonth,
    this.customStart,
    this.customEnd,
    this.category,
  });

  final SmartAnalyticsDateFilter dateFilter;
  final DateTime? customStart;
  final DateTime? customEnd;
  final RenewalCategory? category;

  SmartAnalyticsFilterState copyWith({
    SmartAnalyticsDateFilter? dateFilter,
    DateTime? customStart,
    DateTime? customEnd,
    RenewalCategory? category,
    bool clearCategory = false,
  }) {
    return SmartAnalyticsFilterState(
      dateFilter: dateFilter ?? this.dateFilter,
      customStart: customStart ?? this.customStart,
      customEnd: customEnd ?? this.customEnd,
      category: clearCategory ? null : (category ?? this.category),
    );
  }
}

class AnalyticsCategorySlice {
  const AnalyticsCategorySlice({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.color,
  });

  final RenewalCategory category;
  final double amount;
  final double percentage;
  final Color color;
}

class PlannedVsActualData {
  const PlannedVsActualData({
    required this.planned,
    required this.actual,
    required this.difference,
  });

  final double planned;
  final double actual;
  final double difference;

  bool get isUnderBudget => difference >= 0;
}

class YearlyMonthStat {
  const YearlyMonthStat({
    required this.year,
    required this.month,
    required this.label,
    required this.plannedAmount,
    required this.actualAmount,
    required this.totalAmount,
    required this.reminders,
    required this.expenses,
  });

  final int year;
  final int month;
  final String label;
  final double plannedAmount;
  final double actualAmount;
  final double totalAmount;
  final List<Renewal> reminders;
  final List<ExpenseRecord> expenses;
}

class GoalProgressAnalytics {
  const GoalProgressAnalytics({
    required this.goalAmount,
    required this.estimatedSavings,
    required this.remainingAmount,
    required this.completionPercent,
    required this.conclusion,
    required this.isOnTrack,
  });

  final double goalAmount;
  final double estimatedSavings;
  final double remainingAmount;
  final double completionPercent;
  final String conclusion;
  final bool isOnTrack;
}

class ThisMonthOverview {
  const ThisMonthOverview({
    required this.status,
    required this.expectedSpending,
    required this.expectedSavings,
    required this.highestCategory,
    required this.nextReminder,
  });

  final String status;
  final String expectedSpending;
  final String expectedSavings;
  final String highestCategory;
  final String nextReminder;
}

class SmartAnalyticsSnapshot {
  const SmartAnalyticsSnapshot({
    required this.currency,
    required this.hasExpenseData,
    required this.hasReminderData,
    required this.spendingConclusion,
    required this.categorySlices,
    required this.plannedVsActual,
    required this.plannedVsActualConclusion,
    required this.yearlyConclusion,
    required this.yearlyMonths,
    required this.goalProgress,
    required this.topInsights,
    required this.thisMonth,
  });

  final RenewalCurrency currency;
  final bool hasExpenseData;
  final bool hasReminderData;
  final String? spendingConclusion;
  final List<AnalyticsCategorySlice> categorySlices;
  final PlannedVsActualData? plannedVsActual;
  final String? plannedVsActualConclusion;
  final String? yearlyConclusion;
  final List<YearlyMonthStat> yearlyMonths;
  final GoalProgressAnalytics? goalProgress;
  final List<String> topInsights;
  final ThisMonthOverview? thisMonth;

  bool get hasSpendingAnalytics =>
      hasExpenseData && categorySlices.isNotEmpty;

  bool get hasPlannedVsActual =>
      hasReminderData || hasExpenseData;

  bool get hasYearlyAnalytics =>
      yearlyMonths.any((m) => m.totalAmount > 0);
}

abstract final class SmartAnalyticsColors {
  static const _palette = [
    Color(0xFF6366F1),
    Color(0xFF8B5CF6),
    Color(0xFFEC4899),
    Color(0xFFF97316),
    Color(0xFFEAB308),
    Color(0xFF22C55E),
    Color(0xFF14B8A6),
    Color(0xFF0EA5E9),
    Color(0xFF64748B),
  ];

  static Color forCategory(RenewalCategory category) {
    return _palette[category.index % _palette.length];
  }
}
