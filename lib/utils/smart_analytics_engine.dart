import 'package:renew_wise/models/expense_record.dart';
import 'package:renew_wise/models/goal_planner_models.dart';
import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/models/renewal_category.dart';
import 'package:renew_wise/models/renewal_currency.dart';
import 'package:renew_wise/models/renewal_status.dart';
import 'package:renew_wise/models/smart_analytics_models.dart';
import 'package:renew_wise/utils/date_utils.dart';
import 'package:renew_wise/utils/goal_planner_engine.dart';
import 'package:renew_wise/utils/recurrence_utils.dart';
import 'package:renew_wise/utils/repeat_date_utils.dart';

abstract final class SmartAnalyticsEngine {
  static SmartAnalyticsSnapshot compute({
    required List<ExpenseRecord> expenses,
    required List<Renewal> renewals,
    required GoalPlannerSettings goalSettings,
    required SmartAnalyticsFilterState filter,
    required RenewalCurrency currency,
    DateTime? now,
  }) {
    final current = now ?? DateTime.now();
    final range = _resolveRange(filter, current);
    final filteredExpenses = _filterExpenses(expenses, filter, range, current);
    final categorySlices = _categoryBreakdown(filteredExpenses);
    final spendingConclusion = _spendingConclusion(categorySlices);
    final planned = _plannedInRange(renewals, range.start, range.end);
    final actual = filteredExpenses.fold<double>(0, (sum, e) => sum + e.amount);
    final plannedVsActual = PlannedVsActualData(
      planned: planned,
      actual: actual,
      difference: planned - actual,
    );
    final yearlyMonths = _yearlyMonths(
      expenses: expenses,
      renewals: renewals,
      filter: filter,
      range: range,
      current: current,
    );
    final goalProgress = _goalProgress(goalSettings, renewals, current, expenses);
    final thisMonth = _thisMonthOverview(renewals, expenses, goalSettings, current, currency);
    final topInsights = _topInsights(
      categorySlices: categorySlices,
      plannedVsActual: plannedVsActual,
      goalProgress: goalProgress,
      yearlyMonths: yearlyMonths,
      expenses: expenses,
      renewals: renewals,
      current: current,
      currency: currency,
    );

    return SmartAnalyticsSnapshot(
      currency: currency,
      hasExpenseData: expenses.isNotEmpty,
      hasReminderData: renewals.any(_countsAsExpense),
      spendingConclusion: spendingConclusion,
      categorySlices: categorySlices,
      plannedVsActual: plannedVsActual,
      plannedVsActualConclusion: _plannedVsActualConclusion(plannedVsActual, currency),
      yearlyConclusion: _yearlyConclusion(yearlyMonths, renewals, currency),
      yearlyMonths: yearlyMonths,
      goalProgress: goalProgress,
      topInsights: topInsights,
      thisMonth: thisMonth,
    );
  }

  static ({DateTime start, DateTime end}) _resolveRange(
    SmartAnalyticsFilterState filter,
    DateTime now,
  ) {
    final today = RenewalDateUtils.dateOnly(now);
    return switch (filter.dateFilter) {
      SmartAnalyticsDateFilter.currentMonth => (
          start: DateTime(now.year, now.month, 1),
          end: DateTime(now.year, now.month + 1, 0),
        ),
      SmartAnalyticsDateFilter.last30Days => (
          start: today.subtract(const Duration(days: 29)),
          end: today,
        ),
      SmartAnalyticsDateFilter.currentYear => (
          start: DateTime(now.year, 1, 1),
          end: DateTime(now.year, 12, 31),
        ),
      SmartAnalyticsDateFilter.customRange => (
          start: filter.customStart != null
              ? RenewalDateUtils.dateOnly(filter.customStart!)
              : DateTime(now.year, now.month, 1),
          end: filter.customEnd != null
              ? RenewalDateUtils.dateOnly(filter.customEnd!)
              : today,
        ),
    };
  }

  static List<ExpenseRecord> _filterExpenses(
    List<ExpenseRecord> expenses,
    SmartAnalyticsFilterState filter,
    ({DateTime start, DateTime end}) range,
    DateTime now,
  ) {
    final start = RenewalDateUtils.dateOnly(range.start);
    final end = RenewalDateUtils.dateOnly(range.end);

    return expenses.where((expense) {
      final date = RenewalDateUtils.dateOnly(expense.date);
      if (date.isBefore(start) || date.isAfter(end)) return false;
      if (filter.category != null && expense.category != filter.category) {
        return false;
      }
      return true;
    }).toList()
      ..sort((a, b) => b.date.compareTo(a.date));
  }

  static List<AnalyticsCategorySlice> _categoryBreakdown(
    List<ExpenseRecord> expenses,
  ) {
    if (expenses.isEmpty) return const [];

    final totals = <RenewalCategory, double>{};
    for (final expense in expenses) {
      totals[expense.category] = (totals[expense.category] ?? 0) + expense.amount;
    }

    final grandTotal = totals.values.fold<double>(0, (sum, v) => sum + v);
    if (grandTotal <= 0) return const [];

    final entries = totals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return entries
        .map(
          (e) => AnalyticsCategorySlice(
            category: e.key,
            amount: e.value,
            percentage: (e.value / grandTotal) * 100,
            color: SmartAnalyticsColors.forCategory(e.key),
          ),
        )
        .toList();
  }

  static String? _spendingConclusion(List<AnalyticsCategorySlice> slices) {
    if (slices.isEmpty) return null;
    final top = slices.first;
    if (slices.length == 1) {
      return '${top.category.label} is your highest expense category.';
    }
    final pct = top.percentage.round();
    if (pct >= 15) {
      return '${top.category.label} accounts for $pct% of your expenses.';
    }
    return '${top.category.label} is your highest expense category.';
  }

  static double _plannedInRange(
    List<Renewal> renewals,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    var total = 0.0;
    for (final renewal in renewals) {
      if (!_countsAsExpense(renewal)) continue;
      final amount = renewal.amount ?? 0;
      for (final _ in _occurrencesInRange(renewal, rangeStart, rangeEnd)) {
        total += amount;
      }
    }
    return total;
  }

  static String? _plannedVsActualConclusion(
    PlannedVsActualData data,
    RenewalCurrency currency,
  ) {
    if (data.planned <= 0 && data.actual <= 0) return null;
    final diff = data.difference.abs();
    if (data.difference > 0) {
      return 'You spent ${currency.formatAmount(diff)} less than planned.';
    }
    if (data.difference < 0) {
      return 'You exceeded your planned spending by ${currency.formatAmount(diff)}.';
    }
    return 'Your spending matched your planned expenses.';
  }

  static List<YearlyMonthStat> _yearlyMonths({
    required List<ExpenseRecord> expenses,
    required List<Renewal> renewals,
    required SmartAnalyticsFilterState filter,
    required ({DateTime start, DateTime end}) range,
    required DateTime current,
  }) {
    final chartYear = switch (filter.dateFilter) {
      SmartAnalyticsDateFilter.currentYear => current.year,
      SmartAnalyticsDateFilter.customRange =>
        filter.customEnd?.year ?? filter.customStart?.year ?? current.year,
      _ => current.year,
    };

    final globalStart = RenewalDateUtils.dateOnly(range.start);
    final globalEnd = RenewalDateUtils.dateOnly(range.end);

    return List.generate(12, (index) {
      final month = index + 1;
      final monthStart = DateTime(chartYear, month, 1);
      final monthEnd = DateTime(chartYear, month + 1, 0);
      final effectiveStart = monthStart.isBefore(globalStart) ? globalStart : monthStart;
      final effectiveEnd = monthEnd.isAfter(globalEnd) ? globalEnd : monthEnd;
      final inFilter = !effectiveStart.isAfter(effectiveEnd);

      final monthExpenses = inFilter
          ? expenses.where((e) {
              if (filter.category != null && e.category != filter.category) {
                return false;
              }
              final date = RenewalDateUtils.dateOnly(e.date);
              return !date.isBefore(effectiveStart) && !date.isAfter(effectiveEnd);
            }).toList()
          : <ExpenseRecord>[];

      final monthReminders = inFilter
          ? _remindersInRange(renewals, effectiveStart, effectiveEnd)
          : <Renewal>[];

      final plannedAmount = inFilter
          ? _plannedInRange(renewals, effectiveStart, effectiveEnd)
          : 0.0;
      final actualAmount =
          monthExpenses.fold<double>(0, (sum, e) => sum + e.amount);

      return YearlyMonthStat(
        year: chartYear,
        month: month,
        label: GoalPlannerValidationUtils.shortMonthLabel(month),
        plannedAmount: plannedAmount,
        actualAmount: actualAmount,
        totalAmount: actualAmount > 0 ? actualAmount : plannedAmount,
        reminders: monthReminders,
        expenses: monthExpenses,
      );
    });
  }

  static List<Renewal> _remindersInRange(
    List<Renewal> renewals,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final results = <Renewal>[];
    for (final renewal in renewals) {
      if (!_countsAsExpense(renewal)) continue;
      final dates = _occurrencesInRange(renewal, rangeStart, rangeEnd);
      if (dates.isNotEmpty) results.add(renewal);
    }
    return results;
  }

  static String? _yearlyConclusion(
    List<YearlyMonthStat> months,
    List<Renewal> renewals,
    RenewalCurrency currency,
  ) {
    final withTotals = months.where((m) => m.totalAmount > 0).toList();
    if (withTotals.isEmpty) return null;

    withTotals.sort((a, b) => b.totalAmount.compareTo(a.totalAmount));
    final highest = withTotals.first;
    final monthName = RenewalDateUtils.monthName(highest.month);

    if (highest.actualAmount > 0) {
      return '$monthName is your highest spending month.';
    }

    final plannedOnly = months.where((m) => m.plannedAmount > 0).toList()
      ..sort((a, b) => a.plannedAmount.compareTo(b.plannedAmount));
    if (plannedOnly.isNotEmpty) {
      final lowest = plannedOnly.first;
      return '${RenewalDateUtils.monthName(lowest.month)} has the lowest planned expenses.';
    }

    return '$monthName has the highest planned expenses at ${currency.formatAmount(highest.totalAmount)}.';
  }

  static GoalProgressAnalytics? _goalProgress(
    GoalPlannerSettings settings,
    List<Renewal> renewals,
    DateTime now,
    List<ExpenseRecord> expenses,
  ) {
    if (!settings.planGenerated ||
        settings.goalAmount == null ||
        settings.targetYear == null ||
        settings.targetMonth == null) {
      return null;
    }

    final validation = GoalPlannerValidationUtils.validateInputs(
      settings: settings,
      now: now,
    );
    if (!validation.isValid) return null;

    final plan = GoalPlannerEngine.compute(
      settings: settings,
      renewals: renewals,
      now: now,
    );

    final conclusion = _goalConclusion(plan, expenses, now);
    return GoalProgressAnalytics(
      goalAmount: plan.goalAmount,
      estimatedSavings: plan.estimatedSavings,
      remainingAmount: plan.remainingToGoal,
      completionPercent: plan.completionPercent,
      conclusion: conclusion,
      isOnTrack: plan.isAchievable && plan.completionPercent >= 50,
    );
  }

  static String _goalConclusion(
    GoalPlanResult plan,
    List<ExpenseRecord> expenses,
    DateTime now,
  ) {
    if (plan.isAchievable && plan.completionPercent >= 80) {
      return 'You are on track.';
    }

    GoalPlanMonthRow? heavyMonth;
    for (final m in plan.months) {
      if (m.status == GoalMonthStatus.heavyExpense &&
          m.year == now.year &&
          m.month == now.month) {
        heavyMonth = m;
        break;
      }
    }

    if (heavyMonth != null) {
      return 'Your goal is delayed because of high expenses in ${RenewalDateUtils.monthName(now.month)}.';
    }

    if (!plan.isAchievable) {
      return 'Your current plan may not reach the goal on time.';
    }

    return 'Keep saving steadily to reach your goal.';
  }

  static ThisMonthOverview? _thisMonthOverview(
    List<Renewal> renewals,
    List<ExpenseRecord> expenses,
    GoalPlannerSettings settings,
    DateTime now,
    RenewalCurrency currency,
  ) {
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    final planned = _plannedInRange(renewals, monthStart, monthEnd);
    final actual = expenses
        .where((e) {
          final date = RenewalDateUtils.dateOnly(e.date);
          return !date.isBefore(monthStart) && !date.isAfter(monthEnd);
        })
        .fold<double>(0, (sum, e) => sum + e.amount);

    final categoryTotals = <RenewalCategory, double>{};
    for (final expense in expenses) {
      final date = RenewalDateUtils.dateOnly(expense.date);
      if (date.isBefore(monthStart) || date.isAfter(monthEnd)) continue;
      categoryTotals[expense.category] =
          (categoryTotals[expense.category] ?? 0) + expense.amount;
    }

    String highestCategory = '—';
    if (categoryTotals.isNotEmpty) {
      final top = categoryTotals.entries.reduce(
        (a, b) => a.value >= b.value ? a : b,
      );
      highestCategory = top.key.label;
    } else {
      final plannedByCategory = <RenewalCategory, double>{};
      for (final renewal in renewals) {
        if (!_countsAsExpense(renewal)) continue;
        for (final _ in _occurrencesInRange(renewal, monthStart, monthEnd)) {
          plannedByCategory[renewal.category] =
              (plannedByCategory[renewal.category] ?? 0) + (renewal.amount ?? 0);
        }
      }
      if (plannedByCategory.isNotEmpty) {
        final top = plannedByCategory.entries.reduce(
          (a, b) => a.value >= b.value ? a : b,
        );
        highestCategory = top.key.label;
      }
    }

    final upcoming = renewals
        .where((r) =>
            _countsAsExpense(r) &&
            !RenewalDateUtils.dateOnly(r.renewalDate).isBefore(now))
        .toList()
      ..sort((a, b) => a.renewalDate.compareTo(b.renewalDate));

    final nextReminder = upcoming.isEmpty
        ? '—'
        : '${upcoming.first.title} · ${RenewalDateUtils.formatDisplayDate(upcoming.first.renewalDate)}';

    final savings = planned - actual;
    final status = actual <= planned || planned <= 0 ? 'On Track' : 'Over Budget';

    return ThisMonthOverview(
      status: status,
      expectedSpending: currency.formatAmount(planned),
      expectedSavings: currency.formatAmount(savings.clamp(0, double.infinity)),
      highestCategory: highestCategory,
      nextReminder: nextReminder,
    );
  }

  static List<String> _topInsights({
    required List<AnalyticsCategorySlice> categorySlices,
    required PlannedVsActualData plannedVsActual,
    required GoalProgressAnalytics? goalProgress,
    required List<YearlyMonthStat> yearlyMonths,
    required List<ExpenseRecord> expenses,
    required List<Renewal> renewals,
    required DateTime current,
    required RenewalCurrency currency,
  }) {
    final insights = <String>[];

    if (categorySlices.isNotEmpty) {
      insights.add(
        '${categorySlices.first.category.label} accounts for the largest share of your spending.',
      );
    }

    if (goalProgress != null) {
      insights.add(
        goalProgress.isOnTrack
            ? 'You are likely to reach your savings goal.'
            : goalProgress.conclusion,
      );
    }

    final thisMonth = current.month;
    final lastMonth = thisMonth == 1 ? 12 : thisMonth - 1;
    final lastMonthYear = thisMonth == 1 ? current.year - 1 : current.year;

    final thisMonthSubs = expenses
        .where((e) =>
            e.category == RenewalCategory.subscription &&
            e.date.year == current.year &&
            e.date.month == thisMonth)
        .fold<double>(0, (sum, e) => sum + e.amount);
    final lastMonthSubs = expenses
        .where((e) =>
            e.category == RenewalCategory.subscription &&
            e.date.year == lastMonthYear &&
            e.date.month == lastMonth)
        .fold<double>(0, (sum, e) => sum + e.amount);

    if (thisMonthSubs > 0 && lastMonthSubs > 0) {
      if (thisMonthSubs > lastMonthSubs) {
        insights.add('Subscriptions increased compared to last month.');
      } else if (thisMonthSubs < lastMonthSubs) {
        insights.add('Subscriptions decreased compared to last month.');
      }
    }

    final withTotals = yearlyMonths.where((m) => m.plannedAmount > 0).toList();
    if (withTotals.length >= 2) {
      withTotals.sort((a, b) => b.plannedAmount.compareTo(a.plannedAmount));
      final high = withTotals.first;
      final low = withTotals.last;
      if (high.month != low.month) {
        insights.add(
          '${RenewalDateUtils.monthName(low.month)} has fewer planned expenses than ${RenewalDateUtils.monthName(high.month)}.',
        );
      }
    }

    if (plannedVsActual.actual > 0 && plannedVsActual.planned > 0) {
      final diff = plannedVsActual.difference;
      if (diff.abs() >= 100) {
        insights.add(
          diff > 0
              ? 'You spent ${currency.formatAmount(diff)} less than planned in this period.'
              : 'You exceeded planned spending by ${currency.formatAmount(diff.abs())} in this period.',
        );
      }
    }

    if (insights.isEmpty && renewals.any(_countsAsExpense)) {
      insights.add('Add more reminders to unlock deeper insights.');
    } else if (insights.isEmpty) {
      insights.add('Track a few expenses to start seeing trends.');
    }

    return insights.take(5).toList();
  }

  static bool _countsAsExpense(Renewal renewal) {
    if (!renewal.paymentRequired || renewal.amount == null) return false;
    if (renewal.status == RenewalStatus.paid ||
        renewal.status == RenewalStatus.cancelled) {
      return false;
    }
    return true;
  }

  static List<DateTime> _occurrencesInRange(
    Renewal renewal,
    DateTime rangeStart,
    DateTime rangeEnd,
  ) {
    final start = RenewalDateUtils.dateOnly(rangeStart);
    final end = RenewalDateUtils.dateOnly(rangeEnd);
    var date = RenewalDateUtils.dateOnly(renewal.renewalDate);

    if (!RecurrenceUtils.isRecurring(renewal)) {
      if (date.isBefore(start) || date.isAfter(end)) return const [];
      return [date];
    }

    while (date.isBefore(start)) {
      final next = RepeatDateUtils.nextOccurrence(date, renewal.repeatCycle);
      if (next == null) return const [];
      date = RenewalDateUtils.dateOnly(next);
    }

    final results = <DateTime>[];
    var completed = renewal.recurrenceCompletedCount;
    while (!date.isAfter(end)) {
      results.add(date);
      final next = RepeatDateUtils.nextOccurrence(date, renewal.repeatCycle);
      if (next == null) break;
      completed++;
      if (RecurrenceUtils.shouldEndSeries(
        renewal: renewal,
        completedCount: completed,
        nextOccurrenceDate: next,
      )) {
        break;
      }
      date = RenewalDateUtils.dateOnly(next);
    }
    return results;
  }
}
