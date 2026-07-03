import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:renew_wise/models/event_document.dart';
import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/models/vault_document_category.dart';
import 'package:renew_wise/screens/event_details_screen.dart';
import 'package:renew_wise/services/event_extras_service.dart';
import 'package:renew_wise/services/notification_service.dart';
import 'package:renew_wise/services/reminder_state_service.dart';
import 'package:renew_wise/services/renewal_service.dart';
import 'package:renew_wise/services/settings_service.dart';
import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/utils/document_open_utils.dart';
import 'package:renew_wise/utils/document_protection_dialogs.dart';
import 'package:renew_wise/widgets/common/app_feedback.dart';
import 'package:renew_wise/utils/vault_list_utils.dart';
import 'package:renew_wise/widgets/vault_link_picker.dart';

class VaultDocumentDetailScreen extends StatefulWidget {
  const VaultDocumentDetailScreen({
    super.key,
    required this.documentId,
    required this.eventExtrasService,
    required this.renewalService,
    required this.settingsService,
    required this.reminderStateService,
    required this.notificationService,
  });

  final String documentId;
  final EventExtrasService eventExtrasService;
  final RenewalService renewalService;
  final SettingsService settingsService;
  final ReminderStateService reminderStateService;
  final NotificationService notificationService;

  static Future<void> push(
    BuildContext context, {
    required EventDocument document,
    required EventExtrasService eventExtrasService,
    required RenewalService renewalService,
    required SettingsService settingsService,
    required ReminderStateService reminderStateService,
    required NotificationService notificationService,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => VaultDocumentDetailScreen(
          documentId: document.id,
          eventExtrasService: eventExtrasService,
          renewalService: renewalService,
          settingsService: settingsService,
          reminderStateService: reminderStateService,
          notificationService: notificationService,
        ),
      ),
    );
  }

  @override
  State<VaultDocumentDetailScreen> createState() =>
      _VaultDocumentDetailScreenState();
}

class _VaultDocumentDetailScreenState extends State<VaultDocumentDetailScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      widget.eventExtrasService.markViewed(widget.documentId);
    });
  }

  EventDocument? get _doc =>
      widget.eventExtrasService.documentById(widget.documentId);

  Future<void> _confirmDelete(EventDocument doc) async {
    final authed = await DocumentProtectionFlow.authenticateForDelete(doc);
    if (!authed || !mounted) return;

    final links = widget.eventExtrasService.linkCount(doc.id);
    final message = links > 0
        ? 'This document is linked to $links reminder${links == 1 ? '' : 's'}.'
        : 'This will permanently delete the document.';

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete document?'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.critical),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true && mounted) {
      await widget.eventExtrasService.deleteDocument(doc.id);
      if (mounted) Navigator.pop(context);
    }
  }

  Future<void> _rename(EventDocument doc) async {
    final ctrl = TextEditingController(text: doc.name);
    final name = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Rename'),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          decoration: const InputDecoration(hintText: 'File name'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (name != null && name.isNotEmpty) {
      await widget.eventExtrasService.updateDocument(doc.copyWith(name: name));
    }
  }

  Future<void> _editNotes(EventDocument doc) async {
    final ctrl = TextEditingController(text: doc.notes ?? '');
    final notes = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Notes'),
        content: TextField(
          controller: ctrl,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Document notes'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (notes != null) {
      await widget.eventExtrasService.updateDocument(
        doc.copyWith(notes: notes.isEmpty ? null : notes),
      );
    }
  }

  Future<void> _editTags(EventDocument doc) async {
    final ctrl = TextEditingController(text: doc.tags.join(', '));
    final raw = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Tags'),
        content: TextField(
          controller: ctrl,
          decoration: const InputDecoration(
            hintText: 'Comma-separated tags',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, ctrl.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (raw != null) {
      final tags = raw
          .split(',')
          .map((t) => t.trim())
          .where((t) => t.isNotEmpty)
          .toList();
      await widget.eventExtrasService.updateDocument(doc.copyWith(tags: tags));
    }
  }

  Future<void> _moveCategory(EventDocument doc) async {
    VaultDocumentCategory? selected = doc.category;
    String? custom = doc.customCategory;
    final result = await showDialog<({VaultDocumentCategory cat, String? custom})>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) {
          final customCtrl = TextEditingController(text: custom ?? '');
          return AlertDialog(
            title: const Text('Move Category'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ...VaultDocumentCategory.values.map(
                    (c) => ListTile(
                      title: Text(c.label),
                      trailing: selected == c
                          ? Icon(Icons.check_circle,
                              color: AppColors.primary)
                          : null,
                      onTap: () => setLocal(() => selected = c),
                    ),
                  ),
                  if (selected == VaultDocumentCategory.other)
                    TextField(
                      controller: customCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Custom category',
                      ),
                      onChanged: (v) => custom = v,
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(
                  ctx,
                  (
                    cat: selected ?? VaultDocumentCategory.other,
                    custom: selected == VaultDocumentCategory.other
                        ? customCtrl.text.trim()
                        : null,
                  ),
                ),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
    if (result != null) {
      await widget.eventExtrasService.updateDocument(
        doc.copyWith(
          category: result.cat,
          customCategory: result.custom,
        ),
      );
    }
  }

  Future<void> _duplicate(EventDocument doc) async {
    final copy = doc.copyWith(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: '${doc.name} (Copy)',
      addedAt: DateTime.now(),
      linkedRenewalIds: const [],
      isFavorite: false,
      lastViewedAt: null,
    );
    await widget.eventExtrasService.upsertDocument(copy);
    if (mounted) {
      AppFeedback.success(context, 'Document duplicated');
    }
  }

  void _share(EventDocument doc) {
    Clipboard.setData(ClipboardData(text: doc.path));
    AppFeedback.copied(context);
  }

  Future<void> _toggleProtection(EventDocument doc) async {
    await DocumentProtectionFlow.updateProtection(
      context,
      doc: doc,
      protect: !doc.isProtected,
      persist: widget.eventExtrasService.updateDocument,
    );
  }

  Future<void> _preview(EventDocument doc) async {
    await DocumentOpenUtils.open(context, doc);
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.eventExtrasService,
        widget.renewalService,
      ]),
      builder: (context, _) {
        final doc = _doc;
        if (doc == null) {
          return Scaffold(
            appBar: AppBar(),
            body: const Center(child: Text('Document not found')),
          );
        }

        final linked = <Renewal>[];
        for (final id in doc.linkedRenewalIds) {
          for (final r in widget.renewalService.renewals) {
            if (r.id == id) linked.add(r);
          }
        }

        return Scaffold(
          appBar: AppBar(
            title: Row(
              children: [
                Expanded(
                  child: Text(
                    doc.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                DocumentProtectionLockIcon(isProtected: doc.isProtected),
              ],
            ),
            actions: [
              IconButton(
                icon: Icon(
                  doc.isFavorite ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: doc.isFavorite ? AppColors.gold : null,
                ),
                onPressed: () =>
                    widget.eventExtrasService.toggleFavorite(doc.id),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              _PreviewHero(document: doc, onTap: () => _preview(doc)),
              const SizedBox(height: 16),
              _InfoLine('Category', doc.categoryLabel),
              _InfoLine('Size', VaultListUtils.formatBytes(doc.sizeBytes)),
              _InfoLine(
                'Date Added',
                doc.addedAt?.toLocal().toString().split('.').first ?? '—',
              ),
              _InfoLine('Security', doc.storageBackend.label),
              if (doc.notes != null && doc.notes!.isNotEmpty)
                _InfoLine('Notes', doc.notes!),
              if (doc.tags.isNotEmpty)
                _InfoLine('Tags', doc.tags.join(', ')),
              const SizedBox(height: 16),
              Text(
                'Linked Events',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              if (linked.isEmpty)
                Text(
                  'Not linked to any reminder',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                )
              else
                ...linked.map(
                  (r) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(r.title),
                    trailing: TextButton(
                      onPressed: () =>
                          widget.eventExtrasService.unlinkDocument(doc.id, r.id),
                      child: const Text('Unlink'),
                    ),
                    onTap: () => EventDetailsScreen.push(
                      context,
                      renewal: r,
                      renewalService: widget.renewalService,
                      settingsService: widget.settingsService,
                      reminderStateService: widget.reminderStateService,
                      notificationService: widget.notificationService,
                      eventExtrasService: widget.eventExtrasService,
                    ),
                  ),
                ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _ActionChip(
                    icon: Icons.visibility_outlined,
                    label: 'Preview',
                    onTap: () => _preview(doc),
                  ),
                  _ActionChip(
                    icon: Icons.open_in_new_outlined,
                    label: 'Open',
                    onTap: () => _preview(doc),
                  ),
                  _ActionChip(
                    icon: Icons.share_outlined,
                    label: 'Share',
                    onTap: () => _share(doc),
                  ),
                  _ActionChip(
                    icon: Icons.drive_file_rename_outline,
                    label: 'Rename',
                    onTap: () => _rename(doc),
                  ),
                  _ActionChip(
                    icon: Icons.drive_file_move_outline,
                    label: 'Move Category',
                    onTap: () => _moveCategory(doc),
                  ),
                  _ActionChip(
                    icon: Icons.copy_outlined,
                    label: 'Duplicate',
                    onTap: () => _duplicate(doc),
                  ),
                  _ActionChip(
                    icon: Icons.link_outlined,
                    label: 'Link to Event',
                    onTap: () => VaultLinkPicker.show(
                      context,
                      eventExtrasService: widget.eventExtrasService,
                      renewalService: widget.renewalService,
                      documentId: doc.id,
                    ),
                  ),
                  _ActionChip(
                    icon: Icons.notes_outlined,
                    label: 'Add Notes',
                    onTap: () => _editNotes(doc),
                  ),
                  _ActionChip(
                    icon: Icons.label_outline,
                    label: 'Tags',
                    onTap: () => _editTags(doc),
                  ),
                  _ActionChip(
                    icon: doc.isProtected
                        ? Icons.lock_open_outlined
                        : Icons.lock_outline,
                    label: doc.isProtected
                        ? 'Remove Protection'
                        : 'Protect Document',
                    onTap: () => _toggleProtection(doc),
                  ),
                  _ActionChip(
                    icon: Icons.delete_outline,
                    label: 'Delete',
                    color: AppColors.critical,
                    onTap: () => _confirmDelete(doc),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

class _PreviewHero extends StatelessWidget {
  const _PreviewHero({required this.document, required this.onTap});

  final EventDocument document;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary.withAlpha(12),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: SizedBox(
          height: 180,
          width: double.infinity,
          child: document.isProtected ||
                  document.resolvedFileType != VaultFileType.image ||
                  document.path.startsWith('demo://') ||
                  !File(document.path).existsSync()
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        document.isProtected
                            ? Icons.lock_outline
                            : Icons.insert_drive_file_outlined,
                        size: 64,
                        color: AppColors.primary.withAlpha(160),
                      ),
                      if (document.isProtected) ...[
                        const SizedBox(height: 8),
                        Text(
                          'Protected document',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: Theme.of(context)
                                    .colorScheme
                                    .onSurfaceVariant,
                              ),
                        ),
                      ],
                    ],
                  ),
                )
              : ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.file(File(document.path), fit: BoxFit.cover),
                ),
        ),
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine(this.label, this.value);

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
            ),
          ),
          Expanded(
            child: Text(value, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _ActionChip extends StatelessWidget {
  const _ActionChip({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      avatar: Icon(icon, size: 18, color: color ?? AppColors.primary),
      label: Text(label),
      onPressed: onTap,
    );
  }
}
