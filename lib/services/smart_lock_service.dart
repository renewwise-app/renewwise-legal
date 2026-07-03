import 'package:local_auth/local_auth.dart';

import 'package:renew_wise/models/smart_lock_models.dart';
import 'package:renew_wise/services/document_protection_service.dart';
import 'package:renew_wise/services/settings_service.dart';

/// Smart Lock — app and document protection preferences.
abstract final class SmartLockService {
  static SettingsService? _settings;

  static void attach(SettingsService settings) {
    _settings = settings;
  }

  static SettingsService get settings {
    assert(_settings != null, 'SmartLockService.attach() must be called at startup');
    return _settings!;
  }

  static SmartLockScope get scope => settings.smartLockScope;

  static bool get enabled => settings.smartLockEnabled;

  static bool get locksApp => enabled && scope.locksApp;

  static bool get locksDocuments => enabled && scope.locksDocuments;

  static bool shouldLockAfterBackground(DateTime? pausedAt) {
    if (!enabled || !locksApp) return false;
    final autoLock = settings.smartLockAutoLock;
    if (autoLock == SmartLockAutoLock.never) return false;
    if (pausedAt == null) return autoLock == SmartLockAutoLock.immediately;
    if (autoLock == SmartLockAutoLock.immediately) return true;
    final elapsed = DateTime.now().difference(pausedAt);
    return elapsed.inMinutes >= autoLock.minutes;
  }

  static Future<bool> isFaceUnlockAvailable() async {
    return DocumentProtectionService.availableBiometrics()
        .then((types) => types.contains(BiometricType.face));
  }

  static Future<DocumentAuthResult> authenticate({
    required String reason,
    SmartLockAuthMethod? methodOverride,
  }) {
    final method = methodOverride ?? settings.smartLockAuthMethod;
    return DocumentProtectionService.authenticate(
      reason: reason,
      biometricOnly: method.preferBiometric,
    );
  }
}
