import 'package:flutter/material.dart';

import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/services/notification_service.dart';
import 'package:renew_wise/services/reminder_state_service.dart';
import 'package:renew_wise/services/renewal_completion_flow.dart';
import 'package:renew_wise/services/renewal_service.dart';
import 'package:renew_wise/services/settings_service.dart';
import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';
import 'package:renew_wise/utils/notification_level_resolver.dart';
import 'package:renew_wise/utils/reminder_reschedule_dialog.dart';
import 'package:renew_wise/utils/reminder_snooze_sheet.dart';

/// Prominent missed-reminder callout on Home (does not change dashboard cards).
class MissedRemindersBanner extends StatelessWidget {
  const MissedRemindersBanner({
    super.key,
    required this.renewals,
    required this.renewalService,
    required this.settingsService,
    required this.reminderStateService,
    required this.notificationService,
  });

  final List<Renewal> renewals;
  final RenewalService renewalService;
  final SettingsService settingsService;
  final ReminderStateService reminderStateService;
  final NotificationService notificationService;

  @override
  Widget build(BuildContext context) {
    if (renewals.isEmpty) return const SizedBox.shrink();

    final renewal = renewals.first;
    final extra = renewals.length - 1;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.critical.withAlpha(18),
            RenewWisePalette.orangeSoftStart.withAlpha(120),
          ],
        ),
        borderRadius: BorderRadius.circular(AppRadius.homeCard),
        border: Border.all(color: AppColors.critical.withAlpha(40)),
        boxShadow: RenewWiseShadows.listCard(),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: AppColors.critical),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Missed reminder',
                  style: RenewWiseTypography.cardTitle.copyWith(
                    color: AppColors.critical,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            renewal.title,
            style: RenewWiseTypography.secondary.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
          if (extra > 0) ...[
            const SizedBox(height: 4),
            Text(
              '+ $extra more missed',
              style: RenewWiseTypography.caption.copyWith(
                color: RenewWisePalette.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FilledButton(
                onPressed: () => _markDone(context, renewal),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  visualDensity: VisualDensity.compact,
                ),
                child: const Text('Done'),
              ),
              OutlinedButton(
                onPressed: NotificationLevelResolver.supportsSnooze(renewal)
                    ? () => _snooze(context, renewal)
                    : null,
                child: const Text('Snooze'),
              ),
              OutlinedButton(
                onPressed: () => _reschedule(context, renewal),
                child: const Text('Reschedule'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _markDone(BuildContext context, Renewal renewal) async {
    await notificationService.cancelReminders(renewal.id);
    if (!context.mounted) return;
    await RenewalCompletionFlow(
      renewalService: renewalService,
      reminderStateService: reminderStateService,
      notificationService: notificationService,
      defaultReminderTimeMinutes: settingsService.defaultReminderTimeMinutes,
    ).run(context, renewal, completionMethod: 'missed_banner');
  }

  Future<void> _snooze(BuildContext context, Renewal renewal) async {
    final delay = await ReminderSnoozeSheet.show(
      context,
      defaultSnoozeMinutes: settingsService.defaultSnoozeMinutes,
    );
    if (delay == null || !context.mounted) return;
    await notificationService.cancelReminders(renewal.id);
    await notificationService.scheduleSnooze(
      renewal,
      delay: delay,
      defaultTimeMinutes: settingsService.defaultReminderTimeMinutes,
    );
    await reminderStateService.markAcknowledged(renewal.id);
  }

  Future<void> _reschedule(BuildContext context, Renewal renewal) async {
    await ReminderRescheduleDialog.show(
      context,
      renewal: renewal,
      renewalService: renewalService,
      notificationService: notificationService,
      reminderStateService: reminderStateService,
      defaultReminderTimeMinutes: settingsService.defaultReminderTimeMinutes,
    );
  }
}
