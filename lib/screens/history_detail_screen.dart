import 'package:flutter/material.dart';

import 'package:renew_wise/models/history_entry.dart';
import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/models/renewal_currency.dart';
import 'package:renew_wise/models/renewal_status.dart';
import 'package:renew_wise/screens/add_renewal_screen.dart';
import 'package:renew_wise/services/notification_service.dart';
import 'package:renew_wise/services/reminder_state_service.dart';
import 'package:renew_wise/services/renewal_service.dart';
import 'package:renew_wise/services/settings_service.dart';
import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/theme/design_tokens.dart';
import 'package:renew_wise/widgets/common/app_dialogs.dart';
import 'package:renew_wise/widgets/common/app_feedback.dart';
import 'package:renew_wise/utils/date_utils.dart';

class HistoryDetailScreen extends StatelessWidget {
  const HistoryDetailScreen({
    super.key,
    required this.entry,
    required this.renewalService,
    required this.settingsService,
    required this.reminderStateService,
    required this.notificationService,
  });

  final HistoryEntry entry;
  final RenewalService renewalService;
  final SettingsService settingsService;
  final ReminderStateService reminderStateService;
  final NotificationService notificationService;

  static Future<void> push(
    BuildContext context, {
    required HistoryEntry entry,
    required RenewalService renewalService,
    required SettingsService settingsService,
    required ReminderStateService reminderStateService,
    required NotificationService notificationService,
  }) {
    return Navigator.of(context).push(
      PageRouteBuilder<void>(
        pageBuilder: (_, _, _) => HistoryDetailScreen(
          entry: entry,
          renewalService: renewalService,
          settingsService: settingsService,
          reminderStateService: reminderStateService,
          notificationService: notificationService,
        ),
        transitionsBuilder: (_, anim, _, child) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween<Offset>(
              begin: const Offset(0, 0.04),
              end: Offset.zero,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
            child: child,
          ),
        ),
        transitionDuration: AppMotion.duration,
      ),
    );
  }

  String _formatTime(DateTime dt) {
    final hour = dt.hour;
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = hour >= 12 ? 'PM' : 'AM';
    final h12 = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$h12:$minute $period';
  }

  String _reminderScheduleLabel() {
    if (entry.reminderSchedule.isEmpty) return 'None';
    return entry.reminderSchedule.map((d) => '$d days before').join(', ');
  }

  String _amountLabel() {
    if (!entry.paymentRequired || entry.amount == null) return 'No payment';
    final currency = entry.currencyCode != null
        ? RenewalCurrency.values.byName(entry.currencyCode!)
        : RenewalCurrency.inr;
    return currency.formatAmount(entry.amount!);
  }

  Future<void> _restore(BuildContext context) async {
    final confirmed = await AppDialogs.restore(context);
    if (!confirmed || !context.mounted) return;

    await reminderStateService.restoreFromHistory(
      entry: entry,
      renewalService: renewalService,
    );
    if (context.mounted) {
      AppFeedback.restored(context);
      Navigator.pop(context);
    }
  }

  Future<void> _duplicate(BuildContext context) async {
    final now = DateTime.now();
    final currency = entry.currencyCode != null
        ? RenewalCurrency.values.byName(entry.currencyCode!)
        : RenewalCurrency.inr;

    final copy = Renewal(
      id: now.microsecondsSinceEpoch.toString(),
      title: '${entry.title} (Copy)',
      category: entry.category,
      customEventType: entry.customEventType,
      renewalDate: entry.originalRenewalDate,
      paymentRequired: entry.paymentRequired,
      amount: entry.amount,
      currency: currency,
      reminderSchedule: entry.reminderSchedule,
      notes: entry.notes,
      status: RenewalStatus.upcoming,
      createdAt: now,
      updatedAt: now,
    );

    await AddRenewalScreen.push(
      context,
      renewalService: renewalService,
      renewal: copy,
      defaultCurrency: settingsService.defaultCurrency,
      defaultReminderTimeMinutes: settingsService.defaultReminderTimeMinutes,
    );
  }

  Future<void> _deletePermanently(BuildContext context) async {
    final confirmed = await AppDialogs.delete(
      context,
      title: 'Delete permanently?',
      message:
          'This history entry will be removed forever. This cannot be undone.',
    );
    if (!confirmed || !context.mounted) return;

    await reminderStateService.deleteHistoryEntry(entry.id);
    if (context.mounted) {
      AppFeedback.deleted(context);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: reminderStateService,
      builder: (context, _) {
        final current =
            reminderStateService.entryById(entry.id) ?? entry;
        final theme = Theme.of(context);

        return Scaffold(
          appBar: AppBar(title: const Text('History Details')),
          body: SafeArea(
            child: Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 640),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Row(
                          children: [
                            Container(
                              width: 56,
                              height: 56,
                              decoration: BoxDecoration(
                                color: AppColors.success.withAlpha(22),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Icon(
                                current.category.icon,
                                color: AppColors.success,
                                size: 28,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    current.title,
                                    style: theme.textTheme.titleLarge?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                  Text(
                                    current.categoryLabel,
                                    style: theme.textTheme.bodyMedium?.copyWith(
                                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (current.restored)
                              Chip(
                                label: const Text('Restored'),
                                backgroundColor: AppColors.gold.withAlpha(30),
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Completion Details',
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 12),
                            _DetailRow(
                              icon: Icons.event_outlined,
                              label: 'Original Reminder Date',
                              value: RenewalDateUtils.formatDisplayDate(
                                current.originalRenewalDate,
                              ),
                            ),
                            _DetailRow(
                              icon: Icons.check_circle_outline,
                              label: 'Completion Date',
                              value: RenewalDateUtils.formatDisplayDate(
                                current.completionDate,
                              ),
                            ),
                            _DetailRow(
                              icon: Icons.schedule_outlined,
                              label: 'Completion Time',
                              value: _formatTime(current.completionDate),
                            ),
                            _DetailRow(
                              icon: Icons.notifications_outlined,
                              label: 'Reminder Schedule',
                              value: _reminderScheduleLabel(),
                            ),
                            _DetailRow(
                              icon: Icons.payments_outlined,
                              label: 'Amount',
                              value: _amountLabel(),
                            ),
                            _DetailRow(
                              icon: Icons.touch_app_outlined,
                              label: 'Completion Method',
                              value: current.completionMethodLabel,
                            ),
                            _DetailRow(
                              icon: Icons.folder_open_outlined,
                              label: 'Documents',
                              value: 'No documents attached',
                            ),
                            if (current.notes != null &&
                                current.notes!.trim().isNotEmpty)
                              _DetailRow(
                                icon: Icons.notes_outlined,
                                label: 'Notes',
                                value: current.notes!,
                              ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 28),
                    FilledButton.icon(
                      onPressed: () => _restore(context),
                      icon: const Icon(Icons.restore_rounded, size: 20),
                      label: const Text('Restore'),
                    ),
                    const SizedBox(height: 12),
                    OutlinedButton.icon(
                      onPressed: () => _duplicate(context),
                      icon: const Icon(Icons.copy_outlined, size: 20),
                      label: const Text('Duplicate'),
                    ),
                    const SizedBox(height: 12),
                    TextButton.icon(
                      onPressed: () => _deletePermanently(context),
                      icon: const Icon(Icons.delete_forever_outlined, size: 20),
                      label: const Text('Delete Permanently'),
                      style: TextButton.styleFrom(
                        foregroundColor: AppColors.critical,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 20, color: Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
