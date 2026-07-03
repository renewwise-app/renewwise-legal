import 'package:flutter/material.dart';

import 'package:renew_wise/services/event_extras_service.dart';
import 'package:renew_wise/services/renewal_service.dart';
import 'package:renew_wise/widgets/common/app_empty_state.dart';

/// Pick events to link an existing vault document to.
abstract final class VaultLinkPicker {
  static Future<void> show(
    BuildContext context, {
    required EventExtrasService eventExtrasService,
    required RenewalService renewalService,
    required String documentId,
    String? excludeRenewalId,
  }) {
    final doc = eventExtrasService.documentById(documentId);
    if (doc == null) return Future.value();

    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        final renewals = renewalService.renewals
            .where((r) => r.id != excludeRenewalId)
            .toList();
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.55,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          builder: (_, scrollCtrl) {
            return ListenableBuilder(
              listenable: eventExtrasService,
              builder: (_, _) {
                final linked = eventExtrasService
                        .documentById(documentId)
                        ?.linkedRenewalIds ??
                    const [];
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Link to Event',
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    Expanded(
                      child: renewals.isEmpty
                          ? const AppEmptyState(
                              icon: Icons.event_note_outlined,
                              title: 'No reminders yet',
                              subtitle:
                                  'Add a reminder first, then link documents to it.',
                            )
                          : ListView.builder(
                              controller: scrollCtrl,
                              itemCount: renewals.length,
                              itemBuilder: (_, i) {
                                final r = renewals[i];
                                final isLinked = linked.contains(r.id);
                                return CheckboxListTile(
                                  value: isLinked,
                                  title: Text(r.title),
                                  subtitle: Text(r.categoryLabel),
                                  onChanged: (v) async {
                                    if (v == true) {
                                      await eventExtrasService.linkDocument(
                                        documentId,
                                        r.id,
                                      );
                                    } else {
                                      await eventExtrasService.unlinkDocument(
                                        documentId,
                                        r.id,
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  /// Pick existing vault documents to link to an event (no duplicate uploads).
  static Future<void> pickForEvent(
    BuildContext context, {
    required EventExtrasService eventExtrasService,
    required RenewalService renewalService,
    required String renewalId,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          expand: false,
          initialChildSize: 0.6,
          minChildSize: 0.35,
          maxChildSize: 0.9,
          builder: (_, scrollCtrl) {
            return ListenableBuilder(
              listenable: eventExtrasService,
              builder: (_, _) {
                final all = eventExtrasService.allDocuments;
                return Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        'Link Existing Document',
                        style: Theme.of(ctx).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                      ),
                    ),
                    Expanded(
                      child: all.isEmpty
                          ? const AppEmptyState(
                              icon: Icons.folder_outlined,
                              title: 'Your vault is empty',
                              subtitle:
                                  'Add documents to your vault before linking them.',
                            )
                          : ListView.builder(
                              controller: scrollCtrl,
                              itemCount: all.length,
                              itemBuilder: (_, i) {
                                final doc = all[i];
                                final linked =
                                    doc.linkedRenewalIds.contains(renewalId);
                                return CheckboxListTile(
                                  value: linked,
                                  title: Text(doc.name),
                                  subtitle: Text(doc.categoryLabel),
                                  onChanged: (v) async {
                                    if (v == true) {
                                      await eventExtrasService.linkDocument(
                                        doc.id,
                                        renewalId,
                                      );
                                    } else {
                                      await eventExtrasService.unlinkDocument(
                                        doc.id,
                                        renewalId,
                                      );
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }
}
