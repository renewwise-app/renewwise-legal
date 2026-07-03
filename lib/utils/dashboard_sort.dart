import 'package:renew_wise/models/renewal.dart';

enum DashboardSortOption {
  nearestFirst('Nearest First'),
  farthestFirst('Farthest First'),
  highestAmount('Highest Amount'),
  lowestAmount('Lowest Amount'),
  highestPriority('Highest Priority'),
  category('Category'),
  recentlyAdded('Recently Added'),
  alphabetical('Alphabetical');

  const DashboardSortOption(this.label);
  final String label;
}

abstract final class DashboardSortUtils {
  static void sort(List<Renewal> list, DashboardSortOption option) {
    switch (option) {
      case DashboardSortOption.nearestFirst:
        list.sort((a, b) => a.renewalDate.compareTo(b.renewalDate));
      case DashboardSortOption.farthestFirst:
        list.sort((a, b) => b.renewalDate.compareTo(a.renewalDate));
      case DashboardSortOption.highestAmount:
        list.sort(
          (a, b) => (b.amount ?? 0).compareTo(a.amount ?? 0),
        );
      case DashboardSortOption.lowestAmount:
        list.sort(
          (a, b) => (a.amount ?? 0).compareTo(b.amount ?? 0),
        );
      case DashboardSortOption.highestPriority:
        list.sort((a, b) {
          final p = a.priority.index.compareTo(b.priority.index);
          return p != 0 ? p : a.renewalDate.compareTo(b.renewalDate);
        });
      case DashboardSortOption.category:
        list.sort((a, b) {
          final c = a.categoryLabel.compareTo(b.categoryLabel);
          return c != 0 ? c : a.renewalDate.compareTo(b.renewalDate);
        });
      case DashboardSortOption.recentlyAdded:
        list.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case DashboardSortOption.alphabetical:
        list.sort(
          (a, b) =>
              a.title.toLowerCase().compareTo(b.title.toLowerCase()),
        );
    }
  }
}
