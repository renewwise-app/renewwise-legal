import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/models/repeat_cycle.dart';

enum SmartSuggestionAction {
  attachDocument,
  addAmount,
  addNotes,
  reschedule,
  prepareNextReminder,
  editReminderSchedule,
}

class SmartSuggestion {
  const SmartSuggestion({
    required this.action,
    required this.title,
    required this.subtitle,
  });

  final SmartSuggestionAction action;
  final String title;
  final String subtitle;
}

abstract final class SmartSuggestions {
  static List<SmartSuggestion> forRenewal(
    Renewal renewal, {
    int documentCount = 0,
  }) {
    final items = <SmartSuggestion>[];

    if (documentCount == 0) {
      items.add(
        const SmartSuggestion(
          action: SmartSuggestionAction.attachDocument,
          title: 'Attach Document',
          subtitle: 'Keep proof and details in one place',
        ),
      );
    }

    if (renewal.paymentRequired &&
        (renewal.amount == null || renewal.amount! <= 0)) {
      items.add(
        const SmartSuggestion(
          action: SmartSuggestionAction.addAmount,
          title: 'Add Amount',
          subtitle: 'Track what is due for this reminder',
        ),
      );
    }

    if (renewal.notes == null || renewal.notes!.trim().isEmpty) {
      items.add(
        const SmartSuggestion(
          action: SmartSuggestionAction.addNotes,
          title: 'Add Notes',
          subtitle: 'Capture account numbers or instructions',
        ),
      );
    }

    if (renewal.isOverdue) {
      items.add(
        const SmartSuggestion(
          action: SmartSuggestionAction.reschedule,
          title: 'Reschedule',
          subtitle: 'Set a new date for this overdue reminder',
        ),
      );
    }

    if (renewal.repeatCycle != RepeatCycle.oneTime &&
        renewal.daysRemaining >= 0 &&
        renewal.daysRemaining <= 14) {
      items.add(
        const SmartSuggestion(
          action: SmartSuggestionAction.prepareNextReminder,
          title: 'Prepare next reminder',
          subtitle: 'Recurring event is approaching — review details',
        ),
      );
    }

    final schedule = renewal.customReminderDates.isNotEmpty
        ? renewal.customReminderDates.length
        : renewal.reminderSchedule.length;
    if (schedule < 2) {
      items.add(
        const SmartSuggestion(
          action: SmartSuggestionAction.editReminderSchedule,
          title: 'Improve reminder schedule',
          subtitle: 'Add more lead times for better coverage',
        ),
      );
    }

    return items;
  }
}
