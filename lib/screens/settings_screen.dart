import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:renew_wise/models/renewal_currency.dart';
import 'package:renew_wise/screens/backup_restore_screen.dart';
import 'package:renew_wise/screens/sharing_settings_screen.dart';
import 'package:renew_wise/screens/developer_screen.dart';
import 'package:renew_wise/services/backup/backup_service.dart';
import 'package:renew_wise/services/developer_service.dart';
import 'package:renew_wise/services/event_extras_service.dart';
import 'package:renew_wise/services/notification_service.dart';
import 'package:renew_wise/screens/document_vault_screen.dart';
import 'package:renew_wise/screens/privacy_trust_screen.dart';
import 'package:renew_wise/screens/reminder_alerts_settings_screen.dart';
import 'package:renew_wise/utils/privacy_permission_dialogs.dart';
import 'package:renew_wise/utils/feature_purpose_messaging.dart';
import 'package:renew_wise/services/reminder_state_service.dart';
import 'package:renew_wise/utils/vault_list_utils.dart';
import 'package:renew_wise/services/sharing_service.dart';
import 'package:renew_wise/services/renewal_service.dart';
import 'package:renew_wise/services/settings_service.dart';
import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/widgets/common/app_dialogs.dart';
import 'package:renew_wise/widgets/common/app_feedback.dart';
import 'package:renew_wise/widgets/common/app_shimmer.dart';
import 'package:renew_wise/widgets/common/feature_purpose_subtitle.dart';
import 'package:renew_wise/widgets/backup_status_badge.dart';
import 'package:renew_wise/widgets/renew_wise_logo.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({
    super.key,
    required this.settingsService,
    required this.renewalService,
    required this.notificationService,
    required this.eventExtrasService,
    required this.reminderStateService,
    this.backupService,
    this.sharingService,
    this.developerService,
  });

  final SettingsService settingsService;
  final RenewalService renewalService;
  final NotificationService notificationService;
  final EventExtrasService eventExtrasService;
  final ReminderStateService reminderStateService;
  final BackupService? backupService;
  final SharingService? sharingService;
  final DeveloperService? developerService;

  static Future<void> push(
    BuildContext context, {
    required SettingsService settingsService,
    required RenewalService renewalService,
    required NotificationService notificationService,
    required EventExtrasService eventExtrasService,
    required ReminderStateService reminderStateService,
    BackupService? backupService,
    SharingService? sharingService,
    DeveloperService? developerService,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SettingsScreen(
          settingsService: settingsService,
          renewalService: renewalService,
          notificationService: notificationService,
          eventExtrasService: eventExtrasService,
          reminderStateService: reminderStateService,
          backupService: backupService,
          sharingService: sharingService,
          developerService: developerService,
        ),
      ),
    );
  }

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen>
    with WidgetsBindingObserver {
  bool _notifGranted = false;
  bool _exactAlarmGranted = false;
  bool _loadingPerms = true;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _refreshPermissions();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  /// Re-check permissions when the user returns from system settings.
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _refreshPermissions();
    }
  }

  Future<void> _refreshPermissions() async {
    final notif =
        await widget.notificationService.areNotificationsEnabled();
    final exact =
        await widget.notificationService.canScheduleExactAlarms();
    if (mounted) {
      setState(() {
        _notifGranted = notif;
        _exactAlarmGranted = exact;
        _loadingPerms = false;
      });
    }
  }

  // ─── Actions ─────────────────────────────────────────────────────────────

  Future<void> _requestNotifPermission() async {
    if (Platform.isAndroid) {
      final proceed =
          await PrivacyPermissionDialogs.explainNotifications(context);
      if (!proceed || !mounted) return;
    }
    final granted = await widget.notificationService.requestPermission();
    if (mounted) setState(() => _notifGranted = granted);
    if (!granted && mounted) {
      AppFeedback.info(
        context,
        'Notifications are off. Open Settings › Apps › RenewWise to enable them.',
      );
    }
  }

  Future<void> _requestExactAlarms() async {
    await widget.notificationService.requestExactAlarmsPermission();
    // The result is checked when the app resumes (via WidgetsBindingObserver).
  }

  Future<void> _onNotificationsToggle(bool enabled) async {
    await widget.settingsService.setNotificationsEnabled(enabled);
    if (enabled) {
      for (final r in widget.renewalService.renewals) {
        await widget.notificationService.scheduleReminders(
          r,
          defaultTimeMinutes:
              widget.settingsService.defaultReminderTimeMinutes,
        );
      }
    } else {
      await widget.notificationService.cancelAll();
    }
  }

  Future<void> _pickDefaultReminderTime() async {
    final current = TimeOfDay(
      hour: widget.settingsService.defaultReminderHour,
      minute: widget.settingsService.defaultReminderMinute,
    );
    final picked = await showTimePicker(
      context: context,
      initialTime: current,
      helpText: 'Default reminder time',
    );
    if (picked != null && mounted) {
      await widget.settingsService.setDefaultReminderTime(
        picked.hour,
        picked.minute,
      );
    }
  }

  Future<void> _editName() async {
    final controller = TextEditingController(
      text: widget.settingsService.userName,
    );
    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final canSave = controller.text.trim().isNotEmpty;
            return AlertDialog(
              title: const Text('Name'),
              content: TextField(
                controller: controller,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  hintText: 'Enter your name',
                  labelText: 'Your name',
                ),
                onChanged: (_) => setDialogState(() {}),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx, false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: canSave
                      ? () => Navigator.pop(ctx, true)
                      : null,
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
    final name = controller.text.trim();
    controller.dispose();
    if (saved != true || !mounted || name.isEmpty) return;
    await widget.settingsService.setUserName(name);
  }

  Future<void> _confirmClearAll() async {
    final confirmed = await AppDialogs.clearAllData(context);
    if (!confirmed || !mounted) return;
    await widget.renewalService.clearAll();
    await widget.eventExtrasService.clearAll();
    if (mounted) {
      AppFeedback.show(
        context,
        message: 'All data cleared. You can start fresh anytime.',
        haptic: true,
      );
    }
  }

  String _backupSubtitle(BackupService backup) {
    final ss = widget.settingsService;
    if (!backup.isConnected) {
      return 'Connect Google Drive — your data stays yours';
    }
    if (ss.backupLastAt != null) {
      return 'Last backup · ${backup.formatStorage(ss.backupStorageBytes)} in Drive';
    }
    return 'Ready to back up to your Google Drive';
  }

  String _fmtTime(int hour, int minute) {
    final h = hour % 12 == 0 ? 12 : hour % 12;
    final m = minute.toString().padLeft(2, '0');
    final period = hour < 12 ? 'AM' : 'PM';
    return '$h:$m $period';
  }

  // ─── Build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListenableBuilder(
              listenable: widget.settingsService,
              builder: (context, _) {
                final ss = widget.settingsService;
                return ListView(
                  children: [
                    Padding(
                      padding: EdgeInsets.fromLTRB(
                        AppSpacing.page,
                        AppSpacing.sm,
                        AppSpacing.page,
                        AppSpacing.lg,
                      ),
                      child: const FeaturePurposeSubtitle(
                        FeaturePurposeMessaging.settings,
                      ),
                    ),
                    // ── PERSONALIZATION ───────────────────────────────
                    _SectionLabel('Personalization'),

                    _SettingsTile(
                      icon: Icons.person_outline,
                      title: 'Name',
                      subtitle: ss.userName.isEmpty
                          ? 'Not set'
                          : ss.userName,
                      onTap: _editName,
                    ),

                    const Divider(height: 1),

                    // ── GENERAL ────────────────────────────────────────
                    _SectionLabel('General'),

                    _SettingsTile(
                      icon: Icons.notifications_outlined,
                      title: 'Notifications',
                      subtitle: ss.notificationsEnabled
                          ? 'Reminders are active'
                          : 'All reminders are paused',
                      trailing: Switch(
                        value: ss.notificationsEnabled,
                        activeThumbColor: AppColors.primaryGreen,
                        onChanged: _onNotificationsToggle,
                      ),
                    ),

                    // Notification permission status
                    _PermissionTile(
                      icon: Icons.verified_user_outlined,
                      title: 'Notification Permission',
                      loading: _loadingPerms,
                      granted: _notifGranted,
                      grantedText: 'Granted – notifications will appear',
                      deniedText: 'Denied – tap to request',
                      onRequest: _requestNotifPermission,
                    ),

                    // Exact alarm permission status
                    _PermissionTile(
                      icon: Icons.alarm_outlined,
                      title: 'Exact Alarms',
                      loading: _loadingPerms,
                      granted: _exactAlarmGranted,
                      grantedText: 'Granted – notifications fire on time',
                      deniedText:
                          'Not granted – tap to open Alarms & Reminders',
                      onRequest: _requestExactAlarms,
                    ),

                    const Divider(height: 1),

                    _SectionLabel('Reminder Behaviour'),

                    _SettingsTile(
                      icon: Icons.alarm_outlined,
                      title: 'Alarm Behaviour for Critical Reminders',
                      subtitle: ss.alarmStyleAlertsEnabled
                          ? 'Critical reminders can wake the screen'
                          : 'Critical reminders use standard alerts only',
                      trailing: Switch(
                        value: ss.alarmStyleAlertsEnabled,
                        activeThumbColor: AppColors.primaryGreen,
                        onChanged: ss.setAlarmStyleAlertsEnabled,
                      ),
                    ),

                    _SettingsTile(
                      icon: Icons.snooze_outlined,
                      title: 'Default Snooze Duration',
                      subtitle: '${ss.defaultSnoozeMinutes} minutes',
                      trailing: DropdownButton<int>(
                        value: ss.defaultSnoozeMinutes,
                        underline: const SizedBox.shrink(),
                        items: SettingsService.alertSnoozeOptions
                            .map(
                              (m) => DropdownMenuItem(
                                value: m,
                                child: Text('$m min'),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) ss.setDefaultSnoozeMinutes(v);
                        },
                      ),
                    ),

                    _SettingsTile(
                      icon: Icons.volume_up_outlined,
                      title: 'Notification Sound',
                      subtitle: ss.notificationSoundEnabled
                          ? 'Reminder sounds enabled'
                          : 'Silent reminders',
                      trailing: Switch(
                        value: ss.notificationSoundEnabled,
                        activeThumbColor: AppColors.primaryGreen,
                        onChanged: ss.setNotificationSoundEnabled,
                      ),
                    ),

                    _SettingsTile(
                      icon: Icons.vibration_outlined,
                      title: 'Vibration',
                      subtitle: ss.notificationVibrationEnabled
                          ? 'Vibrate on high and critical reminders'
                          : 'Vibration off',
                      trailing: Switch(
                        value: ss.notificationVibrationEnabled,
                        activeThumbColor: AppColors.primaryGreen,
                        onChanged: ss.setNotificationVibrationEnabled,
                      ),
                    ),

                    _SettingsTile(
                      icon: Icons.flip_to_front_outlined,
                      title: 'Heads-up Notifications',
                      subtitle: ss.headsUpNotificationsEnabled
                          ? 'Important reminders pop over apps'
                          : 'Delivered quietly in the shade',
                      trailing: Switch(
                        value: ss.headsUpNotificationsEnabled,
                        activeThumbColor: AppColors.primaryGreen,
                        onChanged: ss.setHeadsUpNotificationsEnabled,
                      ),
                    ),

                    const Divider(height: 1),

                    // ── DEFAULTS ──────────────────────────────────────
                    _SectionLabel('Defaults'),

                    _SettingsTile(
                      icon: Icons.currency_exchange_rounded,
                      title: 'Default Currency',
                      subtitle: '${ss.defaultCurrency.code} – for new events',
                      trailing: DropdownButton<RenewalCurrency>(
                        value: ss.defaultCurrency,
                        underline: const SizedBox.shrink(),
                        onChanged: (c) {
                          if (c != null) ss.setDefaultCurrency(c);
                        },
                        items: RenewalCurrency.values
                            .map(
                              (c) => DropdownMenuItem(
                                value: c,
                                child: Text('${c.symbol}  ${c.code}'),
                              ),
                            )
                            .toList(),
                      ),
                    ),

                    _SettingsTile(
                      icon: Icons.alarm_outlined,
                      title: 'Default Reminder Lead',
                      subtitle:
                          'Remind ${ss.defaultReminderLeadDays} days before event',
                      trailing: DropdownButton<int>(
                        value: ss.defaultReminderLeadDays,
                        underline: const SizedBox.shrink(),
                        onChanged: (d) {
                          if (d != null) ss.setDefaultReminderLeadDays(d);
                        },
                        items: SettingsService.reminderLeadDayOptions
                            .map(
                              (d) => DropdownMenuItem(
                                value: d,
                                child: Text(d == 1 ? '1 day' : '$d days'),
                              ),
                            )
                            .toList(),
                      ),
                    ),

                    _SettingsTile(
                      icon: Icons.schedule_outlined,
                      title: 'Default Reminder Time',
                      subtitle:
                          'Fire at ${_fmtTime(ss.defaultReminderHour, ss.defaultReminderMinute)}',
                      onTap: _pickDefaultReminderTime,
                      trailing: Icon(
                        Icons.chevron_right_rounded,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),

                    const Divider(height: 1),

                    _SectionLabel('Sharing'),

                    _SettingsTile(
                      icon: Icons.groups_outlined,
                      iconColor: AppColors.teal,
                      title: 'Family & Sharing',
                      subtitle: 'Version 1.0 · Local Sharing Ready',
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => SharingSettingsScreen.push(context),
                    ),

                    const Divider(height: 1),

                    // ── DATA ──────────────────────────────────────────
                    _SectionLabel('Data'),

                    _SettingsTile(
                      icon: Icons.folder_outlined,
                      iconColor: AppColors.primary,
                      title: 'Document Vault',
                      subtitle:
                          '${widget.eventExtrasService.totalDocumentCount} documents · ${VaultListUtils.formatBytes(widget.eventExtrasService.totalStorageBytes)}',
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => DocumentVaultScreen.push(
                        context,
                        eventExtrasService: widget.eventExtrasService,
                        renewalService: widget.renewalService,
                        settingsService: widget.settingsService,
                        reminderStateService: widget.reminderStateService,
                        notificationService: widget.notificationService,
                      ),
                    ),

                    const Divider(height: 1),

                    _SectionLabel('Backup & Restore'),

                    const _BackupStatusTile(
                      icon: Icons.smartphone_outlined,
                      label: 'Device Only',
                      description: 'Stored securely on this phone',
                      selected: true,
                    ),
                    const SizedBox(height: 10),
                    _BackupStatusTile(
                      icon: Icons.cloud_outlined,
                      label: 'Cloud Backup',
                      description: widget.backupService?.isConnected == true
                          ? 'Connected to Google Drive'
                          : 'Not configured',
                      selected: false,
                    ),
                    const SizedBox(height: 10),

                    _SettingsTile(
                      icon: Icons.cloud_outlined,
                      iconColor: AppColors.teal,
                      title: 'Backup & Restore',
                      subtitle: widget.backupService == null
                          ? 'Google Drive backup'
                          : _backupSubtitle(widget.backupService!),
                      trailing: widget.backupService == null
                          ? const Icon(Icons.chevron_right_rounded)
                          : BackupStatusBadge(
                              status: widget.backupService!.displayStatus,
                            ),
                      onTap: widget.backupService == null
                          ? null
                          : () => BackupRestoreScreen.push(
                                context,
                                backupService: widget.backupService!,
                                settingsService: widget.settingsService,
                              ),
                    ),

                    _SettingsTile(
                      icon: Icons.delete_outline_rounded,
                      title: 'Clear All Data',
                      subtitle: 'Permanently delete all events and reminders',
                      iconColor: AppColors.critical,
                      onTap: _confirmClearAll,
                    ),

                    const Divider(height: 1),

                    _SectionLabel('Reminder Alerts'),

                    _SettingsTile(
                      icon: Icons.notifications_active_outlined,
                      title: 'Reminder Alerts',
                      subtitle:
                          'Default alert style, snooze, and Android channels',
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => ReminderAlertsSettingsScreen.push(
                        context,
                        settingsService: widget.settingsService,
                        notificationService: widget.notificationService,
                      ),
                    ),

                    const Divider(height: 1),

                    // ── PRIVACY & TRUST ─────────────────────────────
                    _SectionLabel('Privacy & Trust'),

                    _SettingsTile(
                      icon: Icons.verified_user_outlined,
                      title: 'Privacy & Trust',
                      subtitle:
                          'How RenewWise protects your information',
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: () => PrivacyTrustScreen.push(
                        context,
                        settingsService: widget.settingsService,
                        renewalService: widget.renewalService,
                        eventExtrasService: widget.eventExtrasService,
                        reminderStateService: widget.reminderStateService,
                        notificationService: widget.notificationService,
                      ),
                    ),

                    const Divider(height: 1),

                    // ── SUPPORT ───────────────────────────────────────
                    _SectionLabel('Support'),

                    _SettingsTile(
                      icon: Icons.feedback_outlined,
                      title: 'Send Feedback',
                      subtitle: 'Coming Soon – help us improve RenewWise',
                      iconColor: AppColors.primary.withAlpha(120),
                      trailing: _ComingSoonBadge(),
                    ),

                    const Divider(height: 1),

                    // ── ABOUT ─────────────────────────────────────────
                    _SectionLabel('About'),

                    // Brand card
                    _AboutBrandCard(),

                    _SettingsTile(
                      icon: Icons.privacy_tip_outlined,
                      title: 'Privacy Policy',
                      subtitle: 'Coming Soon',
                      iconColor: AppColors.primary.withAlpha(120),
                      trailing: _ComingSoonBadge(),
                    ),

                    // ── DEVELOPER (debug builds only) ─────────────────
                    if (!kReleaseMode && widget.developerService != null) ...[
                      const Divider(height: 1),
                      _SectionLabel('Developer Tools'),
                      _SettingsTile(
                        icon: Icons.bug_report_rounded,
                        iconColor: AppColors.critical,
                        title: 'Open Developer Mode',
                        subtitle: 'DEBUG BUILD — full control center',
                        trailing: const Icon(Icons.chevron_right_rounded),
                        onTap: () => DeveloperScreen.push(
                          context,
                          developerService: widget.developerService!,
                          settingsService: widget.settingsService,
                          renewalService: widget.renewalService,
                          notificationService: widget.notificationService,
                          backupService: widget.backupService,
                          sharingService: widget.sharingService,
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),
                  ],
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────── Private widgets ────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.fromLTRB(AppSpacing.page, 20, AppSpacing.page, 4),
        child: Text(
          title.toUpperCase(),
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: AppColors.primaryGreen,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.8,
              ),
        ),
      );
}

class _SettingsTile extends StatelessWidget {
  _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
    Color? iconColor,
  }) : iconColor = iconColor ?? AppColors.primaryGreen;

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title),
      subtitle: subtitle != null
          ? Text(
              subtitle!,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            )
          : null,
      trailing: trailing,
      onTap: onTap,
    );
  }
}

/// A settings tile that shows a permission status badge and a request button.
class _PermissionTile extends StatelessWidget {
  const _PermissionTile({
    required this.icon,
    required this.title,
    required this.loading,
    required this.granted,
    required this.grantedText,
    required this.deniedText,
    required this.onRequest,
  });

  final IconData icon;
  final String title;
  final bool loading;
  final bool granted;
  final String grantedText;
  final String deniedText;
  final VoidCallback onRequest;

  @override
  Widget build(BuildContext context) {
    final green = AppColors.primaryGreen;
    const red = AppColors.critical;
    final iconColor = loading
        ? Theme.of(context).colorScheme.onSurfaceVariant
        : granted
            ? green
            : red;

    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: iconColor.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: loading
            ? AppShimmerBox(
                height: 20,
                width: 20,
                borderRadius: BorderRadius.circular(10),
              )
            : Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(title),
      subtitle: Text(
        loading ? 'Checking…' : (granted ? grantedText : deniedText),
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: loading
                  ? Theme.of(context).colorScheme.onSurfaceVariant
                  : granted
                      ? green
                      : red,
            ),
      ),
      trailing: granted
          ? Icon(Icons.check_circle_outline_rounded,
              color: AppColors.primaryGreen)
          : loading
              ? null
              : FilledButton.tonal(
                  // Override the global theme's Size.fromHeight(56) (minWidth=∞)
                  // which would produce invalid BoxConstraints in ListTile.trailing.
                  style: FilledButton.styleFrom(
                    minimumSize: const Size(64, 32),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  onPressed: onRequest,
                  child: const Text('Grant'),
                ),
    );
  }
}

class _ComingSoonBadge extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.onSurfaceVariant.withAlpha(20),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        'Soon',
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w600,
            ),
      ),
    );
  }
}

/// Brand card shown in the About section of Settings.
class _AboutBrandCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.page, vertical: 8),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(10),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: AppColors.primary.withAlpha(35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Logo + name + version row
          Row(
            children: [
              const RenewWiseLogo(size: 52),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'RenewWise',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Because Peace of Mind Matters.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withAlpha(20),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'Version 1.0.0',
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          Divider(color: AppColors.primary.withAlpha(30), height: 1),
          const SizedBox(height: 12),

          // Brand pillars
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _PillarChip(
                icon: Icons.lock_outline_rounded,
                label: 'Privacy First',
              ),
              _PillarChip(
                icon: Icons.offline_bolt_outlined,
                label: 'Offline First',
              ),
              _PillarChip(
                icon: Icons.block_rounded,
                label: 'No Advertisements',
              ),
              _PillarChip(
                icon: Icons.person_outline_rounded,
                label: 'Your Data',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PillarChip extends StatelessWidget {
  const _PillarChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.primary.withAlpha(18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withAlpha(45)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
          ),
        ],
      ),
    );
  }
}

class _BackupStatusTile extends StatelessWidget {
  const _BackupStatusTile({
    required this.icon,
    required this.label,
    required this.description,
    required this.selected,
  });

  final IconData icon;
  final String label;
  final String description;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: AppSpacing.page),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: selected
            ? AppColors.primary.withAlpha(12)
            : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected
              ? AppColors.primary.withAlpha(80)
              : const Color(0xFFE2E8F0),
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 22,
            color: selected ? AppColors.primary : const Color(0xFF64748B),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
              ],
            ),
          ),
          if (selected)
            Icon(
              Icons.check_circle_rounded,
              color: AppColors.primary,
              size: 20,
            ),
        ],
      ),
    );
  }
}
