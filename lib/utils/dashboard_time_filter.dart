import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/utils/date_utils.dart';

/// Time windows for dashboard list screens.
enum DashboardTimeFilter {
  all('All'),
  today('Today'),
  thisWeek('This Week'),
  thisMonth('This Month'),
  specificMonth('Month'),
  specificYear('Year');

  const DashboardTimeFilter(this.label);
  final String label;
}

/// Applies [DashboardTimeFilter] to renewals by [Renewal.renewalDate].
abstract final class DashboardTimeFilterUtils {
  static DateTime _today() => RenewalDateUtils.dateOnly(DateTime.now());

  static bool matches(
    Renewal renewal, {
    required DashboardTimeFilter filter,
    int? year,
    int? month,
  }) {
    if (filter == DashboardTimeFilter.all) return true;

    final date = RenewalDateUtils.dateOnly(renewal.renewalDate);
    final now = _today();

    switch (filter) {
      case DashboardTimeFilter.all:
        return true;
      case DashboardTimeFilter.today:
        return date == now;
      case DashboardTimeFilter.thisWeek:
        final start = now.subtract(Duration(days: now.weekday - 1));
        final end = start.add(const Duration(days: 6));
        return !date.isBefore(start) && !date.isAfter(end);
      case DashboardTimeFilter.thisMonth:
        return date.year == now.year && date.month == now.month;
      case DashboardTimeFilter.specificMonth:
        final y = year ?? now.year;
        final m = month ?? now.month;
        return date.year == y && date.month == m;
      case DashboardTimeFilter.specificYear:
        final y = year ?? now.year;
        return date.year == y;
    }
  }

  static String filterDescription({
    required DashboardTimeFilter filter,
    int? year,
    int? month,
  }) {
    final now = _today();
    switch (filter) {
      case DashboardTimeFilter.all:
        return 'All';
      case DashboardTimeFilter.today:
        return 'Today';
      case DashboardTimeFilter.thisWeek:
        return 'This Week';
      case DashboardTimeFilter.thisMonth:
        return '${RenewalDateUtils.monthName(now.month)} ${now.year}';
      case DashboardTimeFilter.specificMonth:
        final y = year ?? now.year;
        final m = month ?? now.month;
        return '${RenewalDateUtils.monthName(m)} $y';
      case DashboardTimeFilter.specificYear:
        return '${year ?? now.year}';
    }
  }
}
