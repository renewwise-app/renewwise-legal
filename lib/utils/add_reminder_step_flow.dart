import 'package:renew_wise/models/reminder_workflow_type.dart';

/// Single-question steps in the guided Add Reminder conversation.
enum AddReminderStepId {
  typeSelection,
  title,
  category,
  importance,
  alertStyle,
  eventDate,
  repeatFrequency,
  reminderSchedule,
  reminderTime,
  repeatEndToggle,
  repeatEndConfig,
  paymentToggle,
  paymentDetails,
  documents,
  notes,
  review,
}

abstract final class AddReminderStepFlow {
  static List<AddReminderStepId> build({
    required ReminderWorkflowType? workflowType,
    required bool isEditing,
    required bool paymentRequired,
    required bool repeatEndEnabled,
  }) {
    final type = workflowType;
    if (type == null && !isEditing) {
      return const [AddReminderStepId.typeSelection];
    }
    if (type == null) {
      return const [
        AddReminderStepId.title,
        AddReminderStepId.review,
      ];
    }

    final steps = <AddReminderStepId>[
      if (!isEditing) AddReminderStepId.typeSelection,
      AddReminderStepId.title,
      AddReminderStepId.category,
      AddReminderStepId.importance,
      AddReminderStepId.alertStyle,
    ];

    switch (type) {
      case ReminderWorkflowType.oneTime:
        steps.addAll([
          AddReminderStepId.eventDate,
          AddReminderStepId.reminderTime,
          AddReminderStepId.reminderSchedule,
        ]);
      case ReminderWorkflowType.recurring:
        steps.addAll([
          AddReminderStepId.repeatFrequency,
          AddReminderStepId.eventDate,
          AddReminderStepId.reminderTime,
          AddReminderStepId.repeatEndToggle,
        ]);
        if (repeatEndEnabled) {
          steps.add(AddReminderStepId.repeatEndConfig);
        }
      case ReminderWorkflowType.renewal:
        steps.addAll([
          AddReminderStepId.eventDate,
          AddReminderStepId.repeatFrequency,
          AddReminderStepId.reminderSchedule,
          AddReminderStepId.reminderTime,
        ]);
    }

    steps.addAll([
      AddReminderStepId.paymentToggle,
      if (paymentRequired) AddReminderStepId.paymentDetails,
      AddReminderStepId.documents,
      AddReminderStepId.notes,
      AddReminderStepId.review,
    ]);

    return steps;
  }

  static String progressLabel(AddReminderStepId step) {
    return switch (step) {
      AddReminderStepId.typeSelection => 'Type',
      AddReminderStepId.title ||
      AddReminderStepId.category ||
      AddReminderStepId.importance ||
      AddReminderStepId.alertStyle =>
        'Information',
      AddReminderStepId.eventDate ||
      AddReminderStepId.repeatFrequency ||
      AddReminderStepId.reminderSchedule ||
      AddReminderStepId.reminderTime ||
      AddReminderStepId.repeatEndToggle ||
      AddReminderStepId.repeatEndConfig =>
        'Schedule',
      AddReminderStepId.paymentToggle ||
      AddReminderStepId.paymentDetails ||
      AddReminderStepId.documents ||
      AddReminderStepId.notes =>
        'Optional',
      AddReminderStepId.review => 'Review',
    };
  }

  static List<String> progressLabels(List<AddReminderStepId> steps) {
    final labels = <String>[];
    for (final step in steps) {
      final label = progressLabel(step);
      if (labels.isEmpty || labels.last != label) {
        labels.add(label);
      }
    }
    return labels;
  }

  static int progressIndex(List<AddReminderStepId> steps, int stepIndex) {
    if (stepIndex < 0 || stepIndex >= steps.length) return 0;
    final current = progressLabel(steps[stepIndex]);
    final labels = progressLabels(steps);
    return labels.indexOf(current).clamp(0, labels.length - 1);
  }
}
