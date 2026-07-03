import 'package:flutter/material.dart';

import 'package:renew_wise/models/history_entry.dart';
import 'package:renew_wise/models/renewal_category.dart';
import 'package:renew_wise/models/renewal_currency.dart';

/// Category tabs for Life Insights 2.0 (Package 5B).
enum SpendingInsightCategory {
  allOverview('All Overview', Icons.dashboard_outlined),
  insurance('Insurance', Icons.shield_outlined),
  vehicle('Vehicle', Icons.directions_car_outlined),
  subscriptions('Subscriptions', Icons.subscriptions_outlined),
  medical('Medical', Icons.medical_services_outlined),
  shopping('Shopping', Icons.shopping_bag_outlined),
  emi('EMI', Icons.account_balance_outlined),
  utilities('Utilities', Icons.bolt_outlined),
  others('Others', Icons.category_outlined);

  const SpendingInsightCategory(this.label, this.icon);

  final String label;
  final IconData icon;

  bool get isOverview => this == allOverview;

  static SpendingInsightCategory fromRenewalCategory(RenewalCategory category) {
    return switch (category) {
      RenewalCategory.insurance => insurance,
      RenewalCategory.vehicle || RenewalCategory.drivingLicence => vehicle,
      RenewalCategory.subscription ||
      RenewalCategory.gym ||
      RenewalCategory.internet =>
        subscriptions,
      RenewalCategory.warranty => medical,
      RenewalCategory.creditCard => shopping,
      RenewalCategory.loanEmi => emi,
      RenewalCategory.electricity ||
      RenewalCategory.water ||
      RenewalCategory.gas =>
        utilities,
      _ => others,
    };
  }

  static const filterTabs = [
    insurance,
    vehicle,
    subscriptions,
    medical,
    shopping,
    emi,
    utilities,
    others,
  ];
}

class CategorySpendingSlice {
  const CategorySpendingSlice({
    required this.category,
    required this.amount,
    required this.percentage,
    required this.color,
  });

  final SpendingInsightCategory category;
  final double amount;
  final double percentage;
  final Color color;
}

class CategoryYearComparisonRow {
  const CategoryYearComparisonRow({
    required this.category,
    required this.currentAmount,
    required this.lastYearAmount,
    required this.deltaAmount,
    required this.deltaPercent,
  });

  final SpendingInsightCategory category;
  final double currentAmount;
  final double lastYearAmount;
  final double deltaAmount;
  final double deltaPercent;

  bool get isIncrease => deltaAmount > 0;
  bool get isUnchanged => deltaAmount == 0;
}

class CategoryChangeRank {
  const CategoryChangeRank({
    required this.category,
    required this.deltaAmount,
  });

  final SpendingInsightCategory category;
  final double deltaAmount;
}

class NewExpenseInsight {
  const NewExpenseInsight({
    required this.title,
    required this.amount,
    required this.category,
  });

  final String title;
  final double amount;
  final SpendingInsightCategory category;
}

class SpendingInsightsSnapshot {
  const SpendingInsightsSnapshot({
    required this.year,
    required this.previousYear,
    required this.currency,
    required this.filter,
    required this.headlineInsight,
    required this.totalSpentThisYear,
    required this.totalSpentLastYear,
    required this.differenceAmount,
    required this.differencePercent,
    required this.categoryBreakdown,
    required this.breakdownInsight,
    required this.yearComparisons,
    required this.biggestIncreases,
    required this.biggestSavings,
    required this.newExpenses,
    required this.availableYears,
    required this.isEmpty,
  });

  final int year;
  final int previousYear;
  final RenewalCurrency currency;
  final SpendingInsightCategory filter;
  final String headlineInsight;
  final double totalSpentThisYear;
  final double totalSpentLastYear;
  final double differenceAmount;
  final double differencePercent;
  final List<CategorySpendingSlice> categoryBreakdown;
  final String breakdownInsight;
  final List<CategoryYearComparisonRow> yearComparisons;
  final List<CategoryChangeRank> biggestIncreases;
  final List<CategoryChangeRank> biggestSavings;
  final List<NewExpenseInsight> newExpenses;
  final List<int> availableYears;
  final bool isEmpty;

  int get newExpenseCount => newExpenses.length;
}

/// Paid spending row used internally by the engine.
class SpendingRecord {
  const SpendingRecord({
    required this.title,
    required this.category,
    required this.amount,
    required this.year,
    required this.entry,
  });

  final String title;
  final SpendingInsightCategory category;
  final double amount;
  final int year;
  final HistoryEntry entry;
}
