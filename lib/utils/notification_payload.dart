/// Encodes notification tap / action payloads.
abstract final class NotificationPayload {
  static const actionView = 'view';
  static const actionComplete = 'complete';
  static const actionSnooze5 = 'snooze_5';
  static const actionSnooze10 = 'snooze_10';
  static const actionSnooze30 = 'snooze_30';
  static const actionSnooze15 = 'snooze_15';
  static const actionSnooze60 = 'snooze_60';
  static const actionSnoozeDefault = 'snooze_default';
  static const actionSnoozeTomorrow = 'snooze_tomorrow';
  static const actionReschedule = 'reschedule';
  static const actionDismiss = 'dismiss';

  static String encode({
    required String renewalId,
    required String action,
    int? notificationId,
  }) {
    return '$renewalId|$action|${notificationId ?? 0}';
  }

  static ({String renewalId, String action, int notificationId})? decode(
    String? payload,
  ) {
    if (payload == null || payload.isEmpty) return null;
    final parts = payload.split('|');
    if (parts.length < 2) return null;
    return (
      renewalId: parts[0],
      action: parts[1],
      notificationId: parts.length > 2 ? int.tryParse(parts[2]) ?? 0 : 0,
    );
  }
}
