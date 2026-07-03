import 'package:flutter/material.dart';

import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/screens/critical_alert_screen.dart';
import 'package:renew_wise/screens/event_details_screen.dart';
import 'package:renew_wise/services/event_extras_service.dart';
import 'package:renew_wise/services/notification_service.dart';
import 'package:renew_wise/services/reminder_state_service.dart';
import 'package:renew_wise/services/renewal_completion_flow.dart';
import 'package:renew_wise/services/renewal_service.dart';
import 'package:renew_wise/services/settings_service.dart';
import 'package:renew_wise/services/sharing_service.dart';
import 'package:renew_wise/utils/notification_level_resolver.dart';
import 'package:renew_wise/utils/notification_payload.dart';
import 'package:renew_wise/utils/reminder_reschedule_dialog.dart';
import 'package:renew_wise/widgets/common/app_feedback.dart';

/// Handles notification taps and action buttons.
class NotificationActionHandler {
  NotificationActionHandler({
    required this.navigatorKey,
    required this.renewalService,
    required this.settingsService,
    required this.reminderStateService,
    required this.notificationService,
    required this.eventExtrasService,
    this.sharingService,
  });

  final GlobalKey<NavigatorState> navigatorKey;
  final RenewalService renewalService;
  final SettingsService settingsService;
  final ReminderStateService reminderStateService;
  final NotificationService notificationService;
  final EventExtrasService eventExtrasService;
  final SharingService? sharingService;

  BuildContext? get _context => navigatorKey.currentContext;

  Renewal? _findRenewal(String id) {
    if (id.startsWith('test_')) return null;
    try {
      return renewalService.renewals.firstWhere((r) => r.id == id);
    } catch (_) {
      return null;
    }
  }

  Future<void> handle({String? rawPayload, String? actionId}) async {
    final decoded = NotificationPayload.decode(rawPayload);
    if (decoded == null) return;

    final action = actionId ?? decoded.action;
    final renewal = _findRenewal(decoded.renewalId);
    if (renewal == null && !action.startsWith('test')) return;

    switch (action) {
      case NotificationPayload.actionView:
        if (renewal != null) {
          await reminderStateService.recordReminderSent(
            renewal.id,
            DateTime.now(),
          );
          await reminderStateService.markAcknowledged(renewal.id);
          await _openReminderUi(renewal);
        }
      case NotificationPayload.actionComplete:
        if (renewal != null) await _completeFlow(renewal);
      case NotificationPayload.actionSnooze5:
        if (renewal != null) await _snooze(renewal, const Duration(minutes: 5));
      case NotificationPayload.actionSnooze10:
        if (renewal != null) await _snooze(renewal, const Duration(minutes: 10));
      case NotificationPayload.actionSnooze30:
        if (renewal != null) await _snooze(renewal, const Duration(minutes: 30));
      case NotificationPayload.actionSnooze15:
        if (renewal != null) await _snooze(renewal, const Duration(minutes: 15));
      case NotificationPayload.actionSnooze60:
        if (renewal != null) await _snooze(renewal, const Duration(hours: 1));
      case NotificationPayload.actionSnoozeDefault:
        if (renewal != null) {
          await _snooze(
            renewal,
            Duration(minutes: settingsService.defaultSnoozeMinutes),
          );
        }
      case NotificationPayload.actionSnoozeTomorrow:
        if (renewal != null) await _snoozeTomorrow(renewal);
      case NotificationPayload.actionReschedule:
        if (renewal != null) await _reschedule(renewal);
      case NotificationPayload.actionDismiss:
        if (renewal != null) {
          await notificationService.cancelReminders(renewal.id);
          await reminderStateService.markAcknowledged(renewal.id);
        }
      default:
        if (renewal != null) await _openReminderUi(renewal);
    }
  }

  Future<void> _openReminderUi(Renewal renewal) async {
    if (NotificationLevelResolver.isCritical(renewal)) {
      await _openCriticalAlert(renewal);
    } else {
      await _openDetails(renewal);
    }
  }

  Future<void> _openCriticalAlert(Renewal renewal) async {
    final ctx = _context;
    if (ctx == null) return;
    if (settingsService.alarmStyleAlertsEnabled) {
      final canExact = await notificationService.canScheduleExactAlarms();
      if (!canExact) {
        await notificationService.requestExactAlarmsPermission();
      }
    }
    if (!ctx.mounted) return;
    await CriticalAlertScreen.show(
      ctx,
      renewal: renewal,
      renewalService: renewalService,
      settingsService: settingsService,
      reminderStateService: reminderStateService,
      notificationService: notificationService,
      eventExtrasService: eventExtrasService,
      sharingService: sharingService,
    );
  }

  Future<void> _openDetails(Renewal renewal) async {
    final ctx = _context;
    if (ctx == null) return;
    await EventDetailsScreen.push(
      ctx,
      renewal: renewal,
      renewalService: renewalService,
      settingsService: settingsService,
      reminderStateService: reminderStateService,
      notificationService: notificationService,
      eventExtrasService: eventExtrasService,
      sharingService: sharingService,
    );
  }

  Future<void> _reschedule(Renewal renewal) async {
    final ctx = _context;
    if (ctx == null) return;
    await ReminderRescheduleDialog.show(
      ctx,
      renewal: renewal,
      renewalService: renewalService,
      notificationService: notificationService,
      reminderStateService: reminderStateService,
      defaultReminderTimeMinutes: settingsService.defaultReminderTimeMinutes,
    );
  }

  Future<void> _snooze(Renewal renewal, Duration delay) async {
    if (!NotificationLevelResolver.supportsSnooze(renewal)) return;
    await notificationService.cancelReminders(renewal.id);
    await notificationService.scheduleSnooze(
      renewal,
      delay: delay,
      defaultTimeMinutes: settingsService.defaultReminderTimeMinutes,
    );
    _showSnack('Snoozed for ${_formatDuration(delay)}');
  }

  Future<void> _snoozeTomorrow(Renewal renewal) async {
    await _snooze(renewal, ReminderSnoozeOptions.untilTomorrow());
  }

  String _formatDuration(Duration d) {
    if (d.inHours >= 20) return 'until tomorrow';
    if (d.inHours >= 1) return '${d.inHours} hour${d.inHours == 1 ? '' : 's'}';
    return '${d.inMinutes} minutes';
  }

  Future<void> _completeFlow(Renewal renewal) async {
    final ctx = _context;
    if (ctx == null) return;

    await notificationService.cancelReminders(renewal.id);
    if (!ctx.mounted) return;

    await RenewalCompletionFlow(
      renewalService: renewalService,
      reminderStateService: reminderStateService,
      notificationService: notificationService,
      defaultReminderTimeMinutes: settingsService.defaultReminderTimeMinutes,
    ).run(ctx, renewal, completionMethod: 'notification');
  }

  void _showSnack(String message) {
    final ctx = _context;
    if (ctx == null) return;
    AppFeedback.info(ctx, message);
  }
}
