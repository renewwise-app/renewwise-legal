import 'package:renew_wise/models/history_entry.dart';
import 'package:renew_wise/utils/date_utils.dart';

/// History dashboard scopes — mirror of [HomeEventsScope] for completed items.
enum HistoryEventsScope {
  completedToday,
  completedThisWeek,
  completedThisMonth,
  customPeriod,
}

class HistoryPeriodSummary {
  const HistoryPeriodSummary({required this.completedCount});

  final int completedCount;

  String get completedLabel {
    final count = completedCount;
    return '$count reminder${count == 1 ? '' : 's'} completed';
  }
}

abstract final class HistoryEventsScopeUtils {
  static DateTime _today() => RenewalDateUtils.dateOnly(DateTime.now());

  static List<HistoryEntry> scopedEntries(
    List<HistoryEntry> source, {
    required HistoryEventsScope scope,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    final list = source.where((entry) {
      final date = RenewalDateUtils.dateOnly(entry.completionDate);
      return switch (scope) {
        HistoryEventsScope.completedToday => _matchesToday(date),
        HistoryEventsScope.completedThisWeek => _matchesThisWeek(date),
        HistoryEventsScope.completedThisMonth => _matchesThisMonth(date),
        HistoryEventsScope.customPeriod =>
          _inCustomRange(date, fromDate, toDate),
      };
    }).toList();

    list.sort((a, b) => b.completionDate.compareTo(a.completionDate));
    return list;
  }

  static HistoryPeriodSummary summarize(List<HistoryEntry> entries) {
    return HistoryPeriodSummary(completedCount: entries.length);
  }

  static HistoryPeriodSummary summarizeScope(
    List<HistoryEntry> source, {
    required HistoryEventsScope scope,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return summarize(
      scopedEntries(
        source,
        scope: scope,
        fromDate: fromDate,
        toDate: toDate,
      ),
    );
  }

  static bool _matchesToday(DateTime date) => date == _today();

  static bool _matchesThisWeek(DateTime date) {
    final now = _today();
    final start = now.subtract(Duration(days: now.weekday - 1));
    final end = start.add(const Duration(days: 6));
    return !date.isBefore(start) && !date.isAfter(end);
  }

  static bool _matchesThisMonth(DateTime date) {
    final now = _today();
    return date.year == now.year && date.month == now.month;
  }

  static bool _inCustomRange(
    DateTime date,
    DateTime? fromDate,
    DateTime? toDate,
  ) {
    if (fromDate == null || toDate == null) return false;
    final start = RenewalDateUtils.dateOnly(fromDate);
    final end = RenewalDateUtils.dateOnly(toDate);
    if (start.isAfter(end)) return false;
    return !date.isBefore(start) && !date.isAfter(end);
  }
}
