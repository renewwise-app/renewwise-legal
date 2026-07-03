// This file is intentionally NOT protected by a kReleaseMode guard at the
// import level — callers are responsible for gating navigation.  Every
// Navigator route to this screen must be wrapped in `if (!kReleaseMode)`.

import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

import 'package:renew_wise/models/notification_level.dart';
import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/screens/event_details_screen.dart';
import 'package:renew_wise/services/assistant_draft_service.dart';
import 'package:renew_wise/services/backup/backup_service.dart';
import 'package:renew_wise/services/developer_service.dart';
import 'package:renew_wise/services/event_extras_service.dart';
import 'package:renew_wise/services/notification_service.dart';
import 'package:renew_wise/services/reminder_state_service.dart';
import 'package:renew_wise/services/renewal_service.dart';
import 'package:renew_wise/services/settings_service.dart';
import 'package:renew_wise/services/sharing_service.dart';
import 'package:renew_wise/theme/app_theme.dart';

/// Internal Developer Control Center — visible only in non-release builds.
class DeveloperScreen extends StatefulWidget {
  const DeveloperScreen({
    super.key,
    required this.developerService,
    required this.settingsService,
    required this.renewalService,
    required this.notificationService,
    this.reminderStateService,
    this.assistantDraftService,
    this.eventExtrasService,
    this.backupService,
    this.sharingService,
  });

  final DeveloperService developerService;
  final SettingsService settingsService;
  final RenewalService renewalService;
  final NotificationService notificationService;
  final ReminderStateService? reminderStateService;
  final AssistantDraftService? assistantDraftService;
  final EventExtrasService? eventExtrasService;
  final BackupService? backupService;
  final SharingService? sharingService;

  static Future<void> push(
    BuildContext context, {
    required DeveloperService developerService,
    required SettingsService settingsService,
    required RenewalService renewalService,
    required NotificationService notificationService,
    ReminderStateService? reminderStateService,
    AssistantDraftService? assistantDraftService,
    EventExtrasService? eventExtrasService,
    BackupService? backupService,
    SharingService? sharingService,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => DeveloperScreen(
          developerService: developerService,
          settingsService: settingsService,
          renewalService: renewalService,
          notificationService: notificationService,
          reminderStateService: reminderStateService,
          assistantDraftService: assistantDraftService,
          eventExtrasService: eventExtrasService,
          backupService: backupService,
          sharingService: sharingService,
        ),
      ),
    );
  }

  @override
  State<DeveloperScreen> createState() => _DeveloperScreenState();
}

class _DeveloperScreenState extends State<DeveloperScreen> {
  final _searchCtrl = TextEditingController();
  String _q = '';
  Uint8List? _testBackupBytes;

  bool _notifGranted = false;
  bool _exactAlarmGranted = false;
  int _pendingNotifCount = 0;
  String _dbPath = '…';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(_onSearch);
    _loadAsync();
  }

  void _onSearch() => setState(() => _q = _searchCtrl.text.trim().toLowerCase());

  Future<void> _loadAsync() async {
    final n = await widget.notificationService.areNotificationsEnabled();
    final e = await widget.notificationService.canScheduleExactAlarms();
    final p = await widget.notificationService.getPendingNotificationCount();
    final base = await getDatabasesPath();
    if (!mounted) return;
    setState(() {
      _notifGranted = n;
      _exactAlarmGranted = e;
      _pendingNotifCount = p;
      _dbPath = '$base/renewwise.db';
    });
  }

  @override
  void dispose() {
    _searchCtrl.removeListener(_onSearch);
    _searchCtrl.dispose();
    super.dispose();
  }

  // ─── Helpers ─────────────────────────────────────────────────────────────────

  bool _show(String title, [String? sub]) {
    if (_q.isEmpty) return true;
    return title.toLowerCase().contains(_q) ||
        (sub?.toLowerCase().contains(_q) ?? false);
  }

  void _snack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(msg), duration: const Duration(seconds: 3)));
  }

  Future<bool> _confirm(String title, String body, {String action = 'Proceed'}) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(title),
        content: Text(body),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.critical),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(action),
          ),
        ],
      ),
    );
    return result == true;
  }

  // ─── Section 1 – Application ─────────────────────────────────────────────────

  Future<void> _resetOnboarding() async {
    await widget.settingsService.resetFirstLaunchExperience();
    _snack('✓ First-launch flow reset — will show on next launch.');
  }

  Future<void> _clearPreferences() async {
    final ok = await _confirm(
      'Clear All Preferences?',
      'This wipes SharedPreferences (settings, onboarding flag, user name). '
          'The app will restart-like on next launch.',
    );
    if (!ok) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await widget.settingsService.initialize();
    _snack('✓ SharedPreferences cleared.');
  }

  Future<void> _clearDatabase() async {
    final ok = await _confirm(
      'Clear Local Database?',
      'All events and their scheduled notifications will be permanently deleted.',
      action: 'Clear',
    );
    if (!ok) return;
    await widget.renewalService.clearAll();
    _snack('✓ Database cleared — ${widget.renewalService.renewals.length} events remain.');
  }

  Future<void> _generateDemoHistory() async {
    final svc = widget.reminderStateService;
    if (svc == null) return;
    await svc.generateDemoHistory();
    _snack('✓ Demo history entries added.');
  }

  Future<void> _clearHistory() async {
    final svc = widget.reminderStateService;
    if (svc == null) return;
    final ok = await _confirm(
      'Clear History?',
      'All completion history will be removed. Use Restore All History to undo.',
      action: 'Clear',
    );
    if (!ok) return;
    await svc.clearHistory();
    _snack('✓ History cleared.');
  }

  Future<void> _restoreAllHistory() async {
    final svc = widget.reminderStateService;
    if (svc == null) return;
    await svc.restoreAllHistory();
    _snack('✓ History restored from backup.');
  }

  Future<void> _generateSampleEvent() async {
    final svc = widget.assistantDraftService;
    if (svc == null) return;
    await svc.generateSampleDraft();
    _snack('✓ Sample assistant draft created.');
  }

  Future<void> _generateAssistantDraft() async {
    final svc = widget.assistantDraftService;
    if (svc == null) return;
    await svc.generateDraftOnly();
    _snack('✓ Draft at question 1 created.');
  }

  Future<void> _generateAssistantNotes() async {
    final svc = widget.assistantDraftService;
    if (svc == null) return;
    await svc.generateDraftWithNotes();
    _snack('✓ Draft with notes created.');
  }

  Future<void> _generateAssistantAttachments() async {
    final svc = widget.assistantDraftService;
    if (svc == null) return;
    await svc.generateDraftWithAttachments();
    _snack('✓ Draft with attachments created.');
  }

  Renewal? _firstRenewal() {
    final list = widget.renewalService.renewals;
    if (list.isEmpty) return null;
    return list.first;
  }

  Future<void> _generateEventDetailsSamples() async {
    final svc = widget.eventExtrasService;
    final renewal = _firstRenewal();
    if (svc == null || renewal == null) {
      _snack(renewal == null ? 'Add an event first.' : 'Event extras unavailable.');
      return;
    }
    await svc.generateSampleEventDetails(renewal.id);
    _snack('✓ Sample documents and timeline for "${renewal.title}".');
  }

  Future<void> _generateEventAttachments() async {
    final svc = widget.eventExtrasService;
    final renewal = _firstRenewal();
    if (svc == null || renewal == null) {
      _snack(renewal == null ? 'Add an event first.' : 'Event extras unavailable.');
      return;
    }
    await svc.generateSampleDocuments(renewal.id);
    _snack('✓ Sample attachments for "${renewal.title}".');
  }

  Future<void> _generateEventTimeline() async {
    final svc = widget.eventExtrasService;
    final renewal = _firstRenewal();
    if (svc == null || renewal == null) {
      _snack(renewal == null ? 'Add an event first.' : 'Event extras unavailable.');
      return;
    }
    await svc.generateSampleTimeline(renewal.id);
    _snack('✓ Sample activity timeline for "${renewal.title}".');
  }

  Future<void> _openEventDetailsPreview() async {
    final renewal = _firstRenewal();
    final rs = widget.reminderStateService;
    final extras = widget.eventExtrasService;
    if (renewal == null || rs == null || extras == null) {
      _snack('Add an event and open from Home first.');
      return;
    }
    await EventDetailsScreen.push(
      context,
      renewal: renewal,
      renewalService: widget.renewalService,
      settingsService: widget.settingsService,
      reminderStateService: rs,
      notificationService: widget.notificationService,
      eventExtrasService: extras,
      sharingService: widget.sharingService,
    );
  }

  Future<void> _generateLowQualityEvents() async {
    for (final r in DeveloperService.buildLowQualityEvents()) {
      widget.renewalService.addRenewal(r);
    }
    _snack('✓ Added low-quality intelligence test events.');
  }

  Future<void> _generateMissingDocumentEvents() async {
    for (final r in DeveloperService.buildMissingDocumentEvents()) {
      widget.renewalService.addRenewal(r);
    }
    _snack('✓ Added events missing documents.');
  }

  Future<void> _generateOverdueIntelligenceEvents() async {
    for (final r in DeveloperService.buildOverdueIntelligenceEvents()) {
      widget.renewalService.addRenewal(r);
    }
    _snack('✓ Added overdue intelligence test events.');
  }

  Future<void> _generateDuplicateEvents() async {
    for (final r in DeveloperService.buildDuplicateEvents()) {
      widget.renewalService.addRenewal(r);
    }
    _snack('✓ Added duplicate-title test events.');
  }

  Future<void> _generateVaultDocuments() async {
    final svc = widget.eventExtrasService;
    if (svc == null) return;
    final ids = widget.renewalService.renewals.map((r) => r.id).take(3).toList();
    await svc.generateVaultSamples(renewalIds: ids);
    _snack('✓ Generated sample vault documents.');
  }

  Future<void> _generateLinkedVaultDocuments() async {
    final svc = widget.eventExtrasService;
    if (svc == null) return;
    final ids = widget.renewalService.renewals.map((r) => r.id).take(3).toList();
    if (ids.isEmpty) {
      _snack('Add events first.');
      return;
    }
    await svc.generateLinkedVaultDocuments(ids);
    _snack('✓ Generated multi-linked vault document.');
  }

  Future<void> _generateDemo() async {
    final batch = DeveloperService.buildDemoSet();
    for (final r in batch) {
      widget.renewalService.addRenewal(r);
    }
    _snack('✓ Generated ${batch.length} demo events.');
  }

  Future<void> _removeDemo() async {
    final ids = widget.renewalService.renewals
        .where(DeveloperService.isDemoRenewal)
        .map((r) => r.id)
        .toList();
    if (ids.isEmpty) {
      _snack('No demo events found.');
      return;
    }
    for (final id in ids) {
      widget.renewalService.deleteRenewal(id);
    }
    _snack('✓ Removed ${ids.length} demo events.');
  }

  void _showAppInfo() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('App Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow('App', 'RenewWise'),
            _InfoRow('Version', '1.0.0'),
            _InfoRow('Build Mode', kDebugMode ? 'DEBUG' : kProfileMode ? 'PROFILE' : 'RELEASE'),
            _InfoRow('Dart SDK', Platform.version.split(' ').first),
            _InfoRow('OS', '${Platform.operatingSystem} ${Platform.operatingSystemVersion}'),
            _InfoRow('Locale', Platform.localeName),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  // ─── Section 2 – Notifications ───────────────────────────────────────────────

  Future<void> _sendLevelTest(NotificationLevel level) async {
    await widget.notificationService.sendTestNotificationAtLevel(level);
    _snack('✓ ${level.label} priority test notification sent.');
    final p = await widget.notificationService.getPendingNotificationCount();
    if (mounted) setState(() => _pendingNotifCount = p);
  }

  Future<void> _sendFullScreenTest() async {
    await widget.notificationService.sendCriticalFullScreenTest();
    _snack('✓ Critical full-screen test sent.');
  }

  Future<void> _clearTestNotifs() async {
    await widget.notificationService.cancelAllTestNotifications();
    _snack('✓ Test notifications cleared.');
  }

  Future<void> _sendTestNotif(String label) async {
    await widget.notificationService.sendTestNotification();
    _snack('✓ Test notification sent ($label).');
    final p = await widget.notificationService.getPendingNotificationCount();
    if (mounted) setState(() => _pendingNotifCount = p);
  }

  Future<void> _cancelAllNotifs() async {
    final ok = await _confirm('Cancel All Notifications?', 'Cancels all pending RenewWise notifications.');
    if (!ok) return;
    await widget.notificationService.cancelAll();
    final p = await widget.notificationService.getPendingNotificationCount();
    if (mounted) setState(() => _pendingNotifCount = p);
    _snack('✓ All notifications cancelled.');
  }

  Future<void> _refreshNotifStatus() async {
    final n = await widget.notificationService.areNotificationsEnabled();
    final e = await widget.notificationService.canScheduleExactAlarms();
    final p = await widget.notificationService.getPendingNotificationCount();
    if (mounted) setState(() { _notifGranted = n; _exactAlarmGranted = e; _pendingNotifCount = p; });
    _snack('✓ Status refreshed.');
  }

  // ─── Section 3 – Time Travel ─────────────────────────────────────────────────

  void _setDateOverride(DateTime? date) {
    widget.developerService.setDateOverride(date);
    if (date == null) {
      _snack('✓ Time travel cleared — using real today.');
    } else {
      final s = '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
      _snack('✓ Date override set to $s.');
    }
    setState(() {});
  }

  Future<void> _pickCustomDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: widget.developerService.dateOverride ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      helpText: 'Set fake "today"',
    );
    if (picked != null) _setDateOverride(picked);
  }

  // ─── Section 4 – Test Events ─────────────────────────────────────────────────

  Future<void> _addTestEvents() async {
    final batch = DeveloperService.buildTestEventSet();
    for (final r in batch) {
      widget.renewalService.addRenewal(r);
    }
    _snack('✓ Added ${batch.length} test scenario events.');
  }

  Future<void> _addRandomEvents(int count) async {
    final sw = Stopwatch()..start();
    final batch = DeveloperService.buildRandomSet(count);
    for (final r in batch) {
      widget.renewalService.addRenewal(r);
    }
    sw.stop();
    _snack('✓ Added $count random events in ${sw.elapsedMilliseconds} ms.');
  }

  // ─── Section 6 – UI Tests ────────────────────────────────────────────────────

  void _toggleLayoutBounds(bool enabled) {
    widget.developerService.setLayoutBounds(enabled);
    _snack(enabled ? 'Layout bounds ON.' : 'Layout bounds OFF.');
  }

  Future<void> _setTheme(ThemeMode mode) async {
    await widget.developerService.setThemeMode(mode);
    _snack('✓ Theme changed to ${mode.name}.');
  }

  // ─── Section 7 – Debug ───────────────────────────────────────────────────────

  Future<void> _copyDbPath() async {
    await Clipboard.setData(ClipboardData(text: _dbPath));
    _snack('✓ Copied: $_dbPath');
  }

  void _showTimezoneInfo() {
    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Timezone Info'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _InfoRow('Local timezone', DateTime.now().timeZoneName),
            _InfoRow('UTC offset', DateTime.now().timeZoneOffset.toString()),
            _InfoRow('Notification tz', 'UTC (fixed — see notification_service)'),
          ],
        ),
        actions: [TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Close'))],
      ),
    );
  }

  // ─── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final renewals = widget.renewalService.renewals;

    return ListenableBuilder(
      listenable: widget.developerService,
      builder: (context, _) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: const Text('Developer Mode'),
            actions: [
              IconButton(
                icon: const Icon(Icons.refresh_rounded),
                tooltip: 'Refresh status',
                onPressed: _loadAsync,
              ),
            ],
          ),
          body: SafeArea(
            child: Column(
              children: [
                // ── DEBUG BUILD banner ───────────────────────────────────
                Container(
                  width: double.infinity,
                  color: const Color(0xFFDC2626),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.bug_report_rounded, color: Colors.white, size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'DEBUG BUILD — NEVER VISIBLE IN RELEASE',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Search ───────────────────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: TextField(
                    controller: _searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Search developer tools…',
                      prefixIcon: const Icon(Icons.search_rounded),
                      suffixIcon: _q.isEmpty
                          ? null
                          : IconButton(
                              icon: const Icon(Icons.clear_rounded),
                              onPressed: () => _searchCtrl.clear(),
                            ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      filled: true,
                      fillColor: AppColors.cardBackground,
                      contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 4),
                    ),
                  ),
                ),

                // ── Scrollable content ───────────────────────────────────
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(0, 8, 0, 80),
                    children: [
                      // ── 1. Application ─────────────────────────────────
                      _DevCard(
                        title: '1. Application',
                        icon: Icons.phone_android_rounded,
                        color: Colors.deepOrange,
                        visible: _show('Application') || [
                          'Reset Onboarding', 'Reset First Launch',
                          'Clear SharedPreferences', 'Clear Local Database',
                          'Generate Demo Data', 'Remove Demo Data',
                          'App Info', 'Build Mode', 'Device Information',
                        ].any((s) => _show(s)),
                        children: [
                          if (_show('Reset Onboarding', 'Show onboarding on next launch'))
                            _DevTile(icon: Icons.restart_alt_rounded, iconColor: Colors.deepOrange, title: 'Reset Onboarding', subtitle: 'Show onboarding on next launch', onTap: _resetOnboarding),
                          if (_show('Reset First Launch', 'Same as Reset Onboarding'))
                            _DevTile(icon: Icons.first_page_rounded, iconColor: Colors.deepOrange, title: 'Reset First Launch', subtitle: 'Same as Reset Onboarding', onTap: _resetOnboarding),
                          if (_show('Clear SharedPreferences', 'Wipe all settings'))
                            _DevTile(icon: Icons.storage_outlined, iconColor: Colors.deepOrange, title: 'Clear SharedPreferences', subtitle: 'Wipe all app settings', onTap: _clearPreferences, isDestructive: true),
                          if (_show('Clear Local Database', 'Delete all events'))
                            _DevTile(icon: Icons.delete_sweep_outlined, iconColor: Colors.deepOrange, title: 'Clear Local Database', subtitle: 'Delete ALL events from SQLite', onTap: _clearDatabase, isDestructive: true),
                          if (_show('Generate Demo Data', 'Add 10 curated demo events'))
                            _DevTile(icon: Icons.add_box_outlined, iconColor: Colors.deepOrange, title: 'Generate Demo Data', subtitle: 'Add 10 curated sample events', onTap: _generateDemo),
                          if (_show('Remove Demo Data', 'Delete events tagged [DEMO]'))
                            _DevTile(icon: Icons.playlist_remove_rounded, iconColor: Colors.deepOrange, title: 'Remove Demo Data', subtitle: 'Delete all events tagged [DEMO]', onTap: _removeDemo, isDestructive: true),
                          if (_show('App Info', 'Version, build mode, OS'))
                            _DevTile(icon: Icons.info_outline_rounded, iconColor: Colors.deepOrange, title: 'App Info', subtitle: 'Version, build mode, OS', onTap: _showAppInfo),
                          if (_show('Build Mode'))
                            _DevTile(
                              icon: Icons.build_outlined,
                              iconColor: Colors.deepOrange,
                              title: 'Build Mode',
                              subtitle: kDebugMode ? 'DEBUG' : kProfileMode ? 'PROFILE' : 'RELEASE',
                              onTap: () => _snack('Build mode: ${kDebugMode ? "DEBUG" : kProfileMode ? "PROFILE" : "RELEASE"}'),
                            ),
                          if (_show('Device Information', 'Platform, OS'))
                            _DevTile(
                              icon: Icons.devices_rounded,
                              iconColor: Colors.deepOrange,
                              title: 'Device Information',
                              subtitle: '${Platform.operatingSystem} ${Platform.operatingSystemVersion.split(' ').first}',
                              onTap: _showAppInfo,
                            ),
                        ],
                      ),

                      // ── 2. Notifications ───────────────────────────────
                      _DevCard(
                        title: '2. Notifications',
                        icon: Icons.notifications_outlined,
                        color: Colors.blue,
                        visible: _show('Notifications') || [
                          'Send notification', 'Cancel All Notifications',
                          'Show Pending', 'Test Alarm', 'Test Normal', 'Test Critical',
                          'Permission', 'Exact Alarm', 'Pending',
                        ].any((s) => _show(s)),
                        children: [
                          if (_show('Trigger Test Notification'))
                            _DevTile(icon: Icons.notifications_outlined, iconColor: Colors.blue, title: 'Trigger Test Notification', subtitle: 'Medium priority with actions', onTap: () => _sendLevelTest(NotificationLevel.medium)),
                          if (_show('Trigger High Priority Notification'))
                            _DevTile(icon: Icons.priority_high_rounded, iconColor: Colors.orange, title: 'Trigger High Priority Notification', onTap: () => _sendLevelTest(NotificationLevel.high)),
                          if (_show('Trigger Critical Notification'))
                            _DevTile(icon: Icons.notification_important_outlined, iconColor: Colors.red, title: 'Trigger Critical Notification', onTap: () => _sendLevelTest(NotificationLevel.critical)),
                          if (_show('Trigger Full-screen Notification'))
                            _DevTile(icon: Icons.fullscreen_rounded, iconColor: Colors.red, title: 'Trigger Full-screen Notification', subtitle: 'Falls back to heads-up if unsupported', onTap: _sendFullScreenTest),
                          if (_show('Clear All Test Notifications'))
                            _DevTile(icon: Icons.clear_all_rounded, iconColor: Colors.blue, title: 'Clear All Test Notifications', onTap: _clearTestNotifs),
                          if (_show('Cancel All Notifications'))
                            _DevTile(icon: Icons.notifications_off_outlined, iconColor: Colors.blue, title: 'Cancel All Notifications', onTap: _cancelAllNotifs, isDestructive: true),
                          if (_show('Show Pending Notifications', 'Count: $_pendingNotifCount'))
                            _DevTile(
                              icon: Icons.pending_outlined,
                              iconColor: Colors.blue,
                              title: 'Show Pending Notifications',
                              subtitle: 'Pending: $_pendingNotifCount  — tap to refresh',
                              onTap: _refreshNotifStatus,
                            ),
                          if (_show('Test Alarm Notification'))
                            _DevTile(icon: Icons.alarm_rounded, iconColor: Colors.blue, title: 'Test Alarm Notification', onTap: () => _sendTestNotif('alarm')),
                          if (_show('Test Normal Notification'))
                            _DevTile(icon: Icons.circle_notifications_outlined, iconColor: Colors.blue, title: 'Test Normal Notification', onTap: () => _sendTestNotif('normal')),
                          if (_show('Test Critical Notification'))
                            _DevTile(icon: Icons.notification_important_outlined, iconColor: Colors.red, title: 'Test Critical Notification', onTap: () => _sendTestNotif('critical')),
                          if (_show('Notification Permission', _notifGranted ? 'Granted' : 'Denied'))
                            _DevTile(
                              icon: Icons.verified_user_outlined,
                              iconColor: _notifGranted ? AppColors.primary : AppColors.critical,
                              title: 'Notification Permission',
                              subtitle: _notifGranted ? '✓ Granted' : '✗ Denied — tap to request',
                              onTap: _notifGranted ? null : () async {
                                await widget.notificationService.requestPermission();
                                await _refreshNotifStatus();
                              },
                            ),
                          if (_show('Exact Alarm Status', _exactAlarmGranted ? 'Granted' : 'Not granted'))
                            _DevTile(
                              icon: Icons.alarm_outlined,
                              iconColor: _exactAlarmGranted ? AppColors.primary : AppColors.gold,
                              title: 'Exact Alarm Status',
                              subtitle: _exactAlarmGranted ? '✓ Granted — alarms fire on time' : '⚠ Not granted — tap to request',
                              onTap: _exactAlarmGranted ? null : widget.notificationService.requestExactAlarmsPermission,
                            ),
                        ],
                      ),

                      // ── 3. Time Travel ─────────────────────────────────
                      _DevCard(
                        title: '3. Time Travel',
                        icon: Icons.schedule_rounded,
                        color: Colors.purple,
                        visible: _show('Time Travel') || [
                          'Today', 'Tomorrow', '+7 days', '+30 days', 'Custom date',
                          'Override', 'time travel',
                        ].any((s) => _show(s)),
                        children: [
                          // Active override indicator
                          if (widget.developerService.dateOverride != null)
                            Container(
                              margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.purple.withAlpha(20),
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: Colors.purple.withAlpha(60)),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.schedule_rounded, size: 16, color: Colors.purple),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Active: ${_fmtDate(widget.developerService.dateOverride!)}',
                                    style: const TextStyle(color: Colors.purple, fontWeight: FontWeight.w600, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          if (_show('Today', 'Clear time travel override'))
                            _DevTile(icon: Icons.today_rounded, iconColor: Colors.purple, title: 'Today (clear override)', subtitle: 'Use the real current date', onTap: () => _setDateOverride(null)),
                          if (_show('Tomorrow'))
                            _DevTile(icon: Icons.navigate_next_rounded, iconColor: Colors.purple, title: 'Tomorrow', onTap: () => _setDateOverride(_offsetToday(1))),
                          if (_show('+7 days'))
                            _DevTile(icon: Icons.calendar_view_week_outlined, iconColor: Colors.purple, title: '+7 Days', onTap: () => _setDateOverride(_offsetToday(7))),
                          if (_show('+30 days'))
                            _DevTile(icon: Icons.calendar_month_outlined, iconColor: Colors.purple, title: '+30 Days', onTap: () => _setDateOverride(_offsetToday(30))),
                          if (_show('Custom date', 'Pick any calendar date'))
                            _DevTile(icon: Icons.date_range_outlined, iconColor: Colors.purple, title: 'Custom Date…', subtitle: 'Pick any calendar date', onTap: _pickCustomDate),
                        ],
                      ),

                      // ── 4. Test Events ─────────────────────────────────
                      _DevCard(
                        title: '4. Test Events',
                        icon: Icons.add_box_outlined,
                        color: AppColors.teal,
                        visible: _show('Test Events') || [
                          'Insurance', 'Passport', 'Driving', 'Medical',
                          'EMI', 'Vehicle', 'Random', 'Completed',
                        ].any((s) => _show(s)),
                        children: [
                          if (_show('All Test Scenarios', 'Insurance/passport/EMI/expired'))
                            _DevTile(icon: Icons.playlist_add_rounded, iconColor: AppColors.teal, title: 'All Test Scenarios', subtitle: 'Insurance, passport, EMI, expired, medical, vehicle', onTap: _addTestEvents),
                          if (_show('Insurance Expiring Today'))
                            _DevTile(icon: Icons.shield_outlined, iconColor: AppColors.teal, title: 'Insurance Expiring Today', onTap: () => _addSingleTest(0)),
                          if (_show('Insurance Expiring Tomorrow'))
                            _DevTile(icon: Icons.shield_outlined, iconColor: AppColors.teal, title: 'Insurance Expiring Tomorrow', onTap: () => _addSingleTest(1)),
                          if (_show('Passport in 30 Days'))
                            _DevTile(icon: Icons.flight_outlined, iconColor: AppColors.teal, title: 'Passport in 30 Days', onTap: () => _addSingleTest(2)),
                          if (_show('Driving Licence Expired'))
                            _DevTile(icon: Icons.badge_outlined, iconColor: AppColors.teal, title: 'Driving Licence Expired', onTap: () => _addSingleTest(3)),
                          if (_show('Medical Reminder'))
                            _DevTile(icon: Icons.medical_services_outlined, iconColor: AppColors.teal, title: 'Medical Reminder', onTap: () => _addSingleTest(4)),
                          if (_show('EMI Reminder'))
                            _DevTile(icon: Icons.account_balance_outlined, iconColor: AppColors.teal, title: 'EMI Reminder', onTap: () => _addSingleTest(5)),
                          if (_show('Vehicle Tax'))
                            _DevTile(icon: Icons.directions_car_outlined, iconColor: AppColors.teal, title: 'Vehicle Tax', onTap: () => _addSingleTest(6)),
                          if (_show('Random 100 Events'))
                            _DevTile(icon: Icons.shuffle_rounded, iconColor: AppColors.teal, title: 'Random 100 Events', onTap: () => _addRandomEvents(100)),
                          if (_show('Random 500 Events'))
                            _DevTile(icon: Icons.shuffle_rounded, iconColor: AppColors.teal, title: 'Random 500 Events', onTap: () => _addRandomEvents(500)),
                        ],
                      ),

                      // ── 5. Storage ─────────────────────────────────────
                      _DevCard(
                        title: '5. Storage',
                        icon: Icons.storage_rounded,
                        color: Colors.indigo,
                        visible: _show('Storage') || [
                          'Database size', 'Events', 'Overdue', 'Payment',
                          'Pending', 'Storage', 'Path',
                        ].any((s) => _show(s)),
                        children: [
                          _InfoTile(label: 'Total Events', value: '${renewals.length}'),
                          _InfoTile(label: 'Active Events', value: '${renewals.where((r) => r.status.name != 'cancelled').length}'),
                          _InfoTile(label: 'Overdue Events', value: '${renewals.where((r) => r.isOverdue).length}'),
                          _InfoTile(label: 'Payment Events', value: '${renewals.where((r) => r.paymentRequired).length}'),
                          _InfoTile(label: 'Demo/Test Events', value: '${renewals.where(DeveloperService.isDemoRenewal).length}'),
                          _InfoTile(label: 'Pending Notifications', value: '$_pendingNotifCount'),
                          _InfoTile(label: 'Database Path', value: _dbPath, monospace: true),
                          _DevTile(
                            icon: Icons.copy_rounded,
                            iconColor: Colors.indigo,
                            title: 'Copy Database Path',
                            onTap: _copyDbPath,
                          ),
                        ],
                      ),

                      // ── 6. UI Tests ────────────────────────────────────
                      _DevCard(
                        title: '6. UI Tests',
                        icon: Icons.palette_outlined,
                        color: Colors.pink,
                        visible: _show('UI Tests') || [
                          'Theme', 'Light', 'Dark', 'System', 'Layout Bounds',
                          'Text', 'Tablet', 'Phone',
                        ].any((s) => _show(s)),
                        children: [
                          // Theme switcher
                          if (_show('Theme', 'Light / Dark / System'))
                            Padding(
                              padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Theme Mode', style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 8),
                                  SegmentedButton<ThemeMode>(
                                    segments: const [
                                      ButtonSegment(value: ThemeMode.light, label: Text('Light'), icon: Icon(Icons.light_mode_outlined)),
                                      ButtonSegment(value: ThemeMode.dark, label: Text('Dark'), icon: Icon(Icons.dark_mode_outlined)),
                                      ButtonSegment(value: ThemeMode.system, label: Text('System'), icon: Icon(Icons.brightness_auto_outlined)),
                                    ],
                                    selected: {widget.developerService.themeMode},
                                    onSelectionChanged: (s) => _setTheme(s.first),
                                  ),
                                ],
                              ),
                            ),
                          // Layout bounds
                          if (_show('Layout Bounds', 'Debug paint size overlay'))
                            ListTile(
                              leading: Container(
                                width: 40, height: 40,
                                decoration: BoxDecoration(color: Colors.pink.withAlpha(20), borderRadius: BorderRadius.circular(12)),
                                child: const Icon(Icons.grid_4x4_outlined, color: Colors.pink, size: 20),
                              ),
                              title: const Text('Layout Bounds'),
                              subtitle: const Text('Debug paint size overlay'),
                              trailing: Switch(
                                value: widget.developerService.layoutBounds,
                                onChanged: _toggleLayoutBounds,
                                activeThumbColor: AppColors.primary,
                              ),
                            ),
                          if (_show('Large Text', 'Accessibility test'))
                            _DevTile(icon: Icons.text_increase_rounded, iconColor: Colors.pink, title: 'Large Text', subtitle: 'Use system accessibility > Text size', onTap: () => _snack('Set text scale via system Accessibility settings.')),
                          if (_show('Small Text', 'Compact UI test'))
                            _DevTile(icon: Icons.text_decrease_rounded, iconColor: Colors.pink, title: 'Small Text', subtitle: 'Use system accessibility > Text size', onTap: () => _snack('Set text scale via system Accessibility settings.')),
                          if (_show('Tablet Preview', 'Set emulator screen to 7"'))
                            _DevTile(icon: Icons.tablet_rounded, iconColor: Colors.pink, title: 'Tablet Preview', subtitle: 'Set emulator screen to 7″ or wider', onTap: () => _snack('Resize emulator or use flutter run --device tablet.')),
                          if (_show('Phone Preview', 'Standard phone viewport'))
                            _DevTile(icon: Icons.smartphone_rounded, iconColor: Colors.pink, title: 'Phone Preview', subtitle: 'Standard phone viewport', onTap: () => _snack('Default emulator viewport (360 dp).')),
                        ],
                      ),

                      // ── 7. Debug ───────────────────────────────────────
                      _DevCard(
                        title: '7. Debug',
                        icon: Icons.bug_report_outlined,
                        color: Colors.amber.shade700,
                        visible: _show('Debug') || [
                          'Database path', 'Export', 'Import', 'Logs',
                          'Timezone', 'Notification', 'Scheduler',
                        ].any((s) => _show(s)),
                        children: [
                          if (_show('Copy Database Path'))
                            _DevTile(icon: Icons.copy_rounded, iconColor: Colors.amber.shade700, title: 'Copy Database Path', subtitle: _dbPath, onTap: _copyDbPath),
                          if (_show('View Timezone Info', 'Local tz and UTC offset'))
                            _DevTile(icon: Icons.public_rounded, iconColor: Colors.amber.shade700, title: 'View Timezone Info', subtitle: '${DateTime.now().timeZoneName} / UTC ${DateTime.now().timeZoneOffset}', onTap: _showTimezoneInfo),
                          if (_show('Export Database', 'Coming Soon'))
                            _DevTile(icon: Icons.upload_file_outlined, iconColor: Colors.amber.shade700, title: 'Export Database', subtitle: 'Coming Soon', onTap: () => _snack('Export DB: planned for Pack 08.')),
                          if (_show('Import Database', 'Coming Soon'))
                            _DevTile(icon: Icons.download_for_offline_outlined, iconColor: Colors.amber.shade700, title: 'Import Database', subtitle: 'Coming Soon', onTap: () => _snack('Import DB: planned for Pack 08.')),
                          if (_show('View Logs', 'Debug console logs'))
                            _DevTile(icon: Icons.terminal_rounded, iconColor: Colors.amber.shade700, title: 'View Logs', subtitle: 'Use `adb logcat -s flutter` on device', onTap: () => _snack('Run: adb logcat -s flutter')),
                          if (_show('View Last Notification'))
                            _DevTile(icon: Icons.notifications_active_outlined, iconColor: Colors.amber.shade700, title: 'View Last Notification', subtitle: 'Pending count: $_pendingNotifCount', onTap: _refreshNotifStatus),
                          if (_show('Dart / SDK Version', 'Runtime info'))
                            _DevTile(icon: Icons.code_rounded, iconColor: Colors.amber.shade700, title: 'Dart / SDK Version', subtitle: Platform.version.split(' ').first, onTap: _showAppInfo),
                        ],
                      ),

                      // ── 8. Performance ─────────────────────────────────
                      _DevCard(
                        title: '8. Performance',
                        icon: Icons.speed_rounded,
                        color: Colors.deepOrange,
                        visible: _show('Performance') || [
                          '100 reminders', '500 reminders', '1000 reminders',
                          'Measure', 'Loading', 'Frame', 'Render',
                        ].any((s) => _show(s)),
                        children: [
                          if (_show('Generate 100 Reminders', 'Stress test'))
                            _DevTile(icon: Icons.flash_on_rounded, iconColor: Colors.deepOrange, title: 'Generate 100 Events + Measure', subtitle: 'Stress test: 100 random events', onTap: () => _addRandomEvents(100)),
                          if (_show('Generate 500 Reminders', 'Stress test'))
                            _DevTile(icon: Icons.flash_on_rounded, iconColor: Colors.deepOrange, title: 'Generate 500 Events + Measure', subtitle: 'Stress test: 500 random events', onTap: () => _addRandomEvents(500)),
                          if (_show('Generate 1000 Reminders', 'Stress test'))
                            _DevTile(icon: Icons.flash_on_rounded, iconColor: Colors.deepOrange, title: 'Generate 1000 Events + Measure', subtitle: 'Stress test: 1000 random events (may be slow)', onTap: () => _addRandomEvents(1000)),
                          if (_show('Measure Loading Time'))
                            _DevTile(icon: Icons.timer_outlined, iconColor: Colors.deepOrange, title: 'Measure Loading Time', subtitle: 'Clears then reloads all renewals', onTap: _measureLoadTime),
                          if (_show('Show Frame Time', 'Enable performance overlay'))
                            _DevTile(icon: Icons.bar_chart_rounded, iconColor: Colors.deepOrange, title: 'Show Frame Time', subtitle: 'Use --profile build + DevTools timeline', onTap: () => _snack('Run with `flutter run --profile` for accurate frame timing.')),
                          if (_show('Clear Performance Data', 'Remove all DEMO events'))
                            _DevTile(icon: Icons.cleaning_services_rounded, iconColor: Colors.deepOrange, title: 'Clear Performance Data', subtitle: 'Remove all demo events', onTap: _removeDemo, isDestructive: true),
                        ],
                      ),

                      // ── 9. Experimental Flags ──────────────────────────
                      _DevCard(
                        title: '9. Experimental Feature Flags',
                        icon: Icons.science_outlined,
                        color: Colors.cyan.shade700,
                        visible: _show('Experimental') || _show('Feature Flags') ||
                            DeveloperService.featureFlags.any((f) => _show(f.label, f.desc)),
                        children: [
                          for (final f in DeveloperService.featureFlags)
                            if (_show(f.label, f.desc))
                              ListTile(
                                leading: Container(
                                  width: 40, height: 40,
                                  decoration: BoxDecoration(
                                    color: Colors.cyan.withAlpha(20),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(Icons.science_outlined, color: Colors.cyan.shade700, size: 20),
                                ),
                                title: Text(f.label),
                                subtitle: Text(f.desc, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary)),
                                  trailing: Switch(
                                    value: widget.developerService.getFlag(f.key),
                                    onChanged: (v) => widget.developerService.setFlag(f.key, v),
                                    activeThumbColor: AppColors.primary,
                                  ),
                              ),
                        ],
                      ),

                      if (widget.reminderStateService != null)
                        _DevCard(
                          title: '10. History',
                          icon: Icons.history_rounded,
                          color: AppColors.primary,
                          visible: _show('History') || [
                            'Generate Demo History',
                            'Clear History',
                            'Restore All History',
                          ].any((s) => _show(s)),
                          children: [
                            if (_show('Generate Demo History'))
                              _DevTile(
                                icon: Icons.add_chart_outlined,
                                iconColor: AppColors.primary,
                                title: 'Generate Demo History',
                                subtitle: 'Add sample completion entries',
                                onTap: _generateDemoHistory,
                              ),
                            if (_show('Clear History'))
                              _DevTile(
                                icon: Icons.delete_outline_rounded,
                                iconColor: AppColors.primary,
                                title: 'Clear History',
                                subtitle: 'Remove all history entries',
                                onTap: _clearHistory,
                                isDestructive: true,
                              ),
                            if (_show('Restore All History'))
                              _DevTile(
                                icon: Icons.restore_rounded,
                                iconColor: AppColors.primary,
                                title: 'Restore All History',
                                subtitle: 'Undo the last Clear History',
                                onTap: _restoreAllHistory,
                              ),
                          ],
                        ),

                      if (widget.assistantDraftService != null)
                        _DevCard(
                          title: '11. Assistant',
                          icon: Icons.smart_toy_outlined,
                          color: AppColors.teal,
                          visible: _show('Assistant') || [
                            'Generate Sample Event',
                            'Generate Draft',
                            'Generate Attachments',
                            'Generate Notes',
                          ].any((s) => _show(s)),
                          children: [
                            if (_show('Generate Sample Event'))
                              _DevTile(
                                icon: Icons.event_available_outlined,
                                iconColor: AppColors.teal,
                                title: 'Generate Sample Event',
                                subtitle: 'Pre-filled assistant draft',
                                onTap: _generateSampleEvent,
                              ),
                            if (_show('Generate Draft'))
                              _DevTile(
                                icon: Icons.drafts_outlined,
                                iconColor: AppColors.teal,
                                title: 'Generate Draft',
                                subtitle: 'Draft at question 1',
                                onTap: _generateAssistantDraft,
                              ),
                            if (_show('Generate Attachments'))
                              _DevTile(
                                icon: Icons.attach_file_outlined,
                                iconColor: AppColors.teal,
                                title: 'Generate Attachments',
                                subtitle: 'Draft with demo attachment',
                                onTap: _generateAssistantAttachments,
                              ),
                            if (_show('Generate Notes'))
                              _DevTile(
                                icon: Icons.notes_outlined,
                                iconColor: AppColors.teal,
                                title: 'Generate Notes',
                                subtitle: 'Draft with sample notes',
                                onTap: _generateAssistantNotes,
                              ),
                          ],
                        ),

                      if (widget.eventExtrasService != null &&
                          widget.reminderStateService != null)
                        _DevCard(
                          title: '12. Event Details',
                          icon: Icons.event_note_outlined,
                          color: AppColors.primary,
                          visible: _show('Event Details') || [
                            'Generate Sample Event Details',
                            'Generate Attachments',
                            'Generate Timeline',
                            'Open Event Details',
                          ].any((s) => _show(s)),
                          children: [
                            if (_show('Generate Sample Event Details'))
                              _DevTile(
                                icon: Icons.dashboard_customize_outlined,
                                iconColor: AppColors.primary,
                                title: 'Generate Sample Event Details',
                                subtitle: 'Documents + activity for first event',
                                onTap: _generateEventDetailsSamples,
                              ),
                            if (_show('Generate Attachments'))
                              _DevTile(
                                icon: Icons.attach_file_outlined,
                                iconColor: AppColors.primary,
                                title: 'Generate Attachments',
                                subtitle: 'Sample document cards on first event',
                                onTap: _generateEventAttachments,
                              ),
                            if (_show('Generate Timeline'))
                              _DevTile(
                                icon: Icons.timeline_outlined,
                                iconColor: AppColors.primary,
                                title: 'Generate Timeline',
                                subtitle: 'Sample activity log on first event',
                                onTap: _generateEventTimeline,
                              ),
                            if (_show('Open Event Details'))
                              _DevTile(
                                icon: Icons.open_in_new_outlined,
                                iconColor: AppColors.primary,
                                title: 'Open Event Details',
                                subtitle: 'Preview first event control center',
                                onTap: _openEventDetailsPreview,
                              ),
                          ],
                        ),

                      _DevCard(
                        title: '13. Intelligence',
                        icon: Icons.psychology_outlined,
                        color: AppColors.gold,
                        visible: _show('Intelligence') || [
                          'Generate Low Quality Events',
                          'Generate Missing Documents',
                          'Generate Overdue Events',
                          'Generate Duplicate Events',
                        ].any((s) => _show(s)),
                        children: [
                          if (_show('Generate Low Quality Events'))
                            _DevTile(
                              icon: Icons.report_gmailerrorred_outlined,
                              iconColor: AppColors.gold,
                              title: 'Generate Low Quality Events',
                              subtitle: 'Missing notes, amounts, reminders',
                              onTap: _generateLowQualityEvents,
                            ),
                          if (_show('Generate Missing Documents'))
                            _DevTile(
                              icon: Icons.description_outlined,
                              iconColor: AppColors.gold,
                              title: 'Generate Missing Documents',
                              subtitle: 'Events without attachments',
                              onTap: _generateMissingDocumentEvents,
                            ),
                          if (_show('Generate Overdue Events'))
                            _DevTile(
                              icon: Icons.warning_amber_rounded,
                              iconColor: AppColors.critical,
                              title: 'Generate Overdue Events',
                              subtitle: 'Overdue health-check scenarios',
                              onTap: _generateOverdueIntelligenceEvents,
                            ),
                          if (_show('Generate Duplicate Events'))
                            _DevTile(
                              icon: Icons.copy_all_outlined,
                              iconColor: AppColors.gold,
                              title: 'Generate Duplicate Events',
                              subtitle: 'Same-title duplicate detection',
                              onTap: _generateDuplicateEvents,
                            ),
                        ],
                        ),

                      if (widget.eventExtrasService != null)
                        _DevCard(
                          title: '14. Document Vault',
                          icon: Icons.folder_special_outlined,
                          color: AppColors.teal,
                          visible: _show('Document Vault') || [
                            'Generate Documents',
                            'Generate Categories',
                            'Generate Linked Documents',
                            'Generate Vault',
                          ].any((s) => _show(s)),
                          children: [
                            if (_show('Generate Documents'))
                              _DevTile(
                                icon: Icons.description_outlined,
                                iconColor: AppColors.teal,
                                title: 'Generate Documents',
                                subtitle: 'Sample vault files across categories',
                                onTap: _generateVaultDocuments,
                              ),
                            if (_show('Generate Categories'))
                              _DevTile(
                                icon: Icons.category_outlined,
                                iconColor: AppColors.teal,
                                title: 'Generate Categories',
                                subtitle: 'Passport, insurance, medical samples',
                                onTap: _generateVaultDocuments,
                              ),
                            if (_show('Generate Linked Documents'))
                              _DevTile(
                                icon: Icons.link_outlined,
                                iconColor: AppColors.teal,
                                title: 'Generate Linked Documents',
                                subtitle: 'One doc linked to multiple events',
                                onTap: _generateLinkedVaultDocuments,
                              ),
                            if (_show('Generate Vault'))
                              _DevTile(
                                icon: Icons.folder_copy_outlined,
                                iconColor: AppColors.teal,
                                title: 'Generate Vault',
                                subtitle: 'Full vault sample set',
                                onTap: _generateVaultDocuments,
                              ),
                          ],
                        ),

                      if (widget.backupService != null)
                        _DevCard(
                          title: '15. Google Drive Backup',
                          icon: Icons.cloud_sync_outlined,
                          color: AppColors.teal,
                          visible: _show('Google Drive Backup') || [
                            'Generate Backup',
                            'Restore Backup',
                            'Delete Test Backup',
                            'Simulate Backup Failure',
                            'Simulate Drive Offline',
                          ].any((s) => _show(s)),
                          children: [
                            if (_show('Generate Backup'))
                              _DevTile(
                                icon: Icons.archive_outlined,
                                iconColor: AppColors.teal,
                                title: 'Generate Backup',
                                subtitle: 'Create encrypted local test backup',
                                onTap: _devGenerateBackup,
                              ),
                            if (_show('Restore Backup'))
                              _DevTile(
                                icon: Icons.unarchive_outlined,
                                iconColor: AppColors.teal,
                                title: 'Restore Backup',
                                subtitle: 'Restore last generated test backup',
                                onTap: _devRestoreBackup,
                              ),
                            if (_show('Delete Test Backup'))
                              _DevTile(
                                icon: Icons.delete_sweep_outlined,
                                iconColor: AppColors.critical,
                                title: 'Delete Test Backup',
                                subtitle: 'Clear in-memory test backup bytes',
                                onTap: _devDeleteTestBackup,
                              ),
                            if (_show('Simulate Backup Failure'))
                              _DevTile(
                                icon: Icons.error_outline,
                                iconColor: AppColors.gold,
                                title: 'Simulate Backup Failure',
                                subtitle: 'Next backup throws an error',
                                onTap: _devSimulateFailure,
                              ),
                            if (_show('Simulate Drive Offline'))
                              _DevTile(
                                icon: Icons.cloud_off_outlined,
                                iconColor: AppColors.gold,
                                title: 'Simulate Drive Offline',
                                subtitle: 'Next Drive call reports offline',
                                onTap: _devSimulateOffline,
                              ),
                          ],
                        ),

                      if (widget.sharingService != null)
                        _DevCard(
                          title: '16. Shared Events',
                          icon: Icons.groups_outlined,
                          color: AppColors.teal,
                          visible: _show('Shared Events') || [
                            'Generate Shared Events',
                            'Generate Shared Members',
                            'Generate Shared Documents',
                            'Generate Activity Timeline',
                          ].any((s) => _show(s)),
                          children: [
                            if (_show('Generate Shared Events'))
                              _DevTile(
                                icon: Icons.event_available_outlined,
                                iconColor: AppColors.teal,
                                title: 'Generate Shared Events',
                                subtitle: 'Mark sample events as shared',
                                onTap: _devGenerateSharedEvents,
                              ),
                            if (_show('Generate Shared Members'))
                              _DevTile(
                                icon: Icons.person_add_alt_1_outlined,
                                iconColor: AppColors.teal,
                                title: 'Generate Shared Members',
                                subtitle: 'Events shared with you (demo)',
                                onTap: _devGenerateSharedWithMe,
                              ),
                            if (_show('Generate Shared Documents'))
                              _DevTile(
                                icon: Icons.folder_shared_outlined,
                                iconColor: AppColors.teal,
                                title: 'Generate Shared Documents',
                                subtitle: 'Activity for docs on shared events',
                                onTap: _devGenerateSharedDocuments,
                              ),
                            if (_show('Generate Activity Timeline'))
                              _DevTile(
                                icon: Icons.timeline_outlined,
                                iconColor: AppColors.teal,
                                title: 'Generate Activity Timeline',
                                subtitle: 'Full shared activity on first event',
                                onTap: _devGenerateSharedActivity,
                              ),
                          ],
                        ),

                      _DevCard(
                        title: '17. Life Insights',
                        icon: Icons.insights_outlined,
                        color: AppColors.primary,
                        visible: _show('Life Insights') || [
                          'Generate Statistics',
                          'Generate Spending',
                          'Generate Completions',
                          'Generate Timeline',
                        ].any((s) => _show(s)),
                        children: [
                          if (_show('Generate Statistics'))
                            _DevTile(
                              icon: Icons.analytics_outlined,
                              iconColor: AppColors.primary,
                              title: 'Generate Statistics',
                              subtitle: 'Diverse categories for insights QA',
                              onTap: _devGenerateInsightsStatistics,
                            ),
                          if (_show('Generate Spending'))
                            _DevTile(
                              icon: Icons.payments_outlined,
                              iconColor: AppColors.primary,
                              title: 'Generate Spending',
                              subtitle: 'Monthly bills across 6 months',
                              onTap: _devGenerateInsightsSpending,
                            ),
                          if (_show('Generate Completions'))
                            _DevTile(
                              icon: Icons.task_alt_outlined,
                              iconColor: AppColors.primary,
                              title: 'Generate Completions',
                              subtitle: 'Demo history for completion analytics',
                              onTap: _devGenerateInsightsCompletions,
                            ),
                          if (_show('Generate Timeline'))
                            _DevTile(
                              icon: Icons.view_timeline_outlined,
                              iconColor: AppColors.primary,
                              title: 'Generate Timeline',
                              subtitle: 'Events across 7/30/90 day windows',
                              onTap: _devGenerateInsightsTimeline,
                            ),
                        ],
                      ),

                      const Divider(height: 32),

                      // Footer
                      Padding(
                        padding: const EdgeInsets.fromLTRB(24, 0, 24, 16),
                        child: Text(
                          'All destructive actions require confirmation.\n'
                          'This screen is completely removed in Release builds.',
                          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ─── Helper action ────────────────────────────────────────────────────────────

  Future<void> _addSingleTest(int index) async {
    final batch = DeveloperService.buildTestEventSet();
    if (index < batch.length) {
      widget.renewalService.addRenewal(batch[index]);
      _snack('✓ Added: ${batch[index].title}');
    }
  }

  Future<void> _measureLoadTime() async {
    final sw = Stopwatch()..start();
    await widget.renewalService.loadRenewals();
    sw.stop();
    _snack('Load time: ${sw.elapsedMilliseconds} ms — ${widget.renewalService.renewals.length} events.');
  }

  DateTime _offsetToday(int days) {
    final t = DateTime.now();
    final base = DateTime(t.year, t.month, t.day);
    return base.add(Duration(days: days));
  }

  String _fmtDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _devGenerateBackup() async {
    final bs = widget.backupService;
    if (bs == null) return;
    _testBackupBytes = await bs.generateLocalTestBackup();
    _snack('Test backup generated (${_testBackupBytes!.length} bytes encrypted).');
  }

  Future<void> _devRestoreBackup() async {
    final bs = widget.backupService;
    if (bs == null) return;
    if (_testBackupBytes == null) {
      _snack('Generate a test backup first.');
      return;
    }
    await bs.restoreLocalTestBackup(_testBackupBytes!);
    _snack('Test backup restored — restart app to verify fully.');
  }

  void _devDeleteTestBackup() {
    _testBackupBytes = null;
    _snack('Test backup bytes cleared.');
  }

  void _devSimulateFailure() {
    widget.backupService?.setSimulateFailure(true);
    _snack('Simulate failure ON — next backup will fail.');
  }

  void _devSimulateOffline() {
    widget.backupService?.setSimulateOffline(true);
    _snack('Simulate offline ON — next Drive call will fail.');
  }

  Future<void> _devGenerateSharedEvents() async {
    final ss = widget.sharingService;
    if (ss == null) return;
    await ss.generateDemoSharedEvents(widget.renewalService);
    _snack('Generated shared events with members.');
  }

  Future<void> _devGenerateSharedWithMe() async {
    final ss = widget.sharingService;
    if (ss == null) return;
    await ss.generateDemoSharedWithMe(widget.renewalService);
    _snack('Generated events shared with you.');
  }

  Future<void> _devGenerateSharedDocuments() async {
    final ss = widget.sharingService;
    if (ss == null || widget.eventExtrasService == null) return;
    await ss.markLinkedDocumentsShared(widget.eventExtrasService!);
    _snack('Logged shared document activity.');
  }

  Future<void> _devGenerateSharedActivity() async {
    final ss = widget.sharingService;
    if (ss == null) return;
    final renewals = widget.renewalService.renewals;
    if (renewals.isEmpty) {
      _snack('Add an event first.');
      return;
    }
    await ss.generateDemoActivityTimeline(renewals.first.id);
    _snack('Generated shared activity timeline.');
  }

  Future<void> _devGenerateInsightsStatistics() async {
    for (final r in DeveloperService.buildInsightsStatisticsSet()) {
      widget.renewalService.addRenewal(r);
    }
    for (final r in DeveloperService.buildLowQualityEvents()) {
      widget.renewalService.addRenewal(r);
    }
    _snack('Generated statistics demo events.');
  }

  Future<void> _devGenerateInsightsSpending() async {
    for (final r in DeveloperService.buildInsightsSpendingSet()) {
      widget.renewalService.addRenewal(r);
    }
    _snack('Generated spending timeline demo events.');
  }

  Future<void> _devGenerateInsightsCompletions() async {
    final rs = widget.reminderStateService;
    if (rs == null) {
      _snack('Reminder state service unavailable.');
      return;
    }
    await rs.generateDemoHistory();
    _snack('Generated completion history entries.');
  }

  Future<void> _devGenerateInsightsTimeline() async {
    for (final r in DeveloperService.buildInsightsTimelineSet()) {
      widget.renewalService.addRenewal(r);
    }
    _snack('Generated upcoming timeline demo events.');
  }
}

// ─────────────────────────── Reusable Dev widgets ────────────────────────────

class _DevCard extends StatelessWidget {
  const _DevCard({
    required this.title,
    required this.icon,
    required this.color,
    required this.children,
    this.visible = true,
  });

  final String title;
  final IconData icon;
  final Color color;
  final List<Widget> children;
  final bool visible;

  @override
  Widget build(BuildContext context) {
    if (!visible || children.isEmpty) return const SizedBox.shrink();
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: color.withAlpha(20),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(icon, size: 16, color: color),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, indent: 16, endIndent: 16),
          ...children,
          const SizedBox(height: 6),
        ],
      ),
    );
  }
}

class _DevTile extends StatelessWidget {
  const _DevTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    this.onTap,
    this.isDestructive = false,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback? onTap;
  final bool isDestructive;

  @override
  Widget build(BuildContext context) {
    final effectiveColor = isDestructive ? AppColors.critical : iconColor;
    return ListTile(
      leading: Container(
        width: 36, height: 36,
        decoration: BoxDecoration(
          color: effectiveColor.withAlpha(18),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, size: 18, color: effectiveColor),
      ),
      title: Text(title, style: TextStyle(color: isDestructive ? AppColors.critical : null)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary))
          : null,
      onTap: onTap,
      dense: true,
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({required this.label, required this.value, this.monospace = false});

  final String label;
  final String value;
  final bool monospace;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(flex: 2, child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: AppColors.textSecondary, fontWeight: FontWeight.w500))),
          const SizedBox(width: 8),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: AppColors.textPrimary,
                fontWeight: FontWeight.w600,
                fontFamily: monospace ? 'monospace' : null,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: TextStyle(color: AppColors.textSecondary))),
        ],
      ),
    );
  }
}
