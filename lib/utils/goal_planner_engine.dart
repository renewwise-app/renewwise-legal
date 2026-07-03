import 'package:renew_wise/models/goal_planner_models.dart';
import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/models/renewal_priority.dart';
import 'package:renew_wise/models/renewal_status.dart';
import 'package:renew_wise/utils/date_utils.dart';
import 'package:renew_wise/utils/recurrence_utils.dart';
import 'package:renew_wise/utils/repeat_date_utils.dart';

abstract final class GoalPlannerEngine {
  static GoalPlanResult compute({
    required GoalPlannerSettings settings,
    required List<Renewal> renewals,
    required DateTime now,
  }) {
    final goalAmount = settings.goalAmount ?? 0;
    final target = DateTime(settings.targetYear!, settings.targetMonth!, 1);
    final start = DateTime(now.year, now.month, 1);
    final monthStarts = _monthsBetween(start, target);
    final expensesByMonth = _plannedExpensesByMonth(
      renewals: renewals,
      rangeStart: start,
      rangeEnd: DateTime(target.year, target.month + 1, 0),
    );

    final optionalReminders = <({String title, double amount, RenewalPriority priority})>[];
    var highPriorityTotal = 0.0;
    var lowPriorityTotal = 0.0;

    for (final r in renewals) {
      if (!_countsAsExpense(r)) continue;
      final amount = r.amount ?? 0;
      if (r.priority == RenewalPriority.low) {
        lowPriorityTotal += amount;
        optionalReminders.add((title: r.title, amount: amount, priority: r.priority));
      } else if (r.priority == RenewalPriority.critical ||
          r.priority == RenewalPriority.high) {
        highPriorityTotal += amount;
      }
    }

    final rows = <GoalPlanMonthRow>[];
    var goalRemaining = goalAmount;
    var estimatedSavings = 0.0;
    final expenseTotals = monthStarts
        .map((m) => expensesByMonth[GoalPlannerValidationUtils.monthKey(m.year, m.month)] ?? 0)
        .toList();
    final avgExpenses = expenseTotals.isEmpty
        ? 0.0
        : expenseTotals.reduce((a, b) => a + b) / expenseTotals.length;

    for (final monthStart in monthStarts) {
      final key = GoalPlannerValidationUtils.monthKey(
        monthStart.year,
        monthStart.month,
      );
      final income = _incomeForMonth(settings, monthStart.year, monthStart.month);
      final expenses = expensesByMonth[key] ?? 0;
      final missingIncome =
          settings.incomeType == GoalIncomeType.enterEachMonth &&
              (settings.monthlyIncomes[key] == null || settings.monthlyIncomes[key]! <= 0);

      final effectiveIncome = missingIncome ? 0.0 : income;
      final remaining = effectiveIncome - expenses;
      final suggested = missingIncome || remaining <= 0
          ? 0.0
          : remaining.clamp(0, goalRemaining).toDouble();
      if (!missingIncome) {
        goalRemaining -= suggested;
        estimatedSavings += suggested;
      }

      final status = _statusForMonth(
        missingIncome: missingIncome,
        remaining: remaining,
        expenses: expenses,
        income: effectiveIncome,
        avgExpenses: avgExpenses,
      );

      rows.add(
        GoalPlanMonthRow(
          year: monthStart.year,
          month: monthStart.month,
          label: GoalPlannerValidationUtils.shortMonthLabel(monthStart.month),
          income: effectiveIncome,
          plannedExpenses: expenses,
          suggestedSavings: suggested,
          remainingAmount: remaining,
          status: status,
          missingIncome: missingIncome,
        ),
      );
    }

    return GoalPlanResult(
      months: rows,
      goalAmount: goalAmount,
      estimatedSavings: estimatedSavings,
      isAchievable: estimatedSavings >= goalAmount,
      optionalExpenseReminders: optionalReminders,
      highPriorityExpenseTotal: highPriorityTotal,
      lowPriorityExpenseTotal: lowPriorityTotal,
    );
  }

  static List<DateTime> _monthsBetween(DateTime start, DateTime end) {
    final months = <DateTime>[];
    var y = start.year;
    var m = start.month;
    while (y < end.year || (y == end.year && m <= end.month)) {
      months.add(DateTime(y, m, 1));
      m++;
      if (m > 12) {
        m = 1;
        y++;
      }
    }
    return months;
  }

  static double _incomeForMonth(
    GoalPlannerSettings settings,
    int year,
    int month,
  ) {
    if (settings.incomeType == GoalIncomeType.sameEveryMonth) {
      return settings.defaultMonthlyIncome ?? 0;
    }
    final key = GoalPlannerValidationUtils.monthKey(year, month);
    return settings.monthlyIncomes[key] ?? 0;
  }

  static Map<String, double> _plannedExpensesByMonth({
    required List<Renewal> renewals,
    required DateTime rangeStart,
    required DateTime rangeEnd,
  }) {
    final map = <String, double>{};
    for (final renewal in renewals) {
      if (!_countsAsExpense(renewal)) continue;
      final amount = renewal.amount ?? 0;
      for (final date in _occurrencesInRange(renewal, rangeStart, rangeEnd)) {
        final key = GoalPlannerValidationUtils.monthKey(date.year, date.month);
        map[key] = (map[key] ?? 0) + amount;
      }
    }
    return map;
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

  static GoalMonthStatus _statusForMonth({
    required bool missingIncome,
    required double remaining,
    required double expenses,
    required double income,
    required double avgExpenses,
  }) {
    if (missingIncome) return GoalMonthStatus.missingIncome;
    if (remaining < 0) return GoalMonthStatus.insufficient;
    if (income > 0 && expenses / income >= 0.75) {
      return GoalMonthStatus.heavyExpense;
    }
    if (avgExpenses > 0 && expenses >= avgExpenses * 1.25 && expenses > income * 0.5) {
      return GoalMonthStatus.heavyExpense;
    }
    return GoalMonthStatus.onTrack;
  }
}
