import 'package:flutter/material.dart';

import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/models/renewal_status.dart';
import 'package:renew_wise/services/notification_service.dart';
import 'package:renew_wise/services/reminder_state_service.dart';
import 'package:renew_wise/services/renewal_service.dart';
import 'package:renew_wise/utils/expense_completion_dialog.dart';
import 'package:renew_wise/utils/recurrence_utils.dart';
import 'package:renew_wise/utils/reminder_lifecycle_feedback.dart';
import 'package:renew_wise/utils/repeat_date_utils.dart';
import 'package:renew_wise/widgets/common/app_dialogs.dart';
import 'package:renew_wise/widgets/common/app_feedback.dart';

/// Shared completion flow for notification actions and in-app Complete.
class RenewalCompletionFlow {
  RenewalCompletionFlow({
    required this.renewalService,
    required this.reminderStateService,
    required this.notificationService,
    required this.defaultReminderTimeMinutes,
  });

  final RenewalService renewalService;
  final ReminderStateService reminderStateService;
  final NotificationService notificationService;
  final int defaultReminderTimeMinutes;

  Future<bool> run(
    BuildContext context,
    Renewal renewal, {
    required String completionMethod,
  }) async {
    if (RecurrenceUtils.isRecurring(renewal)) {
      return _completeRecurring(context, renewal, completionMethod);
    }
    return _completeOneTime(context, renewal, completionMethod);
  }

  Future<ExpenseCompletionOutcome> _maybeRecordExpense(
    BuildContext context,
    Renewal renewal,
  ) async {
    if (!context.mounted) return const ExpenseCompletionOutcome();
    return ExpenseCompletionDialog.maybeRecord(
      context: context,
      renewal: renewal,
      currency: renewal.currency,
    );
  }

  Future<bool> _completeOneTime(
    BuildContext context,
    Renewal renewal,
    String completionMethod,
  ) async {
    renewalService.updateRenewal(
      renewal.copyWith(
        status: RenewalStatus.paid,
        updatedAt: DateTime.now(),
      ),
    );

    await notificationService.cancelReminders(renewal.id);
    await reminderStateService.recordCompletion(
      renewal: renewal,
      method: completionMethod,
    );

    if (!context.mounted) return false;

    final expense = await _maybeRecordExpense(context, renewal);

    if (!context.mounted) return false;

    final moveToHistory = await AppDialogs.completeHistory(context);

    if (!context.mounted) return false;

    ReminderLifecycleFeedback.show(
      context,
      renewal: renewal,
      movedToHistory: moveToHistory,
      expense: expense,
    );

    if (moveToHistory) AppHaptics.confirm();
    return moveToHistory;
  }

  Future<bool> _completeRecurring(
    BuildContext context,
    Renewal renewal,
    String completionMethod,
  ) async {
    await notificationService.cancelReminders(renewal.id);

    if (!context.mounted) return false;

    final moveToHistory = await AppDialogs.completeHistory(context);

    if (moveToHistory) {
      await reminderStateService.recordCompletion(
        renewal: renewal,
        method: completionMethod,
      );
    }

    if (!context.mounted) return false;

    final expense = await _maybeRecordExpense(context, renewal);

    if (!context.mounted) return false;

    final now = DateTime.now();
    final completedCount = renewal.recurrenceCompletedCount + 1;
    final nextDate = RepeatDateUtils.nextOccurrence(
      renewal.renewalDate,
      renewal.repeatCycle,
    );
    final seriesEnded = RecurrenceUtils.shouldEndSeries(
      renewal: renewal,
      completedCount: completedCount,
      nextOccurrenceDate: nextDate,
    );

    if (seriesEnded || nextDate == null) {
      renewalService.updateRenewal(
        renewal.copyWith(
          status: RenewalStatus.paid,
          recurrenceCompletedCount: completedCount,
          updatedAt: now,
        ),
      );
    } else {
      renewalService.updateRenewal(
        renewal.copyWith(
          renewalDate: nextDate,
          status: RenewalStatus.upcoming,
          recurrenceCompletedCount: completedCount,
          updatedAt: now,
        ),
      );
      await reminderStateService.clearCompletionForNextOccurrence(renewal.id);
      await notificationService.scheduleReminders(
        renewal.copyWith(
          renewalDate: nextDate,
          status: RenewalStatus.upcoming,
          recurrenceCompletedCount: completedCount,
        ),
        defaultTimeMinutes: defaultReminderTimeMinutes,
      );
    }

    if (!context.mounted) return false;

    ReminderLifecycleFeedback.show(
      context,
      renewal: renewal,
      movedToHistory: moveToHistory,
      expense: expense,
    );

    if (moveToHistory) AppHaptics.confirm();
    return moveToHistory;
  }
}
