import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/design_tokens.dart';

/// Gentle haptics for meaningful actions only.
abstract final class AppHaptics {
  static void light() => HapticFeedback.lightImpact();
  static void confirm() => HapticFeedback.lightImpact();
  static void destructive() => HapticFeedback.mediumImpact();
}

/// Consistent snackbars and user-facing messages.
abstract final class AppFeedback {
  static void show(
    BuildContext context, {
    required String message,
    bool success = false,
    bool error = false,
    Duration? duration,
    bool haptic = false,
  }) {
    if (haptic) {
      if (error) {
        AppHaptics.destructive();
      } else {
        AppHaptics.confirm();
      }
    }
    final messenger = ScaffoldMessenger.of(context);
    final display = success && !message.startsWith('✓')
        ? '✓ $message'
        : message;
    messenger
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(
            display,
            style: error
                ? const TextStyle(color: Colors.white, fontSize: 14)
                : null,
          ),
          duration: duration ?? AppMotion.snackDuration,
          behavior: SnackBarBehavior.floating,
          backgroundColor: error
              ? AppColors.critical
              : Theme.of(context).colorScheme.inverseSurface,
          shape: RoundedRectangleBorder(
            borderRadius: AppRadius.buttonBorder,
          ),
        ),
      );
  }

  static void success(BuildContext context, String message) => show(
        context,
        message: message,
        success: true,
        haptic: true,
      );

  static void error(BuildContext context, String message) => show(
        context,
        message: message,
        error: true,
        haptic: true,
      );

  static void info(BuildContext context, String message) =>
      show(context, message: message);

  // ── Preset copy (RenewWise tone) ─────────────────────────────────────────

  static void saved(BuildContext context) => success(
        context,
        'Reminder saved',
      );

  static void updated(BuildContext context) => success(
        context,
        'Reminder updated',
      );

  static void completed(BuildContext context) => success(
        context,
        'Reminder completed',
      );

  static void restored(BuildContext context) => success(
        context,
        'Restore completed',
      );

  static void deleted(BuildContext context) => success(
        context,
        'Reminder deleted',
      );

  static void documentAttached(BuildContext context) => success(
        context,
        'Document attached',
      );

  static void documentAdded(BuildContext context, {int count = 1}) => success(
        context,
        count == 1 ? 'Document added' : '$count documents added',
      );

  static void exported(BuildContext context) => success(
        context,
        'Export completed',
      );

  static void imported(BuildContext context) => success(
        context,
        'Import completed',
      );

  static void backupSaved(BuildContext context) => success(
        context,
        'Backup completed',
      );

  static void backupFailed(BuildContext context, [String? detail]) => error(
        context,
        "Couldn't complete your backup.\nCheck your connection and try again.",
      );

  static void restoreFailed(BuildContext context) => error(
        context,
        "Couldn't restore your backup.\nPlease try again.",
      );

  static void saveFailed(BuildContext context) => error(
        context,
        "Couldn't save your reminder.\nPlease try again.",
      );

  static void genericError(BuildContext context) => error(
        context,
        "Couldn't complete that action.\nPlease try again.",
      );

  static void copied(BuildContext context) => info(
        context,
        'Copied to clipboard',
      );
}
