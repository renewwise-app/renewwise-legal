import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:renew_wise/models/alert_style.dart';
import 'package:renew_wise/models/backup_models.dart';
import 'package:renew_wise/models/renewal_currency.dart';
import 'package:renew_wise/models/smart_lock_models.dart';
import 'package:renew_wise/utils/dashboard_sort.dart';
import 'package:renew_wise/utils/dashboard_time_filter.dart';

class SettingsService extends ChangeNotifier {
  static const _kCurrencyKey = 'default_currency';
  static const _kNotificationsKey = 'notifications_enabled';
  static const _kDefaultLeadDaysKey = 'default_reminder_lead_days';
  static const _kDefaultReminderHourKey = 'default_reminder_hour';
  static const _kDefaultReminderMinuteKey = 'default_reminder_minute';
  static const _kHasSeenOnboardingKey = 'has_seen_onboarding';
  static const _kUserNameKey = 'user_name';
  static const _kNotifSoundKey = 'notif_sound_enabled';
  static const _kNotifVibrationKey = 'notif_vibration_enabled';
  static const _kAlarmStyleKey = 'alarm_style_alerts';
  static const _kHeadsUpKey = 'heads_up_notifications';
  static const _kDefaultSnoozeKey = 'default_snooze_minutes';
  static const _kDefaultAlertStyleKey = 'default_alert_style_v1';
  static const _kUseSystemSoundKey = 'use_system_sound_v1';
  static const _kDashboardFilterKey = 'dashboard_time_filter_v1';
  static const _kDashboardSortKey = 'dashboard_sort_v1';
  static const _kDashboardFilterYearKey = 'dashboard_filter_year_v1';
  static const _kDashboardFilterMonthKey = 'dashboard_filter_month_v1';
  static const _kInsightRotationKey = 'insight_rotation_index_v1';
  static const _kMotivationSessionKey = 'motivation_session_index_v1';
  static const _kWelcomeLoginKey = 'welcome_login_completed_v1';
  static const _kAccountEmailKey = 'account_email_v1';
  static const _kAccountProviderKey = 'account_provider_v1';
  static const _kTutorialOfferKey = 'tutorial_offer_seen_v1';
  static const _kSmartLockScopeKey = 'smart_lock_scope_v1';
  static const _kSmartLockAuthKey = 'smart_lock_auth_v1';
  static const _kSmartLockAutoLockKey = 'smart_lock_auto_lock_v1';
  static const _kSmartLockEnabledKey = 'smart_lock_enabled_v1';

  RenewalCurrency _defaultCurrency = RenewalCurrency.inr;
  bool _notificationsEnabled = true;
  int _defaultReminderLeadDays = 30;
  int _defaultReminderHour = 9;
  int _defaultReminderMinute = 0;
  bool _hasSeenOnboarding = false;
  String _userName = '';
  bool _notificationSoundEnabled = true;
  bool _notificationVibrationEnabled = true;
  bool _alarmStyleAlertsEnabled = true;
  bool _headsUpNotificationsEnabled = true;
  int _defaultSnoozeMinutes = 10;
  AlertStyle _defaultAlertStyle = AlertStyle.standard;
  bool _useSystemSound = true;
  DashboardTimeFilter _dashboardTimeFilter = DashboardTimeFilter.all;
  DashboardSortOption _dashboardSort = DashboardSortOption.nearestFirst;
  int _dashboardFilterYear = DateTime.now().year;
  int _dashboardFilterMonth = DateTime.now().month;
  int _insightRotationIndex = 0;
  int _motivationSessionIndex = 0;
  bool _hasCompletedWelcomeLogin = false;
  String _accountEmail = '';
  String _accountProvider = '';
  bool _hasSeenTutorialOffer = false;
  SmartLockScope _smartLockScope = SmartLockScope.both;
  SmartLockAuthMethod _smartLockAuthMethod = SmartLockAuthMethod.deviceScreenLock;
  SmartLockAutoLock _smartLockAutoLock = SmartLockAutoLock.after5Minutes;
  bool _smartLockEnabled = false;

  RenewalCurrency get defaultCurrency => _defaultCurrency;
  bool get notificationsEnabled => _notificationsEnabled;
  int get defaultReminderLeadDays => _defaultReminderLeadDays;
  int get defaultReminderHour => _defaultReminderHour;
  int get defaultReminderMinute => _defaultReminderMinute;
  bool get hasSeenOnboarding => _hasSeenOnboarding;
  String get userName => _userName;
  bool get notificationSoundEnabled => _notificationSoundEnabled;
  bool get notificationVibrationEnabled => _notificationVibrationEnabled;
  bool get alarmStyleAlertsEnabled => _alarmStyleAlertsEnabled;
  bool get headsUpNotificationsEnabled => _headsUpNotificationsEnabled;
  int get defaultSnoozeMinutes => _defaultSnoozeMinutes;
  AlertStyle get defaultAlertStyle => _defaultAlertStyle;
  bool get useSystemSound => _useSystemSound;
  static const alertSnoozeOptions = [5, 10, 15, 30, 60];
  static const reminderLeadDayOptions = [1, 3, 7, 15, 30, 60, 90];
  DashboardTimeFilter get dashboardTimeFilter => _dashboardTimeFilter;
  DashboardSortOption get dashboardSort => _dashboardSort;
  int get dashboardFilterYear => _dashboardFilterYear;
  int get dashboardFilterMonth => _dashboardFilterMonth;
  int get insightRotationIndex => _insightRotationIndex;
  int get motivationSessionIndex => _motivationSessionIndex;
  bool get hasCompletedWelcomeLogin => _hasCompletedWelcomeLogin;
  String get accountEmail => _accountEmail;
  String get accountProvider => _accountProvider;
  bool get hasSeenTutorialOffer => _hasSeenTutorialOffer;
  SmartLockScope get smartLockScope => _smartLockScope;
  SmartLockAuthMethod get smartLockAuthMethod => _smartLockAuthMethod;
  SmartLockAutoLock get smartLockAutoLock => _smartLockAutoLock;
  bool get smartLockEnabled => _smartLockEnabled;

  /// Minutes since midnight for the default reminder time (e.g., 9:00 AM = 540).
  int get defaultReminderTimeMinutes =>
      _defaultReminderHour * 60 + _defaultReminderMinute;

  /// Load persisted settings. Call once at app startup.
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();

    final code = prefs.getString(_kCurrencyKey);
    if (code != null) {
      _defaultCurrency = RenewalCurrency.values.firstWhere(
        (c) => c.name == code,
        orElse: () => RenewalCurrency.inr,
      );
    }

    _notificationsEnabled = prefs.getBool(_kNotificationsKey) ?? true;
    final rawLeadDays = prefs.getInt(_kDefaultLeadDaysKey) ?? 30;
    _defaultReminderLeadDays = _normalizeReminderLeadDays(rawLeadDays);
    if (rawLeadDays != _defaultReminderLeadDays) {
      await prefs.setInt(_kDefaultLeadDaysKey, _defaultReminderLeadDays);
    }
    _defaultReminderHour = prefs.getInt(_kDefaultReminderHourKey) ?? 9;
    _defaultReminderMinute = prefs.getInt(_kDefaultReminderMinuteKey) ?? 0;
    _hasSeenOnboarding = prefs.getBool(_kHasSeenOnboardingKey) ?? false;
    _userName = prefs.getString(_kUserNameKey) ?? '';
    _notificationSoundEnabled = prefs.getBool(_kNotifSoundKey) ?? true;
    _notificationVibrationEnabled = prefs.getBool(_kNotifVibrationKey) ?? true;
    _alarmStyleAlertsEnabled = prefs.getBool(_kAlarmStyleKey) ?? true;
    _headsUpNotificationsEnabled = prefs.getBool(_kHeadsUpKey) ?? true;
    final rawSnooze = prefs.getInt(_kDefaultSnoozeKey) ?? 10;
    _defaultSnoozeMinutes = _normalizeSnooze(rawSnooze);
    if (rawSnooze != _defaultSnoozeMinutes) {
      await prefs.setInt(_kDefaultSnoozeKey, _defaultSnoozeMinutes);
    }
    final alertStyleName = prefs.getString(_kDefaultAlertStyleKey);
    if (alertStyleName != null) {
      _defaultAlertStyle = AlertStyle.values.firstWhere(
        (s) => s.name == alertStyleName,
        orElse: () => AlertStyle.standard,
      );
    }
    _useSystemSound = prefs.getBool(_kUseSystemSoundKey) ?? true;

    final filterName = prefs.getString(_kDashboardFilterKey);
    if (filterName != null) {
      _dashboardTimeFilter = DashboardTimeFilter.values.firstWhere(
        (f) => f.name == filterName,
        orElse: () => DashboardTimeFilter.all,
      );
    }
    final sortName = prefs.getString(_kDashboardSortKey);
    if (sortName != null) {
      _dashboardSort = DashboardSortOption.values.firstWhere(
        (s) => s.name == sortName,
        orElse: () => DashboardSortOption.nearestFirst,
      );
    }
    _dashboardFilterYear =
        prefs.getInt(_kDashboardFilterYearKey) ?? DateTime.now().year;
    _dashboardFilterMonth =
        prefs.getInt(_kDashboardFilterMonthKey) ?? DateTime.now().month;
    _insightRotationIndex = prefs.getInt(_kInsightRotationKey) ?? 0;
    _motivationSessionIndex = prefs.getInt(_kMotivationSessionKey) ?? 0;
    _hasCompletedWelcomeLogin = prefs.getBool(_kWelcomeLoginKey) ??
        (_hasSeenOnboarding && _userName.trim().isNotEmpty);
    _accountEmail = prefs.getString(_kAccountEmailKey) ?? '';
    _accountProvider = prefs.getString(_kAccountProviderKey) ?? '';
    _hasSeenTutorialOffer = prefs.getBool(_kTutorialOfferKey) ??
        (_hasSeenOnboarding &&
            _userName.trim().isNotEmpty &&
            _hasCompletedWelcomeLogin);
    final scopeName = prefs.getString(_kSmartLockScopeKey);
    if (scopeName != null) {
      _smartLockScope = SmartLockScope.values.firstWhere(
        (s) => s.name == scopeName,
        orElse: () => SmartLockScope.appOnly,
      );
    }
    final authName = prefs.getString(_kSmartLockAuthKey);
    if (authName != null) {
      _smartLockAuthMethod = SmartLockAuthMethod.values.firstWhere(
        (a) => a.name == authName,
        orElse: () => SmartLockAuthMethod.deviceScreenLock,
      );
    }
    final autoLockName = prefs.getString(_kSmartLockAutoLockKey);
    if (autoLockName != null) {
      _smartLockAutoLock = SmartLockAutoLock.values.firstWhere(
        (a) => a.name == autoLockName,
        orElse: () => SmartLockAutoLock.after5Minutes,
      );
    }
    final hasSavedSmartLock = prefs.containsKey(_kSmartLockScopeKey);
    _smartLockEnabled =
        prefs.getBool(_kSmartLockEnabledKey) ?? hasSavedSmartLock;
  }

  Future<void> setDefaultCurrency(RenewalCurrency currency) async {
    if (_defaultCurrency == currency) return;
    _defaultCurrency = currency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCurrencyKey, currency.name);
    notifyListeners();
  }

  Future<void> setNotificationsEnabled(bool enabled) async {
    if (_notificationsEnabled == enabled) return;
    _notificationsEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotificationsKey, enabled);
    notifyListeners();
  }

  Future<void> setDefaultReminderLeadDays(int days) async {
    final normalized = _normalizeReminderLeadDays(days);
    if (_defaultReminderLeadDays == normalized) return;
    _defaultReminderLeadDays = normalized;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kDefaultLeadDaysKey, normalized);
    notifyListeners();
  }

  Future<void> setDefaultReminderTime(int hour, int minute) async {
    if (_defaultReminderHour == hour && _defaultReminderMinute == minute) return;
    _defaultReminderHour = hour;
    _defaultReminderMinute = minute;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kDefaultReminderHourKey, hour);
    await prefs.setInt(_kDefaultReminderMinuteKey, minute);
    notifyListeners();
  }

  Future<void> setHasSeenOnboarding(bool value) async {
    if (_hasSeenOnboarding == value) return;
    _hasSeenOnboarding = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHasSeenOnboardingKey, value);
    notifyListeners();
  }

  Future<void> setUserName(String name) async {
    final trimmed = name.trim();
    if (_userName == trimmed) return;
    _userName = trimmed;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kUserNameKey, trimmed);
    notifyListeners();
  }

  Future<void> completeWelcomeLogin({
    required String email,
    required String provider,
  }) async {
    _hasCompletedWelcomeLogin = true;
    _accountEmail = email.trim();
    _accountProvider = provider;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kWelcomeLoginKey, true);
    await prefs.setString(_kAccountEmailKey, _accountEmail);
    await prefs.setString(_kAccountProviderKey, _accountProvider);
    notifyListeners();
  }

  Future<void> setHasSeenTutorialOffer(bool value) async {
    if (_hasSeenTutorialOffer == value) return;
    _hasSeenTutorialOffer = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kTutorialOfferKey, value);
    notifyListeners();
  }

  Future<void> resetFirstLaunchExperience() async {
    _hasSeenOnboarding = false;
    _hasCompletedWelcomeLogin = false;
    _hasSeenTutorialOffer = false;
    _accountEmail = '';
    _accountProvider = '';
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHasSeenOnboardingKey, false);
    await prefs.setBool(_kWelcomeLoginKey, false);
    await prefs.setBool(_kTutorialOfferKey, false);
    await prefs.remove(_kAccountEmailKey);
    await prefs.remove(_kAccountProviderKey);
    notifyListeners();
  }

  Future<void> setNotificationSoundEnabled(bool value) async {
    if (_notificationSoundEnabled == value) return;
    _notificationSoundEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifSoundKey, value);
    notifyListeners();
  }

  Future<void> setNotificationVibrationEnabled(bool value) async {
    if (_notificationVibrationEnabled == value) return;
    _notificationVibrationEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNotifVibrationKey, value);
    notifyListeners();
  }

  Future<void> setAlarmStyleAlertsEnabled(bool value) async {
    if (_alarmStyleAlertsEnabled == value) return;
    _alarmStyleAlertsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kAlarmStyleKey, value);
    notifyListeners();
  }

  Future<void> setHeadsUpNotificationsEnabled(bool value) async {
    if (_headsUpNotificationsEnabled == value) return;
    _headsUpNotificationsEnabled = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kHeadsUpKey, value);
    notifyListeners();
  }

  Future<void> setDefaultSnoozeMinutes(int minutes) async {
    final normalized = _normalizeSnooze(minutes);
    if (_defaultSnoozeMinutes == normalized) return;
    _defaultSnoozeMinutes = normalized;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kDefaultSnoozeKey, normalized);
    notifyListeners();
  }

  Future<void> setDefaultAlertStyle(AlertStyle style) async {
    if (_defaultAlertStyle == style) return;
    _defaultAlertStyle = style;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDefaultAlertStyleKey, style.name);
    notifyListeners();
  }

  Future<void> setUseSystemSound(bool value) async {
    if (_useSystemSound == value) return;
    _useSystemSound = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kUseSystemSoundKey, value);
    notifyListeners();
  }

  static int _normalizeSnooze(int minutes) {
    if (alertSnoozeOptions.contains(minutes)) return minutes;
    return alertSnoozeOptions[1];
  }

  static int _normalizeReminderLeadDays(int days) {
    if (reminderLeadDayOptions.contains(days)) return days;
    var nearest = reminderLeadDayOptions[4];
    var minDiff = (days - nearest).abs();
    for (final option in reminderLeadDayOptions) {
      final diff = (days - option).abs();
      if (diff < minDiff) {
        minDiff = diff;
        nearest = option;
      }
    }
    return nearest;
  }

  Future<void> setDashboardListPreferences({
    DashboardTimeFilter? filter,
    DashboardSortOption? sort,
    int? year,
    int? month,
  }) async {
    var changed = false;
    if (filter != null && _dashboardTimeFilter != filter) {
      _dashboardTimeFilter = filter;
      changed = true;
    }
    if (sort != null && _dashboardSort != sort) {
      _dashboardSort = sort;
      changed = true;
    }
    if (year != null && _dashboardFilterYear != year) {
      _dashboardFilterYear = year;
      changed = true;
    }
    if (month != null && _dashboardFilterMonth != month) {
      _dashboardFilterMonth = month;
      changed = true;
    }
    if (!changed) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kDashboardFilterKey, _dashboardTimeFilter.name);
    await prefs.setString(_kDashboardSortKey, _dashboardSort.name);
    await prefs.setInt(_kDashboardFilterYearKey, _dashboardFilterYear);
    await prefs.setInt(_kDashboardFilterMonthKey, _dashboardFilterMonth);
    notifyListeners();
  }

  Future<void> advanceInsightRotation() async {
    _insightRotationIndex++;
    _motivationSessionIndex++;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kInsightRotationKey, _insightRotationIndex);
    await prefs.setInt(_kMotivationSessionKey, _motivationSessionIndex);
    notifyListeners();
  }

  Future<void> setSmartLockScope(SmartLockScope scope) async {
    if (_smartLockScope == scope) return;
    _smartLockScope = scope;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSmartLockScopeKey, scope.name);
    notifyListeners();
  }

  Future<void> setSmartLockAuthMethod(SmartLockAuthMethod method) async {
    if (_smartLockAuthMethod == method) return;
    _smartLockAuthMethod = method;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSmartLockAuthKey, method.name);
    notifyListeners();
  }

  Future<void> setSmartLockAutoLock(SmartLockAutoLock autoLock) async {
    if (_smartLockAutoLock == autoLock) return;
    _smartLockAutoLock = autoLock;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kSmartLockAutoLockKey, autoLock.name);
    notifyListeners();
  }

  Future<void> setSmartLockEnabled(bool enabled) async {
    if (_smartLockEnabled == enabled) return;
    _smartLockEnabled = enabled;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSmartLockEnabledKey, enabled);
    notifyListeners();
  }

  Future<void> applySmartLockConfiguration({
    required SmartLockScope scope,
    required SmartLockAuthMethod authMethod,
    required SmartLockAutoLock autoLock,
  }) async {
    _smartLockEnabled = true;
    _smartLockScope = scope;
    _smartLockAuthMethod = authMethod;
    _smartLockAutoLock = autoLock;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kSmartLockEnabledKey, true);
    await prefs.setString(_kSmartLockScopeKey, scope.name);
    await prefs.setString(_kSmartLockAuthKey, authMethod.name);
    await prefs.setString(_kSmartLockAutoLockKey, autoLock.name);
    notifyListeners();
  }

  // ─── Backup preferences (Pack 08G) ─────────────────────────────────────────

  static const _kBackupFrequencyKey = 'backup_frequency_v1';
  static const _kBackupLastAtKey = 'backup_last_at_v1';
  static const _kBackupConnectedEmailKey = 'backup_connected_email_v1';
  static const _kBackupStatusKey = 'backup_status_v1';
  static const _kBackupStorageBytesKey = 'backup_storage_bytes_v1';
  static const _kBackupContentHashKey = 'backup_content_hash_v1';

  BackupFrequency _backupFrequency = BackupFrequency.weekly;
  DateTime? _backupLastAt;
  String _backupConnectedEmail = '';
  BackupStatus _backupStatus = BackupStatus.notConnected;
  int _backupStorageBytes = 0;
  String _backupContentHash = '';

  BackupFrequency get backupFrequency => _backupFrequency;
  DateTime? get backupLastAt => _backupLastAt;
  String get backupConnectedEmail => _backupConnectedEmail;
  BackupStatus get backupStatus => _backupStatus;
  int get backupStorageBytes => _backupStorageBytes;
  String get backupContentHash => _backupContentHash;

  Future<void> loadBackupPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    final freq = prefs.getString(_kBackupFrequencyKey);
    if (freq != null) {
      _backupFrequency = BackupFrequency.values.firstWhere(
        (f) => f.name == freq,
        orElse: () => BackupFrequency.weekly,
      );
    }
    final lastMs = prefs.getInt(_kBackupLastAtKey);
    _backupLastAt =
        lastMs != null ? DateTime.fromMillisecondsSinceEpoch(lastMs) : null;
    _backupConnectedEmail = prefs.getString(_kBackupConnectedEmailKey) ?? '';
    final statusName = prefs.getString(_kBackupStatusKey);
    if (statusName != null) {
      _backupStatus = BackupStatus.values.firstWhere(
        (s) => s.name == statusName,
        orElse: () => BackupStatus.notConnected,
      );
    }
    _backupStorageBytes = prefs.getInt(_kBackupStorageBytesKey) ?? 0;
    _backupContentHash = prefs.getString(_kBackupContentHashKey) ?? '';
  }

  Future<void> setBackupFrequency(BackupFrequency frequency) async {
    if (_backupFrequency == frequency) return;
    _backupFrequency = frequency;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBackupFrequencyKey, frequency.name);
    notifyListeners();
  }

  Future<void> setBackupLastAt(DateTime? when) async {
    _backupLastAt = when;
    final prefs = await SharedPreferences.getInstance();
    if (when == null) {
      await prefs.remove(_kBackupLastAtKey);
    } else {
      await prefs.setInt(_kBackupLastAtKey, when.millisecondsSinceEpoch);
    }
    notifyListeners();
  }

  Future<void> setBackupConnectedEmail(String email) async {
    _backupConnectedEmail = email;
    final prefs = await SharedPreferences.getInstance();
    if (email.isEmpty) {
      await prefs.remove(_kBackupConnectedEmailKey);
    } else {
      await prefs.setString(_kBackupConnectedEmailKey, email);
    }
    notifyListeners();
  }

  Future<void> setBackupStatus(BackupStatus status) async {
    if (_backupStatus == status) return;
    _backupStatus = status;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kBackupStatusKey, status.name);
    notifyListeners();
  }

  Future<void> setBackupStorageBytes(int bytes) async {
    _backupStorageBytes = bytes;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kBackupStorageBytesKey, bytes);
    notifyListeners();
  }

  Future<void> setBackupContentHash(String hash) async {
    _backupContentHash = hash;
    final prefs = await SharedPreferences.getInstance();
    if (hash.isEmpty) {
      await prefs.remove(_kBackupContentHashKey);
    } else {
      await prefs.setString(_kBackupContentHashKey, hash);
    }
    notifyListeners();
  }

  /// User settings included in backup (excludes backup metadata & dev flags).
  Map<String, dynamic> exportBackupSettings() => {
        'defaultCurrency': _defaultCurrency.name,
        'notificationsEnabled': _notificationsEnabled,
        'defaultReminderLeadDays': _defaultReminderLeadDays,
        'defaultReminderHour': _defaultReminderHour,
        'defaultReminderMinute': _defaultReminderMinute,
        'hasSeenOnboarding': _hasSeenOnboarding,
        'userName': _userName,
        'notificationSoundEnabled': _notificationSoundEnabled,
        'notificationVibrationEnabled': _notificationVibrationEnabled,
        'alarmStyleAlertsEnabled': _alarmStyleAlertsEnabled,
        'headsUpNotificationsEnabled': _headsUpNotificationsEnabled,
        'defaultSnoozeMinutes': _defaultSnoozeMinutes,
        'dashboardTimeFilter': _dashboardTimeFilter.name,
        'dashboardSort': _dashboardSort.name,
        'dashboardFilterYear': _dashboardFilterYear,
        'dashboardFilterMonth': _dashboardFilterMonth,
        'insightRotationIndex': _insightRotationIndex,
        'motivationSessionIndex': _motivationSessionIndex,
        'smartLockScope': _smartLockScope.name,
        'smartLockAuthMethod': _smartLockAuthMethod.name,
        'smartLockAutoLock': _smartLockAutoLock.name,
        'smartLockEnabled': _smartLockEnabled,
      };

  Future<void> importBackupSettings(Map<String, dynamic> json) async {
    _defaultCurrency = RenewalCurrency.values.firstWhere(
      (c) => c.name == json['defaultCurrency'],
      orElse: () => _defaultCurrency,
    );
    _notificationsEnabled = json['notificationsEnabled'] as bool? ?? _notificationsEnabled;
    _defaultReminderLeadDays = _normalizeReminderLeadDays(
      json['defaultReminderLeadDays'] as int? ?? _defaultReminderLeadDays,
    );
    _defaultReminderHour =
        json['defaultReminderHour'] as int? ?? _defaultReminderHour;
    _defaultReminderMinute =
        json['defaultReminderMinute'] as int? ?? _defaultReminderMinute;
    _hasSeenOnboarding =
        json['hasSeenOnboarding'] as bool? ?? _hasSeenOnboarding;
    _userName = json['userName'] as String? ?? _userName;
    _notificationSoundEnabled =
        json['notificationSoundEnabled'] as bool? ?? _notificationSoundEnabled;
    _notificationVibrationEnabled = json['notificationVibrationEnabled'] as bool? ??
        _notificationVibrationEnabled;
    _alarmStyleAlertsEnabled =
        json['alarmStyleAlertsEnabled'] as bool? ?? _alarmStyleAlertsEnabled;
    _headsUpNotificationsEnabled = json['headsUpNotificationsEnabled'] as bool? ??
        _headsUpNotificationsEnabled;
    _defaultSnoozeMinutes = _normalizeSnooze(
      json['defaultSnoozeMinutes'] as int? ?? _defaultSnoozeMinutes,
    );
    final filterName = json['dashboardTimeFilter'] as String?;
    if (filterName != null) {
      _dashboardTimeFilter = DashboardTimeFilter.values.firstWhere(
        (f) => f.name == filterName,
        orElse: () => _dashboardTimeFilter,
      );
    }
    final sortName = json['dashboardSort'] as String?;
    if (sortName != null) {
      _dashboardSort = DashboardSortOption.values.firstWhere(
        (s) => s.name == sortName,
        orElse: () => _dashboardSort,
      );
    }
    _dashboardFilterYear =
        json['dashboardFilterYear'] as int? ?? _dashboardFilterYear;
    _dashboardFilterMonth =
        json['dashboardFilterMonth'] as int? ?? _dashboardFilterMonth;
    _insightRotationIndex =
        json['insightRotationIndex'] as int? ?? _insightRotationIndex;
    _motivationSessionIndex =
        json['motivationSessionIndex'] as int? ?? _motivationSessionIndex;
    final scopeName = json['smartLockScope'] as String?;
    if (scopeName != null) {
      _smartLockScope = SmartLockScope.values.firstWhere(
        (s) => s.name == scopeName,
        orElse: () => _smartLockScope,
      );
    }
    final authName = json['smartLockAuthMethod'] as String?;
    if (authName != null) {
      _smartLockAuthMethod = SmartLockAuthMethod.values.firstWhere(
        (a) => a.name == authName,
        orElse: () => _smartLockAuthMethod,
      );
    }
    final autoLockName = json['smartLockAutoLock'] as String?;
    if (autoLockName != null) {
      _smartLockAutoLock = SmartLockAutoLock.values.firstWhere(
        (a) => a.name == autoLockName,
        orElse: () => _smartLockAutoLock,
      );
    }
    _smartLockEnabled =
        json['smartLockEnabled'] as bool? ?? _smartLockEnabled;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_kCurrencyKey, _defaultCurrency.name);
    await prefs.setBool(_kNotificationsKey, _notificationsEnabled);
    await prefs.setInt(_kDefaultLeadDaysKey, _defaultReminderLeadDays);
    await prefs.setInt(_kDefaultReminderHourKey, _defaultReminderHour);
    await prefs.setInt(_kDefaultReminderMinuteKey, _defaultReminderMinute);
    await prefs.setBool(_kHasSeenOnboardingKey, _hasSeenOnboarding);
    await prefs.setString(_kUserNameKey, _userName);
    await prefs.setBool(_kNotifSoundKey, _notificationSoundEnabled);
    await prefs.setBool(_kNotifVibrationKey, _notificationVibrationEnabled);
    await prefs.setBool(_kAlarmStyleKey, _alarmStyleAlertsEnabled);
    await prefs.setBool(_kHeadsUpKey, _headsUpNotificationsEnabled);
    await prefs.setInt(_kDefaultSnoozeKey, _defaultSnoozeMinutes);
    await prefs.setString(_kDashboardFilterKey, _dashboardTimeFilter.name);
    await prefs.setString(_kDashboardSortKey, _dashboardSort.name);
    await prefs.setInt(_kDashboardFilterYearKey, _dashboardFilterYear);
    await prefs.setInt(_kDashboardFilterMonthKey, _dashboardFilterMonth);
    await prefs.setInt(_kInsightRotationKey, _insightRotationIndex);
    await prefs.setInt(_kMotivationSessionKey, _motivationSessionIndex);
    await prefs.setBool(_kSmartLockEnabledKey, _smartLockEnabled);
    await prefs.setString(_kSmartLockScopeKey, _smartLockScope.name);
    await prefs.setString(_kSmartLockAuthKey, _smartLockAuthMethod.name);
    await prefs.setString(_kSmartLockAutoLockKey, _smartLockAutoLock.name);
    notifyListeners();
  }
}
