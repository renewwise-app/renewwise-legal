import 'package:renew_wise/models/history_entry.dart';
import 'package:renew_wise/models/renewal_category.dart';

/// Filters for completed history list screens (Packet 5A).
enum HistoryCompletedFilter {
  all('All'),
  paymentRequired('Payment Required'),
  noPayment('No Payment');

  const HistoryCompletedFilter(this.label);
  final String label;
}

abstract final class HistoryCompletedFilterUtils {
  static bool matchesCategory(HistoryEntry entry, RenewalCategory? category) {
    if (category == null) return true;
    return entry.category == category;
  }

  static bool matchesPaymentFilter(
    HistoryEntry entry,
    HistoryCompletedFilter filter,
  ) {
    return switch (filter) {
      HistoryCompletedFilter.all => true,
      HistoryCompletedFilter.paymentRequired =>
        entry.paymentRequired && entry.amount != null,
      HistoryCompletedFilter.noPayment =>
        !entry.paymentRequired || entry.amount == null,
    };
  }
}
