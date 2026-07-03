import 'package:renew_wise/models/history_entry.dart';

/// Sort options for completed history list screens (Packet 5A).
enum HistoryCompletedSortOption {
  completionDate('Completion Date'),
  amount('Amount');

  const HistoryCompletedSortOption(this.label);
  final String label;
}

abstract final class HistoryCompletedSortUtils {
  static void sort(List<HistoryEntry> entries, HistoryCompletedSortOption option) {
    switch (option) {
      case HistoryCompletedSortOption.completionDate:
        entries.sort((a, b) => b.completionDate.compareTo(a.completionDate));
      case HistoryCompletedSortOption.amount:
        entries.sort((a, b) {
          final amount = (b.amount ?? 0).compareTo(a.amount ?? 0);
          if (amount != 0) return amount;
          return b.completionDate.compareTo(a.completionDate);
        });
    }
  }
}
