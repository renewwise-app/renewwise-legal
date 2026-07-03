import 'package:renew_wise/utils/date_utils.dart';

/// Smart reminder preset and validation helpers (Package 4B.6 / 4B.6.1).
abstract final class ReminderScheduleUtils {
  static const presetOptions = [90, 60, 30, 15, 7, 3, 1];

  static const betweenTodayAndExpiryMessage =
      'Reminder must fall between today and the expiry date.';
  static const beforeExpiryMessage =
      'Reminder must be before the expiry date.';
  static const futureReminderMessage = 'Please choose a future reminder.';

  static DateTime reminderDateForDaysBefore(
    DateTime expiry,
    int daysBefore, {
    DateTime? now,
  }) {
    return RenewalDateUtils.dateOnly(expiry)
        .subtract(Duration(days: daysBefore));
  }

  static int maxValidDaysBefore(DateTime expiry, {DateTime? now}) {
    final today = RenewalDateUtils.dateOnly(now ?? DateTime.now());
    final expiryDay = RenewalDateUtils.dateOnly(expiry);
    return expiryDay.difference(today).inDays;
  }

  /// True when [daysBefore] yields a reminder on or after today and on/before expiry.
  static bool isValidDaysBefore(
    DateTime expiry,
    int daysBefore, {
    DateTime? now,
  }) {
    if (daysBefore <= 0) return false;
    final today = RenewalDateUtils.dateOnly(now ?? DateTime.now());
    final expiryDay = RenewalDateUtils.dateOnly(expiry);
    final reminderDate = expiryDay.subtract(Duration(days: daysBefore));
    return !reminderDate.isBefore(today) && !reminderDate.isAfter(expiryDay);
  }

  static List<int> availablePresetOptions(
    DateTime expiry, {
    DateTime? now,
  }) {
    return presetOptions
        .where((days) => isValidDaysBefore(expiry, days, now: now))
        .toList();
  }

  static bool isValidCustomReminderDate(
    DateTime expiry,
    DateTime date, {
    DateTime? now,
  }) {
    final today = RenewalDateUtils.dateOnly(now ?? DateTime.now());
    final expiryDay = RenewalDateUtils.dateOnly(expiry);
    final day = RenewalDateUtils.dateOnly(date);
    return !day.isBefore(today) && !day.isAfter(expiryDay);
  }

  static DateTime clampReminderDate(
    DateTime date,
    DateTime expiry, {
    DateTime? now,
  }) {
    final today = RenewalDateUtils.dateOnly(now ?? DateTime.now());
    final expiryDay = RenewalDateUtils.dateOnly(expiry);
    var day = RenewalDateUtils.dateOnly(date);
    if (day.isBefore(today)) day = today;
    if (day.isAfter(expiryDay)) day = expiryDay;
    return day;
  }

  static List<DateTime> allReminderDates({
    required DateTime expiry,
    required List<int> reminderDays,
    required List<DateTime> customDates,
  }) {
    final expiryDay = RenewalDateUtils.dateOnly(expiry);
    return [
      ...reminderDays.map(
        (days) => expiryDay.subtract(Duration(days: days)),
      ),
      ...customDates.map(RenewalDateUtils.dateOnly),
    ];
  }

  static bool hasReminderSelection({
    required List<int> reminderDays,
    required List<DateTime> customDates,
  }) {
    return reminderDays.isNotEmpty || customDates.isNotEmpty;
  }

  static bool isReminderDateToday(
    DateTime reminderDate, {
    DateTime? now,
  }) {
    final today = RenewalDateUtils.dateOnly(now ?? DateTime.now());
    return RenewalDateUtils.dateOnly(reminderDate) == today;
  }

  static bool isValidReminderTime(
    DateTime reminderDate,
    int hour,
    int minute, {
    DateTime? now,
  }) {
    if (!isReminderDateToday(reminderDate, now: now)) return true;
    final current = now ?? DateTime.now();
    final today = RenewalDateUtils.dateOnly(current);
    final scheduled = DateTime(today.year, today.month, today.day, hour, minute);
    return scheduled.isAfter(current);
  }

  static bool requiresFutureTimeToday({
    required DateTime expiry,
    required List<int> reminderDays,
    required List<DateTime> customDates,
    DateTime? now,
  }) {
    return allReminderDates(
      expiry: expiry,
      reminderDays: reminderDays,
      customDates: customDates,
    ).any((date) => isReminderDateToday(date, now: now));
  }

  static String? validateSchedule({
    required DateTime expiry,
    required List<int> reminderDays,
    required List<DateTime> customDates,
    required int reminderHour,
    required int reminderMinute,
    DateTime? now,
  }) {
    if (!hasReminderSelection(
      reminderDays: reminderDays,
      customDates: customDates,
    )) {
      return futureReminderMessage;
    }

    final today = RenewalDateUtils.dateOnly(now ?? DateTime.now());
    final expiryDay = RenewalDateUtils.dateOnly(expiry);

    for (final days in reminderDays) {
      if (!isValidDaysBefore(expiry, days, now: now)) {
        return betweenTodayAndExpiryMessage;
      }

      final reminderDate = expiryDay.subtract(Duration(days: days));
      if (reminderDate.isAfter(expiryDay)) {
        return beforeExpiryMessage;
      }
      if (reminderDate.isBefore(today)) {
        return futureReminderMessage;
      }
      if (!isValidReminderTime(
        reminderDate,
        reminderHour,
        reminderMinute,
        now: now,
      )) {
        return futureReminderMessage;
      }
    }

    for (final date in customDates) {
      final day = RenewalDateUtils.dateOnly(date);
      if (day.isAfter(expiryDay)) {
        return beforeExpiryMessage;
      }
      if (day.isBefore(today)) {
        return futureReminderMessage;
      }
      if (!isValidCustomReminderDate(expiry, date, now: now)) {
        return betweenTodayAndExpiryMessage;
      }
      if (!isValidReminderTime(
        day,
        reminderHour,
        reminderMinute,
        now: now,
      )) {
        return futureReminderMessage;
      }
    }

    return null;
  }

  static void pruneInvalidSelections({
    required DateTime expiry,
    required Set<int> reminderDays,
    required List<DateTime> customReminderDates,
    DateTime? now,
  }) {
    reminderDays.removeWhere(
      (days) => !isValidDaysBefore(expiry, days, now: now),
    );
    customReminderDates.removeWhere(
      (date) => !isValidCustomReminderDate(expiry, date, now: now),
    );
  }
}
