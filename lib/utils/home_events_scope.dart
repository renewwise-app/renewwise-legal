import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/models/renewal_currency.dart';
import 'package:renew_wise/models/renewal_priority.dart';
import 'package:renew_wise/models/renewal_status.dart';
import 'package:renew_wise/services/renewal_service.dart';
import 'package:renew_wise/utils/dashboard_list_utils.dart';
import 'package:renew_wise/utils/dashboard_time_filter.dart';
import 'package:renew_wise/utils/date_utils.dart';

/// Home dashboard period scopes for summary cards and event list screens.
enum HomeEventsScope {
  today,
  thisWeek,
  thisMonth,
  customRange,
}

/// Secondary filters for home event list screens.
enum HomeEventsListFilter {
  all('All'),
  highPriority('High Priority'),
  overdue('Overdue'),
  withPayment('With Payment');

  const HomeEventsListFilter(this.label);
  final String label;
}

class HomePeriodSummary {
  const HomePeriodSummary({
    required this.eventCount,
    required this.dueTotal,
    required this.highPriorityCount,
  });

  final int eventCount;
  final double dueTotal;
  final int highPriorityCount;

  String subtitle(RenewalCurrency currency) {
    final lines = <String>[
      '$eventCount Event${eventCount == 1 ? '' : 's'}',
    ];

    if (dueTotal > 0) {
      lines.add('${currency.formatAmount(dueTotal)} Due');
    }

    if (highPriorityCount > 0) {
      lines.add(
        '$highPriorityCount High Priorit${highPriorityCount == 1 ? 'y' : 'ies'}',
      );
    }

    return lines.join('\n');
  }
}

abstract final class HomeEventsScopeUtils {
  static List<Renewal> activeRenewals(RenewalService service) =>
      service.renewals
          .where(
            (r) =>
                r.status != RenewalStatus.cancelled &&
                r.status != RenewalStatus.paid,
          )
          .toList();

  static List<Renewal> scopedRenewals(
    RenewalService service, {
    required HomeEventsScope scope,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    final active = activeRenewals(service);
    final list = switch (scope) {
      HomeEventsScope.today => active.where(_matchesTodayScope),
      HomeEventsScope.thisWeek => active.where(
          (r) => DashboardTimeFilterUtils.matches(
            r,
            filter: DashboardTimeFilter.thisWeek,
          ),
        ),
      HomeEventsScope.thisMonth => active.where(
          (r) => DashboardTimeFilterUtils.matches(
            r,
            filter: DashboardTimeFilter.thisMonth,
          ),
        ),
      HomeEventsScope.customRange => active.where(
          (r) => _inCustomRange(r, fromDate, toDate),
        ),
    };

    final sorted = list.toList()
      ..sort((a, b) => a.renewalDate.compareTo(b.renewalDate));
    return sorted;
  }

  static HomePeriodSummary summarize(List<Renewal> renewals) {
    final highPriority = renewals.where(
      (r) =>
          r.priority == RenewalPriority.high ||
          r.priority == RenewalPriority.critical,
    ).length;

    return HomePeriodSummary(
      eventCount: renewals.length,
      dueTotal: DashboardListUtils.totalAmount(renewals),
      highPriorityCount: highPriority,
    );
  }

  static HomePeriodSummary summarizeScope(
    RenewalService service, {
    required HomeEventsScope scope,
    DateTime? fromDate,
    DateTime? toDate,
  }) {
    return summarize(
      scopedRenewals(
        service,
        scope: scope,
        fromDate: fromDate,
        toDate: toDate,
      ),
    );
  }

  static bool _matchesTodayScope(Renewal renewal) =>
      renewal.isOverdue || renewal.daysRemaining == 0;

  static bool _inCustomRange(
    Renewal renewal,
    DateTime? fromDate,
    DateTime? toDate,
  ) {
    if (fromDate == null || toDate == null) return false;

    final date = RenewalDateUtils.dateOnly(renewal.renewalDate);
    final start = RenewalDateUtils.dateOnly(fromDate);
    final end = RenewalDateUtils.dateOnly(toDate);
    if (start.isAfter(end)) return false;
    return !date.isBefore(start) && !date.isAfter(end);
  }

  static bool matchesListFilter(Renewal renewal, HomeEventsListFilter filter) {
    switch (filter) {
      case HomeEventsListFilter.all:
        return true;
      case HomeEventsListFilter.highPriority:
        return renewal.priority == RenewalPriority.high ||
            renewal.priority == RenewalPriority.critical;
      case HomeEventsListFilter.overdue:
        return renewal.isOverdue;
      case HomeEventsListFilter.withPayment:
        return renewal.paymentRequired && renewal.amount != null;
    }
  }
}
