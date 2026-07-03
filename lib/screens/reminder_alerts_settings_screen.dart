import 'dart:io';

import 'package:app_settings/app_settings.dart';
import 'package:flutter/material.dart';

import 'package:renew_wise/models/alert_style.dart';
import 'package:renew_wise/services/notification_service.dart';
import 'package:renew_wise/services/settings_service.dart';
import 'package:renew_wise/theme/app_theme.dart';

class ReminderAlertsSettingsScreen extends StatelessWidget {
  const ReminderAlertsSettingsScreen({
    super.key,
    required this.settingsService,
    required this.notificationService,
  });

  final SettingsService settingsService;
  final NotificationService notificationService;

  static Future<void> push(
    BuildContext context, {
    required SettingsService settingsService,
    required NotificationService notificationService,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ReminderAlertsSettingsScreen(
          settingsService: settingsService,
          notificationService: notificationService,
        ),
      ),
    );
  }

  Future<void> _openAndroidNotificationSettings() async {
    if (Platform.isAndroid) {
      await AppSettings.openAppSettings(type: AppSettingsType.notification);
    } else {
      await AppSettings.openAppSettings();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reminder Alerts')),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 640),
            child: ListenableBuilder(
              listenable: settingsService,
              builder: (context, _) {
                final ss = settingsService;
                return ListView(
                  children: [
                    _SectionLabel('Alert Defaults'),
                    _SettingsTile(
                      icon: Icons.notifications_active_outlined,
                      title: 'Default Alert Style',
                      subtitle: ss.defaultAlertStyle.dropdownLabel,
                      trailing: DropdownButton<AlertStyle>(
                        value: ss.defaultAlertStyle,
                        underline: const SizedBox.shrink(),
                        items: AlertStyle.values
                            .map(
                              (s) => DropdownMenuItem(
                                value: s,
                                child: Text(s.dropdownLabel),
                              ),
                            )
                            .toList(),
                        onChanged: (v) {
                          if (v != null) ss.setDefaultAlertStyle(v);
                        },
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
                    const Divider(height: 1),
                    _SectionLabel('Alert Behaviour'),
                    _SettingsTile(
                      icon: Icons.vibration_outlined,
                      title: 'Vibration',
                      subtitle: ss.notificationVibrationEnabled
                          ? 'Vibrate on reminders'
                          : 'Vibration off',
                      trailing: Switch(
                        value: ss.notificationVibrationEnabled,
                        activeThumbColor: AppColors.primaryGreen,
                        onChanged: ss.setNotificationVibrationEnabled,
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.volume_up_outlined,
                      title: 'Reminder Sound',
                      subtitle: ss.notificationSoundEnabled
                          ? 'Notification sounds enabled'
                          : 'Silent notifications',
                      trailing: Switch(
                        value: ss.notificationSoundEnabled,
                        activeThumbColor: AppColors.primaryGreen,
                        onChanged: ss.setNotificationSoundEnabled,
                      ),
                    ),
                    _SettingsTile(
                      icon: Icons.settings_outlined,
                      title: 'Use System Sound',
                      subtitle: ss.useSystemSound
                          ? 'Uses your device notification sound'
                          : 'Sound disabled at app level',
                      trailing: Switch(
                        value: ss.useSystemSound,
                        activeThumbColor: AppColors.primaryGreen,
                        onChanged: ss.setUseSystemSound,
                      ),
                    ),
                    const Divider(height: 1),
                    _SectionLabel('Android'),
                    _SettingsTile(
                      icon: Icons.tune_outlined,
                      title: 'Open Android Notification Settings',
                      subtitle:
                          'Customise RenewWise notification channels',
                      trailing: const Icon(Icons.chevron_right_rounded),
                      onTap: _openAndroidNotificationSettings,
                    ),
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

class _SectionLabel extends StatelessWidget {
  const _SectionLabel(this.title);
  final String title;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.fromLTRB(16, 20, 16, 4),
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
  const _SettingsTile({
    required this.icon,
    required this.title,
    this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: AppColors.primaryGreen.withAlpha(20),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, color: AppColors.primaryGreen, size: 20),
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
