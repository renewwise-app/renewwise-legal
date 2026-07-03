import 'package:flutter/material.dart';

import 'package:renew_wise/utils/notification_level_resolver.dart';

/// Unified snooze picker for the reminder lifecycle (DR-4).
abstract final class ReminderSnoozeSheet {
  static Future<Duration?> show(
    BuildContext context, {
    int? defaultSnoozeMinutes,
  }) {
    final defaultDuration = defaultSnoozeMinutes != null
        ? Duration(minutes: defaultSnoozeMinutes)
        : null;

    return showModalBottomSheet<Duration>(
      context: context,
      showDragHandle: true,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
              child: Text(
                'Snooze for…',
                style: Theme.of(ctx).textTheme.titleMedium,
              ),
            ),
            if (defaultDuration != null)
              ListTile(
                leading: const Icon(Icons.star_outline_rounded),
                title: Text(
                  '${ReminderSnoozeOptions.label(defaultDuration)} (default)',
                ),
                onTap: () => Navigator.pop(ctx, defaultDuration),
              ),
            for (final duration in ReminderSnoozeOptions.presets)
              if (defaultDuration == null || duration != defaultDuration)
                ListTile(
                  leading: const Icon(Icons.snooze_outlined),
                  title: Text(ReminderSnoozeOptions.label(duration)),
                  onTap: () => Navigator.pop(ctx, duration),
                ),
            ListTile(
              leading: const Icon(Icons.wb_sunny_outlined),
              title: const Text('Tomorrow'),
              onTap: () => Navigator.pop(
                ctx,
                ReminderSnoozeOptions.untilTomorrow(),
              ),
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}
