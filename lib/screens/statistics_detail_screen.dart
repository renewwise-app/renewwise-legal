import 'package:flutter/material.dart';

import 'package:renew_wise/models/history_entry.dart';
import 'package:renew_wise/models/renewal.dart';
import 'package:renew_wise/services/event_extras_service.dart';
import 'package:renew_wise/services/notification_service.dart';
import 'package:renew_wise/services/reminder_state_service.dart';
import 'package:renew_wise/services/renewal_service.dart';
import 'package:renew_wise/services/settings_service.dart';
import 'package:renew_wise/services/sharing_service.dart';
import 'package:renew_wise/screens/event_details_screen.dart';
import 'package:renew_wise/theme/app_theme.dart';
import 'package:renew_wise/widgets/common/app_empty_state.dart';
import 'package:renew_wise/widgets/renewal_list_item.dart';

/// Filtered renewal or history list opened from a statistics card.
class StatisticsDetailScreen extends StatelessWidget {
  const StatisticsDetailScreen({
    super.key,
    required this.title,
    required this.subtitle,
    required this.renewals,
    this.historyEntries = const [],
    required this.renewalService,
    this.settingsService,
    this.reminderStateService,
    this.notificationService,
    this.eventExtrasService,
    this.sharingService,
  });

  final String title;
  final String subtitle;
  final List<Renewal> renewals;
  final List<HistoryEntry> historyEntries;
  final RenewalService renewalService;
  final SettingsService? settingsService;
  final ReminderStateService? reminderStateService;
  final NotificationService? notificationService;
  final EventExtrasService? eventExtrasService;
  final SharingService? sharingService;

  static Future<void> push(
    BuildContext context, {
    required String title,
    required String subtitle,
    required List<Renewal> renewals,
    List<HistoryEntry> historyEntries = const [],
    required RenewalService renewalService,
    SettingsService? settingsService,
    ReminderStateService? reminderStateService,
    NotificationService? notificationService,
    EventExtrasService? eventExtrasService,
    SharingService? sharingService,
  }) {
    return Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => StatisticsDetailScreen(
          title: title,
          subtitle: subtitle,
          renewals: renewals,
          historyEntries: historyEntries,
          renewalService: renewalService,
          settingsService: settingsService,
          reminderStateService: reminderStateService,
          notificationService: notificationService,
          eventExtrasService: eventExtrasService,
          sharingService: sharingService,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canOpenEvent = settingsService != null &&
        reminderStateService != null &&
        notificationService != null &&
        eventExtrasService != null;

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
          children: [
            Text(
              subtitle,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 16),
            if (renewals.isEmpty && historyEntries.isEmpty)
              const AppEmptyState(
                icon: Icons.inbox_outlined,
                title: 'Nothing to show yet',
                subtitle:
                    'Your insights will appear as you continue using RenewWise.',
              )
            else ...[
              ...renewals.map(
                (r) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: RenewalListItem(
                    renewal: r,
                    documentCount:
                        eventExtrasService?.documentsFor(r.id).length ?? 0,
                    onTap: canOpenEvent
                        ? () => EventDetailsScreen.push(
                              context,
                              renewal: r,
                              renewalService: renewalService,
                              settingsService: settingsService!,
                              reminderStateService: reminderStateService!,
                              notificationService: notificationService!,
                              eventExtrasService: eventExtrasService!,
                              sharingService: sharingService,
                            )
                        : null,
                  ),
                ),
              ),
              ...historyEntries.map(
                (e) => Card(
                  margin: const EdgeInsets.only(bottom: 10),
                  child: ListTile(
                    leading: Icon(
                      Icons.check_circle_outline,
                      color: AppColors.primary,
                    ),
                    title: Text(e.title),
                    subtitle: Text(
                      'Completed ${e.completionDate.day}/${e.completionDate.month}/${e.completionDate.year}',
                    ),
                    trailing: e.amount != null
                        ? Text(
                            '₹${e.amount!.toStringAsFixed(0)}',
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          )
                        : null,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
