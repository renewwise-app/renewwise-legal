import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'package:renew_wise/models/backup_models.dart';
import 'package:renew_wise/services/backup/backup_service.dart';
import 'package:renew_wise/services/settings_service.dart';
import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/utils/feature_purpose_messaging.dart';
import 'package:renew_wise/utils/vault_list_utils.dart';
import 'package:renew_wise/widgets/backup_status_badge.dart';
import 'package:renew_wise/widgets/common/app_feedback.dart';
import 'package:renew_wise/widgets/common/app_shimmer.dart';
import 'package:renew_wise/widgets/common/feature_purpose_subtitle.dart';

class BackupRestoreScreen extends StatefulWidget {
  const BackupRestoreScreen({
    super.key,
    required this.backupService,
    required this.settingsService,
  });

  final BackupService backupService;
  final SettingsService settingsService;

  static Future<void> push(
    BuildContext context, {
    required BackupService backupService,
    required SettingsService settingsService,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BackupRestoreScreen(
          backupService: backupService,
          settingsService: settingsService,
        ),
      ),
    );
  }

  @override
  State<BackupRestoreScreen> createState() => _BackupRestoreScreenState();
}

class _BackupRestoreScreenState extends State<BackupRestoreScreen> {
  List<DriveBackupEntry> _backups = [];
  bool _loadingBackups = false;

  @override
  void initState() {
    super.initState();
    widget.backupService.addListener(_onBackupChanged);
    _loadBackups();
  }

  @override
  void dispose() {
    widget.backupService.removeListener(_onBackupChanged);
    super.dispose();
  }

  void _onBackupChanged() {
    if (mounted) setState(() {});
  }

  Future<void> _loadBackups() async {
    if (!widget.backupService.isConnected) return;
    setState(() => _loadingBackups = true);
    try {
      _backups = await widget.backupService.listBackups();
    } catch (_) {
      _backups = [];
    }
    if (mounted) setState(() => _loadingBackups = false);
  }

  Future<void> _connect() async {
    try {
      final ok = await widget.backupService.connectGoogle();
      if (ok && mounted) {
        AppHaptics.confirm();
        AppFeedback.success(
          context,
          'Google account connected. Your backups stay in your Drive.',
        );
        await _loadBackups();
      }
    } on BackupException catch (e) {
      if (mounted) {
        AppFeedback.backupFailed(context, e.message);
      }
    }
  }

  Future<void> _backupNow() async {
    try {
      await widget.backupService.runBackup(manual: true);
      if (mounted) {
        AppFeedback.backupSaved(context);
        await _loadBackups();
      }
    } on BackupException catch (e) {
      if (mounted) {
        AppFeedback.backupFailed(context, e.message);
      }
    }
  }

  Future<void> _pickFrequency() async {
    final current = widget.settingsService.backupFrequency;
    final picked = await showModalBottomSheet<BackupFrequency>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Automatic Backup',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ),
            ...BackupFrequency.values.map(
              (f) => ListTile(
                title: Text(f.label),
                trailing: current == f
                    ? Icon(Icons.check_rounded, color: AppColors.primary)
                    : null,
                onTap: () => Navigator.pop(ctx, f),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
    if (picked != null) {
      await widget.settingsService.setBackupFrequency(picked);
    }
  }

  Future<void> _restoreFlow() async {
    if (_backups.isEmpty) {
      await _loadBackups();
    }
    if (_backups.isEmpty) {
      if (mounted) {
        AppFeedback.info(
          context,
          "We couldn't find any backups in your Google Drive yet.",
        );
      }
      return;
    }

    if (!mounted) return;
    final selected = await showModalBottomSheet<DriveBackupEntry>(
      context: context,
      isScrollControlled: true,
      showDragHandle: true,
      builder: (ctx) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.55,
        minChildSize: 0.35,
        maxChildSize: 0.85,
        builder: (_, scroll) => Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                'Choose a backup',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            Expanded(
              child: ListView.builder(
                controller: scroll,
                itemCount: _backups.length,
                itemBuilder: (_, i) {
                  final b = _backups[i];
                  return ListTile(
                    leading: const Icon(Icons.backup_outlined),
                    title: Text(DateFormat.yMMMd().add_jm().format(b.createdTime)),
                    subtitle: Text(
                      '${b.deviceName ?? 'Unknown device'} · '
                      'v${b.appVersion ?? '?'} · '
                      '${VaultListUtils.formatBytes(b.sizeBytes)}',
                    ),
                    onTap: () => Navigator.pop(ctx, b),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
    if (selected == null || !mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Restore this backup?'),
        content: Text(
          'Backup from ${DateFormat.yMMMd().add_jm().format(selected.createdTime)} '
          'on ${selected.deviceName ?? 'unknown device'} will be applied.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    final hasLocalData = widget.backupService.renewalService.upcomingCount > 0 ||
        widget.backupService.eventExtrasService.totalDocumentCount > 0;

    RestoreConflictMode mode = RestoreConflictMode.replace;
    if (hasLocalData) {
      mode = await _conflictDialog() ?? RestoreConflictMode.cancel;
      if (mode == RestoreConflictMode.cancel || !mounted) return;
    }

    if (!mounted) return;
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => _RestoreProgressScreen(
          backupService: widget.backupService,
          fileId: selected.id,
          mode: mode,
        ),
      ),
    );
    await _loadBackups();
  }

  Future<RestoreConflictMode?> _conflictDialog() {
    return showDialog<RestoreConflictMode>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Local data differs'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: RestoreConflictMode.values.map((m) {
              if (m == RestoreConflictMode.cancel) {
                return const SizedBox.shrink();
              }
              return Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.label,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      m.description,
                      style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, RestoreConflictMode.cancel),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, RestoreConflictMode.merge),
            child: const Text('Merge'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, RestoreConflictMode.replace),
            child: const Text('Replace Local'),
          ),
        ],
      ),
    );
  }

  Future<void> _disconnect() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Disconnect Google?'),
        content: const Text(
          'Automatic backups will stop. Files already in your Google Drive '
          'stay yours — RenewWise never deletes them without your permission.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Disconnect'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await widget.backupService.disconnect();
    }
  }

  Future<void> _deleteCloud() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete cloud backups?'),
        content: const Text(
          'This permanently removes RenewWise backup files from YOUR Google Drive. '
          'Local data on this device is not affected.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.critical),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok == true) {
      await widget.backupService.deleteCloudBackups();
      await _loadBackups();
      if (mounted) {
        AppHaptics.destructive();
        AppFeedback.show(
          context,
          message: 'Cloud backups removed from your Drive.',
          haptic: false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final ss = widget.settingsService;
    final bs = widget.backupService;
    final fmt = DateFormat.yMMMd().add_jm();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Backup & Restore'),
      ),
      body: ListenableBuilder(
        listenable: Listenable.merge([bs, ss]),
        builder: (context, _) {
          final status = bs.displayStatus;
          final progress = bs.progress;

          return SafeArea(
           child: Stack(
            children: [
              ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  const FeaturePurposeSubtitle(
                    FeaturePurposeMessaging.backup,
                  ),
                  const SizedBox(height: 16),
                  _PrivacyCard(),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Backup Status',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(fontWeight: FontWeight.w700),
                                ),
                              ),
                              BackupStatusBadge(status: status),
                            ],
                          ),
                          const SizedBox(height: 12),
                          _InfoRow(
                            label: 'Connected Account',
                            value: ss.backupConnectedEmail.isEmpty
                                ? 'Not connected'
                                : ss.backupConnectedEmail,
                          ),
                          _InfoRow(
                            label: 'Last Backup',
                            value: ss.backupLastAt == null
                                ? 'Never'
                                : fmt.format(ss.backupLastAt!),
                          ),
                          _InfoRow(
                            label: 'Storage Used',
                            value: bs.formatStorage(ss.backupStorageBytes),
                          ),
                          _InfoRow(
                            label: 'Frequency',
                            value: ss.backupFrequency.label,
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!bs.isConnected)
                    FilledButton.icon(
                      onPressed: bs.isBusy ? null : _connect,
                      icon: const Icon(Icons.login_rounded),
                      label: const Text('Connect Google Account'),
                    )
                  else ...[
                    FilledButton.icon(
                      onPressed: bs.isBusy ? null : _backupNow,
                      icon: const Icon(Icons.cloud_upload_outlined),
                      label: const Text('Backup Now'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: bs.isBusy ? null : _restoreFlow,
                      icon: const Icon(Icons.restore_rounded),
                      label: const Text('Restore'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: bs.isBusy ? null : _pickFrequency,
                      icon: const Icon(Icons.schedule_rounded),
                      label: const Text('Backup Frequency'),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: bs.isBusy ? null : _disconnect,
                      icon: const Icon(Icons.link_off_rounded),
                      label: const Text('Disconnect'),
                    ),
                    TextButton.icon(
                      onPressed: bs.isBusy ? null : _deleteCloud,
                      icon: Icon(Icons.delete_outline, color: AppColors.critical),
                      label: Text(
                        'Delete Cloud Backups',
                        style: TextStyle(color: AppColors.critical),
                      ),
                    ),
                  ],
                  if (_loadingBackups) ...[
                    const SizedBox(height: 16),
                    const AppCardSkeleton(),
                    const SizedBox(height: 12),
                    const AppCardSkeleton(),
                  ],
                ],
              ),
              if (bs.isBusy && progress != null)
                ColoredBox(
                  color: Colors.black54,
                  child: Center(
                    child: Card(
                      margin: const EdgeInsets.all(32),
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Backing up…',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleMedium
                                  ?.copyWith(fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 16),
                            LinearProgressIndicator(value: progress.fraction),
                            const SizedBox(height: 8),
                            Text(
                              progress.stage,
                              style: TextStyle(
                                color: Theme.of(context).colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
            ],
           ),
          );
        },
      ),
    );
  }
}

class _PrivacyCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      color: AppColors.teal.withAlpha(20),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.lock_outline, color: AppColors.teal),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Your data remains yours. Stored locally by default. Cloud backups '
                'live only inside YOUR Google Drive folder (RenewWise → Backups). '
                'RenewWise cannot access your files without your permission.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withAlpha(204),
                  height: 1.4,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
            SizedBox(
            width: 130,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _RestoreProgressScreen extends StatefulWidget {
  const _RestoreProgressScreen({
    required this.backupService,
    required this.fileId,
    required this.mode,
  });

  final BackupService backupService;
  final String fileId;
  final RestoreConflictMode mode;

  @override
  State<_RestoreProgressScreen> createState() => _RestoreProgressScreenState();
}

class _RestoreProgressScreenState extends State<_RestoreProgressScreen> {
  BackupProgress? _progress;
  bool _done = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _run();
  }

  Future<void> _run() async {
    try {
      await widget.backupService.restoreBackup(
        widget.fileId,
        mode: widget.mode,
        onProgress: (p) => setState(() => _progress = p),
      );
      setState(() => _done = true);
    } on BackupException catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: _done || _error != null,
      child: Scaffold(
        appBar: AppBar(
          automaticallyImplyLeading: _done || _error != null,
          title: const Text('Restore'),
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: _error != null
                ? Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.error_outline, size: 48, color: AppColors.critical),
                      const SizedBox(height: 16),
                      Text(
                        "Couldn't restore your backup.\nPlease try again.",
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const SizedBox(height: 16),
                      FilledButton(
                        onPressed: () => Navigator.pop(context),
                        child: const Text('Close'),
                      ),
                    ],
                  )
                : _done
                    ? Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.check_circle_outline,
                              size: 56, color: AppColors.primary),
                          const SizedBox(height: 16),
                          Text(
                            'Restore completed',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Restart RenewWise to finish applying your data.',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 24),
                          FilledButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Done'),
                          ),
                        ],
                      )
                    : Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Restoring your data…',
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(fontWeight: FontWeight.w700),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Please keep RenewWise open',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant,
                                ),
                          ),
                          const SizedBox(height: 24),
                          SizedBox(
                            width: 240,
                            child: LinearProgressIndicator(
                              value: _progress?.fraction,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(_progress?.stage ?? 'Starting…'),
                        ],
                      ),
          ),
        ),
      ),
    );
  }
}
