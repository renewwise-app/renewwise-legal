import 'package:flutter/material.dart';

abstract final class RenewalDateUtils {
  static DateTime dateOnly(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  static int daysRemaining(DateTime renewalDate) {
    final today = dateOnly(DateTime.now());
    final target = dateOnly(renewalDate);
    return target.difference(today).inDays;
  }

  static String daysRemainingLabel(DateTime renewalDate) {
    final days = daysRemaining(renewalDate);

    if (days < 0) {
      final n = days.abs();
      return n == 1 ? 'Overdue by 1 day' : 'Overdue by $n days';
    }
    if (days == 0) return 'Due today';
    if (days == 1) return '1 day remaining';
    return '$days days remaining';
  }

  static String monthName(int month) {
    const months = [
      'January', 'February', 'March', 'April',
      'May', 'June', 'July', 'August',
      'September', 'October', 'November', 'December',
    ];
    return months[month - 1];
  }

  static String formatDisplayDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return '${months[date.month - 1]} ${date.day}, ${date.year}';
  }

  static Future<DateTime?> pickDate(
    BuildContext context, {
    String helpText = 'Select event date',
    DateTime? initialDate,
  }) {
    final now = DateTime.now();
    return showDatePicker(
      context: context,
      initialDate: initialDate ?? now,
      firstDate: now.subtract(const Duration(days: 365 * 5)),
      lastDate: now.add(const Duration(days: 365 * 10)),
      helpText: helpText,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          datePickerTheme: DatePickerThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        child: child!,
      ),
    );
  }

  /// Expiry/renewal date picker — today onward only (Package 4B.6.1).
  static Future<DateTime?> pickExpiryDate(
    BuildContext context, {
    String helpText = 'Select expiry date',
    DateTime? initialDate,
  }) {
    final now = DateTime.now();
    final today = dateOnly(now);
    var initial = initialDate != null ? dateOnly(initialDate) : today;
    if (initial.isBefore(today)) initial = today;

    return showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365 * 50)),
      helpText: helpText,
      selectableDayPredicate: (date) => !dateOnly(date).isBefore(today),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          datePickerTheme: DatePickerThemeData(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
          ),
        ),
        child: child!,
      ),
    );
  }

  /// Alias kept for backward compatibility.
  static Future<DateTime?> pickRenewalDate(BuildContext context) =>
      pickDate(context, helpText: 'Select renewal date');
}
