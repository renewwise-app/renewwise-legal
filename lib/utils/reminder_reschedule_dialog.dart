import 'package:flutter/material.dart';

import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/services/notification_service.dart';
import 'package:renew_wise/services/renewal_service.dart';
import 'package:renew_wise/services/reminder_state_service.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/utils/date_utils.dart';
import 'package:renew_wise/widgets/common/app_feedback.dart';

/// Reschedule a reminder to a new date and time without opening the full editor.
abstract final class ReminderRescheduleDialog {
  static Future<bool> show(
    BuildContext context, {
    required Renewal renewal,
    required RenewalService renewalService,
    required NotificationService notificationService,
    required ReminderStateService reminderStateService,
    required int defaultReminderTimeMinutes,
  }) async {
    var selectedDate = RenewalDateUtils.dateOnly(renewal.renewalDate);
    final timeMinutes =
        renewal.reminderTimeMinutes ?? defaultReminderTimeMinutes;
    var selectedTime = TimeOfDay(
      hour: timeMinutes ~/ 60,
      minute: timeMinutes % 60,
    );

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setLocal) {
          return AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: AppRadius.dialogBorder,
            ),
            title: const Text('Reschedule Reminder'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: const Text('Date'),
                  subtitle: Text(
                    RenewalDateUtils.formatDisplayDate(selectedDate),
                  ),
                  onTap: () async {
                    final picked = await RenewalDateUtils.pickExpiryDate(
                      context,
                      helpText: 'Select new date',
                      initialDate: selectedDate,
                    );
                    if (picked != null) {
                      setLocal(() => selectedDate = picked);
                    }
                  },
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.access_time_rounded),
                  title: const Text('Time'),
                  subtitle: Text(selectedTime.format(context)),
                  onTap: () async {
                    final picked = await showTimePicker(
                      context: context,
                      initialTime: selectedTime,
                      helpText: 'Reminder time',
                    );
                    if (picked != null) {
                      setLocal(() => selectedTime = picked);
                    }
                  },
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );

    if (saved != true || !context.mounted) return false;

    final newDateTime = DateTime(
      selectedDate.year,
      selectedDate.month,
      selectedDate.day,
      selectedTime.hour,
      selectedTime.minute,
    );
    final updatedMinutes = selectedTime.hour * 60 + selectedTime.minute;

    renewalService.updateRenewal(
      renewal.copyWith(
        renewalDate: newDateTime,
        reminderTimeMinutes: updatedMinutes,
        updatedAt: DateTime.now(),
      ),
    );

    await notificationService.cancelReminders(renewal.id);
    await notificationService.scheduleReminders(
      renewal.copyWith(
        renewalDate: newDateTime,
        reminderTimeMinutes: updatedMinutes,
      ),
      defaultTimeMinutes: defaultReminderTimeMinutes,
    );
    await reminderStateService.markAcknowledged(renewal.id);

    if (context.mounted) {
      AppFeedback.success(
        context,
        'Rescheduled to ${RenewalDateUtils.formatDisplayDate(newDateTime)} '
        'at ${selectedTime.format(context)}',
      );
    }
    return true;
  }
}
