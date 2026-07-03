import 'package:renew_wise/models/history_entry.dart';
import 'package:renew_wise/utils/history_filter.dart';

abstract final class HistorySortUtils {
  static void sort(List<HistoryEntry> entries, HistorySortOption option) {
    switch (option) {
      case HistorySortOption.newestFirst:
      case HistorySortOption.completionDate:
        entries.sort((a, b) => b.completionDate.compareTo(a.completionDate));
      case HistorySortOption.oldestFirst:
        entries.sort((a, b) => a.completionDate.compareTo(b.completionDate));
      case HistorySortOption.alphabetical:
        entries.sort(
          (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
      case HistorySortOption.category:
        entries.sort((a, b) {
          final c = a.categoryLabel
              .toLowerCase()
              .compareTo(b.categoryLabel.toLowerCase());
          if (c != 0) return c;
          return b.completionDate.compareTo(a.completionDate);
        });
    }
  }
}
