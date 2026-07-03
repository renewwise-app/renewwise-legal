import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:renew_wise/models/alert_style.dart';
import 'package:renew_wise/models/notification_level.dart';
import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/models/renewal_category.dart';
import 'package:renew_wise/services/notification_service.dart';
import 'package:renew_wise/services/reminder_state_service.dart';
import 'package:renew_wise/services/settings_service.dart';
import 'package:renew_wise/services/sharing_service.dart';
import 'package:renew_wise/utils/notification_level_resolver.dart';
import 'package:renew_wise/utils/notification_payload.dart';

const _kSupportedDays = [90, 60, 30, 15, 7, 3, 1];
const _kMaxCustomDates = 10;

const _kTestBaseId = 999999980;
const _kSnoozeIdBase = 888888000;

class LocalNotificationService implements NotificationService {
  LocalNotificationService();

  final _plugin = FlutterLocalNotificationsPlugin();
  SettingsService? _settings;
  ReminderStateService? _reminderState;
  SharingService? _sharing;
  Future<void> Function(String? payload, String? actionId)? _actionCallback;

  static const _levelChannels = {
    NotificationLevel.low: (
      id: 'renewwise_standard',
      name: 'RenewWise Standard',
      desc: 'Standard reminders — dismissible',
    ),
    NotificationLevel.medium: (
      id: 'renewwise_medium',
      name: 'RenewWise Medium',
      desc: 'Reminders with sound until dismissed',
    ),
    NotificationLevel.high: (
      id: 'renewwise_important',
      name: 'RenewWise Important',
      desc: 'High-priority reminders until acknowledged',
    ),
    NotificationLevel.critical: (
      id: 'renewwise_critical',
      name: 'RenewWise Critical',
      desc: 'Alarm-style alerts for time-sensitive reminders',
    ),
  };

  static const _alertChannels = {
    AlertStyle.standard: (
      id: 'renewwise_standard',
      name: 'RenewWise Standard',
      desc: 'Standard reminders for everyday events',
    ),
    AlertStyle.important: (
      id: 'renewwise_important',
      name: 'RenewWise Important',
      desc: 'High-priority reminders that stay visible until acknowledged',
    ),
    AlertStyle.critical: (
      id: 'renewwise_critical',
      name: 'RenewWise Critical',
      desc: 'Alarm-style alerts for time-sensitive reminders',
    ),
  };

  void attach({
    required SettingsService settings,
    required ReminderStateService reminderState,
    SharingService? sharingService,
  }) {
    _settings = settings;
    _reminderState = reminderState;
    _sharing = sharingService;
  }

  @override
  void setActionCallback(
    Future<void> Function(String? payload, String? actionId) callback,
  ) {
    _actionCallback = callback;
  }

  @override
  Future<void> initialize() async {
    if (kDebugMode) debugPrint('[Notif] initialize()');
    tz.initializeTimeZones();

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
      ),
      onDidReceiveNotificationResponse: _onNotificationResponse,
    );

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();

    for (final level in NotificationLevel.values) {
      final cfg = _levelChannels[level]!;
      await android?.createNotificationChannel(
        AndroidNotificationChannel(
          cfg.id,
          cfg.name,
          description: cfg.desc,
          importance: _levelImportance(level),
          enableVibration: true,
          playSound: true,
        ),
      );
    }

    for (final style in AlertStyle.values) {
      final cfg = _alertChannels[style]!;
      await android?.createNotificationChannel(
        AndroidNotificationChannel(
          cfg.id,
          cfg.name,
          description: cfg.desc,
          importance: _channelImportance(style),
          enableVibration: true,
          playSound: true,
        ),
      );
    }

    await android?.requestNotificationsPermission();
  }

  @override
  Future<NotificationLaunchDetails?> getLaunchDetails() async {
    final details = await _plugin.getNotificationAppLaunchDetails();
    if (details == null || !details.didNotificationLaunchApp) return null;
    return NotificationLaunchDetails(
      payload: details.notificationResponse?.payload,
      actionId: details.notificationResponse?.actionId,
    );
  }

  Importance _levelImportance(NotificationLevel level) {
    return switch (level) {
      NotificationLevel.low => Importance.defaultImportance,
      NotificationLevel.medium => Importance.high,
      NotificationLevel.high => Importance.high,
      NotificationLevel.critical => Importance.max,
    };
  }

  Importance _channelImportance(AlertStyle style) {
    return switch (style) {
      AlertStyle.standard => Importance.defaultImportance,
      AlertStyle.important => Importance.high,
      AlertStyle.critical => Importance.max,
    };
  }

  Future<void> _onNotificationResponse(NotificationResponse response) async {
    if (kDebugMode) {
      debugPrint(
        '[Notif] action=${response.actionId} payload=${response.payload}',
      );
    }
    if (_actionCallback != null) {
      await _actionCallback!(response.payload, response.actionId);
    }
  }

  bool get _soundOn => _settings?.notificationSoundEnabled ?? true;
  bool get _vibrateOn => _settings?.notificationVibrationEnabled ?? true;
  bool get _alarmStyle => _settings?.alarmStyleAlertsEnabled ?? true;
  bool get _headsUp => _settings?.headsUpNotificationsEnabled ?? true;

  NotificationDetails _detailsFor(Renewal renewal, int notifId) {
    final level = NotificationLevelResolver.resolve(renewal);
    final channel = _levelChannels[level]!;
    final isCritical = level == NotificationLevel.critical;
    final isHigh = level == NotificationLevel.high;
    final isPersistent = NotificationLevelResolver.isPersistent(renewal);

    Int64List? vibrationPattern;
    if (_vibrateOn) {
      vibrationPattern = switch (level) {
        NotificationLevel.low || NotificationLevel.medium => null,
        NotificationLevel.high => Int64List.fromList([0, 400, 200, 400]),
        NotificationLevel.critical =>
          Int64List.fromList([0, 800, 400, 800, 400, 800]),
      };
    }

    final playSound = _soundOn && level != NotificationLevel.low;

    return NotificationDetails(
      android: AndroidNotificationDetails(
        channel.id,
        channel.name,
        channelDescription: channel.desc,
        importance: _headsUp && level != NotificationLevel.low
            ? _levelImportance(level)
            : _levelImportance(level),
        priority: isCritical
            ? Priority.max
            : isHigh
                ? Priority.high
                : Priority.defaultPriority,
        icon: '@mipmap/ic_launcher',
        enableVibration: _vibrateOn &&
            (level == NotificationLevel.high ||
                level == NotificationLevel.critical),
        vibrationPattern: vibrationPattern,
        playSound: playSound,
        ongoing: isPersistent,
        autoCancel: !isPersistent,
        fullScreenIntent: isCritical && _alarmStyle,
        category: isCritical
            ? AndroidNotificationCategory.alarm
            : AndroidNotificationCategory.reminder,
        visibility: NotificationVisibility.public,
        actions: _actionsFor(level),
      ),
    );
  }

  List<AndroidNotificationAction> _actionsFor(NotificationLevel level) {
    if (level == NotificationLevel.low) {
      return [
        AndroidNotificationAction(
          NotificationPayload.actionView,
          'View',
          showsUserInterface: true,
          cancelNotification: true,
        ),
        AndroidNotificationAction(
          NotificationPayload.actionComplete,
          'Mark Done',
          showsUserInterface: true,
        ),
        AndroidNotificationAction(
          NotificationPayload.actionDismiss,
          'Dismiss',
          cancelNotification: true,
          showsUserInterface: false,
        ),
      ];
    }

    final defaultMin = _settings?.defaultSnoozeMinutes ?? 10;

    return [
      AndroidNotificationAction(
        NotificationPayload.actionComplete,
        'Mark Done',
        showsUserInterface: true,
      ),
      AndroidNotificationAction(
        NotificationPayload.actionSnoozeDefault,
        'Snooze ${defaultMin}m',
        showsUserInterface: false,
      ),
      AndroidNotificationAction(
        NotificationPayload.actionSnoozeTomorrow,
        'Tomorrow',
        showsUserInterface: false,
      ),
      AndroidNotificationAction(
        NotificationPayload.actionReschedule,
        'Reschedule',
        showsUserInterface: true,
      ),
    ];
  }

  String _title(Renewal renewal) {
    final sharedSuffix =
        _sharing?.isShared(renewal.id) == true ? ' 👥' : '';
    final level = NotificationLevelResolver.resolve(renewal);
    return switch (level) {
      NotificationLevel.critical => '🚨 ${renewal.title}$sharedSuffix',
      NotificationLevel.high => 'Important: ${renewal.title}$sharedSuffix',
      NotificationLevel.medium => 'Reminder: ${renewal.title}$sharedSuffix',
      NotificationLevel.low => '${renewal.title}$sharedSuffix',
    };
  }

  String _body(Renewal renewal, int days) {
    final action = renewal.isOverdue
        ? 'Action needed — tap to respond.'
        : days <= 0
            ? 'Due today — tap to view or complete.'
            : days == 1
                ? 'Due tomorrow.'
                : 'Due in $days days.';
    final payment = renewal.formattedAmount;
    final paymentSuffix =
        payment != null && payment != 'No payment' ? ' · $payment' : '';
    return '${renewal.categoryLabel} · $action$paymentSuffix';
  }

  @override
  Future<void> scheduleReminders(
    Renewal renewal, {
    int defaultTimeMinutes = 540,
  }) async {
    await cancelReminders(renewal.id);
    final now = tz.TZDateTime.now(tz.UTC);
    final canExact = await canScheduleExactAlarms();
    final mode = canExact
        ? AndroidScheduleMode.alarmClock
        : AndroidScheduleMode.inexact;
    final timeMinutes = renewal.reminderTimeMinutes ?? defaultTimeMinutes;
    final hour = timeMinutes ~/ 60;
    final minute = timeMinutes % 60;

    for (final days in renewal.reminderSchedule) {
      final baseDate =
          renewal.renewalDate.subtract(Duration(days: days));
      final localFire =
          DateTime(baseDate.year, baseDate.month, baseDate.day, hour, minute);
      final fireTZ = tz.TZDateTime.from(localFire, tz.UTC);
      if (fireTZ.isBefore(now)) continue;

      final id = _dayNotifId(renewal.id, days);
      final payload = NotificationPayload.encode(
        renewalId: renewal.id,
        action: NotificationPayload.actionView,
        notificationId: id,
      );
      await _plugin.zonedSchedule(
        id: id,
        title: _title(renewal),
        body: _body(renewal, days),
        scheduledDate: fireTZ,
        notificationDetails: _detailsFor(renewal, id),
        androidScheduleMode: mode,
        payload: payload,
      );
    }

    for (var i = 0; i < renewal.customReminderDates.length; i++) {
      final date = renewal.customReminderDates[i];
      final localFire =
          DateTime(date.year, date.month, date.day, hour, minute);
      final fireTZ = tz.TZDateTime.from(localFire, tz.UTC);
      if (fireTZ.isBefore(now)) continue;

      final daysUntil = renewal.renewalDate.difference(date).inDays;
      final id = _customDateNotifId(renewal.id, i);
      final payload = NotificationPayload.encode(
        renewalId: renewal.id,
        action: NotificationPayload.actionView,
        notificationId: id,
      );
      await _plugin.zonedSchedule(
        id: id,
        title: _title(renewal),
        body: _body(renewal, daysUntil),
        scheduledDate: fireTZ,
        notificationDetails: _detailsFor(renewal, id),
        androidScheduleMode: mode,
        payload: payload,
      );
    }
  }

  @override
  Future<void> scheduleSnooze(
    Renewal renewal, {
    required Duration delay,
    int defaultTimeMinutes = 540,
  }) async {
    await cancelReminders(renewal.id);
    final fireTime = tz.TZDateTime.now(tz.UTC).add(delay);
    final id = _snoozeNotifId(renewal.id);
    final payload = NotificationPayload.encode(
      renewalId: renewal.id,
      action: NotificationPayload.actionView,
      notificationId: id,
    );
    await _plugin.zonedSchedule(
      id: id,
      title: _title(renewal),
      body: 'Snoozed reminder — ${_body(renewal, renewal.daysRemaining)}',
      scheduledDate: fireTime,
      notificationDetails: _detailsFor(renewal, id),
      androidScheduleMode: AndroidScheduleMode.alarmClock,
      payload: payload,
    );
    await _reminderState?.markSnoozed(renewal.id, fireTime);
  }

  @override
  Future<void> showImmediateReminder(
    Renewal renewal, {
    NotificationLevel? levelOverride,
  }) async {
    final id = _snoozeNotifId(renewal.id);
    final payload = NotificationPayload.encode(
      renewalId: renewal.id,
      action: NotificationPayload.actionView,
      notificationId: id,
    );
    await _plugin.show(
      id: id,
      title: _title(renewal),
      body: _body(renewal, renewal.daysRemaining),
      notificationDetails: _detailsFor(renewal, id),
      payload: payload,
    );
    await _reminderState?.recordReminderSent(renewal.id, DateTime.now());
  }

  @override
  Future<void> cancelReminders(String renewalId) async {
    for (final days in _kSupportedDays) {
      await _plugin.cancel(id: _dayNotifId(renewalId, days));
    }
    for (var i = 0; i < _kMaxCustomDates; i++) {
      await _plugin.cancel(id: _customDateNotifId(renewalId, i));
    }
    await _plugin.cancel(id: _snoozeNotifId(renewalId));
  }

  @override
  Future<void> cancelAll() async {
    await _plugin.cancelAll();
  }

  AlertStyle _styleForLevel(NotificationLevel level) {
    return switch (level) {
      NotificationLevel.low => AlertStyle.standard,
      NotificationLevel.medium => AlertStyle.standard,
      NotificationLevel.high => AlertStyle.important,
      NotificationLevel.critical => AlertStyle.critical,
    };
  }

  @override
  Future<void> sendTestNotification() async {
    await sendTestNotificationAtLevel(NotificationLevel.medium);
  }

  @override
  Future<void> sendTestNotificationAtLevel(NotificationLevel level) async {
    final style = _styleForLevel(level);
    final testRenewal = Renewal(
      id: 'test_${level.name}',
      title: 'RenewWise Test (${level.label})',
      category: RenewalCategory.insurance,
      renewalDate: DateTime.now().add(const Duration(days: 1)),
      alertStyle: style,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final id = _kTestBaseId + level.index;
    final payload = NotificationPayload.encode(
      renewalId: testRenewal.id,
      action: NotificationPayload.actionView,
      notificationId: id,
    );
    await _plugin.show(
      id: id,
      title: _title(testRenewal),
      body: 'Test ${style.label} alert — actions are enabled.',
      notificationDetails: _detailsFor(testRenewal, id),
      payload: payload,
    );
  }

  @override
  Future<void> sendCriticalFullScreenTest() async {
    await sendTestNotificationAtLevel(NotificationLevel.critical);
  }

  @override
  Future<void> cancelAllTestNotifications() async {
    for (var i = 0; i < 4; i++) {
      await _plugin.cancel(id: _kTestBaseId + i);
    }
  }

  @override
  Future<bool> areNotificationsEnabled() async {
    final v = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.areNotificationsEnabled();
    return v ?? true;
  }

  @override
  Future<bool> requestPermission() async {
    final v = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    return v ?? false;
  }

  @override
  Future<bool> canScheduleExactAlarms() async {
    final v = await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.canScheduleExactNotifications();
    return v ?? true;
  }

  @override
  Future<void> requestExactAlarmsPermission() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestExactAlarmsPermission();
  }

  @override
  Future<void> openAndroidNotificationSettings() async {
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
    // Deep-link handled via app_settings from the settings screen.
  }

  @override
  Future<int> getPendingNotificationCount() async {
    return (await _plugin.pendingNotificationRequests()).length;
  }

  int _dayNotifId(String renewalId, int days) {
    final h = renewalId.hashCode.abs() % 10000000;
    return h * 100 + (days % 100);
  }

  int _customDateNotifId(String renewalId, int index) {
    final h = renewalId.hashCode.abs() % 100000;
    return 1000000000 + h * 10 + (index % 10);
  }

  int _snoozeNotifId(String renewalId) {
    return _kSnoozeIdBase + (renewalId.hashCode.abs() % 100000);
  }
}
