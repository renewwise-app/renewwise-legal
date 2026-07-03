import 'package:renew_wise/models/renewal.dart';

/// Sort options for Home event list screens (Packet 02.1).
enum EventListSortOption {
  dueSoonest('Due Soonest'),
  highestAmount('Highest Amount'),
  lowestAmount('Lowest Amount'),
  highestPriority('Highest Priority'),
  category('Category');

  const EventListSortOption(this.label);
  final String label;
}

abstract final class EventListSortUtils {
  static void sort(List<Renewal> list, EventListSortOption option) {
    switch (option) {
      case EventListSortOption.dueSoonest:
        list.sort((a, b) => a.renewalDate.compareTo(b.renewalDate));
      case EventListSortOption.highestAmount:
        list.sort((a, b) => (b.amount ?? 0).compareTo(a.amount ?? 0));
      case EventListSortOption.lowestAmount:
        list.sort((a, b) => (a.amount ?? 0).compareTo(b.amount ?? 0));
      case EventListSortOption.highestPriority:
        list.sort((a, b) {
          final p = a.priority.index.compareTo(b.priority.index);
          return p != 0 ? p : a.renewalDate.compareTo(b.renewalDate);
        });
      case EventListSortOption.category:
        list.sort((a, b) {
          final c = a.categoryLabel.compareTo(b.categoryLabel);
          return c != 0 ? c : a.renewalDate.compareTo(b.renewalDate);
        });
    }
  }
}
