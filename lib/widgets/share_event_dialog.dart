import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:renew_wise/models/sharing_models.dart';
import 'package:renew_wise/services/sharing_service.dart';
import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/widgets/sharing_widgets.dart';
import 'package:renew_wise/widgets/common/app_feedback.dart';
import 'package:renew_wise/widgets/common/renew_wise_inline_empty_state.dart';

/// Share event dialog — full v1 UI; cloud sync activates later.
Future<void> showShareEventDialog(
  BuildContext context, {
  required SharingService sharingService,
  required String renewalId,
  required String eventTitle,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    builder: (ctx) => _ShareEventSheet(
      sharingService: sharingService,
      renewalId: renewalId,
      eventTitle: eventTitle,
    ),
  );
}

class _ShareEventSheet extends StatefulWidget {
  const _ShareEventSheet({
    required this.sharingService,
    required this.renewalId,
    required this.eventTitle,
  });

  final SharingService sharingService;
  final String renewalId;
  final String eventTitle;

  @override
  State<_ShareEventSheet> createState() => _ShareEventSheetState();
}

class _ShareEventSheetState extends State<_ShareEventSheet> {
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  SharePermission _invitePermission = SharePermission.viewer;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    super.dispose();
  }

  EventSharingMeta get _meta => widget.sharingService.metaFor(widget.renewalId);
  bool get _isOwner => widget.sharingService.isOwner(widget.renewalId);

  Future<void> _toggleShared(bool value) async {
    if (value) {
      await widget.sharingService.makeShared(widget.renewalId);
    } else {
      await widget.sharingService.makePrivate(widget.renewalId);
    }
    setState(() {});
  }

  Future<void> _invite() async {
    final name = _nameCtrl.text.trim();
    if (name.isEmpty) return;
    await widget.sharingService.addMember(
      widget.renewalId,
      displayName: name,
      email: _emailCtrl.text.trim().isEmpty ? null : _emailCtrl.text.trim(),
      permission: _invitePermission,
    );
    _nameCtrl.clear();
    _emailCtrl.clear();
    setState(() {});
  }

  void _copyLink() {
    Clipboard.setData(
      ClipboardData(text: 'renewwise://share/${widget.renewalId}'),
    );
    AppFeedback.copied(context);
  }

  @override
  Widget build(BuildContext context) {
    final meta = _meta;
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (_, scroll) {
        return ListView(
          controller: scroll,
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          children: [
            Text(
              'Share Event',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),
            const SizedBox(height: 4),
            Text(
              widget.eventTitle,
              style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
            ),
            const SizedBox(height: 16),
            Card(
              color: AppColors.teal.withValues(alpha: 0.08),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: AppColors.teal, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Sharing will become available once cloud collaboration is enabled. '
                        'Version 1.0 saves members and permissions locally on this device.',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.85),
                          height: 1.4,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Shared Event'),
              subtitle: Text(
                meta.isShared
                    ? 'Visible to invited members'
                    : 'Only you can see this event',
              ),
              value: meta.isShared,
              onChanged: _isOwner ? _toggleShared : null,
            ),
            if (meta.isShared) ...[
              const SizedBox(height: 8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: MemberAvatar(
                  name: meta.ownerName,
                  hue: meta.ownerName.hashCode % 360,
                ),
                title: Text(meta.ownerName),
                subtitle: const Text('Owner'),
                trailing:
                    const PermissionChip(permission: SharePermission.owner),
              ),
              const Divider(height: 24),
              Text(
                'Members',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              if (meta.members.isEmpty)
                const RenewWiseInlineEmptyState(
                  icon: Icons.group_outlined,
                  message: 'No members yet.',
                  subtitle:
                      'Invite someone you trust when sharing is ready.',
                ),
              ...meta.members.map(
                (m) => ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: MemberAvatar(name: m.displayName, hue: m.avatarHue),
                  title: Text(m.displayName),
                  subtitle: m.email != null ? Text(m.email!) : null,
                  trailing: _isOwner
                      ? PopupMenuButton<SharePermission>(
                          onSelected: (p) async {
                            await widget.sharingService.updateMemberPermission(
                              widget.renewalId,
                              m.id,
                              p,
                            );
                            setState(() {});
                          },
                          itemBuilder: (_) => SharePermission.values
                              .where((p) => p != SharePermission.owner)
                              .map(
                                (p) => PopupMenuItem(
                                  value: p,
                                  child: Text(p.label),
                                ),
                              )
                              .toList(),
                          child: PermissionChip(permission: m.permission),
                        )
                      : PermissionChip(permission: m.permission),
                ),
              ),
              if (_isOwner) ...[
                const SizedBox(height: 16),
                Text(
                  'Invite Member',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Email (optional)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<SharePermission>(
                  initialValue: _invitePermission,
                  decoration: const InputDecoration(
                    labelText: 'Permission',
                    border: OutlineInputBorder(),
                  ),
                  items: const [SharePermission.editor, SharePermission.viewer]
                      .map(
                        (p) => DropdownMenuItem(
                          value: p,
                          child: Text('${p.label} — ${p.description}'),
                        ),
                      )
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _invitePermission = v);
                  },
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _invite,
                  icon: const Icon(Icons.person_add_outlined),
                  label: const Text('Invite Member'),
                ),
              ],
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: _copyLink,
                icon: const Icon(Icons.link_rounded),
                label: const Text('Copy Share Link'),
              ),
            ],
          ],
        );
      },
    );
  }
}
