import 'package:renew_wise/models/alert_style.dart';
import 'package:renew_wise/models/notification_level.dart';
import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/models/renewal_priority.dart';

/// Maps reminder importance (priority + alert style) to notification tiers.
abstract final class NotificationLevelResolver {
  static NotificationLevel resolve(Renewal renewal) {
    if (renewal.alertStyle == AlertStyle.critical ||
        renewal.priority == RenewalPriority.critical) {
      return NotificationLevel.critical;
    }
    if (renewal.alertStyle == AlertStyle.important ||
        renewal.priority == RenewalPriority.high) {
      return NotificationLevel.high;
    }
    if (renewal.priority == RenewalPriority.medium) {
      return NotificationLevel.medium;
    }
    return NotificationLevel.low;
  }

  static bool isCritical(Renewal renewal) =>
      resolve(renewal) == NotificationLevel.critical;

  static bool supportsSnooze(Renewal renewal) =>
      resolve(renewal) != NotificationLevel.low;

  static bool isPersistent(Renewal renewal) =>
      resolve(renewal) != NotificationLevel.low;
}

/// Lifecycle snooze presets (DR-4).
abstract final class ReminderSnoozeOptions {
  static const presets = <Duration>[
    Duration(minutes: 5),
    Duration(minutes: 10),
    Duration(minutes: 15),
    Duration(minutes: 30),
    Duration(hours: 1),
  ];

  static String label(Duration duration) {
    if (duration.inHours >= 1) {
      return duration.inHours == 1 ? '1 Hour' : '${duration.inHours} Hours';
    }
    return '${duration.inMinutes} Minutes';
  }

  static Duration untilTomorrow({DateTime? now}) {
    final current = now ?? DateTime.now();
    final tomorrow = DateTime(
      current.year,
      current.month,
      current.day + 1,
      9,
    );
    return tomorrow.difference(current);
  }
}
