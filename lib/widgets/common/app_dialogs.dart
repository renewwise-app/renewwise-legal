import 'package:flutter/material.dart';

import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/widgets/common/app_feedback.dart';

/// Standardized confirmation and warning dialogs.
abstract final class AppDialogs {
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    required String message,
    String cancelLabel = 'Cancel',
    String confirmLabel = 'Confirm',
    bool destructive = false,
    bool hapticOnConfirm = true,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.dialogBorder),
        title: Text(title),
        content: Text(
          message,
          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                height: 1.45,
              ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          0,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: destructive
                ? FilledButton.styleFrom(backgroundColor: AppColors.critical)
                : null,
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
    if (result == true && hapticOnConfirm) {
      destructive ? AppHaptics.destructive() : AppHaptics.confirm();
    }
    return result ?? false;
  }

  static Future<bool> delete(
    BuildContext context, {
    required String title,
    required String message,
  }) =>
      confirm(
        context,
        title: title,
        message: message,
        confirmLabel: 'Delete',
        destructive: true,
      );

  static Future<bool> restore(
    BuildContext context, {
    String title = 'Restore this event?',
    String message =
        'It will return to your active reminders with the same details.',
  }) =>
      confirm(
        context,
        title: title,
        message: message,
        confirmLabel: 'Restore',
      );

  static Future<bool> completeHistory(
    BuildContext context,
  ) =>
      confirm(
        context,
        title: 'Move to History?',
        message:
            'This event will be marked complete and kept in your history for reference.',
        cancelLabel: 'Not now',
        confirmLabel: 'Yes, move it',
      );

  static Future<bool> scheduleNext(
    BuildContext context, {
    required String cycleLabel,
  }) =>
      confirm(
        context,
        title: 'Schedule the next one?',
        message: 'Create the next $cycleLabel reminder automatically?',
        cancelLabel: 'Skip',
        confirmLabel: 'Schedule',
      );

  static Future<bool> clearAllData(BuildContext context) => delete(
        context,
        title: 'Clear all data?',
        message:
            'This permanently removes all events, documents, and scheduled reminders. This cannot be undone.',
      ).then((v) {
        if (v) AppHaptics.destructive();
        return v;
      });

  static Future<bool> backupWarning(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Continue',
  }) =>
      confirm(
        context,
        title: title,
        message: message,
        confirmLabel: confirmLabel,
        destructive: false,
      );
}
