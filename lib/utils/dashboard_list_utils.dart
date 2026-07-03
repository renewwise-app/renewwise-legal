import 'package:renew_wise/models/renewal.dart';

import 'package:renew_wise/models/renewal_currency.dart';
import 'package:renew_wise/models/sharing_models.dart';

import 'package:renew_wise/services/event_extras_service.dart';
import 'package:renew_wise/services/sharing_service.dart';

import 'package:renew_wise/utils/dashboard_sort.dart';

import 'package:renew_wise/utils/dashboard_time_filter.dart';



abstract final class DashboardListUtils {

  /// Search title, category, notes, tags, amount, documents, priority, status.

  static bool matchesSearch(

    Renewal renewal,

    String query, {

    EventExtrasService? eventExtras,
    SharingService? sharingService,
  }) {

    final q = query.trim().toLowerCase();

    if (q.isEmpty) return true;



    final haystack = <String>[

      renewal.title,

      renewal.categoryLabel,

      renewal.category.label,

      renewal.priority.label,

      renewal.status.label,

      renewal.repeatCycle.label,

      renewal.notes ?? '',

      renewal.customEventType ?? '',

      if (renewal.amount != null) renewal.amount!.toStringAsFixed(0),

      if (renewal.amount != null)

        renewal.currency.formatAmount(renewal.amount!),

    ];



    if (eventExtras != null) {

      for (final doc in eventExtras.documentsFor(renewal.id)) {

        haystack.add(doc.name);

      }

    }



    if (sharingService != null) {
      final meta = sharingService.metaFor(renewal.id);
      haystack.add(meta.ownerName);
      for (final m in meta.members) {
        haystack.add(m.displayName);
        if (m.email != null) haystack.add(m.email!);
      }
      haystack.add(meta.visibility.label);
    }

    return haystack.any((part) => part.toLowerCase().contains(q));

  }



  static List<Renewal> apply({

    required List<Renewal> source,

    required DashboardTimeFilter filter,

    required DashboardSortOption sort,

    required String searchQuery,

    int? year,

    int? month,

    EventExtrasService? eventExtras,
    SharingService? sharingService,
    SharingListFilter sharingFilter = SharingListFilter.all,
  }) {
    final list = source
        .where(
          (r) => DashboardTimeFilterUtils.matches(
            r,
            filter: filter,
            year: year,
            month: month,
          ),
        )
        .where(
          (r) => matchesSearch(
            r,
            searchQuery,
            eventExtras: eventExtras,
            sharingService: sharingService,
          ),
        );

    final filtered = sharingService == null ||
            sharingFilter == SharingListFilter.all
        ? list.toList()
        : sharingService.filterRenewals(list.toList(), sharingFilter);

    DashboardSortUtils.sort(filtered, sort);
    return filtered;
  }



  static double totalAmount(List<Renewal> renewals) {

    return renewals.fold<double>(

      0,

      (sum, r) =>

          sum + ((r.paymentRequired && r.amount != null) ? r.amount! : 0),

    );

  }



  static String formatTotal(List<Renewal> renewals, RenewalCurrency currency) {

    return currency.formatAmount(totalAmount(renewals));

  }

}

