import 'package:flutter_test/flutter_test.dart';

import 'package:renew_wise/models/history_entry.dart';
import 'package:renew_wise/models/renewal_category.dart';
import 'package:renew_wise/utils/history_filter.dart';
import 'package:renew_wise/utils/history_list_utils.dart';
import 'package:renew_wise/utils/history_sort.dart';
import 'package:renew_wise/utils/history_stats.dart';

HistoryEntry _entry({
  required String id,
  required String title,
  required DateTime completed,
  RenewalCategory category = RenewalCategory.insurance,
}) {
  return HistoryEntry(
    id: id,
    renewalId: 'r_$id',
    title: title,
    categoryLabel: category.label,
    category: category,
    completionDate: completed,
    completionMethod: 'app',
    originalRenewalDate: completed,
  );
}

void main() {
  final now = DateTime.now();

  test('HistoryListUtils search matches title and notes', () {
    final entry = _entry(
      id: '1',
      title: 'Passport Renewal',
      completed: now,
    ).copyWith(notes: 'urgent travel');
    expect(HistoryListUtils.matchesSearch(entry, 'passport'), isTrue);
    expect(HistoryListUtils.matchesSearch(entry, 'travel'), isTrue);
    expect(HistoryListUtils.matchesSearch(entry, 'electricity'), isFalse);
  });

  test('HistorySortUtils sorts newest first', () {
    final entries = [
      _entry(id: '1', title: 'A', completed: now.subtract(const Duration(days: 2))),
      _entry(id: '2', title: 'B', completed: now),
    ];
    HistorySortUtils.sort(entries, HistorySortOption.newestFirst);
    expect(entries.first.id, '2');
  });

  test('HistoryListUtils groups by year month day', () {
    final entries = [
      _entry(
        id: '1',
        title: 'Morning',
        completed: DateTime(now.year, now.month, now.day, 10, 30),
      ),
      _entry(
        id: '2',
        title: 'Afternoon',
        completed: DateTime(now.year, now.month, now.day, 14, 15),
      ),
    ];
    final rows = HistoryListUtils.buildGroupedRows(
      entries: entries,
      collapsedKeys: {},
    );
    expect(rows.where((r) => r.kind == HistoryListRowKind.entry).length, 2);
    expect(rows.any((r) => r.kind == HistoryListRowKind.year), isTrue);
  });

  test('HistoryStatsCalculator computes completion rate', () {
    final history = [
      _entry(id: '1', title: 'A', completed: now),
    ];
    final stats = HistoryStatsCalculator.compute(
      history: history,
      activeEventCount: 3,
    );
    expect(stats.completedThisMonth, 1);
    expect(stats.completionRate, closeTo(25, 0.1));
  });

  test('HistoryFilterUtils matches completed today', () {
    final entry = _entry(id: '1', title: 'Today', completed: now);
    expect(
      HistoryFilterUtils.matchesFilter(entry, HistoryFilter.completedToday),
      isTrue,
    );
  });
}
