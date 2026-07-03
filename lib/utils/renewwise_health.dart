import 'package:flutter/material.dart';

import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/services/event_extras_service.dart';
import 'package:renew_wise/services/renewal_service.dart';

enum HealthIssueKind {
  missingDocuments('Events Missing Documents', Icons.description_outlined),
  missingAmounts('Events Missing Amounts', Icons.payments_outlined),
  missingNotes('Events Missing Notes', Icons.notes_outlined),
  overdue('Overdue Events', Icons.warning_amber_rounded),
  duplicates('Duplicate Events', Icons.copy_all_outlined);

  const HealthIssueKind(this.label, this.icon);
  final String label;
  final IconData icon;
}

class HealthReport {
  const HealthReport({
    required this.missingDocuments,
    required this.missingAmounts,
    required this.missingNotes,
    required this.overdue,
    required this.duplicates,
  });

  final int missingDocuments;
  final int missingAmounts;
  final int missingNotes;
  final int overdue;
  final int duplicates;

  int countFor(HealthIssueKind kind) => switch (kind) {
        HealthIssueKind.missingDocuments => missingDocuments,
        HealthIssueKind.missingAmounts => missingAmounts,
        HealthIssueKind.missingNotes => missingNotes,
        HealthIssueKind.overdue => overdue,
        HealthIssueKind.duplicates => duplicates,
      };

  bool get isHealthy =>
      missingDocuments == 0 &&
      missingAmounts == 0 &&
      missingNotes == 0 &&
      overdue == 0 &&
      duplicates == 0;

  int get totalIssues =>
      missingDocuments +
      missingAmounts +
      missingNotes +
      overdue +
      duplicates;
}

abstract final class RenewWiseHealth {
  static HealthReport compute(
    RenewalService service,
    EventExtrasService extras,
  ) {
    final renewals = service.renewals;
    var missingDocs = 0;
    var missingAmounts = 0;
    var missingNotes = 0;
    var overdue = 0;

    for (final r in renewals) {
      if (extras.documentsFor(r.id).isEmpty) missingDocs++;
      if (r.paymentRequired && (r.amount == null || r.amount! <= 0)) {
        missingAmounts++;
      }
      if (r.notes == null || r.notes!.trim().isEmpty) missingNotes++;
      if (r.isOverdue) overdue++;
    }

    return HealthReport(
      missingDocuments: missingDocs,
      missingAmounts: missingAmounts,
      missingNotes: missingNotes,
      overdue: overdue,
      duplicates: duplicateCount(renewals),
    );
  }

  static int duplicateCount(List<Renewal> renewals) {
    return duplicateGroups(renewals).length;
  }

  static Map<String, List<Renewal>> duplicateGroups(List<Renewal> renewals) {
    final map = <String, List<Renewal>>{};
    for (final r in renewals) {
      final key = _normalizeTitle(r.title);
      map.putIfAbsent(key, () => []).add(r);
    }
    return Map.fromEntries(
      map.entries.where((e) => e.value.length > 1),
    );
  }

  static List<Renewal> filter(
    List<Renewal> renewals,
    HealthIssueKind kind,
    EventExtrasService extras,
  ) {
    return switch (kind) {
      HealthIssueKind.missingDocuments =>
        renewals.where((r) => extras.documentsFor(r.id).isEmpty).toList(),
      HealthIssueKind.missingAmounts => renewals
          .where(
            (r) =>
                r.paymentRequired && (r.amount == null || r.amount! <= 0),
          )
          .toList(),
      HealthIssueKind.missingNotes => renewals
          .where((r) => r.notes == null || r.notes!.trim().isEmpty)
          .toList(),
      HealthIssueKind.overdue =>
        renewals.where((r) => r.isOverdue).toList(),
      HealthIssueKind.duplicates => duplicateGroups(renewals)
          .values
          .expand((group) => group)
          .toList(),
    };
  }

  static String _normalizeTitle(String title) {
    return title
        .toLowerCase()
        .replaceAll(
          RegExp(r'\[demo\]|\[test\]|\(copy\)', caseSensitive: false),
          '',
        )
        .replaceAll(RegExp(r'[^a-z0-9]+'), ' ')
        .trim();
  }
}
