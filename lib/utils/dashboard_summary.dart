import 'package:renew_wise/services/renewal_service.dart';



/// Picks the most relevant one-line summary for the home dashboard.

abstract final class DashboardSummaryText {

  static String forHome(RenewalService service) {

    final criticalToday = service.criticalTodayCount;

    if (criticalToday > 0) {

      return criticalToday == 1

          ? 'You have 1 critical reminder today.'

          : 'You have $criticalToday critical reminders today.';

    }



    final hasUrgent =

        service.criticalRenewals.isNotEmpty || service.overdueCount > 0;



    if (!hasUrgent) {

      if (service.dueThisMonthTotal > 0) {

        return '${service.primaryCurrency.formatAmount(service.dueThisMonthTotal)} is due this month.';

      }

      if (service.upcomingCount == 0) {

        return "You're all caught up.";

      }

      return "You're all caught up for today.";

    }



    if (service.dueThisMonthTotal > 0) {

      return '${service.primaryCurrency.formatAmount(service.dueThisMonthTotal)} is due this month.';

    }



    return "You're all caught up for today.";

  }

}

