import 'package:renew_wise/models/notification_level.dart';
import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/services/notification_service.dart';

/// No-op implementation used in widget and unit tests.
class NoOpNotificationService implements NotificationService {
  const NoOpNotificationService();

  @override
  Future<void> initialize() async {}

  @override
  Future<void> scheduleReminders(
    Renewal renewal, {
    int defaultTimeMinutes = 540,
  }) async {}

  @override
  Future<void> cancelReminders(String renewalId) async {}

  @override
  Future<void> sendTestNotification() async {}

  @override
  Future<void> sendTestNotificationAtLevel(NotificationLevel level) async {}

  @override
  Future<void> sendCriticalFullScreenTest() async {}

  @override
  Future<void> cancelAllTestNotifications() async {}

  @override
  Future<void> scheduleSnooze(
    Renewal renewal, {
    required Duration delay,
    int defaultTimeMinutes = 540,
  }) async {}

  @override
  Future<void> showImmediateReminder(
    Renewal renewal, {
    NotificationLevel? levelOverride,
  }) async {}

  @override
  Future<void> cancelAll() async {}

  @override
  Future<bool> areNotificationsEnabled() async => true;

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<bool> canScheduleExactAlarms() async => true;

  @override
  Future<void> requestExactAlarmsPermission() async {}

  @override
  Future<NotificationLaunchDetails?> getLaunchDetails() async => null;

  @override
  Future<void> openAndroidNotificationSettings() async {}

  @override
  Future<int> getPendingNotificationCount() async => 0;

  @override
  void setActionCallback(
    Future<void> Function(String? payload, String? actionId) callback,
  ) {}
}
