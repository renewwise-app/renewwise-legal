import 'dart:io';

import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

enum DocumentAuthResult {
  success,
  cancelled,
  failed,
  noDeviceSecurity,
}

/// Device authentication for protected documents (Package 7C).
abstract final class DocumentProtectionService {
  static final LocalAuthentication _auth = LocalAuthentication();

  static Future<bool> isDeviceAuthAvailable() async {
    if (!Platform.isAndroid && !Platform.isIOS) return false;
    try {
      return await _auth.isDeviceSupported();
    } on PlatformException {
      return false;
    }
  }

  static Future<List<BiometricType>> availableBiometrics() async {
    if (!Platform.isAndroid && !Platform.isIOS) return const [];
    try {
      return await _auth.getAvailableBiometrics();
    } on PlatformException {
      return const [];
    }
  }

  static Future<DocumentAuthResult> authenticate({
    required String reason,
    bool biometricOnly = false,
  }) async {
    if (!Platform.isAndroid && !Platform.isIOS) {
      return DocumentAuthResult.noDeviceSecurity;
    }

    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return DocumentAuthResult.noDeviceSecurity;

      final ok = await _auth.authenticate(
        localizedReason: reason,
        options: AuthenticationOptions(
          biometricOnly: biometricOnly,
          stickyAuth: true,
        ),
      );
      return ok ? DocumentAuthResult.success : DocumentAuthResult.cancelled;
    } on PlatformException catch (e) {
      if (e.code == 'PasscodeNotSet' ||
          e.code == 'NotEnrolled' ||
          e.code == 'LockedOut') {
        return DocumentAuthResult.noDeviceSecurity;
      }
      if (e.code == 'UserCanceled' || e.code == 'Canceled') {
        return DocumentAuthResult.cancelled;
      }
      return DocumentAuthResult.failed;
    } catch (_) {
      return DocumentAuthResult.failed;
    }
  }
}
