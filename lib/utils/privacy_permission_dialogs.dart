import 'dart:io';

import 'package:flutter/material.dart';

import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/design_tokens.dart';

/// Short trust-building explanations shown before Android permission requests.
abstract final class PrivacyPermissionDialogs {
  static Future<bool> explainNotifications(BuildContext context) {
    return _show(
      context,
      title: 'Allow Notifications',
      body:
          'RenewWise needs notification permission so it can remind you about important events.\n\n'
          'No advertisements.\n\n'
          'No spam.\n\n'
          'Only your reminders.',
    );
  }

  static Future<bool> explainDocumentAccess(BuildContext context) {
    return _show(
      context,
      title: 'Allow Document Access',
      body:
          'This permission is only required if you choose to attach documents to your reminders.\n\n'
          'RenewWise never scans your files.',
    );
  }

  static Future<bool> _show(
    BuildContext context, {
    required String title,
    required String body,
  }) async {
    if (!Platform.isAndroid) return true;

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.dialogBorder),
        title: Text(title),
        content: Text(
          body,
          style: Theme.of(ctx).textTheme.bodyMedium?.copyWith(
                color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                height: 1.5,
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
            child: const Text('Not Now'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
            child: const Text('Continue'),
          ),
        ],
      ),
    );
    return result ?? false;
  }
}
