import 'package:renew_wise/models/history_entry.dart';
import 'package:renew_wise/models/renewal_category.dart';

enum HistoryMonthSelector {
  all('All'),
  thisMonth('This Month'),
  lastMonth('Last Month'),
  january('January', 1),
  february('February', 2),
  march('March', 3),
  april('April', 4),
  may('May', 5),
  june('June', 6),
  july('July', 7),
  august('August', 8),
  september('September', 9),
  october('October', 10),
  november('November', 11),
  december('December', 12);

  const HistoryMonthSelector(this.label, [this.monthNumber]);

  final String label;
  final int? monthNumber;
}

enum HistoryFilter {
  all('All'),
  completedToday('Completed Today'),
  completedThisWeek('Completed This Week'),
  completedThisMonth('Completed This Month'),
  byCategory('By Category'),
  byYear('By Year');

  const HistoryFilter(this.label);
  final String label;
}

enum HistorySortOption {
  newestFirst('Newest First'),
  oldestFirst('Oldest First'),
  alphabetical('Alphabetical'),
  category('Category'),
  completionDate('Completion Date');

  const HistorySortOption(this.label);
  final String label;
}

abstract final class HistoryFilterUtils {
  static bool matchesMonthSelector(
    HistoryEntry entry,
    HistoryMonthSelector selector, {
    int? selectedYear,
  }) {
    final d = entry.completionDate;
    final now = DateTime.now();
    return switch (selector) {
      HistoryMonthSelector.all => true,
      HistoryMonthSelector.thisMonth =>
        d.year == now.year && d.month == now.month,
      HistoryMonthSelector.lastMonth => () {
          final lm = DateTime(now.year, now.month - 1);
          return d.year == lm.year && d.month == lm.month;
        }(),
      _ when selector.monthNumber != null =>
        d.month == selector.monthNumber &&
            (selectedYear == null || d.year == selectedYear),
      _ => true,
    };
  }

  static bool matchesFilter(
    HistoryEntry entry,
    HistoryFilter filter, {
    RenewalCategory? category,
    int? year,
  }) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final d = entry.completionDate;
    final day = DateTime(d.year, d.month, d.day);

    return switch (filter) {
      HistoryFilter.all => true,
      HistoryFilter.completedToday => day == today,
      HistoryFilter.completedThisWeek =>
        day.isAfter(today.subtract(const Duration(days: 7))) ||
            day == today,
      HistoryFilter.completedThisMonth =>
        d.year == now.year && d.month == now.month,
      HistoryFilter.byCategory =>
        category != null && entry.category == category,
      HistoryFilter.byYear => year == null || d.year == year,
    };
  }
}
