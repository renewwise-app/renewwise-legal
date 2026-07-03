import 'package:flutter/material.dart';

import 'package:renew_wise/models/history_entry.dart';
import 'package:renew_wise/models/renewal_currency.dart';
import 'package:renew_wise/models/spending_insights_models.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';

abstract final class SpendingInsightsEngine {
  static const _sliceColors = [
    RenewWisePalette.green,
    RenewWisePalette.blue,
    RenewWisePalette.purple,
    RenewWisePalette.orange,
    Color(0xFFEC4899),
    Color(0xFF14B8A6),
    Color(0xFF6366F1),
    Color(0xFF64748B),
  ];

  static SpendingInsightsSnapshot compute({
    required List<HistoryEntry> history,
    required int year,
    SpendingInsightCategory filter = SpendingInsightCategory.allOverview,
  }) {
    final records = _paidRecords(history);
    final availableYears = _availableYears(records, year);
    final currency = _primaryCurrency(records);

    final previousYear = year - 1;

    final currentRecords = _recordsForYear(records, year, filter);
    final previousRecords = _recordsForYear(records, previousYear, filter);

    final totalThisYear = _sum(currentRecords);
    final totalLastYear = _sum(previousRecords);
    final difference = totalThisYear - totalLastYear;
    final differencePercent = totalLastYear <= 0
        ? (totalThisYear > 0 ? 100.0 : 0.0)
        : (difference / totalLastYear) * 100;

    final breakdown = _buildBreakdown(currentRecords, filter);
    final comparisons = _buildComparisons(records, year, filter);
    final increases = _rankChanges(comparisons, savings: false);
    final savings = _rankChanges(comparisons, savings: true);
    final newExpenses = _detectNewExpenses(records, year, filter);

    final headline = _headline(
      filter: filter,
      currency: currency,
      totalThisYear: totalThisYear,
      totalLastYear: totalLastYear,
      difference: difference,
      differencePercent: differencePercent,
      comparisons: comparisons,
    );

    final breakdownInsight = _breakdownInsight(breakdown);

    return SpendingInsightsSnapshot(
      year: year,
      previousYear: previousYear,
      currency: currency,
      filter: filter,
      headlineInsight: headline,
      totalSpentThisYear: totalThisYear,
      totalSpentLastYear: totalLastYear,
      differenceAmount: difference,
      differencePercent: differencePercent,
      categoryBreakdown: breakdown,
      breakdownInsight: breakdownInsight,
      yearComparisons: comparisons,
      biggestIncreases: increases,
      biggestSavings: savings,
      newExpenses: newExpenses,
      availableYears: availableYears,
      isEmpty: records.isEmpty,
    );
  }

  static List<SpendingRecord> _paidRecords(List<HistoryEntry> history) {
    return history
        .where(
          (entry) =>
              !entry.restored &&
              entry.amount != null &&
              entry.amount! > 0,
        )
        .map(
          (entry) => SpendingRecord(
            title: entry.title.trim(),
            category: SpendingInsightCategory.fromRenewalCategory(entry.category),
            amount: entry.amount!,
            year: entry.completionDate.year,
            entry: entry,
          ),
        )
        .toList();
  }

  static List<int> _availableYears(List<SpendingRecord> records, int selected) {
    final years = records.map((r) => r.year).toSet()..add(selected);
    final list = years.toList()..sort((a, b) => b.compareTo(a));
    return list;
  }

  static RenewalCurrency _primaryCurrency(List<SpendingRecord> records) {
    final freq = <RenewalCurrency, int>{};
    for (final record in records) {
      final code = record.entry.currencyCode;
      if (code == null) continue;
      final currency = RenewalCurrency.values.byName(code);
      freq[currency] = (freq[currency] ?? 0) + 1;
    }
    if (freq.isEmpty) return RenewalCurrency.inr;
    return freq.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
  }

  static List<SpendingRecord> _recordsForYear(
    List<SpendingRecord> records,
    int year,
    SpendingInsightCategory filter,
  ) {
    return records.where((record) {
      if (record.year != year) return false;
      if (filter.isOverview) return true;
      return record.category == filter;
    }).toList();
  }

  static double _sum(List<SpendingRecord> records) {
    return records.fold<double>(0, (sum, record) => sum + record.amount);
  }

  static List<CategorySpendingSlice> _buildBreakdown(
    List<SpendingRecord> currentRecords,
    SpendingInsightCategory filter,
  ) {
    if (filter.isOverview) {
      final totals = <SpendingInsightCategory, double>{};
      for (final record in currentRecords) {
        totals[record.category] = (totals[record.category] ?? 0) + record.amount;
      }
      final total = _sum(currentRecords);
      if (total <= 0) return const [];

      final entries = totals.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      return [
        for (var i = 0; i < entries.length; i++)
          CategorySpendingSlice(
            category: entries[i].key,
            amount: entries[i].value,
            percentage: (entries[i].value / total) * 100,
            color: _sliceColors[i % _sliceColors.length],
          ),
      ];
    }

    final total = _sum(currentRecords);
    if (total <= 0) return const [];
    return [
      CategorySpendingSlice(
        category: filter,
        amount: total,
        percentage: 100,
        color: _sliceColors[0],
      ),
    ];
  }

  static List<CategoryYearComparisonRow> _buildComparisons(
    List<SpendingRecord> records,
    int year,
    SpendingInsightCategory filter,
  ) {
    final categories = filter.isOverview
        ? SpendingInsightCategory.filterTabs
        : [filter];

    final rows = <CategoryYearComparisonRow>[];
    for (final category in categories) {
      final current = _sum(_recordsForYear(records, year, category));
      final last = _sum(_recordsForYear(records, year - 1, category));
      if (current <= 0 && last <= 0) continue;

      final delta = current - last;
      final deltaPercent =
          last <= 0 ? (current > 0 ? 100.0 : 0.0) : (delta / last) * 100;

      rows.add(
        CategoryYearComparisonRow(
          category: category,
          currentAmount: current,
          lastYearAmount: last,
          deltaAmount: delta,
          deltaPercent: deltaPercent,
        ),
      );
    }

    rows.sort((a, b) => b.currentAmount.compareTo(a.currentAmount));
    return rows;
  }

  static List<CategoryChangeRank> _rankChanges(
    List<CategoryYearComparisonRow> comparisons, {
    required bool savings,
  }) {
    final filtered = comparisons.where((row) {
      return savings ? row.deltaAmount < 0 : row.deltaAmount > 0;
    }).toList();

    filtered.sort((a, b) => savings
        ? a.deltaAmount.compareTo(b.deltaAmount)
        : b.deltaAmount.compareTo(a.deltaAmount));

    return filtered
        .take(3)
        .map(
          (row) => CategoryChangeRank(
            category: row.category,
            deltaAmount: row.deltaAmount,
          ),
        )
        .toList();
  }

  static List<NewExpenseInsight> _detectNewExpenses(
    List<SpendingRecord> records,
    int year,
    SpendingInsightCategory filter,
  ) {
    final currentTitles = <String, ({String title, double amount, SpendingInsightCategory category})>{};
    final lastYearTitles = <String>{};

    for (final record in records) {
      final key = record.title.toLowerCase();
      if (record.year == year) {
        if (filter.isOverview || record.category == filter) {
          final existing = currentTitles[key];
          currentTitles[key] = (
            title: record.title,
            amount: (existing?.amount ?? 0) + record.amount,
            category: record.category,
          );
        }
      } else if (record.year == year - 1) {
        if (filter.isOverview || record.category == filter) {
          lastYearTitles.add(key);
        }
      }
    }

    final results = <NewExpenseInsight>[];
    for (final entry in currentTitles.entries) {
      if (lastYearTitles.contains(entry.key)) continue;
      results.add(
        NewExpenseInsight(
          title: entry.value.title,
          amount: entry.value.amount,
          category: entry.value.category,
        ),
      );
    }

    results.sort((a, b) => b.amount.compareTo(a.amount));
    return results;
  }

  static String _headline({
    required SpendingInsightCategory filter,
    required RenewalCurrency currency,
    required double totalThisYear,
    required double totalLastYear,
    required double difference,
    required double differencePercent,
    required List<CategoryYearComparisonRow> comparisons,
  }) {
    String fmt(double value) => currency.formatAmount(value.abs());

    if (filter.isOverview) {
      if (totalLastYear > 0 || totalThisYear > 0) {
        if (difference.abs() >= 1) {
          if (difference > 0) {
            return 'You spent ${fmt(difference)} more than last year.';
          }
          return 'You spent ${fmt(difference)} less than last year.';
        }
      }
    } else {
      final row = comparisons.firstWhere(
        (r) => r.category == filter,
        orElse: () => CategoryYearComparisonRow(
          category: filter,
          currentAmount: totalThisYear,
          lastYearAmount: totalLastYear,
          deltaAmount: difference,
          deltaPercent: differencePercent,
        ),
      );

      if (row.lastYearAmount <= 0 && row.currentAmount > 0) {
        return '${filter.label} is a new spending category this year.';
      }
      if (row.deltaAmount.abs() >= 1) {
        if (row.deltaPercent.abs() >= 1) {
          final direction = row.deltaAmount > 0 ? 'increased' : 'reduced';
          return '${filter.label} spending $direction by '
              '${row.deltaPercent.abs().toStringAsFixed(0)}%.';
        }
        if (row.deltaAmount > 0) {
          return '${filter.label} spending increased by ${fmt(row.deltaAmount)}.';
        }
        return '${filter.label} expenses reduced by ${fmt(row.deltaAmount)}.';
      }
    }

    final notable = comparisons
        .where((row) => row.deltaAmount.abs() >= 1)
        .toList()
      ..sort((a, b) => b.deltaAmount.abs().compareTo(a.deltaAmount.abs()));

    if (notable.isNotEmpty) {
      final top = notable.first;
      if (top.deltaAmount > 0) {
        if (top.deltaPercent.abs() >= 1) {
          return '${top.category.label} spending increased by '
              '${top.deltaPercent.abs().toStringAsFixed(0)}%.';
        }
        return '${top.category.label} spending increased by '
            '${fmt(top.deltaAmount)}.';
      }
      if (top.deltaPercent.abs() >= 1) {
        return '${top.category.label} expenses reduced by '
            '${top.deltaPercent.abs().toStringAsFixed(0)}%.';
      }
      return '${top.category.label} expenses reduced by '
          '${fmt(top.deltaAmount)}.';
    }

    if (totalThisYear > 0) {
      return 'You spent ${fmt(totalThisYear)} this year so far.';
    }
    return 'Start completing paid reminders to unlock spending insights.';
  }

  static String _breakdownInsight(List<CategorySpendingSlice> breakdown) {
    if (breakdown.length < 2) {
      if (breakdown.isEmpty) {
        return 'Complete paid reminders to see where your money goes.';
      }
      final only = breakdown.first;
      return '${only.category.label} accounts for '
          '${only.percentage.toStringAsFixed(0)}% of your spending.';
    }

    final topTwo = breakdown.take(2).toList();
    final combined =
        topTwo.fold<double>(0, (sum, slice) => sum + slice.percentage);
    return '${topTwo[0].category.label} and ${topTwo[1].category.label} '
        'account for ${combined.toStringAsFixed(0)}% of your total spending.';
  }
}
