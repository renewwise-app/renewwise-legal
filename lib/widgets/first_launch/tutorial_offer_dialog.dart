import 'package:flutter/material.dart';

import 'package:renew_wise/services/settings_service.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/widgets/first_launch/quick_tutorial_sheet.dart';

/// One-time tutorial offer shown after first successful login and name entry.
abstract final class TutorialOfferDialog {
  static Future<void> maybeShow(
    BuildContext context,
    SettingsService settingsService,
  ) async {
    if (settingsService.hasSeenTutorialOffer) return;

    final choice = await showDialog<TutorialOfferChoice>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.dialogBorder),
        title: const Text('Welcome to RenewWise'),
        content: const Text(
          'RenewWise is designed to be simple.\n\n'
          'If you\'d like a quick walkthrough, you can watch the tutorial anytime from Settings.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, TutorialOfferChoice.later),
            child: const Text('Maybe Later'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, TutorialOfferChoice.watch),
            child: const Text('Watch Tutorial'),
          ),
        ],
      ),
    );

    if (choice == TutorialOfferChoice.watch && context.mounted) {
      await QuickTutorialSheet.show(context);
    }

    await settingsService.setHasSeenTutorialOffer(true);
  }
}

enum TutorialOfferChoice { watch, later }
