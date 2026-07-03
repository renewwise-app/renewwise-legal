import 'package:renew_wise/models/recurrence_end_type.dart';
import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/models/repeat_cycle.dart';
import 'package:renew_wise/utils/date_utils.dart';

/// Recurrence options exposed in the add-reminder flow (Package 7B).
const kUserRecurrenceCycles = <RepeatCycle>[
  RepeatCycle.daily,
  RepeatCycle.weekdays,
  RepeatCycle.weekly,
  RepeatCycle.monthly,
  RepeatCycle.yearly,
];

abstract final class RecurrenceUtils {
  static bool isRecurring(Renewal renewal) =>
      renewal.repeatCycle != RepeatCycle.oneTime &&
      renewal.repeatCycle != RepeatCycle.custom;

  static bool isRecurringCycle(RepeatCycle cycle) =>
      cycle != RepeatCycle.oneTime && cycle != RepeatCycle.custom;

  /// Label shown in the add-reminder recurrence picker.
  static String cyclePickerLabel(RepeatCycle cycle) {
    return switch (cycle) {
      RepeatCycle.daily => 'Every Day',
      RepeatCycle.weekdays => 'Weekdays (Monday–Friday)',
      RepeatCycle.weekly => 'Every Week',
      RepeatCycle.monthly => 'Every Month',
      RepeatCycle.yearly => 'Every Year',
      _ => cycle.label,
    };
  }

  /// Display label for event details, e.g. "Every Day", "Every Month".
  static String recurringCycleLabel(RepeatCycle cycle) {
    return switch (cycle) {
      RepeatCycle.daily => 'Every Day',
      RepeatCycle.weekdays => 'Weekdays',
      RepeatCycle.weekly => 'Every Week',
      RepeatCycle.monthly => 'Every Month',
      RepeatCycle.yearly => 'Every Year',
      _ => cycle.label,
    };
  }

  static String repeatLabel(Renewal renewal) {
    if (!isRecurring(renewal)) return 'One Time';
    return recurringCycleLabel(renewal.repeatCycle);
  }

  static String endConditionSummary(Renewal renewal) {
    if (!isRecurring(renewal)) return 'One Time';

    return switch (renewal.recurrenceEndType) {
      RecurrenceEndType.never => 'Never Ends',
      RecurrenceEndType.endDate when renewal.recurrenceEndDate != null =>
        'Ends ${RenewalDateUtils.formatDisplayDate(renewal.recurrenceEndDate!)}',
      RecurrenceEndType.endDate => 'End On Date',
      RecurrenceEndType.occurrenceCount
          when renewal.recurrenceOccurrenceLimit != null =>
        'After ${renewal.recurrenceOccurrenceLimit} occurrence${renewal.recurrenceOccurrenceLimit == 1 ? '' : 's'}',
      RecurrenceEndType.occurrenceCount => 'After Number of Occurrences',
    };
  }

  /// Returns null when valid, otherwise an error message.
  static String? validate({
    required bool isRecurring,
    required RepeatCycle cycle,
    required DateTime? renewalDate,
    required RecurrenceEndType endType,
    required DateTime? endDate,
    required int? occurrenceLimit,
  }) {
    if (!isRecurring) return null;
    if (renewalDate == null) return 'Renewal date is required';

    if (!kUserRecurrenceCycles.contains(cycle)) {
      return 'Select a recurrence pattern';
    }

    switch (cycle) {
      case RepeatCycle.weekly:
        if (renewalDate.weekday < DateTime.monday ||
            renewalDate.weekday > DateTime.sunday) {
          return 'Weekly reminders require a valid weekday';
        }
      case RepeatCycle.monthly:
        if (renewalDate.day < 1 || renewalDate.day > 31) {
          return 'Monthly reminders require a day of the month';
        }
      case RepeatCycle.yearly:
        if (renewalDate.month < 1 ||
            renewalDate.month > 12 ||
            renewalDate.day < 1 ||
            renewalDate.day > 31) {
          return 'Yearly reminders require a valid calendar date';
        }
      default:
        break;
    }

    switch (endType) {
      case RecurrenceEndType.never:
        return null;
      case RecurrenceEndType.endDate:
        if (endDate == null) return 'Select when this reminder should stop';
        final today = RenewalDateUtils.dateOnly(DateTime.now());
        final end = RenewalDateUtils.dateOnly(endDate);
        if (!end.isAfter(today)) {
          return 'End date must be after today';
        }
        return null;
      case RecurrenceEndType.occurrenceCount:
        if (occurrenceLimit == null || occurrenceLimit <= 0) {
          return 'Occurrences must be greater than zero';
        }
        return null;
    }
  }

  static bool shouldEndSeries({
    required Renewal renewal,
    required int completedCount,
    required DateTime? nextOccurrenceDate,
  }) {
    if (!isRecurring(renewal)) return true;

    switch (renewal.recurrenceEndType) {
      case RecurrenceEndType.never:
        return nextOccurrenceDate == null;
      case RecurrenceEndType.endDate:
        final end = renewal.recurrenceEndDate;
        if (end == null) return nextOccurrenceDate == null;
        if (nextOccurrenceDate == null) return true;
        return RenewalDateUtils.dateOnly(nextOccurrenceDate)
            .isAfter(RenewalDateUtils.dateOnly(end));
      case RecurrenceEndType.occurrenceCount:
        final limit = renewal.recurrenceOccurrenceLimit;
        if (limit == null || limit <= 0) return nextOccurrenceDate == null;
        return completedCount >= limit;
    }
  }
}
