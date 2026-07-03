import 'package:flutter/material.dart';

import 'package:renew_wise/models/alert_style.dart';
import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/services/event_extras_service.dart';
import 'package:renew_wise/services/notification_service.dart';
import 'package:renew_wise/services/reminder_state_service.dart';
import 'package:renew_wise/services/renewal_completion_flow.dart';
import 'package:renew_wise/services/renewal_service.dart';
import 'package:renew_wise/services/settings_service.dart';
import 'package:renew_wise/services/sharing_service.dart';
import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/theme/renew_wise_design_system.dart';
import 'package:renew_wise/utils/reminder_reschedule_dialog.dart';
import 'package:renew_wise/utils/reminder_snooze_sheet.dart';

/// Full-screen critical reminder experience (Package 7A / DR-4).
class CriticalAlertScreen extends StatelessWidget {
  const CriticalAlertScreen({
    super.key,
    required this.renewal,
    required this.renewalService,
    required this.settingsService,
    required this.reminderStateService,
    required this.notificationService,
    required this.eventExtrasService,
    this.sharingService,
  });

  final Renewal renewal;
  final RenewalService renewalService;
  final SettingsService settingsService;
  final ReminderStateService reminderStateService;
  final NotificationService notificationService;
  final EventExtrasService eventExtrasService;
  final SharingService? sharingService;

  static Future<void> show(
    BuildContext context, {
    required Renewal renewal,
    required RenewalService renewalService,
    required SettingsService settingsService,
    required ReminderStateService reminderStateService,
    required NotificationService notificationService,
    required EventExtrasService eventExtrasService,
    SharingService? sharingService,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        fullscreenDialog: true,
        pageBuilder: (_, _, _) => CriticalAlertScreen(
          renewal: renewal,
          renewalService: renewalService,
          settingsService: settingsService,
          reminderStateService: reminderStateService,
          notificationService: notificationService,
          eventExtrasService: eventExtrasService,
          sharingService: sharingService,
        ),
        transitionsBuilder: (_, anim, _, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  Future<void> _markComplete(BuildContext context) async {
    await notificationService.cancelReminders(renewal.id);
    if (!context.mounted) return;
    await RenewalCompletionFlow(
      renewalService: renewalService,
      reminderStateService: reminderStateService,
      notificationService: notificationService,
      defaultReminderTimeMinutes: settingsService.defaultReminderTimeMinutes,
    ).run(context, renewal, completionMethod: 'critical_alert');
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _snooze(BuildContext context) async {
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
    if (context.mounted) Navigator.of(context).pop();
  }

  Future<void> _reschedule(BuildContext context) async {
    final saved = await ReminderRescheduleDialog.show(
      context,
      renewal: renewal,
      renewalService: renewalService,
      notificationService: notificationService,
      reminderStateService: reminderStateService,
      defaultReminderTimeMinutes: settingsService.defaultReminderTimeMinutes,
    );
    if (saved && context.mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final dueLabel = renewal.isOverdue
        ? 'Overdue · ${renewal.formattedRenewalDate}'
        : renewal.daysRemaining <= 0
            ? 'Due today · ${renewal.formattedRenewalDate}'
            : '${renewal.daysRemainingLabel} · ${renewal.formattedRenewalDate}';

    final paymentLabel = renewal.formattedAmount;

    return PopScope(
      canPop: false,
      child: Scaffold(
        backgroundColor: RenewWisePalette.pageBackground,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.page),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: AlertStyle.critical.color.withAlpha(20),
                        borderRadius: BorderRadius.circular(AppRadius.pill),
                      ),
                      child: Text(
                        AlertStyle.critical.dropdownLabel,
                        style: RenewWiseTypography.caption.copyWith(
                          color: AlertStyle.critical.color,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        RenewWisePalette.brandSoftStart,
                        RenewWisePalette.brandSoftEnd,
                      ],
                    ),
                    borderRadius: BorderRadius.circular(AppRadius.homeCard),
                    boxShadow: RenewWiseShadows.homeCard(AppColors.critical),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        renewal.title,
                        style: RenewWiseTypography.screenTitle.copyWith(
                          fontSize: 28,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      Text(
                        renewal.categoryLabel,
                        style: RenewWiseTypography.secondary.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      Text(
                        dueLabel,
                        style: RenewWiseTypography.cardTitle.copyWith(
                          color: AppColors.critical,
                        ),
                      ),
                      if (paymentLabel != 'No payment') ...[
                        const SizedBox(height: AppSpacing.sm),
                        Text(
                          'Estimated payment: $paymentLabel',
                          style: RenewWiseTypography.secondary.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                const Spacer(flex: 2),
                FilledButton.icon(
                  onPressed: () => _markComplete(context),
                  icon: const Icon(Icons.check_rounded),
                  label: const Text('Mark Done'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _snooze(context),
                  icon: const Icon(Icons.snooze_rounded),
                  label: const Text('Snooze'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    side: BorderSide(color: AppColors.primary.withAlpha(80)),
                  ),
                ),
                const SizedBox(height: 12),
                OutlinedButton.icon(
                  onPressed: () => _reschedule(context),
                  icon: const Icon(Icons.calendar_month_outlined),
                  label: const Text('Reschedule'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    minimumSize: const Size.fromHeight(52),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadius.md),
                    ),
                    side: BorderSide(color: AppColors.primary.withAlpha(80)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
