import 'package:renew_wise/models/notification_level.dart';
import 'package:renew_wise/models/renewal.dart';

class NotificationLaunchDetails {
  const NotificationLaunchDetails({this.payload, this.actionId});

  final String? payload;
  final String? actionId;
}

/// Abstract interface for local notification scheduling.
abstract class NotificationService {
  Future<void> initialize();

  Future<NotificationLaunchDetails?> getLaunchDetails();

  Future<void> scheduleReminders(
    Renewal renewal, {
    int defaultTimeMinutes = 540,
  });

  Future<void> cancelReminders(String renewalId);

  Future<void> sendTestNotification();

  Future<void> sendTestNotificationAtLevel(NotificationLevel level);

  Future<void> sendCriticalFullScreenTest();

  Future<void> cancelAllTestNotifications();

  Future<void> scheduleSnooze(
    Renewal renewal, {
    required Duration delay,
    int defaultTimeMinutes = 540,
  });

  Future<void> showImmediateReminder(
    Renewal renewal, {
    NotificationLevel? levelOverride,
  });

  Future<void> cancelAll();

  Future<bool> areNotificationsEnabled();

  Future<bool> requestPermission();

  Future<bool> canScheduleExactAlarms();

  Future<void> requestExactAlarmsPermission();

  Future<void> openAndroidNotificationSettings();

  Future<int> getPendingNotificationCount();

  /// Register handler invoked when a notification action is tapped.
  void setActionCallback(
    Future<void> Function(String? payload, String? actionId) callback,
  );
}
