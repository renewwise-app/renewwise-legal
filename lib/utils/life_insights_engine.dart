import 'package:renew_wise/models/history_entry.dart';
import 'package:renew_wise/models/life_insights_models.dart';
import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/models/renewal_category.dart';
import 'package:renew_wise/models/renewal_currency.dart';
import 'package:renew_wise/models/renewal_status.dart';
import 'package:renew_wise/models/repeat_cycle.dart';
import 'package:renew_wise/services/event_extras_service.dart';
import 'package:renew_wise/services/sharing_service.dart';
import 'package:renew_wise/utils/date_utils.dart';

/// Computes Life Insights metrics from read-only service snapshots.
class LifeInsightsEngine {
  LifeInsightsEngine({
    required this.renewals,
    required this.history,
    this.eventExtras,
    this.sharing,
    this.filter = InsightsTimeFilter.year,
    this.customStart,
    this.customEnd,
    this.searchQuery = '',
    this.spendingGranularity = SpendingGranularity.month,
    this.calendarYear,
    this.calendarMonth,
  });

  final List<Renewal> renewals;
  final List<HistoryEntry> history;
  final EventExtrasService? eventExtras;
  final SharingService? sharing;
  final InsightsTimeFilter filter;
  final DateTime? customStart;
  final DateTime? customEnd;
  final String searchQuery;
  final SpendingGranularity spendingGranularity;
  final int? calendarYear;
  final int? calendarMonth;

  LifeInsightsSnapshot compute() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final range = _dateRange(now);
    final currency = _primaryCurrency();

    final searched = _applySearch(renewals);
    final inRange = searched.where((r) {
      if (r.status == RenewalStatus.cancelled) return false;
      return _inRange(_dateOnly(r.renewalDate), range.$1, range.$2);
    }).toList();

    final active = inRange
        .where(
          (r) =>
              r.status == RenewalStatus.upcoming ||
              r.status == RenewalStatus.overdue,
        )
        .toList();

    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    final upcomingThisMonth = searched
        .where(
          (r) =>
              r.status != RenewalStatus.cancelled &&
              r.status != RenewalStatus.paid &&
              !_before(_dateOnly(r.renewalDate), monthStart) &&
              !_after(_dateOnly(r.renewalDate), monthEnd),
        )
        .length;

    final yearStart = DateTime(now.year, 1, 1);
    final yearEnd = DateTime(now.year, 12, 31);
    final historyInYear = history.where(
      (e) =>
          !e.restored &&
          !_before(_dateOnly(e.completionDate), yearStart) &&
          !_after(_dateOnly(e.completionDate), yearEnd),
    );
    final completedThisYear = historyInYear.length;

    final totalAmountDue = active
        .where((r) => r.paymentRequired && r.amount != null)
        .fold<double>(0, (s, r) => s + r.amount!);

    final amountDueThisMonth = searched
        .where(
          (r) =>
              r.status != RenewalStatus.cancelled &&
              r.status != RenewalStatus.paid &&
              r.paymentRequired &&
              r.amount != null &&
              !_before(_dateOnly(r.renewalDate), monthStart) &&
              !_after(_dateOnly(r.renewalDate), monthEnd),
        )
        .fold<double>(0, (s, r) => s + r.amount!);

    final amountDueThisYear = searched
        .where(
          (r) =>
              r.status != RenewalStatus.cancelled &&
              r.status != RenewalStatus.paid &&
              r.paymentRequired &&
              r.amount != null &&
              r.renewalDate.year == now.year,
        )
        .fold<double>(0, (s, r) => s + r.amount!);

    final paidThisYear = historyInYear
        .where((e) => e.amount != null)
        .fold<double>(0, (s, e) => s + e.amount!);

    final monthsElapsed = now.month.clamp(1, 12);
    final avgMonthlyPayments =
        monthsElapsed > 0 ? paidThisYear / monthsElapsed : 0.0;

    final categoryGroups = _buildCategoryGroups(inRange);
    CategoryGroupStat? highest;
    CategoryGroupStat? lowest;
    if (categoryGroups.isNotEmpty) {
      final withAmount = categoryGroups.where((g) => g.amount > 0).toList();
      if (withAmount.isNotEmpty) {
        withAmount.sort((a, b) => b.amount.compareTo(a.amount));
        highest = withAmount.first;
        lowest = withAmount.last;
      }
    }

    final completion = _computeCompletion(range);
    final calYear = calendarYear ?? now.year;
    final calMonth = calendarMonth ?? now.month;
    final calendarDays = _buildCalendar(calYear, calMonth, searched);

    final upcoming7 = _upcoming(searched, today, 7);
    final upcoming30 = _upcoming(searched, today, 30);
    final upcoming90 = _upcoming(searched, today, 90);

    final spendingTimeline = _buildSpendingTimeline(searched, now);
    final healthInsights = _buildHealth(searched);
    final achievements = _buildAchievements(now: now);

    return LifeInsightsSnapshot(
      filter: filter,
      currency: currency,
      activeEvents: active.length,
      upcomingThisMonth: upcomingThisMonth,
      completedThisYear: completedThisYear,
      totalAmountDue: totalAmountDue,
      amountDueThisMonth: amountDueThisMonth,
      amountDueThisYear: amountDueThisYear,
      paidThisYear: paidThisYear,
      avgMonthlyPayments: avgMonthlyPayments,
      highestCategory: highest,
      lowestCategory: lowest,
      categoryGroups: categoryGroups,
      completion: completion,
      calendarDays: calendarDays,
      upcoming7: upcoming7,
      upcoming30: upcoming30,
      upcoming90: upcoming90,
      spendingTimeline: spendingTimeline,
      healthInsights: healthInsights,
      achievements: achievements,
      filteredRenewals: inRange,
      isEmpty: renewals.isEmpty && history.isEmpty,
    );
  }

  (DateTime, DateTime) _dateRange(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);
    switch (filter) {
      case InsightsTimeFilter.today:
        return (today, today);
      case InsightsTimeFilter.week:
        final start = today.subtract(Duration(days: today.weekday - 1));
        return (start, start.add(const Duration(days: 6)));
      case InsightsTimeFilter.month:
        return (
          DateTime(now.year, now.month, 1),
          DateTime(now.year, now.month + 1, 0),
        );
      case InsightsTimeFilter.quarter:
        final q = ((now.month - 1) ~/ 3) * 3 + 1;
        return (DateTime(now.year, q, 1), DateTime(now.year, q + 3, 0));
      case InsightsTimeFilter.year:
        return (DateTime(now.year, 1, 1), DateTime(now.year, 12, 31));
      case InsightsTimeFilter.custom:
        final start = customStart != null
            ? _dateOnly(customStart!)
            : DateTime(now.year, 1, 1);
        final end = customEnd != null
            ? _dateOnly(customEnd!)
            : DateTime(now.year, 12, 31);
        return start.isBefore(end) ? (start, end) : (end, start);
    }
  }

  List<Renewal> _applySearch(List<Renewal> source) {
    final q = searchQuery.trim().toLowerCase();
    if (q.isEmpty) return source;
    return source.where((r) {
      if (r.title.toLowerCase().contains(q)) return true;
      if (r.categoryLabel.toLowerCase().contains(q)) return true;
      if (r.category.label.toLowerCase().contains(q)) return true;
      if (r.notes?.toLowerCase().contains(q) ?? false) return true;
      if (r.amount?.toString().contains(q) ?? false) return true;
      if ('${r.renewalDate.year}'.contains(q)) return true;
      if (RenewalDateUtils.monthName(r.renewalDate.month)
          .toLowerCase()
          .contains(q)) {
        return true;
      }
      return false;
    }).toList();
  }

  List<CategoryGroupStat> _buildCategoryGroups(List<Renewal> items) {
    final map = <CategoryAnalyticsGroup, List<Renewal>>{};
    for (final r in items) {
      final g = CategoryAnalyticsGroup.fromRenewalCategory(r.category);
      map.putIfAbsent(g, () => []).add(r);
    }
    return CategoryAnalyticsGroup.values
        .map((g) {
          final list = map[g] ?? const <Renewal>[];
          final amount = list
              .where((r) => r.paymentRequired && r.amount != null)
              .fold<double>(0, (s, r) => s + r.amount!);
          return CategoryGroupStat(
            group: g,
            count: list.length,
            amount: amount,
            renewals: list,
          );
        })
        .where((g) => g.count > 0)
        .toList();
  }

  CompletionInsights _computeCompletion((DateTime, DateTime) range) {
    final entries = history.where((e) {
      if (e.restored) return false;
      final d = _dateOnly(e.completionDate);
      return _inRange(d, range.$1, range.$2);
    }).toList();

    if (entries.isEmpty) {
      return const CompletionInsights(
        completionRate: 0,
        completedOnTime: 0,
        completedLate: 0,
        averageDelayDays: 0,
        longestStreak: 0,
        currentStreak: 0,
      );
    }

    var onTime = 0;
    var late = 0;
    var totalDelay = 0;
    for (final e in entries) {
      final delay = _dateOnly(e.completionDate)
          .difference(_dateOnly(e.originalRenewalDate))
          .inDays;
      if (delay <= 0) {
        onTime++;
      } else {
        late++;
        totalDelay += delay;
      }
    }
    final total = onTime + late;
    final rate = total > 0 ? (onTime / total) * 100 : 0.0;
    final avgDelay = late > 0 ? totalDelay / late : 0.0;

    final sortedDates = entries
        .map((e) => _dateOnly(e.completionDate))
        .toSet()
        .toList()
      ..sort();
    final streaks = _computeStreaks(sortedDates);
    return CompletionInsights(
      completionRate: rate,
      completedOnTime: onTime,
      completedLate: late,
      averageDelayDays: avgDelay,
      longestStreak: streaks.$1,
      currentStreak: streaks.$2,
    );
  }

  (int longest, int current) _computeStreaks(List<DateTime> sortedUniqueDays) {
    if (sortedUniqueDays.isEmpty) return (0, 0);

    var longest = 1;
    var run = 1;
    for (var i = 1; i < sortedUniqueDays.length; i++) {
      final diff =
          sortedUniqueDays[i].difference(sortedUniqueDays[i - 1]).inDays;
      if (diff == 1) {
        run++;
        if (run > longest) longest = run;
      } else {
        run = 1;
      }
    }

    var current = 0;
    final today = _dateOnly(DateTime.now());
    var cursor = today;
    while (sortedUniqueDays.contains(cursor)) {
      current++;
      cursor = cursor.subtract(const Duration(days: 1));
    }

    return (longest, current);
  }

  List<DayInsights> _buildCalendar(
    int year,
    int month,
    List<Renewal> items,
  ) {
    final first = DateTime(year, month, 1);
    final last = DateTime(year, month + 1, 0);
    final days = <DayInsights>[];
    for (var d = first;
        !d.isAfter(last);
        d = d.add(const Duration(days: 1))) {
      final day = _dateOnly(d);
      final dayRenewals = items.where((r) {
        if (r.status == RenewalStatus.cancelled) return false;
        return _sameDay(_dateOnly(r.renewalDate), day);
      }).toList();
      final dayHistory = history.where((e) {
        if (e.restored) return false;
        return _sameDay(_dateOnly(e.completionDate), day);
      }).toList();
      final overdue = dayRenewals.where((r) => r.isOverdue).toList();

      DayCellKind kind = DayCellKind.none;
      final hasReminder = dayRenewals.isNotEmpty;
      final hasCompleted = dayHistory.isNotEmpty;
      final hasOverdue = overdue.isNotEmpty;
      if (hasReminder && hasCompleted && hasOverdue) {
        kind = DayCellKind.mixed;
      } else if (hasOverdue) {
        kind = DayCellKind.overdue;
      } else if (hasCompleted) {
        kind = DayCellKind.completed;
      } else if (hasReminder) {
        kind = DayCellKind.reminder;
      }

      days.add(
        DayInsights(
          date: day,
          kind: kind,
          renewals: dayRenewals,
          historyEntries: dayHistory,
        ),
      );
    }
    return days;
  }

  List<Renewal> _upcoming(List<Renewal> source, DateTime today, int days) {
    final end = today.add(Duration(days: days));
    return source
        .where(
          (r) =>
              r.status != RenewalStatus.cancelled &&
              r.status != RenewalStatus.paid &&
              !_before(_dateOnly(r.renewalDate), today) &&
              !_after(_dateOnly(r.renewalDate), end),
        )
        .toList()
      ..sort((a, b) => a.renewalDate.compareTo(b.renewalDate));
  }

  List<SpendingPeriodStat> _buildSpendingTimeline(
    List<Renewal> items,
    DateTime now,
  ) {
    switch (spendingGranularity) {
      case SpendingGranularity.month:
        return List.generate(12, (i) {
          final month = i + 1;
          final inMonth = items.where(
            (r) =>
                r.status != RenewalStatus.cancelled &&
                r.paymentRequired &&
                r.amount != null &&
                r.renewalDate.year == now.year &&
                r.renewalDate.month == month,
          );
          final amount = inMonth.fold<double>(0, (s, r) => s + r.amount!);
          return SpendingPeriodStat(
            label: RenewalDateUtils.monthName(month).substring(0, 3),
            amount: amount,
            count: inMonth.length,
            year: now.year,
            month: month,
          );
        });
      case SpendingGranularity.quarter:
        return List.generate(4, (i) {
          final qStart = i * 3 + 1;
          final inQ = items.where(
            (r) =>
                r.status != RenewalStatus.cancelled &&
                r.paymentRequired &&
                r.amount != null &&
                r.renewalDate.year == now.year &&
                r.renewalDate.month >= qStart &&
                r.renewalDate.month <= qStart + 2,
          );
          final amount = inQ.fold<double>(0, (s, r) => s + r.amount!);
          return SpendingPeriodStat(
            label: 'Q${i + 1}',
            amount: amount,
            count: inQ.length,
            year: now.year,
            month: qStart,
          );
        });
      case SpendingGranularity.year:
        final years = <int>{now.year, now.year - 1, now.year - 2};
        for (final r in items) {
          if (r.paymentRequired && r.amount != null) {
            years.add(r.renewalDate.year);
          }
        }
        final sorted = years.toList()..sort();
        return sorted.reversed.take(5).map((y) {
          final inY = items.where(
            (r) =>
                r.status != RenewalStatus.cancelled &&
                r.paymentRequired &&
                r.amount != null &&
                r.renewalDate.year == y,
          );
          final amount = inY.fold<double>(0, (s, r) => s + r.amount!);
          return SpendingPeriodStat(
            label: '$y',
            amount: amount,
            count: inY.length,
            year: y,
            month: 1,
          );
        }).toList();
    }
  }

  List<HealthInsight> _buildHealth(List<Renewal> items) {
    final active = items
        .where(
          (r) =>
              r.status != RenewalStatus.cancelled &&
              r.status != RenewalStatus.paid,
        )
        .toList();

    List<Renewal> missingDocs() => active.where((r) {
          final docs = eventExtras?.documentsFor(r.id) ?? const [];
          return docs.isEmpty;
        }).toList();

    List<Renewal> missingNotes() => active
        .where((r) => r.notes == null || r.notes!.trim().isEmpty)
        .toList();

    List<Renewal> withoutAmount() =>
        active.where((r) => r.paymentRequired && r.amount == null).toList();

    List<Renewal> overdue() => active.where((r) => r.isOverdue).toList();

    List<Renewal> shared() {
      final svc = sharing;
      if (svc == null) return const [];
      return active.where((r) => svc.isShared(r.id)).toList();
    }

    List<Renewal> recurring() =>
        active.where((r) => r.repeatCycle != RepeatCycle.oneTime).toList();

    return [
      HealthInsight(
        kind: HealthInsightKind.missingDocuments,
        count: missingDocs().length,
        renewals: missingDocs(),
      ),
      HealthInsight(
        kind: HealthInsightKind.missingNotes,
        count: missingNotes().length,
        renewals: missingNotes(),
      ),
      HealthInsight(
        kind: HealthInsightKind.withoutAmount,
        count: withoutAmount().length,
        renewals: withoutAmount(),
      ),
      HealthInsight(
        kind: HealthInsightKind.overdue,
        count: overdue().length,
        renewals: overdue(),
      ),
      HealthInsight(
        kind: HealthInsightKind.shared,
        count: shared().length,
        renewals: shared(),
      ),
      HealthInsight(
        kind: HealthInsightKind.recurring,
        count: recurring().length,
        renewals: recurring(),
      ),
    ];
  }

  List<AchievementInsight> _buildAchievements({required DateTime now}) {
    final totalCompleted = history.where((e) => !e.restored).length;
    final insuranceOnTime = history.where((e) {
      if (e.restored) return false;
      if (e.category != RenewalCategory.insurance) return false;
      final delay = _dateOnly(e.completionDate)
          .difference(_dateOnly(e.originalRenewalDate))
          .inDays;
      return delay <= 0;
    }).length;

    final monthEntries = history.where((e) {
      if (e.restored) return false;
      return e.completionDate.year == now.year &&
          e.completionDate.month == now.month;
    }).toList();
    final monthPerfect = monthEntries.isNotEmpty &&
        monthEntries.every(
          (e) =>
              _dateOnly(e.completionDate)
                  .difference(_dateOnly(e.originalRenewalDate))
                  .inDays <=
              0,
        );

    final earliest = renewals
        .map((r) => r.createdAt)
        .fold<DateTime?>(null, (a, b) => a == null || b.isBefore(a) ? b : a);
    final oneYear =
        earliest != null && now.difference(earliest).inDays >= 365;

    return [
      AchievementInsight(
        title: '100 Reminders Completed',
        subtitle: '$totalCompleted completed so far',
        achieved: totalCompleted >= 100,
        iconName: 'check_circle',
      ),
      AchievementInsight(
        title: 'One Year with RenewWise',
        subtitle: oneYear ? 'Thank you for staying organized' : 'Keep going',
        achieved: oneYear,
        iconName: 'calendar_today',
      ),
      AchievementInsight(
        title: '100% Completion This Month',
        subtitle: monthPerfect
            ? 'Every reminder handled on time'
            : 'Complete all this month on time',
        achieved: monthPerfect,
        iconName: 'verified',
      ),
      AchievementInsight(
        title: 'Never Missed an Insurance Renewal',
        subtitle: '$insuranceOnTime on-time insurance renewals',
        achieved: insuranceOnTime >= 3,
        iconName: 'shield',
      ),
    ];
  }

  RenewalCurrency _primaryCurrency() {
    final freqs = <RenewalCurrency, int>{};
    for (final r in renewals) {
      if (r.paymentRequired && r.status != RenewalStatus.cancelled) {
        freqs[r.currency] = (freqs[r.currency] ?? 0) + 1;
      }
    }
    if (freqs.isEmpty) return RenewalCurrency.inr;
    return freqs.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  static DateTime _dateOnly(DateTime d) => DateTime(d.year, d.month, d.day);

  static bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static bool _inRange(DateTime d, DateTime start, DateTime end) =>
      !_before(d, start) && !_after(d, end);

  static bool _before(DateTime a, DateTime b) => a.isBefore(b);
  static bool _after(DateTime a, DateTime b) => a.isAfter(b);

  List<Renewal> renewalsForOverview(OverviewMetricKind kind) {
    final snap = compute();
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);

    return switch (kind) {
      OverviewMetricKind.activeEvents => snap.filteredRenewals
          .where(
            (r) =>
                r.status == RenewalStatus.upcoming ||
                r.status == RenewalStatus.overdue,
          )
          .toList(),
      OverviewMetricKind.upcomingThisMonth => _applySearch(renewals)
          .where(
            (r) =>
                r.status != RenewalStatus.cancelled &&
                r.status != RenewalStatus.paid &&
                !_before(_dateOnly(r.renewalDate), monthStart) &&
                !_after(_dateOnly(r.renewalDate), monthEnd),
          )
          .toList(),
      OverviewMetricKind.completedThisYear => const [],
      OverviewMetricKind.totalAmountDue => snap.filteredRenewals
          .where(
            (r) =>
                (r.status == RenewalStatus.upcoming ||
                    r.status == RenewalStatus.overdue) &&
                r.paymentRequired &&
                r.amount != null,
          )
          .toList(),
    };
  }

  List<Renewal> renewalsForFinancial(FinancialMetricKind kind) {
    final now = DateTime.now();
    final monthStart = DateTime(now.year, now.month, 1);
    final monthEnd = DateTime(now.year, now.month + 1, 0);
    final searched = _applySearch(renewals);

    return switch (kind) {
      FinancialMetricKind.dueThisMonth => searched
          .where(
            (r) =>
                r.status != RenewalStatus.cancelled &&
                r.status != RenewalStatus.paid &&
                r.paymentRequired &&
                r.amount != null &&
                !_before(_dateOnly(r.renewalDate), monthStart) &&
                !_after(_dateOnly(r.renewalDate), monthEnd),
          )
          .toList(),
      FinancialMetricKind.dueThisYear => searched
          .where(
            (r) =>
                r.status != RenewalStatus.cancelled &&
                r.status != RenewalStatus.paid &&
                r.paymentRequired &&
                r.amount != null &&
                r.renewalDate.year == now.year,
          )
          .toList(),
      FinancialMetricKind.paidThisYear ||
      FinancialMetricKind.avgMonthly =>
        const [],
      FinancialMetricKind.highestCategory =>
        compute().highestCategory?.renewals ?? const [],
      FinancialMetricKind.lowestCategory =>
        compute().lowestCategory?.renewals ?? const [],
    };
  }

  List<HistoryEntry> historyForFinancial(FinancialMetricKind kind) {
    final now = DateTime.now();
    final yearStart = DateTime(now.year, 1, 1);
    final yearEnd = DateTime(now.year, 12, 31);
    if (kind == FinancialMetricKind.paidThisYear ||
        kind == FinancialMetricKind.avgMonthly) {
      return history
          .where(
            (e) =>
                !e.restored &&
                !_before(_dateOnly(e.completionDate), yearStart) &&
                !_after(_dateOnly(e.completionDate), yearEnd),
          )
          .toList();
    }
    return const [];
  }

  List<Renewal> renewalsForSpendingPeriod(SpendingPeriodStat period) {
    return _applySearch(renewals)
        .where(
          (r) =>
              r.status != RenewalStatus.cancelled &&
              r.paymentRequired &&
              r.amount != null &&
              r.renewalDate.year == period.year &&
              (spendingGranularity == SpendingGranularity.year ||
                  r.renewalDate.month == period.month ||
                  (spendingGranularity == SpendingGranularity.quarter &&
                      r.renewalDate.month >= period.month &&
                      r.renewalDate.month <= period.month + 2)),
        )
        .toList();
  }
}
