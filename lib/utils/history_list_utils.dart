import 'package:renew_wise/models/history_entry.dart';
import 'package:renew_wise/models/renewal_category.dart';
import 'package:renew_wise/utils/history_filter.dart';
import 'package:renew_wise/utils/history_sort.dart';

enum HistoryListRowKind { year, month, day, entry }

class HistoryListRow {
  const HistoryListRow({
    required this.kind,
    this.entry,
    this.year,
    this.month,
    this.day,
    this.key = '',
  });

  final HistoryListRowKind kind;
  final HistoryEntry? entry;
  final int? year;
  final int? month;
  final int? day;
  final String key;
}

abstract final class HistoryListUtils {
  /// Instant search across title, category, notes. Documents reserved for future.
  static bool matchesSearch(HistoryEntry entry, String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return entry.title.toLowerCase().contains(q) ||
        entry.categoryLabel.toLowerCase().contains(q) ||
        entry.category.label.toLowerCase().contains(q) ||
        (entry.notes?.toLowerCase().contains(q) ?? false) ||
        (entry.customEventType?.toLowerCase().contains(q) ?? false);
  }

  static List<HistoryEntry> apply({
    required List<HistoryEntry> source,
    required HistoryMonthSelector monthSelector,
    required HistoryFilter filter,
    required HistorySortOption sort,
    required String searchQuery,
    int? selectedYear,
    RenewalCategory? filterCategory,
  }) {
    final list = source
        .where(
          (e) => HistoryFilterUtils.matchesMonthSelector(
            e,
            monthSelector,
            selectedYear: selectedYear,
          ),
        )
        .where(
          (e) => HistoryFilterUtils.matchesFilter(
            e,
            filter,
            category: filterCategory,
            year: selectedYear,
          ),
        )
        .where((e) => matchesSearch(e, searchQuery))
        .toList();
    HistorySortUtils.sort(list, sort);
    return list;
  }

  static Set<int> availableYears(List<HistoryEntry> entries) {
    final years = entries.map((e) => e.completionDate.year).toSet();
    years.add(DateTime.now().year);
    return years;
  }

  static List<HistoryListRow> buildGroupedRows({
    required List<HistoryEntry> entries,
    required Set<String> collapsedKeys,
  }) {
    if (entries.isEmpty) return const [];

    final sorted = List<HistoryEntry>.from(entries);
    HistorySortUtils.sort(sorted, HistorySortOption.newestFirst);

    final rows = <HistoryListRow>[];
    int? currentYear;
    int? currentMonth;
    int? currentDay;

    for (final entry in sorted) {
      final d = entry.completionDate;
      if (currentYear != d.year) {
        currentYear = d.year;
        currentMonth = null;
        currentDay = null;
        rows.add(
          HistoryListRow(
            kind: HistoryListRowKind.year,
            year: d.year,
            key: 'y-$currentYear',
          ),
        );
      }
      if (currentMonth != d.month) {
        currentMonth = d.month;
        currentDay = null;
        final monthKey = 'y-$currentYear-m-$currentMonth';
        if (!collapsedKeys.contains('y-$currentYear')) {
          rows.add(
            HistoryListRow(
              kind: HistoryListRowKind.month,
              year: currentYear,
              month: currentMonth,
              key: monthKey,
            ),
          );
        }
      }
      if (currentDay != d.day) {
        currentDay = d.day;
        final dayKey = 'y-$currentYear-m-$currentMonth-d-$currentDay';
        if (!collapsedKeys.contains('y-$currentYear') &&
            !collapsedKeys.contains('y-$currentYear-m-$currentMonth')) {
          rows.add(
            HistoryListRow(
              kind: HistoryListRowKind.day,
              year: currentYear,
              month: currentMonth,
              day: currentDay,
              key: dayKey,
            ),
          );
        }
      }
      if (!collapsedKeys.contains('y-$currentYear') &&
          !collapsedKeys.contains('y-$currentYear-m-$currentMonth')) {
        rows.add(
          HistoryListRow(
            kind: HistoryListRowKind.entry,
            entry: entry,
            key: entry.id,
          ),
        );
      }
    }
    return rows;
  }
}
