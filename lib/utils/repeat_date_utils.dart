import 'package:renew_wise/models/repeat_cycle.dart';
import 'package:renew_wise/utils/date_utils.dart';

abstract final class RepeatDateUtils {
  static DateTime? nextOccurrence(DateTime from, RepeatCycle cycle) {
    final anchor = RenewalDateUtils.dateOnly(from);

    switch (cycle) {
      case RepeatCycle.oneTime:
      case RepeatCycle.custom:
        return null;
      case RepeatCycle.hourly:
        return from.add(const Duration(hours: 1));
      case RepeatCycle.daily:
        return anchor.add(const Duration(days: 1));
      case RepeatCycle.weekdays:
        return _nextWeekday(anchor);
      case RepeatCycle.weekly:
        return anchor.add(const Duration(days: 7));
      case RepeatCycle.monthly:
        return _addMonths(anchor, 1);
      case RepeatCycle.quarterly:
        return _addMonths(anchor, 3);
      case RepeatCycle.halfYearly:
        return _addMonths(anchor, 6);
      case RepeatCycle.yearly:
        return _addYears(anchor, 1);
    }
  }

  static DateTime _nextWeekday(DateTime from) {
    var next = from.add(const Duration(days: 1));
    while (next.weekday == DateTime.saturday ||
        next.weekday == DateTime.sunday) {
      next = next.add(const Duration(days: 1));
    }
    return next;
  }

  static DateTime _addMonths(DateTime from, int months) {
    final totalMonths = from.month + months;
    final year = from.year + (totalMonths - 1) ~/ 12;
    final month = ((totalMonths - 1) % 12) + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final day = from.day > lastDay ? lastDay : from.day;
    return DateTime(year, month, day);
  }

  static DateTime _addYears(DateTime from, int years) {
    final year = from.year + years;
    final lastDay = DateTime(year, from.month + 1, 0).day;
    final day = from.day > lastDay ? lastDay : from.day;
    return DateTime(year, from.month, day);
  }
}
