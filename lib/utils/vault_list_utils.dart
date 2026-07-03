import 'package:renew_wise/models/event_document.dart';
import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/models/vault_document_category.dart';

abstract final class VaultListUtils {
  static bool matchesSearch(
    EventDocument doc,
    String query, {
    Map<String, Renewal>? renewalsById,
  }) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;

    final parts = <String>[
      doc.name,
      doc.categoryLabel,
      doc.notes ?? '',
      ...doc.tags,
      doc.ocrText ?? '',
    ];

    if (renewalsById != null) {
      for (final id in doc.linkedRenewalIds) {
        final r = renewalsById[id];
        if (r != null) {
          parts.add(r.title);
          parts.add(r.categoryLabel);
        }
      }
    }

    return parts.any((p) => p.toLowerCase().contains(q));
  }

  static bool matchesFilter(
    EventDocument doc,
    VaultFilterKind filter, {
    VaultDocumentCategory? category,
  }) {
    if (category != null && doc.category != category) return false;

    return switch (filter) {
      VaultFilterKind.all => true,
      VaultFilterKind.images => doc.resolvedFileType == VaultFileType.image,
      VaultFilterKind.pdf => doc.resolvedFileType == VaultFileType.pdf,
      VaultFilterKind.documents =>
        doc.resolvedFileType == VaultFileType.document,
      VaultFilterKind.linked => doc.isLinked,
      VaultFilterKind.unlinked => !doc.isLinked,
    };
  }

  static void sortList(List<EventDocument> list, VaultSortOption option) {
    switch (option) {
      case VaultSortOption.newest:
        list.sort(
          (a, b) => (b.addedAt ?? DateTime(0))
              .compareTo(a.addedAt ?? DateTime(0)),
        );
      case VaultSortOption.oldest:
        list.sort(
          (a, b) => (a.addedAt ?? DateTime(0))
              .compareTo(b.addedAt ?? DateTime(0)),
        );
      case VaultSortOption.alphabetical:
        list.sort(
          (a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()),
        );
      case VaultSortOption.category:
        list.sort((a, b) {
          final c = a.categoryLabel.compareTo(b.categoryLabel);
          return c != 0 ? c : a.name.compareTo(b.name);
        });
      case VaultSortOption.size:
        list.sort((a, b) => b.sizeBytes.compareTo(a.sizeBytes));
      case VaultSortOption.recentlyViewed:
        list.sort((a, b) {
          final av = a.lastViewedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bv = b.lastViewedAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bv.compareTo(av);
        });
    }
  }

  static List<EventDocument> apply({
    required List<EventDocument> source,
    required String query,
    required VaultFilterKind filter,
    required VaultSortOption sort,
    VaultDocumentCategory? category,
    Map<String, Renewal>? renewalsById,
  }) {
    final list = source
        .where((d) => matchesFilter(d, filter, category: category))
        .where((d) => matchesSearch(d, query, renewalsById: renewalsById))
        .toList();
    sortList(list, sort);
    return list;
  }

  static String formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) {
      return '${(bytes / 1024).toStringAsFixed(1)} KB';
    }
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }
}
